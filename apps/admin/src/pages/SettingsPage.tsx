import { useEffect, useState, type FormEvent } from 'react'
import {
  adminApi,
  type AdminIdentity,
  type AdminRole,
  type SystemHealth,
} from '../lib/adminRpc'
import { useI18n } from '../lib/i18n'
import { OIcon } from '../ui/Icon'

export function SettingsPage({ admin }: { admin: AdminIdentity }) {
  const { t } = useI18n()
  const [admins, setAdmins] = useState<AdminIdentity[]>([])
  const [health, setHealth] = useState<SystemHealth | null>(null)
  const [emailOrUid, setEmailOrUid] = useState('')
  const [role, setRole] = useState<AdminRole>('moderator')
  const [note, setNote] = useState('')
  const [statusMsg, setStatusMsg] = useState<string | null>(null)

  const loadData = async () => {
    const [list, hl] = await Promise.all([
      adminApi.listAdmins(),
      adminApi.systemHealth(),
    ])
    setAdmins(list)
    setHealth(hl)
  }

  useEffect(() => {
    void loadData()
  }, [])

  const handleUpsertAdmin = async (e: FormEvent) => {
    e.preventDefault()
    if (!emailOrUid.trim()) return
    await adminApi.upsertAdminUser({
      p_email_or_uid: emailOrUid.trim(),
      p_role: role,
      p_note: note.trim() || undefined,
    })
    setStatusMsg(
      t(
        `Đã cập nhật quyền quản trị cho ${emailOrUid.trim()} (${role}).`,
        `Upserted admin user ${emailOrUid.trim()} (${role}).`,
      ),
    )
    setEmailOrUid('')
    setNote('')
    await loadData()
  }

  const handleRemoveAdmin = async (userId: string) => {
    await adminApi.removeAdminUser(userId, 'Removed from Settings page')
    setStatusMsg(t('Đã gỡ quyền quản trị viên.', 'Removed admin user.'))
    await loadData()
  }

  const handleRunStorageSweep = async () => {
    await adminApi.invokeAdminAction({ action: 'run_storage_sweep' })
    setStatusMsg(
      t(
        'Đã chạy tiến trình dọn dẹp Storage (storage-purge-sweep).',
        'Executed Storage Purge Sweep Now.',
      ),
    )
    await loadData()
  }

  const handleResetStuckPurge = async () => {
    await adminApi.resetStuckStoragePurge(
      'Manual retry reset from Admin Settings',
    )
    setStatusMsg(
      t(
        'Đã đặt lại bộ đếm thử lại cho các tệp bị kẹt.',
        'Reset stuck storage purge retries.',
      ),
    )
    await loadData()
  }

  const handleTriggerModerationNotify = async () => {
    await adminApi.invokeAdminAction({ action: 'trigger_moderation_notify' })
    setStatusMsg(
      t(
        'Đã kích hoạt gửi thông báo cảnh báo kiểm duyệt (notify-moderation).',
        'Triggered Moderation Notification Digest.',
      ),
    )
    await loadData()
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 22 }}>
      <div className="page-header">
        <div>
          <h1 className="page-title">
            {t(
              'Cài đặt Đội ngũ Quản trị & Vận hành Hệ thống',
              'Admin Team Settings & System Operations',
            )}
          </h1>
          <p className="page-subtitle">
            {t(
              'Quản lý danh sách private.admins (owner / moderator), giám sát hàng đợi xóa tệp Storage và kích hoạt cảnh báo SLA.',
              'Manage private.admins (owner / moderator) and operate pending_storage_purge and moderation notification queues.',
            )}
          </p>
        </div>
      </div>

      {statusMsg && (
        <div className="status-banner success" role="status">
          <span>{statusMsg}</span>
        </div>
      )}

      {health && (
        <div className="charts-grid">
          <div className="card">
            <h3 style={{ marginBottom: 8 }}>
              {t(
                'Sức khỏe Hàng đợi Dọn dẹp Storage (private.pending_storage_purge)',
                'Storage Purge Queue Health (private.pending_storage_purge)',
              )}
            </h3>
            <div className="kpi-grid" style={{ marginBottom: 14 }}>
              <div className="card-subtle">
                <div className="kpi-label">
                  {t('Chờ xử lý ngay', 'Due Now')}
                </div>
                <div className="kpi-value">
                  {health.storage_purge.due_now_count}
                </div>
              </div>
              <div className="card-subtle">
                <div className="kpi-label">
                  {t('Đang giãn cách thử lại', 'Backing Off')}
                </div>
                <div className="kpi-value">
                  {health.storage_purge.backing_off_count}
                </div>
              </div>
              <div className="card-subtle">
                <div className="kpi-label">
                  {t('Bị kẹt (Attempts >= 20)', 'Stuck (>= 20)')}
                </div>
                <div className="kpi-value">
                  {health.storage_purge.stuck_count}
                </div>
              </div>
            </div>

            <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
              <button
                type="button"
                className="btn btn-primary"
                onClick={() => void handleRunStorageSweep()}
              >
                <OIcon name="trash" size={18} />
                <span>
                  {t(
                    'Chạy dọn dẹp Storage ngay',
                    'Run Storage Purge Sweep Now',
                  )}
                </span>
              </button>

              <button
                type="button"
                className="btn"
                onClick={() => void handleResetStuckPurge()}
              >
                <OIcon name="refresh" size={18} />
                <span>
                  {t('Đặt lại tệp bị kẹt', 'Reset Stuck Retries')}
                </span>
              </button>
            </div>
          </div>

          <div className="card">
            <h3 style={{ marginBottom: 8 }}>
              {t(
                'Trạng thái Cảnh báo Kiểm duyệt (notify-moderation)',
                'Moderation Alert Webhook Status',
              )}
            </h3>
            <div className="card-subtle" style={{ marginBottom: 14 }}>
              <div className="kpi-label">
                {t(
                  'Số báo cáo mở chưa gửi thông báo',
                  'Unnotified Open Queue Items',
                )}
              </div>
              <div className="kpi-value">
                {health.moderation_alerts.unnotified_open_count}
              </div>
            </div>

            <button
              type="button"
              className="btn btn-warn"
              onClick={() => void handleTriggerModerationNotify()}
            >
              <OIcon name="activity" size={18} />
              <span>
                {t(
                  'Kích hoạt gửi cảnh báo kiểm duyệt',
                  'Trigger Moderation Notification Digest',
                )}
              </span>
            </button>
          </div>
        </div>
      )}

      <div className="card">
        <h3 style={{ marginBottom: 12 }}>
          {t('Đội ngũ Quản trị viên (private.admins)', 'Admin Team (private.admins)')}
        </h3>

        {admin.role === 'owner' && (
          <form
            onSubmit={handleUpsertAdmin}
            style={{
              display: 'grid',
              gridTemplateColumns: '1fr 160px 1fr auto',
              gap: 10,
              marginBottom: 18,
            }}
          >
            <input
              type="text"
              className="input"
              placeholder={t(
                'Email hoặc UUID tài khoản Ourney...',
                'Email or Auth User UUID...',
              )}
              value={emailOrUid}
              onChange={(e) => setEmailOrUid(e.target.value)}
              required
            />
            <select
              aria-label={t('Vai trò quản trị', 'Admin role')}
              className="select"
              value={role}
              onChange={(e) => setRole(e.target.value as AdminRole)}
            >
              <option value="moderator">moderator</option>
              <option value="owner">owner</option>
            </select>
            <input
              type="text"
              className="input"
              placeholder={t('Ghi chú vai trò...', 'Role note...')}
              value={note}
              onChange={(e) => setNote(e.target.value)}
            />
            <button type="submit" className="btn btn-primary">
              <OIcon name="plus" size={18} />
              <span>{t('Thêm / Cập nhật', 'Add / Update Admin')}</span>
            </button>
          </form>
        )}

        <div className="table-wrap" style={{ boxShadow: 'none' }}>
          <table className="data-table">
            <thead>
              <tr>
                <th>Email & Username</th>
                <th>{t('Vai trò', 'Role')}</th>
                <th>{t('Ghi chú', 'Note')}</th>
                <th>{t('Thao tác', 'Actions')}</th>
              </tr>
            </thead>
            <tbody>
              {admins.map((a) => (
                <tr key={a.user_id}>
                  <td>
                    <div style={{ fontWeight: 700 }}>{a.email}</div>
                    <div style={{ fontSize: '0.78rem', color: 'var(--muted)' }}>
                      {a.username ? `@${a.username}` : a.user_id}
                    </div>
                  </td>
                  <td>
                    <span
                      className={`badge ${
                        a.role === 'owner' ? 'badge-primary' : 'badge-sky'
                      }`}
                    >
                      {a.role}
                    </span>
                  </td>
                  <td>{a.note || '—'}</td>
                  <td>
                    {admin.role === 'owner' && a.user_id !== admin.user_id && (
                      <button
                        type="button"
                        className="btn btn-danger"
                        onClick={() => void handleRemoveAdmin(a.user_id)}
                      >
                        <OIcon name="trash" size={16} />
                        <span>{t('Gỡ quyền', 'Remove')}</span>
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
