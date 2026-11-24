import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { adminApi } from '../lib/adminRpc'
import { I18nProvider, useI18n } from '../lib/i18n'
import { OverviewPage } from '../pages/OverviewPage'
import { SQL_FIXTURE_FR_STATS, SQL_FIXTURE_OVERVIEW } from './fixtures'

function ThemeHarness() {
  const { theme, toggleTheme } = useI18n()
  return (
    <div>
      <button type="button" onClick={toggleTheme}>
        Switch Theme ({theme})
      </button>
      <OverviewPage />
    </div>
  )
}

describe('OverviewPage', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
  })

  it('renders SQL-shaped overview_stats KPIs, urgent SLA banner, and SVG bars with zero NaN attributes', async () => {
    vi.spyOn(adminApi, 'overviewStats').mockResolvedValue(SQL_FIXTURE_OVERVIEW)
    vi.spyOn(adminApi, 'featureRequestStats').mockResolvedValue(
      SQL_FIXTURE_FR_STATS,
    )

    const { container } = render(
      <MemoryRouter>
        <I18nProvider initialLang="en" initialTheme="light">
          <ThemeHarness />
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(
        screen.getByText(/2 open moderation reports/i),
      ).toBeInTheDocument()
    })

    expect(screen.getByText('482')).toBeInTheDocument()
    expect(screen.getByText('1280')).toBeInTheDocument()
    expect(screen.getByText(/New Feature Requests \(7d\)/i)).toBeInTheDocument()
    expect(screen.getByText('+11')).toBeInTheDocument()
    expect(screen.getByText(/Top Voted Feature Requests/i)).toBeInTheDocument()
    expect(screen.getByText(/7-Day Activation Funnel/i)).toBeInTheDocument()
    expect(screen.getByText(/Posted 1st Check-in/i)).toBeInTheDocument()
    expect(screen.getByText(/Weekly Cohort Retention/i)).toBeInTheDocument()

    const rects = Array.from(container.querySelectorAll('svg rect'))
    expect(rects.length).toBeGreaterThan(5)
    for (const rect of rects) {
      expect(rect.getAttribute('y')).not.toContain('NaN')
      expect(rect.getAttribute('height')).not.toContain('NaN')
    }

    const user = userEvent.setup()
    await user.click(screen.getByRole('button', { name: /Switch Theme/i }))
    expect(document.documentElement.dataset.theme).toBe('dark')
  })

  it('renders clean zero/uninstalled state when Migration 0024 is absent (kpis.feature_requests: null)', async () => {
    vi.spyOn(adminApi, 'overviewStats').mockResolvedValue({
      ...SQL_FIXTURE_OVERVIEW,
      alerts: {
        ...SQL_FIXTURE_OVERVIEW.alerts,
        untriaged_feature_requests: 0,
      },
      kpis: {
        ...SQL_FIXTURE_OVERVIEW.kpis,
        feature_requests: null,
      },
    })
    vi.spyOn(adminApi, 'featureRequestStats').mockRejectedValue(
      Object.assign(new Error('Could not find the function'), {
        code: 'PGRST202',
      }),
    )

    render(
      <MemoryRouter>
        <I18nProvider initialLang="en">
          <OverviewPage />
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(
        screen.getByText(
          /Feature requests table not installed yet \(Migration 0024\)/i,
        ),
      ).toBeInTheDocument()
    })
  })
})
