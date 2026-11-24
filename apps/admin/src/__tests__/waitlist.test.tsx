import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { adminApi, type AdminIdentity } from '../lib/adminRpc'
import { buildWaitlistCsv } from '../lib/csv'
import { I18nProvider } from '../lib/i18n'
import { WaitlistPage } from '../pages/WaitlistPage'

const OWNER_ADMIN: AdminIdentity = {
  user_id: 'uid-1',
  email: 'owner@ourney.tech',
  role: 'owner',
  username: 'hoang',
  display_name: 'Hoang',
  note: null,
}

describe('WaitlistPage & CSV Export', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    vi.spyOn(adminApi, 'waitlistSummary').mockResolvedValue({
      total: 2,
      ios_only: 1,
      android_only: 0,
      both_platforms: 1,
      vi_count: 1,
      en_count: 1,
      sent_count: 1,
      failed_count: 1,
      unsent_count: 0,
      converted_count: 1,
      top_sources: [{ source: 'landing_hero', count: 2 }],
      daily: [{ day: '24/11', vi: 1, en: 1 }],
    })
    vi.spyOn(adminApi, 'listWaitlist').mockResolvedValue([
      {
        id: 'wl-1',
        email: 'minh@example.com',
        lang: 'vi',
        platforms: ['ios'],
        source: 'landing_hero',
        created_at: '2026-11-24T05:12:00Z',
        confirmation_sent_at: '2026-11-24T05:12:03Z',
        confirmation_error: null,
        registered_in_app: true,
      },
    ])
  })

  it('builds UTF-8 BOM CSV string with exact columns', () => {
    const csv = buildWaitlistCsv([
      {
        email: 'minh@example.com',
        lang: 'vi',
        platforms: ['ios', 'android'],
        source: 'landing_hero',
        created_at: '2026-11-24T05:12:00Z',
        confirmation_sent_at: '2026-11-24T05:12:03Z',
        registered_in_app: true,
      },
    ])
    expect(csv.startsWith('\uFEFFemail,lang,platforms,source,created_at,confirmation_sent_at,registered_in_app')).toBe(true)
    expect(csv).toContain('minh@example.com,vi,ios|android,landing_hero')
  })

  it('triggers Resend retry and delete confirmation on WaitlistPage', async () => {
    const actionSpy = vi
      .spyOn(adminApi, 'invokeAdminAction')
      .mockResolvedValue({ ok: true })
    const deleteSpy = vi
      .spyOn(adminApi, 'deleteWaitlistEntry')
      .mockResolvedValue()

    render(
      <MemoryRouter>
        <I18nProvider initialLang="en">
          <WaitlistPage admin={OWNER_ADMIN} />
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(screen.getByText('minh@example.com')).toBeInTheDocument()
    })

    const user = userEvent.setup()
    await user.click(screen.getByRole('button', { name: /Resend/i }))
    expect(actionSpy).toHaveBeenCalledWith({
      action: 'waitlist_resend',
      waitlist_id: 'wl-1',
    })

    await user.click(screen.getByRole('button', { name: /^Delete$/i }))
    await user.click(screen.getByRole('button', { name: /Confirm Delete/i }))
    expect(deleteSpy).toHaveBeenCalledWith(
      'wl-1',
      'Removed by owner on request',
    )
  })
})
