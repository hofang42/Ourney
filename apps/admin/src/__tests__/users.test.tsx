import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { adminApi } from '../lib/adminRpc'
import { I18nProvider } from '../lib/i18n'
import { UsersPage } from '../pages/UsersPage'
import {
  SQL_FIXTURE_MODERATOR,
  SQL_FIXTURE_OWNER,
  SQL_FIXTURE_USERS_LIST,
  SQL_FIXTURE_USER_DETAIL,
} from './fixtures'

describe('UsersPage & Moderation State Gating (UX-28)', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    vi.spyOn(adminApi, 'listUsers').mockResolvedValue(SQL_FIXTURE_USERS_LIST)
    vi.spyOn(adminApi, 'getUserDetail').mockResolvedValue(
      SQL_FIXTURE_USER_DETAIL,
    )
  })

  it('gates Ban vs Unban by state with tooltip reason, requires confirmation before Revoke Sessions, passes detail.id to ban/delete mutations, and hides Delete Account for moderators (UX-28)', async () => {
    const banSpy = vi.spyOn(adminApi, 'banUser').mockResolvedValue()
    const revokeSpy = vi
      .spyOn(adminApi, 'revokeUserSessions')
      .mockResolvedValue()
    const actionSpy = vi
      .spyOn(adminApi, 'invokeAdminAction')
      .mockResolvedValue({ ok: true })

    const { unmount } = render(
      <MemoryRouter initialEntries={['/users/usr-10']}>
        <I18nProvider initialLang="en">
          <Routes>
            <Route
              path="/users/:id"
              element={<UsersPage admin={SQL_FIXTURE_OWNER} />}
            />
          </Routes>
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(
        screen.getByRole('button', { name: /Ban \/ Suspend User/i }),
      ).toBeInTheDocument()
      expect(
        screen.getByText(/48 · Best Streak 24d/i),
      ).toBeInTheDocument()
      expect(screen.getByText(/#901 · View User Detail/i)).toBeInTheDocument()
    })

    // UX-28: On an active (unbanned) user, Ban is enabled while Unban is disabled with a tooltip reason
    const banBtn = screen.getByRole('button', { name: /Ban \/ Suspend User/i })
    const unbanBtn = screen.getByRole('button', { name: /Unban User/i })
    expect(banBtn).not.toBeDisabled()
    expect(unbanBtn).toBeDisabled()
    expect(unbanBtn).toHaveAttribute(
      'title',
      expect.stringMatching(/not currently banned/i),
    )

    const user = userEvent.setup()
    await user.click(banBtn)
    expect(
      screen.getByText(/does NOT delete the user profile/i),
    ).toBeInTheDocument()

    // Check severe abuse checkbox, then press Escape: only Ban modal closes, drawer stays open, and wipeUgc resets on reopen
    await user.click(screen.getByRole('checkbox'))
    expect(screen.getByRole('checkbox')).toBeChecked()
    await user.keyboard('{Escape}')
    expect(
      screen.queryByRole('dialog', { name: /Ban \/ Suspend User Account/i }),
    ).toBeNull()
    expect(
      screen.getByRole('dialog', { name: /User detail drawer/i }),
    ).toBeInTheDocument()

    // Reopen Ban modal -> wipeUgc was reset to unchecked, and Confirm Ban is disabled until reason >= 3 chars
    await user.click(banBtn)
    expect(screen.getByRole('checkbox')).not.toBeChecked()
    const confirmBanBtn = screen.getByRole('button', { name: /Confirm Ban/i })
    expect(confirmBanBtn).toBeDisabled()

    await user.type(
      screen.getByPlaceholderText(/Enter violation reason/i),
      'Violated community safety rules',
    )
    await user.click(screen.getByRole('checkbox'))
    expect(confirmBanBtn).not.toBeDisabled()
    await user.click(confirmBanBtn)
    expect(banSpy).toHaveBeenCalledWith({
      p_user: 'usr-10',
      p_reason: 'Violated community safety rules',
      p_wipe_ugc: true,
    })

    // UX-28: Revoke Sessions opens confirmation dialog before revoking
    await user.click(
      screen.getByRole('button', { name: /Revoke Sessions/i }),
    )
    expect(revokeSpy).not.toHaveBeenCalled()
    expect(
      screen.getByRole('dialog', { name: /Confirm Revoke Active Sessions/i }),
    ).toBeInTheDocument()
    await user.click(
      screen.getByRole('button', { name: /Confirm Revoke Sessions/i }),
    )
    expect(revokeSpy).toHaveBeenCalledWith(
      'usr-10',
      'Manual session revoke from Users Drawer',
    )

    await user.click(
      screen.getByRole('button', { name: /Delete Account on Request/i }),
    )
    const confirmBtn = screen.getByRole('button', {
      name: /Execute Account Erasure/i,
    })
    expect(confirmBtn).toBeDisabled()

    await user.type(screen.getByPlaceholderText('@linh_ielts'), '@linh_ielts')
    expect(confirmBtn).toBeDisabled()
    await user.type(
      screen.getByPlaceholderText(/Enter verified erasure reason/i),
      'Verified user deletion request',
    )
    expect(confirmBtn).not.toBeDisabled()
    await user.click(confirmBtn)

    expect(actionSpy).toHaveBeenCalledWith({
      action: 'delete_user',
      user_id: 'usr-10',
      reason: 'Verified user deletion request',
      ticket_ref: undefined,
    })

    unmount()

    // UX-28: On a banned user, Ban is disabled with tooltip while Unban is enabled
    vi.spyOn(adminApi, 'getUserDetail').mockResolvedValueOnce({
      ...SQL_FIXTURE_USER_DETAIL,
      is_banned: true,
      status: 'banned',
      banned_until: '2099-01-01T00:00:00Z',
    })

    const secondRender = render(
      <MemoryRouter initialEntries={['/users/usr-10']}>
        <I18nProvider initialLang="en">
          <Routes>
            <Route
              path="/users/:id"
              element={<UsersPage admin={SQL_FIXTURE_MODERATOR} />}
            />
          </Routes>
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(
        screen.getByRole('button', { name: /Ban \/ Suspend User/i }),
      ).toBeDisabled()
    })
    expect(
      screen.getByRole('button', { name: /Ban \/ Suspend User/i }),
    ).toHaveAttribute('title', expect.stringMatching(/already banned/i))
    expect(
      screen.getByRole('button', { name: /Unban User/i }),
    ).not.toBeDisabled()
    expect(
      screen.queryByRole('button', { name: /Delete Account on Request/i }),
    ).toBeNull()

    secondRender.unmount()

    // Self-action gating: when viewing own admin account (detail.id === admin.user_id), Ban, Unban, Revoke, and Delete are all disabled
    vi.spyOn(adminApi, 'getUserDetail').mockResolvedValueOnce({
      ...SQL_FIXTURE_USER_DETAIL,
      id: SQL_FIXTURE_OWNER.user_id,
      email: SQL_FIXTURE_OWNER.email,
      username: SQL_FIXTURE_OWNER.username,
    })

    render(
      <MemoryRouter initialEntries={[`/users/${SQL_FIXTURE_OWNER.user_id}`]}>
        <I18nProvider initialLang="en">
          <Routes>
            <Route
              path="/users/:id"
              element={<UsersPage admin={SQL_FIXTURE_OWNER} />}
            />
          </Routes>
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(
        screen.getByRole('button', { name: /Ban \/ Suspend User/i }),
      ).toBeDisabled()
      expect(
        screen.getByRole('button', { name: /Revoke Sessions/i }),
      ).toBeDisabled()
      expect(
        screen.getByRole('button', { name: /Delete Account on Request/i }),
      ).toBeDisabled()
    })
  })

  it('renders empty state row when listUsers returns 0 items and renders modal RPC errors inside the open modal dialog (F-42)', async () => {
    vi.spyOn(adminApi, 'listUsers').mockResolvedValueOnce({
      total: 0,
      items: [],
    })
    vi.spyOn(adminApi, 'revokeUserSessions').mockRejectedValueOnce(
      Object.assign(new Error('rate_limited'), { code: 'P0001' }),
    )

    render(
      <MemoryRouter initialEntries={['/users/usr-10']}>
        <I18nProvider initialLang="en">
          <Routes>
            <Route
              path="/users/:id"
              element={<UsersPage admin={SQL_FIXTURE_OWNER} />}
            />
          </Routes>
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(
        screen.getByText(/No users match the current filters/i),
      ).toBeInTheDocument()
      expect(
        screen.getByRole('button', { name: /Revoke Sessions/i }),
      ).toBeInTheDocument()
    })

    const user = userEvent.setup()
    await user.click(
      screen.getByRole('button', { name: /Revoke Sessions/i }),
    )
    await user.click(
      screen.getByRole('button', { name: /Confirm Revoke Sessions/i }),
    )

    await waitFor(() => {
      const dialog = screen.getByRole('dialog', {
        name: /Confirm Revoke Active Sessions/i,
      })
      expect(dialog).toHaveTextContent(/Rate limit exceeded/i)
    })
  })
})
