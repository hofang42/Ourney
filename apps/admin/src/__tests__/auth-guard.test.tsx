import { act, render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { adminApi, handleRpcError } from '../lib/adminRpc'
import {
  fmtDateShort,
  fmtDateTime,
  formatAdminError,
  formatAuditAction,
  formatFeatureRequestCategory,
  formatFeatureRequestStatus,
  formatJourneyKind,
  formatJourneyVisibility,
  formatModerationReason,
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
    expect(fmtDateShort('2026-10-21', 'vi')).toBe('21/10/2026')
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
