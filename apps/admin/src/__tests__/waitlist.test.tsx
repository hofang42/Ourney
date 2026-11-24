import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { adminApi } from '../lib/adminRpc'
import { buildWaitlistCsv, sanitizeRawCsvString } from '../lib/csv'
import { I18nProvider } from '../lib/i18n'
import { WaitlistPage } from '../pages/WaitlistPage'
import {
  SQL_FIXTURE_MODERATOR,
  SQL_FIXTURE_OWNER,
  SQL_FIXTURE_WAITLIST_LIST,
  SQL_FIXTURE_WAITLIST_SUMMARY,
} from './fixtures'

describe('WaitlistPage & CSV Formula Injection Protection', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    vi.spyOn(adminApi, 'waitlistSummary').mockResolvedValue(
      SQL_FIXTURE_WAITLIST_SUMMARY,
    )
    vi.spyOn(adminApi, 'listWaitlist').mockResolvedValue(
      SQL_FIXTURE_WAITLIST_LIST,
    )
  })

  it('builds UTF-8 BOM CSV string and neutralizes formula injection prefixes (=, +, -, @, tab, cr, leading spaces)', () => {
    const csv = buildWaitlistCsv([
      {
        email: '=cmd|\' /C calc\'!A0@example.com',
        lang: 'vi',
        platforms: ['ios', 'android'],
        source: '  +HYPERLINK("http://evil")',
        created_at: '2026-11-24T05:12:00Z',
        confirmation_sent_at: '\t-2+3',
        registered_in_app: true,
      },
    ])
    expect(
      csv.startsWith(
        '\uFEFFemail,lang,platforms,source,created_at,confirmation_sent_at,registered_in_app',
      ),
    ).toBe(true)
    expect(csv).toContain("'=cmd|' /C calc'!A0@example.com")
    expect(csv).toContain('\'  +HYPERLINK(""http://evil"")')
    expect(csv).toContain("'\t-2+3")

    const rawFromSql =
      'email,lang,platforms,source,created_at,confirmation_sent_at,registered_in_app\n"=SUM(1,2)@example.com","vi","ios","@attacker","2026-11-24T05:12:00Z","","false"'
    const sanitized = sanitizeRawCsvString(rawFromSql)
    expect(sanitized).toContain("'=SUM(1,2)@example.com")
    expect(sanitized).toContain("'@attacker")
  })

  it('renders SQL waitlist_summary KPIs, triggers Resend retry, and hides owner-only Export/Delete for moderators', async () => {
    const actionSpy = vi
      .spyOn(adminApi, 'invokeAdminAction')
      .mockResolvedValue({ ok: true })
    const deleteSpy = vi
      .spyOn(adminApi, 'deleteWaitlistEntry')
      .mockResolvedValue()

    const { unmount } = render(
      <MemoryRouter>
        <I18nProvider initialLang="en">
          <WaitlistPage admin={SQL_FIXTURE_OWNER} />
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(
        screen.getByText('minh.nguyen@example.com'),
      ).toBeInTheDocument()
      expect(screen.getByText('VI: 1090')).toBeInTheDocument()
      expect(screen.getByText('1274')).toBeInTheDocument()
    })

    const user = userEvent.setup()
    await user.click(
      screen.getByRole('button', {
        name: /Resend minh\.nguyen@example\.com/i,
      }),
    )
    expect(actionSpy).toHaveBeenCalledWith({
      action: 'waitlist_resend',
      waitlist_id: 'wl-1',
    })

    await user.click(
      screen.getByRole('button', {
        name: /Delete minh\.nguyen@example\.com/i,
      }),
    )
    await user.click(screen.getByRole('button', { name: /Confirm Delete/i }))
    expect(deleteSpy).toHaveBeenCalledWith(
      'wl-1',
      'Removed by owner on request',
    )

    unmount()

    // Moderator RBAC check: Export CSV and Delete row buttons are hidden
    render(
      <MemoryRouter>
        <I18nProvider initialLang="en">
          <WaitlistPage admin={SQL_FIXTURE_MODERATOR} />
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(
        screen.getByText('minh.nguyen@example.com'),
      ).toBeInTheDocument()
    })
    expect(screen.queryByRole('button', { name: /Export CSV/i })).toBeNull()
    expect(
      screen.queryByRole('button', {
        name: /Delete minh\.nguyen@example\.com/i,
      }),
    ).toBeNull()
  })
})
