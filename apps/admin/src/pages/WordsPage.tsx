import { useEffect, useState, type FormEvent } from 'react'
import {
  adminApi,
  type FilterDryRunResult,
  type ObjectionableWordRow,
} from '../lib/adminRpc'
import { useI18n } from '../lib/i18n'
import { OIcon } from '../ui/Icon'

export function WordsPage() {
  const { t } = useI18n()
  const [words, setWords] = useState<ObjectionableWordRow[]>([])
  const [search, setSearch] = useState('')
  const [langFilter, setLangFilter] = useState('all')
  const [modeFilter, setModeFilter] = useState('all')
  const [catFilter, setCatFilter] = useState('all')

  const [sampleText, setSampleText] = useState('')
  const [dryRunResult, setDryRunResult] = useState<FilterDryRunResult | null>(
    null,
  )

  const [newTerm, setNewTerm] = useState('')
  const [newLang, setNewLang] = useState<'vi' | 'en' | 'any'>('vi')
  const [newMode, setNewMode] = useState<
    'diacritic_word' | 'word' | 'substring'
  >('diacritic_word')
  const [newCategory, setNewCategory] = useState<
    'csae' | 'self_harm' | 'violence' | 'sexual' | 'slur' | 'profanity'
  >('profanity')

  const [statusMsg, setStatusMsg] = useState<string | null>(null)

  const loadWords = async () => {
    const list = await adminApi.listObjectionableWords({
      p_search: search,
      p_lang: langFilter,
      p_mode: modeFilter,
      p_category: catFilter,
    })
    setWords(list)
  }

  useEffect(() => {
    void loadWords()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search, langFilter, modeFilter, catFilter])

  const handleDryRun = async (e: FormEvent) => {
    e.preventDefault()
    const res = await adminApi.testContentFilter(sampleText)
    setDryRunResult(res)
  }

  const handleAddWord = async (e: FormEvent) => {
    e.preventDefault()
    if (!newTerm.trim()) return
    await adminApi.upsertObjectionableWord({
      p_term: newTerm.trim().toLowerCase(),
      p_lang: newLang,
      p_match_mode: newMode,
      p_category: newCategory,
      p_enabled: true,
    })
    setStatusMsg(
      t(
        `Đã lưu từ khóa lọc: ${newTerm.trim().toLowerCase()}`,
        `Saved filter word: ${newTerm.trim().toLowerCase()}`,
      ),
    )
    setNewTerm('')
    await loadWords()
  }

  const handleToggleWord = async (row: ObjectionableWordRow) => {
    await adminApi.setObjectionableWordEnabled(row.term, !row.enabled)
    await loadWords()
  }

  const handleDeleteWord = async (term: string) => {
    await adminApi.deleteObjectionableWord(term, 'Deleted from Words page')
    setStatusMsg(t(`Đã xóa từ khóa: ${term}`, `Deleted word: ${term}`))
    await loadWords()
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
      <div className="page-header">
        <div>
          <h1 className="page-title">
            {t(
              'Bộ lọc Từ khóa Chặn (private.objectionable_words)',
              'Content Filter Words (private.objectionable_words)',
            )}
          </h1>
          <p className="page-subtitle">
            {t(
              'Quản lý danh sách từ khóa cấm song ngữ Việt/Anh áp dụng trực tiếp trên hồ sơ, hành trình, check-in, tin nhắn và đề xuất.',
              'Manage live bilingual blocklist enforced across profiles, journeys, check-ins, messages, and feature requests.',
            )}
          </p>
        </div>
      </div>

      {statusMsg && (
        <div className="status-banner success" role="status">
          <span>{statusMsg}</span>
        </div>
      )}

      <div className="charts-grid">
        <div className="card">
          <h3 style={{ marginBottom: 6 }}>
            {t(
              'Trình kiểm thử bộ lọc trực tiếp (Dry-Run Tester)',
              'Live Filter Dry-Run Tester',
            )}
          </h3>
          <p className="kpi-label" style={{ marginBottom: 12 }}>
            {t(
              'Kiểm tra nhanh câu tiếng Việt có dấu hoặc tiếng Anh để tránh chặn nhầm (không lưu dữ liệu).',
              'Test candidate Vietnamese or English phrases in-memory without storing anything.',
            )}
          </p>
          <form onSubmit={handleDryRun} style={{ display: 'grid', gap: 12 }}>
            <input
              type="text"
              className="input"
              placeholder={t(
                'Dán câu chú thích, tên người dùng hoặc đề xuất để thử...',
                'Paste sample Vietnamese/English caption, feature request, or username...',
              )}
              value={sampleText}
              onChange={(e) => setSampleText(e.target.value)}
            />
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <button type="submit" className="btn btn-primary">
                <OIcon name="filter" size={18} />
                <span>{t('Kiểm thử bộ lọc / Test Filter', 'Test Filter')}</span>
              </button>

              {dryRunResult && (
                <div>
                  {dryRunResult.allowed ? (
                    <span className="badge badge-success">
                      PASS ({t('Cho phép', 'Allowed')})
                    </span>
                  ) : (
                    <span className="badge badge-danger">
                      BLOCKED (content_policy) · {dryRunResult.matched_term} (
                      {dryRunResult.match_mode} / {dryRunResult.category})
                    </span>
                  )}
                </div>
              )}
            </div>
          </form>
        </div>

        <div className="card">
          <h3 style={{ marginBottom: 6 }}>
            {t('Thêm hoặc cập nhật từ khóa', 'Add or Update Filter Word')}
          </h3>
          <form onSubmit={handleAddWord} style={{ display: 'grid', gap: 12 }}>
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: '1fr 110px',
                gap: 10,
              }}
            >
              <input
                type="text"
                className="input"
                placeholder={t('Nhập từ khóa (NFC lowercase)...', 'Term...')}
                value={newTerm}
                onChange={(e) => setNewTerm(e.target.value)}
                required
              />
              <select
                aria-label={t('Ngôn ngữ từ khóa', 'Word language')}
                className="select"
                value={newLang}
                onChange={(e) =>
                  setNewLang(e.target.value as 'vi' | 'en' | 'any')
                }
              >
                <option value="vi">vi</option>
                <option value="en">en</option>
                <option value="any">any</option>
              </select>
            </div>

            <div
              style={{
                display: 'grid',
                gridTemplateColumns: '1fr 1fr auto',
                gap: 10,
              }}
            >
              <select
                aria-label={t('Chế độ khớp', 'Match mode')}
                className="select"
                value={newMode}
                onChange={(e) =>
                  setNewMode(
                    e.target.value as 'diacritic_word' | 'word' | 'substring',
                  )
                }
              >
                <option value="diacritic_word">diacritic_word</option>
                <option value="word">word</option>
                <option value="substring">substring</option>
              </select>

              <select
                aria-label={t('Danh mục vi phạm', 'Violation category')}
                className="select"
                value={newCategory}
                onChange={(e) =>
                  setNewCategory(
                    e.target.value as
                      | 'csae'
                      | 'self_harm'
                      | 'violence'
                      | 'sexual'
                      | 'slur'
                      | 'profanity',
                  )
                }
              >
                <option value="profanity">profanity</option>
                <option value="slur">slur</option>
                <option value="sexual">sexual</option>
                <option value="violence">violence</option>
                <option value="self_harm">self_harm</option>
                <option value="csae">csae</option>
              </select>

              <button type="submit" className="btn btn-primary">
                <OIcon name="plus" size={18} />
                <span>{t('Lưu từ khóa', 'Save Word')}</span>
              </button>
            </div>
          </form>
        </div>
      </div>

      <div className="filter-bar">
        <input
          type="search"
          className="input search-input"
          placeholder={t('Tìm kiếm từ khóa...', 'Search term...')}
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <select
          aria-label={t('Lọc ngôn ngữ', 'Filter language')}
          className="select"
          value={langFilter}
          onChange={(e) => setLangFilter(e.target.value)}
        >
          <option value="all">{t('Mọi ngôn ngữ', 'All languages')}</option>
          <option value="vi">vi</option>
          <option value="en">en</option>
          <option value="any">any</option>
        </select>
        <select
          aria-label={t('Lọc chế độ khớp', 'Filter match mode')}
          className="select"
          value={modeFilter}
          onChange={(e) => setModeFilter(e.target.value)}
        >
          <option value="all">{t('Mọi chế độ khớp', 'All match modes')}</option>
          <option value="diacritic_word">diacritic_word</option>
          <option value="word">word</option>
          <option value="substring">substring</option>
        </select>
        <select
          aria-label={t('Lọc danh mục', 'Filter category')}
          className="select"
          value={catFilter}
          onChange={(e) => setCatFilter(e.target.value)}
        >
          <option value="all">{t('Mọi danh mục', 'All categories')}</option>
          <option value="csae">csae</option>
          <option value="self_harm">self_harm</option>
          <option value="violence">violence</option>
          <option value="sexual">sexual</option>
          <option value="slur">slur</option>
          <option value="profanity">profanity</option>
        </select>
      </div>

      <div className="table-wrap">
        <table className="data-table">
          <thead>
            <tr>
              <th>{t('Từ khóa (Term)', 'Term')}</th>
              <th>{t('Ngôn ngữ', 'Lang')}</th>
              <th>{t('Chế độ khớp', 'Match Mode')}</th>
              <th>{t('Danh mục', 'Category')}</th>
              <th>{t('Trạng thái', 'Enabled')}</th>
              <th>{t('Thao tác', 'Actions')}</th>
            </tr>
          </thead>
          <tbody>
            {words.map((w) => (
              <tr key={w.term}>
                <td style={{ fontWeight: 700 }}>{w.term}</td>
                <td>
                  <span className="badge">{w.lang}</span>
                </td>
                <td>
                  <span className="badge badge-sky">{w.match_mode}</span>
                </td>
                <td>
                  <span className="badge badge-warn">{w.category}</span>
                </td>
                <td>
                  <button
                    type="button"
                    className={`btn ${w.enabled ? 'btn-success' : ''}`}
                    onClick={() => void handleToggleWord(w)}
                  >
                    <span>
                      {w.enabled
                        ? t('Đang bật (Enabled)', 'Enabled')
                        : t('Đang tắt (Disabled)', 'Disabled')}
                    </span>
                  </button>
                </td>
                <td>
                  <button
                    type="button"
                    className="btn btn-danger"
                    onClick={() => void handleDeleteWord(w.term)}
                  >
                    <OIcon name="trash" size={16} />
                    <span>{t('Xóa', 'Delete')}</span>
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
