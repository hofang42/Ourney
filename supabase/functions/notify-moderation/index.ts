// notify-moderation (CS-03, Apple Guideline 1.2 / Google Play UGC 24-hour moderation SLA):
// Leases newly queued open items from public.moderation_queue (via public.claim_moderation_notifications),
// emails/alerts the owner (default support@ourney.tech) via a configurable HTTP endpoint
// (MODERATION_WEBHOOK_URL, e.g. Resend `https://api.resend.com/emails` or a generic webhook URL)
// with optional Bearer token MODERATION_WEBHOOK_API_KEY, and confirms `notified_at = now()`
// (via public.confirm_moderation_notifications) only after webhook delivery succeeds.
//
// Safe when not configured or when the webhook fails: claimed items are structured-logged and
// their lease is released (via public.release_moderation_notifications) so they remain unnotified
// and will be delivered on the next run once configured/reachable.
//
// Auth: accepts `x-moderation-token` matching MODERATION_WEBHOOK_TOKEN, `x-sweep-token` matching
// SWEEP_TOKEN, or `Authorization: Bearer <service_role_key>`.
import { adminClient, json } from "../_shared/admin.ts";

const DEFAULT_LIMIT = 50;

export type ModerationQueueItem = {
  id: string;
  kind: "report" | "block";
  report_id: string | null;
  status: string;
  reason: string | null;
  note: string | null;
  created_at: string;
  due_at: string;
  overdue?: boolean;
  hours_remaining?: number;
  actor_id: string | null;
  actor_username?: string | null;
  target_user_id: string | null;
  target_username?: string | null;
  target_display_name?: string | null;
  target_checkin_id: string | null;
  checkin_caption?: string | null;
  target_message_id: string | null;
  message_body?: string | null;
  distinct_open_reporters?: number;
};

async function sha256(input: string): Promise<Uint8Array> {
  return new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(input)));
}

/** Constant-time comparison: hash both sides to equal length, then XOR-accumulate. */
async function sameSecret(given: string, expected: string): Promise<boolean> {
  if (!given || !expected) return false;
  const [a, b] = await Promise.all([sha256(given), sha256(expected)]);
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
  return diff === 0;
}

function configuredServiceKey(): string {
  const raw = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (raw) {
    try {
      const key = (JSON.parse(raw) as Record<string, string>)["default"];
      if (key) return key;
    } catch {
      // fall through
    }
  }
  return Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
}

async function isAuthorized(req: Request): Promise<boolean> {
  const modSecret = Deno.env.get("MODERATION_WEBHOOK_TOKEN") ?? "";
  const sweepSecret = Deno.env.get("SWEEP_TOKEN") ?? "";
  const serviceSecret = configuredServiceKey();

  const givenMod = req.headers.get("x-moderation-token") ?? "";
  if (modSecret && await sameSecret(givenMod, modSecret)) return true;

  const givenSweep = req.headers.get("x-sweep-token") ?? "";
  if (sweepSecret && await sameSecret(givenSweep, sweepSecret)) return true;

  const auth = req.headers.get("Authorization") ?? "";
  const bearer = auth.startsWith("Bearer ") ? auth.slice(7).trim() : "";
  if (bearer && modSecret && await sameSecret(bearer, modSecret)) return true;
  if (bearer && sweepSecret && await sameSecret(bearer, sweepSecret)) return true;
  if (bearer && serviceSecret && await sameSecret(bearer, serviceSecret)) return true;

  // If no custom token secret is configured at all and service key is absent, deny.
  return false;
}

export function formatModerationDigest(items: ModerationQueueItem[]): { subject: string; text: string } {
  const reports = items.filter((i) => i.kind === "report").length;
  const blocks = items.length - reports;
  const earliestDue = items.reduce(
    (min, i) => (!min || (i.due_at && i.due_at < min) ? i.due_at : min),
    "",
  );
  const subject = `[Ourney Moderation] ${items.length} item(s) pending 24h review (${reports} report, ${blocks} block)`;
  const lines = [
    `Ourney 24-Hour Moderation Queue Alert`,
    `Items claimed: ${items.length} (earliest due_at: ${earliestDue || "n/a"})`,
    ``,
    ...items.map((item, idx) => {
      const target = item.target_checkin_id
        ? `checkin=${item.target_checkin_id}`
        : item.target_message_id
        ? `message=${item.target_message_id}`
        : `user=${item.target_user_id ?? "unknown"}`;
      const excerpt = item.checkin_caption ?? item.message_body ?? item.note ?? "";
      return `${idx + 1}. [${item.kind.toUpperCase()}] id=${item.id} reason=${item.reason ?? "n/a"} ${target} ` +
        `target_user=${item.target_username ?? item.target_user_id ?? "n/a"} ` +
        `reporters=${item.distinct_open_reporters ?? 1} due_at=${item.due_at}` +
        (excerpt ? ` | "${excerpt.slice(0, 120)}"` : "");
    }),
    ``,
    `Review & resolve within 24 hours: bash scripts/moderation/review.sh list`,
  ];
  return { subject, text: lines.join("\n") };
}

export async function handle(req: Request): Promise<Response> {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405, { Allow: "POST" });
  if (!(await isAuthorized(req))) return json({ error: "unauthenticated" }, 401);

  let payload: { limit?: number } = {};
  try {
    payload = await req.json();
  } catch {
    payload = {};
  }

  const limit = typeof payload.limit === "number" && Number.isFinite(payload.limit)
    ? Math.max(1, Math.min(200, Math.trunc(payload.limit)))
    : DEFAULT_LIMIT;

  const admin = adminClient();
  const { data, error } = await admin.rpc("claim_moderation_notifications", { p_limit: limit });
  if (error) {
    console.error(JSON.stringify({ event: "moderation_claim_failed", error: error.message }));
    return json({ error: "internal" }, 500);
  }

  const items = ((data ?? []) as ModerationQueueItem[]).slice();
  const itemIds = items.map((i) => i.id);

  const recipient = (Deno.env.get("MODERATION_NOTIFY_EMAIL") ?? "support@ourney.tech").trim() || "support@ourney.tech";
  const sender = (Deno.env.get("MODERATION_FROM_EMAIL") ?? "moderation@ourney.tech").trim() ||
    "moderation@ourney.tech";
  const webhookUrl = (Deno.env.get("MODERATION_WEBHOOK_URL") ?? "").trim();
  const webhookKey = (Deno.env.get("MODERATION_WEBHOOK_API_KEY") ?? "").trim();

  if (items.length === 0) {
    return json({
      claimed: 0,
      notified: 0,
      logged: 0,
      configured: webhookUrl.length > 0,
      recipient,
    });
  }

  const digest = formatModerationDigest(items);

  if (!webhookUrl) {
    console.info(JSON.stringify({
      event: "moderation_queue_alert",
      configured: false,
      count: items.length,
      recipient,
      subject: digest.subject,
      item_ids: itemIds,
    }));
    const release = await admin.rpc("release_moderation_notifications", { p_ids: itemIds });
    if (release.error) {
      console.error(JSON.stringify({ event: "moderation_release_failed", error: release.error.message }));
    }
    return json({
      claimed: items.length,
      notified: 0,
      logged: items.length,
      configured: false,
      recipient,
      subject: digest.subject,
      item_ids: itemIds,
    });
  }

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };
  if (webhookKey) {
    headers["Authorization"] = `Bearer ${webhookKey}`;
  }

  const isResendApi = /api\.resend\.com\b/i.test(webhookUrl);
  const webhookBody = isResendApi
    ? {
      from: sender,
      to: [recipient],
      subject: digest.subject,
      text: digest.text,
    }
    : {
      from: sender,
      to: [recipient],
      subject: digest.subject,
      text: digest.text,
      items,
    };

  try {
    const resp = await fetch(webhookUrl, {
      method: "POST",
      headers,
      body: JSON.stringify(webhookBody),
    });
    if (!resp.ok) {
      console.error(JSON.stringify({
        event: "moderation_webhook_failed",
        status: resp.status,
        count: items.length,
        recipient,
        item_ids: itemIds,
      }));
      const release = await admin.rpc("release_moderation_notifications", { p_ids: itemIds });
      if (release.error) {
        console.error(JSON.stringify({ event: "moderation_release_failed", error: release.error.message }));
      }
      return json({
        claimed: items.length,
        notified: 0,
        logged: items.length,
        configured: true,
        recipient,
        error: "webhook_failed",
        webhook_status: resp.status,
      }, 502);
    }
  } catch (e) {
    console.error(JSON.stringify({
      event: "moderation_webhook_unreachable",
      error: e instanceof Error ? e.message : String(e),
      count: items.length,
      recipient,
      item_ids: itemIds,
    }));
    const release = await admin.rpc("release_moderation_notifications", { p_ids: itemIds });
    if (release.error) {
      console.error(JSON.stringify({ event: "moderation_release_failed", error: release.error.message }));
    }
    return json({
      claimed: items.length,
      notified: 0,
      logged: items.length,
      configured: true,
      recipient,
      error: "webhook_unreachable",
    }, 502);
  }

  const confirm = await admin.rpc("confirm_moderation_notifications", { p_ids: itemIds });
  if (confirm.error) {
    console.error(JSON.stringify({ event: "moderation_confirm_failed", error: confirm.error.message }));
  }
  console.info(JSON.stringify({
    event: "moderation_queue_notified",
    configured: true,
    count: items.length,
    recipient,
    subject: digest.subject,
    item_ids: itemIds,
  }));

  return json({
    claimed: items.length,
    notified: items.length,
    logged: items.length,
    configured: true,
    recipient,
    subject: digest.subject,
    item_ids: itemIds,
  });
}

if (import.meta.main) {
  Deno.serve(async (req: Request): Promise<Response> => {
    try {
      return await handle(req);
    } catch (e) {
      console.error(JSON.stringify({
        event: "moderation_unhandled_error",
        error: e instanceof Error ? e.message : String(e),
      }));
      return json({ error: "internal" }, 500);
    }
  });
}
