// delete-account (FR-A4, NFR-4): permanently deletes the caller's account.
//   1. authenticate the caller from their own JWT (Authorization: Bearer <access token>)
//   2. remove every storage object of the user (public.account_media_paths lists the real
//      objects in bucket `media`: avatars/{uid}/*, checkins/*/{uid}/*, and all media of
//      journeys that die with the account). Repeated until empty, so retries are safe.
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
import { createClient } from "npm:@supabase/supabase-js@2.117.2";
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

const MAX_ROUNDS = 20;

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
    if (error || data?.user?.id !== userId) return authFailure(error?.message, error?.status);
  }

  let removed = 0;
  for (let round = 0; ; round++) {
    const { data: paths, error } = await admin.rpc("account_media_paths", { p_user: userId });
    if (error) {
      console.error("account_media_paths failed", error.message);
      return json({ error: "storage_listing_failed" }, 500);
    }
    const list = (paths ?? []) as string[];
    if (list.length === 0) break;
    if (round >= MAX_ROUNDS) return json({ error: "storage_cleanup_incomplete" }, 500);
    for (const part of chunk(list, 100)) {
      const { error: removeError } = await admin.storage.from("media").remove(part);
      if (removeError) {
        console.error("storage remove failed", removeError.message);
        return json({ error: "storage_cleanup_failed" }, 500);
      }
      removed += part.length;
    }
  }

  const { error: deleteError } = await admin.auth.admin.deleteUser(userId);
  if (deleteError) {
    console.error("deleteUser failed", deleteError.message);
    return json({ error: "delete_failed" }, 500);
  }
  return json({ deleted: true, removed_objects: removed });
});
