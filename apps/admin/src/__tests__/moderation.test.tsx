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

describe('ModerationPage', () => {
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

  it('displays server summary KPIs, 24h SLA countdown, gated Reveal Reported Media flow, keyboard row navigation, and Escape modal close', async () => {
    const revealSpy = vi
      .spyOn(adminApi, 'revealReportedMedia')
      .mockResolvedValue(SQL_FIXTURE_REVEAL_MEDIA)
    const resolveSpy = vi
      .spyOn(adminApi, 'resolveModeration')
      .mockResolvedValue()

    render(
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

    // Keyboard select 2nd row (user block with target_type === 'user' and null target_user)
    const rows = screen.getAllByRole('row')
    rows[2].focus()
    await user.keyboard('{Enter}')

    await waitFor(() => {
      // Quarantine button is hidden for user-only targets (0023_admin.sql:2262)
      expect(
        screen.queryByRole('button', { name: /Quarantine Target/i }),
      ).toBeNull()
    })
  })
})
