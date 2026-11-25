import { fmtDateShort, useI18n } from '../lib/i18n'
import type { OverviewStats } from '../lib/adminRpc'

const FUNNEL_STEP_LABELS: Record<string, { vi: string; en: string }> = {
  auth_signup: {
    vi: 'Đăng ký tài khoản',
    en: 'Auth Signup',
  },
  terms_accepted: {
    vi: 'Đồng ý điều khoản',
    en: 'Accepted Terms',
  },
  profile_created: {
    vi: 'Tạo hồ sơ cá nhân',
    en: 'Created Profile',
  },
  first_journey: {
    vi: 'Tạo hoặc vào hành trình',
    en: 'Joined / Created Journey',
  },
  first_live_checkin: {
    vi: 'Chụp ảnh ngày đầu',
    en: 'Posted 1st Check-in',
  },
  first_checkin: {
    vi: 'Chụp ảnh ngày đầu',
    en: 'Posted 1st Check-in',
  },
  social_connected: {
    vi: 'Kết nối nhóm / bạn bè',
    en: 'Joined Squad / Added Friend',
  },
}

function formatShortDay(day: string): string {
  // Format YYYY-MM-DD as DD/MM so 30-day charts stay legible
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(day)
  if (m) return `${m[3]}/${m[2]}`
  return day
}

export function BarTrendChart({
  data,
}: {
  data: OverviewStats['daily_growth']
}) {
  const { t } = useI18n()
  const maxVal = Math.max(
    10,
    ...data.flatMap((d) => [
      Number(d.new_profiles ?? 0),
      Number(d.new_waitlist ?? 0),
    ]),
  )
  const chartW = 540
  const chartH = 170
  const padLeft = 34
  const padBottom = 28
  const padTop = 14
  const usableW = chartW - padLeft - 14
  const usableH = chartH - padBottom - padTop
  const groupW = data.length > 0 ? usableW / data.length : usableW
  const labelStep = Math.max(1, Math.ceil(data.length / 8))

  return (
    <div className="card">
      <div className="kpi-top" style={{ marginBottom: 12 }}>
        <div>
          <h3>{t('Tăng trưởng hàng ngày', 'Daily Growth')}</h3>
          <p className="kpi-label">
            {t(
              'Người dùng mới so với lượt đăng ký danh sách chờ',
              'New profiles vs. waitlist signups per day',
            )}
          </p>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <span className="badge badge-primary">
            {t('Người dùng', 'Profiles')}
          </span>
          <span className="badge badge-warn">
            {t('Danh sách chờ', 'Waitlist')}
          </span>
        </div>
      </div>
      <svg
        viewBox={`0 0 ${chartW} ${chartH}`}
        className="svg-chart"
        role="img"
        aria-label={t('Biểu đồ tăng trưởng hàng ngày', 'Daily growth chart')}
      >
        <line
          x1={padLeft}
          y1={padTop + usableH}
          x2={chartW - 10}
          y2={padTop + usableH}
          stroke="var(--outline)"
          strokeWidth="2"
        />
        {data.map((d, idx) => {
          const x0 = padLeft + idx * groupW + groupW * 0.14
          const barW = Math.max(6, groupW * 0.34)
          const profiles = Number(d.new_profiles ?? 0)
          const waitlist = Number(d.new_waitlist ?? 0)
          const hUsers = Math.round((profiles / maxVal) * usableH)
          const hWaitlist = Math.round((waitlist / maxVal) * usableH)
          const showLabel = idx % labelStep === 0 || idx === data.length - 1
          return (
            <g key={d.day}>
              <rect
                x={x0}
                y={padTop + usableH - hUsers}
                width={barW}
                height={Math.max(2, hUsers)}
                rx="4"
                fill="var(--primary)"
                stroke="#1A1A1A"
                strokeWidth="1.5"
              />
              <rect
                x={x0 + barW + 2}
                y={padTop + usableH - hWaitlist}
                width={barW}
                height={Math.max(2, hWaitlist)}
                rx="4"
                fill="var(--pastel-study)"
                stroke="#1A1A1A"
                strokeWidth="1.5"
              />
              {showLabel && (
                <text
                  x={x0 + barW}
                  y={chartH - 8}
                  textAnchor="middle"
                  fontSize="11"
                  fontWeight="700"
                  fill="var(--muted)"
                >
                  {formatShortDay(d.day)}
                </text>
              )}
            </g>
          )
        })}
      </svg>
    </div>
  )
}

export function LineAreaChart({
  data,
}: {
  data: OverviewStats['daily_habit_pulse']
}) {
  const { t } = useI18n()
  const maxVal = Math.max(
    10,
    ...data.flatMap((d) => [Number(d.dau ?? 0), Number(d.live_checkins ?? 0)]),
  )
  const chartW = 540
  const chartH = 170
  const padLeft = 34
  const padBottom = 28
  const padTop = 14
  const usableW = chartW - padLeft - 18
  const usableH = chartH - padBottom - padTop
  const labelStep = Math.max(1, Math.ceil(data.length / 8))

  const toCoords = (key: 'dau' | 'live_checkins') =>
    data.map((d, idx) => {
      const x =
        padLeft +
        (data.length > 1 ? (idx / (data.length - 1)) * usableW : usableW / 2)
      const val = Number(d[key] ?? 0)
      const y = padTop + usableH - (val / maxVal) * usableH
      return { x, y, label: d.day, val, idx }
    })

  const dauPts = toCoords('dau')
  const chkPts = toCoords('live_checkins')

  const linePath = (pts: Array<{ x: number; y: number }>) =>
    pts
      .map((p, i) => `${i === 0 ? 'M' : 'L'}${p.x.toFixed(1)},${p.y.toFixed(1)}`)
      .join(' ')

  return (
    <div className="card">
      <div className="kpi-top" style={{ marginBottom: 12 }}>
        <div>
          <h3>{t('Nhịp độ thói quen mỗi ngày', 'Daily Habit Pulse')}</h3>
          <p className="kpi-label">
            {t(
              'DAU thực chất và số ảnh check-in trực tiếp',
              'Meaningful DAU and live check-ins per day',
            )}
          </p>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <span className="badge badge-success">DAU</span>
          <span className="badge badge-primary">
            {t('Ảnh check-in', 'Check-ins')}
          </span>
        </div>
      </div>
      <svg
        viewBox={`0 0 ${chartW} ${chartH}`}
        className="svg-chart"
        role="img"
        aria-label={t('Biểu đồ nhịp độ thói quen', 'Daily habit pulse chart')}
      >
        <line
          x1={padLeft}
          y1={padTop + usableH}
          x2={chartW - 10}
          y2={padTop + usableH}
          stroke="var(--outline)"
          strokeWidth="2"
        />
        {dauPts.length > 1 && (
          <path
            d={linePath(dauPts)}
            fill="none"
            stroke="var(--pastel-weight)"
            strokeWidth="3.5"
            strokeLinecap="round"
          />
        )}
        {chkPts.length > 1 && (
          <path
            d={linePath(chkPts)}
            fill="none"
            stroke="var(--primary)"
            strokeWidth="3.5"
            strokeLinecap="round"
          />
        )}
        {dauPts.map((p) => {
          const showLabel = p.idx % labelStep === 0 || p.idx === data.length - 1
          return (
            <g key={p.label}>
              <circle
                cx={p.x}
                cy={p.y}
                r="4.5"
                fill="var(--pastel-weight)"
                stroke="#1A1A1A"
                strokeWidth="1.5"
              />
              {showLabel && (
                <text
                  x={p.x}
                  y={chartH - 8}
                  textAnchor="middle"
                  fontSize="11"
                  fontWeight="700"
                  fill="var(--muted)"
                >
                  {formatShortDay(p.label)}
                </text>
              )}
            </g>
          )
        })}
        {chkPts.map((p) => (
          <circle
            key={`chk-${p.label}`}
            cx={p.x}
            cy={p.y}
            r="4.5"
            fill="var(--primary)"
            stroke="#1A1A1A"
            strokeWidth="1.5"
          />
        ))}
      </svg>
    </div>
  )
}

export function FunnelChart({
  steps,
}: {
  steps: OverviewStats['activation_funnel_7d']
}) {
  const { lang, t } = useI18n()
  return (
    <div className="card">
      <div className="kpi-top" style={{ marginBottom: 14 }}>
        <div>
          <h3>{t('Phễu kích hoạt 7 ngày', '7-Day Activation Funnel')}</h3>
          <p className="kpi-label">
            {t(
              'Tỷ lệ chuyển đổi từ lúc tạo tài khoản đến khi chụp ảnh và kết nối nhóm',
              'Conversion from signup to first live snap and squad connection',
            )}
          </p>
        </div>
      </div>
      <div className="funnel-list">
        {steps.map((s) => {
          const localized = FUNNEL_STEP_LABELS[s.step]
          const stepTitle = localized
            ? lang === 'vi'
              ? localized.vi
              : localized.en
            : s.label || s.step
          const pct = Number(s.conversion_pct ?? 0)
          return (
            <div className="funnel-row" key={s.step}>
              <div style={{ fontWeight: 700, fontSize: '0.84rem' }}>
                {stepTitle}
              </div>
              <div className="funnel-track">
                <div
                  className="funnel-bar"
                  style={{ width: `${Math.min(100, Math.max(4, pct))}%` }}
                />
              </div>
              <div
                className="tabular"
                style={{
                  fontWeight: 700,
                  fontSize: '0.84rem',
                  textAlign: 'right',
                }}
              >
                {s.count} ({pct.toFixed(1)}%)
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}

export function CohortHeatmap({
  cohorts,
}: {
  cohorts: OverviewStats['cohort_retention']
}) {
  const { lang, t } = useI18n()
  const cellBg = (pct: number) => {
    if (!pct || pct <= 0) return 'var(--fill)'
    const alpha = Math.min(0.92, Math.max(0.18, pct / 100))
    return `rgba(255, 138, 61, ${alpha.toFixed(2)})`
  }

  const cellTextColor = (pct: number) => {
    if (!pct || pct <= 0) return 'var(--muted)'
    // P1-5: On low/medium alpha (< 55%), composite over Dark Mode (#25221E) is dark brown,
    // so var(--ink) (#ECE5D8 in dark, #1A1A1A in light) guarantees >= 4.5:1 AA contrast.
    // On high alpha (>= 55%), the bright orange fill contrasts cleanly with #1A1A1A.
    return pct >= 55 ? '#1A1A1A' : 'var(--ink)'
  }

  return (
    <div className="card">
      <div className="kpi-top" style={{ marginBottom: 14 }}>
        <div>
          <h3>
            {t(
              'Giữ chân theo tuần (Cohort Retention)',
              'Weekly Cohort Retention',
            )}
          </h3>
          <p className="kpi-label">
            {t(
              'Tỷ lệ người dùng quay lại chụp ảnh vào D1 / D7 / D14 / D30',
              'Percentage of weekly cohort posting a live check-in on D1 / D7 / D14 / D30',
            )}
          </p>
        </div>
      </div>
      <div className="table-wrap" style={{ boxShadow: 'none' }}>
        <table className="data-table">
          <thead>
            <tr>
              <th>{t('Tuần đăng ký', 'Cohort Week')}</th>
              <th>{t('Quy mô', 'Size')}</th>
              <th>D1</th>
              <th>D7</th>
              <th>D14</th>
              <th>D30</th>
            </tr>
          </thead>
          <tbody>
            {cohorts.map((c) => (
              <tr key={c.cohort_week}>
                <td style={{ fontWeight: 700 }}>
                  {fmtDateShort(c.cohort_week, lang)}
                </td>
                <td className="tabular">{c.cohort_size}</td>
                {(['d1_pct', 'd7_pct', 'd14_pct', 'd30_pct'] as const).map(
                  (k) => (
                    <td
                      key={k}
                      className="tabular"
                      style={{
                        background: cellBg(c[k]),
                        fontWeight: 700,
                        color: cellTextColor(c[k]),
                      }}
                    >
                      {c[k] > 0 ? `${c[k]}%` : '—'}
                    </td>
                  ),
                )}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
