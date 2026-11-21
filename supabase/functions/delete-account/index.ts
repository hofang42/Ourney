// delete-account (FR-A4, NFR-4): permanently deletes the caller's account.
//   1. authenticate the caller from their own JWT (Authorization: Bearer <access token>)
//   2. remove every storage object of the user (public.account_media_paths lists the real
//      objects in bucket `media`: avatars/{uid}/*, checkins/*/{uid}/*, and all media of
//      journeys that die with the account), then every chat image in bucket `messages`
//      (public.account_message_paths: images the user sent, every image of the user's
//      conversations, and of conversations of journeys that die with the account).
//      The lists are captured first (they depend on rows that cascade away), the auth user is
//      deleted next, and the objects are removed last, best effort. Deploy migration 0016 (which
//      adds account_message_paths) before this function.
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

/** Best-effort removal after the account is gone: failures are logged, never returned (the
 *  user no longer exists, so the client could not retry anyway). Returns the removed count. */
async function removePaths(admin: SupabaseClient, bucket: string, list: string[]): Promise<number> {
  let removed = 0;
  for (const part of chunk(list, 100)) {
    try {
      const { error } = await admin.storage.from(bucket).remove(part);
      if (error) {
        console.error(`storage remove failed (${bucket}, ${part.length} objects)`, error.message);
        continue;
      }
      removed += part.length;
    } catch (e) {
      console.error(`storage remove threw (${bucket})`, e instanceof Error ? e.message : String(e));
    }
  }
  return removed;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405, { Allow: "POST" });

  const auth = req.headers.get("Authorization") ?? "";
  const token = auth.startsWith("Bearer ") ? auth.slice(7).trim() : "";
  if (!token) return json({ error: "unauthenticated" }, 401);

  const admin = adminClient();
  const { data: userData, error: userError } = await admin.auth.getUser(token);
  const userId = userData?.user?.id;
  if (userError || !userId) return json({ error: "unauthenticated" }, 401);

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

  // Delete the auth user first: if it fails nothing was touched and a retry is safe; once it
  // succeeds the account is gone for good and the storage purge is best effort.
  const { error: deleteError } = await admin.auth.admin.deleteUser(userId);
  if (deleteError) {
    console.error("deleteUser failed", deleteError.message);
    return json({ error: "delete_failed" }, 500);
  }
  let removed = 0;
  for (const [bucket, list] of lists) removed += await removePaths(admin, bucket, list);
  return json({ deleted: true, removed_objects: removed });
});
