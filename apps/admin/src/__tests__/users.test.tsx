import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { adminApi, type AdminIdentity } from '../lib/adminRpc'
import { I18nProvider } from '../lib/i18n'
import { UsersPage } from '../pages/UsersPage'

const OWNER_ADMIN: AdminIdentity = {
  user_id: 'uid-1',
  email: 'owner@ourney.tech',
  role: 'owner',
  username: 'hoang',
  display_name: 'Hoang',
  note: null,
}

describe('UsersPage', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    vi.spyOn(adminApi, 'listUsers').mockResolvedValue([
      {
        user_id: 'usr-10',
        username: 'linh_ielts',
        display_name: 'Linh Nguyen',
        email: 'linh@example.com',
        has_phone: true,
        has_password: true,
        terms_version: 1,
        status: 'active',
        active_journeys: 2,
        total_journeys: 3,
        group_journeys: 2,
        total_checkins: 48,
        best_streak: 24,
        feature_requests_count: 1,
        open_reports_against: 0,
        total_actioned_reports: 0,
        blocked_by_count: 0,
        last_active_at: '2026-11-24T06:20:00Z',
        created_at: '2026-10-20T09:00:00Z',
      },
    ])
    vi.spyOn(adminApi, 'getUserDetail').mockResolvedValue({
      user_id: 'usr-10',
      username: 'linh_ielts',
      display_name: 'Linh Nguyen',
      email: 'linh@example.com',
      has_phone: true,
      has_password: true,
      terms_version: 1,
      status: 'active',
      active_journeys: 2,
      total_journeys: 3,
      group_journeys: 2,
      total_checkins: 48,
      best_streak: 24,
      feature_requests_count: 1,
      open_reports_against: 0,
      total_actioned_reports: 0,
      blocked_by_count: 0,
      last_active_at: '2026-11-24T06:20:00Z',
      created_at: '2026-10-20T09:00:00Z',
      banned_until: null,
      ban_reason: null,
      wiped_ugc: false,
      feature_requests: [],
      moderation_history: [],
    })
  })

  it('opens detail drawer, supports reversible ban vs wipe-UGC toggle (A2), and owner type-to-confirm account deletion', async () => {
    const banSpy = vi.spyOn(adminApi, 'banUser').mockResolvedValue()
    const actionSpy = vi
      .spyOn(adminApi, 'invokeAdminAction')
      .mockResolvedValue({ ok: true })

    render(
      <MemoryRouter>
        <I18nProvider initialLang="en">
          <UsersPage admin={OWNER_ADMIN} />
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(screen.getByText('@linh_ielts')).toBeInTheDocument()
    })

    const user = userEvent.setup()
    await user.click(screen.getByRole('button', { name: /Inspect/i }))

    await waitFor(() => {
      expect(
        screen.getByRole('button', { name: /Ban \/ Suspend User/i }),
      ).toBeInTheDocument()
    })

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
  })
})
