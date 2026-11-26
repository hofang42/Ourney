// Unit tests for supabase/functions/notify-moderation/index.ts (F-44)
// Run: deno test supabase/functions/notify-moderation/index_test.ts
import type { SupabaseClient } from "npm:@supabase/supabase-js@2.117.2";
import { formatModerationDigest, handle, type ModerationQueueItem } from "./index.ts";

function assert(cond: unknown, msg: string): void {
  if (!cond) throw new Error(msg);
}

function assertEquals(actual: unknown, expected: unknown, field: string): void {
  if (actual !== expected) {
    throw new Error(`${field}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

Deno.test("formatModerationDigest labels feature_request reports accurately with title and body excerpt", () => {
  const items: ModerationQueueItem[] = [
    {
      id: "11111111-1111-4111-8111-111111111111",
      kind: "report",
      report_id: "22222222-2222-4222-8222-222222222222",
      status: "open",
      reason: "spam",
      note: "reporter note",
      created_at: "2026-11-26T00:00:00Z",
      due_at: "2026-11-27T00:00:00Z",
      actor_id: "33333333-3333-4333-8333-333333333333",
      target_user_id: "44444444-4444-4444-8444-444444444444",
      target_username: "author_handle",
      target_checkin_id: null,
      target_message_id: null,
      target_feature_request_id: "55555555-5555-4555-8555-555555555555",
      feature_request_title: "Add dark mode widgets",
      feature_request_body: "Please support dark mode on home screen widgets",
      distinct_open_reporters: 2,
    },
  ];

  const digest = formatModerationDigest(items);
  assert(
    digest.text.includes("feature_request=55555555-5555-4555-8555-555555555555"),
    "digest must label target as feature_request=<id>",
  );
  assert(
    !digest.text.includes("user=44444444-4444-4444-8444-444444444444"),
    "digest must not mislabel feature_request report as user=<id>",
  );
  assert(
    digest.text.includes('Add dark mode widgets: Please support dark mode on home screen widgets'),
    "digest must include feature request title and body in excerpt",
  );
});

Deno.test("notify-moderation passes timeout signal to webhook fetch and confirms delivery", async () => {
  let receivedSignal: AbortSignal | null | undefined;
  const confirmedIds: string[][] = [];

  const mockAdmin = {
    rpc(fn: string, args: Record<string, unknown>) {
      if (fn === "claim_moderation_notifications") {
        return Promise.resolve({
          data: [
            {
              id: "11111111-1111-4111-8111-111111111111",
              kind: "report",
              report_id: null,
              status: "open",
              reason: "spam",
              note: null,
              created_at: "2026-11-26T00:00:00Z",
              due_at: "2026-11-27T00:00:00Z",
              actor_id: null,
              target_user_id: "44444444-4444-4444-8444-444444444444",
              target_checkin_id: null,
              target_message_id: null,
              target_feature_request_id: "55555555-5555-4555-8555-555555555555",
              feature_request_title: "Spam title",
              feature_request_body: "Spam body",
            },
          ],
          error: null,
        });
      }
      if (fn === "confirm_moderation_notifications") {
        confirmedIds.push(args.p_ids as string[]);
        return Promise.resolve({ data: 1, error: null });
      }
      return Promise.resolve({ data: 0, error: null });
    },
  } as unknown as SupabaseClient;

  const response = await handle(
    new Request("https://moderation.example.test/functions/v1/notify-moderation", {
      method: "POST",
      headers: {
        "x-moderation-token": "mod-secret-token",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ limit: 10 }),
    }),
    {
      createAdmin: () => mockAdmin,
      envGet: (key: string) => {
        if (key === "MODERATION_WEBHOOK_TOKEN") return "mod-secret-token";
        if (key === "MODERATION_WEBHOOK_URL") return "https://api.resend.com/emails";
        return undefined;
      },
      fetchFn: ((_input: RequestInfo | URL, init?: RequestInit) => {
        receivedSignal = init?.signal;
        return Promise.resolve(new Response(JSON.stringify({ id: "email_1" }), { status: 200 }));
      }) as typeof fetch,
    },
  );

  assertEquals(response.status, 200, "notify status");
  const body = await response.json();
  assertEquals(body.notified, 1, "notified count");
  assert(receivedSignal instanceof AbortSignal, "webhook fetch must attach an AbortSignal timeout");
  assertEquals(confirmedIds.length, 1, "confirm_moderation_notifications called once");
});
