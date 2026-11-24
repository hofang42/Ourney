import { createClient, type SupabaseClient } from '@supabase/supabase-js'
import type { WaitlistExportRow } from './csv'

export type AdminRole = 'owner' | 'moderator'

export interface AdminIdentity {
  user_id: string
  email: string
  role: AdminRole
  username: string | null
  display_name: string | null
  note: string | null
  created_at?: string
}

export interface OverviewStats {
  urgent: {
    open_reports: number
    overdue_reports: number
    earliest_hours_remaining: number | null
    untriaged_feature_requests: number
    failed_waitlist_emails: number
    stuck_storage_purge: number
    pending_storage_purge: number
  }
  kpis: {
    total_users: number
    total_auth_users: number
    new_users_today: number
    new_users_7d: number
    waitlist_total: number
    waitlist_7d: number
    waitlist_converted_pct: number
    dau: number
    wau: number
    mau: number
    stickiness_pct: number
    checkins_today: number
    checkins_7d: number
    camera_live_pct: number
    active_streaks_3d: number
    active_streaks_7d: number
    open_moderation_reports: number
    open_block_signals: number
    sla_24h_compliance_pct: number
    feature_requests_installed: boolean
    new_feature_requests_7d: number
    untriaged_feature_requests: number
    top_voted_request: {
      id: string
      title: string
      vote_count: number
      category: string
      status: string
    } | null
  }
  daily_growth: Array<{
    day: string
    new_users: number
    waitlist_signups: number
  }>
  daily_habit: Array<{
    day: string
    dau: number
    live_checkins: number
  }>
  activation_funnel: Array<{
    step: string
    label_vi: string
    label_en: string
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
  top_feature_requests: Array<{
    id: string
    title: string
    category: string
    status: string
    vote_count: number
  }>
  template_mix: Array<{
    template_id: string
    active_journeys: number
  }>
}

export interface ModerationQueueRow {
  id: string
  kind: 'report' | 'block'
  status: 'open' | 'actioned' | 'dismissed'
  reason: string
  target_type: 'checkin' | 'message' | 'feature_request' | 'user'
  target_id: string
  target_user_id: string
  target_username: string
  target_prior_actions: number
  target_blocked_by_count: number
  actor_username: string
  distinct_open_reporters: number
  is_quarantined: boolean
  has_reported_media: boolean
  created_at: string
  due_at: string
  handled_at: string | null
  hours_remaining: number
}

export interface ModerationItemDetail {
  queue: ModerationQueueRow
  target_user: {
    user_id: string
    username: string
    display_name: string
    created_at: string
    prior_actioned_reports: number
    blocked_by_count: number
    is_banned: boolean
  }
  excerpt: {
    target_type: 'checkin' | 'message' | 'feature_request' | 'user'
    title: string | null
    body: string | null
    extra_note: string | null
    created_at: string | null
  }
  has_reported_media: boolean
  media_objects: Array<{
    bucket_id: string
    object_path: string
    label: string
  }>
  sibling_reports: Array<{
    id: string
    reporter_username: string
    reason: string
    note: string | null
    created_at: string
  }>
}

export interface RevealedMediaGrant {
  bucket_id: string
  object_path: string
  expires_at: string
  signed_url?: string
}

export interface ObjectionableWordRow {
  term: string
  lang: 'vi' | 'en' | 'any'
  match_mode: 'diacritic_word' | 'word' | 'substring'
  category: 'csae' | 'self_harm' | 'violence' | 'sexual' | 'slur' | 'profanity'
  enabled: boolean
  created_at: string
}

export interface FilterDryRunResult {
  allowed: boolean
  matched_term: string | null
  lang: string | null
  match_mode: string | null
  category: string | null
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
  admin_reply: string | null
  admin_replied_at: string | null
  shipped_at: string | null
  duplicate_of: string | null
  merged_children_count: number
  hidden: boolean
  created_at: string
  updated_at: string
}

export interface FeatureRequestVoterRow {
  user_id: string
  username: string
  display_name: string
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
    reporter_username: string
    reason: string
    note: string | null
    status: string
    created_at: string
  }>
  voters: FeatureRequestVoterRow[]
}

export interface WaitlistSummary {
  total: number
  ios_only: number
  android_only: number
  both_platforms: number
  vi_count: number
  en_count: number
  sent_count: number
  failed_count: number
  unsent_count: number
  converted_count: number
  top_sources: Array<{ source: string; count: number }>
  daily: Array<{ day: string; vi: number; en: number }>
}

export interface WaitlistRow {
  id: string
  email: string
  lang: 'vi' | 'en'
  platforms: string[]
  source: string
  created_at: string
  confirmation_sent_at: string | null
  confirmation_error: string | null
  registered_in_app: boolean
}

export interface AdminUserRow {
  user_id: string
  username: string | null
  display_name: string | null
  email: string | null
  has_phone: boolean
  has_password: boolean
  terms_version: number
  status: 'active' | 'incomplete_onboarding' | 'banned' | 'soft_deleted'
  active_journeys: number
  total_journeys: number
  group_journeys: number
  total_checkins: number
  best_streak: number
  feature_requests_count: number
  open_reports_against: number
  total_actioned_reports: number
  blocked_by_count: number
  last_active_at: string | null
  created_at: string
}

export interface AdminUserDetail extends AdminUserRow {
  banned_until: string | null
  ban_reason: string | null
  wiped_ugc: boolean
  feature_requests: Array<{
    id: string
    title: string
    status: string
    vote_count: number
    created_at: string
  }>
  moderation_history: Array<{
    id: string
    action: string
    reason: string | null
    created_at: string
  }>
}

export interface JourneyStats {
  total_active: number
  total_ended: number
  total_archived: number
  solo_count: number
  group_count: number
  couple_count: number
  live_count: number
  imported_count: number
  active_public_links: number
  total_public_views: number
}

export interface AdminJourneyRow {
  id: string
  owner_id: string
  owner_username: string
  kind: 'solo' | 'group' | 'couple'
  origin: 'live' | 'imported'
  template_id: string
  skin_id: string
  status: 'active' | 'ended' | 'archived'
  visibility: 'private' | 'group' | 'link'
  public_token: string | null
  title: string | null
  active_members: number
  max_members: number
  checkin_count: number
  public_views: number
  created_at: string
}

export interface AuditLogRow {
  id: number
  created_at: string
  admin_id: string | null
  admin_email: string
  action: string
  target_type: string
  target_id: string | null
  reason: string | null
  meta: Record<string, unknown>
}

export interface SystemHealth {
  storage_purge: {
    due_now_count: number
    backing_off_count: number
    stuck_count: number
    sample_errors: Array<{
      bucket: string
      path_prefix: string
      attempts: number
      last_error: string
    }>
  }
  moderation_alerts: {
    unnotified_open_count: number
    oldest_unnotified_at: string | null
  }
}

const supabaseUrl =
  (import.meta.env.VITE_SUPABASE_URL as string | undefined) ||
  'https://example.supabase.co'
const supabaseAnonKey =
  (import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined) ||
  'sb_publishable_placeholder'

export const supabase: SupabaseClient = createClient(
  supabaseUrl,
  supabaseAnonKey,
  {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
    },
  },
)

export function isDemoMode(): boolean {
  if (typeof window === 'undefined') return false
  try {
    const params = new URLSearchParams(window.location.search)
    if (params.get('demo') === '1') {
      window.sessionStorage.setItem('ourney_admin_demo', '1')
      return true
    }
    if (window.sessionStorage.getItem('ourney_admin_demo') === '1') return true
    if (window.localStorage.getItem('ourney_admin_demo') === '1') return true
  } catch {
    return false
  }
  return false
}

export function isForbiddenError(err: unknown): boolean {
  if (!err || typeof err !== 'object') return false
  const e = err as { code?: string; status?: number; message?: string }
  return (
    e.code === '42501' ||
    e.status === 403 ||
    Boolean(e.message && /forbidden|permission denied|not_admin|42501/i.test(e.message))
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
        /PGRST202|404|not_installed|feature_requests|Could not find the function/i.test(
          e.message,
        ),
    )
  )
}

async function callAdminRpc<T>(
  fnName: string,
  args?: Record<string, unknown>,
): Promise<T> {
  const schemaClient = supabase.schema('admin')
  const { data, error } = args
    ? await schemaClient.rpc(fnName, args)
    : await schemaClient.rpc(fnName)
  if (error) {
    throw error
  }
  return data as T
}

export const DEMO_OVERVIEW: OverviewStats = {
  urgent: {
    open_reports: 2,
    overdue_reports: 0,
    earliest_hours_remaining: 3.4,
    untriaged_feature_requests: 4,
    failed_waitlist_emails: 1,
    stuck_storage_purge: 0,
    pending_storage_purge: 3,
  },
  kpis: {
    total_users: 482,
    total_auth_users: 510,
    new_users_today: 19,
    new_users_7d: 114,
    waitlist_total: 1280,
    waitlist_7d: 245,
    waitlist_converted_pct: 34.2,
    dau: 214,
    wau: 368,
    mau: 455,
    stickiness_pct: 47.0,
    checkins_today: 189,
    checkins_7d: 1246,
    camera_live_pct: 84.5,
    active_streaks_3d: 162,
    active_streaks_7d: 94,
    open_moderation_reports: 2,
    open_block_signals: 1,
    sla_24h_compliance_pct: 100,
    feature_requests_installed: true,
    new_feature_requests_7d: 11,
    untriaged_feature_requests: 4,
    top_voted_request: {
      id: 'fr-101',
      title: 'Widget màn hình khóa iOS hiển thị chuỗi lửa cùng nhóm',
      vote_count: 68,
      category: 'streaks',
      status: 'planned',
    },
  },
  daily_growth: [
    { day: '18/11', new_users: 14, waitlist_signups: 32 },
    { day: '19/11', new_users: 16, waitlist_signups: 41 },
    { day: '20/11', new_users: 15, waitlist_signups: 38 },
    { day: '21/11', new_users: 21, waitlist_signups: 49 },
    { day: '22/11', new_users: 18, waitlist_signups: 44 },
    { day: '23/11', new_users: 22, waitlist_signups: 52 },
    { day: '24/11', new_users: 19, waitlist_signups: 39 },
  ],
  daily_habit: [
    { day: '18/11', dau: 172, live_checkins: 151 },
    { day: '19/11', dau: 184, live_checkins: 164 },
    { day: '20/11', dau: 191, live_checkins: 170 },
    { day: '21/11', dau: 198, live_checkins: 176 },
    { day: '22/11', dau: 205, live_checkins: 182 },
    { day: '23/11', dau: 211, live_checkins: 188 },
    { day: '24/11', dau: 214, live_checkins: 189 },
  ],
  activation_funnel: [
    {
      step: 'auth_signup',
      label_vi: 'Đăng ký tài khoản',
      label_en: 'Auth Signup',
      count: 510,
      conversion_pct: 100,
    },
    {
      step: 'terms_accepted',
      label_vi: 'Đồng ý điều khoản',
      label_en: 'Terms Accepted',
      count: 496,
      conversion_pct: 97.3,
    },
    {
      step: 'profile_created',
      label_vi: 'Tạo hồ sơ cá nhân',
      label_en: 'Profile Created',
      count: 482,
      conversion_pct: 94.5,
    },
    {
      step: 'first_journey',
      label_vi: 'Tạo hoặc vào hành trình',
      label_en: 'First Journey',
      count: 438,
      conversion_pct: 85.9,
    },
    {
      step: 'first_checkin',
      label_vi: 'Chụp ảnh ngày đầu',
      label_en: 'First Live Check-in',
      count: 374,
      conversion_pct: 73.3,
    },
    {
      step: 'social_connected',
      label_vi: 'Kết nối nhóm / bạn bè',
      label_en: 'Squad / Friend Connected',
      count: 268,
      conversion_pct: 52.5,
    },
  ],
  cohort_retention: [
    { cohort_week: 'W43 (21/10)', cohort_size: 84, d1_pct: 78, d7_pct: 61, d14_pct: 52, d30_pct: 46 },
    { cohort_week: 'W44 (28/10)', cohort_size: 96, d1_pct: 81, d7_pct: 64, d14_pct: 55, d30_pct: 48 },
    { cohort_week: 'W45 (04/11)', cohort_size: 108, d1_pct: 82, d7_pct: 66, d14_pct: 58, d30_pct: 0 },
    { cohort_week: 'W46 (11/11)', cohort_size: 110, d1_pct: 85, d7_pct: 69, d14_pct: 0, d30_pct: 0 },
    { cohort_week: 'W47 (18/11)', cohort_size: 114, d1_pct: 86, d7_pct: 0, d14_pct: 0, d30_pct: 0 },
  ],
  top_feature_requests: [
    {
      id: 'fr-101',
      title: 'Widget màn hình khóa iOS hiển thị chuỗi lửa cùng nhóm',
      category: 'streaks',
      status: 'planned',
      vote_count: 68,
    },
    {
      id: 'fr-102',
      title: 'Xuất video timelapse 30 ngày giảm cân từ khung Ghost Align',
      category: 'sharing',
      status: 'in_progress',
      vote_count: 54,
    },
    {
      id: 'fr-103',
      title: 'Chế độ nhắc chụp ảnh theo khung giờ riêng của từng thành viên',
      category: 'squad',
      status: 'under_review',
      vote_count: 41,
    },
  ],
  template_mix: [
    { template_id: 'english_daily', active_journeys: 164 },
    { template_id: 'weight_loss', active_journeys: 128 },
    { template_id: 'workout_30', active_journeys: 112 },
    { template_id: 'couple', active_journeys: 86 },
    { template_id: 'travel', active_journeys: 64 },
    { template_id: 'custom', active_journeys: 58 },
  ],
}

export const DEMO_MODERATION_QUEUE: ModerationQueueRow[] = [
  {
    id: 'mq-01',
    kind: 'report',
    status: 'open',
    reason: 'harassment',
    target_type: 'checkin',
    target_id: 'chk-901',
    target_user_id: 'usr-88',
    target_username: 'hung_gym99',
    target_prior_actions: 1,
    target_blocked_by_count: 2,
    actor_username: 'linh_ielts',
    distinct_open_reporters: 2,
    is_quarantined: false,
    has_reported_media: true,
    created_at: '2026-11-23T17:10:00Z',
    due_at: '2026-11-24T17:10:00Z',
    handled_at: null,
    hours_remaining: 3.4,
  },
  {
    id: 'mq-02',
    kind: 'report',
    status: 'open',
    reason: 'spam',
    target_type: 'message',
    target_id: 'msg-404',
    target_user_id: 'usr-92',
    target_username: 'promo_fast',
    target_prior_actions: 2,
    target_blocked_by_count: 4,
    actor_username: 'minh_run',
    distinct_open_reporters: 3,
    is_quarantined: true,
    has_reported_media: false,
    created_at: '2026-11-24T04:00:00Z',
    due_at: '2026-11-25T04:00:00Z',
    handled_at: null,
    hours_remaining: 14.2,
  },
]

export const DEMO_FEATURE_REQUEST_STATS: FeatureRequestStats = {
  new: 4,
  under_review: 3,
  planned: 5,
  in_progress: 2,
  shipped: 7,
  declined: 1,
  hidden: 0,
  merged: 2,
  new_this_week: 11,
  top_voted: [
    {
      id: 'fr-101',
      title: 'Widget màn hình khóa iOS hiển thị chuỗi lửa cùng nhóm',
      category: 'squad',
      status: 'planned',
      vote_count: 68,
    },
    {
      id: 'fr-102',
      title: 'Xuất video timelapse 30 ngày giảm cân từ khung Ghost Align',
      category: 'sharing',
      status: 'in_progress',
      vote_count: 54,
    },
    {
      id: 'fr-103',
      title: 'Chế độ nhắc chụp ảnh theo khung giờ riêng của từng thành viên',
      category: 'journeys',
      status: 'under_review',
      vote_count: 41,
    },
  ],
}

export const DEMO_FEATURE_REQUESTS: FeatureRequestRow[] = [
  {
    id: 'fr-101',
    title: 'Widget màn hình khóa iOS hiển thị chuỗi lửa cùng nhóm',
    body: 'Mong Ourney có widget ngoài màn hình khóa để cả nhóm IELTS thấy ai chưa nộp bài trong ngày.',
    category: 'squad',
    status: 'planned',
    vote_count: 68,
    open_reports_count: 0,
    author_id: 'usr-10',
    author_username: 'linh_ielts',
    author_display_name: 'Linh Nguyễn',
    admin_reply: 'Đội ngũ Ourney đang thiết kế Widget Lock Screen cho bản iOS 1.1 vào tháng tới.',
    admin_replied_at: '2026-11-22T09:30:00Z',
    shipped_at: null,
    duplicate_of: null,
    merged_children_count: 2,
    hidden: false,
    created_at: '2026-11-12T08:00:00Z',
    updated_at: '2026-11-22T09:30:00Z',
  },
  {
    id: 'fr-102',
    title: 'Xuất video timelapse 30 ngày giảm cân từ khung Ghost Align',
    body: 'Khi đủ 30 ngày trong hành trình Quiet Transformer, cho phép xuất clip MP4 ghép mượt từng ngày.',
    category: 'sharing',
    status: 'in_progress',
    vote_count: 54,
    open_reports_count: 0,
    author_id: 'usr-12',
    author_username: 'thao_fit',
    author_display_name: 'Thảo Phạm',
    admin_reply: null,
    admin_replied_at: null,
    shipped_at: null,
    duplicate_of: null,
    merged_children_count: 0,
    hidden: false,
    created_at: '2026-11-14T10:15:00Z',
    updated_at: '2026-11-21T11:00:00Z',
  },
  {
    id: 'fr-103',
    title: 'Thêm widget iOS xem streak nhóm',
    body: 'Muốn xem nhanh nhóm học tiếng Anh trên màn hình chính iPhone.',
    category: 'squad',
    status: 'new',
    vote_count: 9,
    open_reports_count: 0,
    author_id: 'usr-15',
    author_username: 'khoa_dev',
    author_display_name: 'Khoa Trần',
    admin_reply: null,
    admin_replied_at: null,
    shipped_at: null,
    duplicate_of: null,
    merged_children_count: 0,
    hidden: false,
    created_at: '2026-11-23T15:20:00Z',
    updated_at: '2026-11-23T15:20:00Z',
  },
]

export const adminApi = {
  async signInWithOtp(email: string): Promise<void> {
    const { error } = await supabase.auth.signInWithOtp({
      email: email.trim().toLowerCase(),
      options: { shouldCreateUser: false },
    })
    if (error) throw error
  },

  async verifyOtp(email: string, token: string): Promise<void> {
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
    if (isDemoMode()) {
      return {
        user_id: '00000000-0000-0000-0000-000000000001',
        email: 'owner@ourney.tech',
        role: 'owner',
        username: 'hoang_owner',
        display_name: 'Hoàng (Founder)',
        note: 'Primary Owner',
      }
    }
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
    if (isDemoMode()) return DEMO_OVERVIEW
    const raw = await callAdminRpc<Partial<OverviewStats>>('overview_stats', {
      p_days,
      p_tz,
    })
    return {
      urgent: {
        ...DEMO_OVERVIEW.urgent,
        ...(raw?.urgent ?? {}),
      },
      kpis: {
        ...DEMO_OVERVIEW.kpis,
        ...(raw?.kpis ?? {}),
      },
      daily_growth: raw?.daily_growth ?? DEMO_OVERVIEW.daily_growth,
      daily_habit: raw?.daily_habit ?? DEMO_OVERVIEW.daily_habit,
      activation_funnel:
        raw?.activation_funnel ?? DEMO_OVERVIEW.activation_funnel,
      cohort_retention: raw?.cohort_retention ?? DEMO_OVERVIEW.cohort_retention,
      top_feature_requests:
        raw?.top_feature_requests ?? DEMO_OVERVIEW.top_feature_requests,
      template_mix: raw?.template_mix ?? DEMO_OVERVIEW.template_mix,
    }
  },

  async listModerationQueue(params: {
    p_status?: string
    p_kind?: string
    p_reason?: string
    p_limit?: number
    p_offset?: number
  }): Promise<ModerationQueueRow[]> {
    if (isDemoMode()) return DEMO_MODERATION_QUEUE
    const data = await callAdminRpc<
      ModerationQueueRow[] | { items?: ModerationQueueRow[] }
    >('list_moderation_queue', {
      p_status: params.p_status ?? 'open',
      p_kind: params.p_kind ?? 'all',
      p_reason: params.p_reason ?? 'all',
      p_limit: params.p_limit ?? 50,
      p_offset: params.p_offset ?? 0,
    })
    return Array.isArray(data) ? data : (data?.items ?? [])
  },

  async getModerationItem(p_queue_id: string): Promise<ModerationItemDetail> {
    if (isDemoMode()) {
      const q =
        DEMO_MODERATION_QUEUE.find((item) => item.id === p_queue_id) ??
        DEMO_MODERATION_QUEUE[0]
      return {
        queue: q,
        target_user: {
          user_id: q.target_user_id,
          username: q.target_username,
          display_name: q.target_username,
          created_at: '2026-10-15T08:00:00Z',
          prior_actioned_reports: q.target_prior_actions,
          blocked_by_count: q.target_blocked_by_count,
          is_banned: false,
        },
        excerpt: {
          target_type: q.target_type,
          title: null,
          body: 'Nội dung chú thích bị báo cáo vi phạm quy tắc cộng đồng trong nhóm.',
          extra_note: null,
          created_at: q.created_at,
        },
        has_reported_media: q.has_reported_media,
        media_objects: q.has_reported_media
          ? [
              {
                bucket_id: 'media',
                object_path: 'checkins/demo-journey/usr-88/chk-901.jpg',
                label: 'checkin_photo_path',
              },
            ]
          : [],
        sibling_reports: [
          {
            id: 'rep-1',
            reporter_username: q.actor_username,
            reason: q.reason,
            note: 'Ngôn từ công kích cá nhân trong nhóm học tập.',
            created_at: q.created_at,
          },
        ],
      }
    }
    return callAdminRpc<ModerationItemDetail>('get_moderation_item', {
      p_queue_id,
    })
  },

  async revealReportedMedia(
    p_queue_id: string,
    p_purpose = 'Moderation SLA verification',
  ): Promise<RevealedMediaGrant[]> {
    if (isDemoMode()) {
      return [
        {
          bucket_id: 'media',
          object_path: 'checkins/demo-journey/usr-88/chk-901.jpg',
          expires_at: new Date(Date.now() + 5 * 60 * 1000).toISOString(),
          signed_url:
            'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="400" height="300"><rect width="400" height="300" fill="%2325221E"/><text x="50%" y="50%" fill="%23ECE5D8" font-family="sans-serif" font-size="18" text-anchor="middle">Reported Check-in Media (5m Grant)</text></svg>',
        },
      ]
    }
    const raw = await callAdminRpc<
      RevealedMediaGrant[] | { grants?: RevealedMediaGrant[] }
    >('reveal_reported_media', {
      p_queue_id,
      p_purpose,
    })
    const grants = Array.isArray(raw) ? raw : (raw?.grants ?? [])
    const withUrls: RevealedMediaGrant[] = []
    for (const g of grants) {
      if (g.signed_url) {
        withUrls.push(g)
      } else {
        const { data } = await supabase.storage
          .from(g.bucket_id)
          .createSignedUrl(g.object_path, 120)
        withUrls.push({
          ...g,
          signed_url: data?.signedUrl,
        })
      }
    }
    return withUrls
  },

  async quarantineModerationTarget(
    p_queue_id: string,
    p_note: string,
  ): Promise<void> {
    if (isDemoMode()) return
    await callAdminRpc('quarantine_moderation_target', {
      p_queue_id,
      p_note,
    })
  },

  async resolveModeration(
    p_queue_id: string,
    p_action: 'dismiss' | 'remove_content' | 'ban_user',
    p_note: string,
  ): Promise<void> {
    if (isDemoMode()) return
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
    if (isDemoMode()) {
      return [
        {
          term: 'lừa đảo',
          lang: 'vi',
          match_mode: 'diacritic_word',
          category: 'profanity',
          enabled: true,
          created_at: '2026-11-01T00:00:00Z',
        },
        {
          term: 'scam link',
          lang: 'en',
          match_mode: 'substring',
          category: 'profanity',
          enabled: true,
          created_at: '2026-11-01T00:00:00Z',
        },
      ]
    }
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
    if (isDemoMode()) {
      const lower = p_text.toLowerCase()
      if (lower.includes('lừa đảo') || lower.includes('scam')) {
        return {
          allowed: false,
          matched_term: 'lừa đảo',
          lang: 'vi',
          match_mode: 'diacritic_word',
          category: 'profanity',
        }
      }
      return {
        allowed: true,
        matched_term: null,
        lang: null,
        match_mode: null,
        category: null,
      }
    }
    return callAdminRpc<FilterDryRunResult>('test_content_filter', { p_text })
  },

  async upsertObjectionableWord(params: {
    p_term: string
    p_lang: 'vi' | 'en' | 'any'
    p_match_mode: 'diacritic_word' | 'word' | 'substring'
    p_category: 'csae' | 'self_harm' | 'violence' | 'sexual' | 'slur' | 'profanity'
    p_enabled: boolean
  }): Promise<void> {
    if (isDemoMode()) return
    await callAdminRpc('upsert_objectionable_word', params)
  },

  async setObjectionableWordEnabled(
    p_term: string,
    p_enabled: boolean,
  ): Promise<void> {
    if (isDemoMode()) return
    await callAdminRpc('set_objectionable_word_enabled', {
      p_term,
      p_enabled,
    })
  },

  async deleteObjectionableWord(
    p_term: string,
    p_reason = 'Removed via Admin Console',
  ): Promise<void> {
    if (isDemoMode()) return
    await callAdminRpc('delete_objectionable_word', {
      p_term,
      p_reason,
    })
  },

  async featureRequestStats(): Promise<FeatureRequestStats> {
    if (isDemoMode()) return DEMO_FEATURE_REQUEST_STATS
    const raw = await callAdminRpc<Partial<FeatureRequestStats>>(
      'feature_request_stats',
    )
    return {
      ...DEMO_FEATURE_REQUEST_STATS,
      ...(raw ?? {}),
      top_voted: raw?.top_voted ?? DEMO_FEATURE_REQUEST_STATS.top_voted,
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
  }): Promise<FeatureRequestRow[]> {
    if (isDemoMode()) return DEMO_FEATURE_REQUESTS
    const data = await callAdminRpc<
      FeatureRequestRow[] | { items?: FeatureRequestRow[] }
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
    return Array.isArray(data) ? data : (data?.items ?? [])
  },

  async getFeatureRequestDetail(p_id: string): Promise<FeatureRequestDetail> {
    if (isDemoMode()) {
      const found =
        DEMO_FEATURE_REQUESTS.find((r) => r.id === p_id) ??
        DEMO_FEATURE_REQUESTS[0]
      return {
        ...found,
        merged_children:
          found.merged_children_count > 0
            ? [
                {
                  id: 'fr-099',
                  title: 'Widget màn hình khóa cho nhóm học',
                  author_username: 'minh_study',
                  vote_count: 6,
                  created_at: '2026-11-10T08:00:00Z',
                },
              ]
            : [],
        reports: [],
        voters: [
          {
            user_id: 'usr-10',
            username: 'linh_ielts',
            display_name: 'Linh Nguyễn',
            is_author: true,
            voted_at: '2026-11-12T08:00:00Z',
          },
          {
            user_id: 'usr-12',
            username: 'thao_fit',
            display_name: 'Thảo Phạm',
            is_author: false,
            voted_at: '2026-11-14T11:20:00Z',
          },
        ],
      }
    }
    const raw = await callAdminRpc<Partial<FeatureRequestDetail>>(
      'get_feature_request_detail',
      { p_id },
    )
    return {
      ...(raw as FeatureRequestDetail),
      merged_children: raw?.merged_children ?? [],
      reports: raw?.reports ?? [],
      voters: raw?.voters ?? [],
    }
  },

  async updateFeatureRequest(params: {
    p_id: string
    p_status: FeatureRequestStatus
    p_category: FeatureRequestCategory
    p_admin_reply: string | null
    p_hidden: boolean
    p_reason: string
  }): Promise<void> {
    if (isDemoMode()) return
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
    if (isDemoMode()) return
    await callAdminRpc('merge_feature_request', {
      p_source_id: params.p_source_id,
      p_target_id: params.p_target_id,
      p_reason: params.p_reason,
    })
  },

  async waitlistSummary(p_days = 30): Promise<WaitlistSummary> {
    if (isDemoMode()) {
      return {
        total: 1280,
        ios_only: 740,
        android_only: 380,
        both_platforms: 160,
        vi_count: 1090,
        en_count: 190,
        sent_count: 1274,
        failed_count: 1,
        unsent_count: 5,
        converted_count: 438,
        top_sources: [
          { source: 'landing_hero', count: 890 },
          { source: 'tiktok_bio', count: 270 },
          { source: 'friend_share', count: 120 },
        ],
        daily: [
          { day: '18/11', vi: 27, en: 5 },
          { day: '19/11', vi: 35, en: 6 },
          { day: '20/11', vi: 32, en: 6 },
          { day: '21/11', vi: 41, en: 8 },
          { day: '22/11', vi: 38, en: 6 },
          { day: '23/11', vi: 44, en: 8 },
          { day: '24/11', vi: 33, en: 6 },
        ],
      }
    }
    return callAdminRpc<WaitlistSummary>('waitlist_summary', { p_days })
  },

  async listWaitlist(params: {
    p_search?: string
    p_lang?: string
    p_platform?: string
    p_mail_status?: string
    p_converted?: string
    p_limit?: number
    p_offset?: number
  }): Promise<WaitlistRow[]> {
    if (isDemoMode()) {
      return [
        {
          id: 'wl-1',
          email: 'minh.nguyen@example.com',
          lang: 'vi',
          platforms: ['ios'],
          source: 'landing_hero',
          created_at: '2026-11-24T05:12:00Z',
          confirmation_sent_at: '2026-11-24T05:12:03Z',
          confirmation_error: null,
          registered_in_app: true,
        },
        {
          id: 'wl-2',
          email: 'retry.me@example.com',
          lang: 'en',
          platforms: ['ios', 'android'],
          source: 'tiktok_bio',
          created_at: '2026-11-24T04:10:00Z',
          confirmation_sent_at: null,
          confirmation_error: 'Resend 429 rate limit exceeded',
          registered_in_app: false,
        },
      ]
    }
    const data = await callAdminRpc<
      WaitlistRow[] | { items?: WaitlistRow[] }
    >('list_waitlist', {
      p_search: params.p_search ?? '',
      p_lang: params.p_lang ?? 'all',
      p_platform: params.p_platform ?? 'all',
      p_mail_status: params.p_mail_status ?? 'all',
      p_converted: params.p_converted ?? 'all',
      p_limit: params.p_limit ?? 50,
      p_offset: params.p_offset ?? 0,
    })
    return Array.isArray(data) ? data : (data?.items ?? [])
  },

  async exportWaitlist(params: {
    p_search?: string
    p_lang?: string
    p_platform?: string
    p_mail_status?: string
    p_converted?: string
  }): Promise<WaitlistExportRow[] | string> {
    if (isDemoMode()) {
      return [
        {
          email: 'minh.nguyen@example.com',
          lang: 'vi',
          platforms: ['ios'],
          source: 'landing_hero',
          created_at: '2026-11-24T05:12:00Z',
          confirmation_sent_at: '2026-11-24T05:12:03Z',
          registered_in_app: true,
        },
      ]
    }
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
    if (isDemoMode()) return
    await callAdminRpc('delete_waitlist_entry', { p_id, p_reason })
  },

  async listUsers(params: {
    p_search?: string
    p_status?: string
    p_sort?: string
    p_limit?: number
    p_offset?: number
  }): Promise<AdminUserRow[]> {
    if (isDemoMode()) {
      return [
        {
          user_id: 'usr-10',
          username: 'linh_ielts',
          display_name: 'Linh Nguyễn',
          email: 'linh.ielts@example.com',
          has_phone: true,
          has_password: true,
          terms_version: 1,
          status: 'active',
          active_journeys: 2,
          total_journeys: 3,
          group_journeys: 2,
          total_checkins: 48,
          best_streak: 24,
          feature_requests_count: 2,
          open_reports_against: 0,
          total_actioned_reports: 0,
          blocked_by_count: 0,
          last_active_at: '2026-11-24T06:20:00Z',
          created_at: '2026-10-20T09:00:00Z',
        },
        {
          user_id: 'usr-88',
          username: 'hung_gym99',
          display_name: 'Hùng Trần',
          email: 'hung.gym@example.com',
          has_phone: false,
          has_password: true,
          terms_version: 1,
          status: 'active',
          active_journeys: 1,
          total_journeys: 1,
          group_journeys: 1,
          total_checkins: 9,
          best_streak: 4,
          feature_requests_count: 0,
          open_reports_against: 1,
          total_actioned_reports: 1,
          blocked_by_count: 2,
          last_active_at: '2026-11-23T17:10:00Z',
          created_at: '2026-11-10T11:00:00Z',
        },
      ]
    }
    const data = await callAdminRpc<
      AdminUserRow[] | { items?: AdminUserRow[] }
    >('list_users', {
      p_search: params.p_search || null,
      p_status: params.p_status ?? 'all',
      p_sort: params.p_sort ?? 'created_at',
      p_limit: params.p_limit ?? 50,
      p_offset: params.p_offset ?? 0,
    })
    return Array.isArray(data) ? data : (data?.items ?? [])
  },

  async getUserDetail(p_user: string): Promise<AdminUserDetail> {
    if (isDemoMode()) {
      const list = await this.listUsers({})
      const base = list.find((u) => u.user_id === p_user) ?? list[0]
      return {
        ...base,
        banned_until: base.status === 'banned' ? '2126-11-24T00:00:00Z' : null,
        ban_reason: null,
        wiped_ugc: false,
        feature_requests: [
          {
            id: 'fr-101',
            title: 'Widget màn hình khóa iOS hiển thị chuỗi lửa cùng nhóm',
            status: 'planned',
            vote_count: 68,
            created_at: '2026-11-12T08:00:00Z',
          },
        ],
        moderation_history: [],
      }
    }
    return callAdminRpc<AdminUserDetail>('get_user_detail', { p_user })
  },

  async banUser(params: {
    p_user: string
    p_reason: string
    p_wipe_ugc: boolean
  }): Promise<void> {
    if (isDemoMode()) return
    await callAdminRpc('ban_user', params)
  },

  async unbanUser(p_user: string, p_reason: string): Promise<void> {
    if (isDemoMode()) return
    await callAdminRpc('unban_user', { p_user, p_reason })
  },

  async revokeUserSessions(p_user: string, p_reason: string): Promise<void> {
    if (isDemoMode()) return
    await callAdminRpc('revoke_user_sessions', { p_user, p_reason })
  },

  async journeyStats(): Promise<JourneyStats> {
    if (isDemoMode()) {
      return {
        total_active: 612,
        total_ended: 144,
        total_archived: 39,
        solo_count: 342,
        group_count: 184,
        couple_count: 86,
        live_count: 554,
        imported_count: 58,
        active_public_links: 47,
        total_public_views: 3890,
      }
    }
    return callAdminRpc<JourneyStats>('journey_stats')
  },

  async listJourneys(params: {
    p_search?: string
    p_kind?: string
    p_template?: string
    p_status?: string
    p_public_only?: boolean
    p_limit?: number
    p_offset?: number
  }): Promise<AdminJourneyRow[]> {
    if (isDemoMode()) {
      return [
        {
          id: 'jrn-01',
          owner_id: 'usr-10',
          owner_username: 'linh_ielts',
          kind: 'group',
          origin: 'live',
          template_id: 'english_daily',
          skin_id: 'accountabilitySquad',
          status: 'active',
          visibility: 'link',
          public_token: 'pub_ielts_30d',
          title: '30 Ngày Cày IELTS 7.5 Cùng Squad',
          active_members: 5,
          max_members: 5,
          checkin_count: 112,
          public_views: 340,
          created_at: '2026-11-01T08:00:00Z',
        },
        {
          id: 'jrn-02',
          owner_id: 'usr-12',
          owner_username: 'thao_fit',
          kind: 'solo',
          origin: 'live',
          template_id: 'weight_loss',
          skin_id: 'quietTransformer',
          status: 'active',
          visibility: 'private',
          public_token: null,
          title: null,
          active_members: 1,
          max_members: 1,
          checkin_count: 21,
          public_views: 0,
          created_at: '2026-11-03T07:30:00Z',
        },
      ]
    }
    const data = await callAdminRpc<
      AdminJourneyRow[] | { items?: AdminJourneyRow[] }
    >('list_journeys', {
      p_search: params.p_search ?? '',
      p_kind: params.p_kind ?? 'all',
      p_template: params.p_template ?? 'all',
      p_status: params.p_status ?? 'all',
      p_public_only: params.p_public_only ?? false,
      p_limit: params.p_limit ?? 50,
      p_offset: params.p_offset ?? 0,
    })
    return Array.isArray(data) ? data : (data?.items ?? [])
  },

  async revokeJourneyPublicLink(
    p_journey: string,
    p_reason: string,
  ): Promise<void> {
    if (isDemoMode()) return
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
  }): Promise<AuditLogRow[]> {
    if (isDemoMode()) {
      return [
        {
          id: 1042,
          created_at: '2026-11-24T06:15:00Z',
          admin_id: '00000000-0000-0000-0000-000000000001',
          admin_email: 'owner@ourney.tech',
          action: 'feature_requests.update',
          target_type: 'feature_request',
          target_id: 'fr-101',
          reason: 'Updated roadmap status to planned and posted public reply',
          meta: { status: 'planned', tags: ['ios', 'quick-win', 'v1-1'] },
        },
        {
          id: 1041,
          created_at: '2026-11-24T05:50:00Z',
          admin_id: '00000000-0000-0000-0000-000000000001',
          admin_email: 'owner@ourney.tech',
          action: 'moderation.reveal_media',
          target_type: 'moderation_queue',
          target_id: 'mq-01',
          reason: '24h SLA triage check',
          meta: { ttl_seconds: 300, bucket: 'media' },
        },
      ]
    }
    const data = await callAdminRpc<AuditLogRow[] | { items?: AuditLogRow[] }>(
      'list_audit_log',
      {
        p_admin: params.p_admin ?? null,
        p_action_prefix: params.p_action_prefix || null,
        p_target_type:
          !params.p_target_type || params.p_target_type === 'all'
            ? null
            : params.p_target_type,
        p_target_id: params.p_target_id || null,
        p_before_id: params.p_before_id ?? null,
        p_limit: params.p_limit ?? 50,
      },
    )
    return Array.isArray(data) ? data : (data?.items ?? [])
  },

  async listAdmins(): Promise<AdminIdentity[]> {
    if (isDemoMode()) {
      return [
        {
          user_id: '00000000-0000-0000-0000-000000000001',
          email: 'owner@ourney.tech',
          role: 'owner',
          username: 'hoang_owner',
          display_name: 'Hoàng (Founder)',
          note: 'Initial owner bootstrap',
          created_at: '2026-10-01T00:00:00Z',
        },
      ]
    }
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
    if (isDemoMode()) return
    await callAdminRpc('upsert_admin_user', {
      p_email_or_uid: params.p_email_or_uid,
      p_role: params.p_role,
      p_note: params.p_note ?? null,
    })
  },

  async removeAdminUser(p_user: string, p_reason: string): Promise<void> {
    if (isDemoMode()) return
    await callAdminRpc('remove_admin_user', { p_user, p_reason })
  },

  async systemHealth(): Promise<SystemHealth> {
    if (isDemoMode()) {
      return {
        storage_purge: {
          due_now_count: 3,
          backing_off_count: 0,
          stuck_count: 0,
          sample_errors: [],
        },
        moderation_alerts: {
          unnotified_open_count: 0,
          oldest_unnotified_at: null,
        },
      }
    }
    return callAdminRpc<SystemHealth>('system_health')
  },

  async resetStuckStoragePurge(p_reason = 'Manual reset from Admin Settings'): Promise<void> {
    if (isDemoMode()) return
    await callAdminRpc('reset_stuck_storage_purge', { p_reason })
  },

  async invokeAdminAction<T = Record<string, unknown>>(
    payload:
      | { action: 'waitlist_resend'; waitlist_id: string }
      | { action: 'waitlist_resend_failed'; limit?: number }
      | { action: 'delete_user'; user_id: string; reason: string; ticket_ref?: string }
      | { action: 'run_storage_sweep'; limit?: number }
      | { action: 'trigger_moderation_notify'; limit?: number },
  ): Promise<T> {
    if (isDemoMode()) {
      return { ok: true, action: payload.action } as unknown as T
    }
    const { data, error } = await supabase.functions.invoke('admin-action', {
      body: payload,
    })
    if (error) throw error
    return data as T
  },
}
