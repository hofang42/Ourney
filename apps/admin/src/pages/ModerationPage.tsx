import { useEffect, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import {
  adminApi,
  handleRpcError,
  type ModerationItemDetail,
  type ModerationQueueRow,
  type ModerationQueueSummary,
  type RevealedMediaObject,
} from '../lib/adminRpc'
import { useI18n } from '../lib/i18n'
import { OIcon } from '../ui/Icon'
import { AccessibleModal, PaginationBar } from '../ui/Modal'

const PAGE_LIMIT = 50

export function formatSlaBadge(
  row: Pick<ModerationQueueRow, 'status' | 'hours_remaining' | 'handled_at'>,
  t: (vi: string, en: string) => string,
): { text: string; tone: 'badge-danger' | 'badge-warn' | 'badge-success' } {
  if (row.status !== 'open') {
    return {
      text: t('Đã xử lý', 'Handled'),
      tone: 'badge-success',
    }
  }
  if (row.hours_remaining < 0) {
    const over = Math.abs(row.hours_remaining).toFixed(1)
    return {
      text: `OVERDUE +${over}h`,
      tone: 'badge-danger',
    }
  }
  const hrs = Math.floor(row.hours_remaining)
  const mins = Math.round((row.hours_remaining - hrs) * 60)
  return {
    text: `${hrs}h ${mins}m left`,
    tone: row.hours_remaining < 4 ? 'badge-warn' : 'badge-success',
  }
}

export function ModerationPage() {
  const { t } = useI18n()
  const [searchParams] = useSearchParams()
  const [statusFilter, setStatusFilter] = useState(
    searchParams.get('status') || 'open',
  )
  const [kindFilter, setKindFilter] = useState('all')
  const [reasonFilter, setReasonFilter] = useState('all')
  const [offset, setOffset] = useState(0)

  const [summary, setSummary] = useState<ModerationQueueSummary | null>(null)
  const [total, setTotal] = useState(0)
  const [rows, setRows] = useState<ModerationQueueRow[]>([])
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [detail, setDetail] = useState<ModerationItemDetail | null>(null)
  const [revealedObjects, setRevealedObjects] = useState<RevealedMediaObject[]>(
    [],
  )
  const [unblurred, setUnblurred] = useState(false)
  const [loading, setLoading] = useState(true)
  const [revealing, setRevealing] = useState(false)
  const [bannerMsg, setBannerMsg] = useState<string | null>(null)
  const [errorMsg, setErrorMsg] = useState<string | null>(null)

  const [modalAction, setModalAction] = useState<
    'dismiss' | 'quarantine' | 'remove_content' | 'ban_user' | null
  >(null)
  const [resolutionNote, setResolutionNote] = useState('')
  const [submitting, setSubmitting] = useState(false)

  const loadQueue = async (nextOffset = offset) => {
    setLoading(true)
    setErrorMsg(null)
    try {
      const res = await adminApi.listModerationQueue({
        p_status: statusFilter,
        p_kind: kindFilter,
        p_reason: reasonFilter,
        p_limit: PAGE_LIMIT,
        p_offset: nextOffset,
      })
      setSummary(res.summary)
      setTotal(res.total)
      setRows(res.items)
      if (res.items.length > 0) {
        const nextId =
          selectedId && res.items.some((r) => r.id === selectedId)
            ? selectedId
            : res.items[0].id
        setSelectedId(nextId)
      } else {
        setSelectedId(null)
        setDetail(null)
      }
    } catch (err) {
      const msg = await handleRpcError(err, 'list_moderation_queue')
      setErrorMsg(msg)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    setOffset(0)
    void loadQueue(0)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [statusFilter, kindFilter, reasonFilter])

  useEffect(() => {
    if (!selectedId) {
      setDetail(null)
      return
    }
    setRevealedObjects([])
    setUnblurred(false)
    void (async () => {
      try {
        const d = await adminApi.getModerationItem(selectedId)
        setDetail(d)
      } catch (err) {
        const msg = await handleRpcError(err, 'get_moderation_item')
        setErrorMsg(msg)
        setDetail(null)
      }
    })()
  }, [selectedId])

  const handleRevealMedia = async () => {
    if (!selectedId) return
    setRevealing(true)
    setErrorMsg(null)
    try {
      const res = await adminApi.revealReportedMedia(
        selectedId,
        '24h SLA moderation inspection',
      )
      setRevealedObjects(res.objects)
      setUnblurred(false)
      setBannerMsg(
        t(
          'Đã cấp quyền xem ảnh bị báo cáo trong 5 phút (đã ghi nhật ký kiểm toán).',
          'Granted 5-minute reported media access (recorded in audit log).',
        ),
      )
    } catch (err) {
      const msg = await handleRpcError(err, 'reveal_reported_media')
      setErrorMsg(msg)
    } finally {
      setRevealing(false)
    }
  }

  const handleConfirmResolution = async () => {
    if (!selectedId || !modalAction) return
    setSubmitting(true)
    setErrorMsg(null)
    try {
      const note =
        resolutionNote.trim() || `Action ${modalAction} executed by operator`
      if (modalAction === 'quarantine') {
        await adminApi.quarantineModerationTarget(selectedId, note)
      } else {
        await adminApi.resolveModeration(selectedId, modalAction, note)
      }
      setBannerMsg(
        t(
          `Đã thực thi hành động kiểm duyệt: ${modalAction}`,
          `Executed moderation action: ${modalAction}`,
        ),
      )
      setModalAction(null)
      setResolutionNote('')
      await loadQueue(offset)
    } catch (err) {
      const msg = await handleRpcError(err, 'resolve_moderation')
      setErrorMsg(msg)
    } finally {
      setSubmitting(false)
    }
  }

  const detailContent = detail?.reported_content
  const detailTargetType =
    detailContent?.target_type ??
    (detail?.target_checkin_id
      ? 'checkin'
      : detail?.target_message_id
        ? 'message'
        : 'user')

  const detailHasMedia =
    detailContent?.target_type === 'checkin'
      ? Boolean(
          detailContent.has_photo ||
            detailContent.has_partner_photo ||
            detailContent.has_thumb,
        )
      : detailContent?.target_type === 'message'
        ? Boolean(detailContent.has_media)
        : false

  const detailTextExcerpt =
    detailContent?.target_type === 'checkin'
      ? detailContent.caption
      : detailContent?.target_type === 'message'
        ? detailContent.body
        : detail?.note ?? null

  const canQuarantine = Boolean(
    detail && (detail.target_checkin_id || detail.target_message_id),
  )

  const formatUserHandle = (
    username: string | null | undefined,
    fallbackId: string | null | undefined,
  ) => {
    if (username) return `@${username}`
    if (fallbackId) return fallbackId.slice(0, 8)
    return t('[Đã xóa]', '[Deleted]')
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
      <div className="page-header">
        <div>
          <h1 className="page-title">
            {t(
              'Hàng đợi Kiểm duyệt UGC (Cam kết SLA 24 Giờ)',
              'UGC Moderation Queue (24-Hour SLA)',
            )}
          </h1>
          <p className="page-subtitle">
            {t(
              'Tuân thủ Apple Guideline 1.2 & Google Play UGC: chỉ xem đúng nội dung bị báo cáo, giải trình mở khóa ảnh 5 phút.',
              'Apple Guideline 1.2 & Google Play UGC compliant triage: strictly scoped to reported items with 5m audited media grants.',
            )}
          </p>
        </div>
      </div>

      <div className="kpi-grid">
        <div className="kpi-card">
          <span className="kpi-label">{t('Đang mở', 'Open Reports')}</span>
          <div className="kpi-value">{summary?.open_reports ?? 0}</div>
          <div className="kpi-sub">
            <span>
              {summary?.open_blocks ?? 0} {t('tín hiệu chặn', 'open blocks')}
            </span>
          </div>
        </div>
        <div className="kpi-card">
          <span className="kpi-label">
            {t('Quá hạn (> 24h)', 'Overdue (> 24h)')}
          </span>
          <div className="kpi-value">{summary?.overdue_count ?? 0}</div>
        </div>
        <div className="kpi-card">
          <span className="kpi-label">
            {t('Sắp đến hạn (< 4h)', 'Due < 4h')}
          </span>
          <div className="kpi-value">{summary?.due_soon_count ?? 0}</div>
        </div>
        <div className="kpi-card">
          <span className="kpi-label">
            {t('Đã tạm ẩn (Quarantined)', 'Auto-Quarantined')}
          </span>
          <div className="kpi-value">{summary?.quarantined_count ?? 0}</div>
          <div className="kpi-sub">
            <span>
              {t('Thời gian xử lý trung vị 30d:', 'Median handle 30d:')}{' '}
              {Number(summary?.median_handle_hours_30d ?? 0).toFixed(2)}h
            </span>
          </div>
        </div>
      </div>

      {errorMsg && (
        <div className="status-banner error" role="alert">
          <span>{errorMsg}</span>
        </div>
      )}

      {bannerMsg && (
        <div className="status-banner success" role="status">
          <span>{bannerMsg}</span>
        </div>
      )}

      <div className="filter-bar">
        <select
          aria-label={t('Trạng thái hàng đợi', 'Queue status')}
          className="select"
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
        >
          <option value="open">{t('Đang mở (Open)', 'Open')}</option>
          <option value="overdue">{t('Quá hạn (Overdue)', 'Overdue')}</option>
          <option value="quarantined">
            {t('Đang tạm ẩn (Quarantined)', 'Quarantined')}
          </option>
          <option value="actioned">
            {t('Đã xử phạt (Actioned)', 'Actioned')}
          </option>
          <option value="dismissed">
            {t('Đã bác bỏ (Dismissed)', 'Dismissed')}
          </option>
          <option value="all">{t('Tất cả', 'All')}</option>
        </select>

        <select
          aria-label={t('Loại tín hiệu', 'Signal kind')}
          className="select"
          value={kindFilter}
          onChange={(e) => setKindFilter(e.target.value)}
        >
          <option value="all">{t('Tất cả loại', 'All kinds')}</option>
          <option value="report">{t('Báo cáo (Report)', 'Report')}</option>
          <option value="block">{t('Chặn (Block signal)', 'Block')}</option>
        </select>

        <select
          aria-label={t('Lý do báo cáo', 'Report reason')}
          className="select"
          value={reasonFilter}
          onChange={(e) => setReasonFilter(e.target.value)}
        >
          <option value="all">{t('Mọi lý do', 'All reasons')}</option>
          <option value="nudity">Nudity / NSFW</option>
          <option value="self_harm">Self Harm</option>
          <option value="harassment">Harassment</option>
          <option value="spam">Spam</option>
          <option value="other">Other</option>
        </select>
      </div>

      <div className="split-pane">
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>SLA 24h</th>
                  <th>{t('Lý do & Loại', 'Reason & Kind')}</th>
                  <th>{t('Đối tượng', 'Target')}</th>
                  <th>{t('Người báo cáo', 'Reporters')}</th>
                </tr>
              </thead>
              <tbody>
                {rows.length === 0 && !loading ? (
                  <tr>
                    <td colSpan={4} style={{ textAlign: 'center', padding: 28 }}>
                      {t(
                        'Không có báo cáo nào trong bộ lọc này.',
                        'No moderation queue items match this filter.',
                      )}
                    </td>
                  </tr>
                ) : (
                  rows.map((r) => {
                    const sla = formatSlaBadge(r, t)
                    const reasonLabel =
                      r.reason ??
                      (r.kind === 'block' ? 'user_block' : 'unspecified')
                    const isSelected = selectedId === r.id
                    return (
                      <tr
                        key={r.id}
                        tabIndex={0}
                        aria-selected={isSelected}
                        className={`clickable-row ${
                          isSelected ? 'selected-row' : ''
                        }`}
                        onClick={() => setSelectedId(r.id)}
                        onKeyDown={(e) => {
                          if (e.key === 'Enter' || e.key === ' ') {
                            e.preventDefault()
                            setSelectedId(r.id)
                          }
                        }}
                      >
                        <td>
                          <span className={`badge ${sla.tone} tabular`}>
                            {sla.text}
                          </span>
                        </td>
                        <td>
                          <div style={{ fontWeight: 700 }}>
                            {r.kind.toUpperCase()} · {reasonLabel}
                          </div>
                          {r.auto_quarantined && (
                            <span className="badge badge-purple">
                              Quarantined
                            </span>
                          )}
                        </td>
                        <td>
                          <div style={{ fontWeight: 700 }}>
                            {formatUserHandle(
                              r.target_username,
                              r.target_user_id,
                            )}
                          </div>
                          <div
                            style={{ fontSize: '0.78rem', color: 'var(--muted)' }}
                          >
                            {r.target_type} · {r.target_prior_actions}{' '}
                            {t('lần vi phạm trước', 'prior actions')} ·{' '}
                            {t('bị chặn bởi', 'blocked by')}{' '}
                            {r.target_blocked_by_count}
                          </div>
                        </td>
                        <td className="tabular">
                          {r.distinct_open_reporters} (
                          {formatUserHandle(r.actor_username, r.actor_id)})
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
              void loadQueue(next)
            }}
          />
        </div>

        <div className="card">
          {!detail ? (
            <p className="page-subtitle">
              {t(
                'Chọn một mục bên trái để kiểm tra chi tiết (mọi thao tác mở xem đều ghi nhật ký moderation.view_item).',
                'Select an item on the left to inspect (opening logs moderation.view_item).',
              )}
            </p>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
              <div className="kpi-top">
                <div>
                  <h3>
                    {formatUserHandle(
                      detail.target_user?.username,
                      detail.target_user?.user_id ?? detail.target_user_id,
                    )}{' '}
                    ({detailTargetType})
                  </h3>
                  <p className="kpi-label">
                    {t('Số lần bị xử lý trước đó:', 'Prior actioned reports:')}{' '}
                    {detail.target_user?.prior_actioned_reports ?? 0} ·{' '}
                    {t('Bị chặn bởi:', 'Blocked by:')}{' '}
                    {detail.target_user?.blocked_by_count ?? 0}
                  </p>
                </div>
                <span className="badge badge-warn">
                  {detail.reason ??
                    (detail.kind === 'block' ? 'user_block' : 'unspecified')}
                </span>
              </div>

              <div className="card-subtle">
                <div className="field-label" style={{ marginBottom: 6 }}>
                  {t(
                    'Nội dung văn bản bị báo cáo (Phạm vi hẹp — không hiển thị tin nhắn xung quanh)',
                    'Reported Text Excerpt (Strictly Scoped — zero surrounding chat messages)',
                  )}
                </div>
                <p style={{ marginTop: 4 }}>
                  {detailTextExcerpt ||
                    t('[Không có văn bản]', '[No text caption]')}
                </p>
              </div>

              {detailHasMedia && detail.status === 'open' && (
                <div className="media-vault-box">
                  <div className="kpi-top">
                    <div
                      style={{ display: 'flex', alignItems: 'center', gap: 8 }}
                    >
                      <OIcon name="lock" size={18} />
                      <strong>
                        {t(
                          'Ảnh bị báo cáo được khóa mặc định',
                          'Reported Media Hidden by Default',
                        )}
                      </strong>
                    </div>
                    {revealedObjects.length > 0 && (
                      <button
                        type="button"
                        className="btn"
                        onClick={() => setUnblurred((prev) => !prev)}
                      >
                        <OIcon
                          name={unblurred ? 'eye-off' : 'eye'}
                          size={18}
                        />
                        <span>
                          {unblurred
                            ? t('Làm mờ lại (Blur)', 'Blur Image')
                            : t('Bỏ làm mờ (Unblur)', 'Unblur Image')}
                        </span>
                      </button>
                    )}
                  </div>

                  {revealedObjects.length === 0 ? (
                    <div
                      style={{
                        display: 'flex',
                        flexDirection: 'column',
                        gap: 10,
                      }}
                    >
                      <p style={{ fontSize: '0.84rem', color: 'var(--muted)' }}>
                        {t(
                          'Bấm nút bên dưới để cấp quyền truy cập tạm thời 5 phút và ghi vào private.admin_audit.',
                          'Click below to mint an audited 5-minute scoped storage grant.',
                        )}
                      </p>
                      <button
                        type="button"
                        className="btn btn-warn"
                        onClick={() => void handleRevealMedia()}
                        disabled={revealing}
                      >
                        <OIcon name="eye" size={18} />
                        <span>
                          {revealing
                            ? t('Đang cấp quyền...', 'Minting grant...')
                            : t(
                                'Mở khóa ảnh bị báo cáo (Ghi nhật ký, 5 phút)',
                                'Reveal Reported Media (Audited, 5m TTL)',
                              )}
                        </span>
                      </button>
                    </div>
                  ) : (
                    <div className="revealed-media-grid">
                      {revealedObjects.map((obj) => (
                        <div
                          key={`${obj.bucket}:${obj.path}`}
                          className="revealed-image-frame"
                        >
                          {obj.signed_url && (
                            <img
                              src={obj.signed_url}
                              alt={`Reported media ${obj.path}`}
                              className={unblurred ? '' : 'blurred'}
                            />
                          )}
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}

              <div>
                <div className="field-label" style={{ marginBottom: 8 }}>
                  {t(
                    `Danh sách báo cáo cùng mục tiêu (${detail.sibling_reports.length})`,
                    `Sibling Reports (${detail.sibling_reports.length})`,
                  )}
                </div>
                <div style={{ display: 'grid', gap: 8 }}>
                  {detail.sibling_reports.map((rep) => (
                    <div key={rep.id} className="card-subtle">
                      <div style={{ fontWeight: 700, fontSize: '0.84rem' }}>
                        {formatUserHandle(
                          rep.reporter_username,
                          rep.reporter_id,
                        )}{' '}
                        · {rep.reason ?? 'report'}
                      </div>
                      {rep.note && (
                        <div style={{ fontSize: '0.84rem', marginTop: 4 }}>
                          {rep.note}
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              </div>

              <div
                style={{
                  display: 'flex',
                  flexWrap: 'wrap',
                  gap: 10,
                  paddingTop: 8,
                  borderTop: '2px dashed var(--border)',
                }}
              >
                <button
                  type="button"
                  className="btn btn-success"
                  onClick={() => setModalAction('dismiss')}
                >
                  <OIcon name="check" size={18} />
                  <span>{t('Bác bỏ báo cáo (Dismiss)', 'Dismiss Report')}</span>
                </button>

                {canQuarantine && (
                  <button
                    type="button"
                    className="btn btn-warn"
                    onClick={() => setModalAction('quarantine')}
                  >
                    <OIcon name="eye-off" size={18} />
                    <span>
                      {t('Tạm ẩn điều tra (Quarantine)', 'Quarantine Target')}
                    </span>
                  </button>
                )}

                <button
                  type="button"
                  className="btn btn-primary"
                  onClick={() => setModalAction('remove_content')}
                >
                  <OIcon name="trash" size={18} />
                  <span>
                    {t('Gỡ bỏ nội dung (Remove Content)', 'Remove Content')}
                  </span>
                </button>

                <button
                  type="button"
                  className="btn btn-danger"
                  onClick={() => setModalAction('ban_user')}
                >
                  <OIcon name="ban" size={18} />
                  <span>
                    {t(
                      'Khóa tài khoản & Xóa UGC (Ban User)',
                      'Ban User & Wipe Content',
                    )}
                  </span>
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {modalAction && (
        <AccessibleModal
          title={`${t('Xác nhận quyết định kiểm duyệt', 'Confirm Moderation Action')}: ${modalAction}`}
          onClose={() => setModalAction(null)}
        >
          <h3>
            {t('Xác nhận quyết định kiểm duyệt', 'Confirm Moderation Action')}:{' '}
            {modalAction}
          </h3>
          <p className="page-subtitle">
            {t(
              'Quyết định này sẽ được ghi bất biến vào private.admin_audit kèm theo ghi chú giải trình.',
              'This decision is immutably recorded in private.admin_audit with your resolution note.',
            )}
          </p>
          <label className="field-group">
            <span className="field-label">
              {t('Ghi chú giải trình (Resolution Note)', 'Resolution Note')}
            </span>
            <textarea
              className="textarea"
              placeholder={t(
                'Nhập lý do xử lý để lưu bằng chứng SLA 24h...',
                'Enter resolution reason for 24h SLA audit trail...',
              )}
              value={resolutionNote}
              onChange={(e) => setResolutionNote(e.target.value)}
            />
          </label>
          <div
            style={{
              display: 'flex',
              justifyContent: 'flex-end',
              gap: 10,
            }}
          >
            <button
              type="button"
              className="btn"
              onClick={() => setModalAction(null)}
            >
              {t('Hủy', 'Cancel')}
            </button>
            <button
              type="button"
              className="btn btn-primary"
              onClick={() => void handleConfirmResolution()}
              disabled={submitting}
            >
              {t('Xác nhận thực thi', 'Confirm Action')}
            </button>
          </div>
        </AccessibleModal>
      )}
    </div>
  )
}
