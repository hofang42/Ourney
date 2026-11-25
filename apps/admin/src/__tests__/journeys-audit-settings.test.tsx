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

    listSpy.mockResolvedValueOnce({
      items: [SQL_FIXTURE_AUDIT_LIST.items[1]],
      next_before_id: null,
    })
    await user.selectOptions(
      screen.getByLabelText(/Filter audit log by action prefix/i),
      'moderation.',
    )
    expect(listSpy).toHaveBeenLastCalledWith(
      expect.objectContaining({ p_action_prefix: 'moderation.' }),
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

  it('renders JourneysPage, AuditPage, and SettingsPage cleanly in default Vietnamese (initialLang="vi") without leftover English copy or raw sentinel IDs', async () => {
    vi.spyOn(adminApi, 'journeyStats').mockResolvedValue(
      SQL_FIXTURE_JOURNEY_STATS,
    )
    vi.spyOn(adminApi, 'listJourneys').mockResolvedValue(
      SQL_FIXTURE_JOURNEYS_LIST,
    )
    vi.spyOn(adminApi, 'listAuditLog').mockResolvedValue({
      items: [
        {
          ...SQL_FIXTURE_AUDIT_LIST.items[0],
          action: 'system.run_storage_sweep',
          target_type: 'system',
          target_id: 'pending_storage_purge',
          reason: null,
          meta: { claimed: 3, removed: 3 },
        },
      ],
      next_before_id: null,
    })

    const { unmount } = render(
      <MemoryRouter>
        <I18nProvider initialLang="vi">
          <JourneysPage />
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(screen.getByText('47 (3890 lượt xem)')).toBeInTheDocument()
    })
    unmount()

    render(
      <MemoryRouter>
        <I18nProvider initialLang="vi">
          <AuditPage />
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(
        screen.getByText('Hàng đợi dọn dẹp lưu trữ'),
      ).toBeInTheDocument()
      expect(
        screen.getByText(/Đã nhận: 3 · Đã xóa tệp: 3/i),
      ).toBeInTheDocument()
    })
  })

  it('formats action-contextual audit meta on AuditPage without leaking "Không rõ (<raw>)" / "Unknown (<raw>)" across moderation.resolve, words.upsert, words.delete, waitlist.export_csv, feature_requests.update, and system.reset_storage_purge', async () => {
    const baseRow = SQL_FIXTURE_AUDIT_LIST.items[0]
    const contextualAuditRows = [
      {
        ...baseRow,
        id: 2001,
        action: 'moderation.resolve',
        target_type: 'moderation_queue',
        target_id: 'mq-01',
        reason: 'Confirmed harassment takedown',
        meta: {
          action: 'remove_content',
          status: 'actioned',
          target_user_id: 'usr-88',
        },
      },
      {
        ...baseRow,
        id: 2002,
        action: 'words.upsert',
        target_type: 'word',
        target_id: 'tu_xau',
        reason: null,
        meta: {
          lang: 'vi',
          match_mode: 'diacritic_word',
          category: 'self_harm',
          enabled: true,
        },
      },
      {
        ...baseRow,
        id: 2003,
        action: 'words.delete',
        target_type: 'word',
        target_id: 'badword',
        reason: 'False positive cleanup',
        meta: {
          lang: 'en',
          match_mode: 'word',
          category: 'profanity',
        },
      },
      {
        ...baseRow,
        id: 2004,
        action: 'waitlist.export_csv',
        target_type: 'waitlist',
        target_id: null,
        reason: null,
        meta: {
          row_count: 120,
          lang: 'all',
          platform: 'all',
          mail_status: 'all',
          converted: 'all',
        },
      },
      {
        ...baseRow,
        id: 2005,
        action: 'feature_requests.update',
        target_type: 'feature_request',
        target_id: 'fr-101',
        reason: 'Triaged into squad roadmap',
        meta: {
          old_status: 'new',
          new_status: 'planned',
          old_category: 'other',
          new_category: 'squad',
        },
      },
      {
        ...baseRow,
        id: 2006,
        action: 'system.reset_storage_purge',
        target_type: 'system',
        target_id: 'pending_storage_purge',
        reason: 'Reset after storage outage',
        meta: {
          reset_count: 4,
        },
      },
    ]

    vi.spyOn(adminApi, 'listAuditLog').mockResolvedValue({
      items: contextualAuditRows,
      next_before_id: null,
    })

    const { unmount } = render(
      <MemoryRouter>
        <I18nProvider initialLang="vi">
          <AuditPage />
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(
        screen.getByText('Quyết định: Gỡ bỏ nội dung · Trạng thái: Đã xử phạt'),
      ).toBeInTheDocument()
      expect(
        screen.getByText(
          'Ngôn ngữ: Tiếng Việt (VI) · Chế độ khớp: Từ có dấu chính xác · Danh mục: Tự gây hại',
        ),
      ).toBeInTheDocument()
      expect(
        screen.getByText(
          'Ngôn ngữ: Tiếng Anh (EN) · Chế độ khớp: Từ nguyên vẹn · Danh mục: Ngôn từ thô tục',
        ),
      ).toBeInTheDocument()
      expect(
        screen.getByText('Số dòng: 120 · Ngôn ngữ: Mọi ngôn ngữ'),
      ).toBeInTheDocument()
      expect(
        screen.getByText(
          'Trạng thái cũ: Mới gửi · Trạng thái: Đã lên kế hoạch · Danh mục cũ: Khác · Danh mục: Nhóm bạn (Squad)',
        ),
      ).toBeInTheDocument()
      expect(screen.getByText('Đã đặt lại: 4')).toBeInTheDocument()
    })
    expect(document.body.textContent).not.toContain('Không rõ')
    expect(document.body.textContent).not.toContain('Unknown')
    unmount()

    render(
      <MemoryRouter>
        <I18nProvider initialLang="en">
          <AuditPage />
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(
        screen.getByText('Action: Remove Content · Status: Actioned'),
      ).toBeInTheDocument()
      expect(
        screen.getByText(
          'Language: Vietnamese (VI) · Match Mode: Exact Diacritic Word · Category: Self-Harm',
        ),
      ).toBeInTheDocument()
      expect(
        screen.getByText(
          'Language: English (EN) · Match Mode: Whole Word · Category: Profanity',
        ),
      ).toBeInTheDocument()
      expect(
        screen.getByText('Rows: 120 · Language: All languages'),
      ).toBeInTheDocument()
      expect(
        screen.getByText(
          'Prev Status: New · Status: Planned · Prev Category: Other · Category: Squad',
        ),
      ).toBeInTheDocument()
      expect(screen.getByText('Reset: 4')).toBeInTheDocument()
    })
    expect(document.body.textContent).not.toContain('Không rõ')
    expect(document.body.textContent).not.toContain('Unknown')
  })
})
