import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { adminApi } from '../lib/adminRpc'
import { I18nProvider } from '../lib/i18n'
import { AdminAuthGuard } from '../ui/Shell'

describe('AdminAuthGuard', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
  })

  it('auto-signs out and displays error when admin.me() returns 42501 forbidden', async () => {
    const forbiddenErr = Object.assign(new Error('forbidden'), { code: '42501' })
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

  it('completes 6-digit OTP login flow and renders protected content when admin.me() succeeds', async () => {
    const meSpy = vi
      .spyOn(adminApi, 'me')
      .mockRejectedValueOnce(new Error('no_session'))
      .mockResolvedValueOnce({
        user_id: 'uid-owner',
        email: 'owner@ourney.tech',
        role: 'owner',
        username: 'hoang_owner',
        display_name: 'Hoang',
        note: null,
      })
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
      expect(screen.getByPlaceholderText('owner@ourney.tech')).toBeInTheDocument()
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

    await user.type(screen.getByPlaceholderText('123456'), '654321')
    await user.click(screen.getByRole('button', { name: /Verify & Sign In/i }))

    expect(verifySpy).toHaveBeenCalledWith('owner@ourney.tech', '654321')
    await waitFor(() => {
      expect(screen.getByText('Welcome Admin: owner@ourney.tech')).toBeInTheDocument()
    })
    expect(meSpy).toHaveBeenCalledTimes(2)
  })
})
