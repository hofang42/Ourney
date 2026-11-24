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

describe('UsersPage', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    vi.spyOn(adminApi, 'listUsers').mockResolvedValue(SQL_FIXTURE_USERS_LIST)
    vi.spyOn(adminApi, 'getUserDetail').mockResolvedValue(
      SQL_FIXTURE_USER_DETAIL,
    )
  })

  it('opens detail drawer via /users/:id route, passes detail.id to ban/delete mutations, and hides Delete Account for moderators', async () => {
    const banSpy = vi.spyOn(adminApi, 'banUser').mockResolvedValue()
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
      expect(screen.getByText(/#901 · users\.view_detail/i)).toBeInTheDocument()
    })

    const user = userEvent.setup()
    await user.click(
      screen.getByRole('button', { name: /Ban \/ Suspend User/i }),
    )
    expect(
      screen.getByText(/does NOT set profiles\.deleted_at/i),
    ).toBeInTheDocument()

    await user.click(screen.getByRole('checkbox'))
    await user.click(screen.getByRole('button', { name: /Confirm Ban/i }))
    expect(banSpy).toHaveBeenCalledWith({
      p_user: 'usr-10',
      p_reason: 'Violated community safety rules',
      p_wipe_ugc: true,
    })

    await user.click(
      screen.getByRole('button', { name: /Delete Account on Request/i }),
    )
    const confirmBtn = screen.getByRole('button', {
      name: /Execute Account Erasure/i,
    })
    expect(confirmBtn).toBeDisabled()

    await user.type(screen.getByPlaceholderText('@linh_ielts'), '@linh_ielts')
    expect(confirmBtn).not.toBeDisabled()
    await user.click(confirmBtn)

    expect(actionSpy).toHaveBeenCalledWith({
      action: 'delete_user',
      user_id: 'usr-10',
      reason: 'Verified user deletion request',
      ticket_ref: undefined,
    })

    unmount()

    // Moderator RBAC check: Delete Account on Request is hidden
    render(
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
      ).toBeInTheDocument()
    })
    expect(
      screen.queryByRole('button', { name: /Delete Account on Request/i }),
    ).toBeNull()
  })
})
