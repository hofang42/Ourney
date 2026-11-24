import { useEffect, useState } from 'react'
import {
  adminApi,
  handleRpcError,
  type AuditLogRow,
} from '../lib/adminRpc'
import {
  fmtDateTime,
  formatAuditAction,
  formatTargetType,
  useI18n,
} from '../lib/i18n'
import { OIcon } from '../ui/Icon'

const AUDIT_TARGET_TYPES = [
  'moderation_queue',
  'checkin',
  'message',
  'feature_request',
  'user',
  'journey',
  'waitlist',
  'word',
  'admin',
  'system',
] as const

export function AuditPage() {
  const { lang, t } = useI18n()
  const [rows, setRows] = useState<AuditLogRow[]>([])
  const [actionPrefix, setActionPrefix] = useState('')
  const [targetType, setTargetType] = useState('all')
  const [targetId, setTargetId] = useState('')
  const [beforeId, setBeforeId] = useState<number | null>(null)
  const [nextBeforeId, setNextBeforeId] = useState<number | null>(null)
  const [copiedId, setCopiedId] = useState<number | null>(null)
  const [errorMsg, setErrorMsg] = useState<string | null>(null)

  const loadAudit = async (cursor: number | null = beforeId) => {
    setErrorMsg(null)
    try {
      const res = await adminApi.listAuditLog({
        p_action_prefix: actionPrefix,
        p_target_type: targetType,
        p_target_id: targetId,
        p_before_id: cursor,
        p_limit: 50,
      })
      setRows(res.items)
      setNextBeforeId(res.next_before_id)
    } catch (err) {
      const msg = await handleRpcError(err, 'list_audit_log', lang)
      setErrorMsg(msg)
    }
  }

  useEffect(() => {
    setBeforeId(null)
    void loadAudit(null)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [actionPrefix, targetType, targetId])

  const handleCopyJson = async (row: AuditLogRow) => {
    try {
      await navigator.clipboard.writeText(JSON.stringify(row, null, 2))
      setCopiedId(row.id)
    } catch {
      // Ignore clipboard failures in headless test environments
    }
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
      <div className="page-header">
        <div>
          <h1 className="page-title">
            {t('Nhật ký Kiểm toán Bất biến', 'Immutable Audit Log')}
          </h1>
          <p className="page-subtitle">
            {t(
              'Sổ cái chỉ-thêm ghi lại mọi thao tác thay đổi và mọi lần mở xem nội dung nhạy cảm (được bảo vệ chống chỉnh sửa hoặc xóa).',
              'Append-only ledger of every admin action and privacy-sensitive inspection (protected against modification or deletion).',
            )}
          </p>
        </div>
      </div>

      {errorMsg && (
        <div className="status-banner error" role="alert">
          <span>{errorMsg}</span>
        </div>
      )}

      <div className="filter-bar">
        <input
          type="search"
          className="input search-input"
          aria-label={t(
            'Lọc theo nhóm hành động kiểm toán',
            'Filter audit log by action prefix',
          )}
          placeholder={t(
            'Tìm theo nhóm hành động (kiểm duyệt, người dùng, đề xuất)...',
            'Filter by action group (moderation, users, feature requests)...',
          )}
          value={actionPrefix}
          onChange={(e) => setActionPrefix(e.target.value)}
        />

        <select
          aria-label={t('Loại đối tượng', 'Target type')}
          className="select"
          value={targetType}
          onChange={(e) => setTargetType(e.target.value)}
        >
          <option value="all">{t('Mọi đối tượng', 'All target types')}</option>
          {AUDIT_TARGET_TYPES.map((tt) => (
            <option key={tt} value={tt}>
              {formatTargetType(tt, lang)}
            </option>
          ))}
        </select>

        <input
          type="text"
          className="input"
          aria-label={t('Mã đối tượng đích chính xác', 'Exact target ID')}
          placeholder={t('Mã đối tượng chính xác...', 'Exact target ID...')}
          value={targetId}
          onChange={(e) => setTargetId(e.target.value)}
        />
      </div>

      <div className="table-wrap">
        <table className="data-table">
          <thead>
            <tr>
              <th>ID & {t('Thời gian', 'Timestamp')}</th>
              <th>{t('Quản trị viên', 'Admin')}</th>
              <th>{t('Hành động', 'Action')}</th>
              <th>{t('Đối tượng', 'Target')}</th>
              <th>{t('Lý do & Chi tiết', 'Reason & Details')}</th>
              <th>JSON</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.id}>
                <td className="tabular">
                  <div style={{ fontWeight: 700 }}>#{r.id}</div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--muted)' }}>
                    {fmtDateTime(r.created_at, lang)}
                  </div>
                </td>
                <td style={{ fontWeight: 700 }}>
                  {r.admin_email || t('Hệ thống', 'System')}
                </td>
                <td>
                  <span className="badge badge-primary">
                    {formatAuditAction(r.action, lang)}
                  </span>
                </td>
                <td>
                  <span className="badge">
                    {formatTargetType(r.target_type, lang)}
                  </span>{' '}
                  <span style={{ fontSize: '0.8rem' }}>{r.target_id}</span>
                </td>
                <td>
                  <div>{r.reason || '—'}</div>
                  <code
                    style={{
                      display: 'block',
                      fontSize: '0.75rem',
                      color: 'var(--muted)',
                      marginTop: 4,
                    }}
                  >
                    {JSON.stringify(r.meta)}
                  </code>
                </td>
                <td>
                  <button
                    type="button"
                    className="btn"
                    aria-label={`${t('Chép JSON', 'Copy JSON')} #${r.id}`}
                    onClick={() => void handleCopyJson(r)}
                  >
                    <OIcon name="copy" size={16} />
                    <span>
                      {copiedId === r.id
                        ? t('Đã chép', 'Copied')
                        : t('Chép JSON', 'Copy JSON')}
                    </span>
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {(beforeId !== null || nextBeforeId !== null) && (
        <div
          className="pagination-bar"
          role="navigation"
          aria-label={t('Phân trang nhật ký kiểm toán', 'Audit log pagination')}
        >
          <span
            className="tabular"
            style={{ fontWeight: 700, fontSize: '0.84rem' }}
          >
            {beforeId !== null
              ? t(
                  `Đang xem các mục trước ID #${beforeId}`,
                  `Viewing entries before ID #${beforeId}`,
                )
              : t('Đang xem các mục mới nhất', 'Viewing latest entries')}
          </span>
          <div style={{ display: 'flex', gap: 8 }}>
            {beforeId !== null && (
              <button
                type="button"
                className="btn"
                onClick={() => {
                  setBeforeId(null)
                  void loadAudit(null)
                }}
              >
                <OIcon name="back" size={16} />
                <span>{t('Về mới nhất', 'Latest Entries')}</span>
              </button>
            )}
            {nextBeforeId !== null && (
              <button
                type="button"
                className="btn"
                onClick={() => {
                  setBeforeId(nextBeforeId)
                  void loadAudit(nextBeforeId)
                }}
              >
                <span>{t('Tải mục cũ hơn', 'Load Older Entries')}</span>
                <OIcon name="caret-right" size={16} />
              </button>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
