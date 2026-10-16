// Shared helpers for Edge Functions. The service key is read from the environment that
// Supabase injects into every function (never from the repo, never sent to clients).
// Docs: https://supabase.com/docs/guides/functions/secrets#default-secrets
import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2.117.2";

function secretKey(): string {
  // New-style keys first (SUPABASE_SECRET_KEYS = {"default": "sb_secret_..."}), then legacy.
  const raw = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (raw) {
    try {
      const key = (JSON.parse(raw) as Record<string, string>)["default"];
      if (key) return key;
    } catch {
      // fall through to the legacy variable
    }
  }
  const legacy = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!legacy) throw new Error("service key missing from environment");
  return legacy;
}

/** Client that bypasses RLS. Only use it after authorising the request yourself. */
export function adminClient(): SupabaseClient {
  const url = Deno.env.get("SUPABASE_URL");
  if (!url) throw new Error("SUPABASE_URL missing from environment");
  return createClient(url, secretKey(), {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
  });
}

export function json(body: unknown, status = 200, headers: HeadersInit = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
      ...headers,
    },
  });
}

export function chunk<T>(items: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += size) out.push(items.slice(i, i + size));
  return out;
}
