import { useEffect, useState, type FormEvent } from 'react'
import {
  adminApi,
  handleRpcError,
  type FilterDryRunResult,
  type ObjectionableWordRow,
} from '../lib/adminRpc'
import {
  formatWordCategory,
  formatWordLang,
  formatWordMatchMode,
  useI18n,
} from '../lib/i18n'
import { OIcon } from '../ui/Icon'
import { AccessibleModal } from '../ui/Modal'

export function WordsPage() {
  const { lang, t } = useI18n()
  const [words, setWords] = useState<ObjectionableWordRow[]>([])
  const [search, setSearch] = useState('')
  const [langFilter, setLangFilter] = useState('all')
  const [modeFilter, setModeFilter] = useState('all')
  const [catFilter, setCatFilter] = useState('all')
  const [enabledFilter, setEnabledFilter] = useState<
    'all' | 'enabled' | 'disabled'
  >('all')

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

  const [deleteTarget, setDeleteTarget] =
    useState<ObjectionableWordRow | null>(null)
  const [deleteReason, setDeleteReason] = useState('')

  const [statusMsg, setStatusMsg] = useState<string | null>(null)
  const [errorMsg, setErrorMsg] = useState<string | null>(null)

  const loadWords = async () => {
    setErrorMsg(null)
    try {
      const list = await adminApi.listObjectionableWords({
        p_search: search,
        p_lang: langFilter,
        p_mode: modeFilter,
        p_category: catFilter,
        p_enabled:
          enabledFilter === 'all' ? null : enabledFilter === 'enabled',
      })
      setWords(list)
    } catch (err) {
      const msg = await handleRpcError(err, 'list_objectionable_words', lang)
      setErrorMsg(msg)
    }
  }

  useEffect(() => {
    void loadWords()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search, langFilter, modeFilter, catFilter, enabledFilter])

  const handleDryRun = async (e: FormEvent) => {
    e.preventDefault()
    setErrorMsg(null)
    try {
      const res = await adminApi.testContentFilter(sampleText)
      setDryRunResult(res)
    } catch (err) {
      const msg = await handleRpcError(err, 'test_content_filter', lang)
      setErrorMsg(msg)
    }
  }

  const handleAddWord = async (e: FormEvent) => {
    e.preventDefault()
    const normalized = newTerm.trim().normalize('NFC').toLowerCase()
    if (normalized.length < 2 || normalized.length > 64) {
      setErrorMsg(
        t(
          'Từ khóa phải dài từ 2 đến 64 ký tự.',
          'Term must be between 2 and 64 characters.',
        ),
      )
      return
    }
    setErrorMsg(null)
    try {
      await adminApi.upsertObjectionableWord({
        p_term: normalized,
        p_lang: newLang,
        p_match_mode: newMode,
        p_category: newCategory,
        p_enabled: true,
      })
      setStatusMsg(
        t(
          `Đã lưu từ khóa lọc: ${normalized}`,
          `Saved filter word: ${normalized}`,
        ),
      )
      setNewTerm('')
      await loadWords()
    } catch (err) {
      const msg = await handleRpcError(err, 'upsert_objectionable_word', lang)
      setErrorMsg(msg)
    }
  }

  const handleToggleWord = async (row: ObjectionableWordRow) => {
    setErrorMsg(null)
    try {
      await adminApi.setObjectionableWordEnabled(row.term, !row.enabled)
      await loadWords()
    } catch (err) {
      const msg = await handleRpcError(
        err,
        'set_objectionable_word_enabled',
        lang,
      )
      setErrorMsg(msg)
    }
  }

  const handleConfirmDeleteWord = async () => {
    if (!deleteTarget) return
    setErrorMsg(null)
    try {
      const term = deleteTarget.term
      await adminApi.deleteObjectionableWord(
        term,
        deleteReason.trim() || 'Deleted from Words page',
      )
      setStatusMsg(t(`Đã xóa từ khóa: ${term}`, `Deleted word: ${term}`))
      setDeleteTarget(null)
      setDeleteReason('')
      await loadWords()
    } catch (err) {
      const msg = await handleRpcError(err, 'delete_objectionable_word', lang)
      setErrorMsg(msg)
    }
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
      <div className="page-header">
        <div>
          <h1 className="page-title">
            {t('Bộ lọc Từ khóa Chặn', 'Content Filter Words')}
          </h1>
          <p className="page-subtitle">
            {t(
              'Quản lý danh sách từ khóa cấm song ngữ Việt/Anh áp dụng trực tiếp trên hồ sơ, hành trình, check-in, tin nhắn và đề xuất.',
              'Manage live bilingual blocklist enforced across profiles, journeys, check-ins, messages, and feature requests.',
            )}
          </p>
        </div>
      </div>

      {errorMsg && (
        <div className="status-banner error" role="alert">
          <span>{errorMsg}</span>
        </div>
      )}

      {statusMsg && (
        <div className="status-banner success" role="status">
          <span>{statusMsg}</span>
        </div>
      )}

      <div className="charts-grid">
        <div className="card">
          <h3 style={{ marginBottom: 6 }}>
            {t(
              'Trình kiểm thử bộ lọc trực tiếp',
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
              aria-label={t(
                'Văn bản mẫu kiểm thử bộ lọc',
                'Sample text for content filter dry-run',
              )}
              placeholder={t(
                'Dán câu chú thích, tên người dùng hoặc đề xuất để thử...',
                'Paste sample Vietnamese/English caption, feature request, or username...',
              )}
              value={sampleText}
              onChange={(e) => setSampleText(e.target.value)}
            />
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 12,
                flexWrap: 'wrap',
              }}
            >
              <button type="submit" className="btn btn-primary">
                <OIcon name="filter" size={18} />
                <span>{t('Kiểm thử bộ lọc', 'Test Filter')}</span>
              </button>

              {dryRunResult && (
                <div>
                  {!dryRunResult.blocked ? (
                    <span className="badge badge-success">
                      {t('HỢP LỆ (Cho phép)', 'PASS (Allowed)')}
                    </span>
                  ) : (
                    <span className="badge badge-danger">
                      {t('BỊ CHẶN', 'BLOCKED')} · {dryRunResult.term} (
                      {formatWordMatchMode(dryRunResult.match_mode, lang)} /{' '}
                      {formatWordCategory(dryRunResult.category, lang)})
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
            <div className="form-grid-word-top">
              <input
                type="text"
                className="input"
                minLength={2}
                maxLength={64}
                aria-label={t('Từ khóa chặn mới', 'New filter word term')}
                placeholder={t('Nhập từ khóa chữ thường...', 'Term...')}
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
                <option value="vi">{formatWordLang('vi', lang)}</option>
                <option value="en">{formatWordLang('en', lang)}</option>
                <option value="any">{formatWordLang('any', lang)}</option>
              </select>
            </div>

            <div className="form-grid-word-bottom">
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
                <option value="diacritic_word">
                  {formatWordMatchMode('diacritic_word', lang)}
                </option>
                <option value="word">
                  {formatWordMatchMode('word', lang)}
                </option>
                <option value="substring">
                  {formatWordMatchMode('substring', lang)}
                </option>
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
                <option value="profanity">
                  {formatWordCategory('profanity', lang)}
                </option>
                <option value="slur">{formatWordCategory('slur', lang)}</option>
                <option value="sexual">
                  {formatWordCategory('sexual', lang)}
                </option>
                <option value="violence">
                  {formatWordCategory('violence', lang)}
                </option>
                <option value="self_harm">
                  {formatWordCategory('self_harm', lang)}
                </option>
                <option value="csae">{formatWordCategory('csae', lang)}</option>
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
          aria-label={t('Tìm kiếm từ khóa chặn', 'Search filter terms')}
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
          <option value="vi">{formatWordLang('vi', lang)}</option>
          <option value="en">{formatWordLang('en', lang)}</option>
          <option value="any">{formatWordLang('any', lang)}</option>
        </select>
        <select
          aria-label={t('Lọc chế độ khớp', 'Filter match mode')}
          className="select"
          value={modeFilter}
          onChange={(e) => setModeFilter(e.target.value)}
        >
          <option value="all">
            {t('Mọi chế độ khớp', 'All match modes')}
          </option>
          <option value="diacritic_word">
            {formatWordMatchMode('diacritic_word', lang)}
          </option>
          <option value="word">{formatWordMatchMode('word', lang)}</option>
          <option value="substring">
            {formatWordMatchMode('substring', lang)}
          </option>
        </select>
        <select
          aria-label={t('Lọc danh mục', 'Filter category')}
          className="select"
          value={catFilter}
          onChange={(e) => setCatFilter(e.target.value)}
        >
          <option value="all">{t('Mọi danh mục', 'All categories')}</option>
          <option value="csae">{formatWordCategory('csae', lang)}</option>
          <option value="self_harm">
            {formatWordCategory('self_harm', lang)}
          </option>
          <option value="violence">
            {formatWordCategory('violence', lang)}
          </option>
          <option value="sexual">{formatWordCategory('sexual', lang)}</option>
          <option value="slur">{formatWordCategory('slur', lang)}</option>
          <option value="profanity">
            {formatWordCategory('profanity', lang)}
          </option>
        </select>
        <select
          aria-label={t('Lọc trạng thái bật/tắt', 'Filter enabled status')}
          className="select"
          value={enabledFilter}
          onChange={(e) =>
            setEnabledFilter(e.target.value as 'all' | 'enabled' | 'disabled')
          }
        >
          <option value="all">
            {t('Mọi trạng thái', 'All enabled states')}
          </option>
          <option value="enabled">{t('Đang bật', 'Enabled')}</option>
          <option value="disabled">{t('Đang tắt', 'Disabled')}</option>
        </select>
      </div>

      <div className="table-wrap">
        <table className="data-table">
          <thead>
            <tr>
              <th>{t('Từ khóa', 'Term')}</th>
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
                  <span className="badge">{formatWordLang(w.lang, lang)}</span>
                </td>
                <td>
                  <span className="badge badge-sky">
                    {formatWordMatchMode(w.match_mode, lang)}
                  </span>
                </td>
                <td>
                  <span className="badge badge-warn">
                    {formatWordCategory(w.category, lang)}
                  </span>
                </td>
                <td>
                  <button
                    type="button"
                    aria-pressed={w.enabled}
                    aria-label={
                      w.enabled
                        ? `${t('Đang bật', 'Enabled')} ${w.term}`
                        : `${t('Đang tắt', 'Disabled')} ${w.term}`
                    }
                    className={`btn ${w.enabled ? 'btn-success' : ''}`}
                    onClick={() => void handleToggleWord(w)}
                  >
                    <span>
                      {w.enabled
                        ? t('Đang bật', 'Enabled')
                        : t('Đang tắt', 'Disabled')}
                    </span>
                  </button>
                </td>
                <td>
                  <button
                    type="button"
                    aria-label={`${t('Xóa', 'Delete')} ${w.term}`}
                    className="btn btn-danger"
                    onClick={() => setDeleteTarget(w)}
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

      {deleteTarget && (
        <AccessibleModal
          title={t(
            'Xác nhận xóa từ khóa chặn',
            'Confirm Filter Word Deletion',
          )}
          onClose={() => {
            setDeleteTarget(null)
            setDeleteReason('')
          }}
        >
          <h3>
            {t('Xác nhận xóa từ khóa chặn', 'Confirm Filter Word Deletion')}
          </h3>
          <p className="page-subtitle">
            <strong>{deleteTarget.term}</strong> (
            {formatWordCategory(deleteTarget.category, lang)}) —{' '}
            {t(
              'Sau khi xóa, từ khóa này sẽ không còn bị chặn tự động trên hồ sơ, chú thích ảnh, tin nhắn hay đề xuất tính năng.',
              'Removing this word immediately stops blocking it across profiles, check-ins, messages, and feature requests.',
            )}
          </p>
          <label className="field-group">
            <span className="field-label">
              {t('Lý do xóa', 'Deletion Reason')}
            </span>
            <input
              type="text"
              className="input"
              value={deleteReason}
              onChange={(e) => setDeleteReason(e.target.value)}
              placeholder={t(
                'Từ khóa gây chặn nhầm hoặc không còn phù hợp...',
                'False positive or obsolete term...',
              )}
            />
          </label>
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
            <button
              type="button"
              className="btn"
              onClick={() => {
                setDeleteTarget(null)
                setDeleteReason('')
              }}
            >
              {t('Hủy', 'Cancel')}
            </button>
            <button
              type="button"
              className="btn btn-danger"
              onClick={() => void handleConfirmDeleteWord()}
            >
              {t('Xác nhận xóa', 'Confirm Delete')}
            </button>
          </div>
        </AccessibleModal>
      )}
    </div>
  )
}
