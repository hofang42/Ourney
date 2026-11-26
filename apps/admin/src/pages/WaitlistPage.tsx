import { useEffect, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import {
  adminApi,
  handleRpcError,
  type AdminIdentity,
  type WaitlistResendResponse,
  type WaitlistRow,
  type WaitlistSummary,
} from '../lib/adminRpc'
import {
  buildWaitlistCsv,
  sanitizeRawCsvString,
  triggerCsvDownload,
} from '../lib/csv'
import {
  fmtDateTime,
  formatAdminError,
  formatPlatformLabel,
  formatTechnicalDiagnostic,
  formatWaitlistSource,
  formatWordLang,
  useI18n,
} from '../lib/i18n'
import { OIcon } from '../ui/Icon'
import { AccessibleModal, PaginationBar } from '../ui/Modal'

const PAGE_LIMIT = 50

export function WaitlistPage({ admin }: { admin: AdminIdentity }) {
  const { lang, t } = useI18n()
  const [searchParams] = useSearchParams()
  const [search, setSearch] = useState('')
  const [langFilter, setLangFilter] = useState('all')
  const [platformFilter, setPlatformFilter] = useState('all')
  const [mailFilter, setMailFilter] = useState(
    searchParams.get('mail_status') || 'all',
  )
  const [convertedFilter, setConvertedFilter] = useState('all')
  const [offset, setOffset] = useState(0)

  const [summary, setSummary] = useState<WaitlistSummary | null>(null)
  const [total, setTotal] = useState(0)
  const [rows, setRows] = useState<WaitlistRow[]>([])
  const [statusMsg, setStatusMsg] = useState<string | null>(null)
  const [warnMsg, setWarnMsg] = useState<string | null>(null)
  const [errorMsg, setErrorMsg] = useState<string | null>(null)
  const [failedRows, setFailedRows] = useState<Record<string, string>>({})
  const [resendingId, setResendingId] = useState<string | null>(null)
  const [bulkRetrying, setBulkRetrying] = useState(false)
  const [loading, setLoading] = useState(true)
  const [deleting, setDeleting] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState<WaitlistRow | null>(null)
  const [deleteReason, setDeleteReason] = useState('')

  const loadData = async (nextOffset = offset) => {
    setLoading(true)
    try {
      const [sum, listRes] = await Promise.all([
        adminApi.waitlistSummary(30),
        adminApi.listWaitlist({
          p_search: search,
          p_lang: langFilter,
          p_platform: platformFilter,
          p_mail_status: mailFilter,
          p_converted: convertedFilter,
          p_limit: PAGE_LIMIT,
          p_offset: nextOffset,
        }),
      ])
      setSummary(sum)
      setTotal(listRes.total)
      setRows(listRes.items)
    } catch (err) {
      const msg = await handleRpcError(err, 'list_waitlist', lang)
      setErrorMsg(msg)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    setOffset(0)
    setErrorMsg(null)
    void loadData(0)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search, langFilter, platformFilter, mailFilter, convertedFilter])

  const handleExportCsv = async () => {
    setErrorMsg(null)
    try {
      const exported = await adminApi.exportWaitlist({
        p_search: search,
        p_lang: langFilter,
        p_platform: platformFilter,
        p_mail_status: mailFilter,
        p_converted: convertedFilter,
      })
      const csv =
        typeof exported === 'string'
          ? sanitizeRawCsvString(exported)
          : buildWaitlistCsv(exported)
      triggerCsvDownload(csv, 'ourney-waitlist.csv')
      setStatusMsg(
        t(
          'Đã xuất tệp CSV danh sách chờ (UTF-8 BOM, đã ghi nhật ký kiểm toán).',
          'Exported waitlist to UTF-8 BOM CSV (recorded in audit log).',
        ),
      )
    } catch (err) {
      const msg = await handleRpcError(err, 'export_waitlist', lang)
      setErrorMsg(msg)
    }
  }

  const handleResendRow = async (id: string) => {
    if (resendingId || bulkRetrying) return
    setResendingId(id)
    setErrorMsg(null)
    setWarnMsg(null)
    setStatusMsg(null)
    try {
      const res = await adminApi.invokeAdminAction<WaitlistResendResponse>({
        action: 'waitlist_resend',
        waitlist_id: id,
      })
      const hasCounts =
        typeof res?.sent === 'number' || typeof res?.failed === 'number'
      const failed = typeof res?.failed === 'number' ? res.failed : 0
      const sent =
        typeof res?.sent === 'number'
          ? res.sent
          : hasCounts
            ? 0
            : failed > 0
              ? 0
              : 1
      const errs = Array.isArray(res?.errors) ? res.errors : []

      if (failed > 0 || sent === 0) {
        const rawErr = errs[0]?.error || 'resend_failed'
        console.debug('[OurneyAdmin Resend Error]', id, rawErr)
        const mappedReason = formatAdminError(rawErr, lang)
        setFailedRows((prev) => ({
          ...prev,
          [id]: rawErr,
        }))
        setErrorMsg(
          t(
            `Không gửi được email xác nhận (Đã gửi ${sent}, lỗi ${failed}): ${mappedReason}`,
            `Failed to send confirmation email (Sent ${sent}, failed ${failed}): ${mappedReason}`,
          ),
        )
      } else {
        setFailedRows((prev) => {
          const next = { ...prev }
          delete next[id]
          return next
        })
        setStatusMsg(
          t(
            `Đã gửi lại email xác nhận thành công (Đã gửi ${sent}, lỗi 0).`,
            `Re-sent confirmation email via Resend (Sent ${sent}, failed 0).`,
          ),
        )
      }
      await loadData(offset)
    } catch (err) {
      const msg = await handleRpcError(err, 'waitlist_resend', lang)
      const rawText =
        err instanceof Error
          ? err.message
          : typeof err === 'string'
            ? err
            : msg
      setFailedRows((prev) => ({ ...prev, [id]: rawText }))
      setErrorMsg(msg)
    } finally {
      setResendingId(null)
    }
  }

  const handleBulkRetryFailed = async () => {
    if (bulkRetrying || resendingId) return
    setBulkRetrying(true)
    setErrorMsg(null)
    setWarnMsg(null)
    setStatusMsg(null)
    try {
      const res = await adminApi.invokeAdminAction<WaitlistResendResponse>({
        action: 'waitlist_resend_failed',
        limit: 25,
      })
      const hasCounts =
        typeof res?.sent === 'number' || typeof res?.failed === 'number'
      const failed = typeof res?.failed === 'number' ? res.failed : 0
      const sent =
        typeof res?.sent === 'number'
          ? res.sent
          : hasCounts
            ? 0
            : failed > 0
              ? 0
              : 1
      const errs = Array.isArray(res?.errors) ? res.errors : []

      const nextFailed: Record<string, string> = {}
      const distinctReasons = new Set<string>()
      for (const item of errs) {
        if (item && item.id) {
          const rawItemErr = item.error || 'resend_failed'
          nextFailed[item.id] = rawItemErr
          distinctReasons.add(formatAdminError(rawItemErr, lang))
        }
      }
      if (errs.length > 0) {
        console.debug('[OurneyAdmin Bulk Resend Errors]', errs)
      }
      setFailedRows(nextFailed)

      if (failed > 0) {
        const firstReason = formatAdminError(
          errs[0]?.error || 'resend_failed',
          lang,
        )
        const multiSuffix =
          distinctReasons.size > 1
            ? t(
                ' (Xem lý do chi tiết từng dòng trong bảng bên dưới).',
                ' (See per-row reasons in the table below).',
              )
            : ''
        const message = t(
          `Gửi lại hàng loạt có lỗi: Đã gửi ${sent}, lỗi ${failed}. Lý do: ${firstReason}${multiSuffix}`,
          `Bulk retry finished with errors: Sent ${sent}, failed ${failed}. Reason: ${firstReason}${multiSuffix}`,
        )
        if (sent > 0) {
          setWarnMsg(message)
        } else {
          setErrorMsg(message)
        }
      } else if (hasCounts && sent === 0) {
        setStatusMsg(
          t(
            'Không có email lỗi nào cần gửi lại (Đã gửi 0, lỗi 0).',
            'No failed emails needed retrying (Sent 0, failed 0).',
          ),
        )
      } else {
        setStatusMsg(
          t(
            `Đã gửi lại thành công ${sent} email xác nhận (Đã gửi ${sent}, lỗi 0).`,
            `Triggered bulk retry: Sent ${sent}, failed 0.`,
          ),
        )
      }
      await loadData(offset)
    } catch (err) {
      const msg = await handleRpcError(err, 'waitlist_resend_failed', lang)
      setErrorMsg(msg)
    } finally {
      setBulkRetrying(false)
    }
  }

  const handleConfirmDelete = async () => {
    if (!deleteTarget || deleting) return
    setDeleting(true)
    setErrorMsg(null)
    try {
      await adminApi.deleteWaitlistEntry(
        deleteTarget.id,
        deleteReason.trim() || 'Removed by owner on request',
      )
      setStatusMsg(
        t(
          'Đã xóa mục danh sách chờ (email đã được ẩn danh trong nhật ký kiểm toán).',
          'Deleted waitlist entry (email anonymized in audit log).',
        ),
      )
      setDeleteTarget(null)
      setDeleteReason('')
      await loadData(offset)
    } catch (err) {
      const msg = await handleRpcError(err, 'delete_waitlist_entry', lang)
      setErrorMsg(msg)
    } finally {
      setDeleting(false)
    }
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
      <div className="page-header">
        <div>
          <h1 className="page-title">
            {t('Quản lý Danh sách chờ Beta', 'Beta Waitlist Operations')}
          </h1>
          <p className="page-subtitle">
            {t(
              'Phân tích nền tảng iOS/Android, ngôn ngữ VI/EN, xuất CSV và gửi lại email xác nhận cho các mục bị lỗi.',
              'Segment iOS/Android and VI/EN signups, export UTF-8 BOM CSV, and retry failed confirmation emails.',
            )}
          </p>
        </div>

        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
          <button
            type="button"
            className="btn btn-warn"
            disabled={bulkRetrying || resendingId !== null}
            onClick={() => void handleBulkRetryFailed()}
          >
            <OIcon name="refresh" size={18} />
            <span>
              {t('Gửi lại hàng loạt email lỗi', 'Bulk Retry Failed Emails')}
            </span>
          </button>

          {admin.role === 'owner' && (
            <button
              type="button"
              className="btn btn-primary"
              onClick={() => void handleExportCsv()}
            >
              <OIcon name="download" size={18} />
              <span>{t('Xuất CSV (UTF-8 BOM)', 'Export CSV')}</span>
            </button>
          )}
        </div>
      </div>

      {errorMsg && !deleteTarget && (
        <div className="status-banner error" role="alert">
          <span>{errorMsg}</span>
        </div>
      )}

      {warnMsg && (
        <div className="status-banner warn" role="alert">
          <span>{warnMsg}</span>
        </div>
      )}

      {statusMsg && (
        <div className="status-banner success" role="status">
          <span>{statusMsg}</span>
        </div>
      )}

      {summary && (
        <div className="kpi-grid">
          <div className="kpi-card">
            <span className="kpi-label">
              {t('Tổng đăng ký', 'Total Signups')}
            </span>
            <div className="kpi-value">{summary.total}</div>
            <div className="kpi-sub">
              <span className="badge badge-primary">
                +{summary.new_7d} ({t('7 ngày', '7d')})
              </span>
              <span>VI: {summary.lang_vi}</span>
              <span>EN: {summary.lang_en}</span>
            </div>
          </div>

          <div className="kpi-card">
            <span className="kpi-label">
              {t('Phân bổ thiết bị', 'Platform Split')}
            </span>
            <div className="kpi-value">
              iOS {summary.ios_only} / Android {summary.android_only}
            </div>
            <div className="kpi-sub">
              <span>
                {t('Cả hai:', 'Both:')} {summary.both_platforms}
              </span>
            </div>
          </div>

          <div className="kpi-card">
            <span className="kpi-label">
              {t('Trạng thái Email xác nhận', 'Confirmation Emails')}
            </span>
            <div className="kpi-value">{summary.mail_sent}</div>
            <div className="kpi-sub">
              <span className="badge badge-danger">
                {t('Lỗi:', 'Failed:')} {summary.mail_failed}
              </span>
              <span>
                {t('Chờ:', 'Pending:')} {summary.mail_unsent}
              </span>
            </div>
          </div>

          <div className="kpi-card">
            <span className="kpi-label">
              {t('Đã tạo tài khoản App', 'Converted to App')}
            </span>
            <div className="kpi-value">{summary.converted_count}</div>
            <div className="kpi-sub">
              <span>
                {t('Đang chờ:', 'Waiting:')} {summary.waiting_count}
              </span>
              {summary.by_source.slice(0, 2).map((s) => (
                <span key={s.source} className="badge">
                  {formatWaitlistSource(s.source, lang)}: {s.count}
                </span>
              ))}
            </div>
          </div>
        </div>
      )}

      <div className="filter-bar">
        <input
          type="search"
          className="input search-input"
          aria-label={t(
            'Tìm kiếm email hoặc nguồn danh sách chờ',
            'Search waitlist email or source',
          )}
          placeholder={t(
            'Tìm email hoặc nguồn đăng ký...',
            'Search email or source...',
          )}
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />

        <select
          aria-label={t('Lọc nền tảng', 'Filter platform')}
          className="select"
          value={platformFilter}
          onChange={(e) => setPlatformFilter(e.target.value)}
        >
          <option value="all">{t('Mọi nền tảng', 'All platforms')}</option>
          <option value="ios">iOS</option>
          <option value="android">Android</option>
        </select>

        <select
          aria-label={t('Lọc ngôn ngữ', 'Filter language')}
          className="select"
          value={langFilter}
          onChange={(e) => setLangFilter(e.target.value)}
        >
          <option value="all">{t('Mọi ngôn ngữ', 'All languages')}</option>
          <option value="vi">{formatWordLang('vi', lang)}</option>
          <option value="en">{formatWordLang('en', lang)}</option>
        </select>

        <select
          aria-label={t('Trạng thái gửi email', 'Filter mail status')}
          className="select"
          value={mailFilter}
          onChange={(e) => setMailFilter(e.target.value)}
        >
          <option value="all">
            {t('Mọi trạng thái email', 'All mail status')}
          </option>
          <option value="sent">{t('Đã gửi', 'Sent')}</option>
          <option value="failed">{t('Gửi lỗi', 'Failed')}</option>
          <option value="unsent">{t('Chưa gửi', 'Unsent')}</option>
        </select>

        <select
          aria-label={t('Trạng thái chuyển đổi', 'Filter converted')}
          className="select"
          value={convertedFilter}
          onChange={(e) => setConvertedFilter(e.target.value)}
        >
          <option value="all">
            {t('Mọi trạng thái App', 'All conversion')}
          </option>
          <option value="registered">
            {t('Đã đăng ký App', 'Registered')}
          </option>
          <option value="waiting">{t('Đang chờ', 'Waiting')}</option>
        </select>
      </div>

      <div className="table-wrap">
        <table className="data-table">
          <thead>
            <tr>
              <th>Email</th>
              <th>{t('Ngôn ngữ', 'Lang')}</th>
              <th>{t('Nền tảng', 'Platforms')}</th>
              <th>{t('Nguồn', 'Source')}</th>
              <th>{t('Trạng thái Email', 'Mail Status')}</th>
              <th>{t('Tài khoản App', 'App Account')}</th>
              <th>{t('Thao tác', 'Actions')}</th>
            </tr>
          </thead>
          <tbody>
            {loading && rows.length === 0 ? (
              <tr>
                <td colSpan={7} style={{ textAlign: 'center', padding: 28 }}>
                  {t(
                    'Đang tải danh sách chờ...',
                    'Loading waitlist entries...',
                  )}
                </td>
              </tr>
            ) : rows.length === 0 ? (
              <tr>
                <td colSpan={7} style={{ textAlign: 'center', padding: 28 }}>
                  {t(
                    'Không tìm thấy mục danh sách chờ nào khớp với bộ lọc.',
                    'No waitlist entries match the current filters.',
                  )}
                </td>
              </tr>
            ) : (
              rows.map((r) => {
              const isRowHighlightedFailed = Boolean(failedRows[r.id])
              const rawRowError =
                failedRows[r.id] || r.confirmation_error || null
              const rowErrorText = rawRowError
                ? formatAdminError(rawRowError, lang)
                : null
              const rowTechDiagnostic =
                admin.role === 'owner' && rawRowError
                  ? formatTechnicalDiagnostic(rawRowError)
                  : null
              const isSent =
                !rowErrorText &&
                (r.mail_status === 'sent' ||
                  Boolean(r.confirmation_sent_at && !r.confirmation_error))
              const canResend = !r.registered_in_app && !isSent

              return (
                <tr
                  key={r.id}
                  className={isRowHighlightedFailed ? 'failed-row' : undefined}
                  data-failed={isRowHighlightedFailed ? 'true' : undefined}
                >
                  <td style={{ fontWeight: 700 }}>
                    <div>{r.email}</div>
                    <div
                      className="tabular"
                      style={{ fontSize: '0.75rem', color: 'var(--muted)' }}
                    >
                      {fmtDateTime(r.created_at, lang)}
                    </div>
                  </td>
                  <td>
                    <span className="badge">{formatWordLang(r.lang, lang)}</span>
                  </td>
                  <td>
                    {r.platforms.map((p) => formatPlatformLabel(p)).join(', ')}
                  </td>
                  <td>{formatWaitlistSource(r.source, lang)}</td>
                  <td>
                    {rowErrorText ? (
                      <div
                        style={{
                          display: 'flex',
                          flexDirection: 'column',
                          gap: 4,
                        }}
                      >
                        <span className="badge badge-danger">
                          {t('Gửi lỗi', 'Failed')}: {rowErrorText}
                        </span>
                        {rowTechDiagnostic && (
                          <details style={{ fontSize: '0.75rem' }}>
                            <summary style={{ cursor: 'pointer' }}>
                              {t('Chi tiết kỹ thuật', 'Technical details')}
                            </summary>
                            <code>{rowTechDiagnostic}</code>
                          </details>
                        )}
                      </div>
                    ) : isSent ? (
                      <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                        <span className="badge badge-success">
                          {t('Đã gửi', 'Sent')}
                        </span>
                        {r.confirmation_sent_at && (
                          <span
                            className="tabular"
                            style={{ fontSize: '0.72rem', color: 'var(--muted)' }}
                          >
                            {fmtDateTime(r.confirmation_sent_at, lang)}
                          </span>
                        )}
                      </div>
                    ) : (
                      <span className="badge badge-warn">
                        {t('Chờ gửi', 'Pending')}
                      </span>
                    )}
                  </td>
                  <td>
                    {r.registered_in_app ? (
                      <span className="badge badge-primary">
                        {t('Đã đăng ký App', 'Registered')}
                      </span>
                    ) : (
                      <span className="badge">{t('Đang chờ', 'Waiting')}</span>
                    )}
                  </td>
                  <td>
                    <div style={{ display: 'flex', gap: 8 }}>
                      {canResend && (
                        <button
                          type="button"
                          className="btn"
                          disabled={resendingId === r.id || bulkRetrying}
                          aria-label={`${t('Gửi lại', 'Resend')} ${r.email}`}
                          onClick={() => void handleResendRow(r.id)}
                        >
                          <OIcon name="paper-plane" size={16} />
                          <span>{t('Gửi lại', 'Resend')}</span>
                        </button>
                      )}
                      {admin.role === 'owner' && (
                        <button
                          type="button"
                          className="btn btn-danger"
                          disabled={deleting}
                          aria-label={`${t('Xóa', 'Delete')} ${r.email}`}
                          onClick={() => {
                            setErrorMsg(null)
                            setDeleteTarget(r)
                          }}
                        >
                          <OIcon name="trash" size={16} />
                          <span>{t('Xóa', 'Delete')}</span>
                        </button>
                      )}
                    </div>
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

      {deleteTarget && (
        <AccessibleModal
          title={t(
            'Xác nhận xóa khỏi Danh sách chờ',
            'Confirm Waitlist Deletion',
          )}
          onClose={() => {
            if (deleting) return
            setDeleteTarget(null)
            setDeleteReason('')
            setErrorMsg(null)
          }}
        >
          <h3>
            {t('Xác nhận xóa khỏi Danh sách chờ', 'Confirm Waitlist Deletion')}
          </h3>
          {errorMsg && (
            <div className="status-banner error" role="alert">
              <span>{errorMsg}</span>
            </div>
          )}
          <p className="page-subtitle">
            {deleteTarget.email} —{' '}
            {t(
              'Nhật ký kiểm toán sẽ chỉ lưu mã ẩn danh để tôn trọng quyền xóa dữ liệu của người dùng.',
              'The audit log stores only an anonymized email digest to respect privacy erasure.',
            )}
          </p>
          <label className="field-group">
            <span className="field-label">
              {t('Lý do xóa', 'Deletion Reason')}
            </span>
            <input
              type="text"
              className="input"
              value={deleteReason}
              onChange={(e) => setDeleteReason(e.target.value)}
              placeholder={t(
                'Email thử nghiệm hoặc người dùng yêu cầu hủy...',
                'Test entry or user unsubscribe request...',
              )}
            />
          </label>
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
            <button
              type="button"
              className="btn"
              disabled={deleting}
              onClick={() => {
                setDeleteTarget(null)
                setDeleteReason('')
                setErrorMsg(null)
              }}
            >
              {t('Hủy', 'Cancel')}
            </button>
            <button
              type="button"
              className="btn btn-danger"
              disabled={deleting}
              onClick={() => void handleConfirmDelete()}
            >
              {t('Xác nhận xóa', 'Confirm Delete')}
            </button>
          </div>
        </AccessibleModal>
      )}
    </div>
  )
}
