import { createClient } from "npm:@supabase/supabase-js@2.117.2";
import { handle } from "./index.ts";

function assertEquals(actual: unknown, expected: unknown, field: string): void {
  if (actual !== expected) {
    throw new Error(
      `${field}: expected ${JSON.stringify(expected)}, got ${
        JSON.stringify(actual)
      }`,
    );
  }
}

Deno.test("public-journey redacts metrics and the follow frame on an existing link", async () => {
  const baseUrl = "https://public-journey.example.test";
  const publicToken = "a".repeat(40);
  const publicUrl =
    `${baseUrl}/functions/v1/public-journey?token=${publicToken}`;
  const journeyId = "11111111-1111-4111-8111-111111111111";
  const ownerId = "22222222-2222-4222-8222-222222222222";
  const checkInId = "33333333-3333-4333-8333-333333333333";
  const metricName = "Progress";
  const metricUnit = "lbs";
  const metricValue = 167.25;
  const membership = { user_id: ownerId, hide_metric: false, blur_media: true };
  const journey = {
    id: journeyId,
    owner_id: ownerId,
    public_token: publicToken,
    kind: "solo",
    template_id: "custom",
    title: "Daily log",
    emoji: "",
    metric_name: metricName,
    metric_unit: metricUnit,
    start_date: "2026-01-01",
    duration_days: 30,
    timezone: "UTC",
    status: "ended",
    origin: "imported",
    layout: null,
    color: null,
    cover: null,
    story_title: null,
    story_intro: null,
    story_lessons: null,
    cover_checkin_id: checkInId,
    show_counts: false,
  };
  const tableRows: Record<string, Record<string, unknown>[]> = {
    journeys: [journey],
    memberships: [membership],
    journey_share_consents: [],
    profiles: [{ display_name: "Test owner" }],
    check_ins: [{
      id: checkInId,
      user_id: ownerId,
      local_date: "2026-01-01",
      captured_at: "2026-01-01T08:00:00Z",
      caption: null,
      from_library: false,
      photo_path: "photo.jpg",
      thumb_path: "thumb.jpg",
    }],
    check_in_metrics: [{ checkin_id: checkInId, metric_value: metricValue }],
  };

  // Keep the real handler and Supabase query builder, with fixture rows at the HTTP boundary.
  const client = createClient(baseUrl, "local-test-key", {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
    global: {
      fetch: (input, init) => {
        const url = new URL(new Request(input, init).url);
        if (url.pathname === "/rest/v1/rpc/record_journey_view") {
          return Promise.resolve(Response.json(null));
        }

        const table = url.pathname.slice("/rest/v1/".length);
        const rows = tableRows[table];
        const columns = url.searchParams.get("select")?.split(",");
        if (!rows || !columns) {
          throw new Error(`Unexpected Supabase request: ${url}`);
        }
        if (table === "journeys") {
          assertEquals(
            url.searchParams.get("public_token"),
            `eq.${journey.public_token}`,
            "token filter",
          );
        }
        if (table === "memberships") {
          assertEquals(
            url.searchParams.get("journey_id"),
            `eq.${journeyId}`,
            "membership filter",
          );
        }
        return Promise.resolve(
          Response.json(
            rows.map((row) =>
              Object.fromEntries(columns.map((column) => [column, row[column]]))
            ),
          ),
        );
      },
    },
  });
  const deps = { createAdmin: () => client, viewSalt: "" };

  for (const hideMetric of [false, true]) {
    membership.hide_metric = hideMetric;
    const response = await handle(new Request(publicUrl), deps);
    assertEquals(response.status, 200, "status");
    assertEquals(
      response.headers.get("Cache-Control"),
      "no-store",
      "cache policy",
    );

    const body = await response.json();
    assertEquals(body.journey.title, journey.title, "journey title");
    assertEquals(body.check_ins.length, 1, "visible check-ins");
    assertEquals(body.check_ins[0].checkin_id, checkInId, "check-in ID");
    assertEquals(body.can_follow, true, "can follow");
    assertEquals(
      body.frame.source_journey_id,
      journeyId,
      "follow frame source",
    );
    assertEquals(
      body.check_ins[0].metric_value,
      hideMetric ? null : metricValue,
      "check-in metric value",
    );
    assertEquals(
      body.journey.metric_name,
      hideMetric ? null : metricName,
      "journey metric label",
    );
    assertEquals(
      body.journey.metric_unit,
      hideMetric ? null : metricUnit,
      "journey metric unit",
    );
    assertEquals(
      body.frame.metric_name,
      hideMetric ? null : metricName,
      "follow frame metric label",
    );
    assertEquals(
      body.frame.metric_unit,
      hideMetric ? null : metricUnit,
      "follow frame metric unit",
    );
  }
});
