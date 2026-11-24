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

describe('WordsPage & Filter Word Deletion Confirmation (UX-28)', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    vi.spyOn(adminApi, 'listObjectionableWords').mockResolvedValue(
      SQL_FIXTURE_WORDS,
    )
  })

  it('evaluates live dry-run tester using SQL { blocked, term } contract, supports add/toggle, and requires confirmation before deleting a word (UX-28)', async () => {
    vi.spyOn(adminApi, 'testContentFilter')
      .mockResolvedValueOnce(SQL_FIXTURE_FILTER_PASS)
      .mockResolvedValueOnce(SQL_FIXTURE_FILTER_BLOCKED)
    const upsertSpy = vi
      .spyOn(adminApi, 'upsertObjectionableWord')
      .mockResolvedValue()
    const toggleSpy = vi
      .spyOn(adminApi, 'setObjectionableWordEnabled')
      .mockResolvedValue()
    const deleteSpy = vi
      .spyOn(adminApi, 'deleteObjectionableWord')
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
        screen.getByText(/BLOCKED · scam link \(Substring \/ Profanity\)/i),
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

    // UX-28: Clicking Delete opens confirmation modal first
    await user.click(
      screen.getByRole('button', { name: /Delete scam link/i }),
    )
    expect(deleteSpy).not.toHaveBeenCalled()
    expect(screen.getByRole('dialog')).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: /Confirm Delete/i }))
    expect(deleteSpy).toHaveBeenCalledWith(
      'scam link',
      'Deleted from Words page',
    )
  })
})
