// delete-account (FR-A4, NFR-4, CS-05): permanently deletes the caller's account.
//   1. authenticate the caller from their own JWT (Authorization: Bearer <access token>)
//   2. detach storage.objects.owner, then delete the auth user (auth.admin.deleteUser).
//      Inside the BEFORE DELETE ON public.profiles trigger, public.purge_account_data locks the
//      user's journeys FOR UPDATE and atomically queues every dying media/message path into
//      private.pending_storage_purge (migrations 0017, 0019), hands over / archives surviving
//      group journeys, and deletes journeys nobody else is active in.
//   3. drain claim_storage_purge (plus a second listing pass for any racing direct upload) and
//      remove the objects via the Storage API. Whatever fails stays queued for storage-purge-sweep.
// The service key comes only from the function environment.
//
// v2 + CS-05: deletion is gated by re-authentication (3-step flow: confirm -> OTP or password -> final).
//   {"action":"send"}                      -> sends a fresh Supabase Auth OTP to the account's own
//                                             email (or phone when it has no email) and reports
//                                             `has_password` (from public.account_has_password).
//                                             If the account has a password and initial OTP delivery
//                                             is unavailable/rate-limited (and the caller did not
//                                             explicitly request an OTP resend), returns 200 with
//                                             `channel: "password"` so the client can still advance
//                                             and confirm with password.
//   {"action":"delete","code":"123456"}    -> verifies the 6-digit OTP server-side (or password if
//   {"action":"delete","password":"..."}      `password` is provided, or if `code` is a password on
//                                             a password-enabled account), enforces a per-user
//                                             brute-force rate limit, confirms the verified user id
//                                             matches the JWT caller, then deletes.
// The destination is always read from the caller's own auth record, never from the request.
import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2.117.2";
import { adminClient, chunk, json } from "../_shared/admin.ts";

function anonClient() {
  const url = Deno.env.get("SUPABASE_URL");
  let key = Deno.env.get("SUPABASE_ANON_KEY");
  if (!key) {
    try {
      key = (JSON.parse(Deno.env.get("SUPABASE_PUBLISHABLE_KEYS") ?? "{}") as Record<string, string>)["default"];
    } catch {
      key = undefined;
    }
  }
  if (!url || !key) throw new Error("public key missing from environment");
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
  });
}

function authFailure(message: string | undefined, status: number | undefined): Response {
  const rate = status === 429 || /rate|too many|seconds/i.test(message ?? "");
  return rate ? json({ error: "rate_limited" }, 429) : json({ error: "invalid" }, 400);
}

/** Normalizes a GoTrue user.phone (which may omit the leading '+') to E.164 (`+<digits>`). */
export function normalizeE164Phone(raw: string | undefined | null): string {
  const trimmed = (raw ?? "").trim();
  if (!trimmed) return "";
  return trimmed.startsWith("+") ? trimmed : `+${trimmed}`;
}

/** True for pre-seeded App Review demo accounts that authenticate with password. */
export function isReviewDemoEmail(email: string): boolean {
  const lower = email.trim().toLowerCase();
  return lower === "review@ourney.tech" || lower === "review-delete@ourney.tech";
}

/** Checks whether the account has a password set in auth.users (migration 0020). */
async function accountHasPassword(admin: SupabaseClient, userId: string): Promise<boolean> {
  try {
    const { data, error } = await admin.rpc("account_has_password", { p_user: userId });
    if (error) return false;
    return data === true;
  } catch {
    return false;
  }
}

/** Enforces a per-user brute-force rate limit (< 10 failed re-auth attempts per 15 minutes). */
async function checkReauthRateLimit(
  admin: SupabaseClient,
  userId: string,
  recordFailure: boolean,
): Promise<boolean> {
  try {
    const { data, error } = await admin.rpc("check_delete_reauth_rate_limit", {
      p_user: userId,
      p_record_failure: recordFailure,
    });
    if (error) {
      console.error("check_delete_reauth_rate_limit failed", error.message);
      return true;
    }
    return data !== false;
  } catch {
    return true;
  }
}

/** Lists every object the RPC reports for the user. */
async function listPaths(
  admin: SupabaseClient,
  rpc: string,
  userId: string,
): Promise<{ paths: string[] } | { error: Response }> {
  const { data: paths, error } = await admin.rpc(rpc, { p_user: userId });
  if (error) {
    console.error(`${rpc} failed`, error.message);
    return { error: json({ error: "storage_listing_failed" }, 500) };
  }
  return { paths: (paths ?? []) as string[] };
}

/** Queues paths in the service-only purge table (migration 0017), in chunks. Returns false when a
 *  chunk could not be recorded. */
async function queuePaths(admin: SupabaseClient, bucket: string, userId: string, paths: string[]): Promise<boolean> {
  for (const part of chunk(paths, 500)) {
    try {
      const { error } = await admin.rpc("enqueue_storage_purge", { p_bucket: bucket, p_user: userId, p_paths: part });
      if (error) {
        console.error(`enqueue_storage_purge failed (${bucket}, ${part.length} paths)`, error.message);
        return false;
      }
    } catch (e) {
      console.error("enqueue_storage_purge threw", e instanceof Error ? e.message : String(e));
      return false;
    }
  }
  return true;
}

/** Drops paths from the purge table once they are removed. */
async function dequeuePaths(admin: SupabaseClient, bucket: string, paths: string[]) {
  for (const part of chunk(paths, 500)) {
    try {
      const { error } = await admin.rpc("finish_storage_purge", { p_bucket: bucket, p_paths: part });
      if (error) console.error(`finish_storage_purge failed (${bucket}, ${part.length} paths)`, error.message);
    } catch (e) {
      console.error("finish_storage_purge threw", e instanceof Error ? e.message : String(e));
    }
  }
}

/** Removal after the account is gone. Every path is already queued: a removed one is dequeued, a
 *  failed one stays queued with its attempt counted (the sweep retries it). Failures are never
 *  returned (the user no longer exists, so the client could not retry). Returns the removed count. */
async function removePaths(admin: SupabaseClient, bucket: string, list: string[]): Promise<number> {
  let removed = 0;
  for (const part of chunk(list, 100)) {
    let failure: string | null = null;
    try {
      const { error } = await admin.storage.from(bucket).remove(part);
      if (error) failure = error.message;
    } catch (e) {
      failure = e instanceof Error ? e.message : String(e);
    }
    if (failure === null) {
      removed += part.length;
      await dequeuePaths(admin, bucket, part);
      continue;
    }
    console.error(`storage remove failed (${bucket}, ${part.length} objects)`, failure);
    try {
      const noted = await admin.rpc("fail_storage_purge", { p_bucket: bucket, p_paths: part, p_error: failure });
      if (noted.error) console.error("fail_storage_purge failed", noted.error.message);
    } catch (e) {
      console.error("fail_storage_purge threw", e instanceof Error ? e.message : String(e));
    }
  }
  return removed;
}

/** Claims and removes queued storage paths for deleted accounts (queued by purge_account_data). */
async function drainClaimedPurge(admin: SupabaseClient): Promise<number> {
  let removed = 0;
  for (let pass = 0; pass < 10; pass++) {
    const { data, error } = await admin.rpc("claim_storage_purge", { p_limit: 500 });
    if (error) {
      console.error("claim_storage_purge failed", error.message);
      break;
    }
    const rows = (data ?? []) as { bucket: string; path: string }[];
    if (rows.length === 0) break;
    const byBucket = new Map<string, string[]>();
    for (const r of rows) {
      const list = byBucket.get(r.bucket) ?? [];
      list.push(r.path);
      byBucket.set(r.bucket, list);
    }
    for (const [bucket, paths] of byBucket) {
      removed += await removePaths(admin, bucket, paths);
    }
    if (rows.length < 500) break;
  }
  return removed;
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** The `sub` claim of a JWT (payload only; the signature was verified by the gateway). */
function jwtSub(token: string): string | null {
  try {
    const part = token.split(".")[1];
    if (!part) return null;
    const b64 = part.replace(/-/g, "+").replace(/_/g, "/");
    const payload = JSON.parse(atob(b64.padEnd(Math.ceil(b64.length / 4) * 4, "="))) as { sub?: unknown };
    return typeof payload.sub === "string" && UUID_RE.test(payload.sub) ? payload.sub : null;
  } catch {
    return null;
  }
}

export async function handle(req: Request): Promise<Response> {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405, { Allow: "POST" });

  const auth = req.headers.get("Authorization") ?? "";
  const token = auth.startsWith("Bearer ") ? auth.slice(7).trim() : "";
  if (!token) return json({ error: "unauthenticated" }, 401);

  const admin = adminClient();
  const { data: userData, error: userError } = await admin.auth.getUser(token);
  const userId = userData?.user?.id;
  if (userError || !userId) {
    // getUser failing does not by itself mean the account is gone (a revoked session, "Session
    // from session_id claim in JWT does not exist", also fails it). Ask for the user directly by
    // the JWT's `sub` (the gateway verified the signature: verify_jwt = true in config.toml) and
    // say 410 only when that lookup itself reports the user missing.
    const sub = jwtSub(token);
    if (!sub) return json({ error: "unauthenticated" }, 401);
    try {
      const lookup = await admin.auth.admin.getUserById(sub);
      const err = lookup.error;
      if (err) {
        if (err.status === 404 || err.code === "user_not_found") return json({ error: "already_deleted" }, 410);
        // The lookup itself failed (network, auth server down): neither deleted nor unauthenticated.
        if (!err.status || err.status >= 500) return json({ error: "internal" }, 503);
      }
    } catch (e) {
      console.error("getUserById threw", e instanceof Error ? e.message : String(e));
      return json({ error: "internal" }, 503);
    }
    // The user exists (or another auth error): the session is revoked/expired.
    return json({ error: "unauthenticated" }, 401);
  }

  let body: {
    action?: string;
    code?: string;
    token?: string;
    password?: string;
    method?: string;
    resend?: boolean;
  } = {};
  try {
    body = await req.json();
  } catch {
    body = {};
  }
  const email = (userData.user?.email ?? "").trim();
  // FS-02: GoTrue persists user.phone without a leading '+', whereas OTP endpoints expect E.164.
  const phone = normalizeE164Phone(userData.user?.phone);
  if (!email && !phone) return json({ error: "invalid" }, 400);

  const hasPassword = await accountHasPassword(admin, userId);

  if (body.action === "send") {
    if (body.method === "password" && hasPassword) {
      return json({ sent: false, channel: "password", has_password: true });
    }
    const anon = anonClient();
    const { error } = email
      ? await anon.auth.signInWithOtp({ email, options: { shouldCreateUser: false } })
      : await anon.auth.signInWithOtp({ phone, options: { shouldCreateUser: false } });
    if (error) {
      console.warn("delete otp send failed", error.message);
      // CS-05: if a password-enabled account cannot send an initial OTP due to SMTP/rate limits,
      // still let the client proceed to step 2 for password re-auth (unless the user explicitly
      // asked for an OTP or clicked "Resend code").
      if (hasPassword && !body.resend && body.method !== "otp") {
        return json({ sent: false, channel: "password", has_password: true });
      }
      return authFailure(error.message, error.status);
    }
    return json({ sent: true, channel: email ? "email" : "sms", has_password: hasPassword });
  }

  if (body.action !== "delete") return json({ error: "invalid" }, 400);

  const rawPassword = typeof body.password === "string" ? body.password : "";
  const rawCode = typeof body.code === "string"
    ? body.code.trim()
    : (typeof body.token === "string" ? body.token.trim() : "");
  const isSixDigitOtp = /^\d{6}$/.test(rawCode);
  const forcePasswordMethod = body.method === "password" && hasPassword;
  // CS-05: accept explicit `password`, OR `code` when `method === "password"`, OR a non-6-digit
  // `code` on a password-enabled account (in case the client passes password via `code`).
  const candidatePassword = rawPassword.length > 0
    ? rawPassword
    : ((forcePasswordMethod || (!isSixDigitOtp && hasPassword && body.method !== "otp")) &&
        typeof body.code === "string" && body.code.length > 0
      ? body.code
      : "");

  if (!isSixDigitOtp && candidatePassword.length === 0) {
    return json({ error: "invalid" }, 400);
  }

  if (!(await checkReauthRateLimit(admin, userId, false))) {
    return json({ error: "rate_limited" }, 429);
  }

  {
    const anon = anonClient();
    let verifiedUserId: string | undefined;
    let verifyError: { message?: string; status?: number } | null = null;

    if (candidatePassword.length > 0) {
      const { data, error } = email
        ? await anon.auth.signInWithPassword({ email, password: candidatePassword })
        : await anon.auth.signInWithPassword({ phone, password: candidatePassword });
      verifiedUserId = data?.user?.id;
      verifyError = error;
    } else {
      const { data, error } = email
        ? await anon.auth.verifyOtp({ email, token: rawCode, type: "email" })
        : await anon.auth.verifyOtp({ phone, token: rawCode, type: "sms" });
      verifiedUserId = data?.user?.id;
      verifyError = error;

      // If a password-enabled user has a 6-digit numeric password and passed it via `code`
      // without `method: "password"`, fall back to password verification when verifyOtp fails.
      if ((verifyError || verifiedUserId !== userId) && hasPassword && body.method !== "otp") {
        const pwAttempt = email
          ? await anon.auth.signInWithPassword({ email, password: rawCode })
          : await anon.auth.signInWithPassword({ phone, password: rawCode });
        if (!pwAttempt.error && pwAttempt.data?.user?.id === userId) {
          verifiedUserId = pwAttempt.data.user.id;
          verifyError = null;
        }
      }
    }

    if (verifyError || verifiedUserId !== userId) {
      console.warn(
        "delete re-auth failed",
        verifyError ? `${verifyError.status ?? "?"} ${verifyError.message}` : "user mismatch",
      );
      const allowed = await checkReauthRateLimit(admin, userId, true);
      if (!allowed) return json({ error: "rate_limited" }, 429);
      return authFailure(verifyError?.message, verifyError?.status);
    }
    // FS-02: revoke only the temporary local session minted by verifyOtp / signInWithPassword on
    // `anon` (never `scope: "global"`, which would revoke the caller's mobile session before
    // deleteUser succeeds).
    try {
      await anon.auth.signOut({ scope: "local" });
    } catch {
      // Best-effort cleanup before deleteUser removes all sessions.
    }
  }

  // storage.objects.owner may reference auth.users depending on the Storage version: detach it
  // first so deleteUser cannot be blocked by existing objects (they are removed below).
  const detach = await admin.rpc("detach_account_storage_owner", { p_user: userId });
  if (detach.error) console.error("detach_account_storage_owner failed", detach.error.message);

  // FS-08: deleteUser triggers profiles_before_delete -> purge_account_data(userId) inside the
  // same DB transaction, locking journeys FOR UPDATE and queueing only the paths of journeys and
  // conversations that truly die with the account.
  let { error: deleteError } = await admin.auth.admin.deleteUser(userId);
  if (deleteError) {
    // Retry once after a short delay in case a simultaneous co-member deleteUser hit a transient
    // lock/deadlock rollback during group ownership handover.
    await new Promise((r) => setTimeout(r, 150));
    try {
      const check = await admin.auth.admin.getUserById(userId);
      if (!check.error && check.data?.user) {
        ({ error: deleteError } = await admin.auth.admin.deleteUser(userId));
      } else if (check.error?.status === 404 || check.error?.code === "user_not_found") {
        deleteError = null;
      }
    } catch {
      // Keep original deleteError if lookup threw.
    }
  }
  if (deleteError) {
    console.error("deleteUser failed", deleteError.message);
    return json({ error: "delete_failed" }, 500);
  }

  let removed = await drainClaimedPurge(admin);

  // Second pass: folder-based objects (avatars/{uid}, checkins/*/{uid}, messages/*/{uid}) uploaded
  // in a racing request right around deleteUser.
  for (const [rpc, bucket] of [
    ["account_media_paths", "media"],
    ["account_message_paths", "messages"],
  ] as const) {
    const again = await listPaths(admin, rpc, userId);
    if ("error" in again) {
      console.error(`second pass listing failed (${rpc}); see docs/runbooks/storage-purge.md`);
      continue;
    }
    if (again.paths.length === 0) continue;
    if (!(await queuePaths(admin, bucket, userId, again.paths))) {
      console.error(`second pass paths could not be queued (${bucket}, ${again.paths.length})`);
    }
    removed += await removePaths(admin, bucket, again.paths);
  }
  return json({ deleted: true, removed_objects: removed });
}

if (import.meta.main) {
  Deno.serve(async (req: Request): Promise<Response> => {
    try {
      return await handle(req);
    } catch (e) {
      console.error("delete-account failed", e instanceof Error ? e.message : String(e));
      return json({ error: "internal" }, 500);
    }
  });
}
