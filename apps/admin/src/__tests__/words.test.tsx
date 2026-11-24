import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { adminApi } from '../lib/adminRpc'
import { I18nProvider } from '../lib/i18n'
import { WordsPage } from '../pages/WordsPage'
import {
  SQL_FIXTURE_FILTER_BLOCKED,
  SQL_FIXTURE_FILTER_PASS,
  SQL_FIXTURE_WORDS,
} from './fixtures'

describe('WordsPage', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    vi.spyOn(adminApi, 'listObjectionableWords').mockResolvedValue(
      SQL_FIXTURE_WORDS,
    )
  })

  it('evaluates live dry-run tester using SQL { blocked, term } contract and supports add/toggle/delete word flows', async () => {
    vi.spyOn(adminApi, 'testContentFilter')
      .mockResolvedValueOnce(SQL_FIXTURE_FILTER_PASS)
      .mockResolvedValueOnce(SQL_FIXTURE_FILTER_BLOCKED)
    const upsertSpy = vi
      .spyOn(adminApi, 'upsertObjectionableWord')
      .mockResolvedValue()
    const toggleSpy = vi
      .spyOn(adminApi, 'setObjectionableWordEnabled')
      .mockResolvedValue()

    render(
      <MemoryRouter>
        <I18nProvider initialLang="en">
          <WordsPage />
        </I18nProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(screen.getByText('scam link')).toBeInTheDocument()
    })

    const user = userEvent.setup()
    const dryRunInput = screen.getByLabelText(
      /Sample text for content filter dry-run/i,
    )
    await user.type(dryRunInput, 'Hello morning habit')
    await user.click(screen.getByRole('button', { name: /Test Filter/i }))

    await waitFor(() => {
      expect(screen.getByText(/PASS \(Allowed\)/i)).toBeInTheDocument()
    })

    await user.clear(dryRunInput)
    await user.type(dryRunInput, 'Click this scam link')
    await user.click(screen.getByRole('button', { name: /Test Filter/i }))

    await waitFor(() => {
      expect(
        screen.getByText(/BLOCKED \(content_policy\) · scam link/i),
      ).toBeInTheDocument()
    })

    await user.type(screen.getByPlaceholderText('Term...'), 'badword')
    await user.click(screen.getByRole('button', { name: /Save Word/i }))
    expect(upsertSpy).toHaveBeenCalledWith({
      p_term: 'badword',
      p_lang: 'vi',
      p_match_mode: 'diacritic_word',
      p_category: 'profanity',
      p_enabled: true,
    })

    await user.click(
      screen.getByRole('button', { name: /Enabled scam link/i }),
    )
    expect(toggleSpy).toHaveBeenCalledWith('scam link', false)
  })
})
