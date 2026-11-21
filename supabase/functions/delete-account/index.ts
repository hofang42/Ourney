// delete-account (FR-A4, NFR-4): permanently deletes the caller's account.
//   1. authenticate the caller from their own JWT (Authorization: Bearer <access token>)
//   2. remove every storage object of the user (public.account_media_paths lists the real
//      objects in bucket `media`: avatars/{uid}/*, checkins/*/{uid}/*, and all media of
//      journeys that die with the account), then every chat image in bucket `messages`
//      (public.account_message_paths: images the user sent, every image of the user's
//      conversations, and of conversations of journeys that die with the account).
//      The lists are captured first (they depend on rows that cascade away) and every path is
//      queued in private.pending_storage_purge (migration 0017); then the auth user is deleted
//      (after detaching storage.objects.owner), the objects are removed and dequeued one by one,
//      and a second listing pass runs. Whatever is left stays queued for the storage-purge-sweep
//      function. Deploy migrations 0016 (adds account_message_paths) and 0017 before this function.
//   3. auth.admin.deleteUser -> cascades to public.profiles; the profiles BEFORE DELETE trigger
//      hands group ownership to the earliest joined member / archives empty groups and
//      deletes journeys nobody else is active in. Everything else cascades.
// The service key comes only from the function environment.
//
// v2: deletion is gated by a one-time code (3-step flow: confirm -> OTP -> final). The request body
// selects the step:
//   {"action":"send"}                  -> sends a fresh Supabase Auth OTP to the account's own email
//                                         (or phone when it has no email). Nothing is deleted.
//   {"action":"delete","code":"123456"} -> verifies that code server-side (the caller's identity is
//                                         re-checked against the verified user), then deletes.
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

/** Lists every object the RPC reports for the user. Must run BEFORE the auth user is deleted:
 *  the listing joins tables (journeys dying with the account, conversations) that cascade away. */
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

/** The deletion was abandoned before the account was touched: drop only THIS user's queued paths. */
async function abortPaths(admin: SupabaseClient, bucket: string, userId: string, paths: string[]) {
  for (const part of chunk(paths, 500)) {
    try {
      const { error } = await admin.rpc("abort_storage_purge", { p_bucket: bucket, p_user: userId, p_paths: part });
      if (error) console.error(`abort_storage_purge failed (${bucket}, ${part.length} paths)`, error.message);
    } catch (e) {
      console.error("abort_storage_purge threw", e instanceof Error ? e.message : String(e));
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

Deno.serve(async (req: Request): Promise<Response> => {
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

  let body: { action?: string; code?: string } = {};
  try {
    body = await req.json();
  } catch {
    body = {};
  }
  const email = userData.user?.email ?? "";
  const phone = userData.user?.phone ?? "";
  if (!email && !phone) return json({ error: "invalid" }, 400);

  if (body.action === "send") {
    const anon = anonClient();
    const { error } = email
      ? await anon.auth.signInWithOtp({ email, options: { shouldCreateUser: false } })
      : await anon.auth.signInWithOtp({ phone, options: { shouldCreateUser: false } });
    if (error) {
      console.error("delete otp send failed", error.message);
      return authFailure(error.message, error.status);
    }
    return json({ sent: true, channel: email ? "email" : "sms" });
  }

  const code = typeof body.code === "string" ? body.code.trim() : "";
  if (body.action !== "delete" || !/^\d{6}$/.test(code)) return json({ error: "invalid" }, 400);
  {
    const anon = anonClient();
    const { data, error } = email
      ? await anon.auth.verifyOtp({ email, token: code, type: "email" })
      : await anon.auth.verifyOtp({ phone, token: code, type: "sms" });
    if (error || data?.user?.id !== userId) {
      console.warn("delete code check failed", error ? `${error.status ?? "?"} ${error.message}` : "user mismatch");
      return authFailure(error?.message, error?.status);
    }
  }

  const lists: [string, string[]][] = [];
  for (const [rpc, bucket] of [
    ["account_media_paths", "media"],
    ["account_message_paths", "messages"],
  ] as const) {
    const result = await listPaths(admin, rpc, userId);
    if ("error" in result) return result.error;
    lists.push([bucket, result.paths]);
  }

  // getUser just proved the account is alive, so any queued row stamped with this user is stale
  // (an earlier aborted run) and must not become claimable later: start from a clean slate.
  {
    const cleared = await admin.rpc("clear_storage_purge_for_user", { p_user: userId });
    if (cleared.error) {
      console.error("clear_storage_purge_for_user failed", cleared.error.message);
      return json({ error: "storage_cleanup_failed" }, 500);
    }
  }

  // Queue EVERY listed path before touching the account: a crash or timeout from here on leaves
  // all of them for the sweep (which only claims paths of accounts that no longer exist).
  for (const [bucket, list] of lists) {
    if (!(await queuePaths(admin, bucket, userId, list))) {
      for (const [b, l] of lists) await abortPaths(admin, b, userId, l);
      return json({ error: "storage_cleanup_failed" }, 500);
    }
  }

  // storage.objects.owner may reference auth.users depending on the Storage version: detach it
  // first so deleteUser cannot be blocked by existing objects (they are removed below).
  const detach = await admin.rpc("detach_account_storage_owner", { p_user: userId });
  if (detach.error) console.error("detach_account_storage_owner failed", detach.error.message);

  // Delete the auth user before removing storage. If it fails nothing was removed and a retry is
  // safe; the queued paths stay (the sweep never claims paths of an account that still exists, and
  // the retry re-stamps them), so a deleteUser that actually went through despite the error still
  // gets its storage purged.
  const { error: deleteError } = await admin.auth.admin.deleteUser(userId);
  if (deleteError) {
    console.error("deleteUser failed", deleteError.message);
    return json({ error: "delete_failed" }, 500);
  }
  let removed = 0;
  for (const [bucket, list] of lists) removed += await removePaths(admin, bucket, list);

  // Second pass: files uploaded between the first listing and deleteUser. The folder-based
  // listings (avatars/{uid}, checkins/*/{uid}) still resolve after the user is gone.
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
});
