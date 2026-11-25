import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { adminApi } from '../lib/adminRpc'
import { I18nProvider } from '../lib/i18n'
import { ModerationPage } from '../pages/ModerationPage'
import {
  SQL_FIXTURE_MODERATION_DETAIL,
  SQL_FIXTURE_MODERATION_QUEUE,
  SQL_FIXTURE_REVEAL_MEDIA,
} from './fixtures'

describe('ModerationPage & Action Gating (UX-28)', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    vi.spyOn(adminApi, 'listModerationQueue').mockResolvedValue(
      SQL_FIXTURE_MODERATION_QUEUE,
    )
    vi.spyOn(adminApi, 'getModerationItem').mockImplementation(async (id) => {
      if (id === 'mq-02') {
        return {
          ...SQL_FIXTURE_MODERATION_DETAIL,
          id: 'mq-02',
          kind: 'block',
          reason: null,
          target_checkin_id: null,
          target_message_id: null,
          target_user: null,
          reported_content: {
            target_type: 'user',
            user_id: 'usr-92',
          },
        }
      }
      return SQL_FIXTURE_MODERATION_DETAIL
    })
  })

  it('displays server summary KPIs, 24h SLA countdown, gated Reveal Reported Media flow, disables Remove Content on user-only reports with tooltip, and gates resolved reports behind Reopen Review (UX-28)', async () => {
    const revealSpy = vi
      .spyOn(adminApi, 'revealReportedMedia')
      .mockResolvedValue(SQL_FIXTURE_REVEAL_MEDIA)
    const resolveSpy = vi
      .spyOn(adminApi, 'resolveModeration')
      .mockResolvedValue()

    const { unmount } = render(
      <MemoryRouter>
        <I18nProvider initialLang="en">
          <ModerationPage />
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(screen.getByText(/3h 24m left/i)).toBeInTheDocument()
      expect(
        screen.getByText('Reported check-in caption text only'),
      ).toBeInTheDocument()
      expect(screen.getByText(/Median handle 30d: 1\.45h/i)).toBeInTheDocument()
    })

    const user = userEvent.setup()
    const revealBtn = screen.getByRole('button', {
      name: /Reveal Reported Media/i,
    })
    await user.click(revealBtn)

    expect(revealSpy).toHaveBeenCalledWith(
      'mq-01',
      '24h SLA moderation inspection',
    )

    await waitFor(() => {
      const img = screen.getByAltText(/Reported media/i)
      expect(img).toHaveClass('blurred')
    })

    // Open modal and test Escape dismissal
    await user.click(screen.getByRole('button', { name: /Remove Content/i }))
    expect(screen.getByRole('dialog')).toBeInTheDocument()
    await user.keyboard('{Escape}')
    expect(screen.queryByRole('dialog')).toBeNull()

    // Reopen and confirm action
    await user.click(screen.getByRole('button', { name: /Remove Content/i }))
    await user.type(
      screen.getByPlaceholderText(/Enter resolution reason/i),
      'Confirmed harassment violation',
    )
    await user.click(screen.getByRole('button', { name: /Confirm Action/i }))

    expect(resolveSpy).toHaveBeenCalledWith(
      'mq-01',
      'remove_content',
      'Confirmed harassment violation',
    )

    // Keyboard select 2nd row (user block with target_type === 'user')
    const rows = screen.getAllByRole('row')
    rows[2].focus()
    await user.keyboard('{Enter}')

    await waitFor(() => {
      // Quarantine button is hidden for user-only targets (0023_admin.sql:2262)
      expect(
        screen.queryByRole('button', { name: /Quarantine Target/i }),
      ).toBeNull()
      // UX-28: Remove Content is disabled with tooltip reason on user-only reports
      const removeBtn = screen.getByRole('button', { name: /Remove Content/i })
      expect(removeBtn).toBeDisabled()
      expect(removeBtn).toHaveAttribute(
        'title',
        expect.stringMatching(/no individual content item to remove/i),
      )
    })

    unmount()

    // UX-28: Already-resolved ('actioned') report disables all moderation buttons until Reopen Review is clicked,
    // and keeps Dismiss disabled even after reopening an actioned report.
    vi.spyOn(adminApi, 'getModerationItem').mockResolvedValueOnce({
      ...SQL_FIXTURE_MODERATION_DETAIL,
      status: 'actioned',
      handled_at: '2026-11-24T08:00:00Z',
      resolution_note: 'Prior takedown',
    })

    render(
      <MemoryRouter>
        <I18nProvider initialLang="en">
          <ModerationPage />
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(
        screen.getByRole('button', { name: /Reopen Review/i }),
      ).toBeInTheDocument()
    })
    expect(screen.getByRole('button', { name: /Dismiss Report/i })).toBeDisabled()
    expect(screen.getByRole('button', { name: /Remove Content/i })).toBeDisabled()
    expect(
      screen.getByRole('button', { name: /Ban User & Wipe Content/i }),
    ).toBeDisabled()

    await user.click(screen.getByRole('button', { name: /Reopen Review/i }))
    // Dismiss stays disabled on an already-actioned item
    expect(screen.getByRole('button', { name: /Dismiss Report/i })).toBeDisabled()
    expect(
      screen.getByRole('button', { name: /Ban User & Wipe Content/i }),
    ).not.toBeDisabled()
  })

  it('supports feature_request moderation targets (title + body excerpt, Quarantine Target button) and hides dead-end Reopen Review when report is already fully actioned (ban_user + content removed)', async () => {
    const quarantineSpy = vi
      .spyOn(adminApi, 'quarantineModerationTarget')
      .mockResolvedValue()

    vi.spyOn(adminApi, 'getModerationItem').mockResolvedValueOnce({
      ...SQL_FIXTURE_MODERATION_DETAIL,
      id: 'mq-fr-1',
      target_checkin_id: null,
      target_message_id: null,
      target_feature_request_id: 'fr-101',
      reported_content: {
        target_type: 'feature_request',
        feature_request_id: 'fr-101',
        title: 'Reported Feature Title',
        body: 'Reported feature request body text',
        caption: 'Reported Feature Title\n\nReported feature request body text',
        category: 'squad',
        status: 'new',
        hidden: false,
        moderated_at: null,
      },
    })

    const { unmount } = render(
      <MemoryRouter>
        <I18nProvider initialLang="en">
          <ModerationPage />
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(
        screen.getByText(/Reported Feature Title/i),
      ).toBeInTheDocument()
      expect(
        screen.getByText(/Reported feature request body text/i),
      ).toBeInTheDocument()
    })

    const quarantineBtn = screen.getByRole('button', {
      name: /Quarantine Target/i,
    })
    expect(quarantineBtn).not.toBeDisabled()

    const user = userEvent.setup()
    await user.click(quarantineBtn)
    await user.click(screen.getByRole('button', { name: /Confirm Action/i }))
    expect(quarantineSpy).toHaveBeenCalledWith('mq-01', null)

    unmount()

    // Terminal state: status = 'actioned', content removed (deleted_at set), and target_user.is_banned = true
    vi.spyOn(adminApi, 'getModerationItem').mockResolvedValueOnce({
      ...SQL_FIXTURE_MODERATION_DETAIL,
      status: 'actioned',
      handled_at: '2026-11-24T08:00:00Z',
      resolution_note: 'Action ban_user executed by operator',
      target_user: {
        ...SQL_FIXTURE_MODERATION_DETAIL.target_user!,
        is_banned: true,
      },
      reported_content: {
        ...(SQL_FIXTURE_MODERATION_DETAIL.reported_content as Extract<
          typeof SQL_FIXTURE_MODERATION_DETAIL.reported_content,
          { target_type: 'checkin' }
        >),
        deleted_at: '2026-11-24T08:00:00Z',
        moderated_at: '2026-11-24T08:00:00Z',
      },
    })

    render(
      <MemoryRouter>
        <I18nProvider initialLang="en">
          <ModerationPage />
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(
        screen.getByText(/All available actions have already been applied/i),
      ).toBeInTheDocument()
    })
    expect(
      screen.queryByRole('button', { name: /Reopen Review/i }),
    ).toBeNull()
  })
})
