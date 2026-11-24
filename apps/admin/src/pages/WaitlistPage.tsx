import { useEffect, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import {
  adminApi,
  handleRpcError,
  type AdminIdentity,
  type WaitlistRow,
  type WaitlistSummary,
} from '../lib/adminRpc'
import {
  buildWaitlistCsv,
  sanitizeRawCsvString,
  triggerCsvDownload,
} from '../lib/csv'
import { useI18n } from '../lib/i18n'
import { OIcon } from '../ui/Icon'
import { AccessibleModal, PaginationBar } from '../ui/Modal'

const PAGE_LIMIT = 50

export function WaitlistPage({ admin }: { admin: AdminIdentity }) {
  const { t } = useI18n()
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
  const [errorMsg, setErrorMsg] = useState<string | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<WaitlistRow | null>(null)
  const [deleteReason, setDeleteReason] = useState('')

  const loadData = async (nextOffset = offset) => {
    setErrorMsg(null)
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
      const msg = await handleRpcError(err, 'list_waitlist')
      setErrorMsg(msg)
    }
  }

  useEffect(() => {
    setOffset(0)
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
          'Đã xuất tệp CSV danh sách chờ (UTF-8 BOM, đã ghi waitlist.export_csv).',
          'Exported waitlist to UTF-8 BOM CSV (logged waitlist.export_csv).',
        ),
      )
    } catch (err) {
      const msg = await handleRpcError(err, 'export_waitlist')
      setErrorMsg(msg)
    }
  }

  const handleResendRow = async (id: string) => {
    setErrorMsg(null)
    try {
      await adminApi.invokeAdminAction({
        action: 'waitlist_resend',
        waitlist_id: id,
      })
      setStatusMsg(
        t(
          'Đã gửi lại email xác nhận qua Resend.',
          'Re-sent confirmation email via Resend.',
        ),
      )
      await loadData(offset)
    } catch (err) {
      const msg = await handleRpcError(err, 'waitlist_resend')
      setErrorMsg(msg)
    }
  }

  const handleBulkRetryFailed = async () => {
    setErrorMsg(null)
    try {
      await adminApi.invokeAdminAction({
        action: 'waitlist_resend_failed',
        limit: 25,
      })
      setStatusMsg(
        t(
          'Đã kích hoạt gửi lại tối đa 25 email bị lỗi.',
          'Triggered bulk retry for up to 25 failed emails.',
        ),
      )
      await loadData(offset)
    } catch (err) {
      const msg = await handleRpcError(err, 'waitlist_resend_failed')
      setErrorMsg(msg)
    }
  }

  const handleConfirmDelete = async () => {
    if (!deleteTarget) return
    setErrorMsg(null)
    try {
      await adminApi.deleteWaitlistEntry(
        deleteTarget.id,
        deleteReason.trim() || 'Removed by owner on request',
      )
      setStatusMsg(
        t(
          'Đã xóa mục danh sách chờ (lưu mã băm sha256 trong nhật ký).',
          'Deleted waitlist entry (logged with sha256 email digest).',
        ),
      )
      setDeleteTarget(null)
      setDeleteReason('')
      await loadData(offset)
    } catch (err) {
      const msg = await handleRpcError(err, 'delete_waitlist_entry')
      setErrorMsg(msg)
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
              'Phân tích nền tảng iOS/Android, ngôn ngữ VI/EN, xuất CSV cho TestFlight/Play Testing và gửi lại email xác nhận Resend.',
              'Segment iOS/Android and VI/EN signups, export UTF-8 BOM CSV for TestFlight waves, and retry failed Resend confirmation emails.',
            )}
          </p>
        </div>

        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
          <button
            type="button"
            className="btn btn-warn"
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

      {errorMsg && (
        <div className="status-banner error" role="alert">
          <span>{errorMsg}</span>
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
                +{summary.new_7d} (7d)
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
              {t('Trạng thái Email Resend', 'Confirmation Emails')}
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
                  {s.source}: {s.count}
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
            'Tìm email hoặc nguồn (source)...',
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
          <option value="vi">VI</option>
          <option value="en">EN</option>
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
          <option value="sent">{t('Đã gửi (Sent)', 'Sent')}</option>
          <option value="failed">{t('Gửi lỗi (Failed)', 'Failed')}</option>
          <option value="unsent">{t('Chưa gửi (Unsent)', 'Unsent')}</option>
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
            {rows.map((r) => (
              <tr key={r.id}>
                <td style={{ fontWeight: 700 }}>{r.email}</td>
                <td>
                  <span className="badge">{r.lang.toUpperCase()}</span>
                </td>
                <td>{r.platforms.join(', ')}</td>
                <td>{r.source || 'landing'}</td>
                <td>
                  {r.confirmation_error ? (
                    <span className="badge badge-danger">
                      Failed: {r.confirmation_error}
                    </span>
                  ) : r.confirmation_sent_at ? (
                    <span className="badge badge-success">Sent</span>
                  ) : (
                    <span className="badge badge-warn">Pending</span>
                  )}
                </td>
                <td>
                  {r.registered_in_app ? (
                    <span className="badge badge-primary">Registered</span>
                  ) : (
                    <span className="badge">Waiting</span>
                  )}
                </td>
                <td>
                  <div style={{ display: 'flex', gap: 8 }}>
                    <button
                      type="button"
                      className="btn"
                      aria-label={`${t('Gửi lại', 'Resend')} ${r.email}`}
                      onClick={() => void handleResendRow(r.id)}
                    >
                      <OIcon name="paper-plane" size={16} />
                      <span>{t('Gửi lại', 'Resend')}</span>
                    </button>
                    {admin.role === 'owner' && (
                      <button
                        type="button"
                        className="btn btn-danger"
                        aria-label={`${t('Xóa', 'Delete')} ${r.email}`}
                        onClick={() => setDeleteTarget(r)}
                      >
                        <OIcon name="trash" size={16} />
                        <span>{t('Xóa', 'Delete')}</span>
                      </button>
                    )}
                  </div>
                </td>
              </tr>
            ))}
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
          onClose={() => setDeleteTarget(null)}
        >
          <h3>
            {t('Xác nhận xóa khỏi Danh sách chờ', 'Confirm Waitlist Deletion')}
          </h3>
          <p className="page-subtitle">
            {deleteTarget.email} —{' '}
            {t(
              'Nhật ký kiểm toán sẽ chỉ lưu mã băm sha256(email) để tôn trọng quyền xóa dữ liệu.',
              'Audit log stores only sha256(email) to respect privacy erasure.',
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
              onClick={() => setDeleteTarget(null)}
            >
              {t('Hủy', 'Cancel')}
            </button>
            <button
              type="button"
              className="btn btn-danger"
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
