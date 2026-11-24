import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import {
  adminApi,
  DEMO_FEATURE_REQUEST_STATS,
  DEMO_FEATURE_REQUESTS,
} from '../lib/adminRpc'
import { I18nProvider } from '../lib/i18n'
import { FeatureRequestsPage } from '../pages/FeatureRequestsPage'

describe('FeatureRequestsPage', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
  })

  it('renders graceful not-installed empty state when RPC returns PGRST202 / 404', async () => {
    const notFoundErr = Object.assign(
      new Error('Could not find the function admin.list_feature_requests'),
      { code: 'PGRST202', status: 404 },
    )
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
        screen.getByText(/Tính năng Đề xuất chưa cài đặt \(Migration 0024\)/i),
      ).toBeInTheDocument()
    })
  })

  it('uses section 4.4B RPCs (feature_request_stats, list_feature_requests, get_feature_request_detail, update_feature_request, merge_feature_request) with no tags and no unmerge', async () => {
    vi.spyOn(adminApi, 'featureRequestStats').mockResolvedValue(
      DEMO_FEATURE_REQUEST_STATS,
    )
    vi.spyOn(adminApi, 'listFeatureRequests').mockResolvedValue(
      DEMO_FEATURE_REQUESTS,
    )
    vi.spyOn(adminApi, 'getFeatureRequestDetail').mockResolvedValue({
      ...DEMO_FEATURE_REQUESTS[0],
      merged_children: [],
      reports: [],
      voters: [
        {
          user_id: 'usr-10',
          username: 'linh_ielts',
          display_name: 'Linh Nguyen',
          is_author: true,
          voted_at: '2026-11-12T08:00:00Z',
        },
      ],
    })
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

    // F1 & A3: No unmerge button and no tags input
    expect(screen.queryByRole('button', { name: /unmerge/i })).toBeNull()
    expect(screen.queryByPlaceholderText(/quick-win/i)).toBeNull()

    const user = userEvent.setup()
    await user.click(screen.getByRole('button', { name: /Save Update/i }))
    expect(updateSpy).toHaveBeenCalledWith({
      p_id: 'fr-101',
      p_status: 'planned',
      p_category: 'squad',
      p_admin_reply:
        'Đội ngũ Ourney đang thiết kế Widget Lock Screen cho bản iOS 1.1 vào tháng tới.',
      p_hidden: false,
      p_reason: 'Updated status=planned, category=squad, hidden=false',
    })

    await user.click(
      screen.getByRole('button', { name: /Merge into Canonical Request/i }),
    )

    await user.selectOptions(
      screen.getByLabelText(/Select canonical target/i),
      'fr-102',
    )
    expect(
      screen.getByText(/Estimated Net Unique Votes after merge:/i),
    ).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: /Confirm Merge/i }))
    expect(mergeSpy).toHaveBeenCalledWith({
      p_source_id: 'fr-101',
      p_target_id: 'fr-102',
      p_reason: 'Merged duplicate request',
    })
  })
})
