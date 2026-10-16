// public-journey (FR-E3): read-only JSON view of a SOLO journey whose visibility is `link`,
// addressed by its revocable token (public.set_public_link rotates/revokes it).
//   GET /functions/v1/public-journey?token=<40 chars [a-z0-9]>
// Group journeys never match (kind = 'solo' and visibility = 'link' are both required, and the
// schema forbids link visibility for groups). Media is returned only as short-lived signed URLs.
// Privacy (FR-B7): metric values are omitted when the owner hides metrics, and photo URLs are
// omitted when the owner blurs media for sharing.
// Spike S7: Supabase rewrites `text/html` GET responses to `text/plain` on the default
// supabase.co domain, so this returns JSON for a static page (e.g. GitHub Pages) to render.
import { adminClient, json } from "../_shared/admin.ts";

const TOKEN_RE = /^[a-z0-9]{40}$/;
const SIGNED_URL_TTL_SECONDS = 600;
const MAX_CHECKINS = 400; // duration_days <= 365

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
};

type CheckInRow = {
  id: string;
  local_date: string;
  caption: string | null;
  metric_value: number | null;
  from_library: boolean;
  photo_path: string;
  thumb_path: string;
};

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
  if (req.method !== "GET") return json({ error: "method_not_allowed" }, 405, { ...cors, Allow: "GET" });

  const token = new URL(req.url).searchParams.get("token") ?? "";
  // Same response for malformed, unknown and revoked tokens.
  const notFound = () => json({ error: "not_found" }, 404, cors);
  if (!TOKEN_RE.test(token)) return notFound();

  const admin = adminClient();
  const { data: journey, error } = await admin
    .from("journeys")
    .select(
      "id, owner_id, template_id, title, emoji, metric_name, metric_unit, start_date, duration_days, timezone, status",
    )
    .eq("public_token", token)
    .eq("visibility", "link")
    .eq("kind", "solo")
    .is("deleted_at", null)
    .maybeSingle();
  if (error) {
    console.error("journey lookup failed", error.message);
    return json({ error: "internal" }, 500, cors);
  }
  if (!journey) return notFound();

  const [membership, profile, checkIns, streak] = await Promise.all([
    admin.from("memberships").select("hide_metric, blur_media")
      .eq("journey_id", journey.id).eq("user_id", journey.owner_id).maybeSingle(),
    admin.from("profiles").select("display_name").eq("id", journey.owner_id).maybeSingle(),
    admin.from("check_ins")
      .select("id, local_date, caption, metric_value, from_library, photo_path, thumb_path")
      .eq("journey_id", journey.id).eq("user_id", journey.owner_id).is("deleted_at", null)
      .order("local_date", { ascending: true }).limit(MAX_CHECKINS),
    admin.rpc("journey_streak", { journey: journey.id, member: journey.owner_id }),
  ]);
  for (const r of [membership, profile, checkIns, streak]) {
    if (r.error) {
      console.error("public-journey query failed", r.error.message);
      return json({ error: "internal" }, 500, cors);
    }
  }

  const hideMetric = membership.data?.hide_metric ?? true;
  const blurMedia = membership.data?.blur_media ?? true;
  const rows = (checkIns.data ?? []) as CheckInRow[];

  const paths = rows.flatMap((c) => (blurMedia ? [] : [c.thumb_path, c.photo_path]));
  const signed = new Map<string, string>();
  if (paths.length > 0) {
    const { data, error: signError } = await admin.storage.from("media")
      .createSignedUrls(paths, SIGNED_URL_TTL_SECONDS);
    if (signError) {
      console.error("createSignedUrls failed", signError.message);
      return json({ error: "internal" }, 500, cors);
    }
    for (const s of data ?? []) {
      if (s.path && s.signedUrl && !s.error) signed.set(s.path, s.signedUrl);
    }
  }

  const s = (streak.data as { current_streak: number; best_streak: number; completed_days: number }[] | null)?.[0];
  return json({
    journey: {
      title: journey.title,
      emoji: journey.emoji,
      template_id: journey.template_id,
      start_date: journey.start_date,
      duration_days: journey.duration_days,
      timezone: journey.timezone,
      status: journey.status,
      metric_name: hideMetric ? null : journey.metric_name,
      metric_unit: hideMetric ? null : journey.metric_unit,
      owner_display_name: profile.data?.display_name ?? null,
    },
    streak: {
      current: s?.current_streak ?? 0,
      best: s?.best_streak ?? 0,
      completed: s?.completed_days ?? 0,
    },
    media_blurred: blurMedia,
    signed_url_ttl_seconds: SIGNED_URL_TTL_SECONDS,
    check_ins: rows.map((c) => ({
      local_date: c.local_date,
      caption: c.caption,
      from_library: c.from_library,
      metric_value: hideMetric ? null : c.metric_value,
      thumb_url: signed.get(c.thumb_path) ?? null,
      photo_url: signed.get(c.photo_path) ?? null,
    })),
  }, 200, cors);
});
