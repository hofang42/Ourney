import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import {
  adminApi,
  DEMO_FEATURE_REQUEST_STATS,
  DEMO_OVERVIEW,
} from '../lib/adminRpc'
import { I18nProvider, useI18n } from '../lib/i18n'
import { OverviewPage } from '../pages/OverviewPage'

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
    vi.spyOn(adminApi, 'overviewStats').mockResolvedValue(DEMO_OVERVIEW)
    vi.spyOn(adminApi, 'featureRequestStats').mockResolvedValue(
      DEMO_FEATURE_REQUEST_STATS,
    )
  })

  it('renders KPI cards including New Feature Requests (7d), Top Voted card, urgent 24h SLA banner, and SVG charts', async () => {
    render(
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

    expect(screen.getByText(/New Feature Requests \(7d\)/i)).toBeInTheDocument()
    expect(screen.getByText('+11')).toBeInTheDocument()
    expect(screen.getByText(/Top Voted Feature Requests/i)).toBeInTheDocument()
    expect(screen.getByText(/7-Day Activation Funnel/i)).toBeInTheDocument()
    expect(screen.getByText(/Weekly Cohort Retention/i)).toBeInTheDocument()

    const user = userEvent.setup()
    await user.click(screen.getByRole('button', { name: /Switch Theme/i }))
    expect(document.documentElement.dataset.theme).toBe('dark')
  })
})
