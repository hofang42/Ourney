import { useEffect, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import {
  adminApi,
  handleRpcError,
  isFeatureRequestsNotInstalledError,
  type FeatureRequestCategory,
  type FeatureRequestDetail,
  type FeatureRequestRow,
  type FeatureRequestStats,
  type FeatureRequestStatus,
} from '../lib/adminRpc'
import { useI18n } from '../lib/i18n'
import { OIcon } from '../ui/Icon'
import { AccessibleModal, PaginationBar } from '../ui/Modal'

const PAGE_LIMIT = 50

const STATUS_TABS: Array<{
  id: string
  vi: string
  en: string
  visibility?: 'active' | 'hidden' | 'merged' | 'all'
  statKey?: keyof Omit<FeatureRequestStats, 'new_this_week' | 'top_voted'>
}> = [
  { id: 'all_active', vi: 'Đang mở', en: 'All Active', visibility: 'active' },
  {
    id: 'new',
    vi: 'Mới (Cần phân loại)',
    en: 'New (Needs Triage)',
    statKey: 'new',
  },
  {
    id: 'under_review',
    vi: 'Đang xem xét',
    en: 'Under Review',
    statKey: 'under_review',
  },
  { id: 'planned', vi: 'Đã lên kế hoạch', en: 'Planned', statKey: 'planned' },
  {
    id: 'in_progress',
    vi: 'Đang làm',
    en: 'In Progress',
    statKey: 'in_progress',
  },
  { id: 'shipped', vi: 'Đã ra mắt', en: 'Shipped', statKey: 'shipped' },
  { id: 'declined', vi: 'Chưa phù hợp', en: 'Declined', statKey: 'declined' },
  {
    id: 'merged',
    vi: 'Trùng lặp đã gộp',
    en: 'Merged Duplicates',
    visibility: 'merged',
    statKey: 'merged',
  },
  {
    id: 'hidden',
    vi: 'Đã ẩn / Bị báo cáo',
    en: 'Hidden / Reported',
    visibility: 'hidden',
    statKey: 'hidden',
  },
]

const CATEGORIES: FeatureRequestCategory[] = [
  'camera',
  'journeys',
  'squad',
  'sharing',
  'design',
  'other',
]

export function FeatureRequestsPage() {
  const { lang, t } = useI18n()
  const [searchParams] = useSearchParams()
  const [activeTab, setActiveTab] = useState(
    searchParams.get('status') || 'all_active',
  )
  const [search, setSearch] = useState('')
  const [categoryFilter, setCategoryFilter] = useState('all')
  const [visibilityFilter, setVisibilityFilter] = useState('active')
  const [sortBy, setSortBy] = useState('votes_desc')
  const [offset, setOffset] = useState(0)

  const [notInstalled, setNotInstalled] = useState(false)
  const [stats, setStats] = useState<FeatureRequestStats | null>(null)
  const [total, setTotal] = useState(0)
  const [rows, setRows] = useState<FeatureRequestRow[]>([])
  const [selectedId, setSelectedId] = useState<string | null>(
    searchParams.get('id'),
  )
  const [detail, setDetail] = useState<FeatureRequestDetail | null>(null)
  const [loading, setLoading] = useState(true)
  const [bannerMsg, setBannerMsg] = useState<string | null>(null)
  const [errorMsg, setErrorMsg] = useState<string | null>(null)
  const [filterCheckMsg, setFilterCheckMsg] = useState<string | null>(null)

  const [editStatus, setEditStatus] = useState<FeatureRequestStatus>('new')
  const [editCategory, setEditCategory] =
    useState<FeatureRequestCategory>('other')
  const [editReply, setEditReply] = useState('')
  const [editHidden, setEditHidden] = useState(false)
  const [editReason, setEditReason] = useState('')
  const [saving, setSaving] = useState(false)

  const [mergeModalOpen, setMergeModalOpen] = useState(false)
  const [mergeSearch, setMergeSearch] = useState('')
  const [mergePool, setMergePool] = useState<FeatureRequestRow[]>([])
  const [mergeTargetId, setMergeTargetId] = useState('')
  const [mergeTargetDetail, setMergeTargetDetail] =
    useState<FeatureRequestDetail | null>(null)
  const [mergeReason, setMergeReason] = useState('')

  const loadList = async (nextOffset = offset) => {
    setLoading(true)
    setNotInstalled(false)
    setErrorMsg(null)
    try {
      const tabObj = STATUS_TABS.find((x) => x.id === activeTab)
      const effectiveVisibility = tabObj?.visibility ?? visibilityFilter
      const statusParam =
        tabObj?.visibility || activeTab === 'all_active'
          ? 'all_active'
          : activeTab

      const [st, listRes] = await Promise.all([
        adminApi.featureRequestStats(),
        adminApi.listFeatureRequests({
          p_search: search,
          p_status: statusParam,
          p_category: categoryFilter,
          p_visibility: effectiveVisibility,
          p_sort: sortBy,
          p_limit: PAGE_LIMIT,
          p_offset: nextOffset,
        }),
      ])
      setStats(st)
      setTotal(listRes.total)
      setRows(listRes.items)
      if (listRes.items.length > 0) {
        const nextId =
          selectedId && listRes.items.some((r) => r.id === selectedId)
            ? selectedId
            : listRes.items[0].id
        setSelectedId(nextId)
      } else {
        setSelectedId(null)
        setDetail(null)
      }
    } catch (err) {
      if (isFeatureRequestsNotInstalledError(err)) {
        setNotInstalled(true)
      } else {
        const msg = await handleRpcError(err, 'list_feature_requests')
        setErrorMsg(msg)
      }
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    setOffset(0)
    void loadList(0)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeTab, search, categoryFilter, visibilityFilter, sortBy])

  useEffect(() => {
    if (!selectedId || notInstalled) {
      setDetail(null)
      return
    }
    void (async () => {
      try {
        const d = await adminApi.getFeatureRequestDetail(selectedId)
        setDetail(d)
        setEditStatus(d.status)
        setEditCategory(d.category)
        setEditReply(d.admin_reply ?? '')
        setEditHidden(d.hidden)
        setEditReason('')
        setFilterCheckMsg(null)
      } catch (err) {
        if (isFeatureRequestsNotInstalledError(err)) {
          setNotInstalled(true)
        } else {
          const msg = await handleRpcError(err, 'get_feature_request_detail')
          setErrorMsg(msg)
        }
      }
    })()
  }, [selectedId, notInstalled])

  useEffect(() => {
    if (!mergeModalOpen) return
    void (async () => {
      try {
        const res = await adminApi.listFeatureRequests({
          p_search: mergeSearch,
          p_status: 'all_active',
          p_visibility: 'active',
          p_sort: 'votes_desc',
          p_limit: 50,
          p_offset: 0,
        })
        setMergePool(res.items)
      } catch {
        setMergePool(rows)
      }
    })()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [mergeModalOpen, mergeSearch])

  useEffect(() => {
    if (!mergeTargetId) {
      setMergeTargetDetail(null)
      return
    }
    void (async () => {
      try {
        const td = await adminApi.getFeatureRequestDetail(mergeTargetId)
        setMergeTargetDetail(td)
      } catch {
        setMergeTargetDetail(null)
      }
    })()
  }, [mergeTargetId])

  if (notInstalled) {
    return (
      <div className="card" role="status">
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <OIcon name="bulb" size={28} active />
          <div>
            <h2>
              {t(
                'Tính năng Đề xuất chưa cài đặt (Migration 0024)',
                'Feature Requests Not Installed Yet (Migration 0024)',
              )}
            </h2>
            <p className="page-subtitle">
              {t(
                'Bảng public.feature_requests và các RPC admin.*_feature_request* chưa được cài đặt trên cơ sở dữ liệu này (404 / PGRST202). Trang sẽ tự động hoạt động ngay khi migration 0024_feature_requests.sql được áp dụng.',
                'The public.feature_requests schema and admin.*_feature_request* RPCs returned 404 / PGRST202. This page will activate automatically once migration 0024_feature_requests.sql is applied.',
              )}
            </p>
          </div>
        </div>
      </div>
    )
  }

  const handleDryRunReply = async () => {
    if (!editReply.trim()) return
    setErrorMsg(null)
    try {
      const res = await adminApi.testContentFilter(editReply)
      setFilterCheckMsg(
        !res.blocked
          ? t('PASS: Nội dung phản hồi hợp lệ.', 'PASS: Reply text is clean.')
          : t(
              `BLOCKED: Khớp từ khóa "${res.term}" (${res.category})`,
              `BLOCKED: Matched "${res.term}" (${res.category})`,
            ),
      )
    } catch (err) {
      const msg = await handleRpcError(err, 'test_content_filter')
      setErrorMsg(msg)
    }
  }

  const handleSaveUpdate = async (
    clearReply = false,
    nextHidden = editHidden,
  ) => {
    if (!detail) return
    setSaving(true)
    setErrorMsg(null)
    try {
      const replyVal = clearReply ? null : editReply.trim() || null
      await adminApi.updateFeatureRequest({
        p_id: detail.id,
        p_status: editStatus,
        p_category: editCategory,
        p_admin_reply: replyVal,
        p_hidden: nextHidden,
        p_reason:
          editReason.trim() ||
          `Updated status=${editStatus}, category=${editCategory}, hidden=${String(nextHidden)}`,
      })
      if (clearReply) setEditReply('')
      setEditHidden(nextHidden)
      setBannerMsg(
        t(
          'Đã cập nhật đề xuất tính năng và phản hồi công khai.',
          'Saved feature request update and official Ourney reply.',
        ),
      )
      await loadList(offset)
    } catch (err) {
      const msg = await handleRpcError(err, 'update_feature_request')
      setErrorMsg(msg)
    } finally {
      setSaving(false)
    }
  }

  const handleConfirmMerge = async () => {
    if (!detail || !mergeTargetId) return
    setErrorMsg(null)
    try {
      await adminApi.mergeFeatureRequest({
        p_source_id: detail.id,
        p_target_id: mergeTargetId,
        p_reason: mergeReason.trim() || 'Merged duplicate request',
      })
      setMergeModalOpen(false)
      setMergeTargetId('')
      setMergeReason('')
      setMergeSearch('')
      setBannerMsg(
        t(
          'Đã gộp đề xuất trùng lặp và hợp nhất số phiếu bầu duy nhất.',
          'Merged duplicate feature request and consolidated unique votes.',
        ),
      )
      await loadList(offset)
    } catch (err) {
      const msg = await handleRpcError(err, 'merge_feature_request')
      setErrorMsg(msg)
    }
  }

  const candidateSource = mergePool.length > 0 ? mergePool : rows
  const mergeCandidates = candidateSource.filter(
    (r) => r.id !== detail?.id && !r.duplicate_of,
  )
  const selectedCandidate = mergeCandidates.find((r) => r.id === mergeTargetId)

  const computeEstimatedNetVotes = (): number => {
    if (!detail || !selectedCandidate) return 0
    if (
      mergeTargetDetail &&
      mergeTargetDetail.id === selectedCandidate.id &&
      mergeTargetDetail.voters.length > 0 &&
      detail.voters.length > 0
    ) {
      const targetVoterIds = new Set(
        mergeTargetDetail.voters.map((v) => v.user_id),
      )
      let overlap = 0
      for (const v of detail.voters) {
        if (targetVoterIds.has(v.user_id)) {
          overlap += 1
        }
      }
      return Math.max(
        selectedCandidate.vote_count,
        selectedCandidate.vote_count + detail.vote_count - overlap,
      )
    }
    return selectedCandidate.vote_count + detail.vote_count
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
      <div className="page-header">
        <div>
          <h1 className="page-title">
            {t(
              'Đề xuất Tính năng & Lộ trình Công khai',
              'Feature Requests & Public Roadmap',
            )}
          </h1>
          <p className="page-subtitle">
            {t(
              'Phân loại ý tưởng từ người dùng qua 6 trạng thái, xem danh sách người bình chọn, gộp trùng lặp bảo toàn phiếu bầu và đăng phản hồi chính thức từ Ourney.',
              'Triage user ideas across 6 roadmap states, inspect voters, merge duplicates with unique vote consolidation, and publish official Ourney replies.',
            )}
          </p>
        </div>
        {stats && (
          <div style={{ display: 'flex', gap: 10 }}>
            <span className="badge badge-primary tabular">
              +{stats.new_this_week}{' '}
              {t('tuần này (7d)', 'new this week (7d)')}
            </span>
          </div>
        )}
      </div>

      {errorMsg && (
        <div className="status-banner error" role="alert">
          <span>{errorMsg}</span>
        </div>
      )}

      {bannerMsg && (
        <div className="status-banner success" role="status">
          <span>{bannerMsg}</span>
        </div>
      )}

      <div
        className="pipeline-tabs"
        role="tablist"
        aria-label={t('Bộ lọc trạng thái lộ trình', 'Roadmap status pipeline')}
      >
        {STATUS_TABS.map((tab, idx) => {
          const count =
            stats && tab.statKey !== undefined ? stats[tab.statKey] : null
          const isSelected = activeTab === tab.id
          return (
            <button
              key={tab.id}
              id={`fr-tab-${tab.id}`}
              type="button"
              role="tab"
              aria-selected={isSelected}
              aria-controls="fr-tabpanel"
              className={`pipeline-tab ${isSelected ? 'active' : ''}`}
              onClick={() => setActiveTab(tab.id)}
              onKeyDown={(e) => {
                if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') {
                  e.preventDefault()
                  const dir = e.key === 'ArrowRight' ? 1 : -1
                  const nextIdx =
                    (idx + dir + STATUS_TABS.length) % STATUS_TABS.length
                  const nextTab = STATUS_TABS[nextIdx]
                  setActiveTab(nextTab.id)
                  document.getElementById(`fr-tab-${nextTab.id}`)?.focus()
                }
              }}
            >
              <span>{lang === 'vi' ? tab.vi : tab.en}</span>
              {count !== null && (
                <span className="badge tabular">{count}</span>
              )}
            </button>
          )
        })}
      </div>

      <div className="filter-bar">
        <input
          type="search"
          className="input search-input"
          aria-label={t('Tìm kiếm đề xuất tính năng', 'Search feature requests')}
          placeholder={t(
            'Tìm theo tiêu đề, nội dung hoặc @username...',
            'Search title, body, or @username...',
          )}
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />

        <select
          aria-label={t('Danh mục đề xuất', 'Filter category')}
          className="select"
          value={categoryFilter}
          onChange={(e) => setCategoryFilter(e.target.value)}
        >
          <option value="all">{t('Mọi danh mục', 'All categories')}</option>
          {CATEGORIES.map((c) => (
            <option key={c} value={c}>
              {c}
            </option>
          ))}
        </select>

        <select
          aria-label={t('Trạng thái hiển thị', 'Filter visibility')}
          className="select"
          value={visibilityFilter}
          onChange={(e) => setVisibilityFilter(e.target.value)}
        >
          <option value="active">
            {t('Đang hiển thị (Visible)', 'Visible')}
          </option>
          <option value="hidden">
            {t('Đã ẩn / Tạm khóa (Hidden)', 'Hidden / Quarantined')}
          </option>
          <option value="merged">
            {t('Trùng lặp đã gộp (Merged)', 'Merged Duplicates')}
          </option>
          <option value="all">{t('Tất cả (All)', 'All')}</option>
        </select>

        <select
          aria-label={t('Sắp xếp đề xuất', 'Sort requests')}
          className="select"
          value={sortBy}
          onChange={(e) => setSortBy(e.target.value)}
        >
          <option value="votes_desc">
            {t('Nhiều bình chọn nhất (Most Voted)', 'Most Voted')}
          </option>
          <option value="newest">{t('Mới nhất (Newest)', 'Newest')}</option>
          <option value="updated_desc">
            {t('Mới cập nhật (Recently Updated)', 'Recently Updated')}
          </option>
          <option value="reports_desc">
            {t('Nhiều báo cáo nhất (Most Reported)', 'Most Reported')}
          </option>
        </select>
      </div>

      <div
        id="fr-tabpanel"
        role="tabpanel"
        aria-labelledby={`fr-tab-${activeTab}`}
        className="split-pane"
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>{t('Phiếu bầu', 'Votes')}</th>
                  <th>{t('Tiêu đề & Mô tả', 'Title & Snippet')}</th>
                  <th>{t('Danh mục', 'Category')}</th>
                  <th>{t('Trạng thái', 'Status')}</th>
                  <th>{t('Tác giả', 'Author')}</th>
                </tr>
              </thead>
              <tbody>
                {rows.length === 0 && !loading ? (
                  <tr>
                    <td colSpan={5} style={{ textAlign: 'center', padding: 28 }}>
                      {t(
                        'Không tìm thấy đề xuất tính năng nào.',
                        'No feature requests match the current filters.',
                      )}
                    </td>
                  </tr>
                ) : (
                  rows.map((r) => {
                    const isSelected = selectedId === r.id
                    return (
                      <tr
                        key={r.id}
                        tabIndex={0}
                        aria-selected={isSelected}
                        className={`clickable-row ${
                          isSelected ? 'selected-row' : ''
                        }`}
                        onClick={() => setSelectedId(r.id)}
                        onKeyDown={(e) => {
                          if (e.key === 'Enter' || e.key === ' ') {
                            e.preventDefault()
                            setSelectedId(r.id)
                          }
                        }}
                      >
                        <td>
                          <span className="badge badge-primary tabular">
                            {r.vote_count}
                          </span>
                        </td>
                        <td>
                          <div style={{ fontWeight: 700 }}>{r.title}</div>
                          <div
                            style={{
                              fontSize: '0.8rem',
                              color: 'var(--muted)',
                              marginTop: 2,
                            }}
                          >
                            {r.body}
                          </div>
                          <div
                            style={{
                              display: 'flex',
                              gap: 6,
                              marginTop: 6,
                              flexWrap: 'wrap',
                            }}
                          >
                            {r.admin_reply && (
                              <span className="badge badge-warn">
                                {t('Phản hồi Ourney', 'Official Reply')}
                              </span>
                            )}
                            {r.hidden && (
                              <span className="badge badge-danger">Hidden</span>
                            )}
                            {r.merged_children_count > 0 && (
                              <span className="badge badge-purple">
                                Merged ({r.merged_children_count})
                              </span>
                            )}
                            {r.open_reports_count > 0 && (
                              <span className="badge badge-danger">
                                {r.open_reports_count} reports
                              </span>
                            )}
                          </div>
                        </td>
                        <td>
                          <span className="badge">{r.category}</span>
                        </td>
                        <td>
                          <span className="badge badge-success">{r.status}</span>
                        </td>
                        <td>
                          {r.author_username
                            ? `@${r.author_username}`
                            : t('Thành viên Ourney', 'Ourney member')}
                        </td>
                      </tr>
                    )
                  })
                )}
              </tbody>
            </table>
          </div>

          <PaginationBar
            total={total}
            limit={PAGE_LIMIT}
            offset={offset}
            onChangeOffset={(next) => {
              setOffset(next)
              void loadList(next)
            }}
          />
        </div>

        <div className="card">
          {!detail ? (
            <p className="page-subtitle">
              {t(
                'Chọn một đề xuất bên trái để xem chi tiết, phản hồi hoặc gộp trùng lặp.',
                'Select a feature request on the left to inspect, reply, or merge.',
              )}
            </p>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
              <div className="kpi-top">
                <div>
                  <h3>{detail.title}</h3>
                  <p className="kpi-label">
                    {detail.author_username
                      ? `@${detail.author_username}`
                      : t('Thành viên Ourney', 'Ourney member')}{' '}
                    · {detail.vote_count} votes
                  </p>
                </div>
                <button
                  type="button"
                  className="btn"
                  aria-pressed={editHidden}
                  onClick={() => void handleSaveUpdate(false, !editHidden)}
                >
                  <OIcon name={editHidden ? 'eye' : 'eye-off'} size={18} />
                  <span>
                    {editHidden
                      ? t('Hiện lại (Unhide)', 'Unhide')
                      : t('Ẩn bài (Hide)', 'Hide Request')}
                  </span>
                </button>
              </div>

              <div className="card-subtle">
                <p>{detail.body}</p>
              </div>

              {editStatus === 'shipped' && (
                <div className="status-banner success" role="note">
                  <OIcon name="trophy" size={20} />
                  <span>
                    {t(
                      `Lưu ở trạng thái Đã ra mắt (Shipped) sẽ thông báo tới tất cả ${detail.vote_count} người bình chọn trong hộp thư Hoạt động của ứng dụng.`,
                      `Saving as Shipped will notify all ${detail.vote_count} voters in their in-app Activity inbox.`,
                    )}
                  </span>
                </div>
              )}

              <div className="form-grid-2col">
                <label className="field-group">
                  <span className="field-label">
                    {t('Trạng thái lộ trình', 'Roadmap Status')}
                  </span>
                  <select
                    aria-label={t(
                      'Chọn trạng thái lộ trình',
                      'Select roadmap status',
                    )}
                    className="select"
                    value={editStatus}
                    onChange={(e) =>
                      setEditStatus(e.target.value as FeatureRequestStatus)
                    }
                  >
                    <option value="new">new</option>
                    <option value="under_review">under_review</option>
                    <option value="planned">planned</option>
                    <option value="in_progress">in_progress</option>
                    <option value="shipped">shipped</option>
                    <option value="declined">declined</option>
                  </select>
                </label>

                <label className="field-group">
                  <span className="field-label">
                    {t('Danh mục', 'Category')}
                  </span>
                  <select
                    aria-label={t('Chọn danh mục', 'Select category')}
                    className="select"
                    value={editCategory}
                    onChange={(e) =>
                      setEditCategory(e.target.value as FeatureRequestCategory)
                    }
                  >
                    {CATEGORIES.map((c) => (
                      <option key={c} value={c}>
                        {c}
                      </option>
                    ))}
                  </select>
                </label>
              </div>

              <div className="field-group">
                <div className="kpi-top">
                  <label
                    htmlFor="fr-official-reply"
                    className="field-label"
                  >
                    {t(
                      'Phản hồi công khai từ Ourney (Tối đa 1000 ký tự)',
                      'Official Ourney Public Reply (Max 1000 chars)',
                    )}
                  </label>
                  <button
                    type="button"
                    className="btn"
                    onClick={() => void handleDryRunReply()}
                  >
                    <OIcon name="filter" size={16} />
                    <span>
                      {t('Kiểm tra từ ngữ', 'Check Content Filter')}
                    </span>
                  </button>
                </div>
                <textarea
                  id="fr-official-reply"
                  className="textarea"
                  maxLength={1000}
                  aria-label={t(
                    'Phản hồi công khai từ Ourney',
                    'Official Ourney Public Reply',
                  )}
                  placeholder={t(
                    'Viết phản hồi chính thức hiển thị trên thẻ đề xuất trong ứng dụng...',
                    'Write an official response displayed on the mobile Request Detail card...',
                  )}
                  value={editReply}
                  onChange={(e) => setEditReply(e.target.value)}
                />
                {filterCheckMsg && (
                  <div style={{ fontSize: '0.8rem', fontWeight: 700 }}>
                    {filterCheckMsg}
                  </div>
                )}
              </div>

              {editReply.trim() && (
                <div className="ourney-reply-card">
                  <div
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                    }}
                  >
                    <strong>{t('PHẢN HỒI TỪ OURNEY', 'FROM OURNEY')}</strong>
                    <span className="badge">Ourney</span>
                  </div>
                  <p style={{ fontSize: '0.88rem' }}>{editReply}</p>
                </div>
              )}

              <label className="field-group">
                <span className="field-label">
                  {t(
                    'Lý do cập nhật (Ghi nhật ký kiểm toán)',
                    'Audit Reason',
                  )}
                </span>
                <input
                  type="text"
                  className="input"
                  placeholder={t(
                    'Ghi chú ngắn gọn cho private.admin_audit...',
                    'Brief reason for private.admin_audit...',
                  )}
                  value={editReason}
                  onChange={(e) => setEditReason(e.target.value)}
                />
              </label>

              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 10 }}>
                <button
                  type="button"
                  className="btn btn-primary"
                  onClick={() => void handleSaveUpdate(false, editHidden)}
                  disabled={saving}
                >
                  <OIcon name="check" size={18} />
                  <span>
                    {t('Lưu cập nhật & Đăng phản hồi', 'Save Update')}
                  </span>
                </button>

                {detail.admin_reply && (
                  <button
                    type="button"
                    className="btn"
                    onClick={() => void handleSaveUpdate(true, editHidden)}
                    disabled={saving}
                  >
                    <OIcon name="trash" size={18} />
                    <span>{t('Xóa phản hồi', 'Clear Reply')}</span>
                  </button>
                )}

                {!detail.duplicate_of && (
                  <button
                    type="button"
                    className="btn btn-warn"
                    onClick={() => setMergeModalOpen(true)}
                  >
                    <OIcon name="merge" size={18} />
                    <span>
                      {t(
                        'Gộp vào đề xuất gốc... / Merge Duplicate',
                        'Merge into Canonical Request...',
                      )}
                    </span>
                  </button>
                )}
              </div>

              {detail.merged_children && detail.merged_children.length > 0 && (
                <div className="card-subtle">
                  <div className="field-label" style={{ marginBottom: 6 }}>
                    {t(
                      'Các đề xuất trùng lặp đã gộp vào bài này:',
                      'Duplicates merged into this canonical request:',
                    )}
                  </div>
                  {detail.merged_children.map((child) => (
                    <div
                      key={child.id}
                      style={{ fontSize: '0.84rem', marginTop: 4 }}
                    >
                      <strong>{child.title}</strong> (@
                      {child.author_username || 'member'})
                    </div>
                  ))}
                </div>
              )}

              <div>
                <div className="field-label" style={{ marginBottom: 8 }}>
                  {t(
                    `Danh sách người bình chọn (${detail.voters.length})`,
                    `Voters List (${detail.voters.length})`,
                  )}
                </div>
                <div style={{ display: 'grid', gap: 8 }}>
                  {detail.voters.map((v) => (
                    <div
                      key={v.user_id}
                      className="card-subtle"
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        gap: 10,
                      }}
                    >
                      <div>
                        <Link
                          to={`/users/${encodeURIComponent(v.user_id)}`}
                          style={{
                            fontWeight: 700,
                            textDecoration: 'underline',
                          }}
                        >
                          @{v.username || v.user_id.slice(0, 8)}
                        </Link>{' '}
                        {v.display_name && <span>({v.display_name})</span>}
                        {v.is_author && (
                          <span
                            className="badge badge-primary"
                            style={{ marginLeft: 8 }}
                          >
                            {t('Tác giả', 'Author')}
                          </span>
                        )}
                      </div>
                      <div
                        className="tabular"
                        style={{ fontSize: '0.78rem', color: 'var(--muted)' }}
                      >
                        {v.voted_at}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {mergeModalOpen && detail && (
        <AccessibleModal
          title={t(
            'Gộp đề xuất trùng lặp vào đề xuất gốc',
            'Merge Duplicate into Canonical Request',
          )}
          onClose={() => setMergeModalOpen(false)}
        >
          <h3>
            {t(
              'Gộp đề xuất trùng lặp vào đề xuất gốc',
              'Merge Duplicate into Canonical Request',
            )}
          </h3>
          <p className="page-subtitle">
            {t(
              'Tất cả phiếu bầu duy nhất sẽ được chuyển sang đề xuất đích (người bình chọn cả 2 bài chỉ tính 1 lần).',
              'All unique votes transfer to the canonical target (overlapping voters are counted once, never double-counted).',
            )}
          </p>

          <label className="field-group">
            <span className="field-label">
              {t(
                'Tìm kiếm đề xuất đích trên toàn bộ trạng thái',
                'Search canonical target across all active statuses',
              )}
            </span>
            <input
              type="search"
              className="input"
              aria-label={t(
                'Tìm kiếm đề xuất gốc',
                'Search canonical target requests',
              )}
              placeholder={t(
                'Nhập từ khóa tiêu đề bài gốc...',
                'Search canonical request title...',
              )}
              value={mergeSearch}
              onChange={(e) => setMergeSearch(e.target.value)}
            />
          </label>

          <label className="field-group">
            <span className="field-label">
              {t('Chọn đề xuất gốc (Canonical Target)', 'Canonical Target')}
            </span>
            <select
              aria-label={t('Chọn đề xuất đích', 'Select canonical target')}
              className="select"
              value={mergeTargetId}
              onChange={(e) => setMergeTargetId(e.target.value)}
            >
              <option value="">
                {t('-- Chọn đề xuất đích --', '-- Select target request --')}
              </option>
              {mergeCandidates.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.title} ({c.vote_count} votes)
                </option>
              ))}
            </select>
          </label>

          {selectedCandidate && (
            <div className="card-subtle">
              <div style={{ fontWeight: 700 }}>
                {t(
                  'Ước tính tổng phiếu bầu sau khi hợp nhất:',
                  'Estimated Net Unique Votes after merge:',
                )}{' '}
                <span className="badge badge-primary tabular">
                  {computeEstimatedNetVotes()} votes
                </span>
              </div>
            </div>
          )}

          <label className="field-group">
            <span className="field-label">
              {t('Lý do gộp (p_reason)', 'Merge Reason')}
            </span>
            <input
              type="text"
              className="input"
              value={mergeReason}
              onChange={(e) => setMergeReason(e.target.value)}
              placeholder={t(
                'Trùng ý tưởng với bài gốc...',
                'Duplicate idea of canonical request...',
              )}
            />
          </label>

          <div
            style={{
              display: 'flex',
              justifyContent: 'flex-end',
              gap: 10,
            }}
          >
            <button
              type="button"
              className="btn"
              onClick={() => setMergeModalOpen(false)}
            >
              {t('Hủy', 'Cancel')}
            </button>
            <button
              type="button"
              className="btn btn-primary"
              disabled={!mergeTargetId}
              onClick={() => void handleConfirmMerge()}
            >
              <OIcon name="merge" size={18} />
              <span>{t('Xác nhận gộp', 'Confirm Merge')}</span>
            </button>
          </div>
        </AccessibleModal>
      )}
    </div>
  )
}
