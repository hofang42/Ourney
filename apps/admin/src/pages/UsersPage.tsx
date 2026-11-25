import { useEffect, useState } from 'react'
import { useParams, useSearchParams } from 'react-router-dom'
import {
  adminApi,
  handleRpcError,
  type AdminIdentity,
  type AdminUserDetail,
  type AdminUserRow,
} from '../lib/adminRpc'
import {
  fmtDateTime,
  formatAuditAction,
  formatAuditReason,
  formatModerationKind,
  formatModerationReason,
  formatModerationStatus,
  formatUserStatus,
  useI18n,
} from '../lib/i18n'
import { OIcon } from '../ui/Icon'
import { AccessibleModal, PaginationBar } from '../ui/Modal'

const PAGE_LIMIT = 50

export function UsersPage({ admin }: { admin: AdminIdentity }) {
  const { lang, t } = useI18n()
  const params = useParams<{ id?: string }>()
  const [searchParams] = useSearchParams()
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [sortBy, setSortBy] = useState('created_at')
  const [offset, setOffset] = useState(0)

  const [total, setTotal] = useState(0)
  const [rows, setRows] = useState<AdminUserRow[]>([])
  const [drawerUserId, setDrawerUserId] = useState<string | null>(
    params.id || searchParams.get('id'),
  )
  const [detail, setDetail] = useState<AdminUserDetail | null>(null)
  const [statusMsg, setStatusMsg] = useState<string | null>(null)
  const [errorMsg, setErrorMsg] = useState<string | null>(null)

  const [banModalOpen, setBanModalOpen] = useState(false)
  const [banReason, setBanReason] = useState('')
  const [wipeUgc, setWipeUgc] = useState(false)

  const [unbanModalOpen, setUnbanModalOpen] = useState(false)
  const [unbanReason, setUnbanReason] = useState('')

  const [revokeModalOpen, setRevokeModalOpen] = useState(false)
  const [revokeReason, setRevokeReason] = useState('')

  const [deleteModalOpen, setDeleteModalOpen] = useState(false)
  const [deleteConfirmInput, setDeleteConfirmInput] = useState('')
  const [deleteReason, setDeleteReason] = useState('')
  const [deleteTicketRef, setDeleteTicketRef] = useState('')

  useEffect(() => {
    const routeTarget = params.id || searchParams.get('id')
    if (routeTarget) {
      setDrawerUserId(routeTarget)
    }
  }, [params.id, searchParams])

  const loadUsers = async (nextOffset = offset) => {
    setErrorMsg(null)
    try {
      const res = await adminApi.listUsers({
        p_search: search,
        p_status: statusFilter,
        p_sort: sortBy,
        p_limit: PAGE_LIMIT,
        p_offset: nextOffset,
      })
      setTotal(res.total)
      setRows(res.items)
    } catch (err) {
      const msg = await handleRpcError(err, 'list_users', lang)
      setErrorMsg(msg)
    }
  }

  useEffect(() => {
    setOffset(0)
    void loadUsers(0)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search, statusFilter, sortBy])

  useEffect(() => {
    setBanModalOpen(false)
    setBanReason('')
    setWipeUgc(false)
    setUnbanModalOpen(false)
    setUnbanReason('')
    setRevokeModalOpen(false)
    setRevokeReason('')
    setDeleteModalOpen(false)
    setDeleteConfirmInput('')
    setDeleteReason('')
    setDeleteTicketRef('')
    if (!drawerUserId) {
      setDetail(null)
      return
    }
    void (async () => {
      try {
        const d = await adminApi.getUserDetail(drawerUserId)
        setDetail(d)
      } catch (err) {
        const msg = await handleRpcError(err, 'get_user_detail', lang)
        setErrorMsg(msg)
        setDetail(null)
      }
    })()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [drawerUserId])

  const handleConfirmBan = async () => {
    if (!detail) return
    const trimmedReason = banReason.trim()
    if (trimmedReason.length < 3) {
      setErrorMsg(
        t(
          'Lý do khóa tài khoản phải có ít nhất 3 ký tự.',
          'Ban reason must be at least 3 characters.',
        ),
      )
      return
    }
    setErrorMsg(null)
    try {
      await adminApi.banUser({
        p_user: detail.id,
        p_reason: trimmedReason,
        p_wipe_ugc: wipeUgc,
      })
      setBanModalOpen(false)
      setBanReason('')
      setWipeUgc(false)
      setStatusMsg(
        wipeUgc
          ? t(
              'Đã khóa tài khoản kèm gỡ bỏ toàn bộ nội dung đăng tải và thu hồi liên kết công khai.',
              'Banned user with full content takedown and revoked public links.',
            )
          : t(
              'Đã khóa tài khoản có thể hoàn tác (đăng xuất mọi thiết bị, thu hồi liên kết công khai, giữ nguyên ảnh riêng tư).',
              'Applied reversible ban (signed out active sessions, revoked public links, and preserved private photos without deleting the profile).',
            ),
      )
      await loadUsers(offset)
      const refreshed = await adminApi.getUserDetail(detail.id)
      setDetail(refreshed)
    } catch (err) {
      const msg = await handleRpcError(err, 'ban_user', lang)
      setErrorMsg(msg)
    }
  }

  const handleConfirmUnban = async () => {
    if (!detail) return
    setErrorMsg(null)
    try {
      await adminApi.unbanUser(
        detail.id,
        unbanReason.trim() || 'Appeal accepted',
      )
      setUnbanModalOpen(false)
      setUnbanReason('')
      setStatusMsg(
        t(
          'Đã mở khóa tài khoản người dùng và khôi phục quyền đăng nhập.',
          'Unbanned user account and restored sign-in access.',
        ),
      )
      await loadUsers(offset)
      const refreshed = await adminApi.getUserDetail(detail.id)
      setDetail(refreshed)
    } catch (err) {
      const msg = await handleRpcError(err, 'unban_user', lang)
      setErrorMsg(msg)
    }
  }

  const handleConfirmRevokeSessions = async () => {
    if (!detail) return
    setErrorMsg(null)
    try {
      await adminApi.revokeUserSessions(
        detail.id,
        revokeReason.trim() || 'Manual session revoke from Users Drawer',
      )
      setRevokeModalOpen(false)
      setRevokeReason('')
      setStatusMsg(
        t(
          'Đã thu hồi toàn bộ phiên đăng nhập đang hoạt động của người dùng.',
          'Revoked all active sign-in sessions for this user.',
        ),
      )
    } catch (err) {
      const msg = await handleRpcError(err, 'revoke_user_sessions', lang)
      setErrorMsg(msg)
    }
  }

  const expectedConfirmToken = detail?.username
    ? `@${detail.username}`
    : detail?.email || detail?.id || ''

  const handleConfirmDeleteAccount = async () => {
    if (!detail) return
    if (deleteConfirmInput.trim() !== expectedConfirmToken) return
    const trimmedReason = deleteReason.trim()
    if (trimmedReason.length < 3) {
      setErrorMsg(
        t(
          'Lý do xóa tài khoản phải có ít nhất 3 ký tự.',
          'Erasure reason must be at least 3 characters.',
        ),
      )
      return
    }
    setErrorMsg(null)
    try {
      await adminApi.invokeAdminAction({
        action: 'delete_user',
        user_id: detail.id,
        reason: trimmedReason,
        ticket_ref: deleteTicketRef.trim() || undefined,
      })
      setDeleteModalOpen(false)
      setDeleteConfirmInput('')
      setDeleteReason('')
      setDeleteTicketRef('')
      setDrawerUserId(null)
      setStatusMsg(
        t(
          'Đã xóa vĩnh viễn tài khoản theo yêu cầu (đã ghi nhật ký kiểm toán ẩn danh).',
          'Permanently erased account on request (recorded in audit log with anonymized email digest).',
        ),
      )
      await loadUsers(offset)
    } catch (err) {
      const msg = await handleRpcError(err, 'delete_user', lang)
      setErrorMsg(msg)
    }
  }

  const isSelfUser = Boolean(detail && detail.id === admin.user_id)
  const isSoftDeleted = Boolean(
    detail && (detail.status === 'soft_deleted' || detail.deleted_at),
  )
  const isBanned = Boolean(
    detail &&
      (detail.is_banned ||
        detail.status === 'banned' ||
        Boolean(detail.banned_until)),
  )

  const banDisabledReason = isSelfUser
    ? t(
        'Bạn không thể tự khóa tài khoản quản trị viên của chính mình.',
        'You cannot ban your own admin account.',
      )
    : isSoftDeleted
      ? t(
          'Tài khoản đã bị xóa mềm, không thể khóa.',
          'Account is soft-deleted and cannot be banned.',
        )
      : isBanned
        ? t(
            'Tài khoản này đang bị khóa.',
            'This user account is already banned.',
          )
        : undefined

  const unbanDisabledReason = isSelfUser
    ? t(
        'Bạn không thể tự mở khóa tài khoản của chính mình.',
        'You cannot unban your own account.',
      )
    : isSoftDeleted
      ? t(
          'Tài khoản đã bị xóa mềm, không thể mở khóa.',
          'Account is soft-deleted and cannot be unbanned.',
        )
      : !isBanned
        ? t(
            'Tài khoản này đang hoạt động bình thường, không bị khóa.',
            'This user account is not currently banned.',
          )
        : undefined

  const revokeDisabledReason = isSelfUser
    ? t(
        'Không thể thu hồi phiên của chính bạn tại đây. Hãy dùng nút Đăng xuất.',
        'Cannot revoke your own active session here. Use Sign Out instead.',
      )
    : isSoftDeleted
      ? t(
          'Tài khoản đã bị xóa mềm, không còn phiên đăng nhập hoạt động.',
          'Account is soft-deleted and has no active sessions.',
        )
      : undefined

  const deleteDisabledReason = isSelfUser
    ? t(
        'Bạn không thể tự xóa tài khoản quản trị viên của chính mình.',
        'You cannot delete your own admin account.',
      )
    : undefined

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

      <div className="filter-bar">
        <input
          type="search"
          className="input search-input"
          aria-label={t('Tìm kiếm người dùng', 'Search users')}
          placeholder={t(
            'Tìm theo @username, email, tên hiển thị hoặc mã người dùng...',
            'Search @username, email, display name, or user ID...',
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
          <option value="active">{formatUserStatus('active', lang)}</option>
          <option value="banned">{formatUserStatus('banned', lang)}</option>
          <option value="incomplete_onboarding">
            {formatUserStatus('incomplete_onboarding', lang)}
          </option>
          <option value="soft_deleted">
            {formatUserStatus('soft_deleted', lang)}
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
              <th>{t('Check-ins & Chuỗi', 'Check-ins & Streak')}</th>
              <th>{t('Tín hiệu an toàn', 'Trust Signals')}</th>
              <th>{t('Thao tác', 'Actions')}</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((u) => {
              const isSelected = drawerUserId === u.id
              return (
                <tr
                  key={u.id}
                  tabIndex={0}
                  aria-selected={isSelected}
                  className={`clickable-row ${
                    isSelected ? 'selected-row' : ''
                  }`}
                  onClick={() => setDrawerUserId(u.id)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                      e.preventDefault()
                      setDrawerUserId(u.id)
                    }
                  }}
                >
                  <td>
                    <div style={{ fontWeight: 700 }}>
                      {u.username
                        ? `@${u.username}`
                        : t('[Chưa đặt tên]', '[No Username]')}
                    </div>
                    <div style={{ fontSize: '0.78rem', color: 'var(--muted)' }}>
                      {u.display_name || '—'} · {(u.id ?? '').slice(0, 8)}
                    </div>
                  </td>
                  <td>
                    <div>{u.email || '—'}</div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--muted)' }}>
                      {t(`Điều khoản v${u.terms_version}`, `Terms v${u.terms_version}`)}{' '}
                      · {u.has_password ? t('Mật khẩu', 'Password') : 'OTP'}
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
                      {formatUserStatus(u.status, lang)}
                    </span>
                  </td>
                  <td className="tabular">
                    {u.active_journeys_count} / {u.total_journeys_count} (
                    {u.group_journeys_count} {t('nhóm', 'squad')})
                  </td>
                  <td className="tabular">
                    {u.total_checkins} {t('ảnh', 'snaps')} ·{' '}
                    {t(`Chuỗi ${u.best_streak} ngày`, `Best ${u.best_streak}d`)}
                  </td>
                  <td>
                    <span
                      className={`badge ${
                        u.open_reports_against > 0 ? 'badge-danger' : ''
                      } tabular`}
                    >
                      {t(
                        `${u.open_reports_against} mở / ${u.total_actioned_reports} xử phạt / ${u.blocked_by_count} chặn`,
                        `${u.open_reports_against} open / ${u.total_actioned_reports} actioned / ${u.blocked_by_count} blocks`,
                      )}
                    </span>
                  </td>
                  <td>
                    <button
                      type="button"
                      className="btn"
                      aria-label={`${t('Chi tiết', 'Inspect')} ${u.username ? `@${u.username}` : u.id}`}
                      onClick={(e) => {
                        e.stopPropagation()
                        setDrawerUserId(u.id)
                      }}
                    >
                      <span>{t('Chi tiết', 'Inspect')}</span>
                    </button>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>

      <PaginationBar
        total={total}
        limit={PAGE_LIMIT}
        offset={offset}
        onChangeOffset={(next) => {
          setOffset(next)
          void loadUsers(next)
        }}
      />

      {drawerUserId && detail && (
        <AccessibleModal
          variant="drawer"
          title={t('Chi tiết người dùng', 'User detail drawer')}
          onClose={() => setDrawerUserId(null)}
        >
          <div className="kpi-top">
            <div>
              <h2>
                {detail.username
                  ? `@${detail.username}`
                  : detail.email || detail.id}
              </h2>
              <p className="kpi-label">
                {detail.display_name || '—'} · ID: {detail.id}
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
                <strong>{t('Trạng thái:', 'Status:')}</strong>{' '}
                {formatUserStatus(detail.status, lang)}
              </div>
              <div>
                <strong>{t('Ngày tạo tài khoản:', 'Created:')}</strong>{' '}
                {fmtDateTime(detail.created_at, lang)}
              </div>
              <div>
                <strong>{t('Điều khoản:', 'Terms Version:')}</strong> v
                {detail.terms_version}
              </div>
              <div>
                <strong>
                  {t(
                    'Hành trình (Đang mở / Tổng / Nhóm):',
                    'Journeys (Active / Total / Squad):',
                  )}
                </strong>{' '}
                {detail.activity.active_journeys_count} /{' '}
                {detail.activity.total_journeys_count} /{' '}
                {detail.activity.group_journeys_count} ·{' '}
                {t('Bạn bè:', 'Friends:')} {detail.activity.friends_count}
              </div>
              <div>
                <strong>
                  {t(
                    'Tổng số ảnh chụp (Chỉ đếm số lượng):',
                    'Total Check-ins (Count Only):',
                  )}
                </strong>{' '}
                {detail.activity.total_checkins} ·{' '}
                {t(
                  `Chuỗi cao nhất ${detail.activity.best_streak} ngày`,
                  `Best Streak ${detail.activity.best_streak}d`,
                )}
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
              disabled={Boolean(banDisabledReason)}
              title={banDisabledReason}
              onClick={() => setBanModalOpen(true)}
            >
              <OIcon name="ban" size={18} />
              <span>
                {t('Khóa tài khoản', 'Ban / Suspend User')}
              </span>
            </button>

            <button
              type="button"
              className="btn btn-success"
              disabled={Boolean(unbanDisabledReason)}
              title={unbanDisabledReason}
              onClick={() => setUnbanModalOpen(true)}
            >
              <OIcon name="check" size={18} />
              <span>{t('Mở khóa tài khoản', 'Unban User')}</span>
            </button>

            <button
              type="button"
              className="btn"
              disabled={Boolean(revokeDisabledReason)}
              title={revokeDisabledReason}
              onClick={() => setRevokeModalOpen(true)}
            >
              <OIcon name="sign-out" size={18} />
              <span>{t('Thu hồi phiên đăng nhập', 'Revoke Sessions')}</span>
            </button>

            {admin.role === 'owner' && (
              <button
                type="button"
                className="btn btn-danger"
                disabled={Boolean(deleteDisabledReason)}
                title={deleteDisabledReason}
                onClick={() => setDeleteModalOpen(true)}
              >
                <OIcon name="trash" size={18} />
                <span>
                  {t(
                    'Xóa tài khoản theo yêu cầu',
                    'Delete Account on Request',
                  )}
                </span>
              </button>
            )}
          </div>

          <div>
            <div className="field-label" style={{ marginBottom: 8 }}>
              {t(
                `Báo cáo vi phạm gần đây (${detail.trust.recent_reports_against.length})`,
                `Recent Reports Against (${detail.trust.recent_reports_against.length})`,
              )}
            </div>
            {detail.trust.recent_reports_against.length === 0 ? (
              <p className="page-subtitle">
                {t('Không có báo cáo vi phạm.', 'No reports against this user.')}
              </p>
            ) : (
              detail.trust.recent_reports_against.map((rep) => (
                <div
                  key={rep.queue_id}
                  className="card-subtle"
                  style={{ marginBottom: 8 }}
                >
                  <div style={{ fontWeight: 700 }}>
                    {formatModerationKind(rep.kind, lang)} ·{' '}
                    {formatModerationReason(rep.reason, lang, rep.kind)} (
                    {formatModerationStatus(rep.status, lang)})
                  </div>
                  <div
                    className="tabular"
                    style={{ fontSize: '0.78rem', color: 'var(--muted)' }}
                  >
                    {fmtDateTime(rep.created_at, lang)}
                    {rep.resolution_note
                      ? ` — ${formatAuditReason(rep.resolution_note, lang)}`
                      : ''}
                  </div>
                </div>
              ))
            )}
          </div>

          <div>
            <div className="field-label" style={{ marginBottom: 8 }}>
              {t(
                `Lịch sử kiểm toán tài khoản (${detail.trust.audit_history.length})`,
                `Account Audit History (${detail.trust.audit_history.length})`,
              )}
            </div>
            {detail.trust.audit_history.map((aud) => (
              <div
                key={aud.id}
                className="card-subtle"
                style={{ marginBottom: 8 }}
              >
                <div style={{ fontWeight: 700 }}>
                  #{aud.id} · {formatAuditAction(aud.action, lang)}
                </div>
                <div
                  className="tabular"
                  style={{ fontSize: '0.78rem', color: 'var(--muted)' }}
                >
                  {aud.admin_email || t('Hệ thống', 'System')} ·{' '}
                  {fmtDateTime(aud.created_at, lang)}
                  {aud.reason
                    ? ` — ${formatAuditReason(aud.reason, lang)}`
                    : ''}
                </div>
              </div>
            ))}
          </div>
        </AccessibleModal>
      )}

      {banModalOpen && detail && (
        <AccessibleModal
          title={t('Khóa tài khoản người dùng', 'Ban / Suspend User Account')}
          onClose={() => {
            setBanModalOpen(false)
            setBanReason('')
            setWipeUgc(false)
          }}
        >
          <h3>
            {t('Khóa tài khoản người dùng', 'Ban / Suspend User Account')}
          </h3>
          <p className="page-subtitle">
            {t(
              'Mặc định là Khóa có thể hoàn tác: chặn đăng nhập, đăng xuất mọi thiết bị đang mở, ghi lịch sử kiểm duyệt và thu hồi liên kết công khai (không xóa hồ sơ và giữ nguyên ảnh riêng tư).',
              'Default is Reversible Ban: suspends sign-in access, revokes active sessions, records the moderation decision, and disables public journey links (does NOT delete the user profile or wipe private photos).',
            )}
          </p>

          <label className="field-group">
            <span className="field-label">
              {t(
                'Lý do khóa tài khoản (tối thiểu 3 ký tự)',
                'Ban Reason (min 3 chars)',
              )}
            </span>
            <textarea
              className="textarea"
              minLength={3}
              maxLength={500}
              value={banReason}
              onChange={(e) => setBanReason(e.target.value)}
              placeholder={t(
                'Nhập lý do vi phạm để lưu vào hồ sơ kiểm duyệt...',
                'Enter violation reason for moderation history & audit trail...',
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
                  'Vi phạm nghiêm trọng: Xóa toàn bộ nội dung đăng tải & tệp lưu trữ',
                  'Severe Abuse Takedown: Permanently Remove User Content & Media Files',
                )}
              </div>
              <div style={{ fontSize: '0.8rem', color: 'var(--muted)' }}>
                {t(
                  'Ẩn toàn bộ ảnh check-in, tin nhắn và đề xuất tính năng, rời khỏi các hành trình nhóm và xếp hàng xóa vĩnh viễn tệp hình ảnh.',
                  'Hides all check-ins, messages, and feature requests, removes user from group journeys, and queues media files for permanent deletion.',
                )}
              </div>
            </div>
          </label>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
            <button
              type="button"
              className="btn"
              onClick={() => {
                setBanModalOpen(false)
                setBanReason('')
                setWipeUgc(false)
              }}
            >
              {t('Hủy', 'Cancel')}
            </button>
            <button
              type="button"
              className="btn btn-danger"
              disabled={banReason.trim().length < 3}
              onClick={() => void handleConfirmBan()}
            >
              {t('Xác nhận khóa', 'Confirm Ban')}
            </button>
          </div>
        </AccessibleModal>
      )}

      {unbanModalOpen && detail && (
        <AccessibleModal
          title={t('Mở khóa tài khoản', 'Unban User Account')}
          onClose={() => {
            setUnbanModalOpen(false)
            setUnbanReason('')
          }}
        >
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
              onClick={() => {
                setUnbanModalOpen(false)
                setUnbanReason('')
              }}
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
        </AccessibleModal>
      )}

      {revokeModalOpen && detail && (
        <AccessibleModal
          title={t(
            'Xác nhận thu hồi phiên đăng nhập',
            'Confirm Revoke Active Sessions',
          )}
          onClose={() => {
            setRevokeModalOpen(false)
            setRevokeReason('')
          }}
        >
          <h3>
            {t(
              'Xác nhận thu hồi phiên đăng nhập',
              'Confirm Revoke Active Sessions',
            )}
          </h3>
          <p className="page-subtitle">
            {t(
              'Người dùng này sẽ bị đăng xuất ngay lập tức khỏi tất cả thiết bị đang đăng nhập.',
              'This user will be signed out immediately across all currently active devices.',
            )}
          </p>
          <label className="field-group">
            <span className="field-label">
              {t('Lý do thu hồi phiên', 'Revocation Reason')}
            </span>
            <input
              type="text"
              className="input"
              value={revokeReason}
              onChange={(e) => setRevokeReason(e.target.value)}
              placeholder={t(
                'Phát hiện hoạt động đăng nhập bất thường hoặc theo yêu cầu hỗ trợ...',
                'Suspicious activity or user support request...',
              )}
            />
          </label>
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
            <button
              type="button"
              className="btn"
              onClick={() => {
                setRevokeModalOpen(false)
                setRevokeReason('')
              }}
            >
              {t('Hủy', 'Cancel')}
            </button>
            <button
              type="button"
              className="btn btn-danger"
              onClick={() => void handleConfirmRevokeSessions()}
            >
              {t('Xác nhận thu hồi phiên', 'Confirm Revoke Sessions')}
            </button>
          </div>
        </AccessibleModal>
      )}

      {deleteModalOpen && detail && (
        <AccessibleModal
          title={t(
            'Xóa vĩnh viễn tài khoản theo yêu cầu (GDPR / Nghị định 13)',
            'Delete Account on Request (GDPR / Decree 13)',
          )}
          onClose={() => {
            setDeleteModalOpen(false)
            setDeleteConfirmInput('')
            setDeleteReason('')
            setDeleteTicketRef('')
          }}
        >
          <h3>
            {t(
              'Xóa vĩnh viễn tài khoản theo yêu cầu (GDPR / Nghị định 13)',
              'Delete Account on Request (GDPR / Decree 13)',
            )}
          </h3>
          <p className="page-subtitle">
            {t(
              `Nhập chính xác "${expectedConfirmToken}" để xác nhận xóa vĩnh viễn tài khoản và toàn bộ tệp hình ảnh lưu trữ.`,
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
              {t('Mã phiếu hỗ trợ', 'Support Ticket Ref')}
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
              {t(
                'Lý do xóa (tối thiểu 3 ký tự)',
                'Erasure Reason (min 3 chars)',
              )}
            </span>
            <input
              type="text"
              className="input"
              minLength={3}
              maxLength={500}
              value={deleteReason}
              onChange={(e) => setDeleteReason(e.target.value)}
              placeholder={t(
                'Nhập lý do xóa theo yêu cầu...',
                'Enter verified erasure reason...',
              )}
            />
          </label>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
            <button
              type="button"
              className="btn"
              onClick={() => {
                setDeleteModalOpen(false)
                setDeleteConfirmInput('')
                setDeleteReason('')
                setDeleteTicketRef('')
              }}
            >
              {t('Hủy', 'Cancel')}
            </button>
            <button
              type="button"
              className="btn btn-danger"
              disabled={
                deleteConfirmInput.trim() !== expectedConfirmToken ||
                deleteReason.trim().length < 3
              }
              onClick={() => void handleConfirmDeleteAccount()}
            >
              {t('Xóa vĩnh viễn tài khoản', 'Execute Account Erasure')}
            </button>
          </div>
        </AccessibleModal>
      )}
    </div>
  )
}
