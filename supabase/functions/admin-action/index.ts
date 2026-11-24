// admin-action: authenticated admin Edge Function for external side-effects that cannot run inside
// pure PostgreSQL functions (Resend waitlist confirmation retry, owner-only user account deletion
// with Storage bucket cleanup, manual storage-purge sweep, and moderation alert digest trigger).
//
// Security model (admin-spec.md §5.1 & §5.2.5):
//   1. Deployed with `verify_jwt = true` (config.toml + deploy-hosted.sh).
//   2. Verifies the caller's Bearer JWT against `supabase.schema("admin").rpc("me")` using the
//      public anon key + caller Authorization header, so PostgreSQL enforces `private.require_admin`
//      before any service-role operation is touched.
//   3. Enforces role requirements (`owner` for `delete_user`, `moderator` or `owner` for
//      `waitlist_resend`, `run_storage_sweep`, and `trigger_moderation_notify`).
//   4. Writes an immutable `private.admin_audit` record via `public.admin_service_record_audit`
//      (with `sha256(email)` on user erasure, never plaintext email).
import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2.117.2";
import { adminClient, chunk, json } from "../_shared/admin.ts";
import { confirmationEmail } from "../waitlist-signup/index.ts";
import { formatModerationDigest, type ModerationQueueItem } from "../notify-moderation/index.ts";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const RESEND_URL = "https://api.resend.com/emails";
const RESEND_TIMEOUT_MS = 8000;
const WEBHOOK_TIMEOUT_MS = 8000;
const MAX_BODY_BYTES = 16 * 1024;
const DEFAULT_ORIGINS = [
  "https://admin.ourney.tech",
  "http://localhost:5173",
  "http://127.0.0.1:5173",
  "http://localhost:3000",
  "http://127.0.0.1:3000",
];

export type AdminIdentity = {
  user_id: string;
  email: string;
  role: "owner" | "moderator";
  username?: string | null;
  display_name?: string | null;
};

export type WaitlistTarget = {
  id: string;
  email: string;
  lang: "vi" | "en";
  platforms: string[];
  source: string | null;
  confirmation_sent_at: string | null;
  confirmation_error: string | null;
};

export type AdminActionDeps = {
  verifyAdmin: (token: string) => Promise<{ admin?: AdminIdentity; status?: number; error?: string }>;
  serviceClient: () => SupabaseClient;
  fetchFn: typeof fetch;
  envGet: (key: string) => string | undefined;
};

export function allowedOrigins(envGet: (key: string) => string | undefined = Deno.env.get): string[] {
  const raw = envGet("ADMIN_ALLOWED_ORIGINS");
  if (!raw) return DEFAULT_ORIGINS;
  return raw.split(",").map((s) => s.trim().replace(/\/+$/, "")).filter(Boolean);
}

export function corsHeaders(
  origin: string | null,
  envGet: (key: string) => string | undefined = Deno.env.get,
): Record<string, string> {
  const list = allowedOrigins(envGet);
  const allow = list.includes("*") ? "*" : origin && list.includes(origin) ? origin : list[0] ?? "";
  return {
    "Access-Control-Allow-Origin": allow,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Max-Age": "86400",
    Vary: "Origin",
  };
}

function publicAnonKey(envGet: (key: string) => string | undefined): string {
  const legacy = envGet("SUPABASE_ANON_KEY");
  if (legacy) return legacy;
  try {
    const parsed = JSON.parse(envGet("SUPABASE_PUBLISHABLE_KEYS") ?? "{}") as Record<string, string>;
    if (parsed["default"]) return parsed["default"];
  } catch {
    // fall through
  }
  throw new Error("public anon key missing from environment");
}

async function defaultVerifyAdmin(
  token: string,
  envGet: (key: string) => string | undefined = Deno.env.get,
): Promise<{ admin?: AdminIdentity; status?: number; error?: string }> {
  const url = envGet("SUPABASE_URL");
  if (!url) throw new Error("SUPABASE_URL missing from environment");
  const anonKey = publicAnonKey(envGet);

  const callerClient = createClient(url, anonKey, {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    global: { headers: { Authorization: `Bearer ${token}` } },
  });

  const { data: userData, error: userErr } = await callerClient.auth.getUser(token);
  if (userErr || !userData?.user?.id) {
    return { status: 401, error: "unauthenticated" };
  }

  const { data, error } = await callerClient.schema("admin").rpc("me");
  if (error) {
    const isForbidden = error.code === "42501" || /forbidden/i.test(error.message ?? "");
    return {
      status: isForbidden ? 403 : 401,
      error: isForbidden ? "forbidden" : "unauthenticated",
    };
  }

  const me = data as AdminIdentity | null;
  if (!me || !me.user_id || (me.role !== "owner" && me.role !== "moderator")) {
    return { status: 403, error: "forbidden" };
  }
  return { admin: me };
}

export async function sha256Hex(input: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(input));
  return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

async function recordAudit(
  service: SupabaseClient,
  adminId: string,
  action: string,
  targetType: string,
  targetId: string | null,
  reason: string | null,
  meta: Record<string, unknown>,
): Promise<void> {
  const { error } = await service.rpc("admin_service_record_audit", {
    p_admin_id: adminId,
    p_action: action,
    p_target_type: targetType,
    p_target_id: targetId,
    p_reason: reason,
    p_meta: meta,
  });
  if (error) {
    console.error(`admin_service_record_audit (${action}) failed`, error.message);
  }
}

async function sendResendEmail(
  payload: Record<string, unknown>,
  fetchFn: typeof fetch,
  envGet: (key: string) => string | undefined,
): Promise<string | null> {
  const key = envGet("RESEND_API_KEY");
  if (!key) return "mail_not_configured: RESEND_API_KEY missing";
  try {
    const res = await fetchFn(RESEND_URL, {
      method: "POST",
      headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(RESEND_TIMEOUT_MS),
    });
    if (res.ok) {
      await res.body?.cancel();
      return null;
    }
    return `resend_${res.status}: ${(await res.text()).slice(0, 400)}`;
  } catch (e) {
    return `resend_failed: ${e instanceof Error ? e.message : String(e)}`;
  }
}

async function removeStorageBatch(
  service: SupabaseClient,
  bucket: string,
  paths: string[],
): Promise<{ removed: number; failed: number }> {
  let removed = 0;
  let failed = 0;
  for (const part of chunk(paths, 100)) {
    let failure: string | null = null;
    try {
      const { error } = await service.storage.from(bucket).remove(part);
      if (error) failure = error.message;
    } catch (e) {
      failure = e instanceof Error ? e.message : String(e);
    }
    if (failure === null) {
      removed += part.length;
      const done = await service.rpc("finish_storage_purge", { p_bucket: bucket, p_paths: part });
      if (done.error) console.error("finish_storage_purge failed", done.error.message);
    } else {
      failed += part.length;
      const noted = await service.rpc("fail_storage_purge", {
        p_bucket: bucket,
        p_paths: part,
        p_error: failure,
      });
      if (noted.error) console.error("fail_storage_purge failed", noted.error.message);
    }
  }
  return { removed, failed };
}

async function drainClaimedPurge(
  service: SupabaseClient,
  limit = 200,
  maxPasses = 5,
): Promise<{ claimed: number; removed: number; failed: number }> {
  let totalClaimed = 0;
  let totalRemoved = 0;
  let totalFailed = 0;

  for (let pass = 0; pass < maxPasses; pass++) {
    const { data, error } = await service.rpc("claim_storage_purge", { p_limit: limit });
    if (error) {
      console.error("claim_storage_purge failed", error.message);
      break;
    }
    const rows = (data ?? []) as { bucket: string; path: string }[];
    if (rows.length === 0) break;
    totalClaimed += rows.length;

    const byBucket = new Map<string, string[]>();
    for (const r of rows) {
      byBucket.set(r.bucket, [...(byBucket.get(r.bucket) ?? []), r.path]);
    }
    for (const [bucket, paths] of byBucket) {
      const res = await removeStorageBatch(service, bucket, paths);
      totalRemoved += res.removed;
      totalFailed += res.failed;
    }
    if (rows.length < limit) break;
  }

  return { claimed: totalClaimed, removed: totalRemoved, failed: totalFailed };
}

export async function handle(
  req: Request,
  customDeps: Partial<AdminActionDeps> = {},
): Promise<Response> {
  const envGet = customDeps.envGet ?? ((k: string) => Deno.env.get(k));
  const cors = corsHeaders(req.headers.get("origin"), envGet);

  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: cors });
  }
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405, { ...cors, Allow: "POST" });
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7).trim() : "";
  if (!token) {
    return json({ error: "unauthenticated" }, 401, cors);
  }

  const verifyAdmin = customDeps.verifyAdmin ?? ((t: string) => defaultVerifyAdmin(t, envGet));
  const authResult = await verifyAdmin(token);
  if (!authResult.admin) {
    return json(
      { error: authResult.error ?? "unauthenticated" },
      authResult.status ?? 401,
      cors,
    );
  }
  const caller = authResult.admin;

  const contentLength = Number(req.headers.get("content-length") ?? "0");
  if (Number.isFinite(contentLength) && contentLength > MAX_BODY_BYTES) {
    return json({ error: "payload_too_large" }, 413, cors);
  }

  let body: Record<string, unknown> = {};
  try {
    const rawText = await req.text();
    if (new TextEncoder().encode(rawText).byteLength > MAX_BODY_BYTES) {
      return json({ error: "payload_too_large" }, 413, cors);
    }
    const parsed = JSON.parse(rawText);
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
      return json({ error: "invalid_body" }, 400, cors);
    }
    body = parsed as Record<string, unknown>;
  } catch {
    return json({ error: "invalid_body" }, 400, cors);
  }

  const action = typeof body.action === "string" ? body.action.trim() : "";
  const service = (customDeps.serviceClient ?? adminClient)();
  const fetchFn = customDeps.fetchFn ?? fetch;

  // -------------------------------------------------------------------------
  // 1. waitlist_resend / waitlist_resend_failed
  // -------------------------------------------------------------------------
  if (action === "waitlist_resend" || action === "waitlist_resend_failed") {
    let waitlistId: string | null = null;
    let rawLimit = 25;

    if (action === "waitlist_resend") {
      // P2-3: single-row resend strictly requires a valid UUID waitlist_id (never falls back to bulk).
      const rawId = typeof body.waitlist_id === "string" ? body.waitlist_id.trim() : "";
      if (!UUID_RE.test(rawId)) {
        return json({ error: "invalid" }, 400, cors);
      }
      waitlistId = rawId;
      rawLimit = 1;
    } else {
      // P2-3: bulk retry only via explicit waitlist_resend_failed; reject any non-null waitlist_id or invalid limit.
      if (body.waitlist_id !== undefined && body.waitlist_id !== null) {
        return json({ error: "invalid" }, 400, cors);
      }
      if (body.limit !== undefined && body.limit !== null) {
        if (typeof body.limit !== "number" || !Number.isFinite(body.limit) || body.limit < 1) {
          return json({ error: "invalid" }, 400, cors);
        }
        rawLimit = Math.max(1, Math.min(25, Math.trunc(body.limit)));
      }
    }

    const { data, error } = await service.rpc("admin_service_get_waitlist_targets", {
      p_waitlist_id: waitlistId,
      p_limit: rawLimit,
    });
    if (error) {
      console.error("admin_service_get_waitlist_targets failed", error.message);
      return json({ error: "internal" }, 500, cors);
    }

    const targets = ((data ?? []) as WaitlistTarget[]).slice();
    if (waitlistId && targets.length === 0) {
      return json({ error: "not_found" }, 404, cors);
    }

    const from = (envGet("WAITLIST_FROM") ?? "").trim();
    const replyTo = (envGet("WAITLIST_REPLY_TO") ?? "").trim();
    let sent = 0;
    let failed = 0;
    const errors: { id: string; error: string }[] = [];

    for (const row of targets) {
      let mailErr: string | null = null;
      if (!from) {
        mailErr = "mail_not_configured: WAITLIST_FROM missing";
      } else {
        const mail = confirmationEmail(row.lang === "en" ? "en" : "vi");
        mailErr = await sendResendEmail(
          {
            from,
            to: [row.email],
            subject: mail.subject,
            text: mail.text,
            html: mail.html,
            ...(replyTo ? { reply_to: replyTo } : {}),
          },
          fetchFn,
          envGet,
        );
      }

      const mark = await service.rpc("waitlist_mark_confirmation", {
        p_id: row.id,
        p_error: mailErr,
      });
      if (mark.error) {
        console.error("waitlist_mark_confirmation failed", mark.error.message);
      }

      if (mailErr === null) {
        sent += 1;
      } else {
        failed += 1;
        errors.push({ id: row.id, error: mailErr });
      }
    }

    await recordAudit(
      service,
      caller.user_id,
      "waitlist.resend_confirmation",
      "waitlist",
      waitlistId ?? "bulk_failed",
      null,
      { attempted: targets.length, sent, failed },
    );

    return json(
      {
        ok: true,
        attempted: targets.length,
        sent,
        failed,
        errors,
      },
      200,
      cors,
    );
  }

  // -------------------------------------------------------------------------
  // 2. delete_user (owner role ONLY — verified delete-on-request erasure)
  // -------------------------------------------------------------------------
  if (action === "delete_user") {
    if (caller.role !== "owner") {
      return json({ error: "forbidden" }, 403, cors);
    }

    const userId = typeof body.user_id === "string" ? body.user_id.trim() : "";
    const reason = typeof body.reason === "string" ? body.reason.trim() : "";
    const ticketRef = typeof body.ticket_ref === "string" ? body.ticket_ref.trim().slice(0, 120) : null;

    if (!UUID_RE.test(userId) || reason.length < 3) {
      return json({ error: "invalid" }, 400, cors);
    }
    if (userId.toLowerCase() === caller.user_id.toLowerCase()) {
      return json({ error: "cannot_delete_self" }, 400, cors);
    }

    const lookup = await service.auth.admin.getUserById(userId);
    if (lookup.error || !lookup.data?.user) {
      const status = lookup.error?.status === 404 || lookup.error?.code === "user_not_found" ? 404 : 500;
      return json({ error: status === 404 ? "not_found" : "lookup_failed" }, status, cors);
    }

    const targetEmail = (lookup.data.user.email ?? "").trim().toLowerCase();
    const emailSha256 = await sha256Hex(targetEmail || userId);

    const detach = await service.rpc("detach_account_storage_owner", { p_user: userId });
    if (detach.error) {
      console.error("detach_account_storage_owner failed", detach.error.message);
    }

    const { error: deleteError } = await service.auth.admin.deleteUser(userId);
    if (deleteError) {
      console.error("admin-action deleteUser failed", deleteError.message);
      return json({ error: "delete_failed" }, 500, cors);
    }

    const drained = await drainClaimedPurge(service, 500, 5);
    let removedObjects = drained.removed;

    // Second pass for any racing direct upload right around deleteUser
    for (const [rpc, bucket] of [
      ["account_media_paths", "media"],
      ["account_message_paths", "messages"],
    ] as const) {
      const { data: extraPaths, error: listErr } = await service.rpc(rpc, { p_user: userId });
      if (listErr) continue;
      const list = ((extraPaths ?? []) as string[]).filter(Boolean);
      if (list.length === 0) continue;
      await service.rpc("enqueue_storage_purge", { p_bucket: bucket, p_user: userId, p_paths: list });
      const extraRes = await removeStorageBatch(service, bucket, list);
      removedObjects += extraRes.removed;
    }

    await recordAudit(
      service,
      caller.user_id,
      "users.delete_on_request",
      "user",
      userId,
      reason,
      {
        email_sha256: emailSha256,
        ticket_ref: ticketRef,
        removed_objects: removedObjects,
      },
    );

    return json(
      {
        ok: true,
        deleted: true,
        user_id: userId,
        email_sha256: emailSha256,
        removed_objects: removedObjects,
      },
      200,
      cors,
    );
  }

  // -------------------------------------------------------------------------
  // 3. run_storage_sweep
  // -------------------------------------------------------------------------
  if (action === "run_storage_sweep") {
    const limit = typeof body.limit === "number" && Number.isFinite(body.limit)
      ? Math.max(1, Math.min(500, Math.trunc(body.limit)))
      : 200;

    const res = await drainClaimedPurge(service, limit, 1);

    await recordAudit(
      service,
      caller.user_id,
      "system.run_storage_sweep",
      "system",
      "pending_storage_purge",
      null,
      res,
    );

    return json({ ok: true, ...res }, 200, cors);
  }

  // -------------------------------------------------------------------------
  // 4. trigger_moderation_notify
  // -------------------------------------------------------------------------
  if (action === "trigger_moderation_notify") {
    const limit = typeof body.limit === "number" && Number.isFinite(body.limit)
      ? Math.max(1, Math.min(200, Math.trunc(body.limit)))
      : 50;

    const { data, error } = await service.rpc("claim_moderation_notifications", { p_limit: limit });
    if (error) {
      console.error("claim_moderation_notifications failed", error.message);
      return json({ error: "internal" }, 500, cors);
    }

    const items = ((data ?? []) as ModerationQueueItem[]).slice();
    const itemIds = items.map((i) => i.id);
    const recipient = (envGet("MODERATION_NOTIFY_EMAIL") ?? "support@ourney.tech").trim() || "support@ourney.tech";
    const sender = (envGet("MODERATION_FROM_EMAIL") ?? "moderation@ourney.tech").trim() || "moderation@ourney.tech";
    const webhookUrl = (envGet("MODERATION_WEBHOOK_URL") ?? "").trim();
    const webhookKey = (envGet("MODERATION_WEBHOOK_API_KEY") ?? "").trim();

    let notified = 0;
    if (items.length > 0) {
      if (!webhookUrl) {
        await service.rpc("release_moderation_notifications", { p_ids: itemIds });
      } else {
        const digest = formatModerationDigest(items);
        const isResendApi = /api\.resend\.com\b/i.test(webhookUrl);
        const headers: Record<string, string> = { "Content-Type": "application/json" };
        if (webhookKey) headers["Authorization"] = `Bearer ${webhookKey}`;
        const webhookBody = isResendApi
          ? { from: sender, to: [recipient], subject: digest.subject, text: digest.text }
          : { from: sender, to: [recipient], subject: digest.subject, text: digest.text, items };

        let ok = false;
        try {
          const resp = await fetchFn(webhookUrl, {
            method: "POST",
            headers,
            body: JSON.stringify(webhookBody),
            signal: AbortSignal.timeout(WEBHOOK_TIMEOUT_MS),
          });
          ok = resp.ok;
          await resp.body?.cancel();
        } catch {
          ok = false;
        }

        if (ok) {
          await service.rpc("confirm_moderation_notifications", { p_ids: itemIds });
          notified = items.length;
        } else {
          await service.rpc("release_moderation_notifications", { p_ids: itemIds });
        }
      }
    }

    await recordAudit(
      service,
      caller.user_id,
      "system.trigger_moderation_notify",
      "system",
      "moderation_queue",
      null,
      { claimed: items.length, notified, configured: webhookUrl.length > 0, recipient },
    );

    return json(
      {
        ok: true,
        claimed: items.length,
        notified,
        configured: webhookUrl.length > 0,
        recipient,
      },
      200,
      cors,
    );
  }

  return json({ error: "invalid_action" }, 400, cors);
}

if (import.meta.main) {
  Deno.serve(async (req: Request): Promise<Response> => {
    try {
      return await handle(req);
    } catch (e) {
      console.error("admin-action failed", e instanceof Error ? e.message : String(e));
      return json({ error: "internal" }, 500, corsHeaders(req.headers.get("origin")));
    }
  });
}
