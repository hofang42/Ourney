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

Deno.test("public-journey resolves both links with the same privacy rules and revokes both", async () => {
  const baseUrl = "https://public-journey.example.test";
  const publicToken = "a".repeat(40);
  const publicSlug = "7-ngay-da-lat-k3f2x7d6yk3gp5tb";
  const recordedViewerKeys: string[] = [];
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
    public_token: publicToken as string | null,
    public_slug: publicSlug,
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
      fetch: async (input, init) => {
        const request = new Request(input, init);
        const url = new URL(request.url);
        if (url.pathname === "/rest/v1/rpc/lookup_public_journey_for_edge") {
          const { p_token, p_ip_hash } = await request.json();
          assertEquals(request.method, "POST", "quota update method");
          assertEquals(p_ip_hash, null, "missing Cloudflare IP uses the SQL fallback");
          return Response.json({
            journey: journey.public_token !== null &&
                (p_token === journey.public_token || p_token === journey.public_slug)
              ? journey
              : null,
            retry_after: 0,
          });
        }
        if (url.pathname === "/rest/v1/rpc/record_journey_view") {
          const { p_viewer_key } = await request.json();
          recordedViewerKeys.push(p_viewer_key);
          return Response.json(null);
        }

        const table = url.pathname.slice("/rest/v1/".length);
        const rows = tableRows[table];
        const columns = url.searchParams.get("select")?.split(",");
        if (!rows || !columns) {
          throw new Error(`Unexpected Supabase request: ${url}`);
        }
        if (table === "memberships") {
          assertEquals(
            url.searchParams.get("journey_id"),
            `eq.${journeyId}`,
            "membership filter",
          );
        }
        return Response.json(
          rows.map((row) =>
            Object.fromEntries(columns.map((column) => [column, row[column]]))
          ),
        );
      },
    },
  });
  const deps = { createAdmin: () => client, viewSalt: "" };
  const openLink = (identifier: string) =>
    handle(
      new Request(`${baseUrl}/functions/v1/public-journey?token=${identifier}`),
      deps,
    );

  for (const [identifier, hideMetric] of [
    [publicToken, false],
    [publicSlug, false],
    [publicToken, true],
    [publicSlug, true],
  ] as const) {
    membership.hide_metric = hideMetric;
    const response = await openLink(identifier);
    assertEquals(response.status, 200, "status");
    assertEquals(
      response.headers.get("Cache-Control"),
      "no-store",
      "cache policy",
    );

    const json = await response.text();
    assertEquals(json.includes(publicToken), false, "token stays out of payload");
    assertEquals(json.includes(publicSlug), false, "slug stays out of payload");
    const body = JSON.parse(json);
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

  assertEquals(recordedViewerKeys.length, 4, "recorded view count");
  assertEquals(
    recordedViewerKeys[0],
    recordedViewerKeys[1],
    "legacy and readable links deduplicate the same viewer",
  );

  for (const identifier of ["b".repeat(40), `missing-${"b".repeat(16)}`]) {
    const response = await openLink(identifier);
    assertEquals(response.status, 404, "unknown link status");
    assertEquals((await response.json()).error, "not_found", "unknown link body");
  }

  journey.public_token = null;
  for (const identifier of [publicToken, publicSlug]) {
    const response = await openLink(identifier);
    assertEquals(response.status, 404, "revoked link status");
    assertEquals((await response.json()).error, "not_found", "revoked link body");
  }
  assertEquals(recordedViewerKeys.length, 4, "failed links do not record views");
});

Deno.test("public-journey rejects missing and malformed identifiers before lookup", async () => {
  const baseUrl = "https://public-journey.example.test/functions/v1/public-journey";
  const deps = {
    createAdmin: () => {
      throw new Error("Invalid requests must not create an admin client");
    },
  };
  const invalidQueries = [
    "",
    "?token=",
    "?token=too-short",
    `?token=title-${"0".repeat(16)}`,
    `?token=${"a".repeat(24)}-${"b".repeat(16)}`,
    `?token=${"a".repeat(40)}%0A`,
  ];

  for (const query of invalidQueries) {
    const response = await handle(new Request(`${baseUrl}${query}`), deps);
    assertEquals(response.status, 404, "invalid link status");
    assertEquals((await response.json()).error, "not_found", "invalid link body");
  }
});

Deno.test("public-journey returns a non-cacheable 429 before loading journey data", async () => {
  let lookupCalls = 0;
  let tableCalls = 0;
  const client = {
    rpc(name: string) {
      assertEquals(name, "lookup_public_journey_for_edge", "lookup RPC");
      lookupCalls++;
      return Promise.resolve({ data: { retry_after: 17, journey: null }, error: null });
    },
    from() {
      tableCalls++;
      return {
        select: () => ({
          eq: () => ({
            is: () => ({ maybeSingle: () => Promise.resolve({ data: null, error: null }) }),
          }),
        }),
      };
    },
  } as unknown as ReturnType<typeof createClient>;
  const response = await handle(
    new Request(`https://public-journey.example.test/?token=${"a".repeat(40)}`),
    { createAdmin: () => client },
  );
  assertEquals(response.status, 429, "throttled status");
  assertEquals(response.headers.get("Retry-After"), "17", "window reset");
  assertEquals(response.headers.get("Access-Control-Expose-Headers"), "Retry-After", "browser retry header");
  assertEquals(response.headers.get("Cache-Control"), "no-store", "cache policy");
  assertEquals((await response.json()).error, "rate_limited", "throttled body");
  assertEquals(lookupCalls, 1, "one database round trip");
  assertEquals(tableCalls, 0, "no downstream table calls");
});

Deno.test("public-journey sends only a keyed hash of the Cloudflare ingress IP", async () => {
  const hashes: (string | null)[] = [];
  const client = {
    rpc(_name: string, { p_ip_hash }: { p_ip_hash: string | null }) {
      hashes.push(p_ip_hash);
      return Promise.resolve({ data: { retry_after: 0, journey: null }, error: null });
    },
  } as unknown as ReturnType<typeof createClient>;
  const url = `https://public-journey.example.test/?token=${"a".repeat(40)}`;
  const cases: Record<string, string>[] = [
    { "cf-connecting-ip": "2001:db8::7", "x-forwarded-for": "203.0.113.8" },
    { "cf-connecting-ip": "2001:0db8:0:0:0:0:0:0007", "x-real-ip": "203.0.113.9" },
    { "cf-connecting-ip": "198.51.100.25" },
    { "x-forwarded-for": "203.0.113.8", "x-real-ip": "203.0.113.9" },
    { "cf-connecting-ip": "198.51.100.1, 198.51.100.2" },
    { "cf-connecting-ip": "2a06:98c0:3600:0:0:0:0:103" },
  ];
  for (const headers of cases) {
    await handle(new Request(url, { headers }), {
      createAdmin: () => client,
      rateLimitSecret: "test-key",
    });
  }
  await handle(new Request(url, { headers: cases[0] }), {
    createAdmin: () => client,
    rateLimitSecret: "different-key",
  });
  assertEquals(/^[a-f0-9]{64}$/.test(hashes[0] ?? ""), true, "SHA-256 HMAC output");
  assertEquals(hashes[0], hashes[1], "same IP across IPv6 spellings and forwarding values");
  assertEquals(hashes[0] === hashes[2], false, "separate IP buckets");
  assertEquals(hashes[3], null, "no caller-supplied forwarding fallback");
  assertEquals(hashes[4], null, "reject a list instead of a single IP");
  assertEquals(hashes[5], null, "the shared Cloudflare Worker address is not a client IP");
  assertEquals(hashes[0] === hashes[6], false, "hash depends on the server key");
});

Deno.test("public-journey never falls back to an unthrottled lookup if the RPC fails", async () => {
  const client = {
    rpc: () => Promise.resolve({ data: null, error: { code: "PGRST202" } }),
    from: () => { throw new Error("Lookup must stop when the limiter is unavailable"); },
  } as unknown as ReturnType<typeof createClient>;
  const response = await handle(
    new Request(`https://public-journey.example.test/?token=${"a".repeat(40)}`),
    { createAdmin: () => client },
  );
  assertEquals(response.status, 500, "unavailable limiter status");
  assertEquals((await response.json()).error, "internal", "generic error body");
});

import "../waitlist-signup/index_test.ts";
import "../notify-moderation/index_test.ts";
