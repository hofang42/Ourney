// Unit tests for supabase/functions/admin-action/index.ts
// Run: deno test supabase/functions/admin-action/index_test.ts
import { type AdminIdentity, handle, sha256Hex } from "./index.ts";
import type { SupabaseClient } from "npm:@supabase/supabase-js@2.117.2";

function assert(cond: unknown, msg = "assertion failed"): asserts cond {
  if (!cond) throw new Error(msg);
}

function assertEquals<T>(actual: T, expected: T, msg = ""): void {
  const a = JSON.stringify(actual);
  const b = JSON.stringify(expected);
  if (a !== b) {
    throw new Error(`${msg ? msg + ": " : ""}expected ${b}, got ${a}`);
  }
}

const OWNER_ADMIN: AdminIdentity = {
  user_id: "11111111-1111-4111-8111-111111111111",
  email: "owner@ourney.tech",
  role: "owner",
  username: "owner",
};

const MOD_ADMIN: AdminIdentity = {
  user_id: "22222222-2222-4222-8222-222222222222",
  email: "mod@ourney.tech",
  role: "moderator",
  username: "mod",
};

const TARGET_USER_ID = "33333333-3333-4333-8333-333333333333";
const WAITLIST_ID = "44444444-4444-4444-8444-444444444444";

type RecordedRpc = { fn: string; args: Record<string, unknown> };

function makeMockService(options: {
  waitlistTargets?: unknown[];
  claimedPurge?: { bucket: string; path: string }[];
  claimedModeration?: unknown[];
  targetUserEmail?: string | null;
  deleteUserError?: { message: string } | null;
} = {}) {
  const rpcs: RecordedRpc[] = [];
  const removedStorage: { bucket: string; paths: string[] }[] = [];
  let purgeConsumed = false;

  const client = {
    rpc: (fn: string, args: Record<string, unknown> = {}) => {
      rpcs.push({ fn, args });
      if (fn === "admin_service_get_waitlist_targets") {
        return Promise.resolve({ data: options.waitlistTargets ?? [], error: null });
      }
      if (fn === "claim_storage_purge") {
        if (purgeConsumed) return Promise.resolve({ data: [], error: null });
        purgeConsumed = true;
        return Promise.resolve({ data: options.claimedPurge ?? [], error: null });
      }
      if (fn === "claim_moderation_notifications") {
        return Promise.resolve({ data: options.claimedModeration ?? [], error: null });
      }
      if (fn === "account_media_paths" || fn === "account_message_paths") {
        return Promise.resolve({ data: [], error: null });
      }
      return Promise.resolve({ data: 1, error: null });
    },
    storage: {
      from: (bucket: string) => ({
        remove: (paths: string[]) => {
          removedStorage.push({ bucket, paths });
          return Promise.resolve({ data: paths, error: null });
        },
      }),
    },
    auth: {
      admin: {
        getUserById: (uid: string) => {
          if (options.targetUserEmail === null) {
            return Promise.resolve({
              data: { user: null },
              error: { status: 404, code: "user_not_found", message: "not found" },
            });
          }
          return Promise.resolve({
            data: { user: { id: uid, email: options.targetUserEmail ?? "victim@example.test" } },
            error: null,
          });
        },
        deleteUser: (_uid: string) => {
          return Promise.resolve({ data: {}, error: options.deleteUserError ?? null });
        },
      },
    },
  } as unknown as SupabaseClient;

  return { client, rpcs, removedStorage };
}

Deno.test("admin-action: OPTIONS returns 204 with CORS headers for allowed origin", async () => {
  const req = new Request("https://example.supabase.co/functions/v1/admin-action", {
    method: "OPTIONS",
    headers: { Origin: "https://admin.ourney.tech" },
  });
  const res = await handle(req);
  assertEquals(res.status, 204);
  assertEquals(res.headers.get("Access-Control-Allow-Origin"), "https://admin.ourney.tech");
});

Deno.test("admin-action: missing Bearer token returns 401 unauthenticated", async () => {
  const req = new Request("https://example.supabase.co/functions/v1/admin-action", {
    method: "POST",
    body: JSON.stringify({ action: "run_storage_sweep" }),
  });
  const res = await handle(req);
  assertEquals(res.status, 401);
  assertEquals(await res.json(), { error: "unauthenticated" });
});

Deno.test("admin-action: non-admin caller rejected by admin.me() returns 403 forbidden", async () => {
  const req = new Request("https://example.supabase.co/functions/v1/admin-action", {
    method: "POST",
    headers: { Authorization: "Bearer user-jwt" },
    body: JSON.stringify({ action: "run_storage_sweep" }),
  });
  const res = await handle(req, {
    verifyAdmin: () => Promise.resolve({ status: 403, error: "forbidden" }),
  });
  assertEquals(res.status, 403);
  assertEquals(await res.json(), { error: "forbidden" });
});

Deno.test("admin-action: waitlist_resend sends Resend email, marks confirmation, and audits", async () => {
  const mock = makeMockService({
    waitlistTargets: [
      {
        id: WAITLIST_ID,
        email: "beta@example.test",
        lang: "vi",
        platforms: ["ios", "android"],
        source: "landing",
        confirmation_sent_at: null,
        confirmation_error: "resend_500",
      },
    ],
  });

  let resendCalls = 0;
  const req = new Request("https://example.supabase.co/functions/v1/admin-action", {
    method: "POST",
    headers: { Authorization: "Bearer mod-jwt" },
    body: JSON.stringify({ action: "waitlist_resend", waitlist_id: WAITLIST_ID }),
  });

  const res = await handle(req, {
    verifyAdmin: () => Promise.resolve({ admin: MOD_ADMIN }),
    serviceClient: () => mock.client,
    envGet: (k: string) => {
      if (k === "RESEND_API_KEY") return "re_test_key";
      if (k === "WAITLIST_FROM") return "Ourney <hello@ourney.tech>";
      return undefined;
    },
    fetchFn: (() => {
      resendCalls += 1;
      return Promise.resolve(new Response(JSON.stringify({ id: "msg_1" }), { status: 200 }));
    }) as typeof fetch,
  });

  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body, { ok: true, attempted: 1, sent: 1, failed: 0, errors: [] });
  assertEquals(resendCalls, 1);

  const markCall = mock.rpcs.find((r) => r.fn === "waitlist_mark_confirmation");
  assert(markCall, "expected waitlist_mark_confirmation call");
  assertEquals(markCall.args.p_id, WAITLIST_ID);
  assertEquals(markCall.args.p_error, null);

  const auditCall = mock.rpcs.find((r) => r.fn === "admin_service_record_audit");
  assert(auditCall, "expected admin_service_record_audit call");
  assertEquals(auditCall.args.p_action, "waitlist.resend_confirmation");
});

Deno.test("admin-action: moderator is denied (403) on owner-only delete_user", async () => {
  const mock = makeMockService();
  const req = new Request("https://example.supabase.co/functions/v1/admin-action", {
    method: "POST",
    headers: { Authorization: "Bearer mod-jwt" },
    body: JSON.stringify({
      action: "delete_user",
      user_id: TARGET_USER_ID,
      reason: "user erasure ticket #101",
    }),
  });

  const res = await handle(req, {
    verifyAdmin: () => Promise.resolve({ admin: MOD_ADMIN }),
    serviceClient: () => mock.client,
  });

  assertEquals(res.status, 403);
  assertEquals(await res.json(), { error: "forbidden" });
});

Deno.test("admin-action: owner delete_user detaches storage, deletes auth user, drains purge, and logs sha256(email)", async () => {
  const mock = makeMockService({
    targetUserEmail: "EraseMe@Example.test",
    claimedPurge: [
      { bucket: "media", path: `checkins/j1/${TARGET_USER_ID}/c1.jpg` },
      { bucket: "media", path: `checkins/j1/${TARGET_USER_ID}/c1_t.jpg` },
    ],
  });

  const req = new Request("https://example.supabase.co/functions/v1/admin-action", {
    method: "POST",
    headers: { Authorization: "Bearer owner-jwt" },
    body: JSON.stringify({
      action: "delete_user",
      user_id: TARGET_USER_ID,
      reason: "Decree 13 / GDPR verified deletion request",
      ticket_ref: "SUP-42",
    }),
  });

  const res = await handle(req, {
    verifyAdmin: () => Promise.resolve({ admin: OWNER_ADMIN }),
    serviceClient: () => mock.client,
  });

  assertEquals(res.status, 200);
  const body = await res.json();
  const expectedHash = await sha256Hex("eraseme@example.test");
  assertEquals(body, {
    ok: true,
    deleted: true,
    user_id: TARGET_USER_ID,
    email_sha256: expectedHash,
    removed_objects: 2,
  });

  assert(mock.rpcs.some((r) => r.fn === "detach_account_storage_owner"), "detach_account_storage_owner called");
  assert(mock.rpcs.some((r) => r.fn === "finish_storage_purge"), "finish_storage_purge called");

  const auditCall = mock.rpcs.find((r) => r.fn === "admin_service_record_audit");
  assert(auditCall, "audit recorded");
  assertEquals(auditCall.args.p_action, "users.delete_on_request");
  assertEquals((auditCall.args.p_meta as Record<string, unknown>).email_sha256, expectedHash);
  assert(
    !JSON.stringify(auditCall.args).toLowerCase().includes("eraseme@example.test"),
    "plaintext email must never appear in audit args",
  );
});

Deno.test("admin-action: run_storage_sweep and trigger_moderation_notify execute and audit", async () => {
  const mock = makeMockService({
    claimedPurge: [{ bucket: "messages", path: "messages/conv1/u1/m1.jpg" }],
    claimedModeration: [
      {
        id: "55555555-5555-4555-8555-555555555555",
        kind: "report",
        report_id: null,
        status: "open",
        reason: "spam",
        note: "spam note",
        created_at: "2026-11-24T00:00:00Z",
        due_at: "2026-11-25T00:00:00Z",
        actor_id: null,
        target_user_id: TARGET_USER_ID,
        target_checkin_id: null,
        target_message_id: null,
      },
    ],
  });

  const sweepReq = new Request("https://example.supabase.co/functions/v1/admin-action", {
    method: "POST",
    headers: { Authorization: "Bearer mod-jwt" },
    body: JSON.stringify({ action: "run_storage_sweep" }),
  });
  const sweepRes = await handle(sweepReq, {
    verifyAdmin: () => Promise.resolve({ admin: MOD_ADMIN }),
    serviceClient: () => mock.client,
  });
  assertEquals(sweepRes.status, 200);
  assertEquals(await sweepRes.json(), { ok: true, claimed: 1, removed: 1, failed: 0 });

  const notifyReq = new Request("https://example.supabase.co/functions/v1/admin-action", {
    method: "POST",
    headers: { Authorization: "Bearer mod-jwt" },
    body: JSON.stringify({ action: "trigger_moderation_notify" }),
  });
  const notifyRes = await handle(notifyReq, {
    verifyAdmin: () => Promise.resolve({ admin: MOD_ADMIN }),
    serviceClient: () => mock.client,
    envGet: (k: string) => (k === "MODERATION_WEBHOOK_URL" ? "https://api.resend.com/emails" : undefined),
    fetchFn: (() => Promise.resolve(new Response("{}", { status: 200 }))) as typeof fetch,
  });
  assertEquals(notifyRes.status, 200);
  assertEquals(await notifyRes.json(), {
    ok: true,
    claimed: 1,
    notified: 1,
    configured: true,
    recipient: "support@ourney.tech",
  });
});
