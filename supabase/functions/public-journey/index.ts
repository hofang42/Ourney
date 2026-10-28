// public-journey (FR-E3, docs/contracts/sharing.md v1.3): read-only JSON view of a journey that
// holds a public token (solo with visibility `link`, or an ended group whose owner turned the
// link on, S32), addressed by its revocable token (public.set_public_link rotates/revokes it).
//   GET /functions/v1/public-journey?token=<40 chars [a-z0-9]>
// Media is returned only as short-lived signed URLs. Privacy:
//   - photos hidden in share (S11), soft-deleted / moderated photos, photos of authors who left
//     and (group) of authors without an `accepted` share consent (S30) are never returned;
//   - metric values are omitted for authors who hide metrics; photo URLs are omitted for authors
//     who blur media for sharing (FR-B7);
//   - like / follow counts only when the owner turned `show_counts` on (S22);
//   - streak never for retold journeys (S12) nor groups (S34: strangers).
// A view is recorded with viewer_key = sha256(token | user-agent | day salt) — no raw IP (S19).
// Spike S7: Supabase rewrites `text/html` GET responses to `text/plain` on the default
// supabase.co domain, so this returns JSON for a static page (e.g. GitHub Pages) to render.
import { adminClient, json } from "../_shared/admin.ts";

const TOKEN_RE = /^[a-z0-9]{40}$/;
const SIGNED_URL_TTL_SECONDS = 600;
const MAX_CHECKINS = 4000; // up to 10 members x 366 days

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
};

type JourneyRow = {
  id: string;
  owner_id: string;
  kind: "solo" | "group";
  template_id: string;
  title: string;
  emoji: string;
  metric_name: string | null;
  metric_unit: string | null;
  start_date: string;
  duration_days: number | null;
  timezone: string;
  status: string;
  origin: "live" | "imported";
  story_title: string | null;
  story_intro: string | null;
  story_lessons: string | null;
  cover_checkin_id: string | null;
  show_counts: boolean;
};

type CheckInRow = {
  id: string;
  user_id: string;
  local_date: string;
  caption: string | null;
  from_library: boolean;
  photo_path: string;
  thumb_path: string;
};

type MemberRow = { user_id: string; hide_metric: boolean; blur_media: boolean };

async function sha256Hex(input: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(input));
  return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
  if (req.method !== "GET") return json({ error: "method_not_allowed" }, 405, { ...cors, Allow: "GET" });

  const token = new URL(req.url).searchParams.get("token") ?? "";
  // Same response for malformed, unknown and revoked tokens.
  const notFound = () => json({ error: "not_found" }, 404, cors);
  if (!TOKEN_RE.test(token)) return notFound();

  const admin = adminClient();
  const { data: journeyData, error } = await admin
    .from("journeys")
    .select(
      "id, owner_id, kind, template_id, title, emoji, metric_name, metric_unit, start_date, duration_days, " +
        "timezone, status, origin, story_title, story_intro, story_lessons, cover_checkin_id, show_counts",
    )
    .eq("public_token", token)
    .is("deleted_at", null)
    .maybeSingle();
  if (error) {
    console.error("journey lookup failed", error.message);
    return json({ error: "internal" }, 500, cors);
  }
  if (!journeyData) return notFound();
  const journey = journeyData as unknown as JourneyRow;

  const [members, consents, owner, checkIns, metrics, followers] = await Promise.all([
    admin.from("memberships").select("user_id, hide_metric, blur_media, joined_at")
      .eq("journey_id", journey.id).eq("status", "active").is("deleted_at", null)
      .order("joined_at", { ascending: true }),
    admin.from("journey_share_consents").select("user_id")
      .eq("journey_id", journey.id).eq("status", "accepted"),
    admin.from("profiles").select("display_name").eq("id", journey.owner_id).maybeSingle(),
    admin.from("check_ins")
      .select("id, user_id, local_date, caption, from_library, photo_path, thumb_path")
      .eq("journey_id", journey.id).is("deleted_at", null).is("moderated_at", null)
      .eq("hidden_in_share", false)
      .order("local_date", { ascending: true }).limit(MAX_CHECKINS),
    admin.from("check_in_metrics").select("checkin_id, metric_value")
      .eq("journey_id", journey.id).limit(MAX_CHECKINS),
    journey.show_counts
      ? admin.from("journeys").select("id", { count: "exact", head: true })
        .eq("followed_from", journey.id).is("deleted_at", null)
      : Promise.resolve({ data: null, error: null, count: null }),
  ]);
  for (const r of [members, consents, owner, checkIns, metrics, followers]) {
    if (r.error) {
      console.error("public-journey query failed", r.error.message);
      return json({ error: "internal" }, 500, cors);
    }
  }

  // Authors whose photos may be shown: active members, and for groups only with consent (S30).
  const memberRows = (members.data ?? []) as MemberRow[];
  const consented = new Set(((consents.data ?? []) as { user_id: string }[]).map((c) => c.user_id));
  const visibleAuthors = new Map<string, MemberRow>();
  for (const m of memberRows) {
    if (journey.kind === "solo" ? m.user_id === journey.owner_id : consented.has(m.user_id)) {
      visibleAuthors.set(m.user_id, m);
    }
  }
  const rows = ((checkIns.data ?? []) as CheckInRow[]).filter((c) => visibleAuthors.has(c.user_id));

  const metricById = new Map<string, number | null>();
  for (const m of (metrics.data ?? []) as { checkin_id: string; metric_value: number | null }[]) {
    metricById.set(m.checkin_id, m.metric_value);
  }

  let likeCount: number | null = null;
  if (journey.show_counts) {
    likeCount = 0;
    const ids = rows.map((c) => c.id);
    for (let i = 0; i < ids.length; i += 200) {
      const { count, error: likeError } = await admin.from("reactions")
        .select("checkin_id", { count: "exact", head: true })
        .in("checkin_id", ids.slice(i, i + 200)).is("deleted_at", null);
      if (likeError) {
        console.error("like count failed", likeError.message);
        return json({ error: "internal" }, 500, cors);
      }
      likeCount += count ?? 0;
    }
  }

  const paths = rows.flatMap((c) => (visibleAuthors.get(c.user_id)?.blur_media ? [] : [c.thumb_path, c.photo_path]));
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

  // Solo streak only (S12: never for imported; S34: no group streak for outsiders).
  let streak: { current: number; best: number; completed: number } | null = null;
  if (journey.kind === "solo" && journey.origin !== "imported") {
    const res = await admin.rpc("journey_streak", { journey: journey.id, member: journey.owner_id });
    if (res.error) {
      console.error("journey_streak failed", res.error.message);
      return json({ error: "internal" }, 500, cors);
    }
    const s = (res.data as { current_streak: number; best_streak: number; completed_days: number }[] | null)?.[0];
    streak = { current: s?.current_streak ?? 0, best: s?.best_streak ?? 0, completed: s?.completed_days ?? 0 };
  }

  // One anonymous view per browser per day (S19). The salt changes daily, so keys cannot be
  // linked across days; VIEW_SALT (optional secret) prevents offline guessing of the hash.
  const day = new Date().toISOString().slice(0, 10);
  const salt = `${day}|${Deno.env.get("VIEW_SALT") ?? ""}`;
  const viewerKey = await sha256Hex(`${token}|${req.headers.get("user-agent") ?? ""}|${salt}`);
  const view = await admin.rpc("record_journey_view", { p_journey: journey.id, p_viewer_key: `web:${viewerKey}` });
  if (view.error) console.error("record_journey_view failed", view.error.message); // never fatal

  const ownerHides = visibleAuthors.get(journey.owner_id)?.hide_metric ?? true;
  const canFollow = journey.status === "ended" || journey.status === "archived" || journey.origin === "imported";
  const coverVisible = rows.some((c) => c.id === journey.cover_checkin_id);

  return json({
    journey: {
      title: journey.title,
      emoji: journey.emoji,
      template_id: journey.template_id,
      kind: journey.kind,
      origin: journey.origin,
      start_date: journey.start_date,
      duration_days: journey.duration_days,
      timezone: journey.timezone,
      status: journey.status,
      metric_name: ownerHides ? null : journey.metric_name,
      metric_unit: ownerHides ? null : journey.metric_unit,
      owner_display_name: owner.data?.display_name ?? null,
    },
    origin: journey.origin,
    story: {
      title: journey.story_title,
      intro: journey.story_intro,
      lessons: journey.story_lessons,
      cover_checkin_id: coverVisible ? journey.cover_checkin_id : null,
    },
    streak,
    can_follow: canFollow,
    frame: canFollow
      ? {
        source_journey_id: journey.id,
        template_id: journey.template_id,
        kind: journey.kind,
        title: journey.title,
        emoji: journey.emoji,
        owner_name: owner.data?.display_name ?? null,
        duration_days: journey.duration_days,
        metric_name: journey.metric_name,
        metric_unit: journey.metric_unit,
      }
      : null,
    ...(journey.show_counts ? { like_count: likeCount ?? 0, follow_count: followers.count ?? 0 } : {}),
    media_blurred: visibleAuthors.get(journey.owner_id)?.blur_media ?? true,
    signed_url_ttl_seconds: SIGNED_URL_TTL_SECONDS,
    check_ins: rows.map((c) => {
      const author = visibleAuthors.get(c.user_id);
      return {
        checkin_id: c.id,
        local_date: c.local_date,
        caption: c.caption,
        from_library: c.from_library,
        metric_value: author && !author.hide_metric ? metricById.get(c.id) ?? null : null,
        blurred: author?.blur_media ?? true,
        thumb_url: signed.get(c.thumb_path) ?? null,
        photo_url: signed.get(c.photo_path) ?? null,
      };
    }),
  }, 200, cors);
});
