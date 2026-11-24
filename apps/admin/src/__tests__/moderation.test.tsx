import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { adminApi, DEMO_MODERATION_QUEUE } from '../lib/adminRpc'
import { I18nProvider } from '../lib/i18n'
import { ModerationPage } from '../pages/ModerationPage'

describe('ModerationPage', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    vi.spyOn(adminApi, 'listModerationQueue').mockResolvedValue(
      DEMO_MODERATION_QUEUE,
    )
    vi.spyOn(adminApi, 'getModerationItem').mockResolvedValue({
      queue: DEMO_MODERATION_QUEUE[0],
      target_user: {
        user_id: 'usr-88',
        username: 'hung_gym99',
        display_name: 'Hung',
        created_at: '2026-10-15T08:00:00Z',
        prior_actioned_reports: 1,
        blocked_by_count: 2,
        is_banned: false,
      },
      excerpt: {
        target_type: 'checkin',
        title: null,
        body: 'Reported check-in caption text only',
        extra_note: null,
        created_at: '2026-11-23T17:10:00Z',
      },
      has_reported_media: true,
      media_objects: [
        {
          bucket_id: 'media',
          object_path: 'checkins/j1/usr-88/chk-901.jpg',
          label: 'checkin_photo_path',
        },
      ],
      sibling_reports: [
        {
          id: 'rep-1',
          reporter_username: 'linh_ielts',
          reason: 'harassment',
          note: 'Harassing note',
          created_at: '2026-11-23T17:10:00Z',
        },
      ],
    })
  })

  it('displays 24h SLA countdown, gated Reveal Reported Media flow, and resolution modal', async () => {
    const revealSpy = vi
      .spyOn(adminApi, 'revealReportedMedia')
      .mockResolvedValue([
        {
          bucket_id: 'media',
          object_path: 'checkins/j1/usr-88/chk-901.jpg',
          expires_at: '2026-11-24T15:00:00Z',
          signed_url: 'https://example.supabase.co/storage/v1/object/sign/media/test.jpg',
        },
      ])
    const resolveSpy = vi.spyOn(adminApi, 'resolveModeration').mockResolvedValue()

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
  })
})
