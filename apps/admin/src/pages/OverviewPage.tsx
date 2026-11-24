import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  adminApi,
  handleRpcError,
  type OverviewFeatureRequestTopItem,
  type OverviewStats,
} from '../lib/adminRpc'
import { useI18n } from '../lib/i18n'
import {
  BarTrendChart,
  CohortHeatmap,
  FunnelChart,
  LineAreaChart,
} from '../ui/Charts'
import { OIcon } from '../ui/Icon'

const TEMPLATE_LABELS: Record<
  string,
  { vi: string; en: string; pastel: string }
> = {
  weight_loss: {
    vi: 'Giảm cân (Quiet Transformer)',
    en: 'Weight Loss (Quiet Transformer)',
    pastel: 'var(--pastel-weight)',
  },
  english_daily: {
    vi: 'Tiếng Anh mỗi ngày (Accountability Squad)',
    en: 'Daily Study (Accountability Squad)',
    pastel: 'var(--pastel-study)',
  },
  travel: {
    vi: 'Chuyến đi (Memory Collectors)',
    en: 'Travel (Memory Collectors)',
    pastel: 'var(--pastel-trip)',
  },
  couple: {
    vi: 'Cặp đôi (Couple Rituals)',
    en: 'Couple (Couple Rituals)',
    pastel: 'var(--pastel-couple)',
  },
  workout_30: {
    vi: 'Tập luyện 30 ngày (Aesthetic Flexer)',
    en: 'Workout 30 (Aesthetic Flexer)',
    pastel: 'var(--pastel-workout)',
  },
  custom: {
    vi: 'Thói quen tối giản (Minimalist Habit)',
    en: 'Custom (Minimalist Habit)',
    pastel: 'var(--pastel-custom)',
  },
}

export function OverviewPage() {
  const { lang, t } = useI18n()
  const [days, setDays] = useState<number>(30)
  const [tz, setTz] = useState<string>('Asia/Ho_Chi_Minh')
  const [stats, setStats] = useState<OverviewStats | null>(null)
  const [loading, setLoading] = useState<boolean>(true)
  const [errorMsg, setErrorMsg] = useState<string | null>(null)

  const loadOverview = async (d = days, timezone = tz) => {
    setLoading(true)
    setErrorMsg(null)
    try {
      const [res, frStats] = await Promise.all([
        adminApi.overviewStats(d, timezone),
        adminApi.featureRequestStats().catch(() => null),
      ])
      if (frStats) {
        const mergedTopVoted: OverviewFeatureRequestTopItem[] =
          frStats.top_voted.length > 0
            ? frStats.top_voted
            : (res.kpis.feature_requests?.top_voted ?? [])
        setStats({
          ...res,
          alerts: {
            ...res.alerts,
            untriaged_feature_requests: frStats.new,
          },
          kpis: {
            ...res.kpis,
            feature_requests: {
              new_7d: frStats.new_this_week,
              untriaged_count: frStats.new,
              open_count:
                frStats.new +
                frStats.under_review +
                frStats.planned +
                frStats.in_progress,
              shipped_count: frStats.shipped,
              top_voted: mergedTopVoted,
            },
          },
        })
      } else {
        setStats(res)
      }
    } catch (err) {
      const msg = await handleRpcError(err, 'overview_stats')
      setErrorMsg(msg)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void loadOverview(days, tz)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [days, tz])

  const alerts = stats?.alerts
  const kpis = stats?.kpis
  const frKpis = kpis?.feature_requests ?? null
  const topFeatureRequests = frKpis?.top_voted ?? []
  const topVotedFirst = topFeatureRequests[0] ?? null

  const hasUrgent = Boolean(
    alerts &&
      (alerts.open_reports > 0 ||
        alerts.open_blocks > 0 ||
        alerts.untriaged_feature_requests > 0 ||
        alerts.failed_waitlist_emails > 0 ||
        alerts.stuck_storage_purge > 0 ||
        alerts.pending_storage_purge > 0),
  )

  const maxTemplateCount = Math.max(
    1,
    ...(stats?.template_mix.map((m) => m.active_journeys) ?? [1]),
  )

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 22 }}>
      <div className="page-header">
        <div>
          <h1 className="page-title">
            {t('Tổng quan vận hành hàng ngày', 'Daily Operations Overview')}
          </h1>
          <p className="page-subtitle">
            {t(
              'Kiểm tra SLA 24h, tăng trưởng danh sách chờ, đề xuất tính năng và tỷ lệ duy trì chuỗi thói quen.',
              '60-second daily health check: 24h SLA alerts, waitlist velocity, feature requests, and habit retention.',
            )}
          </p>
        </div>

        <div className="filter-bar">
          <select
            aria-label={t('Múi giờ báo cáo', 'Report timezone')}
            className="select"
            value={tz}
            onChange={(e) => setTz(e.target.value)}
          >
            <option value="Asia/Ho_Chi_Minh">Asia/Ho_Chi_Minh (GMT+7)</option>
            <option value="UTC">UTC</option>
          </select>

          <select
            aria-label={t('Khoảng thời gian', 'Time window')}
            className="select"
            value={days}
            onChange={(e) => setDays(Number(e.target.value))}
          >
            <option value={7}>{t('7 ngày qua', 'Last 7 days')}</option>
            <option value={30}>{t('30 ngày qua', 'Last 30 days')}</option>
            <option value={90}>{t('90 ngày qua', 'Last 90 days')}</option>
          </select>

          <button
            type="button"
            className="btn"
            onClick={() => void loadOverview(days, tz)}
            disabled={loading}
          >
            <OIcon name="refresh" size={18} />
            <span>{t('Làm mới', 'Refresh')}</span>
          </button>

          <a
            href="https://dash.cloudflare.com"
            target="_blank"
            rel="noopener noreferrer"
            className="btn"
          >
            <OIcon name="external" size={18} />
            <span>Cloudflare Web Analytics</span>
          </a>
        </div>
      </div>

      {errorMsg && (
        <div className="status-banner error" role="alert">
          <span>{errorMsg}</span>
        </div>
      )}

      {loading && !stats && (
        <div className="card" role="status">
          <span>
            {t(
              'Đang tải dữ liệu tổng quan vận hành...',
              'Loading operations overview...',
            )}
          </span>
        </div>
      )}

      {stats && alerts && kpis && (
        <>
          {hasUrgent && (
            <section
              aria-label={t('Cảnh báo cần xử lý ngay', 'Urgent action items')}
              className="urgent-strip"
            >
              {(alerts.open_reports > 0 || alerts.open_blocks > 0) && (
                <Link
                  to="/moderation?status=open"
                  className={`urgent-item ${
                    alerts.overdue_reports > 0 ||
                    (alerts.earliest_hours_remaining !== null &&
                      alerts.earliest_hours_remaining < 4)
                      ? 'danger'
                      : ''
                  }`}
                >
                  <div
                    style={{ display: 'flex', alignItems: 'center', gap: 10 }}
                  >
                    <OIcon name="warning" size={22} />
                    <div>
                      <div>
                        {t(
                          `${alerts.open_reports} báo cáo kiểm duyệt đang mở`,
                          `${alerts.open_reports} open moderation reports`,
                        )}
                      </div>
                      <div style={{ fontSize: '0.78rem', fontWeight: 600 }}>
                        {alerts.earliest_hours_remaining !== null
                          ? t(
                              `SLA gần nhất còn ${alerts.earliest_hours_remaining.toFixed(1)}h`,
                              `Earliest SLA due in ${alerts.earliest_hours_remaining.toFixed(1)}h`,
                            )
                          : t('Cần xử lý trong 24h', '24h SLA window')}
                      </div>
                    </div>
                  </div>
                  <OIcon name="caret-right" size={18} />
                </Link>
              )}

              {alerts.untriaged_feature_requests > 0 && (
                <Link
                  to="/feature-requests?status=new"
                  className="urgent-item"
                >
                  <div
                    style={{ display: 'flex', alignItems: 'center', gap: 10 }}
                  >
                    <OIcon name="bulb" size={22} />
                    <div>
                      <div>
                        {t(
                          `${alerts.untriaged_feature_requests} đề xuất tính năng mới`,
                          `${alerts.untriaged_feature_requests} untriaged feature requests`,
                        )}
                      </div>
                      <div style={{ fontSize: '0.78rem', fontWeight: 600 }}>
                        {t(
                          'Đang chờ phân loại lộ trình',
                          'Awaiting roadmap triage',
                        )}
                      </div>
                    </div>
                  </div>
                  <OIcon name="caret-right" size={18} />
                </Link>
              )}

              {alerts.failed_waitlist_emails > 0 && (
                <Link
                  to="/waitlist?mail_status=failed"
                  className="urgent-item danger"
                >
                  <div
                    style={{ display: 'flex', alignItems: 'center', gap: 10 }}
                  >
                    <OIcon name="email" size={22} />
                    <div>
                      <div>
                        {t(
                          `${alerts.failed_waitlist_emails} email danh sách chờ gửi lỗi`,
                          `${alerts.failed_waitlist_emails} failed waitlist confirmation emails`,
                        )}
                      </div>
                      <div style={{ fontSize: '0.78rem', fontWeight: 600 }}>
                        {t(
                          'Bấm để gửi lại qua Resend',
                          'Click to retry via Resend',
                        )}
                      </div>
                    </div>
                  </div>
                  <OIcon name="caret-right" size={18} />
                </Link>
              )}

              {(alerts.stuck_storage_purge > 0 ||
                alerts.pending_storage_purge > 0) && (
                <Link to="/settings" className="urgent-item">
                  <div
                    style={{ display: 'flex', alignItems: 'center', gap: 10 }}
                  >
                    <OIcon name="trash" size={22} />
                    <div>
                      <div>
                        {t(
                          `${alerts.pending_storage_purge} tệp chờ dọn dẹp Storage`,
                          `${alerts.pending_storage_purge} pending storage purge files`,
                        )}
                      </div>
                      <div style={{ fontSize: '0.78rem', fontWeight: 600 }}>
                        {t(
                          `Bị kẹt: ${alerts.stuck_storage_purge}`,
                          `Stuck retries: ${alerts.stuck_storage_purge}`,
                        )}
                      </div>
                    </div>
                  </div>
                  <OIcon name="caret-right" size={18} />
                </Link>
              )}
            </section>
          )}

          <section
            aria-label={t('Chỉ số KPI cốt lõi', 'Core KPI cards')}
            className="kpi-grid"
          >
            <div className="kpi-card">
              <div className="kpi-top">
                <span className="kpi-label">
                  {t('Tổng người dùng', 'Total Users')}
                </span>
                <OIcon name="profile" size={20} />
              </div>
              <div className="kpi-value">{kpis.users.live_profiles}</div>
              <div className="kpi-sub">
                <span className="badge badge-success">
                  +{kpis.users.new_today} {t('hôm nay', 'today')}
                </span>
                <span>
                  +{kpis.users.new_7d} (7d) / {kpis.users.total_auth} Auth
                </span>
              </div>
            </div>

            <div className="kpi-card">
              <div className="kpi-top">
                <span className="kpi-label">
                  {t('Danh sách chờ Beta', 'Waitlist Signups')}
                </span>
                <OIcon name="email" size={20} />
              </div>
              <div className="kpi-value">{kpis.waitlist.total}</div>
              <div className="kpi-sub">
                <span className="badge badge-warn">
                  +{kpis.waitlist.new_7d} (7d)
                </span>
                <span>
                  {kpis.waitlist.converted_pct.toFixed(1)}%{' '}
                  {t('đã vào app', 'converted')}
                </span>
              </div>
            </div>

            <div className="kpi-card">
              <div className="kpi-top">
                <span className="kpi-label">DAU / WAU / MAU</span>
                <OIcon name="activity" size={20} />
              </div>
              <div className="kpi-value">
                {kpis.engagement.dau} / {kpis.engagement.wau} /{' '}
                {kpis.engagement.mau}
              </div>
              <div className="kpi-sub">
                <span className="badge badge-primary">
                  Stickiness {kpis.engagement.stickiness_pct.toFixed(1)}%
                </span>
              </div>
            </div>

            <div className="kpi-card">
              <div className="kpi-top">
                <span className="kpi-label">
                  {t('Ảnh chụp (Check-ins)', 'Check-ins Today / 7d')}
                </span>
                <OIcon name="camera" size={20} />
              </div>
              <div className="kpi-value">
                {kpis.checkins.today} / {kpis.checkins.last_7d}
              </div>
              <div className="kpi-sub">
                <span className="badge badge-success">
                  {kpis.checkins.camera_pct_7d.toFixed(1)}%{' '}
                  {t('Camera trực tiếp', 'In-app camera')}
                </span>
              </div>
            </div>

            <div className="kpi-card">
              <div className="kpi-top">
                <span className="kpi-label">
                  {t('Chuỗi lửa đang giữ', 'Active Streaks')}
                </span>
                <OIcon name="flame" size={20} />
              </div>
              <div className="kpi-value">{kpis.streaks.streak_3d_plus}</div>
              <div className="kpi-sub">
                <span>{t('Chuỗi >= 3 ngày', 'Streak >= 3d')}</span>
                <span className="badge badge-warn">
                  {kpis.streaks.streak_7d_plus} {t('>= 7 ngày', '>= 7d')}
                </span>
              </div>
            </div>

            <div className="kpi-card">
              <div className="kpi-top">
                <span className="kpi-label">
                  {t('Hàng đợi kiểm duyệt', 'Open Moderation Queue')}
                </span>
                <OIcon name="shield" size={20} />
              </div>
              <div className="kpi-value">{kpis.moderation.open_reports}</div>
              <div className="kpi-sub">
                <span className="badge badge-success">
                  24h SLA: {kpis.moderation.sla_compliance_pct_30d}%
                </span>
                <span>
                  {kpis.moderation.open_blocks}{' '}
                  {t('tín hiệu chặn', 'blocks')}
                </span>
              </div>
            </div>

            <div className="kpi-card">
              <div className="kpi-top">
                <span className="kpi-label">
                  {t(
                    'Đề xuất tính năng (7 ngày)',
                    'New Feature Requests (7d)',
                  )}
                </span>
                <OIcon name="bulb" size={20} />
              </div>
              <div className="kpi-value">+{frKpis?.new_7d ?? 0}</div>
              <div className="kpi-sub">
                <span className="badge badge-purple">
                  {frKpis?.untriaged_count ?? 0}{' '}
                  {t('chưa phân loại', 'untriaged')}
                </span>
                {topVotedFirst && (
                  <Link
                    to={`/feature-requests?id=${encodeURIComponent(topVotedFirst.id)}`}
                    style={{ fontWeight: 700, textDecoration: 'underline' }}
                  >
                    Top #1 ({topVotedFirst.vote_count} votes)
                  </Link>
                )}
              </div>
            </div>
          </section>

          <div className="charts-grid">
            <BarTrendChart data={stats.daily_growth} />
            <LineAreaChart data={stats.daily_habit_pulse} />
          </div>

          <div className="charts-grid">
            <FunnelChart steps={stats.activation_funnel_7d} />
            <CohortHeatmap cohorts={stats.cohort_retention} />
          </div>

          <div className="charts-grid">
            <div className="card">
              <div className="kpi-top" style={{ marginBottom: 14 }}>
                <div>
                  <h3>
                    {t(
                      'Đề xuất tính năng được bình chọn cao nhất',
                      'Top Voted Feature Requests',
                    )}
                  </h3>
                  <p className="kpi-label">
                    {t(
                      '5 ý tưởng mở nhận nhiều phiếu bầu nhất từ người dùng trong ứng dụng',
                      'Top 5 open community requests by unique user votes',
                    )}
                  </p>
                </div>
                <Link to="/feature-requests" className="btn">
                  <span>{t('Xem tất cả', 'View All')}</span>
                  <OIcon name="caret-right" size={16} />
                </Link>
              </div>

              <div
                style={{ display: 'flex', flexDirection: 'column', gap: 10 }}
              >
                {topFeatureRequests.length === 0 ? (
                  <p className="page-subtitle">
                    {frKpis === null
                      ? t(
                          'Chưa cài đặt bảng đề xuất tính năng (Migration 0024).',
                          'Feature requests table not installed yet (Migration 0024).',
                        )
                      : t(
                          'Chưa có đề xuất tính năng nào đang mở.',
                          'No open feature requests yet.',
                        )}
                  </p>
                ) : (
                  topFeatureRequests.map((fr) => (
                    <Link
                      key={fr.id}
                      to={`/feature-requests?id=${encodeURIComponent(fr.id)}`}
                      className="card-subtle"
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        gap: 12,
                      }}
                    >
                      <div
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: 12,
                        }}
                      >
                        <span className="badge badge-primary tabular">
                          {fr.vote_count} votes
                        </span>
                        <div>
                          <div style={{ fontWeight: 700 }}>{fr.title}</div>
                          <div
                            style={{
                              display: 'flex',
                              gap: 6,
                              marginTop: 4,
                              fontSize: '0.75rem',
                            }}
                          >
                            <span className="badge">{fr.category}</span>
                            <span className="badge badge-sky">{fr.status}</span>
                          </div>
                        </div>
                      </div>
                      <OIcon name="caret-right" size={18} />
                    </Link>
                  ))
                )}
              </div>
            </div>

            <div className="card">
              <div className="kpi-top" style={{ marginBottom: 14 }}>
                <div>
                  <h3>
                    {t(
                      'Phân bổ 6 Giao diện Hành trình (Persona Mix)',
                      '6-Persona Template Mix',
                    )}
                  </h3>
                  <p className="kpi-label">
                    {t(
                      'Số hành trình đang hoạt động theo từng mẫu Persona',
                      'Active journeys grouped by Persona Template',
                    )}
                  </p>
                </div>
                <Link to="/journeys" className="btn">
                  <span>{t('Chi tiết', 'Details')}</span>
                  <OIcon name="caret-right" size={16} />
                </Link>
              </div>

              <div className="funnel-list">
                {stats.template_mix.map((row) => {
                  const meta = TEMPLATE_LABELS[row.template] ?? {
                    vi: row.template,
                    en: row.template,
                    pastel: 'var(--pastel-study)',
                  }
                  const pct = Math.round(
                    (row.active_journeys / maxTemplateCount) * 100,
                  )
                  return (
                    <div className="funnel-row" key={row.template}>
                      <div style={{ fontWeight: 700, fontSize: '0.84rem' }}>
                        {lang === 'vi' ? meta.vi : meta.en}
                      </div>
                      <div className="funnel-track">
                        <div
                          className="funnel-bar"
                          style={{
                            width: `${Math.max(8, pct)}%`,
                            background: meta.pastel,
                          }}
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
                        {row.active_journeys}
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  )
}
