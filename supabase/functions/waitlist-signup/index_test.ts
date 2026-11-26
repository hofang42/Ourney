// Unit tests for supabase/functions/waitlist-signup/index.ts (F-05)
// Run: deno test supabase/functions/waitlist-signup/index_test.ts
import type { SupabaseClient } from "npm:@supabase/supabase-js@2.117.2";
import { handle, rateLimitIpHash } from "./index.ts";

function assertEquals(actual: unknown, expected: unknown, field: string): void {
  if (actual !== expected) {
    throw new Error(`${field}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

Deno.test("waitlist-signup ignores spoofed X-Forwarded-For and X-Real-IP, hashing only cf-connecting-ip", async () => {
  const secret = "waitlist-test-secret";
  const req1 = new Request("https://waitlist.example.test/functions/v1/waitlist-signup", {
    method: "POST",
    headers: {
      "cf-connecting-ip": "2001:db8::42",
      "x-forwarded-for": "198.51.100.1, 203.0.113.5",
      "x-real-ip": "198.51.100.2",
    },
  });
  const req2 = new Request("https://waitlist.example.test/functions/v1/waitlist-signup", {
    method: "POST",
    headers: {
      "cf-connecting-ip": "2001:0db8:0:0:0:0:0:0042",
      "x-forwarded-for": "203.0.113.99",
      "x-real-ip": "203.0.113.100",
    },
  });
  const reqSpoofOnly = new Request("https://waitlist.example.test/functions/v1/waitlist-signup", {
    method: "POST",
    headers: {
      "x-forwarded-for": "203.0.113.77",
      "x-real-ip": "203.0.113.78",
    },
  });
  const reqWorkerEgress = new Request("https://waitlist.example.test/functions/v1/waitlist-signup", {
    method: "POST",
    headers: {
      "cf-connecting-ip": "2a06:98c0:3600:0:0:0:0:103",
      "x-forwarded-for": "203.0.113.88",
    },
  });

  const hash1 = await rateLimitIpHash(req1, secret);
  const hash2 = await rateLimitIpHash(req2, secret);
  const hashOtherSecret = await rateLimitIpHash(req1, "other-secret");
  const hashSpoofOnly = await rateLimitIpHash(reqSpoofOnly, secret);
  const hashWorker = await rateLimitIpHash(reqWorkerEgress, secret);

  assertEquals(/^[0-9a-f]{64}$/.test(hash1 ?? ""), true, "valid 64-char hex HMAC");
  assertEquals(hash1, hash2, "forged X-Forwarded-For cannot alter cf-connecting-ip bucket");
  assertEquals(hash1 === hashOtherSecret, false, "HMAC depends on server secret");
  assertEquals(hashSpoofOnly, null, "X-Forwarded-For without cf-connecting-ip falls back to null (SQL fallback bucket)");
  assertEquals(hashWorker, null, "Cloudflare Worker shared egress IP falls back to null (SQL fallback bucket)");
});

Deno.test("waitlist-signup passes keyed cf-connecting-ip hash to RPC and returns 429 on rate_limited without sending mail", async () => {
  const rpcCalls: { fn: string; args: Record<string, unknown> }[] = [];
  let fetchCalls = 0;
  let nextStatus: "created" | "rate_limited" = "created";

  const mockAdmin = {
    rpc(fn: string, args: Record<string, unknown>) {
      rpcCalls.push({ fn, args });
      if (fn === "waitlist_signup") {
        return Promise.resolve({
          data: nextStatus === "created"
            ? { status: "created", id: "11111111-1111-4111-8111-111111111111" }
            : { status: "rate_limited" },
          error: null,
        });
      }
      return Promise.resolve({ data: null, error: null });
    },
  } as unknown as SupabaseClient;

  const deps = {
    createAdmin: () => mockAdmin,
    rateLimitSecret: "test-secret",
    envGet: (key: string) => {
      if (key === "RESEND_API_KEY") return "re_test";
      if (key === "WAITLIST_FROM") return "Ourney <hello@ourney.tech>";
      return undefined;
    },
    fetchFn: (() => {
      fetchCalls++;
      return Promise.resolve(new Response(JSON.stringify({ id: "mail_1" }), { status: 200 }));
    }) as typeof fetch,
  };

  // 1. Created signup with forged X-Forwarded-For + real cf-connecting-ip
  const resCreated = await handle(
    new Request("https://waitlist.example.test/functions/v1/waitlist-signup", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "cf-connecting-ip": "198.51.100.10",
        "x-forwarded-for": "1.2.3.4",
      },
      body: JSON.stringify({ email: "User@Example.test", lang: "en", platforms: ["ios"] }),
    }),
    deps,
  );
  assertEquals(resCreated.status, 200, "created status");
  assertEquals((await resCreated.json()).ok, true, "created body");
  assertEquals(fetchCalls, 1, "one confirmation email sent");

  // 2. Second request with different forged X-Forwarded-For but same cf-connecting-ip hits rate_limited
  nextStatus = "rate_limited";
  const resLimited = await handle(
    new Request("https://waitlist.example.test/functions/v1/waitlist-signup", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "cf-connecting-ip": "198.51.100.10",
        "x-forwarded-for": "5.6.7.8",
      },
      body: JSON.stringify({ email: "User2@Example.test", lang: "en", platforms: ["ios"] }),
    }),
    deps,
  );
  assertEquals(resLimited.status, 429, "rate_limited status");
  assertEquals((await resLimited.json()).error, "rate_limited", "rate_limited error body");
  assertEquals(fetchCalls, 1, "no email sent when rate-limited");

  const signupCalls = rpcCalls.filter((c) => c.fn === "waitlist_signup");
  assertEquals(signupCalls.length, 2, "two waitlist_signup RPC calls");
  assertEquals(
    signupCalls[0].args.p_ip_hash,
    signupCalls[1].args.p_ip_hash,
    "identical p_ip_hash despite different X-Forwarded-For headers",
  );
});
