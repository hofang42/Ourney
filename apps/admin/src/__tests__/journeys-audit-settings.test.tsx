import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { adminApi } from '../lib/adminRpc'
import { I18nProvider } from '../lib/i18n'
import { AuditPage } from '../pages/AuditPage'
import { JourneysPage } from '../pages/JourneysPage'
import { SettingsPage } from '../pages/SettingsPage'
import {
  SQL_FIXTURE_AUDIT_LIST,
  SQL_FIXTURE_JOURNEYS_LIST,
  SQL_FIXTURE_JOURNEY_STATS,
  SQL_FIXTURE_MODERATOR,
  SQL_FIXTURE_OWNER,
  SQL_FIXTURE_SYSTEM_HEALTH,
} from './fixtures'

describe('JourneysPage, AuditPage, and SettingsPage', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
  })

  it('renders JourneysPage with SQL journey_stats, human redacted private titles, compact Open public page CTA, null max_members on solo journeys, and public link revocation (UX-42)', async () => {
    vi.spyOn(adminApi, 'journeyStats').mockResolvedValue(
      SQL_FIXTURE_JOURNEY_STATS,
    )
    vi.spyOn(adminApi, 'listJourneys').mockResolvedValue(
      SQL_FIXTURE_JOURNEYS_LIST,
    )
    const revokeSpy = vi
      .spyOn(adminApi, 'revokeJourneyPublicLink')
      .mockResolvedValue()

    render(
      <MemoryRouter>
        <I18nProvider initialLang="en">
          <JourneysPage />
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(screen.getByText('612 / 144 / 39')).toBeInTheDocument()
      expect(screen.getByText('47 (3890 views)')).toBeInTheDocument()
      expect(
        screen.getByText('30 Ngày Cày IELTS 7.5 Cùng Squad'),
      ).toBeInTheDocument()
      expect(
        screen.getByText('[Private Journey — Title Hidden]'),
      ).toBeInTheDocument()
      expect(
        screen.getByRole('link', { name: /Open public page/i }),
      ).toHaveAttribute('href', 'https://ourney.tech/p/pub_ielts_30d')
      // Solo journey with max_members: null renders "1 · 21 snaps" (not "1/")
      expect(screen.getByText('1 · 21 snaps')).toBeInTheDocument()
    })

    const user = userEvent.setup()
    await user.click(
      screen.getByRole('button', { name: /Revoke Link jrn-01/i }),
    )
    await user.type(
      screen.getByPlaceholderText(/Public link reported for abuse/i),
      'Abusive public share token',
    )
    await user.click(screen.getByRole('button', { name: /Confirm Revoke/i }))

    expect(revokeSpy).toHaveBeenCalledWith(
      'jrn-01',
      'Abusive public share token',
    )
  })

  it('renders AuditPage with localized action and target labels, formatted timestamps, keyset pagination (next_before_id), and JSON copy (UX-42)', async () => {
    const listSpy = vi
      .spyOn(adminApi, 'listAuditLog')
      .mockResolvedValueOnce({
        items: SQL_FIXTURE_AUDIT_LIST.items,
        next_before_id: 1041,
      })
      .mockResolvedValueOnce({
        items: [SQL_FIXTURE_AUDIT_LIST.items[1]],
        next_before_id: null,
      })

    render(
      <MemoryRouter>
        <I18nProvider initialLang="en">
          <AuditPage />
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(screen.getByText('#1042')).toBeInTheDocument()
      expect(screen.getByText('Update Feature Request')).toBeInTheDocument()
    })

    const user = userEvent.setup()
    await user.click(
      screen.getByRole('button', { name: /Load Older Entries/i }),
    )
    expect(listSpy).toHaveBeenLastCalledWith(
      expect.objectContaining({ p_before_id: 1041 }),
    )
  })

  it('renders SettingsPage with SQL system_health (moderation_notifications & sample_errors), ops triggers, and admin removal confirmation modal', async () => {
    vi.spyOn(adminApi, 'listAdmins').mockResolvedValue([
      SQL_FIXTURE_OWNER,
      SQL_FIXTURE_MODERATOR,
    ])
    vi.spyOn(adminApi, 'systemHealth').mockResolvedValue(
      SQL_FIXTURE_SYSTEM_HEALTH,
    )
    const actionSpy = vi
      .spyOn(adminApi, 'invokeAdminAction')
      .mockResolvedValue({ ok: true })
    const removeSpy = vi
      .spyOn(adminApi, 'removeAdminUser')
      .mockResolvedValue()

    render(
      <MemoryRouter>
        <I18nProvider initialLang="en">
          <SettingsPage admin={SQL_FIXTURE_OWNER} />
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(
        screen.getByText(/Storage 503 temporary timeout/i),
      ).toBeInTheDocument()
      expect(screen.getByText('mod@ourney.tech')).toBeInTheDocument()
    })

    const user = userEvent.setup()
    await user.click(
      screen.getByRole('button', { name: /Run Storage Purge Sweep Now/i }),
    )
    expect(actionSpy).toHaveBeenCalledWith({ action: 'run_storage_sweep' })

    await user.click(
      screen.getByRole('button', {
        name: /Trigger Moderation Notification Digest/i,
      }),
    )
    expect(actionSpy).toHaveBeenCalledWith({
      action: 'trigger_moderation_notify',
    })

    // Click Remove on moderator -> opens confirmation modal first
    await user.click(
      screen.getByRole('button', { name: /Remove mod@ourney\.tech/i }),
    )
    expect(screen.getByRole('dialog')).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: /Confirm Remove/i }))
    expect(removeSpy).toHaveBeenCalledWith(
      SQL_FIXTURE_MODERATOR.user_id,
      'Removed from Settings page',
    )
  })
})
