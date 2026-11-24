import { useEffect, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import {
  adminApi,
  type AdminIdentity,
  type AdminUserDetail,
  type AdminUserRow,
} from '../lib/adminRpc'
import { useI18n } from '../lib/i18n'
import { OIcon } from '../ui/Icon'

export function UsersPage({ admin }: { admin: AdminIdentity }) {
  const { t } = useI18n()
  const [searchParams] = useSearchParams()
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [sortBy, setSortBy] = useState('created_at')

  const [rows, setRows] = useState<AdminUserRow[]>([])
  const [drawerUserId, setDrawerUserId] = useState<string | null>(
    searchParams.get('id'),
  )
  const [detail, setDetail] = useState<AdminUserDetail | null>(null)
  const [statusMsg, setStatusMsg] = useState<string | null>(null)

  const [banModalOpen, setBanModalOpen] = useState(false)
  const [banReason, setBanReason] = useState('')
  const [wipeUgc, setWipeUgc] = useState(false)

  const [unbanModalOpen, setUnbanModalOpen] = useState(false)
  const [unbanReason, setUnbanReason] = useState('')

  const [deleteModalOpen, setDeleteModalOpen] = useState(false)
  const [deleteConfirmInput, setDeleteConfirmInput] = useState('')
  const [deleteReason, setDeleteReason] = useState('')
  const [deleteTicketRef, setDeleteTicketRef] = useState('')

  const loadUsers = async () => {
    const list = await adminApi.listUsers({
      p_search: search,
      p_status: statusFilter,
      p_sort: sortBy,
    })
    setRows(list)
  }

  useEffect(() => {
    void loadUsers()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search, statusFilter, sortBy])

  useEffect(() => {
    if (!drawerUserId) {
      setDetail(null)
      return
    }
    void (async () => {
      try {
        const d = await adminApi.getUserDetail(drawerUserId)
        setDetail(d)
      } catch {
        setDetail(null)
      }
    })()
  }, [drawerUserId])

  const handleConfirmBan = async () => {
    if (!detail) return
    await adminApi.banUser({
      p_user: detail.user_id,
      p_reason: banReason.trim() || 'Violated community safety rules',
      p_wipe_ugc: wipeUgc,
    })
    setBanModalOpen(false)
    setBanReason('')
    setWipeUgc(false)
    setStatusMsg(
      wipeUgc
        ? t(
            'Đã khóa tài khoản kèm gỡ bỏ toàn bộ UGC và thu hồi liên kết công khai.',
            'Banned user with full UGC takedown and revoked public links.',
          )
        : t(
            'Đã khóa tài khoản có thể hoàn tác (giữ nguyên dữ liệu ảnh riêng tư, không đặt profiles.deleted_at).',
            'Applied reversible ban (banned_until + session revoke + public_token revoke; profiles.deleted_at untouched).',
          ),
    )
    await loadUsers()
    const refreshed = await adminApi.getUserDetail(detail.user_id)
    setDetail(refreshed)
  }

  const handleConfirmUnban = async () => {
    if (!detail) return
    await adminApi.unbanUser(
      detail.user_id,
      unbanReason.trim() || 'Appeal accepted',
    )
    setUnbanModalOpen(false)
    setUnbanReason('')
    setStatusMsg(
      t(
        'Đã mở khóa tài khoản người dùng (xóa banned_until, cập nhật private.user_moderation).',
        'Unbanned user account (cleared banned_until and updated private.user_moderation).',
      ),
    )
    await loadUsers()
    const refreshed = await adminApi.getUserDetail(detail.user_id)
    setDetail(refreshed)
  }

  const handleRevokeSessions = async () => {
    if (!detail) return
    await adminApi.revokeUserSessions(
      detail.user_id,
      'Manual session revoke from Users Drawer',
    )
    setStatusMsg(
      t(
        'Đã thu hồi toàn bộ phiên đăng nhập (auth.sessions) của người dùng.',
        'Revoked all active auth.sessions for this user.',
      ),
    )
  }

  const expectedConfirmToken =
    detail?.username ? `@${detail.username}` : detail?.email || ''

  const handleConfirmDeleteAccount = async () => {
    if (!detail) return
    if (deleteConfirmInput.trim() !== expectedConfirmToken) return
    await adminApi.invokeAdminAction({
      action: 'delete_user',
      user_id: detail.user_id,
      reason: deleteReason.trim() || 'Verified user deletion request',
      ticket_ref: deleteTicketRef.trim() || undefined,
    })
    setDeleteModalOpen(false)
    setDeleteConfirmInput('')
    setDeleteReason('')
    setDeleteTicketRef('')
    setDrawerUserId(null)
    setStatusMsg(
      t(
        'Đã xóa vĩnh viễn tài khoản theo yêu cầu (ghi nhật ký users.delete_on_request kèm sha256 email).',
        'Permanently erased account on request (logged users.delete_on_request with sha256 email).',
      ),
    )
    await loadUsers()
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
      <div className="page-header">
        <div>
          <h1 className="page-title">
            {t(
              'Tra cứu Người dùng & Hỗ trợ Tài khoản',
              'Users & Account Support',
            )}
          </h1>
          <p className="page-subtitle">
            {t(
              'Chỉ hiển thị chỉ số tổng hợp và tín hiệu an toàn; tuyệt đối không truy cập ảnh cá nhân, cân nặng hay tin nhắn 1:1.',
              'Aggregate counts and trust signals only — zero access to private check-in photos, weight metrics, or 1:1 chats.',
            )}
          </p>
        </div>
      </div>

      {statusMsg && (
        <div className="status-banner success" role="status">
          <span>{statusMsg}</span>
        </div>
      )}

      <div className="filter-bar">
        <input
          type="search"
          className="input search-input"
          placeholder={t(
            'Tìm theo @username, email, tên hiển thị hoặc UUID...',
            'Search @username, email, display name, or UUID...',
          )}
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />

        <select
          aria-label={t('Lọc trạng thái người dùng', 'Filter user status')}
          className="select"
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
        >
          <option value="all">{t('Tất cả trạng thái', 'All statuses')}</option>
          <option value="active">{t('Đang hoạt động', 'Active')}</option>
          <option value="banned">{t('Đang bị khóa (Banned)', 'Banned')}</option>
          <option value="incomplete_onboarding">
            {t('Chưa hoàn tất hồ sơ', 'Incomplete Onboarding')}
          </option>
          <option value="reported">
            {t('Có báo cáo vi phạm', 'Has Reports Against')}
          </option>
        </select>

        <select
          aria-label={t('Sắp xếp người dùng', 'Sort users')}
          className="select"
          value={sortBy}
          onChange={(e) => setSortBy(e.target.value)}
        >
          <option value="created_at">
            {t('Mới đăng ký nhất', 'Newest Signup')}
          </option>
          <option value="last_active_at">
            {t('Hoạt động gần nhất', 'Recently Active')}
          </option>
          <option value="reports_against">
            {t('Nhiều báo cáo nhất', 'Most Reports Against')}
          </option>
        </select>
      </div>

      <div className="table-wrap">
        <table className="data-table">
          <thead>
            <tr>
              <th>{t('Người dùng', 'User')}</th>
              <th>{t('Xác thực & Điều khoản', 'Contact / Auth')}</th>
              <th>{t('Trạng thái', 'Status')}</th>
              <th>{t('Hành trình', 'Journeys')}</th>
              <th>{t('Check-ins & Streak', 'Check-ins & Streak')}</th>
              <th>{t('Tín hiệu an toàn', 'Trust Signals')}</th>
              <th>{t('Thao tác', 'Actions')}</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((u) => (
              <tr
                key={u.user_id}
                className="clickable-row"
                onClick={() => setDrawerUserId(u.user_id)}
              >
                <td>
                  <div style={{ fontWeight: 700 }}>
                    {u.username ? `@${u.username}` : '[No Username]'}
                  </div>
                  <div style={{ fontSize: '0.78rem', color: 'var(--muted)' }}>
                    {u.display_name} · {u.user_id.slice(0, 8)}
                  </div>
                </td>
                <td>
                  <div>{u.email || '—'}</div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--muted)' }}>
                    Terms v{u.terms_version} ·{' '}
                    {u.has_password ? 'Password' : 'OTP'}
                  </div>
                </td>
                <td>
                  <span
                    className={`badge ${
                      u.status === 'banned'
                        ? 'badge-danger'
                        : u.status === 'active'
                          ? 'badge-success'
                          : 'badge-warn'
                    }`}
                  >
                    {u.status}
                  </span>
                </td>
                <td className="tabular">
                  {u.active_journeys} / {u.total_journeys} ({u.group_journeys}{' '}
                  squad)
                </td>
                <td className="tabular">
                  {u.total_checkins} snaps · Best {u.best_streak}d
                </td>
                <td>
                  <span
                    className={`badge ${
                      u.open_reports_against > 0 ? 'badge-danger' : ''
                    } tabular`}
                  >
                    {u.open_reports_against} open / {u.total_actioned_reports}{' '}
                    actioned / {u.blocked_by_count} blocks
                  </span>
                </td>
                <td>
                  <button
                    type="button"
                    className="btn"
                    onClick={(e) => {
                      e.stopPropagation()
                      setDrawerUserId(u.user_id)
                    }}
                  >
                    <span>{t('Chi tiết', 'Inspect')}</span>
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {drawerUserId && detail && (
        <div
          className="drawer-scrim"
          role="dialog"
          aria-modal="true"
          aria-label={t('Chi tiết người dùng', 'User detail drawer')}
        >
          <div className="drawer-panel">
            <div className="kpi-top">
              <div>
                <h2>
                  {detail.username ? `@${detail.username}` : detail.email}
                </h2>
                <p className="kpi-label">
                  {detail.display_name} · UUID: {detail.user_id}
                </p>
              </div>
              <button
                type="button"
                className="btn btn-icon"
                onClick={() => setDrawerUserId(null)}
                aria-label={t('Đóng ngăn chi tiết', 'Close detail drawer')}
              >
                <OIcon name="close" size={18} />
              </button>
            </div>

            <div className="card-subtle">
              <div style={{ display: 'grid', gap: 6, fontSize: '0.88rem' }}>
                <div>
                  <strong>Email:</strong> {detail.email || '—'}
                </div>
                <div>
                  <strong>{t('Trạng thái:', 'Status:')}</strong> {detail.status}
                </div>
                <div>
                  <strong>{t('Điều khoản:', 'Terms Version:')}</strong> v
                  {detail.terms_version}
                </div>
                <div>
                  <strong>
                    {t('Tổng số ảnh chụp (Chỉ đếm số lượng):', 'Total Check-ins (Count Only):')}
                  </strong>{' '}
                  {detail.total_checkins} · Best Streak {detail.best_streak}d
                </div>
              </div>
            </div>

            <div
              style={{
                display: 'flex',
                flexWrap: 'wrap',
                gap: 10,
              }}
            >
              <button
                type="button"
                className="btn btn-warn"
                onClick={() => setBanModalOpen(true)}
              >
                <OIcon name="ban" size={18} />
                <span>
                  {t('Khóa tài khoản (Ban User)', 'Ban / Suspend User')}
                </span>
              </button>

              <button
                type="button"
                className="btn btn-success"
                onClick={() => setUnbanModalOpen(true)}
              >
                <OIcon name="check" size={18} />
                <span>{t('Mở khóa (Unban User)', 'Unban User')}</span>
              </button>

              <button
                type="button"
                className="btn"
                onClick={() => void handleRevokeSessions()}
              >
                <OIcon name="sign-out" size={18} />
                <span>
                  {t('Thu hồi phiên đăng nhập', 'Revoke Sessions')}
                </span>
              </button>

              {admin.role === 'owner' && (
                <button
                  type="button"
                  className="btn btn-danger"
                  onClick={() => setDeleteModalOpen(true)}
                >
                  <OIcon name="trash" size={18} />
                  <span>
                    {t(
                      'Xóa tài khoản theo yêu cầu (Owner)',
                      'Delete Account on Request',
                    )}
                  </span>
                </button>
              )}
            </div>

            <div>
              <div className="field-label" style={{ marginBottom: 8 }}>
                {t(
                  `Đề xuất tính năng đã gửi (${detail.feature_requests.length})`,
                  `Submitted Feature Requests (${detail.feature_requests.length})`,
                )}
              </div>
              {detail.feature_requests.map((fr) => (
                <div key={fr.id} className="card-subtle" style={{ marginBottom: 8 }}>
                  <div style={{ fontWeight: 700 }}>{fr.title}</div>
                  <div style={{ fontSize: '0.78rem', color: 'var(--muted)' }}>
                    {fr.status} · {fr.vote_count} votes
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {banModalOpen && detail && (
        <div className="modal-scrim" role="dialog" aria-modal="true">
          <div className="modal-card">
            <h3>
              {t('Khóa tài khoản người dùng', 'Ban / Suspend User Account')}
            </h3>
            <p className="page-subtitle">
              {t(
                'Mặc định là Khóa có thể hoàn tác: đặt auth.users.banned_until, xóa phiên đăng nhập, ghi private.user_moderation và thu hồi liên kết công khai (không đặt profiles.deleted_at và không xóa ảnh riêng tư).',
                'Default is Reversible Ban: sets auth.users.banned_until, deletes auth.sessions/refresh tokens, writes private.user_moderation, and revokes journeys.public_token (does NOT set profiles.deleted_at or wipe private photos).',
              )}
            </p>

            <label className="field-group">
              <span className="field-label">
                {t('Lý do khóa tài khoản', 'Ban Reason')}
              </span>
              <textarea
                className="textarea"
                value={banReason}
                onChange={(e) => setBanReason(e.target.value)}
                placeholder={t(
                  'Nhập lý do vi phạm để lưu vào private.user_moderation...',
                  'Enter reason for private.user_moderation & audit trail...',
                )}
              />
            </label>

            <label
              className="card-subtle"
              style={{
                display: 'flex',
                alignItems: 'flex-start',
                gap: 10,
                cursor: 'pointer',
              }}
            >
              <input
                type="checkbox"
                checked={wipeUgc}
                onChange={(e) => setWipeUgc(e.target.checked)}
                style={{ width: 20, height: 20, marginTop: 2 }}
              />
              <div>
                <div style={{ fontWeight: 700 }}>
                  {t(
                    'Vi phạm nghiêm trọng: Xóa toàn bộ UGC & Thu hồi tệp Storage (p_wipe_ugc = true)',
                    'Severe Abuse Takedown: Wipe UGC & Enqueue Storage Purge (p_wipe_ugc = true)',
                  )}
                </div>
                <div style={{ fontSize: '0.8rem', color: 'var(--muted)' }}>
                  {t(
                    'Ẩn check-in/tin nhắn, rời khỏi nhóm và xếp hàng xóa ảnh trong private.pending_storage_purge.',
                    'Moderates check-ins/messages, hides feature requests, leaves group journeys, and queues storage files for deletion.',
                  )}
                </div>
              </div>
            </label>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
              <button
                type="button"
                className="btn"
                onClick={() => setBanModalOpen(false)}
              >
                {t('Hủy', 'Cancel')}
              </button>
              <button
                type="button"
                className="btn btn-danger"
                onClick={() => void handleConfirmBan()}
              >
                {t('Xác nhận khóa', 'Confirm Ban')}
              </button>
            </div>
          </div>
        </div>
      )}

      {unbanModalOpen && detail && (
        <div className="modal-scrim" role="dialog" aria-modal="true">
          <div className="modal-card">
            <h3>{t('Mở khóa tài khoản', 'Unban User Account')}</h3>
            <label className="field-group">
              <span className="field-label">
                {t('Lý do mở khóa', 'Unban Reason')}
              </span>
              <input
                type="text"
                className="input"
                value={unbanReason}
                onChange={(e) => setUnbanReason(e.target.value)}
              />
            </label>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
              <button
                type="button"
                className="btn"
                onClick={() => setUnbanModalOpen(false)}
              >
                {t('Hủy', 'Cancel')}
              </button>
              <button
                type="button"
                className="btn btn-success"
                onClick={() => void handleConfirmUnban()}
              >
                {t('Xác nhận mở khóa', 'Confirm Unban')}
              </button>
            </div>
          </div>
        </div>
      )}

      {deleteModalOpen && detail && (
        <div className="modal-scrim" role="dialog" aria-modal="true">
          <div className="modal-card">
            <h3>
              {t(
                'Xóa vĩnh viễn tài khoản theo yêu cầu (GDPR / Nghị định 13)',
                'Delete Account on Request (GDPR / Decree 13)',
              )}
            </h3>
            <p className="page-subtitle">
              {t(
                `Nhập chính xác "${expectedConfirmToken}" để xác nhận xóa vĩnh viễn tài khoản và toàn bộ tệp Storage.`,
                `Type "${expectedConfirmToken}" to confirm permanent erasure of account and storage objects.`,
              )}
            </p>

            <label className="field-group">
              <span className="field-label">
                {t('Nhập xác nhận:', 'Type to confirm:')} {expectedConfirmToken}
              </span>
              <input
                type="text"
                className="input"
                value={deleteConfirmInput}
                onChange={(e) => setDeleteConfirmInput(e.target.value)}
                placeholder={expectedConfirmToken}
              />
            </label>

            <label className="field-group">
              <span className="field-label">
                {t('Mã phiếu hỗ trợ (Ticket Reference)', 'Support Ticket Ref')}
              </span>
              <input
                type="text"
                className="input"
                value={deleteTicketRef}
                onChange={(e) => setDeleteTicketRef(e.target.value)}
                placeholder="DSAR-2026-01"
              />
            </label>

            <label className="field-group">
              <span className="field-label">
                {t('Lý do xóa', 'Erasure Reason')}
              </span>
              <input
                type="text"
                className="input"
                value={deleteReason}
                onChange={(e) => setDeleteReason(e.target.value)}
              />
            </label>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
              <button
                type="button"
                className="btn"
                onClick={() => setDeleteModalOpen(false)}
              >
                {t('Hủy', 'Cancel')}
              </button>
              <button
                type="button"
                className="btn btn-danger"
                disabled={deleteConfirmInput.trim() !== expectedConfirmToken}
                onClick={() => void handleConfirmDeleteAccount()}
              >
                {t('Xóa vĩnh viễn tài khoản', 'Execute Account Erasure')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
