import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from 'react'

export type Lang = 'vi' | 'en'
export type ThemeMode = 'light' | 'dark'

type I18nContextValue = {
  lang: Lang
  setLang: (lang: Lang) => void
  toggleLang: () => void
  theme: ThemeMode
  setTheme: (theme: ThemeMode) => void
  toggleTheme: () => void
  t: (vi: string, en: string) => string
}

const I18nContext = createContext<I18nContextValue | null>(null)

let activeLang: Lang = 'vi'

export function getCurrentLang(): Lang {
  if (typeof document !== 'undefined') {
    const docLang =
      document.documentElement.dataset.lang || document.documentElement.lang
    if (docLang === 'vi' || docLang === 'en') return docLang
  }
  return activeLang
}

export function I18nProvider({
  children,
  initialLang,
  initialTheme,
}: {
  children: ReactNode
  initialLang?: Lang
  initialTheme?: ThemeMode
}) {
  const [lang, setLangState] = useState<Lang>(() => {
    if (initialLang) return initialLang
    try {
      const qLang = new URLSearchParams(window.location.search).get('lang')
      if (qLang === 'vi' || qLang === 'en') return qLang
      const saved = window.localStorage.getItem('ourney_admin_lang')
      if (saved === 'vi' || saved === 'en') return saved
    } catch {
      // Ignore storage error in restricted environments
    }
    return 'vi'
  })

  activeLang = lang
  if (typeof document !== 'undefined') {
    document.documentElement.lang = lang
    document.documentElement.dataset.lang = lang
  }

  const [theme, setThemeState] = useState<ThemeMode>(() => {
    if (initialTheme) return initialTheme
    try {
      const qTheme = new URLSearchParams(window.location.search).get('theme')
      if (qTheme === 'light' || qTheme === 'dark') return qTheme
      const saved = window.localStorage.getItem('ourney_admin_theme')
      if (saved === 'light' || saved === 'dark') return saved
    } catch {
      // Ignore storage error
    }
    return 'light'
  })

  useEffect(() => {
    activeLang = lang
    document.documentElement.lang = lang
    document.documentElement.dataset.lang = lang
    try {
      window.localStorage.setItem('ourney_admin_lang', lang)
    } catch {
      // Ignore
    }
  }, [lang])

  useEffect(() => {
    document.documentElement.dataset.theme = theme
    try {
      window.localStorage.setItem('ourney_admin_theme', theme)
    } catch {
      // Ignore
    }
  }, [theme])

  const setLang = (next: Lang) => setLangState(next)
  const toggleLang = () => setLangState((prev) => (prev === 'vi' ? 'en' : 'vi'))
  const setTheme = (next: ThemeMode) => setThemeState(next)
  const toggleTheme = () =>
    setThemeState((prev) => (prev === 'light' ? 'dark' : 'light'))

  const t = (vi: string, en: string) => (lang === 'vi' ? vi : en)

  return (
    <I18nContext.Provider
      value={{
        lang,
        setLang,
        toggleLang,
        theme,
        setTheme,
        toggleTheme,
        t,
      }}
    >
      {children}
    </I18nContext.Provider>
  )
}

export function useI18n(): I18nContextValue {
  const ctx = useContext(I18nContext)
  if (!ctx) {
    throw new Error('useI18n must be used inside I18nProvider')
  }
  return ctx
}

function pick(lang: Lang, vi: string, en: string): string {
  return lang === 'vi' ? vi : en
}

/**
 * Maps raw PostgreSQL / PostgREST / Supabase Auth / Edge Function errors into
 * plain-language operator messages without leaking SQLSTATE codes, PostgREST
 * identifiers, schema/table names, or migration numbers.
 */
export function formatAdminError(
  err: unknown,
  lang: Lang = getCurrentLang(),
): string {
  const rawObj =
    err && typeof err === 'object'
      ? (err as {
          code?: unknown
          status?: unknown
          message?: unknown
          error?: unknown
          details?: unknown
        })
      : null
  const code =
    rawObj && typeof rawObj.code === 'string' ? rawObj.code.trim() : ''
  const status =
    rawObj && typeof rawObj.status === 'number' ? rawObj.status : undefined
  const rawMsg =
    typeof err === 'string'
      ? err
      : err instanceof Error
        ? err.message
        : rawObj && typeof rawObj.message === 'string'
          ? rawObj.message
          : rawObj && typeof rawObj.error === 'string'
            ? rawObj.error
            : ''
  const combined = `${code} ${rawMsg}`.trim()

  if (
    code === '42501' ||
    status === 403 ||
    /\b(42501|forbidden|permission denied|not_admin)\b/i.test(combined)
  ) {
    return pick(
      lang,
      'Bạn không có quyền thực hiện thao tác này. Tính năng yêu cầu quyền Chủ sở hữu hoặc tài khoản quản trị hợp lệ.',
      'You do not have permission to perform this action. Owner privileges or an active admin role are required.',
    )
  }

  if (
    code === '28000' ||
    code === 'PGRST301' ||
    status === 401 ||
    /\b(28000|PGRST301|unauthenticated|jwt expired|invalid jwt|no_session)\b/i.test(
      combined,
    )
  ) {
    return pick(
      lang,
      'Phiên đăng nhập đã hết hạn hoặc không hợp lệ. Vui lòng đăng nhập lại.',
      'Your session has expired or is invalid. Please sign in again.',
    )
  }

  if (
    code === 'PGRST202' ||
    code === '42883' ||
    code === '42P01' ||
    /\b(PGRST202|42883|42P01|Could not find the function|does not exist)\b/i.test(
      combined,
    )
  ) {
    return pick(
      lang,
      'Tính năng này chưa được kích hoạt trên máy chủ dữ liệu. Vui lòng liên hệ kỹ thuật viên để cập nhật hệ thống.',
      'This feature is not yet enabled on the database server. Please contact engineering to apply the latest system update.',
    )
  }

  if (
    status === 429 ||
    /(?:^|\b|_)(rate_limited|rate_limit_exceeded|rate limit|429|too many requests|over_email_send_rate_limit)(?:\b|_|$)/i.test(
      combined,
    )
  ) {
    return pick(
      lang,
      'Thao tác vượt quá giới hạn tần suất cho phép. Vui lòng đợi ít phút rồi thử lại.',
      'Rate limit exceeded. Please wait a moment and try again.',
    )
  }

  if (/(?:^|\b|_)cannot_remove_last_owner(?:\b|_|$)/i.test(combined)) {
    return pick(
      lang,
      'Không thể gỡ hoặc hạ quyền Chủ sở hữu cuối cùng của hệ thống.',
      'Cannot remove or demote the last remaining Owner of the system.',
    )
  }

  if (/(?:^|\b|_)cannot_delete_self(?:\b|_|$)/i.test(combined)) {
    return pick(
      lang,
      'Bạn không thể tự xóa tài khoản quản trị viên của chính mình.',
      'You cannot delete your own admin account.',
    )
  }

  if (/(?:^|\b|_)no_reported_media(?:\b|_|$)/i.test(combined)) {
    return pick(
      lang,
      'Mục báo cáo này không có tệp hình ảnh hoặc phương tiện đính kèm.',
      'This reported item has no attached photo or media files.',
    )
  }

  if (/(?:^|\b|_)links_not_allowed(?:\b|_|$)/i.test(combined)) {
    return pick(
      lang,
      'Nội dung không được chứa đường dẫn hoặc liên kết web.',
      'Content cannot contain web links or URLs.',
    )
  }

  if (/(?:^|\b|_)(content_policy|objectionable)(?:\b|_|$)/i.test(combined)) {
    return pick(
      lang,
      'Nội dung chứa từ ngữ vi phạm bộ lọc an toàn cộng đồng. Vui lòng kiểm tra lại.',
      'Content contains terms blocked by the community safety filter. Please revise.',
    )
  }

  if (/(?:^|\b|_)immutable_column(?:\b|_|$)/i.test(combined)) {
    return pick(
      lang,
      'Không thể thay đổi trường dữ liệu được bảo vệ.',
      'Cannot modify a protected read-only field.',
    )
  }

  if (
    /(?:^|\b|_)(mail_not_configured|RESEND_API_KEY|WAITLIST_FROM)(?:\b|_|$)/i.test(
      combined,
    )
  ) {
    return pick(
      lang,
      'Dịch vụ gửi email chưa được cấu hình đầy đủ trên máy chủ.',
      'The email delivery service is not configured on the server.',
    )
  }

  if (/(?:^|\b|_)(resend_\d+|resend_failed)(?:\b|_|$)/i.test(combined)) {
    return pick(
      lang,
      'Nhà cung cấp dịch vụ email từ chối hoặc tạm thời không phản hồi. Vui lòng thử lại sau.',
      'The email provider rejected the request or is temporarily unavailable. Please try again.',
    )
  }

  if (
    /(?:^|\b|_)(not_found|user_not_found)(?:\b|_|$)/i.test(combined) ||
    status === 404
  ) {
    return pick(
      lang,
      'Không tìm thấy mục dữ liệu yêu cầu (có thể đã bị xóa trước đó).',
      'The requested record was not found (it may have already been deleted).',
    )
  }

  if (
    /\b(Signups not allowed|user not found|email not authorized)\b/i.test(
      combined,
    )
  ) {
    return pick(
      lang,
      'Email này chưa được cấp quyền truy cập quản trị viên.',
      'This email address is not authorized for admin access.',
    )
  }

  if (
    /\b(otp|token has expired|invalid login|verification failed|otp send failed)\b/i.test(
      combined,
    )
  ) {
    return pick(
      lang,
      'Không thể xác thực mã OTP (mã đã hết hạn hoặc không chính xác). Vui lòng thử lại.',
      'Could not verify the OTP code (it may be invalid or expired). Please try again.',
    )
  }

  if (/(?:^|\b|_)(delete_failed|lookup_failed)(?:\b|_|$)/i.test(combined)) {
    return pick(
      lang,
      'Không thể hoàn tất thao tác xử lý tài khoản trên máy chủ. Vui lòng thử lại.',
      'Could not complete the account operation on the server. Please try again.',
    )
  }

  if (status === 413 || /(?:^|\b|_)payload_too_large(?:\b|_|$)/i.test(combined)) {
    return pick(
      lang,
      'Dữ liệu gửi lên vượt quá dung lượng tối đa cho phép.',
      'The submitted data exceeds the maximum allowed size.',
    )
  }

  if (
    code === '23505' ||
    /\b(23505|duplicate key|already exists)\b/i.test(combined)
  ) {
    return pick(
      lang,
      'Dữ liệu này đã tồn tại trong hệ thống.',
      'This item already exists in the system.',
    )
  }

  if (
    code === 'P0001' ||
    code === '23514' ||
    code === '22P02' ||
    status === 400 ||
    /(?:^|\b|_)(invalid|invalid_body|invalid_action|violates check constraint|23514|22P02)(?:\b|_|$)/i.test(
      combined,
    )
  ) {
    return pick(
      lang,
      'Dữ liệu nhập vào không hợp lệ hoặc thao tác không khả dụng ở trạng thái hiện tại.',
      'The provided input is invalid or the action is not allowed in the current state.',
    )
  }

  if (
    status === 500 ||
    status === 502 ||
    status === 503 ||
    status === 504 ||
    /\b(network|fetch|timeout|503|502|504|internal|ECONN|Failed to fetch)\b/i.test(
      combined,
    )
  ) {
    return pick(
      lang,
      'Không thể kết nối tới máy chủ hoặc dịch vụ đang tạm gián đoạn. Vui lòng thử lại sau.',
      'Unable to reach the server or the service is temporarily unavailable. Please try again shortly.',
    )
  }

  return pick(
    lang,
    'Đã xảy ra lỗi khi xử lý yêu cầu. Vui lòng thử lại.',
    'An unexpected error occurred while processing the request. Please try again.',
  )
}

export function formatTechnicalDiagnostic(
  err: unknown,
): string | null {
  const raw =
    typeof err === 'string'
      ? err
      : err instanceof Error
        ? err.message
        : err && typeof err === 'object'
          ? String(
              (err as { message?: unknown; error?: unknown; code?: unknown })
                .message ??
                (err as { error?: unknown }).error ??
                (err as { code?: unknown }).code ??
                '',
            )
          : ''
  const cleaned = raw
    .replace(/\b(42501|PGRST\d+|28000|P0001|23514|23505|22P02|42883|42P01)\b/gi, '')
    .replace(/\b(private|admin|public)\.[a-z0-9_]+/gi, '[db_object]')
    .replace(/\b(RESEND_API_KEY|WAITLIST_FROM|WAITLIST_REPLY_TO)\b/gi, '[env_config]')
    .trim()
  return cleaned || null
}

function formatUnknownEnum(
  raw: string | null | undefined,
  lang: Lang,
): string {
  const trimmed = (raw ?? '').trim()
  if (!trimmed) {
    return pick(lang, 'Không rõ', 'Unknown')
  }
  return pick(lang, `Không rõ (${trimmed})`, `Unknown (${trimmed})`)
}

export function fmtDateTime(
  iso: string | null | undefined,
  lang: Lang = getCurrentLang(),
  timeZone = 'Asia/Ho_Chi_Minh',
): string {
  if (!iso) return '—'
  const trimmed = iso.trim()
  if (!trimmed) return '—'
  const d = new Date(trimmed)
  if (Number.isNaN(d.getTime())) return trimmed
  const tzLabel =
    timeZone === 'Asia/Ho_Chi_Minh'
      ? 'GMT+7'
      : timeZone === 'UTC'
        ? 'UTC'
        : timeZone
  try {
    const formatted = new Intl.DateTimeFormat(
      lang === 'vi' ? 'vi-VN' : 'en-US',
      {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        hour12: false,
        timeZone,
      },
    ).format(d)
    return `${formatted} (${tzLabel})`
  } catch {
    return `${trimmed.replace('T', ' ').replace(/\.\d+Z$/, '')} (${tzLabel})`
  }
}

export function fmtDateShort(
  isoOrDay: string | null | undefined,
  lang: Lang = getCurrentLang(),
): string {
  if (!isoOrDay) return '—'
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(isoOrDay.trim())
  if (m) {
    return lang === 'vi'
      ? `${m[3]}/${m[2]}/${m[1]}`
      : `${m[2]}/${m[3]}/${m[1]}`
  }
  return fmtDateTime(isoOrDay, lang)
}

export function formatModerationKind(
  kind: string | null | undefined,
  lang: Lang = getCurrentLang(),
): string {
  switch (kind?.toLowerCase().trim()) {
    case 'report':
      return pick(lang, 'Báo cáo', 'Report')
    case 'block':
      return pick(lang, 'Chặn người dùng', 'Block Signal')
    default:
      return formatUnknownEnum(kind, lang)
  }
}

export function formatModerationReason(
  reason: string | null | undefined,
  lang: Lang = getCurrentLang(),
  kind?: string,
): string {
  const key = reason?.toLowerCase().trim()
  if (!key) {
    if (kind === 'block') {
      return pick(lang, 'Người dùng chặn nhau', 'User Block')
    }
    return pick(lang, 'Chưa phân loại', 'Unspecified')
  }
  switch (key) {
    case 'nudity':
      return pick(lang, 'Hình ảnh nhạy cảm / Khỏa thân', 'Nudity / NSFW')
    case 'self_harm':
      return pick(lang, 'Tự gây hại', 'Self-Harm')
    case 'harassment':
      return pick(lang, 'Quấy rối / Công kích', 'Harassment')
    case 'spam':
      return pick(lang, 'Tin rác / Spam', 'Spam')
    case 'other':
      return pick(lang, 'Lý do khác', 'Other')
    case 'user_block':
      return pick(lang, 'Người dùng chặn nhau', 'User Block')
    case 'report':
    case 'unspecified':
      return pick(lang, 'Báo cáo vi phạm', 'Reported Violation')
    default:
      return formatUnknownEnum(reason, lang)
  }
}

export function formatModerationStatus(
  status: string | null | undefined,
  lang: Lang = getCurrentLang(),
): string {
  switch (status?.toLowerCase().trim()) {
    case 'open':
      return pick(lang, 'Đang mở', 'Open')
    case 'overdue':
      return pick(lang, 'Quá hạn', 'Overdue')
    case 'quarantined':
      return pick(lang, 'Đang tạm ẩn', 'Quarantined')
    case 'actioned':
      return pick(lang, 'Đã xử phạt', 'Actioned')
    case 'dismissed':
      return pick(lang, 'Đã bác bỏ', 'Dismissed')
    default:
      return formatUnknownEnum(status, lang)
  }
}

export function formatModerationAction(
  action: string | null | undefined,
  lang: Lang = getCurrentLang(),
): string {
  switch (action?.toLowerCase().trim()) {
    case 'dismiss':
      return pick(lang, 'Bác bỏ báo cáo', 'Dismiss Report')
    case 'quarantine':
      return pick(lang, 'Tạm ẩn điều tra', 'Quarantine Target')
    case 'remove_content':
      return pick(lang, 'Gỡ bỏ nội dung', 'Remove Content')
    case 'ban_user':
      return pick(lang, 'Khóa tài khoản & xóa nội dung', 'Ban User & Wipe Content')
    case 'action':
      return pick(lang, 'Thực thi xử phạt', 'Take Action')
    default:
      return formatUnknownEnum(action, lang)
  }
}

export function formatTargetType(
  targetType: string | null | undefined,
  lang: Lang = getCurrentLang(),
): string {
  switch (targetType?.toLowerCase().trim()) {
    case 'checkin':
      return pick(lang, 'Ảnh check-in', 'Check-in')
    case 'message':
      return pick(lang, 'Tin nhắn', 'Message')
    case 'user':
      return pick(lang, 'Người dùng', 'User')
    case 'feature_request':
      return pick(lang, 'Đề xuất tính năng', 'Feature Request')
    case 'moderation_queue':
      return pick(lang, 'Hàng đợi kiểm duyệt', 'Moderation Queue')
    case 'journey':
      return pick(lang, 'Hành trình', 'Journey')
    case 'waitlist':
      return pick(lang, 'Danh sách chờ', 'Waitlist')
    case 'word':
      return pick(lang, 'Từ khóa chặn', 'Filter Word')
    case 'admin':
      return pick(lang, 'Quản trị viên', 'Admin')
    case 'system':
      return pick(lang, 'Hệ thống', 'System')
    default:
      return formatUnknownEnum(targetType, lang)
  }
}

export function formatWordLang(
  wordLang: string | null | undefined,
  lang: Lang = getCurrentLang(),
): string {
  switch (wordLang?.toLowerCase().trim()) {
    case 'vi':
      return pick(lang, 'Tiếng Việt (VI)', 'Vietnamese (VI)')
    case 'en':
      return pick(lang, 'Tiếng Anh (EN)', 'English (EN)')
    case 'any':
      return pick(lang, 'Mọi ngôn ngữ', 'Any language')
    default:
      return formatUnknownEnum(wordLang, lang)
  }
}

export function formatWordMatchMode(
  mode: string | null | undefined,
  lang: Lang = getCurrentLang(),
): string {
  switch (mode?.toLowerCase().trim()) {
    case 'diacritic_word':
      return pick(lang, 'Từ có dấu chính xác', 'Exact Diacritic Word')
    case 'word':
      return pick(lang, 'Từ nguyên vẹn', 'Whole Word')
    case 'substring':
      return pick(lang, 'Chuỗi ký tự con', 'Substring')
    default:
      return formatUnknownEnum(mode, lang)
  }
}

export function formatWordCategory(
  category: string | null | undefined,
  lang: Lang = getCurrentLang(),
): string {
  switch (category?.toLowerCase().trim()) {
    case 'profanity':
      return pick(lang, 'Ngôn từ thô tục', 'Profanity')
    case 'slur':
      return pick(lang, 'Xúc phạm / Kỳ thị', 'Slur / Hate Speech')
    case 'sexual':
      return pick(lang, 'Nội dung nhạy cảm', 'Sexual Content')
    case 'violence':
      return pick(lang, 'Bạo lực', 'Violence')
    case 'self_harm':
      return pick(lang, 'Tự gây hại', 'Self-Harm')
    case 'csae':
      return pick(lang, 'An toàn trẻ em (CSAE)', 'Child Safety (CSAE)')
    default:
      return formatUnknownEnum(category, lang)
  }
}

export function formatFeatureRequestStatus(
  status: string | null | undefined,
  lang: Lang = getCurrentLang(),
): string {
  switch (status?.toLowerCase().trim()) {
    case 'new':
      return pick(lang, 'Mới gửi', 'New')
    case 'under_review':
      return pick(lang, 'Đang xem xét', 'Under Review')
    case 'planned':
      return pick(lang, 'Đã lên kế hoạch', 'Planned')
    case 'in_progress':
      return pick(lang, 'Đang thực hiện', 'In Progress')
    case 'shipped':
      return pick(lang, 'Đã ra mắt', 'Shipped')
    case 'declined':
      return pick(lang, 'Chưa phù hợp', 'Declined')
    default:
      return formatUnknownEnum(status, lang)
  }
}

export function formatFeatureRequestCategory(
  category: string | null | undefined,
  lang: Lang = getCurrentLang(),
): string {
  switch (category?.toLowerCase().trim()) {
    case 'camera':
      return pick(lang, 'Máy ảnh', 'Camera')
    case 'journeys':
      return pick(lang, 'Hành trình', 'Journeys')
    case 'squad':
      return pick(lang, 'Nhóm bạn (Squad)', 'Squad')
    case 'sharing':
      return pick(lang, 'Chia sẻ', 'Sharing')
    case 'design':
      return pick(lang, 'Giao diện', 'Design')
    case 'other':
      return pick(lang, 'Khác', 'Other')
    default:
      return formatUnknownEnum(category, lang)
  }
}

export function formatUserStatus(
  status: string | null | undefined,
  lang: Lang = getCurrentLang(),
): string {
  switch (status?.toLowerCase().trim()) {
    case 'active':
      return pick(lang, 'Đang hoạt động', 'Active')
    case 'incomplete_onboarding':
      return pick(lang, 'Chưa hoàn tất hồ sơ', 'Incomplete Profile')
    case 'banned':
      return pick(lang, 'Đang bị khóa', 'Banned')
    case 'soft_deleted':
      return pick(lang, 'Đã xóa mềm', 'Soft Deleted')
    default:
      return formatUnknownEnum(status, lang)
  }
}

export function formatJourneyKind(
  kind: string | null | undefined,
  lang: Lang = getCurrentLang(),
): string {
  switch (kind?.toLowerCase().trim()) {
    case 'solo':
      return pick(lang, 'Cá nhân', 'Solo')
    case 'group':
      return pick(lang, 'Nhóm bạn', 'Squad')
    case 'couple':
      return pick(lang, 'Cặp đôi', 'Couple')
    default:
      return formatUnknownEnum(kind, lang)
  }
}

export function formatJourneyTemplate(
  template: string | null | undefined,
  lang: Lang = getCurrentLang(),
): string {
  switch (template?.toLowerCase().trim()) {
    case 'weight_loss':
    case 'quiet_transformer':
      return pick(lang, 'Giảm cân', 'Weight Loss')
    case 'english_daily':
    case 'accountability_squad':
      return pick(lang, 'Học mỗi ngày', 'Daily Study')
    case 'travel':
    case 'memory_collectors':
      return pick(lang, 'Chuyến đi', 'Travel')
    case 'couple':
    case 'couple_rituals':
      return pick(lang, 'Cặp đôi', 'Couple')
    case 'workout_30':
    case 'aesthetic_flexer':
      return pick(lang, 'Tập luyện 30 ngày', 'Workout 30')
    case 'custom':
    case 'minimalist_habit':
      return pick(lang, 'Thói quen tối giản', 'Custom Habit')
    default:
      return formatUnknownEnum(template, lang)
  }
}

export function formatJourneyStatus(
  status: string | null | undefined,
  lang: Lang = getCurrentLang(),
): string {
  switch (status?.toLowerCase().trim()) {
    case 'active':
      return pick(lang, 'Đang diễn ra', 'Active')
    case 'ended':
      return pick(lang, 'Đã kết thúc', 'Ended')
    case 'archived':
      return pick(lang, 'Đã lưu trữ', 'Archived')
    default:
      return formatUnknownEnum(status, lang)
  }
}

export function formatJourneyVisibility(
  vis: string | null | undefined,
  lang: Lang = getCurrentLang(),
): string {
  switch (vis?.toLowerCase().trim()) {
    case 'private':
      return pick(lang, 'Riêng tư', 'Private')
    case 'group':
      return pick(lang, 'Thành viên nhóm', 'Squad Only')
    case 'link':
      return pick(lang, 'Liên kết công khai', 'Public Link')
    default:
      return formatUnknownEnum(vis, lang)
  }
}

export function formatAdminRole(
  role: string | null | undefined,
  lang: Lang = getCurrentLang(),
): string {
  switch (role?.toLowerCase().trim()) {
    case 'owner':
      return pick(lang, 'Chủ sở hữu (Owner)', 'Owner')
    case 'moderator':
      return pick(lang, 'Kiểm duyệt viên', 'Moderator')
    default:
      return formatUnknownEnum(role, lang)
  }
}

export function formatPlatformLabel(platform: string): string {
  switch (platform.toLowerCase().trim()) {
    case 'ios':
      return 'iOS'
    case 'android':
      return 'Android'
    default:
      return platform
  }
}

export function formatWaitlistSource(
  source: string | null | undefined,
  lang: Lang = getCurrentLang(),
): string {
  const s = (source ?? '').trim().toLowerCase()
  if (!s || s === 'landing') {
    return pick(lang, 'Trang chủ', 'Landing Page')
  }
  if (s === 'landing_hero') {
    return pick(lang, 'Trang chủ (Hero)', 'Landing Hero')
  }
  if (s === 'tiktok_bio') {
    return 'TikTok Bio'
  }
  return (source ?? '')
    .replace(/[_-]+/g, ' ')
    .replace(/\b\w/g, (c) => c.toUpperCase())
}

export function formatAuditAction(
  action: string | null | undefined,
  lang: Lang = getCurrentLang(),
): string {
  switch (action?.toLowerCase().trim()) {
    case 'moderation.view_item':
      return pick(lang, 'Xem chi tiết báo cáo', 'Inspect Moderation Item')
    case 'moderation.reveal_media':
      return pick(lang, 'Mở khóa ảnh báo cáo (5 phút)', 'Reveal Reported Media (5m)')
    case 'moderation.quarantine':
      return pick(lang, 'Tạm ẩn nội dung bị báo cáo', 'Quarantine Reported Content')
    case 'moderation.resolve':
      return pick(lang, 'Xử lý báo cáo kiểm duyệt', 'Resolve Moderation Item')
    case 'words.upsert':
      return pick(lang, 'Thêm / cập nhật từ khóa chặn', 'Save Filter Word')
    case 'words.toggle':
      return pick(lang, 'Bật / tắt từ khóa chặn', 'Toggle Filter Word')
    case 'words.delete':
      return pick(lang, 'Xóa từ khóa chặn', 'Delete Filter Word')
    case 'feature_requests.view_detail':
      return pick(lang, 'Xem chi tiết đề xuất', 'View Feature Request Detail')
    case 'feature_requests.update':
      return pick(lang, 'Cập nhật đề xuất tính năng', 'Update Feature Request')
    case 'feature_requests.merge':
      return pick(lang, 'Gộp đề xuất trùng lặp', 'Merge Duplicate Request')
    case 'waitlist.export_csv':
      return pick(lang, 'Xuất CSV danh sách chờ', 'Export Waitlist CSV')
    case 'waitlist.delete':
      return pick(lang, 'Xóa đăng ký danh sách chờ', 'Delete Waitlist Entry')
    case 'waitlist.resend_confirmation':
      return pick(lang, 'Gửi lại email xác nhận', 'Resend Waitlist Confirmation')
    case 'users.view_detail':
      return pick(lang, 'Xem hồ sơ người dùng', 'View User Detail')
    case 'users.ban':
      return pick(lang, 'Khóa tài khoản người dùng', 'Ban User Account')
    case 'users.unban':
      return pick(lang, 'Mở khóa tài khoản người dùng', 'Unban User Account')
    case 'users.revoke_sessions':
      return pick(lang, 'Thu hồi phiên đăng nhập', 'Revoke User Sessions')
    case 'users.delete_on_request':
      return pick(lang, 'Xóa vĩnh viễn tài khoản theo yêu cầu', 'Erase Account on Request')
    case 'journeys.revoke_public_link':
      return pick(lang, 'Thu hồi liên kết công khai', 'Revoke Public Journey Link')
    case 'admins.upsert':
      return pick(lang, 'Cập nhật quyền quản trị viên', 'Add / Update Admin Role')
    case 'admins.remove':
      return pick(lang, 'Gỡ quyền quản trị viên', 'Remove Admin Role')
    case 'system.reset_storage_purge':
      return pick(lang, 'Đặt lại hàng đợi xóa tệp bị kẹt', 'Reset Stuck Storage Purge')
    case 'system.run_storage_sweep':
      return pick(lang, 'Chạy dọn dẹp tệp lưu trữ', 'Run Storage Purge Sweep')
    case 'system.trigger_moderation_notify':
      return pick(lang, 'Gửi cảnh báo kiểm duyệt', 'Trigger Moderation Digest')
    default:
      return formatUnknownEnum(action, lang)
  }
}

export function formatAuditTargetId(
  targetId: string | null | undefined,
  lang: Lang = getCurrentLang(),
): string {
  const trimmed = (targetId ?? '').trim()
  if (!trimmed) return '—'
  switch (trimmed.toLowerCase()) {
    case 'pending_storage_purge':
      return pick(lang, 'Hàng đợi dọn dẹp lưu trữ', 'Storage Purge Queue')
    case 'moderation_queue':
      return pick(lang, 'Hàng đợi kiểm duyệt', 'Moderation Queue')
    case 'bulk_failed':
      return pick(lang, 'Nhóm email gửi lỗi', 'Failed Emails Batch')
    default:
      return trimmed
  }
}

export function formatAuditReason(
  reason: string | null | undefined,
  lang: Lang = getCurrentLang(),
): string {
  const trimmed = (reason ?? '').trim()
  if (!trimmed) return '—'
  const modMatch = /^Action\s+([a-z_]+)\s+executed by operator$/i.exec(trimmed)
  if (modMatch) {
    const act = formatModerationAction(modMatch[1], lang)
    return pick(
      lang,
      `Đã thực thi: ${act}`,
      `Executed moderation decision: ${act}`,
    )
  }
  const frMatch =
    /^Updated status=([a-z_]+),\s*category=([a-z_]+),\s*hidden=(true|false)$/i.exec(
      trimmed,
    )
  if (frMatch) {
    const st = formatFeatureRequestStatus(frMatch[1], lang)
    const cat = formatFeatureRequestCategory(frMatch[2], lang)
    const hid =
      frMatch[3].toLowerCase() === 'true'
        ? pick(lang, 'Đã ẩn', 'Hidden')
        : pick(lang, 'Hiển thị', 'Visible')
    return pick(
      lang,
      `Cập nhật trạng thái: ${st}, danh mục: ${cat} (${hid})`,
      `Updated status: ${st}, category: ${cat} (${hid})`,
    )
  }
  return trimmed
}

const MODERATION_STATUS_VALUES = new Set([
  'open',
  'overdue',
  'quarantined',
  'actioned',
  'dismissed',
])

const WORD_CATEGORY_VALUES = new Set([
  'profanity',
  'slur',
  'sexual',
  'violence',
  'self_harm',
  'csae',
])

function formatAuditMetaStatus(
  raw: string,
  lang: Lang,
  normAction: string,
): string {
  const normVal = raw.toLowerCase().trim()
  if (normAction.startsWith('moderation.')) {
    return formatModerationStatus(raw, lang)
  }
  if (normAction.startsWith('feature_requests.')) {
    return formatFeatureRequestStatus(raw, lang)
  }
  if (normAction.startsWith('users.')) {
    return formatUserStatus(raw, lang)
  }
  if (normAction.startsWith('journeys.')) {
    return formatJourneyStatus(raw, lang)
  }
  if (MODERATION_STATUS_VALUES.has(normVal)) {
    return formatModerationStatus(raw, lang)
  }
  return formatFeatureRequestStatus(raw, lang)
}

function formatAuditMetaCategory(
  raw: string,
  lang: Lang,
  normAction: string,
): string {
  const normVal = raw.toLowerCase().trim()
  if (normAction.startsWith('words.')) {
    return formatWordCategory(raw, lang)
  }
  if (normAction.startsWith('feature_requests.')) {
    return formatFeatureRequestCategory(raw, lang)
  }
  if (WORD_CATEGORY_VALUES.has(normVal)) {
    return formatWordCategory(raw, lang)
  }
  return formatFeatureRequestCategory(raw, lang)
}

export function formatAuditMetaSummary(
  meta: Record<string, unknown> | null | undefined,
  lang: Lang = getCurrentLang(),
  action?: string | null,
): string {
  if (!meta || typeof meta !== 'object') return ''
  const normAction = (action ?? '').toLowerCase().trim()
  const parts: string[] = []
  for (const [k, v] of Object.entries(meta)) {
    if (v === null || v === undefined || v === '') continue
    switch (k) {
      case 'status':
      case 'new_status':
        parts.push(
          `${pick(lang, 'Trạng thái', 'Status')}: ${formatAuditMetaStatus(String(v), lang, normAction)}`,
        )
        break
      case 'old_status':
        parts.push(
          `${pick(lang, 'Trạng thái cũ', 'Prev Status')}: ${formatAuditMetaStatus(String(v), lang, normAction)}`,
        )
        break
      case 'category':
      case 'new_category':
        parts.push(
          `${pick(lang, 'Danh mục', 'Category')}: ${formatAuditMetaCategory(String(v), lang, normAction)}`,
        )
        break
      case 'old_category':
        parts.push(
          `${pick(lang, 'Danh mục cũ', 'Prev Category')}: ${formatAuditMetaCategory(String(v), lang, normAction)}`,
        )
        break
      case 'action':
        parts.push(
          `${pick(lang, 'Quyết định', 'Action')}: ${formatModerationAction(String(v), lang)}`,
        )
        break
      case 'kind':
        parts.push(
          `${pick(lang, 'Loại', 'Kind')}: ${
            normAction.startsWith('journeys.')
              ? formatJourneyKind(String(v), lang)
              : formatModerationKind(String(v), lang)
          }`,
        )
        break
      case 'role':
      case 'removed_role':
        parts.push(
          `${pick(lang, 'Vai trò', 'Role')}: ${formatAdminRole(String(v), lang)}`,
        )
        break
      case 'match_mode':
        parts.push(
          `${pick(lang, 'Chế độ khớp', 'Match Mode')}: ${formatWordMatchMode(String(v), lang)}`,
        )
        break
      case 'lang': {
        const rawLang = String(v).toLowerCase().trim()
        const formattedLang =
          rawLang === 'all'
            ? pick(lang, 'Mọi ngôn ngữ', 'All languages')
            : formatWordLang(String(v), lang)
        parts.push(`${pick(lang, 'Ngôn ngữ', 'Language')}: ${formattedLang}`)
        break
      }
      case 'row_count':
        parts.push(`${pick(lang, 'Số dòng', 'Rows')}: ${String(v)}`)
        break
      case 'reset_count':
        parts.push(`${pick(lang, 'Đã đặt lại', 'Reset')}: ${String(v)}`)
        break
      case 'wipe_ugc':
        parts.push(
          v
            ? pick(lang, 'Xóa toàn bộ nội dung', 'Wiped UGC')
            : pick(lang, 'Khóa có thể hoàn tác', 'Reversible Ban'),
        )
        break
      case 'ttl_seconds':
        parts.push(`${pick(lang, 'Thời hạn', 'TTL')}: ${String(v)}s`)
        break
      case 'expires_at':
        parts.push(
          `${pick(lang, 'Hết hạn', 'Expires')}: ${fmtDateTime(String(v), lang)}`,
        )
        break
      case 'attempted':
        parts.push(`${pick(lang, 'Đã thử', 'Attempted')}: ${String(v)}`)
        break
      case 'sent':
        parts.push(`${pick(lang, 'Đã gửi', 'Sent')}: ${String(v)}`)
        break
      case 'failed':
        parts.push(`${pick(lang, 'Lỗi', 'Failed')}: ${String(v)}`)
        break
      case 'claimed':
        parts.push(`${pick(lang, 'Đã nhận', 'Claimed')}: ${String(v)}`)
        break
      case 'removed':
      case 'removed_objects':
        parts.push(`${pick(lang, 'Đã xóa tệp', 'Removed')}: ${String(v)}`)
        break
      case 'notified':
      case 'notified_users':
        parts.push(`${pick(lang, 'Đã thông báo', 'Notified')}: ${String(v)}`)
        break
      case 'revoked_sessions':
        parts.push(
          `${pick(lang, 'Phiên đã thu hồi', 'Revoked Sessions')}: ${String(v)}`,
        )
        break
      case 'transferred_votes':
        parts.push(
          `${pick(lang, 'Phiếu chuyển giao', 'Transferred Votes')}: ${String(v)}`,
        )
        break
      case 'target_vote_count':
      case 'vote_count':
        parts.push(`${pick(lang, 'Tổng phiếu', 'Votes')}: ${String(v)}`)
        break
      default:
        break
    }
  }
  return parts.join(' · ')
}
