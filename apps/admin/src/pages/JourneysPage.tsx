import { useEffect, useState } from 'react'
import {
  adminApi,
  handleRpcError,
  type AdminJourneyRow,
  type JourneyStats,
} from '../lib/adminRpc'
import {
  formatJourneyKind,
  formatJourneyStatus,
  formatJourneyTemplate,
  formatJourneyVisibility,
  useI18n,
} from '../lib/i18n'
import { OIcon } from '../ui/Icon'
import { AccessibleModal, PaginationBar } from '../ui/Modal'

const PAGE_LIMIT = 50

export function JourneysPage() {
  const { lang, t } = useI18n()
  const [stats, setStats] = useState<JourneyStats | null>(null)
  const [total, setTotal] = useState(0)
  const [rows, setRows] = useState<AdminJourneyRow[]>([])
  const [search, setSearch] = useState('')
  const [kindFilter, setKindFilter] = useState('all')
  const [templateFilter, setTemplateFilter] = useState('all')
  const [statusFilter, setStatusFilter] = useState('all')
  const [publicOnly, setPublicOnly] = useState(false)
  const [offset, setOffset] = useState(0)

  const [revokeTarget, setRevokeTarget] = useState<AdminJourneyRow | null>(null)
  const [revokeReason, setRevokeReason] = useState('')
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [bannerMsg, setBannerMsg] = useState<string | null>(null)
  const [errorMsg, setErrorMsg] = useState<string | null>(null)

  const loadData = async (nextOffset = offset) => {
    setLoading(true)
    setErrorMsg(null)
    try {
      const [st, listRes] = await Promise.all([
        adminApi.journeyStats(),
        adminApi.listJourneys({
          p_search: search,
          p_kind: kindFilter,
          p_template: templateFilter,
          p_status: statusFilter,
          p_public_only: publicOnly,
          p_limit: PAGE_LIMIT,
          p_offset: nextOffset,
        }),
      ])
      setStats(st)
      setTotal(listRes.total)
      setRows(listRes.items)
    } catch (err) {
      const msg = await handleRpcError(err, 'list_journeys', lang)
      setErrorMsg(msg)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    setOffset(0)
    void loadData(0)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search, kindFilter, templateFilter, statusFilter, publicOnly])

  const handleConfirmRevoke = async () => {
    if (!revokeTarget || submitting) return
    const trimmed = revokeReason.trim()
    if (trimmed.length < 3) {
      setErrorMsg(
        t(
          'Lý do thu hồi phải có ít nhất 3 ký tự.',
          'Revocation reason must be at least 3 characters.',
        ),
      )
      return
    }
    setSubmitting(true)
    setErrorMsg(null)
    try {
      await adminApi.revokeJourneyPublicLink(revokeTarget.id, trimmed)
      setBannerMsg(
        t(
          `Đã thu hồi liên kết công khai của hành trình ${revokeTarget.id}`,
          `Revoked public link for journey ${revokeTarget.id}`,
        ),
      )
      setRevokeTarget(null)
      setRevokeReason('')
      await loadData(offset)
    } catch (err) {
      const msg = await handleRpcError(err, 'revoke_journey_public_link', lang)
      setErrorMsg(msg)
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
      <div className="page-header">
        <div>
          <h1 className="page-title">
            {t(
              'Thống kê Hành trình & Kiểm soát Liên kết Công khai',
              'Journeys & Public Link Controls',
            )}
          </h1>
          <p className="page-subtitle">
            {t(
              'Tiêu đề hành trình riêng tư hoặc nhóm đều được ẩn tự động để bảo vệ quyền riêng tư — chỉ hiển thị tiêu đề khi người dùng bật liên kết chia sẻ công khai.',
              'Private and group journey titles are automatically hidden to protect user privacy — titles only appear when visibility is public link.',
            )}
          </p>
        </div>
      </div>

      {errorMsg && !revokeTarget && (
        <div className="status-banner error" role="alert">
          <span>{errorMsg}</span>
        </div>
      )}

      {bannerMsg && (
        <div className="status-banner success" role="status">
          <span>{bannerMsg}</span>
        </div>
      )}

      {stats && (
        <div className="kpi-grid">
          <div className="kpi-card">
            <span className="kpi-label">
              {t('Trạng thái hành trình', 'Active / Ended / Archived')}
            </span>
            <div className="kpi-value">
              {stats.active} / {stats.ended} / {stats.archived}
            </div>
          </div>

          <div className="kpi-card">
            <span className="kpi-label">
              {t('Phân loại Cá nhân / Nhóm / Cặp đôi', 'Solo / Group / Couple')}
            </span>
            <div className="kpi-value">
              {stats.solo_count} / {stats.group_count} / {stats.couple_count}
            </div>
          </div>

          <div className="kpi-card">
            <span className="kpi-label">
              {t('Nguồn tạo (Trực tiếp vs Nhập lại)', 'Live vs Imported')}
            </span>
            <div className="kpi-value">
              {stats.live_count} / {stats.imported_count}
            </div>
          </div>

          <div className="kpi-card">
            <span className="kpi-label">
              {t(
                'Liên kết công khai đang mở & Lượt xem',
                'Active Public Links & Views',
              )}
            </span>
            <div className="kpi-value">
              {stats.public_links_count} ({stats.total_public_views}{' '}
              {t('lượt xem', 'views')})
            </div>
          </div>
        </div>
      )}

      <div className="filter-bar">
        <input
          type="search"
          className="input search-input"
          aria-label={t('Tìm kiếm hành trình', 'Search journeys')}
          placeholder={t(
            'Tìm theo @username chủ sở hữu hoặc mã hành trình...',
            'Search owner @username or Journey ID...',
          )}
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />

        <select
          aria-label={t('Loại hành trình', 'Journey kind')}
          className="select"
          value={kindFilter}
          onChange={(e) => setKindFilter(e.target.value)}
        >
          <option value="all">{t('Mọi loại', 'All kinds')}</option>
          <option value="solo">{formatJourneyKind('solo', lang)}</option>
          <option value="group">{formatJourneyKind('group', lang)}</option>
          <option value="couple">{formatJourneyKind('couple', lang)}</option>
        </select>

        <select
          aria-label={t('Mẫu giao diện', 'Persona template')}
          className="select"
          value={templateFilter}
          onChange={(e) => setTemplateFilter(e.target.value)}
        >
          <option value="all">{t('Mọi mẫu giao diện', 'All templates')}</option>
          <option value="weight_loss">
            {formatJourneyTemplate('weight_loss', lang)}
          </option>
          <option value="english_daily">
            {formatJourneyTemplate('english_daily', lang)}
          </option>
          <option value="travel">
            {formatJourneyTemplate('travel', lang)}
          </option>
          <option value="couple">
            {formatJourneyTemplate('couple', lang)}
          </option>
          <option value="workout_30">
            {formatJourneyTemplate('workout_30', lang)}
          </option>
          <option value="custom">
            {formatJourneyTemplate('custom', lang)}
          </option>
        </select>

        <select
          aria-label={t('Trạng thái hành trình', 'Journey status')}
          className="select"
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
        >
          <option value="all">{t('Mọi trạng thái', 'All statuses')}</option>
          <option value="active">{formatJourneyStatus('active', lang)}</option>
          <option value="ended">{formatJourneyStatus('ended', lang)}</option>
          <option value="archived">
            {formatJourneyStatus('archived', lang)}
          </option>
        </select>

        <button
          type="button"
          aria-pressed={publicOnly}
          className={`btn ${publicOnly ? 'btn-primary' : ''}`}
          onClick={() => setPublicOnly((prev) => !prev)}
        >
          <OIcon name="share" size={18} />
          <span>
            {t('Chỉ hiện có liên kết công khai', 'Public Links Only')}
          </span>
        </button>
      </div>

      <div className="table-wrap">
        <table className="data-table">
          <thead>
            <tr>
              <th>ID & {t('Chủ sở hữu', 'Owner')}</th>
              <th>{t('Loại & Mẫu', 'Kind & Template')}</th>
              <th>
                {t(
                  'Tiêu đề (Đã bảo vệ quyền riêng tư)',
                  'Title (Privacy-Protected)',
                )}
              </th>
              <th>{t('Thành viên & Check-ins', 'Members & Check-ins')}</th>
              <th>{t('Lượt xem công khai', 'Public Views')}</th>
              <th>{t('Thao tác', 'Actions')}</th>
            </tr>
          </thead>
          <tbody>
            {loading && rows.length === 0 ? (
              <tr>
                <td colSpan={6} style={{ textAlign: 'center', padding: 28 }}>
                  {t(
                    'Đang tải danh sách hành trình...',
                    'Loading journeys...',
                  )}
                </td>
              </tr>
            ) : rows.length === 0 ? (
              <tr>
                <td colSpan={6} style={{ textAlign: 'center', padding: 28 }}>
                  {t(
                    'Không tìm thấy hành trình nào khớp với bộ lọc.',
                    'No journeys match the current filters.',
                  )}
                </td>
              </tr>
            ) : (
              rows.map((j) => {
              const kindLabel = j.is_couple ? 'couple' : j.kind
              const membersLabel =
                j.max_members !== null && j.max_members !== undefined
                  ? `${j.active_members}/${j.max_members}`
                  : `${j.active_members}`
              return (
                <tr key={j.id}>
                  <td>
                    <div style={{ fontWeight: 700 }}>
                      {j.owner_username
                        ? `@${j.owner_username}`
                        : j.owner_id.slice(0, 8)}
                    </div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--muted)' }}>
                      {j.id}
                    </div>
                  </td>
                  <td>
                    <span className="badge">
                      {formatJourneyKind(kindLabel, lang)}
                    </span>{' '}
                    <span className="badge badge-sky">
                      {formatJourneyTemplate(j.template_id, lang)}
                    </span>
                  </td>
                  <td>
                    {j.public_token && j.title ? (
                      <span style={{ fontWeight: 700 }}>{j.title}</span>
                    ) : (
                      <span
                        style={{ color: 'var(--muted)', fontStyle: 'italic' }}
                      >
                        {t(
                          '[Hành trình riêng tư — Đã ẩn tiêu đề]',
                          '[Private Journey — Title Hidden]',
                        )}
                      </span>
                    )}
                  </td>
                  <td className="tabular">
                    {membersLabel} · {j.checkin_count} {t('ảnh', 'snaps')}
                  </td>
                  <td className="tabular">{j.public_views}</td>
                  <td>
                    {j.public_token ? (
                      <div style={{ display: 'flex', gap: 8 }}>
                        <a
                          href={`https://ourney.tech/p/${encodeURIComponent(j.public_token)}`}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="btn"
                          title={`/p/${j.public_token}`}
                        >
                          <OIcon name="external" size={16} />
                          <span>
                            {t('Mở trang công khai', 'Open public page')}
                          </span>
                        </a>
                        <button
                          type="button"
                          className="btn btn-danger"
                          disabled={submitting}
                          aria-label={`${t('Thu hồi link', 'Revoke Link')} ${j.id}`}
                          onClick={() => {
                            setErrorMsg(null)
                            setRevokeTarget(j)
                          }}
                        >
                          <OIcon name="ban" size={16} />
                          <span>{t('Thu hồi link', 'Revoke Link')}</span>
                        </button>
                      </div>
                    ) : (
                      <span className="badge">
                        {formatJourneyVisibility(j.visibility, lang)}
                      </span>
                    )}
                  </td>
                </tr>
              )
            })
            )}
          </tbody>
        </table>
      </div>

      <PaginationBar
        total={total}
        limit={PAGE_LIMIT}
        offset={offset}
        onChangeOffset={(next) => {
          setOffset(next)
          void loadData(next)
        }}
      />

      {revokeTarget && (
        <AccessibleModal
          title={t(
            'Thu hồi liên kết công khai',
            'Revoke Public Journey Link',
          )}
          onClose={() => {
            if (submitting) return
            setRevokeTarget(null)
            setRevokeReason('')
            setErrorMsg(null)
          }}
        >
          <h3>
            {t('Thu hồi liên kết công khai', 'Revoke Public Journey Link')}
          </h3>
          {errorMsg && (
            <div className="status-banner error" role="alert">
              <span>{errorMsg}</span>
            </div>
          )}
          <label className="field-group">
            <span className="field-label">
              {t(
                'Lý do thu hồi (tối thiểu 3 ký tự)',
                'Revocation Reason (min 3 chars)',
              )}
            </span>
            <input
              type="text"
              className="input"
              minLength={3}
              maxLength={500}
              value={revokeReason}
              onChange={(e) => setRevokeReason(e.target.value)}
              placeholder={t(
                'Liên kết bị báo cáo lạm dụng...',
                'Public link reported for abuse...',
              )}
            />
          </label>
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
            <button
              type="button"
              className="btn"
              disabled={submitting}
              onClick={() => {
                setRevokeTarget(null)
                setRevokeReason('')
                setErrorMsg(null)
              }}
            >
              {t('Hủy', 'Cancel')}
            </button>
            <button
              type="button"
              className="btn btn-danger"
              disabled={submitting || revokeReason.trim().length < 3}
              onClick={() => void handleConfirmRevoke()}
            >
              {t('Xác nhận thu hồi', 'Confirm Revoke')}
            </button>
          </div>
        </AccessibleModal>
      )}
    </div>
  )
}
