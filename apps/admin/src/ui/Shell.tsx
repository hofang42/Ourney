import { useEffect, useState, type FormEvent, type ReactNode } from 'react'
import { NavLink } from 'react-router-dom'
import {
  adminApi,
  isForbiddenError,
  onAdminSessionRevoked,
  supabase,
  type AdminIdentity,
} from '../lib/adminRpc'
import { useI18n } from '../lib/i18n'
import { OIcon, type OIconName } from './Icon'

interface NavItem {
  to: string
  icon: OIconName
  labelVi: string
  labelEn: string
}

const NAV_ITEMS: NavItem[] = [
  { to: '/', icon: 'chart', labelVi: 'Tổng quan', labelEn: 'Overview' },
  {
    to: '/moderation',
    icon: 'shield',
    labelVi: 'Kiểm duyệt (24h SLA)',
    labelEn: 'Moderation Queue',
  },
  {
    to: '/words',
    icon: 'filter',
    labelVi: 'Từ khóa chặn lọc',
    labelEn: 'Content Filter Words',
  },
  {
    to: '/feature-requests',
    icon: 'bulb',
    labelVi: 'Đề xuất tính năng',
    labelEn: 'Feature Requests',
  },
  {
    to: '/waitlist',
    icon: 'email',
    labelVi: 'Danh sách chờ Beta',
    labelEn: 'Waitlist',
  },
  {
    to: '/users',
    icon: 'profile',
    labelVi: 'Người dùng',
    labelEn: 'Users',
  },
  {
    to: '/journeys',
    icon: 'journeys',
    labelVi: 'Hành trình',
    labelEn: 'Journeys',
  },
  {
    to: '/audit',
    icon: 'audit',
    labelVi: 'Nhật ký kiểm toán',
    labelEn: 'Audit Log',
  },
  {
    to: '/settings',
    icon: 'settings',
    labelVi: 'Cài đặt & Vận hành',
    labelEn: 'Settings & Ops',
  },
]

export function AdminAuthGuard({
  children,
}: {
  children: (
    admin: AdminIdentity,
    refreshAdmin: () => Promise<void>,
  ) => ReactNode
}) {
  const { lang, toggleLang, theme, toggleTheme, t } = useI18n()
  const [admin, setAdmin] = useState<AdminIdentity | null>(null)
  const [loading, setLoading] = useState(true)
  const [step, setStep] = useState<'email' | 'otp'>('email')
  const [email, setEmail] = useState('')
  const [otp, setOtp] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [errorMsg, setErrorMsg] = useState<string | null>(null)
  const [infoMsg, setInfoMsg] = useState<string | null>(null)

  const verifyAdminSession = async () => {
    setLoading(true)
    setErrorMsg(null)
    try {
      const identity = await adminApi.me()
      setAdmin(identity)
    } catch (err) {
      setAdmin(null)
      if (isForbiddenError(err)) {
        await adminApi.signOut()
        setErrorMsg(
          t(
            'Tài khoản này không có quyền quản trị viên (42501). Đã tự động đăng xuất.',
            'This account does not have admin privileges (42501). Signed out automatically.',
          ),
        )
      }
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void verifyAdminSession()

    const unsubRevoked = onAdminSessionRevoked((reason) => {
      setAdmin(null)
      setOtp('')
      setStep('email')
      void adminApi.signOut()
      setErrorMsg(
        reason === 'forbidden'
          ? t(
              'Quyền quản trị viên đã bị thu hồi hoặc tài khoản bị khóa (42501). Đã tự động đăng xuất.',
              'Admin privileges were revoked or account was suspended (42501). Signed out automatically.',
            )
          : t(
              'Phiên đăng nhập đã hết hạn. Vui lòng xác thực lại.',
              'Your session has expired. Please sign in again.',
            ),
      )
    })

    const authListener = supabase?.auth?.onAuthStateChange?.((event) => {
      if (event === 'SIGNED_OUT') {
        setAdmin(null)
        setOtp('')
        setStep('email')
      }
    })

    return () => {
      unsubRevoked()
      authListener?.data?.subscription?.unsubscribe()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleSendOtp = async (e: FormEvent) => {
    e.preventDefault()
    if (!email.trim()) return
    setSubmitting(true)
    setErrorMsg(null)
    setInfoMsg(null)
    try {
      await adminApi.signInWithOtp(email)
      setOtp('')
      setStep('otp')
      setInfoMsg(
        t(
          'Mã OTP 6 chữ số đã được gửi tới email của bạn.',
          'A 6-digit OTP code has been sent to your email.',
        ),
      )
    } catch (err) {
      const message = err instanceof Error ? err.message : 'OTP send failed'
      setErrorMsg(message)
    } finally {
      setSubmitting(false)
    }
  }

  const handleVerifyOtp = async (e: FormEvent) => {
    e.preventDefault()
    if (otp.trim().length < 6) return
    setSubmitting(true)
    setErrorMsg(null)
    try {
      await adminApi.verifyOtp(email, otp)
      setOtp('')
      await verifyAdminSession()
    } catch (err) {
      const message =
        err instanceof Error ? err.message : 'OTP verification failed'
      setErrorMsg(message)
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) {
    return (
      <div className="auth-stage">
        <div className="auth-card" role="status">
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div className="brand-mark">
              <OIcon name="camera" size={24} active />
            </div>
            <div>
              <div className="brand-title">Ourney Admin</div>
              <div className="brand-sub">
                {t(
                  'Đang xác thực phiên quản trị...',
                  'Verifying admin session...',
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    )
  }

  if (!admin) {
    return (
      <div className="auth-stage">
        <div className="auth-card">
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              gap: 10,
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <div className="brand-mark">
                <OIcon name="camera" size={24} active />
              </div>
              <div>
                <h1 className="brand-title">Ourney Admin</h1>
                <p className="brand-sub">
                  {t(
                    'Xác thực OTP 6 số dành riêng cho Quản trị viên',
                    '6-Digit Email OTP for Authorized Operators',
                  )}
                </p>
              </div>
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              <button
                type="button"
                className="btn"
                onClick={toggleLang}
                aria-label={t('Đổi ngôn ngữ', 'Toggle language')}
              >
                {lang.toUpperCase()}
              </button>
              <button
                type="button"
                className="btn btn-icon"
                onClick={toggleTheme}
                aria-label={t(
                  'Đổi giao diện Sáng/Tối',
                  'Toggle Light/Dark theme',
                )}
              >
                <OIcon name={theme === 'dark' ? 'moon' : 'sun'} size={20} />
              </button>
            </div>
          </div>

          {errorMsg && (
            <div className="status-banner error" role="alert">
              <span>{errorMsg}</span>
            </div>
          )}
          {infoMsg && (
            <div className="status-banner success" role="status">
              <span>{infoMsg}</span>
            </div>
          )}

          {step === 'email' ? (
            <form onSubmit={handleSendOtp} style={{ display: 'grid', gap: 14 }}>
              <label className="field-group">
                <span className="field-label">
                  {t('Email quản trị viên', 'Admin Email Address')}
                </span>
                <input
                  type="email"
                  required
                  className="input"
                  placeholder="owner@ourney.tech"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                />
              </label>
              <button
                type="submit"
                className="btn btn-primary"
                disabled={submitting}
              >
                <OIcon name="email" size={20} />
                <span>
                  {submitting
                    ? t('Đang gửi mã OTP...', 'Sending OTP...')
                    : t('Gửi mã OTP 6 chữ số', 'Send 6-Digit OTP')}
                </span>
              </button>
            </form>
          ) : (
            <form
              onSubmit={handleVerifyOtp}
              style={{ display: 'grid', gap: 14 }}
            >
              <label className="field-group">
                <span className="field-label">
                  {t('Mã OTP 6 chữ số', '6-Digit Verification Code')}
                </span>
                <input
                  type="text"
                  inputMode="numeric"
                  pattern="[0-9]{6}"
                  maxLength={6}
                  required
                  className="input tabular"
                  placeholder="123456"
                  value={otp}
                  onChange={(e) => setOtp(e.target.value)}
                />
              </label>
              <div style={{ display: 'flex', gap: 10 }}>
                <button
                  type="button"
                  className="btn"
                  onClick={() => {
                    setOtp('')
                    setErrorMsg(null)
                    setInfoMsg(null)
                    setStep('email')
                  }}
                >
                  <OIcon name="back" size={18} />
                  <span>{t('Quay lại', 'Back')}</span>
                </button>
                <button
                  type="submit"
                  className="btn btn-primary"
                  style={{ flex: 1 }}
                  disabled={submitting}
                >
                  <OIcon name="check" size={20} />
                  <span>
                    {submitting
                      ? t('Đang xác minh...', 'Verifying...')
                      : t('Xác minh & Đăng nhập', 'Verify & Sign In')}
                  </span>
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    )
  }

  return <>{children(admin, verifyAdminSession)}</>
}

export function AdminShell({
  admin,
  onSignOut,
  children,
}: {
  admin: AdminIdentity
  onSignOut: () => Promise<void>
  children: ReactNode
}) {
  const { lang, toggleLang, theme, toggleTheme, t } = useI18n()

  return (
    <div className="admin-shell">
      <a href="#admin-main-content" className="skip-link">
        {t('Chuyển tới nội dung chính', 'Skip to main content')}
      </a>

      <aside
        className="admin-sidebar"
        aria-label={t('Điều hướng quản trị', 'Admin navigation')}
      >
        <div className="brand-lockup">
          <div className="brand-mark">
            <OIcon name="camera" size={24} active />
          </div>
          <div>
            <div className="brand-title">Ourney Admin</div>
            <div className="brand-sub">
              {t('Trung tâm Vận hành V2', 'V2 Operations Console')}
            </div>
          </div>
        </div>

        <nav
          className="nav-list"
          aria-label={t('Danh mục trang quản trị', 'Primary admin sections')}
        >
          {NAV_ITEMS.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              className={({ isActive }) =>
                `nav-link ${isActive ? 'active' : ''}`
              }
            >
              <OIcon name={item.icon} size={20} />
              <span>{lang === 'vi' ? item.labelVi : item.labelEn}</span>
            </NavLink>
          ))}
        </nav>

        <div className="sidebar-footer">
          <div className="operator-pill">
            <div className="operator-email" title={admin.email}>
              {admin.display_name || admin.email}
            </div>
            <div className="operator-role-row">
              <span
                className={`badge ${
                  admin.role === 'owner' ? 'badge-primary' : 'badge-sky'
                }`}
              >
                {admin.role === 'owner'
                  ? t('Chủ sở hữu (Owner)', 'Owner')
                  : t('Kiểm duyệt viên', 'Moderator')}
              </span>
              <span style={{ fontSize: '0.75rem', color: 'var(--muted)' }}>
                {admin.username ? `@${admin.username}` : ''}
              </span>
            </div>
          </div>

          <button
            type="button"
            className="btn"
            onClick={() => void onSignOut()}
            style={{ width: '100%' }}
          >
            <OIcon name="sign-out" size={18} />
            <span>{t('Đăng xuất', 'Sign Out')}</span>
          </button>
        </div>
      </aside>

      <div className="admin-main">
        <header className="admin-topbar">
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <span className="badge badge-success">
              <OIcon name="lock" size={15} />
              <span>
                {t(
                  'Bảo mật quyền tối thiểu (RPC-Only)',
                  'Privacy by Construction (RPC-Only)',
                )}
              </span>
            </span>
          </div>

          <div className="topbar-controls">
            <button
              type="button"
              className="btn"
              onClick={toggleLang}
              aria-label={t(
                'Chuyển đổi ngôn ngữ VI/EN',
                'Switch language VI/EN',
              )}
            >
              <span>{lang === 'vi' ? 'VI / Tiếng Việt' : 'EN / English'}</span>
            </button>

            <button
              type="button"
              className="btn"
              onClick={toggleTheme}
              aria-label={t(
                'Chuyển đổi giao diện Sáng/Tối',
                'Toggle Light/Dark mode',
              )}
            >
              <OIcon name={theme === 'dark' ? 'moon' : 'sun'} size={18} />
              <span>
                {theme === 'dark'
                  ? t('Tối (Warm Espresso)', 'Dark (Espresso)')
                  : t('Sáng (Paper Cream)', 'Light (Cream)')}
              </span>
            </button>
          </div>
        </header>

        <main id="admin-main-content" className="admin-content" tabIndex={-1}>
          {children}
        </main>
      </div>
    </div>
  )
}
