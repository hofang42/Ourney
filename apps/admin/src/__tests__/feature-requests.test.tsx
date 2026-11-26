import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import {
  adminApi,
  isFeatureRequestsNotInstalledError,
} from '../lib/adminRpc'
import { I18nProvider } from '../lib/i18n'
import { FeatureRequestsPage } from '../pages/FeatureRequestsPage'
import {
  SQL_FIXTURE_FILTER_PASS,
  SQL_FIXTURE_FR_DETAIL,
  SQL_FIXTURE_FR_LIST,
  SQL_FIXTURE_FR_STATS,
} from './fixtures'

describe('FeatureRequestsPage', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
  })

  it('renders graceful not-installed empty state without leaking migration numbers or PostgREST codes when RPC returns PGRST202 / 404', async () => {
    const notFoundErr = Object.assign(
      new Error('Could not find the function admin.list_feature_requests'),
      { code: 'PGRST202', status: 404 },
    )
    const constraintErr = Object.assign(
      new Error(
        'new row for relation "feature_requests" violates check constraint',
      ),
      { code: '23514' },
    )
    expect(isFeatureRequestsNotInstalledError(notFoundErr)).toBe(true)
    expect(isFeatureRequestsNotInstalledError(constraintErr)).toBe(false)

    vi.spyOn(adminApi, 'featureRequestStats').mockRejectedValue(notFoundErr)
    vi.spyOn(adminApi, 'listFeatureRequests').mockRejectedValue(notFoundErr)

    render(
      <MemoryRouter>
        <I18nProvider initialLang="vi">
          <FeatureRequestsPage />
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(
        screen.getByText(/Tính năng Đề xuất chưa được kích hoạt/i),
      ).toBeInTheDocument()
    })
    expect(screen.queryByText(/Migration 0024/i)).toBeNull()
    expect(screen.queryByText(/PGRST202/i)).toBeNull()
  })

  it('uses section 4.4B RPCs, deduplicates overlapping voter estimates on merge, supports content filter dry-run, and requires confirmation for Hide Request and Clear Reply (UX-28)', async () => {
    vi.spyOn(adminApi, 'featureRequestStats').mockResolvedValue(
      SQL_FIXTURE_FR_STATS,
    )
    vi.spyOn(adminApi, 'listFeatureRequests').mockResolvedValue(
      SQL_FIXTURE_FR_LIST,
    )
    vi.spyOn(adminApi, 'getFeatureRequestDetail').mockImplementation(
      async (id) => {
        if (id === 'fr-102') {
          return {
            ...SQL_FIXTURE_FR_LIST.items[1],
            merged_children: [],
            reports: [],
            voters: [
              {
                user_id: 'usr-10',
                username: 'linh_ielts',
                display_name: 'Linh Nguyễn',
                is_author: false,
                voted_at: '2026-11-15T08:00:00Z',
              },
            ],
          }
        }
        return SQL_FIXTURE_FR_DETAIL
      },
    )
    vi.spyOn(adminApi, 'testContentFilter').mockResolvedValue(
      SQL_FIXTURE_FILTER_PASS,
    )
    const updateSpy = vi
      .spyOn(adminApi, 'updateFeatureRequest')
      .mockResolvedValue()
    const mergeSpy = vi
      .spyOn(adminApi, 'mergeFeatureRequest')
      .mockResolvedValue()

    render(
      <MemoryRouter>
        <I18nProvider initialLang="en">
          <FeatureRequestsPage />
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(
        screen.getByRole('button', {
          name: /Save Update/i,
        }),
      ).toBeInTheDocument()
    })

    const user = userEvent.setup()
    await user.click(
      screen.getByRole('button', { name: /Check Content Filter/i }),
    )
    await waitFor(() => {
      expect(
        screen.getByText(/PASS: Reply text is clean/i),
      ).toBeInTheDocument()
    })

    await user.click(screen.getByRole('button', { name: /Save Update/i }))
    expect(updateSpy).toHaveBeenCalledWith({
      p_id: 'fr-101',
      p_status: 'planned',
      p_category: 'squad',
      p_admin_reply:
        'Đội ngũ Ourney đang thiết kế Widget Lock Screen cho bản iOS 1.1 vào tháng tới.',
      p_hidden: false,
      p_reason: null,
    })

    // UX-28: Hide Request requires confirmation modal and does NOT commit unsaved status draft
    updateSpy.mockClear()
    await user.selectOptions(
      screen.getByLabelText(/Select roadmap status/i),
      'declined',
    )
    await user.click(screen.getByRole('button', { name: /Hide Request/i }))
    expect(updateSpy).not.toHaveBeenCalled()
    expect(screen.getByRole('dialog')).toBeInTheDocument()
    await user.click(
      screen.getByRole('button', { name: /Confirm Hide Request/i }),
    )
    expect(updateSpy).toHaveBeenCalledWith({
      p_id: 'fr-101',
      p_status: 'planned',
      p_category: 'squad',
      p_admin_reply:
        'Đội ngũ Ourney đang thiết kế Widget Lock Screen cho bản iOS 1.1 vào tháng tới.',
      p_hidden: true,
      p_reason: 'Hidden from public roadmap via Admin Console',
    })

    // UX-28: Clear Reply requires confirmation modal
    updateSpy.mockClear()
    await user.click(screen.getByRole('button', { name: /Clear Reply/i }))
    expect(updateSpy).not.toHaveBeenCalled()
    expect(screen.getByRole('dialog')).toBeInTheDocument()
    await user.click(
      screen.getByRole('button', { name: /Confirm Clear Reply/i }),
    )
    expect(updateSpy).toHaveBeenCalledWith(
      expect.objectContaining({
        p_id: 'fr-101',
        p_admin_reply: null,
      }),
    )

    await user.click(
      screen.getByRole('button', { name: /Merge into Canonical Request/i }),
    )

    await user.selectOptions(
      screen.getByLabelText(/Select canonical target/i),
      'fr-102',
    )
    // 68 + 54 - 1 overlapping voter (usr-10) = 121 unique votes
    await waitFor(() => {
      expect(screen.getByText('121 votes')).toBeInTheDocument()
    })

    await user.click(screen.getByRole('button', { name: /Confirm Merge/i }))
    expect(mergeSpy).toHaveBeenCalledWith({
      p_source_id: 'fr-101',
      p_target_id: 'fr-102',
      p_reason: 'Merged duplicate request',
    })
  })

  it('refreshes detail state after Save Update so subsequent Hide Request or Clear Reply does not revert saved edits (F-15), and wires Visibility select on All Active tab + modal error inside dialog (F-42)', async () => {
    let currentDetail = { ...SQL_FIXTURE_FR_DETAIL }
    vi.spyOn(adminApi, 'featureRequestStats').mockResolvedValue(
      SQL_FIXTURE_FR_STATS,
    )
    const listSpy = vi
      .spyOn(adminApi, 'listFeatureRequests')
      .mockResolvedValue(SQL_FIXTURE_FR_LIST)
    const detailSpy = vi
      .spyOn(adminApi, 'getFeatureRequestDetail')
      .mockImplementation(async () => currentDetail)
    const updateSpy = vi
      .spyOn(adminApi, 'updateFeatureRequest')
      .mockImplementation(async (payload) => {
        currentDetail = {
          ...currentDetail,
          status: payload.p_status,
          category: payload.p_category,
          admin_reply: payload.p_admin_reply ?? null,
          hidden: payload.p_hidden,
        }
      })

    render(
      <MemoryRouter>
        <I18nProvider initialLang="en">
          <FeatureRequestsPage />
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(
        screen.getByRole('button', { name: /Save Update/i }),
      ).toBeInTheDocument()
    })

    const user = userEvent.setup()

    // F-42: Visibility select controls p_visibility on All Active tab
    const visSelect = screen.getByLabelText(/Filter visibility/i)
    expect(visSelect).not.toBeDisabled()
    await user.selectOptions(visSelect, 'all')
    await waitFor(() => {
      expect(listSpy).toHaveBeenLastCalledWith(
        expect.objectContaining({
          p_status: 'all_active',
          p_visibility: 'all',
        }),
      )
    })

    // F-42: Switching to Merged tab pins and disables Visibility select
    await user.click(screen.getByRole('tab', { name: /Merged Duplicates/i }))
    expect(visSelect).toBeDisabled()
    expect(visSelect).toHaveValue('merged')
    await user.click(screen.getByRole('tab', { name: /All Active/i }))
    expect(visSelect).not.toBeDisabled()

    // F-15: Save status = 'in_progress' and a new reply, then Hide Request must preserve 'in_progress' and new reply
    await user.selectOptions(
      screen.getByLabelText(/Select roadmap status/i),
      'in_progress',
    )
    const replyInput = screen.getByLabelText(/Official Ourney Public Reply/i)
    await user.clear(replyInput)
    await user.type(replyInput, 'Shipped in beta build 42')
    await user.click(screen.getByRole('button', { name: /Save Update/i }))

    await waitFor(() => {
      expect(updateSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          p_id: 'fr-101',
          p_status: 'in_progress',
          p_admin_reply: 'Shipped in beta build 42',
        }),
      )
      expect(detailSpy).toHaveBeenCalledWith('fr-101')
    })

    updateSpy.mockClear()
    await user.click(screen.getByRole('button', { name: /Hide Request/i }))
    await user.click(
      screen.getByRole('button', { name: /Confirm Hide Request/i }),
    )

    expect(updateSpy).toHaveBeenCalledWith({
      p_id: 'fr-101',
      p_status: 'in_progress',
      p_category: 'squad',
      p_admin_reply: 'Shipped in beta build 42',
      p_hidden: true,
      p_reason: 'Hidden from public roadmap via Admin Console',
    })

    // F-42: Failed modal RPC renders error alert inside open modal dialog
    updateSpy.mockRejectedValueOnce(
      Object.assign(new Error('rate_limited'), { code: 'P0001' }),
    )
    await user.click(screen.getByRole('button', { name: /Clear Reply/i }))
    await user.click(
      screen.getByRole('button', { name: /Confirm Clear Reply/i }),
    )
    await waitFor(() => {
      const dialog = screen.getByRole('dialog')
      expect(dialog).toHaveTextContent(/Rate limit exceeded/i)
    })
  })
})
