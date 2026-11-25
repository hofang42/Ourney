import { createClient, type SupabaseClient } from '@supabase/supabase-js'
import type { WaitlistExportRow } from './csv'
import { formatAdminError, getCurrentLang, type Lang } from './i18n'

export type AdminRole = 'owner' | 'moderator'

export interface AdminIdentity {
  user_id: string
  email: string
  role: AdminRole
  username: string | null
  display_name: string | null
  avatar_path?: string | null
  note: string | null
  created_at?: string
  updated_at?: string
  last_sign_in_at?: string | null
}

export interface OverviewFeatureRequestTopItem {
  id: string
  title: string
  category: string
  status: string
  vote_count: number
  created_at?: string
}

export interface OverviewStats {
  timezone: string
  days: number
  generated_at: string
  alerts: {
    open_reports: number
    open_blocks: number
    overdue_reports: number
    earliest_due_at: string | null
    earliest_hours_remaining: number | null
    untriaged_feature_requests: number
    failed_waitlist_emails: number
    pending_storage_purge: number
    stuck_storage_purge: number
  }
  kpis: {
    users: {
      total_auth: number
      live_profiles: number
      deleted_profiles: number
      banned_users: number
      new_today: number
      new_7d: number
    }
    waitlist: {
      total: number
      new_7d: number
      converted_count: number
      converted_pct: number
      failed_emails: number
    }
    engagement: {
      dau: number
      wau: number
      mau: number
      avg_dau_7d: number
      stickiness_pct: number
      auth_signins_1d: number
      auth_signins_7d: number
    }
    checkins: {
      today: number
      last_7d: number
      camera_7d: number
      library_7d: number
      camera_pct_7d: number
    }
    streaks: {
      streak_3d_plus: number
      streak_7d_plus: number
      streak_14d_plus: number
      streak_30d_plus: number
    }
    moderation: {
      open_reports: number
      open_blocks: number
      overdue_count: number
      sla_compliance_pct_30d: number
    }
    feature_requests: {
      new_7d: number
      untriaged_count: number
      open_count: number
      shipped_count: number
      top_voted: OverviewFeatureRequestTopItem[]
    } | null
  }
  daily_growth: Array<{
    day: string
    new_profiles: number
    new_waitlist: number
  }>
  daily_habit_pulse: Array<{
    day: string
    dau: number
    live_checkins: number
  }>
  activation_funnel_7d: Array<{
    step: string
    label: string
    count: number
    conversion_pct: number
  }>
  cohort_retention: Array<{
    cohort_week: string
    cohort_size: number
    d1_pct: number
    d7_pct: number
    d14_pct: number
    d30_pct: number
  }>
  template_mix: Array<{
    template: string
    active_journeys: number
  }>
}

export interface ModerationQueueSummary {
  open_reports: number
  open_blocks: number
  overdue_count: number
  due_soon_count: number
  quarantined_count: number
  median_handle_hours_30d: number
}

export interface ModerationQueueRow {
  id: string
  kind: 'report' | 'block'
  report_id: string | null
  status: 'open' | 'actioned' | 'dismissed'
  reason: string | null
  note: string | null
  created_at: string
  due_at: string
  notified_at: string | null
  handled_at: string | null
  resolution_note: string | null
  overdue: boolean
  hours_remaining: number
  target_type: 'checkin' | 'message' | 'user' | 'feature_request'
  actor_id: string | null
  actor_username: string | null
  actor_display_name: string | null
  target_user_id: string | null
  target_username: string | null
  target_display_name: string | null
  target_checkin_id: string | null
  target_message_id: string | null
  target_feature_request_id?: string | null
  auto_quarantined: boolean
  has_reported_media: boolean
  distinct_open_reporters: number
  target_prior_actions: number
  target_blocked_by_count: number
}

export interface ModerationQueueResponse {
  summary: ModerationQueueSummary
  total: number
  items: ModerationQueueRow[]
}

export type ModerationReportedContent =
  | {
      target_type: 'checkin'
      checkin_id: string
      journey_id: string
      local_date: string
      captured_at: string
      caption: string | null
      extras: Record<string, unknown>
      moderated_at: string | null
      deleted_at: string | null
      has_photo: boolean
      has_thumb: boolean
      has_partner_photo: boolean
    }
  | {
      target_type: 'message'
      message_id: string
      conversation_id: string
      kind: string
      body: string | null
      created_at: string
      moderated_at: string | null
      deleted_at: string | null
      has_media: boolean
    }
  | {
      target_type: 'feature_request'
      feature_request_id: string
      title?: string | null
      body?: string | null
      caption?: string | null
      category?: string | null
      status?: string | null
      hidden?: boolean | null
      moderated_at?: string | null
      created_at?: string | null
      deleted?: boolean | null
    }
  | {
      target_type: 'user'
      user_id: string | null
    }

export interface ModerationItemDetail {
  id: string
  kind: 'report' | 'block'
  report_id: string | null
  status: 'open' | 'actioned' | 'dismissed'
  reason: string | null
  note: string | null
  created_at: string
  due_at: string
  notified_at: string | null
  handled_at: string | null
  resolution_note: string | null
  overdue: boolean
  hours_remaining: number
  actor_id: string | null
  target_user_id: string | null
  target_checkin_id: string | null
  target_message_id: string | null
  target_feature_request_id?: string | null
  target_user: {
    user_id: string
    username: string | null
    display_name: string | null
    created_at: string
    is_banned: boolean
    prior_actioned_reports: number
    blocked_by_count: number
  } | null
  sibling_reports: Array<{
    id: string
    reporter_id: string | null
    reporter_username: string | null
    reason: string | null
    note: string | null
    status: string
    created_at: string
    due_at: string
  }>
  reported_content: ModerationReportedContent
}

export interface RevealedMediaObject {
  bucket: 'media' | 'messages'
  path: string
  kind: 'photo' | 'thumb' | 'partner_photo' | 'message_photo'
  signed_url?: string
}

export interface RevealReportedMediaResponse {
  queue_id: string
  expires_at: string
  ttl_seconds: number
  objects: RevealedMediaObject[]
}

export interface ObjectionableWordRow {
  term: string
  lang: 'vi' | 'en' | 'any'
  match_mode: 'diacritic_word' | 'word' | 'substring'
  category: 'csae' | 'self_harm' | 'violence' | 'sexual' | 'slur' | 'profanity'
  enabled: boolean
  created_at?: string
}

export interface ContentFilterMatch {
  term: string
  lang: 'vi' | 'en' | 'any'
  match_mode: 'diacritic_word' | 'word' | 'substring'
  category: 'csae' | 'self_harm' | 'violence' | 'sexual' | 'slur' | 'profanity'
}

export interface FilterDryRunResult {
  blocked: boolean
  term: string | null
  lang: string | null
  match_mode: string | null
  category: string | null
  matches: ContentFilterMatch[]
}

export type FeatureRequestStatus =
  | 'new'
  | 'under_review'
  | 'planned'
  | 'in_progress'
  | 'shipped'
  | 'declined'

export type FeatureRequestCategory =
  | 'camera'
  | 'journeys'
  | 'squad'
  | 'sharing'
  | 'design'
  | 'other'

export interface FeatureRequestStats {
  new: number
  under_review: number
  planned: number
  in_progress: number
  shipped: number
  declined: number
  hidden: number
  merged: number
  new_this_week: number
  top_voted: Array<{
    id: string
    title: string
    category: FeatureRequestCategory
    status: FeatureRequestStatus
    vote_count: number
  }>
}

export interface FeatureRequestAuthor {
  user_id: string | null
  username: string | null
  display_name: string | null
}

export interface FeatureRequestRow {
  id: string
  title: string
  body: string
  category: FeatureRequestCategory
  status: FeatureRequestStatus
  vote_count: number
  open_reports_count: number
  author_id: string | null
  author_username: string | null
  author_display_name: string | null
  author?: FeatureRequestAuthor | null
  admin_reply: string | null
  admin_replied_at: string | null
  shipped_at: string | null
  duplicate_of: string | null
  merged_children_count: number
  hidden: boolean
  created_at: string
  updated_at: string
}

export interface FeatureRequestListResponse {
  total: number
  items: FeatureRequestRow[]
}

export interface FeatureRequestVoterRow {
  user_id: string
  username: string | null
  display_name: string | null
  is_author?: boolean
  voted_at: string
}

export interface FeatureRequestDetail extends FeatureRequestRow {
  merged_children: Array<{
    id: string
    title: string
    author_username: string | null
    vote_count: number
    created_at: string
  }>
  reports: Array<{
    id: string
    reporter_username: string | null
    reason: string
    note: string | null
    status: string
    created_at: string
  }>
  voters: FeatureRequestVoterRow[]
}

export interface WaitlistSummary {
  total: number
  new_7d: number
  ios_only: number
  android_only: number
  both_platforms: number
  lang_vi: number
  lang_en: number
  mail_sent: number
  mail_failed: number
  mail_unsent: number
  converted_count: number
  waiting_count: number
  by_source: Array<{ source: string; count: number }>
  daily: Array<{ day: string; total: number; vi: number; en: number }>
}

export interface WaitlistRow {
  id: string
  email: string
  lang: 'vi' | 'en'
  platforms: string[]
  source: string | null
  created_at: string
  confirmation_sent_at: string | null
  confirmation_error: string | null
  mail_status: 'sent' | 'failed' | 'unsent'
  registered_in_app: boolean
}

export interface WaitlistListResponse {
  total: number
  items: WaitlistRow[]
}

export interface WaitlistResendResponse {
  ok: boolean
  attempted?: number
  sent?: number
  failed?: number
  errors?: Array<{ id: string; error: string }>
}

export interface AdminUserRow {
  id: string
  username: string | null
  display_name: string | null
  email: string | null
  has_phone: boolean
  has_password: boolean
  terms_version: number
  is_banned: boolean
  status: 'active' | 'incomplete_onboarding' | 'banned' | 'soft_deleted'
  banned_at: string | null
  ban_reason: string | null
  wiped_ugc: boolean | null
  active_journeys_count: number
  total_journeys_count: number
  group_journeys_count: number
  total_checkins: number
  best_streak: number
  open_reports_against: number
  total_actioned_reports: number
  blocked_by_count: number
  last_active_at: string | null
  created_at: string
}

export interface AdminUserListResponse {
  total: number
  items: AdminUserRow[]
}

export interface AdminUserModerationRecord {
  user_id: string
  banned_at: string | null
  banned_by: string | null
  ban_reason: string | null
  wiped_ugc: boolean
  unbanned_at: string | null
  unbanned_by: string | null
  unban_reason: string | null
  updated_at: string
}

export interface AdminUserRecentReport {
  queue_id: string
  kind: 'report' | 'block'
  reason: string | null
  status: 'open' | 'actioned' | 'dismissed'
  created_at: string
  due_at: string
  handled_at: string | null
  resolution_note: string | null
}

export interface AdminUserAuditHistoryItem {
  id: number
  admin_id: string | null
  admin_email: string | null
  action: string
  reason: string | null
  meta: Record<string, unknown>
  created_at: string
}

export interface AdminUserDetail {
  id: string
  email: string | null
  has_phone: boolean
  has_password: boolean
  username: string | null
  display_name: string | null
  terms_version: number
  is_banned: boolean
  banned_until: string | null
  status: 'active' | 'incomplete_onboarding' | 'banned' | 'soft_deleted'
  created_at: string
  last_sign_in_at: string | null
  deleted_at: string | null
  last_active_at: string | null
  activity: {
    active_journeys_count: number
    total_journeys_count: number
    group_journeys_count: number
    total_checkins: number
    best_streak: number
    friends_count: number
  }
  trust: {
    open_reports_against: number
    total_actioned_reports: number
    blocked_by_count: number
    moderation_record: AdminUserModerationRecord | null
    recent_reports_against: AdminUserRecentReport[]
    audit_history: AdminUserAuditHistoryItem[]
  }
}

export interface JourneyStats {
  total: number
  active: number
  ended: number
  archived: number
  solo_count: number
  group_count: number
  couple_count: number
  live_count: number
  imported_count: number
  public_links_count: number
  total_public_views: number
  by_template: Array<{ template_id: string; count: number }>
  by_skin: Array<{ skin: string; count: number }>
}

export interface AdminJourneyRow {
  id: string
  owner_id: string
  owner_username: string | null
  owner_display_name: string | null
  kind: 'solo' | 'group'
  is_couple: boolean
  origin: 'live' | 'imported'
  template_id: string
  layout: string | null
  status: 'active' | 'ended' | 'archived'
  visibility: 'private' | 'group' | 'link'
  title: string | null
  emoji: string | null
  has_public_link: boolean
  public_token: string | null
  active_members: number
  max_members: number | null
  checkin_count: number
  public_views: number
  start_date: string
  duration_days: number | null
  created_at: string
}

export interface AdminJourneyListResponse {
  total: number
  items: AdminJourneyRow[]
}

export interface AuditLogRow {
  id: number
  admin_id: string | null
  admin_email: string | null
  admin_username: string | null
  action: string
  target_type: string
  target_id: string | null
  reason: string | null
  meta: Record<string, unknown>
  created_at: string
}

export interface AuditLogListResponse {
  items: AuditLogRow[]
  next_before_id: number | null
}

export interface SystemHealth {
  storage_purge: {
    due_now_count: number
    backing_off_count: number
    stuck_count: number
    total_queued: number
    sample_errors: Array<{
      bucket: string
      path_prefix: string
      attempts: number
      next_attempt_at: string
      last_error: string
      created_at: string
    }>
  }
  moderation_notifications: {
    unnotified_open_count: number
    leased_count: number
    overdue_open_count: number
  }
  admins_count: {
    owners: number
    moderators: number
  }
}

const rawSupabaseUrl = (
  (import.meta.env.VITE_SUPABASE_URL as string | undefined) ?? ''
).trim()
const rawSupabaseAnonKey = (
  (import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined) ?? ''
).trim()

const isTestEnv = import.meta.env.MODE === 'test'

export function assertSupabaseConfigured(): void {
  if (isTestEnv) return
  if (!rawSupabaseUrl || !rawSupabaseAnonKey) {
    throw new Error(
      'Missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY environment configuration',
    )
  }
}

export const supabase: SupabaseClient = createClient(
  rawSupabaseUrl || 'http://127.0.0.1:54321',
  rawSupabaseAnonKey || 'test-anon-key-only',
  {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
    },
  },
)

export function isForbiddenError(err: unknown): boolean {
  if (!err || typeof err !== 'object') return false
  const e = err as { code?: string; status?: number; message?: string }
  return (
    e.code === '42501' ||
    e.status === 403 ||
    Boolean(
      e.message && /forbidden|permission denied|not_admin|42501/i.test(e.message),
    )
  )
}

export function isUnauthenticatedError(err: unknown): boolean {
  if (!err || typeof err !== 'object') return false
  const e = err as { code?: string; status?: number; message?: string }
  return (
    e.code === '28000' ||
    e.code === 'PGRST301' ||
    e.status === 401 ||
    Boolean(e.message && /unauthenticated|jwt expired|invalid jwt/i.test(e.message))
  )
}

export function isFeatureRequestsNotInstalledError(err: unknown): boolean {
  if (!err || typeof err !== 'object') return false
  const e = err as { code?: string; status?: number; message?: string }
  return (
    e.code === 'PGRST202' ||
    e.code === '42883' ||
    e.code === '42P01' ||
    e.status === 404 ||
    Boolean(
      e.message &&
        /PGRST202|42883|42P01|Could not find the function|relation "public\.feature_requests" does not exist/i.test(
          e.message,
        ),
    )
  )
}

type SessionRevokedListener = (reason: 'forbidden' | 'unauthenticated') => void
const sessionRevokedListeners = new Set<SessionRevokedListener>()

export function onAdminSessionRevoked(
  listener: SessionRevokedListener,
): () => void {
  sessionRevokedListeners.add(listener)
  return () => {
    sessionRevokedListeners.delete(listener)
  }
}

export function notifyAdminSessionRevoked(
  reason: 'forbidden' | 'unauthenticated',
): void {
  for (const listener of sessionRevokedListeners) {
    listener(reason)
  }
}

async function verifySessionAfterError(err: unknown, fnName?: string): Promise<void> {
  if (fnName === 'me') return
  if (isUnauthenticatedError(err)) {
    notifyAdminSessionRevoked('unauthenticated')
    return
  }
  if (isForbiddenError(err)) {
    try {
      await adminApi.me()
      // Caller is still a valid admin (e.g. moderator calling an owner-only RPC).
      // Keep them signed in so the page displays the forbidden error banner.
    } catch (meErr) {
      if (isForbiddenError(meErr) || isUnauthenticatedError(meErr)) {
        notifyAdminSessionRevoked('forbidden')
      }
    }
  }
}

export async function handleRpcError(
  err: unknown,
  fnName?: string,
  lang: Lang = getCurrentLang(),
): Promise<string> {
  console.debug('[OurneyAdmin RPC Error]', fnName ?? 'rpc', err)
  await verifySessionAfterError(err, fnName)
  return formatAdminError(err, lang)
}

async function callAdminRpc<T>(
  fnName: string,
  args?: Record<string, unknown>,
): Promise<T> {
  assertSupabaseConfigured()
  const schemaClient = supabase.schema('admin')
  const { data, error } = args
    ? await schemaClient.rpc(fnName, args)
    : await schemaClient.rpc(fnName)
  if (error) {
    await verifySessionAfterError(error, fnName)
    throw error
  }
  return data as T
}

function normalizeFeatureRequestRow(raw: Partial<FeatureRequestRow>): FeatureRequestRow {
  const authorObj = raw.author ?? null
  return {
    id: String(raw.id ?? ''),
    title: String(raw.title ?? ''),
    body: String(raw.body ?? ''),
    category: (raw.category ?? 'other') as FeatureRequestCategory,
    status: (raw.status ?? 'new') as FeatureRequestStatus,
    vote_count: Number(raw.vote_count ?? 0),
    open_reports_count: Number(raw.open_reports_count ?? 0),
    author_id: raw.author_id ?? authorObj?.user_id ?? null,
    author_username: raw.author_username ?? authorObj?.username ?? null,
    author_display_name: raw.author_display_name ?? authorObj?.display_name ?? null,
    author: authorObj,
    admin_reply: raw.admin_reply ?? null,
    admin_replied_at: raw.admin_replied_at ?? null,
    shipped_at: raw.shipped_at ?? null,
    duplicate_of: raw.duplicate_of ?? null,
    merged_children_count: Number(raw.merged_children_count ?? 0),
    hidden: Boolean(raw.hidden ?? false),
    created_at: String(raw.created_at ?? ''),
    updated_at: String(raw.updated_at ?? ''),
  }
}

export const adminApi = {
  async signInWithOtp(email: string): Promise<void> {
    assertSupabaseConfigured()
    const { error } = await supabase.auth.signInWithOtp({
      email: email.trim().toLowerCase(),
      options: { shouldCreateUser: false },
    })
    if (error) throw error
  },

  async verifyOtp(email: string, token: string): Promise<void> {
    assertSupabaseConfigured()
    const { error } = await supabase.auth.verifyOtp({
      email: email.trim().toLowerCase(),
      token: token.trim(),
      type: 'email',
    })
    if (error) throw error
  },

  async signOut(): Promise<void> {
    await supabase.auth.signOut()
  },

  async me(): Promise<AdminIdentity> {
    const raw = await callAdminRpc<AdminIdentity | AdminIdentity[]>('me')
    const item = Array.isArray(raw) ? raw[0] : raw
    if (!item || !item.role) {
      const err = new Error('forbidden') as Error & { code?: string }
      err.code = '42501'
      throw err
    }
    return item
  },

  async overviewStats(
    p_days = 30,
    p_tz = 'Asia/Ho_Chi_Minh',
  ): Promise<OverviewStats> {
    const raw = await callAdminRpc<Partial<OverviewStats>>('overview_stats', {
      p_days,
      p_tz,
    })
    const frRaw = raw?.kpis?.feature_requests
    return {
      timezone: raw?.timezone ?? p_tz,
      days: Number(raw?.days ?? p_days),
      generated_at: raw?.generated_at ?? new Date().toISOString(),
      alerts: {
        open_reports: Number(raw?.alerts?.open_reports ?? 0),
        open_blocks: Number(raw?.alerts?.open_blocks ?? 0),
        overdue_reports: Number(raw?.alerts?.overdue_reports ?? 0),
        earliest_due_at: raw?.alerts?.earliest_due_at ?? null,
        earliest_hours_remaining:
          raw?.alerts?.earliest_hours_remaining !== null &&
          raw?.alerts?.earliest_hours_remaining !== undefined
            ? Number(raw.alerts.earliest_hours_remaining)
            : null,
        untriaged_feature_requests: Number(
          raw?.alerts?.untriaged_feature_requests ?? 0,
        ),
        failed_waitlist_emails: Number(
          raw?.alerts?.failed_waitlist_emails ?? 0,
        ),
        pending_storage_purge: Number(raw?.alerts?.pending_storage_purge ?? 0),
        stuck_storage_purge: Number(raw?.alerts?.stuck_storage_purge ?? 0),
      },
      kpis: {
        users: {
          total_auth: Number(raw?.kpis?.users?.total_auth ?? 0),
          live_profiles: Number(raw?.kpis?.users?.live_profiles ?? 0),
          deleted_profiles: Number(raw?.kpis?.users?.deleted_profiles ?? 0),
          banned_users: Number(raw?.kpis?.users?.banned_users ?? 0),
          new_today: Number(raw?.kpis?.users?.new_today ?? 0),
          new_7d: Number(raw?.kpis?.users?.new_7d ?? 0),
        },
        waitlist: {
          total: Number(raw?.kpis?.waitlist?.total ?? 0),
          new_7d: Number(raw?.kpis?.waitlist?.new_7d ?? 0),
          converted_count: Number(raw?.kpis?.waitlist?.converted_count ?? 0),
          converted_pct: Number(raw?.kpis?.waitlist?.converted_pct ?? 0),
          failed_emails: Number(raw?.kpis?.waitlist?.failed_emails ?? 0),
        },
        engagement: {
          dau: Number(raw?.kpis?.engagement?.dau ?? 0),
          wau: Number(raw?.kpis?.engagement?.wau ?? 0),
          mau: Number(raw?.kpis?.engagement?.mau ?? 0),
          avg_dau_7d: Number(raw?.kpis?.engagement?.avg_dau_7d ?? 0),
          stickiness_pct: Number(raw?.kpis?.engagement?.stickiness_pct ?? 0),
          auth_signins_1d: Number(raw?.kpis?.engagement?.auth_signins_1d ?? 0),
          auth_signins_7d: Number(raw?.kpis?.engagement?.auth_signins_7d ?? 0),
        },
        checkins: {
          today: Number(raw?.kpis?.checkins?.today ?? 0),
          last_7d: Number(raw?.kpis?.checkins?.last_7d ?? 0),
          camera_7d: Number(raw?.kpis?.checkins?.camera_7d ?? 0),
          library_7d: Number(raw?.kpis?.checkins?.library_7d ?? 0),
          camera_pct_7d: Number(raw?.kpis?.checkins?.camera_pct_7d ?? 100),
        },
        streaks: {
          streak_3d_plus: Number(raw?.kpis?.streaks?.streak_3d_plus ?? 0),
          streak_7d_plus: Number(raw?.kpis?.streaks?.streak_7d_plus ?? 0),
          streak_14d_plus: Number(raw?.kpis?.streaks?.streak_14d_plus ?? 0),
          streak_30d_plus: Number(raw?.kpis?.streaks?.streak_30d_plus ?? 0),
        },
        moderation: {
          open_reports: Number(raw?.kpis?.moderation?.open_reports ?? 0),
          open_blocks: Number(raw?.kpis?.moderation?.open_blocks ?? 0),
          overdue_count: Number(raw?.kpis?.moderation?.overdue_count ?? 0),
          sla_compliance_pct_30d: Number(
            raw?.kpis?.moderation?.sla_compliance_pct_30d ?? 100,
          ),
        },
        feature_requests: frRaw
          ? {
              new_7d: Number(frRaw.new_7d ?? 0),
              untriaged_count: Number(frRaw.untriaged_count ?? 0),
              open_count: Number(frRaw.open_count ?? 0),
              shipped_count: Number(frRaw.shipped_count ?? 0),
              top_voted: Array.isArray(frRaw.top_voted) ? frRaw.top_voted : [],
            }
          : null,
      },
      daily_growth: Array.isArray(raw?.daily_growth)
        ? raw.daily_growth.map((d) => ({
            day: String(d.day ?? ''),
            new_profiles: Number(d.new_profiles ?? 0),
            new_waitlist: Number(d.new_waitlist ?? 0),
          }))
        : [],
      daily_habit_pulse: Array.isArray(raw?.daily_habit_pulse)
        ? raw.daily_habit_pulse.map((d) => ({
            day: String(d.day ?? ''),
            dau: Number(d.dau ?? 0),
            live_checkins: Number(d.live_checkins ?? 0),
          }))
        : [],
      activation_funnel_7d: Array.isArray(raw?.activation_funnel_7d)
        ? raw.activation_funnel_7d.map((s) => ({
            step: String(s.step ?? ''),
            label: String(s.label ?? ''),
            count: Number(s.count ?? 0),
            conversion_pct: Number(s.conversion_pct ?? 0),
          }))
        : [],
      cohort_retention: Array.isArray(raw?.cohort_retention)
        ? raw.cohort_retention.map((c) => ({
            cohort_week: String(c.cohort_week ?? ''),
            cohort_size: Number(c.cohort_size ?? 0),
            d1_pct: Number(c.d1_pct ?? 0),
            d7_pct: Number(c.d7_pct ?? 0),
            d14_pct: Number(c.d14_pct ?? 0),
            d30_pct: Number(c.d30_pct ?? 0),
          }))
        : [],
      template_mix: Array.isArray(raw?.template_mix)
        ? raw.template_mix.map((m) => ({
            template: String(m.template ?? ''),
            active_journeys: Number(m.active_journeys ?? 0),
          }))
        : [],
    }
  },

  async listModerationQueue(params: {
    p_status?: string
    p_kind?: string
    p_reason?: string
    p_limit?: number
    p_offset?: number
  }): Promise<ModerationQueueResponse> {
    const data = await callAdminRpc<
      ModerationQueueRow[] | Partial<ModerationQueueResponse>
    >('list_moderation_queue', {
      p_status: params.p_status ?? 'open',
      p_kind: params.p_kind ?? 'all',
      p_reason: params.p_reason ?? 'all',
      p_limit: params.p_limit ?? 50,
      p_offset: params.p_offset ?? 0,
    })

    const items = Array.isArray(data) ? data : (data?.items ?? [])
    const rawSummary = !Array.isArray(data) ? data?.summary : undefined
    const summary: ModerationQueueSummary = {
      open_reports:
        rawSummary?.open_reports ??
        items.filter((r) => r.status === 'open' && r.kind === 'report').length,
      open_blocks:
        rawSummary?.open_blocks ??
        items.filter((r) => r.status === 'open' && r.kind === 'block').length,
      overdue_count:
        rawSummary?.overdue_count ??
        items.filter((r) => r.status === 'open' && (r.overdue || r.hours_remaining <= 0))
          .length,
      due_soon_count:
        rawSummary?.due_soon_count ??
        items.filter(
          (r) => r.status === 'open' && r.hours_remaining > 0 && r.hours_remaining <= 4,
        ).length,
      quarantined_count:
        rawSummary?.quarantined_count ??
        items.filter((r) => r.status === 'open' && r.auto_quarantined).length,
      median_handle_hours_30d: Number(rawSummary?.median_handle_hours_30d ?? 0),
    }

    return {
      summary,
      total: !Array.isArray(data) && typeof data?.total === 'number' ? data.total : items.length,
      items,
    }
  },

  async getModerationItem(p_queue_id: string): Promise<ModerationItemDetail> {
    const raw = await callAdminRpc<ModerationItemDetail>('get_moderation_item', {
      p_queue_id,
    })
    return {
      ...raw,
      target_user: raw.target_user ?? null,
      sibling_reports: Array.isArray(raw.sibling_reports)
        ? raw.sibling_reports
        : [],
      reported_content: raw.reported_content ?? {
        target_type: 'user',
        user_id: raw.target_user_id ?? null,
      },
    }
  },

  async revealReportedMedia(
    p_queue_id: string,
    p_purpose = 'Moderation reported media inspection',
  ): Promise<RevealReportedMediaResponse> {
    const raw = await callAdminRpc<Partial<RevealReportedMediaResponse>>(
      'reveal_reported_media',
      {
        p_queue_id,
        p_purpose,
      },
    )
    const allObjects = Array.isArray(raw?.objects) ? raw.objects : []
    const hasFullPhoto = allObjects.some((o) => o.kind === 'photo')
    const filteredObjects = hasFullPhoto
      ? allObjects.filter((o) => o.kind !== 'thumb')
      : allObjects

    const withUrls: RevealedMediaObject[] = []
    for (const obj of filteredObjects) {
      if (obj.signed_url) {
        withUrls.push(obj)
      } else {
        const { data } = await supabase.storage
          .from(obj.bucket)
          .createSignedUrl(obj.path, 120)
        withUrls.push({
          ...obj,
          signed_url: data?.signedUrl,
        })
      }
    }

    return {
      queue_id: raw?.queue_id ?? p_queue_id,
      expires_at: raw?.expires_at ?? new Date(Date.now() + 300_000).toISOString(),
      ttl_seconds: Number(raw?.ttl_seconds ?? 300),
      objects: withUrls,
    }
  },

  async quarantineModerationTarget(
    p_queue_id: string,
    p_note: string | null,
  ): Promise<void> {
    await callAdminRpc('quarantine_moderation_target', {
      p_queue_id,
      p_note,
    })
  },

  async resolveModeration(
    p_queue_id: string,
    p_action: 'dismiss' | 'remove_content' | 'action' | 'ban_user',
    p_note: string | null,
  ): Promise<void> {
    await callAdminRpc('resolve_moderation', {
      p_queue_id,
      p_action,
      p_note,
    })
  },

  async listObjectionableWords(params: {
    p_search?: string
    p_lang?: string
    p_mode?: string
    p_category?: string
    p_enabled?: boolean | null
  }): Promise<ObjectionableWordRow[]> {
    const data = await callAdminRpc<
      ObjectionableWordRow[] | { items?: ObjectionableWordRow[] }
    >('list_objectionable_words', {
      p_search: params.p_search || null,
      p_lang: !params.p_lang || params.p_lang === 'all' ? null : params.p_lang,
      p_mode: !params.p_mode || params.p_mode === 'all' ? null : params.p_mode,
      p_category:
        !params.p_category || params.p_category === 'all'
          ? null
          : params.p_category,
      p_enabled: params.p_enabled ?? null,
    })
    return Array.isArray(data) ? data : (data?.items ?? [])
  },

  async testContentFilter(p_text: string): Promise<FilterDryRunResult> {
    const raw = await callAdminRpc<Partial<FilterDryRunResult>>(
      'test_content_filter',
      { p_text },
    )
    const matches = Array.isArray(raw?.matches) ? raw.matches : []
    return {
      blocked: Boolean(raw?.blocked ?? matches.length > 0),
      term: raw?.term ?? matches[0]?.term ?? null,
      lang: raw?.lang ?? matches[0]?.lang ?? null,
      match_mode: raw?.match_mode ?? matches[0]?.match_mode ?? null,
      category: raw?.category ?? matches[0]?.category ?? null,
      matches,
    }
  },

  async upsertObjectionableWord(params: {
    p_term: string
    p_lang: 'vi' | 'en' | 'any'
    p_match_mode: 'diacritic_word' | 'word' | 'substring'
    p_category: 'csae' | 'self_harm' | 'violence' | 'sexual' | 'slur' | 'profanity'
    p_enabled: boolean
  }): Promise<void> {
    await callAdminRpc('upsert_objectionable_word', params)
  },

  async setObjectionableWordEnabled(
    p_term: string,
    p_enabled: boolean,
  ): Promise<void> {
    await callAdminRpc('set_objectionable_word_enabled', {
      p_term,
      p_enabled,
    })
  },

  async deleteObjectionableWord(
    p_term: string,
    p_reason = 'Removed via Admin Console',
  ): Promise<void> {
    await callAdminRpc('delete_objectionable_word', {
      p_term,
      p_reason,
    })
  },

  async featureRequestStats(): Promise<FeatureRequestStats> {
    const raw = await callAdminRpc<Partial<FeatureRequestStats>>(
      'feature_request_stats',
    )
    return {
      new: Number(raw?.new ?? 0),
      under_review: Number(raw?.under_review ?? 0),
      planned: Number(raw?.planned ?? 0),
      in_progress: Number(raw?.in_progress ?? 0),
      shipped: Number(raw?.shipped ?? 0),
      declined: Number(raw?.declined ?? 0),
      hidden: Number(raw?.hidden ?? 0),
      merged: Number(raw?.merged ?? 0),
      new_this_week: Number(raw?.new_this_week ?? 0),
      top_voted: Array.isArray(raw?.top_voted) ? raw.top_voted : [],
    }
  },

  async listFeatureRequests(params: {
    p_search?: string
    p_status?: string
    p_category?: string
    p_visibility?: string
    p_sort?: string
    p_limit?: number
    p_offset?: number
  }): Promise<FeatureRequestListResponse> {
    const data = await callAdminRpc<
      Array<Partial<FeatureRequestRow>> | { total?: number; items?: Array<Partial<FeatureRequestRow>> }
    >('list_feature_requests', {
      p_search: params.p_search || null,
      p_status:
        !params.p_status || params.p_status === 'all_active'
          ? null
          : params.p_status,
      p_category:
        !params.p_category || params.p_category === 'all'
          ? null
          : params.p_category,
      p_visibility: params.p_visibility ?? 'active',
      p_sort: params.p_sort ?? 'votes_desc',
      p_limit: params.p_limit ?? 50,
      p_offset: params.p_offset ?? 0,
    })
    const rawItems = Array.isArray(data) ? data : (data?.items ?? [])
    const items = rawItems.map(normalizeFeatureRequestRow)
    const total =
      !Array.isArray(data) && typeof data?.total === 'number'
        ? data.total
        : items.length
    return { total, items }
  },

  async getFeatureRequestDetail(p_id: string): Promise<FeatureRequestDetail> {
    const raw = await callAdminRpc<Partial<FeatureRequestDetail>>(
      'get_feature_request_detail',
      { p_id },
    )
    const base = normalizeFeatureRequestRow(raw ?? {})
    return {
      ...base,
      merged_children: Array.isArray(raw?.merged_children)
        ? raw.merged_children
        : [],
      reports: Array.isArray(raw?.reports) ? raw.reports : [],
      voters: Array.isArray(raw?.voters) ? raw.voters : [],
    }
  },

  async updateFeatureRequest(params: {
    p_id: string
    p_status: FeatureRequestStatus
    p_category: FeatureRequestCategory
    p_admin_reply: string | null
    p_hidden: boolean
    p_reason: string | null
  }): Promise<void> {
    await callAdminRpc('update_feature_request', {
      p_id: params.p_id,
      p_status: params.p_status,
      p_category: params.p_category,
      p_admin_reply: params.p_admin_reply,
      p_hidden: params.p_hidden,
      p_reason: params.p_reason,
    })
  },

  async mergeFeatureRequest(params: {
    p_source_id: string
    p_target_id: string
    p_reason: string
  }): Promise<void> {
    await callAdminRpc('merge_feature_request', {
      p_source_id: params.p_source_id,
      p_target_id: params.p_target_id,
      p_reason: params.p_reason,
    })
  },

  async waitlistSummary(p_days = 30): Promise<WaitlistSummary> {
    const raw = await callAdminRpc<Partial<WaitlistSummary>>(
      'waitlist_summary',
      { p_days },
    )
    return {
      total: Number(raw?.total ?? 0),
      new_7d: Number(raw?.new_7d ?? 0),
      ios_only: Number(raw?.ios_only ?? 0),
      android_only: Number(raw?.android_only ?? 0),
      both_platforms: Number(raw?.both_platforms ?? 0),
      lang_vi: Number(raw?.lang_vi ?? 0),
      lang_en: Number(raw?.lang_en ?? 0),
      mail_sent: Number(raw?.mail_sent ?? 0),
      mail_failed: Number(raw?.mail_failed ?? 0),
      mail_unsent: Number(raw?.mail_unsent ?? 0),
      converted_count: Number(raw?.converted_count ?? 0),
      waiting_count: Number(
        raw?.waiting_count ??
          Math.max(0, Number(raw?.total ?? 0) - Number(raw?.converted_count ?? 0)),
      ),
      by_source: Array.isArray(raw?.by_source) ? raw.by_source : [],
      daily: Array.isArray(raw?.daily) ? raw.daily : [],
    }
  },

  async listWaitlist(params: {
    p_search?: string
    p_lang?: string
    p_platform?: string
    p_mail_status?: string
    p_converted?: string
    p_limit?: number
    p_offset?: number
  }): Promise<WaitlistListResponse> {
    const data = await callAdminRpc<
      WaitlistRow[] | { total?: number; items?: WaitlistRow[] }
    >('list_waitlist', {
      p_search: params.p_search || null,
      p_lang: params.p_lang ?? 'all',
      p_platform: params.p_platform ?? 'all',
      p_mail_status: params.p_mail_status ?? 'all',
      p_converted: params.p_converted ?? 'all',
      p_limit: params.p_limit ?? 50,
      p_offset: params.p_offset ?? 0,
    })
    const items = Array.isArray(data) ? data : (data?.items ?? [])
    const total =
      !Array.isArray(data) && typeof data?.total === 'number'
        ? data.total
        : items.length
    return { total, items }
  },

  async exportWaitlist(params: {
    p_search?: string
    p_lang?: string
    p_platform?: string
    p_mail_status?: string
    p_converted?: string
  }): Promise<WaitlistExportRow[] | string> {
    const data = await callAdminRpc<
      string | WaitlistExportRow[] | { items?: WaitlistExportRow[] }
    >('export_waitlist', {
      p_search: params.p_search || null,
      p_lang: params.p_lang ?? 'all',
      p_platform: params.p_platform ?? 'all',
      p_mail_status: params.p_mail_status ?? 'all',
      p_converted: params.p_converted ?? 'all',
    })
    if (typeof data === 'string') return data
    return Array.isArray(data) ? data : (data?.items ?? [])
  },

  async deleteWaitlistEntry(p_id: string, p_reason: string): Promise<void> {
    await callAdminRpc('delete_waitlist_entry', { p_id, p_reason })
  },

  async listUsers(params: {
    p_search?: string
    p_status?: string
    p_sort?: string
    p_limit?: number
    p_offset?: number
  }): Promise<AdminUserListResponse> {
    const data = await callAdminRpc<
      AdminUserRow[] | { total?: number; items?: AdminUserRow[] }
    >('list_users', {
      p_search: params.p_search || null,
      p_status: params.p_status ?? 'all',
      p_sort: params.p_sort ?? 'created_at',
      p_limit: params.p_limit ?? 50,
      p_offset: params.p_offset ?? 0,
    })
    const items = Array.isArray(data) ? data : (data?.items ?? [])
    const total =
      !Array.isArray(data) && typeof data?.total === 'number'
        ? data.total
        : items.length
    return { total, items }
  },

  async getUserDetail(p_user: string): Promise<AdminUserDetail> {
    const raw = await callAdminRpc<AdminUserDetail>('get_user_detail', {
      p_user,
    })
    return {
      ...raw,
      activity: {
        active_journeys_count: Number(raw.activity?.active_journeys_count ?? 0),
        total_journeys_count: Number(raw.activity?.total_journeys_count ?? 0),
        group_journeys_count: Number(raw.activity?.group_journeys_count ?? 0),
        total_checkins: Number(raw.activity?.total_checkins ?? 0),
        best_streak: Number(raw.activity?.best_streak ?? 0),
        friends_count: Number(raw.activity?.friends_count ?? 0),
      },
      trust: {
        open_reports_against: Number(raw.trust?.open_reports_against ?? 0),
        total_actioned_reports: Number(raw.trust?.total_actioned_reports ?? 0),
        blocked_by_count: Number(raw.trust?.blocked_by_count ?? 0),
        moderation_record: raw.trust?.moderation_record ?? null,
        recent_reports_against: Array.isArray(raw.trust?.recent_reports_against)
          ? raw.trust.recent_reports_against
          : [],
        audit_history: Array.isArray(raw.trust?.audit_history)
          ? raw.trust.audit_history
          : [],
      },
    }
  },

  async banUser(params: {
    p_user: string
    p_reason: string
    p_wipe_ugc: boolean
  }): Promise<void> {
    await callAdminRpc('ban_user', params)
  },

  async unbanUser(p_user: string, p_reason: string): Promise<void> {
    await callAdminRpc('unban_user', { p_user, p_reason })
  },

  async revokeUserSessions(p_user: string, p_reason: string): Promise<void> {
    await callAdminRpc('revoke_user_sessions', { p_user, p_reason })
  },

  async journeyStats(): Promise<JourneyStats> {
    const raw = await callAdminRpc<Partial<JourneyStats>>('journey_stats')
    return {
      total: Number(raw?.total ?? 0),
      active: Number(raw?.active ?? 0),
      ended: Number(raw?.ended ?? 0),
      archived: Number(raw?.archived ?? 0),
      solo_count: Number(raw?.solo_count ?? 0),
      group_count: Number(raw?.group_count ?? 0),
      couple_count: Number(raw?.couple_count ?? 0),
      live_count: Number(raw?.live_count ?? 0),
      imported_count: Number(raw?.imported_count ?? 0),
      public_links_count: Number(raw?.public_links_count ?? 0),
      total_public_views: Number(raw?.total_public_views ?? 0),
      by_template: Array.isArray(raw?.by_template) ? raw.by_template : [],
      by_skin: Array.isArray(raw?.by_skin) ? raw.by_skin : [],
    }
  },

  async listJourneys(params: {
    p_search?: string
    p_kind?: string
    p_template?: string
    p_status?: string
    p_public_only?: boolean
    p_limit?: number
    p_offset?: number
  }): Promise<AdminJourneyListResponse> {
    const data = await callAdminRpc<
      AdminJourneyRow[] | { total?: number; items?: AdminJourneyRow[] }
    >('list_journeys', {
      p_search: params.p_search || null,
      p_kind: params.p_kind ?? 'all',
      p_template: params.p_template ?? 'all',
      p_status: params.p_status ?? 'all',
      p_public_only: params.p_public_only ?? false,
      p_limit: params.p_limit ?? 50,
      p_offset: params.p_offset ?? 0,
    })
    const items = Array.isArray(data) ? data : (data?.items ?? [])
    const total =
      !Array.isArray(data) && typeof data?.total === 'number'
        ? data.total
        : items.length
    return { total, items }
  },

  async revokeJourneyPublicLink(
    p_journey: string,
    p_reason: string,
  ): Promise<void> {
    await callAdminRpc('revoke_journey_public_link', {
      p_journey,
      p_reason,
    })
  },

  async listAuditLog(params: {
    p_admin?: string | null
    p_action_prefix?: string
    p_target_type?: string
    p_target_id?: string
    p_before_id?: number | null
    p_limit?: number
  }): Promise<AuditLogListResponse> {
    const data = await callAdminRpc<
      AuditLogRow[] | Partial<AuditLogListResponse>
    >('list_audit_log', {
      p_admin: params.p_admin ?? null,
      p_action_prefix: params.p_action_prefix || null,
      p_target_type:
        !params.p_target_type || params.p_target_type === 'all'
          ? null
          : params.p_target_type,
      p_target_id: params.p_target_id || null,
      p_before_id: params.p_before_id ?? null,
      p_limit: params.p_limit ?? 50,
    })
    const items = Array.isArray(data) ? data : (data?.items ?? [])
    const next_before_id =
      !Array.isArray(data) && typeof data?.next_before_id === 'number'
        ? data.next_before_id
        : null
    return { items, next_before_id }
  },

  async listAdmins(): Promise<AdminIdentity[]> {
    const data = await callAdminRpc<
      AdminIdentity[] | { items?: AdminIdentity[] }
    >('list_admins')
    return Array.isArray(data) ? data : (data?.items ?? [])
  },

  async upsertAdminUser(params: {
    p_email_or_uid: string
    p_role: AdminRole
    p_note?: string
  }): Promise<void> {
    await callAdminRpc('upsert_admin_user', {
      p_email_or_uid: params.p_email_or_uid,
      p_role: params.p_role,
      p_note: params.p_note ?? null,
    })
  },

  async removeAdminUser(p_user: string, p_reason: string): Promise<void> {
    await callAdminRpc('remove_admin_user', { p_user, p_reason })
  },

  async systemHealth(): Promise<SystemHealth> {
    const raw = await callAdminRpc<Partial<SystemHealth>>('system_health')
    return {
      storage_purge: {
        due_now_count: Number(raw?.storage_purge?.due_now_count ?? 0),
        backing_off_count: Number(raw?.storage_purge?.backing_off_count ?? 0),
        stuck_count: Number(raw?.storage_purge?.stuck_count ?? 0),
        total_queued: Number(raw?.storage_purge?.total_queued ?? 0),
        sample_errors: Array.isArray(raw?.storage_purge?.sample_errors)
          ? raw.storage_purge.sample_errors
          : [],
      },
      moderation_notifications: {
        unnotified_open_count: Number(
          raw?.moderation_notifications?.unnotified_open_count ?? 0,
        ),
        leased_count: Number(raw?.moderation_notifications?.leased_count ?? 0),
        overdue_open_count: Number(
          raw?.moderation_notifications?.overdue_open_count ?? 0,
        ),
      },
      admins_count: {
        owners: Number(raw?.admins_count?.owners ?? 0),
        moderators: Number(raw?.admins_count?.moderators ?? 0),
      },
    }
  },

  async resetStuckStoragePurge(
    p_reason = 'Manual reset from Admin Settings',
  ): Promise<void> {
    await callAdminRpc('reset_stuck_storage_purge', { p_reason })
  },

  async invokeAdminAction<T = Record<string, unknown>>(
    payload:
      | { action: 'waitlist_resend'; waitlist_id: string }
      | { action: 'waitlist_resend_failed'; limit?: number }
      | {
          action: 'delete_user'
          user_id: string
          reason: string
          ticket_ref?: string
        }
      | { action: 'run_storage_sweep'; limit?: number }
      | { action: 'trigger_moderation_notify'; limit?: number },
  ): Promise<T> {
    assertSupabaseConfigured()
    const { data, error } = await supabase.functions.invoke('admin-action', {
      body: payload,
    })
    if (error) {
      let status: number | undefined =
        typeof (error as { status?: unknown }).status === 'number'
          ? ((error as { status?: number }).status ?? undefined)
          : undefined
      let code: string | undefined =
        typeof (error as { code?: unknown }).code === 'string'
          ? ((error as { code?: string }).code ?? undefined)
          : undefined
      const ctx = (
        error as {
          context?: {
            status?: unknown
            clone?: () => { json?: () => Promise<unknown>; text?: () => Promise<string> }
            json?: () => Promise<unknown>
            text?: () => Promise<string>
          }
        }
      ).context
      if (ctx && typeof ctx === 'object') {
        if (typeof ctx.status === 'number') {
          status = ctx.status
        }
        try {
          const reader = typeof ctx.clone === 'function' ? ctx.clone() : ctx
          if (typeof reader.json === 'function') {
            const parsed = (await reader.json()) as {
              error?: unknown
              code?: unknown
              message?: unknown
            } | null
            const extracted =
              typeof parsed?.error === 'string'
                ? parsed.error
                : typeof parsed?.code === 'string'
                  ? parsed.code
                  : typeof parsed?.message === 'string'
                    ? parsed.message
                    : undefined
            if (extracted) {
              code = extracted
            }
          } else if (typeof reader.text === 'function') {
            const rawText = (await reader.text()).trim()
            if (rawText) {
              try {
                const parsed = JSON.parse(rawText) as {
                  error?: unknown
                  code?: unknown
                }
                const extracted =
                  typeof parsed?.error === 'string'
                    ? parsed.error
                    : typeof parsed?.code === 'string'
                      ? parsed.code
                      : rawText
                code = extracted
              } catch {
                code = rawText
              }
            }
          }
        } catch {
          // Ignore body parse errors on already-consumed or empty responses
        }
      }
      const enriched = Object.assign(
        new Error(code || (error instanceof Error ? error.message : String(error))),
        {
          status,
          code,
          cause: error,
        },
      )
      await verifySessionAfterError(enriched, 'admin-action')
      throw enriched
    }
    return data as T
  },
}
