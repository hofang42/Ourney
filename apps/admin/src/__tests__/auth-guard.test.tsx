import { act, render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { adminApi, handleRpcError } from '../lib/adminRpc'
import { I18nProvider } from '../lib/i18n'
import { AdminAuthGuard } from '../ui/Shell'
import { SQL_FIXTURE_MODERATOR, SQL_FIXTURE_OWNER } from './fixtures'

describe('AdminAuthGuard & Mid-Session 42501 Handling', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
  })

  it('auto-signs out and displays error when admin.me() returns 42501 forbidden', async () => {
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
    expect(
      screen.getByText(/does not have admin privileges \(42501\)/i),
    ).toBeInTheDocument()
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
      // Initial mount succeeds as moderator
      .mockResolvedValueOnce(SQL_FIXTURE_MODERATOR)
      // First 42501 check: moderator is still valid in private.admins
      .mockResolvedValueOnce(SQL_FIXTURE_MODERATOR)
      // Second 42501 check: moderator was removed/banned -> 42501
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

    // 1. Moderator hits owner-only RPC (42501), but me() still resolves -> stays signed in
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

    // 2. Admin is removed from private.admins -> me() rejects with 42501 -> signs out immediately
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
