// storage-purge-sweep: retries the storage removals of deleted accounts that delete-account could
// not finish (private.pending_storage_purge, migration 0017). Service-side only: callers must send
// the shared secret in `x-sweep-token` (function secret SWEEP_TOKEN). Run it on a schedule
// (Supabase Dashboard > Edge Functions > Schedule, or pg_cron + pg_net) or by hand; see
// docs/runbooks/storage-purge.md. Idempotent: removing a missing object is not an error. Rows that
// failed back off and are given up on after 20 attempts, so `claimed` reaches 0.
import { adminClient, chunk, json } from "../_shared/admin.ts";

const BATCH = 200;

async function sha256(input: string): Promise<Uint8Array> {
  return new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(input)));
}

/** Constant-time comparison: hash both sides to equal length, then XOR-accumulate. */
async function sameSecret(given: string, expected: string): Promise<boolean> {
  const [a, b] = await Promise.all([sha256(given), sha256(expected)]);
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
  return diff === 0;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405, { Allow: "POST" });
  const expected = Deno.env.get("SWEEP_TOKEN") ?? "";
  const given = req.headers.get("x-sweep-token") ?? "";
  if (!expected || !(await sameSecret(given, expected))) return json({ error: "unauthenticated" }, 401);

  try {
    const admin = adminClient();
    const { data, error } = await admin.rpc("claim_storage_purge", { p_limit: BATCH });
    if (error) {
      console.error("claim_storage_purge failed", error.message);
      return json({ error: "internal" }, 500);
    }
    const rows = (data ?? []) as { bucket: string; path: string }[];
    const byBucket = new Map<string, string[]>();
    for (const r of rows) byBucket.set(r.bucket, [...(byBucket.get(r.bucket) ?? []), r.path]);

    let removed = 0;
    let failed = 0;
    for (const [bucket, paths] of byBucket) {
      for (const part of chunk(paths, 100)) {
        const { error: removeError } = await admin.storage.from(bucket).remove(part);
        if (removeError) {
          console.error(`sweep remove failed (${bucket}, ${part.length})`, removeError.message);
          failed += part.length;
          const noted = await admin.rpc("fail_storage_purge", {
            p_bucket: bucket,
            p_paths: part,
            p_error: removeError.message,
          });
          if (noted.error) console.error("fail_storage_purge failed", noted.error.message);
          continue;
        }
        const done = await admin.rpc("finish_storage_purge", { p_bucket: bucket, p_paths: part });
        if (done.error) console.error("finish_storage_purge failed", done.error.message);
        removed += part.length;
      }
    }
    return json({ claimed: rows.length, removed, failed });
  } catch (e) {
    console.error("storage-purge-sweep failed", e instanceof Error ? e.message : String(e));
    return json({ error: "internal" }, 500);
  }
});
