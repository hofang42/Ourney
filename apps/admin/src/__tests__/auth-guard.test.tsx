import { act, render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { adminApi, handleRpcError, supabase } from '../lib/adminRpc'
import {
  fmtDateShort,
  fmtDateTime,
  formatAdminError,
  formatAdminRole,
  formatAuditAction,
  formatAuditMetaSummary,
  formatFeatureRequestCategory,
  formatFeatureRequestStatus,
  formatJourneyKind,
  formatJourneyStatus,
  formatJourneyVisibility,
  formatModerationReason,
  formatModerationStatus,
  formatPlatformLabel,
  formatTargetType,
  formatUserStatus,
  formatWordCategory,
  formatWordMatchMode,
  I18nProvider,
} from '../lib/i18n'
import { AdminAuthGuard } from '../ui/Shell'
import { SQL_FIXTURE_MODERATOR, SQL_FIXTURE_OWNER } from './fixtures'

describe('AdminAuthGuard, Central Error Mapper (UX-10), and Localization Helpers (UX-42)', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
  })

  it('auto-signs out and displays human message without leaking raw 42501 when admin.me() returns forbidden', async () => {
    const forbiddenErr = Object.assign(new Error('forbidden'), {
      code: '42501',
    })
    vi.spyOn(adminApi, 'me').mockRejectedValue(forbiddenErr)
    const signOutSpy = vi.spyOn(adminApi, 'signOut').mockResolvedValue()

    render(
      <MemoryRouter>
        <I18nProvider initialLang="en">
          <AdminAuthGuard>
            {(admin) => <div>Authenticated: {admin.email}</div>}
          </AdminAuthGuard>
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(signOutSpy).toHaveBeenCalledTimes(1)
    })
    const alert = screen.getByRole('alert')
    expect(alert).toHaveTextContent(/does not have admin privileges/i)
    expect(alert.textContent).not.toContain('42501')
  })

  it('maps raw SQLSTATE, PostgREST, Auth, and Edge Function errors to human VI/EN messages without leaking internal codes', async () => {
    const cases: Array<{ err: unknown; viMatch: RegExp; enMatch: RegExp }> = [
      {
        err: { code: '42501', message: 'permission denied for schema private' },
        viMatch: /không có quyền thực hiện/i,
        enMatch: /do not have permission/i,
      },
      {
        err: {
          code: 'PGRST202',
          message: 'Could not find the function admin.list_feature_requests',
        },
        viMatch: /chưa được kích hoạt trên máy chủ/i,
        enMatch: /not yet enabled on the database server/i,
      },
      {
        err: { code: '28000', message: 'JWT expired' },
        viMatch: /Phiên đăng nhập đã hết hạn/i,
        enMatch: /session has expired/i,
      },
      {
        err: { code: 'P0001', message: 'rate_limited' },
        viMatch: /giới hạn tần suất/i,
        enMatch: /Rate limit exceeded/i,
      },
      {
        err: { code: 'P0001', message: 'not_found' },
        viMatch: /Không tìm thấy mục dữ liệu/i,
        enMatch: /requested record was not found/i,
      },
      {
        err: { code: 'P0001', message: 'cannot_remove_last_owner' },
        viMatch: /Chủ sở hữu cuối cùng/i,
        enMatch: /last remaining Owner/i,
      },
      {
        err: { code: '23514', message: 'links_not_allowed' },
        viMatch: /không được chứa đường dẫn/i,
        enMatch: /cannot contain web links/i,
      },
      {
        err: { code: 'P0001', message: 'invalid' },
        viMatch: /Dữ liệu nhập vào không hợp lệ/i,
        enMatch: /provided input is invalid/i,
      },
      {
        err: new Error('mail_not_configured: RESEND_API_KEY missing'),
        viMatch: /Dịch vụ gửi email chưa được cấu hình/i,
        enMatch: /email delivery service is not configured/i,
      },
      {
        err: new Error('Token has expired or is invalid'),
        viMatch: /Không thể xác thực mã OTP/i,
        enMatch: /Could not verify the OTP code/i,
      },
      {
        err: new Error('resend_429: {"name":"rate_limit_exceeded"}'),
        viMatch: /giới hạn tần suất/i,
        enMatch: /Rate limit exceeded/i,
      },
    ]

    for (const c of cases) {
      const viText = formatAdminError(c.err, 'vi')
      const enText = formatAdminError(c.err, 'en')
      expect(viText).toMatch(c.viMatch)
      expect(enText).toMatch(c.enMatch)
      for (const leaked of [
        '42501',
        'PGRST202',
        '28000',
        'P0001',
        '23514',
        'private.',
        'admin.',
        'RESEND_API_KEY',
      ]) {
        expect(viText).not.toContain(leaked)
        expect(enText).not.toContain(leaked)
      }
    }

    const debugSpy = vi.spyOn(console, 'debug').mockImplementation(() => {})
    const mappedViaRpc = await handleRpcError(
      { code: 'PGRST202', message: 'Could not find the function' },
      'feature_request_stats',
      'vi',
    )
    expect(mappedViaRpc).toMatch(/chưa được kích hoạt/i)
    expect(mappedViaRpc).not.toContain('PGRST202')
    expect(debugSpy).toHaveBeenCalled()
  })

  it('formats enums and ISO timestamps into localized human labels (UX-42)', () => {
    expect(formatFeatureRequestStatus('under_review', 'vi')).toBe('Đang xem xét')
    expect(formatFeatureRequestStatus('in_progress', 'en')).toBe('In Progress')
    expect(formatFeatureRequestCategory('squad', 'vi')).toBe('Nhóm bạn (Squad)')
    expect(formatModerationReason('self_harm', 'vi')).toBe('Tự gây hại')
    expect(formatTargetType('feature_request', 'vi')).toBe('Đề xuất tính năng')
    expect(formatWordMatchMode('diacritic_word', 'vi')).toBe('Từ có dấu chính xác')
    expect(formatWordCategory('csae', 'en')).toBe('Child Safety (CSAE)')
    expect(formatUserStatus('incomplete_onboarding', 'vi')).toBe(
      'Chưa hoàn tất hồ sơ',
    )
    expect(formatJourneyKind('group', 'vi')).toBe('Nhóm bạn')
    expect(formatJourneyVisibility('private', 'vi')).toBe('Riêng tư')
    expect(formatPlatformLabel('ios')).toBe('iOS')
    expect(formatPlatformLabel('android')).toBe('Android')
    expect(formatAuditAction('users.view_detail', 'en')).toBe('View User Detail')

    const formattedVi = fmtDateTime('2026-11-24T06:15:00Z', 'vi')
    expect(formattedVi).not.toContain('2026-11-24T06:15:00Z')
    expect(formattedVi).toContain('2026')
    expect(formattedVi).toContain('13:15')
    expect(formattedVi).toContain('(GMT+7)')
    expect(fmtDateShort('2026-10-21', 'vi')).toBe('21/10/2026')

    // Unknown enum values render neutral "Không rõ (<raw>)" / "Unknown (<raw>)" labels, never a wrong known value
    expect(formatUserStatus('mystery_state', 'vi')).toBe(
      'Không rõ (mystery_state)',
    )
    expect(formatUserStatus('mystery_state', 'en')).toBe(
      'Unknown (mystery_state)',
    )
    expect(formatJourneyVisibility('unlisted_v3', 'vi')).toBe(
      'Không rõ (unlisted_v3)',
    )
    expect(formatJourneyStatus('paused_v2', 'vi')).toBe('Không rõ (paused_v2)')
    expect(formatFeatureRequestStatus('backlog_v2', 'vi')).toBe(
      'Không rõ (backlog_v2)',
    )
    expect(formatModerationStatus('escalated', 'en')).toBe(
      'Unknown (escalated)',
    )
    expect(formatAdminRole('super_root', 'vi')).toBe('Không rõ (super_root)')

    // Action-contextual formatAuditMetaSummary assertions (Finding R1)
    expect(
      formatAuditMetaSummary(
        { action: 'ban_user', status: 'actioned' },
        'vi',
        'moderation.resolve',
      ),
    ).toBe('Quyết định: Khóa tài khoản & xóa nội dung · Trạng thái: Đã xử phạt')
    expect(
      formatAuditMetaSummary(
        { action: 'dismiss', status: 'dismissed' },
        'en',
        'moderation.resolve',
      ),
    ).toBe('Action: Dismiss Report · Status: Dismissed')
    expect(
      formatAuditMetaSummary(
        { lang: 'vi', match_mode: 'diacritic_word', category: 'self_harm' },
        'vi',
        'words.upsert',
      ),
    ).toBe(
      'Ngôn ngữ: Tiếng Việt (VI) · Chế độ khớp: Từ có dấu chính xác · Danh mục: Tự gây hại',
    )
    expect(
      formatAuditMetaSummary(
        { lang: 'any', match_mode: 'substring', category: 'csae' },
        'en',
        'words.delete',
      ),
    ).toBe(
      'Language: Any language · Match Mode: Substring · Category: Child Safety (CSAE)',
    )
    expect(
      formatAuditMetaSummary(
        { row_count: 120, lang: 'all', platform: 'all' },
        'vi',
        'waitlist.export_csv',
      ),
    ).toBe('Số dòng: 120 · Ngôn ngữ: Mọi ngôn ngữ')
    expect(
      formatAuditMetaSummary(
        { row_count: 120, lang: 'all', platform: 'all' },
        'en',
        'waitlist.export_csv',
      ),
    ).toBe('Rows: 120 · Language: All languages')
    expect(
      formatAuditMetaSummary(
        {
          old_status: 'new',
          new_status: 'planned',
          old_category: 'other',
          new_category: 'squad',
        },
        'en',
        'feature_requests.update',
      ),
    ).toBe(
      'Prev Status: New · Status: Planned · Prev Category: Other · Category: Squad',
    )
    expect(
      formatAuditMetaSummary(
        { reset_count: 5 },
        'vi',
        'system.reset_storage_purge',
      ),
    ).toBe('Đã đặt lại: 5')
  })

  it('extracts Edge Function status and JSON error code from FunctionsHttpError context in invokeAdminAction', async () => {
    const httpError = Object.assign(
      new Error('Edge Function returned a non-2xx status code'),
      {
        name: 'FunctionsHttpError',
        context: new Response(JSON.stringify({ error: 'cannot_delete_self' }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        }),
      },
    )
    const invokeMock = vi.fn().mockResolvedValueOnce({
      data: null,
      error: httpError,
    })
    vi.spyOn(supabase, 'functions', 'get').mockReturnValue({
      invoke: invokeMock,
    } as unknown as typeof supabase.functions)

    let caught: unknown = null
    try {
      await adminApi.invokeAdminAction({
        action: 'delete_user',
        user_id: '00000000-0000-0000-0000-000000000001',
        reason: 'Self delete test',
      })
    } catch (err) {
      caught = err
    }

    expect(caught).toBeTruthy()
    expect((caught as { status?: number }).status).toBe(400)
    expect((caught as { code?: string }).code).toBe('cannot_delete_self')
    expect(formatAdminError(caught, 'vi')).toMatch(
      /không thể tự xóa tài khoản quản trị viên của chính mình/i,
    )
    expect(formatAdminError(caught, 'en')).toMatch(
      /cannot delete your own admin account/i,
    )
  })

  it('completes 6-digit OTP login flow, clears OTP on Back button, and renders protected content', async () => {
    const meSpy = vi
      .spyOn(adminApi, 'me')
      .mockRejectedValueOnce(new Error('no_session'))
      .mockResolvedValueOnce(SQL_FIXTURE_OWNER)
    const otpSpy = vi.spyOn(adminApi, 'signInWithOtp').mockResolvedValue()
    const verifySpy = vi.spyOn(adminApi, 'verifyOtp').mockResolvedValue()

    render(
      <MemoryRouter>
        <I18nProvider initialLang="en">
          <AdminAuthGuard>
            {(admin) => <div>Welcome Admin: {admin.email}</div>}
          </AdminAuthGuard>
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(
        screen.getByPlaceholderText('owner@ourney.tech'),
      ).toBeInTheDocument()
    })

    const user = userEvent.setup()
    await user.type(
      screen.getByPlaceholderText('owner@ourney.tech'),
      'owner@ourney.tech',
    )
    await user.click(screen.getByRole('button', { name: /Send 6-Digit OTP/i }))
    expect(otpSpy).toHaveBeenCalledWith('owner@ourney.tech')

    await waitFor(() => {
      expect(screen.getByPlaceholderText('123456')).toBeInTheDocument()
    })

    await user.type(screen.getByPlaceholderText('123456'), '111111')
    await user.click(screen.getByRole('button', { name: /Back/i }))
    await user.click(screen.getByRole('button', { name: /Send 6-Digit OTP/i }))
    expect(screen.getByPlaceholderText('123456')).toHaveValue('')

    await user.type(screen.getByPlaceholderText('123456'), '654321')
    await user.click(screen.getByRole('button', { name: /Verify & Sign In/i }))

    expect(verifySpy).toHaveBeenCalledWith('owner@ourney.tech', '654321')
    await waitFor(() => {
      expect(
        screen.getByText('Welcome Admin: owner@ourney.tech'),
      ).toBeInTheDocument()
    })
    expect(meSpy).toHaveBeenCalledTimes(2)
  })

  it('signs out automatically on mid-session 42501 when admin privileges are revoked, but keeps moderator signed in when hitting owner-only 42501', async () => {
    const signOutSpy = vi.spyOn(adminApi, 'signOut').mockResolvedValue()
    const meSpy = vi
      .spyOn(adminApi, 'me')
      .mockResolvedValueOnce(SQL_FIXTURE_MODERATOR)
      .mockResolvedValueOnce(SQL_FIXTURE_MODERATOR)
      .mockRejectedValueOnce(
        Object.assign(new Error('forbidden'), { code: '42501' }),
      )

    render(
      <MemoryRouter>
        <I18nProvider initialLang="en">
          <AdminAuthGuard>
            {(admin) => <div>Active Session: {admin.email}</div>}
          </AdminAuthGuard>
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(
        screen.getByText('Active Session: mod@ourney.tech'),
      ).toBeInTheDocument()
    })

    await act(async () => {
      await handleRpcError(
        Object.assign(new Error('forbidden'), { code: '42501' }),
        'export_waitlist',
      )
    })
    expect(
      screen.getByText('Active Session: mod@ourney.tech'),
    ).toBeInTheDocument()
    expect(signOutSpy).not.toHaveBeenCalled()

    await act(async () => {
      await handleRpcError(
        Object.assign(new Error('forbidden'), { code: '42501' }),
        'list_users',
      )
    })
    await waitFor(() => {
      expect(signOutSpy).toHaveBeenCalledTimes(1)
      expect(
        screen.getByText(/privileges were revoked or account was suspended/i),
      ).toBeInTheDocument()
    })
    expect(meSpy).toHaveBeenCalledTimes(3)
  })
})
