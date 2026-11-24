import { useEffect, useState, type FormEvent } from 'react'
import {
  adminApi,
  handleRpcError,
  type AdminIdentity,
  type AdminRole,
  type SystemHealth,
} from '../lib/adminRpc'
import { formatAdminRole, useI18n } from '../lib/i18n'
import { OIcon } from '../ui/Icon'
import { AccessibleModal } from '../ui/Modal'

export function SettingsPage({ admin }: { admin: AdminIdentity }) {
  const { lang, t } = useI18n()
  const [admins, setAdmins] = useState<AdminIdentity[]>([])
  const [health, setHealth] = useState<SystemHealth | null>(null)
  const [emailOrUid, setEmailOrUid] = useState('')
  const [role, setRole] = useState<AdminRole>('moderator')
  const [note, setNote] = useState('')
  const [statusMsg, setStatusMsg] = useState<string | null>(null)
  const [errorMsg, setErrorMsg] = useState<string | null>(null)

  const [removeTarget, setRemoveTarget] = useState<AdminIdentity | null>(null)
  const [removeReason, setRemoveReason] = useState('')

  const loadData = async () => {
    setErrorMsg(null)
    try {
      const [list, hl] = await Promise.all([
        adminApi.listAdmins(),
        adminApi.systemHealth(),
      ])
      setAdmins(list)
      setHealth(hl)
    } catch (err) {
      const msg = await handleRpcError(err, 'system_health', lang)
      setErrorMsg(msg)
    }
  }

  useEffect(() => {
    void loadData()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleUpsertAdmin = async (e: FormEvent) => {
    e.preventDefault()
    if (!emailOrUid.trim()) return
    setErrorMsg(null)
    try {
      await adminApi.upsertAdminUser({
        p_email_or_uid: emailOrUid.trim(),
        p_role: role,
        p_note: note.trim() || undefined,
      })
      const roleLabel = formatAdminRole(role, lang)
      setStatusMsg(
        t(
          `Đã cập nhật quyền quản trị cho ${emailOrUid.trim()} (${roleLabel}).`,
          `Upserted admin user ${emailOrUid.trim()} (${roleLabel}).`,
        ),
      )
      setEmailOrUid('')
      setNote('')
      await loadData()
    } catch (err) {
      const msg = await handleRpcError(err, 'upsert_admin_user', lang)
      setErrorMsg(msg)
    }
  }

  const handleConfirmRemoveAdmin = async () => {
    if (!removeTarget) return
    setErrorMsg(null)
    try {
      await adminApi.removeAdminUser(
        removeTarget.user_id,
        removeReason.trim() || 'Removed from Settings page',
      )
      setStatusMsg(t('Đã gỡ quyền quản trị viên.', 'Removed admin user.'))
      setRemoveTarget(null)
      setRemoveReason('')
      await loadData()
    } catch (err) {
      const msg = await handleRpcError(err, 'remove_admin_user', lang)
      setErrorMsg(msg)
    }
  }

  const handleRunStorageSweep = async () => {
    setErrorMsg(null)
    try {
      await adminApi.invokeAdminAction({ action: 'run_storage_sweep' })
      setStatusMsg(
        t(
          'Đã chạy tiến trình dọn dẹp tệp lưu trữ.',
          'Executed Storage Purge Sweep Now.',
        ),
      )
      await loadData()
    } catch (err) {
      const msg = await handleRpcError(err, 'run_storage_sweep', lang)
      setErrorMsg(msg)
    }
  }

  const handleResetStuckPurge = async () => {
    setErrorMsg(null)
    try {
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
    } catch (err) {
      const msg = await handleRpcError(
        err,
        'reset_stuck_storage_purge',
        lang,
      )
      setErrorMsg(msg)
    }
  }

  const handleTriggerModerationNotify = async () => {
    setErrorMsg(null)
    try {
      await adminApi.invokeAdminAction({ action: 'trigger_moderation_notify' })
      setStatusMsg(
        t(
          'Đã kích hoạt gửi thông báo cảnh báo kiểm duyệt.',
          'Triggered Moderation Notification Digest.',
        ),
      )
      await loadData()
    } catch (err) {
      const msg = await handleRpcError(
        err,
        'trigger_moderation_notify',
        lang,
      )
      setErrorMsg(msg)
    }
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
              'Quản lý danh sách quản trị viên (Chủ sở hữu / Kiểm duyệt viên), giám sát hàng đợi dọn dẹp tệp lưu trữ và kích hoạt cảnh báo SLA.',
              'Manage admin team roles (Owner / Moderator) and operate storage purge and moderation notification queues.',
            )}
          </p>
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

      {health && (
        <div className="charts-grid">
          <div className="card">
            <h3 style={{ marginBottom: 8 }}>
              {t(
                'Sức khỏe Hàng đợi Dọn dẹp Lưu trữ',
                'Storage Purge Queue Health',
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
                  {t('Bị kẹt (>= 20 lần thử)', 'Stuck (>= 20)')}
                </div>
                <div className="kpi-value">
                  {health.storage_purge.stuck_count}
                </div>
              </div>
            </div>

            {health.storage_purge.sample_errors.length > 0 && (
              <div
                className="card-subtle"
                style={{ marginBottom: 14, display: 'grid', gap: 6 }}
              >
                <div className="field-label">
                  {t(
                    'Mẫu lỗi xóa tệp gần nhất (Đã ẩn đường dẫn đầy đủ):',
                    'Recent Sample Purge Errors (Redacted Path Prefix):',
                  )}
                </div>
                {health.storage_purge.sample_errors.map((err, idx) => (
                  <div
                    key={`${err.bucket}:${err.path_prefix}:${idx}`}
                    style={{ fontSize: '0.8rem' }}
                  >
                    <strong>
                      {err.bucket}/{err.path_prefix}
                    </strong>{' '}
                    ({err.attempts} {t('lần thử', 'attempts')}):{' '}
                    {err.last_error}
                  </div>
                ))}
              </div>
            )}

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
                <span>{t('Đặt lại tệp bị kẹt', 'Reset Stuck Retries')}</span>
              </button>
            </div>
          </div>

          <div className="card">
            <h3 style={{ marginBottom: 8 }}>
              {t(
                'Trạng thái Cảnh báo Kiểm duyệt',
                'Moderation Alert Webhook Status',
              )}
            </h3>
            <div className="kpi-grid" style={{ marginBottom: 14 }}>
              <div className="card-subtle">
                <div className="kpi-label">
                  {t(
                    'Số báo cáo mở chưa gửi thông báo',
                    'Unnotified Open Queue Items',
                  )}
                </div>
                <div className="kpi-value">
                  {health.moderation_notifications.unnotified_open_count}
                </div>
              </div>
              <div className="card-subtle">
                <div className="kpi-label">
                  {t('Đang xử lý gửi', 'Leased In-Flight')}
                </div>
                <div className="kpi-value">
                  {health.moderation_notifications.leased_count}
                </div>
              </div>
              <div className="card-subtle">
                <div className="kpi-label">
                  {t('Quá hạn đang mở', 'Overdue Open')}
                </div>
                <div className="kpi-value">
                  {health.moderation_notifications.overdue_open_count}
                </div>
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
        <div className="kpi-top" style={{ marginBottom: 12 }}>
          <h3>
            {t('Đội ngũ Quản trị viên', 'Admin Team')}
          </h3>
          {health && (
            <div style={{ display: 'flex', gap: 8 }}>
              <span className="badge badge-primary">
                {t('Chủ sở hữu', 'Owners')}: {health.admins_count.owners}
              </span>
              <span className="badge badge-sky">
                {t('Kiểm duyệt viên', 'Moderators')}:{' '}
                {health.admins_count.moderators}
              </span>
            </div>
          )}
        </div>

        {admin.role === 'owner' && (
          <form onSubmit={handleUpsertAdmin} className="form-grid-admin">
            <input
              type="text"
              className="input"
              aria-label={t(
                'Email hoặc mã người dùng quản trị viên',
                'Admin email or Auth User ID',
              )}
              placeholder={t(
                'Email hoặc mã tài khoản Ourney...',
                'Email or Auth User ID...',
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
              <option value="moderator">
                {formatAdminRole('moderator', lang)}
              </option>
              <option value="owner">{formatAdminRole('owner', lang)}</option>
            </select>
            <input
              type="text"
              className="input"
              aria-label={t('Ghi chú vai trò quản trị', 'Admin role note')}
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
                      {formatAdminRole(a.role, lang)}
                    </span>
                  </td>
                  <td>{a.note || '—'}</td>
                  <td>
                    {admin.role === 'owner' && a.user_id !== admin.user_id && (
                      <button
                        type="button"
                        className="btn btn-danger"
                        aria-label={`${t('Gỡ quyền', 'Remove')} ${a.email}`}
                        onClick={() => setRemoveTarget(a)}
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

      {removeTarget && (
        <AccessibleModal
          title={t(
            'Xác nhận gỡ quyền quản trị viên',
            'Confirm Admin Removal',
          )}
          onClose={() => setRemoveTarget(null)}
        >
          <h3>
            {t('Xác nhận gỡ quyền quản trị viên', 'Confirm Admin Removal')}
          </h3>
          <p className="page-subtitle">
            {removeTarget.email} ({formatAdminRole(removeTarget.role, lang)}) —{' '}
            {t(
              'Hành động này sẽ thu hồi ngay mọi quyền truy cập bảng điều khiển và hủy các quyền xem ảnh tạm thời đang mở.',
              'This revokes admin console privileges immediately and purges any active media grants.',
            )}
          </p>
          <label className="field-group">
            <span className="field-label">
              {t('Lý do gỡ quyền', 'Removal Reason')}
            </span>
            <input
              type="text"
              className="input"
              value={removeReason}
              onChange={(e) => setRemoveReason(e.target.value)}
              placeholder={t(
                'Luân chuyển nhân sự hoặc kết thúc ca trực...',
                'Role rotation or offboarding...',
              )}
            />
          </label>
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
            <button
              type="button"
              className="btn"
              onClick={() => setRemoveTarget(null)}
            >
              {t('Hủy', 'Cancel')}
            </button>
            <button
              type="button"
              className="btn btn-danger"
              onClick={() => void handleConfirmRemoveAdmin()}
            >
              {t('Xác nhận gỡ quyền', 'Confirm Remove')}
            </button>
          </div>
        </AccessibleModal>
      )}
    </div>
  )
}
