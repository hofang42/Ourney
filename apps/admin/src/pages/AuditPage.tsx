import { useEffect, useState } from 'react'
import { adminApi, type AuditLogRow } from '../lib/adminRpc'
import { useI18n } from '../lib/i18n'
import { OIcon } from '../ui/Icon'

export function AuditPage() {
  const { t } = useI18n()
  const [rows, setRows] = useState<AuditLogRow[]>([])
  const [actionPrefix, setActionPrefix] = useState('')
  const [targetType, setTargetType] = useState('all')
  const [targetId, setTargetId] = useState('')
  const [copiedId, setCopiedId] = useState<number | null>(null)

  const loadAudit = async () => {
    const list = await adminApi.listAuditLog({
      p_action_prefix: actionPrefix,
      p_target_type: targetType,
      p_target_id: targetId,
    })
    setRows(list)
  }

  useEffect(() => {
    void loadAudit()
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
            {t(
              'Nhật ký Kiểm toán Bất biến (private.admin_audit)',
              'Immutable Audit Log (private.admin_audit)',
            )}
          </h1>
          <p className="page-subtitle">
            {t(
              'Sổ cái chỉ-thêm (append-only) ghi lại mọi thao tác thay đổi và mọi lần mở xem nội dung nhạy cảm (trigger immutable_audit_log chặn UPDATE/DELETE).',
              'Append-only ledger of every admin mutation and privacy-sensitive read (protected by immutable_audit_log BEFORE UPDATE OR DELETE trigger).',
            )}
          </p>
        </div>
      </div>

      <div className="filter-bar">
        <input
          type="search"
          className="input search-input"
          placeholder={t(
            'Lọc theo tiền tố hành động (vd: moderation., feature_requests., users.)...',
            'Filter by action prefix (e.g. moderation., feature_requests., users.)...',
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
          <option value="moderation_queue">moderation_queue</option>
          <option value="feature_request">feature_request</option>
          <option value="user">user</option>
          <option value="journey">journey</option>
          <option value="waitlist">waitlist</option>
          <option value="word">word</option>
          <option value="admin">admin</option>
          <option value="system">system</option>
        </select>

        <input
          type="text"
          className="input"
          placeholder={t('Target ID chính xác...', 'Exact target_id...')}
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
              <th>{t('Lý do & Meta JSON', 'Reason & Meta')}</th>
              <th>JSON</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.id}>
                <td className="tabular">
                  <div style={{ fontWeight: 700 }}>#{r.id}</div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--muted)' }}>
                    {r.created_at}
                  </div>
                </td>
                <td style={{ fontWeight: 700 }}>{r.admin_email}</td>
                <td>
                  <span className="badge badge-primary">{r.action}</span>
                </td>
                <td>
                  <span className="badge">{r.target_type}</span>{' '}
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
    </div>
  )
}
