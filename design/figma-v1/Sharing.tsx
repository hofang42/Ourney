import { useState } from "react"
import type { ReactNode } from "react"
import {
  ArrowLeft,
  Ban,
  BarChart3,
  Camera,
  Check,
  ChevronDown,
  ChevronRight,
  Clock3,
  Copy,
  Eye,
  EyeOff,
  Image as ImageIcon,
  Link,
  Lock,
  MessageCircle,
  MoreHorizontal,
  Plus,
  QrCode,
  Search,
  Send,
  Share2,
  Slash,
  UserPlus,
  Users,
  Undo2,
  X,
} from "lucide-react"

type Language = "en" | "vi"

const image = {
  reading:
    "https://images.unsplash.com/photo-1707142979946-a745d1d0092c?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  trip: "https://images.unsplash.com/photo-1660287989246-639df4884ed3?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  run: "https://images.unsplash.com/photo-1588786849554-ef79422ee605?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  cooking:
    "https://images.unsplash.com/photo-1758522489456-96afe24741dc?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  pine: "https://images.unsplash.com/photo-1774081639594-0c4ab58afabb?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  lake: "https://images.unsplash.com/photo-1762251501272-d87349fc9549?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  flowers:
    "https://images.unsplash.com/photo-1600103792025-08a70de9738c?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  night:
    "https://images.unsplash.com/photo-1748596161714-4049199ae770?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  coffee:
    "https://images.unsplash.com/photo-1790577845138-8d374728118f?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  baby: "https://images.unsplash.com/photo-1544126592-807ade215a0b?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  skin: "https://images.unsplash.com/photo-1556227703-b7668d8cff99?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  study:
    "https://images.unsplash.com/photo-1605915968535-7a95bcd68cab?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  beach:
    "https://images.unsplash.com/photo-1732243395944-cb3ff9311091?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  lanterns:
    "https://images.unsplash.com/photo-1563354860-799d15199ac3?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
}

const daLatPhotos = [
  image.pine,
  image.lake,
  image.flowers,
  image.night,
  image.coffee,
]

const friends = [
  ["Nam Tran", "@nam.tran"],
  ["Hà Vu", "@ha.vu"],
  ["Lan Do", "@lan.do"],
  ["Minh Pham", "@minh.pham"],
  ["Thu Nguyen", "@thu.nguyen"],
  ["Bao Le", "@bao.le"],
  ["Quynh Hoang", "@quynh.hoang"],
  ["Duc Ngo", "@duc.ngo"],
  ["An Phan", "@an.phan"],
  ["Vy Dang", "@vy.dang"],
  ["Tam Bui", "@tam.bui"],
  ["Hieu Ly", "@hieu.ly"],
] as const

function Avatar({ name, index = 0 }: { name: string index?: number }) {
  return (
    <span className={`share-avatar avatar-${index % 5}`}>{name.charAt(0)}</span>
  )
}

function BackHeader({
  title,
  subtitle,
  onBack,
  action,
}: {
  title: string
  subtitle?: string
  onBack: () => void
  action?: ReactNode
}) {
  return (
    <header className="sharing-nav">
      <button aria-label="Back" onClick={onBack}>
        <ArrowLeft />
      </button>
      <div>
        <strong>{title}</strong>
        {subtitle && <small>{subtitle}</small>}
      </div>
      {action || <span />}
    </header>
  )
}

export function SharedWithMe({
  language,
  saved,
  onOpen,
}: {
  language: Language
  saved: boolean
  onOpen: (running?: boolean) => void
}) {
  const l = language === "vi"
  const cards = [
    {
      title: "Da Lat in 5 photos",
      owner: "Hà Vu",
      style: "Memory Collectors",
      meta: l ? "Kết thúc 18 Thg 10" : "Finished Oct 18",
      photo: image.pine,
      running: false,
    },
    {
      title: "Couch to 5K",
      owner: "Nam Tran",
      style: "Aesthetic Flexer",
      meta: l ? "Ngày 12 · trực tiếp" : "Day 12 · live",
      photo: image.run,
      running: true,
    },
  ]
  return (
    <section className="shared-hub-content">
      <h2>{l ? "Từ bạn bè" : "From friends"}</h2>
      <div className="shared-compact-list">
        {cards.map((card, index) => (
          <button key={card.title} onClick={() => onOpen(card.running)}>
            <img src={card.photo} alt="" />
            <span className="shared-card-copy">
              <strong>{card.title}</strong>
              <span className="shared-owner">
                <Avatar name={card.owner} index={index + 1} />
                {card.owner}
              </span>
              <small>
                <i className={index ? "pink" : "clay"} />
                {card.style} · {card.meta}
              </small>
            </span>
            {index === 1 && (
              <span className="new-status">
                <i />
                New
              </span>
            )}
            <ChevronRight />
          </button>
        ))}
      </div>
      {saved && (
        <>
          <h2>{l ? "Đã lưu" : "Saved"}</h2>
          <button className="saved-story" onClick={() => onOpen(false)}>
            <img src={image.pine} alt="" />
            <span>
              <strong>Da Lat in 5 photos</strong>
              <small>
                {l ? "Đã thích qua liên kết" : "Liked from a public link"}
              </small>
            </span>
            <ChevronRight />
          </button>
        </>
      )}
    </section>
  )
}

export function FriendsScreen({
  language,
  onBack,
  onAdd,
  requests,
  acceptedFriends,
  onRequestHandled,
}: {
  language: Language
  onBack: () => void
  onAdd: () => void
  requests: string[]
  acceptedFriends: string[]
  onRequestHandled: (name: string, accept: boolean) => void
}) {
  const l = language === "vi"
  const [selected, setSelected] = useState<readonly [string, string] | null>(
    null,
  )
  const requestRows = requests.map(
    (name) => [name, name === "Khoa Le" ? "@khoa.le" : "@mai.pham"] as const,
  )
  const friendRows: ReadonlyArray<readonly [string, string]> = [
    ...friends,
    ...acceptedFriends.map(
      (name) => [name, name === "Khoa Le" ? "@khoa.le" : "@mai.pham"] as const,
    ),
  ]
  return (
    <div className="screen sharing-screen">
      <BackHeader
        title={l ? "Bạn bè" : "Friends"}
        subtitle={
          l
            ? `${friendRows.length} người bạn · chỉ bạn thấy`
            : `${friendRows.length} friends · only you see this`
        }
        onBack={onBack}
        action={
          <button className="nav-text-button" onClick={onAdd}>
            <UserPlus />
            {l ? "Thêm" : "Add"}
          </button>
        }
      />
      <section className="sharing-section">
        <h2>{l ? "Lời mời" : "Requests"}</h2>
        {requestRows.length === 0 && (
          <p className="sharing-muted">
            {l ? "Không có lời mời mới" : "No new requests"}
          </p>
        )}
        {requestRows.map((request, index) => (
          <div className="person-row request-row" key={request[1]}>
            <Avatar name={request[0]} index={index + 3} />
            <span>
              <strong>{request[0]}</strong>
              <small>{request[1]}</small>
            </span>
            <button onClick={() => onRequestHandled(request[0], true)}>
              {l ? "Chấp nhận" : "Accept"}
            </button>
            <button
              className="quiet-action"
              onClick={() => onRequestHandled(request[0], false)}
            >
              {l ? "Từ chối" : "Decline"}
            </button>
          </div>
        ))}
      </section>
      <section className="sharing-section friend-list">
        {friendRows.map((friend, index) => (
          <button
            className="person-row"
            key={friend[1]}
            onClick={() => setSelected(friend)}
          >
            <Avatar name={friend[0]} index={index} />
            <span>
              <strong>{friend[0]}</strong>
              <small>{friend[1]}</small>
              {(index === 0 || index === 1) && (
                <small>
                  {l
                    ? "Chia sẻ 1 hành trình với bạn"
                    : "Shares 1 journey with you"}
                </small>
              )}
            </span>
            <ChevronRight />
          </button>
        ))}
      </section>
      {selected && (
        <div
          className="modal-layer profile-layer"
          onMouseDown={() => setSelected(null)}
        >
          <section
            className="bottom-sheet friend-sheet"
            onMouseDown={(event) => event.stopPropagation()}
          >
            <div className="sheet-grabber" />
            <div className="friend-sheet-title">
              <Avatar name={selected[0]} />
              <span>
                <h2>{selected[0]}</h2>
                <small>{selected[1]}</small>
              </span>
            </div>
            <h3>{l ? "Họ chia sẻ với bạn" : "Shared with you"}</h3>
            <div className="mini-shared-row">
              <img src={image.trip} alt="" />
              <span>Da Lat in 5 photos</span>
              <button>{l ? "Xóa" : "Remove"}</button>
            </div>
            <h3>{l ? "Bạn chia sẻ với họ" : "You share with them"}</h3>
            <div className="mini-shared-row">
              <img src={image.reading} alt="" />
              <span>Daily Reading</span>
              <button>{l ? "Xóa" : "Remove"}</button>
            </div>
            <button className="sheet-action">
              <MessageCircle />
              {l ? "Nhắn tin" : "Message"}
            </button>
            <button
              className="sheet-action danger-action"
              onClick={() =>
                window.confirm(
                  l
                    ? "Hai bạn sẽ không còn thấy hành trình được chia sẻ của nhau."
                    : "You'll stop seeing each other's shared journeys.",
                )
              }
            >
              {l ? "Xóa bạn" : "Remove friend"}
            </button>
            <button className="sheet-action">
              <Ban />
              {l ? "Chặn" : "Block"}
            </button>
            <button className="sheet-action">
              <Slash />
              {l ? "Báo cáo" : "Report"}
            </button>
          </section>
        </div>
      )}
    </div>
  )
}

export function AddFriendsScreen({
  language,
  onBack,
  onToast,
}: {
  language: Language
  onBack: () => void
  onToast: (message: string) => void
}) {
  const l = language === "vi"
  const [query, setQuery] = useState("")
  const [requested, setRequested] = useState(false)
  const [qrLarge, setQrLarge] = useState(false)
  const exact = query.trim().toLowerCase() === "@tuan.vo"
  return (
    <div className="screen sharing-screen">
      <BackHeader title={l ? "Thêm bạn" : "Add friends"} onBack={onBack} />
      <section className="sharing-block">
        <span className="block-icon">
          <Link />
        </span>
        <div>
          <h2>{l ? "Chia sẻ liên kết mời" : "Share my invite link"}</h2>
          <p>ourney.app/invite/linh-tran</p>
        </div>
        <button
          onClick={() => onToast(l ? "Đã sao chép liên kết" : "Link copied")}
        >
          <Copy />
          {l ? "Sao chép" : "Copy"}
        </button>
      </section>
      <section className="sharing-block qr-block">
        <button
          className={`mock-qr ${qrLarge ? "large" : ""}`}
          aria-label="Enlarge QR code"
          onClick={() => setQrLarge(!qrLarge)}
        >
          <QrCode />
        </button>
        <div>
          <h2>{l ? "Mã QR của tôi" : "My QR code"}</h2>
          <p>{l ? "Chạm để phóng to" : "Tap to enlarge"}</p>
        </div>
        <button>
          <Camera />
          {l ? "Quét mã" : "Scan a code"}
        </button>
      </section>
      <section className="username-search">
        <h2>{l ? "Tìm bằng tên người dùng" : "Find by username"}</h2>
        <label>
          <Search />
          <input
            value={query}
            onChange={(event) => {
              setQuery(event.target.value)
              setRequested(false)
            }}
            placeholder="@username"
          />
        </label>
        {query &&
          (exact ? (
            <div className="person-row">
              <Avatar name="Tuan Vo" index={2} />
              <span>
                <strong>Tuan Vo</strong>
                <small>@tuan.vo</small>
              </span>
              <button onClick={() => setRequested(true)}>
                {requested
                  ? l
                    ? "Đã gửi"
                    : "Requested"
                  : l
                    ? "Thêm bạn"
                    : "Add friend"}
              </button>
            </div>
          ) : (
            <p className="no-result">
              {l
                ? "Không có ai với tên người dùng này"
                : "No one with that username"}
            </p>
          ))}
      </section>
    </div>
  )
}

export function ShareJourneySheet({
  language,
  kind,
  journeyId,
  journeyName,
  under18,
  onClose,
  onEdit,
  onInsights,
}: {
  language: Language
  kind: "running" | "finished" | "imported" | "squad"
  journeyId: number
  journeyName: string
  under18: boolean
  onClose: () => void
  onEdit: () => void
  onInsights: () => void
}) {
  const l = language === "vi"
  const sensitive = [1, 7, 8].includes(journeyId)
  const journeyPreview =
    journeyId === 2
      ? image.study
      : journeyId === 12
        ? image.beach
        : journeyId === 7
          ? image.skin
          : journeyId === 8
            ? image.baby
            : kind === "imported"
              ? image.trip
              : image.reading
  const linkEligible = kind === "imported" || kind === "finished"
  const alreadyShared =
    kind === "imported" && journeyId === 0
      ? ["@nam.tran", "@ha.vu", "@lan.do", "@thu.nguyen", "@bao.le"]
      : []
  const shareableFriends =
    kind === "squad"
      ? friends.filter(
          (friend) =>
            !["@nam.tran", "@ha.vu", "@minh.pham"].includes(friend[1]),
        )
      : friends
  const [selected, setSelected] = useState(
    sensitive ? [] : shareableFriends.map((friend) => friend[1]),
  )
  const [reminded, setReminded] = useState(false)
  const [linkOn, setLinkOn] = useState(
    kind === "imported" && journeyId !== 8 && !under18,
  )
  const [sensitiveWarning, setSensitiveWarning] = useState(false)
  const newlySelected = selected.filter(
    (username) => !alreadyShared.includes(username),
  ).length
  const toggle = (username: string) =>
    setSelected((current) =>
      current.includes(username)
        ? current.filter((item) => item !== username)
        : [...current, username],
    )
  return (
    <div className="modal-layer profile-layer" onMouseDown={onClose}>
      <section
        className="bottom-sheet share-journey-sheet"
        onMouseDown={(event) => event.stopPropagation()}
      >
        <div className="sheet-grabber" />
        <div className="share-preview">
          <img src={journeyPreview} alt="" />
          <span>
            <small>{l ? "CHIA SẺ HÀNH TRÌNH" : "SHARE THIS JOURNEY"}</small>
            <strong>{journeyName}</strong>
          </span>
          <button onClick={onEdit}>
            {l ? "Sửa câu chuyện" : "Edit story"}
          </button>
        </div>
        {kind === "squad" && (
          <section className="consent-block">
            <h3>{l ? "Đồng thuận của nhóm" : "Squad consent"}</h3>
            {[
              ["Linh", "Agreed"],
              ["Hà", "Agreed"],
              ["Nam", "Agreed"],
              ["Minh", reminded ? "Reminded" : "Waiting"],
            ].map((member, index) => (
              <div key={member[0]}>
                <Avatar name={member[0]} index={index} />
                <span>{member[0]}</span>
                {member[1] === "Agreed" ? <Check /> : <Clock3 />}
                <small>{member[1]}</small>
                {member[0] === "Minh" && !reminded && (
                  <button onClick={() => setReminded(true)}>Remind</button>
                )}
              </div>
            ))}
            <p>
              {l
                ? "Chỉ ảnh của người đã đồng ý được chia sẻ"
                : "Only photos of people who agreed are shared"}
            </p>
          </section>
        )}
        <section className="share-friends-block">
          <header>
            <h3>{l ? "Bạn bè" : "Friends"}</h3>
            <button
              onClick={() =>
                setSelected(shareableFriends.map((friend) => friend[1]))
              }
            >
              {l ? "Chọn tất cả" : "Select all"}
            </button>
            <button onClick={() => setSelected([])}>
              {l ? "Xóa" : "Clear"}
            </button>
          </header>
          {shareableFriends.length > 10 && (
            <label className="friend-search">
              <Search />
              <input placeholder={l ? "Tìm bạn" : "Search friends"} />
            </label>
          )}
          <div className="share-check-list">
            {shareableFriends.map((friend, index) => (
              <button key={friend[1]} onClick={() => toggle(friend[1])}>
                <Avatar name={friend[0]} index={index} />
                <span>
                  <strong>{friend[0]}</strong>
                  {alreadyShared.includes(friend[1]) && (
                    <small>
                      {l ? "Có thể xem" : "Can see"} · {l ? "Xóa" : "Remove"}
                    </small>
                  )}
                </span>
                <i className={selected.includes(friend[1]) ? "checked" : ""}>
                  {selected.includes(friend[1]) && <Check />}
                </i>
              </button>
            ))}
          </div>
          {sensitive && (
            <p className="sensitive-helper">
              {l
                ? "Hành trình nhạy cảm: chọn từng người"
                : "Sensitive journey: pick people one by one"}
            </p>
          )}
          {kind === "squad" && (
            <p>
              {l
                ? "2 người bạn của thành viên khác cũng có thể xem"
                : "2 friends of other members can also see this"}
            </p>
          )}
          {kind === "running" && (
            <p>
              {l
                ? "Họ sẽ thấy ảnh mới khi bạn đăng"
                : "They'll see new photos as you post"}
            </p>
          )}
          <button
            className="brand-primary share-submit"
            disabled={newlySelected === 0}
            aria-disabled={newlySelected === 0}
          >
            {newlySelected === 0
              ? l
                ? "Chọn bạn để chia sẻ"
                : "Pick friends to share"
              : l
                ? `Chia sẻ cho ${newlySelected} bạn`
                : `Share with ${newlySelected} friends`}
          </button>
        </section>
        <section
          className={`public-link-block ${!linkEligible ? "locked" : ""}`}
        >
          <h3>{l ? "Liên kết công khai" : "Public link"}</h3>
          {!linkEligible ? (
            <div className="locked-link">
              <Lock />
              <span>
                <strong>
                  {kind === "squad"
                    ? l
                      ? "Do Hà quản lý"
                      : "Managed by Hà"
                    : l
                      ? "Liên kết mở khi hành trình kết thúc"
                      : "Links open when this journey is finished"}
                </strong>
                <small>
                  {l
                    ? "Chưa thể bật liên kết"
                    : "Public access is not available yet"}
                </small>
              </span>
            </div>
          ) : (
            <>
              <label className="switch-row">
                <span>
                  <strong>{l ? "Bật liên kết" : "Link on"}</strong>
                  <small>
                    ourney.app/j/
                    {journeyName
                      .toLowerCase()
                      .replaceAll(/[^a-z0-9]+/g, "-")
                      .replaceAll(/^-|-$/g, "")}
                  </small>
                </span>
                <input
                  type="checkbox"
                  checked={linkOn}
                  disabled={under18}
                  onChange={() => {
                    if (sensitive && !linkOn) setSensitiveWarning(true)
                    else setLinkOn(!linkOn)
                  }}
                />
              </label>
              {under18 && (
                <p className="underage-link-note">
                  {l
                    ? "Link công khai dành cho người từ 18 tuổi"
                    : "Public links are for 18+"}
                </p>
              )}
              {sensitive && (
                <div className="sensitive-link-preview">
                  <img src={journeyPreview} alt="" />
                  <span>
                    {l
                      ? "Ảnh được làm mờ trong bản xem trước"
                      : "Photos blurred in previews"}
                  </span>
                </div>
              )}
              <div className="link-actions">
                <button>
                  <Copy />
                  {l ? "Sao chép" : "Copy link"}
                </button>
                <button>
                  <Share2 />
                  {l ? "Chia sẻ" : "Share"}
                </button>
                <button>{l ? "Đặt lại" : "Reset link"}</button>
                <button>{l ? "Xem trước" : "Preview"}</button>
              </div>
              <p>
                {l
                  ? "Ai có liên kết cũng có thể xem và làm theo hành trình."
                  : "Anyone with the link can view it and do this journey too"}
              </p>
              {(l
                ? [
                    [
                      "Hiện số liệu",
                      "Hiện lượt thích và số người làm theo cho người xem",
                    ],
                    [
                      "Cho phép mọi người tương tác",
                      "Người có tài khoản Ourney có thể thích",
                    ],
                    [
                      "Cho phép người xem gửi lời mời kết bạn",
                      "Người xem có thể gửi lời mời kết bạn",
                    ],
                  ]
                : [
                    ["Show counts", "Show likes and follow-alongs to viewers"],
                    [
                      "Let anyone react",
                      "People with an Ourney account can like it",
                    ],
                    [
                      "Allow friend requests from viewers",
                      "Viewers can send you a friend request",
                    ],
                  ]
              ).map(([label, helper]) => (
                <label className="switch-row" key={label}>
                  <span>
                    <strong>{label}</strong>
                    <small>{helper}</small>
                  </span>
                  <input type="checkbox" defaultChecked />
                </label>
              ))}
              <button className="owner-stats" onClick={onInsights}>
                1.2k views · 340 ❤️ · 28 started <ChevronRight />
              </button>
            </>
          )}
        </section>
        {(kind === "imported" || kind === "squad") && (
          <button
            className="stop-sharing"
            onClick={() =>
              window.confirm(
                l
                  ? "Mọi người sẽ mất quyền truy cập. Người đã bắt đầu vẫn giữ hành trình của họ."
                  : "Everyone loses access. People who started this journey keep theirs.",
              )
            }
          >
            {kind === "squad"
              ? l
                ? "Xóa ảnh của tôi khỏi chia sẻ"
                : "Remove my photos from sharing"
              : l
                ? "Dừng chia sẻ"
                : "Stop sharing"}
          </button>
        )}
        {sensitiveWarning && (
          <div className="modal-layer sensitive-warning-layer">
            <section className="bottom-sheet sensitive-warning-sheet">
              <h2>
                {l
                  ? "Ai có link đều xem được hành trình này"
                  : "Anyone with the link can see this journey"}
              </h2>
              <ul>
                <li>
                  <Users />
                  <span>
                    {l
                      ? "Bất kỳ ai nhận được link đều có thể xem."
                      : "Anyone who receives the link can view it."}
                  </span>
                </li>
                <li>
                  <Eye />
                  <span>
                    {l
                      ? "Chỉ ảnh bạn chọn mới hiện; bản xem trước được làm mờ."
                      : "Only selected photos show; previews are blurred."}
                  </span>
                </li>
                <li>
                  <Undo2 />
                  <span>
                    {l
                      ? "Bạn có thể tắt link bất cứ lúc nào."
                      : "You can turn the link off at any time."}
                  </span>
                </li>
              </ul>
              <button
                className="brand-primary"
                onClick={() => {
                  setLinkOn(true)
                  setSensitiveWarning(false)
                }}
              >
                {l ? "Bật link" : "Turn on link"}
              </button>
              <button
                className="secondary-wide"
                onClick={() => setSensitiveWarning(false)}
              >
                {l ? "Hủy" : "Cancel"}
              </button>
            </section>
          </div>
        )}
      </section>
    </div>
  )
}

export function StoryEditor({
  language,
  onBack,
  onPreview,
}: {
  language: Language
  onBack: () => void
  onPreview: () => void
}) {
  const l = language === "vi"
  const [hidden, setHidden] = useState<number[]>([])
  return (
    <div className="screen story-editor">
      <header>
        <button onClick={onBack}>{l ? "Hủy" : "Cancel"}</button>
        <strong>{l ? "Câu chuyện của bạn" : "Your story"}</strong>
        <button onClick={onBack}>{l ? "Lưu" : "Save"}</button>
      </header>
      <div className="story-form">
        <label>
          <span>{l ? "Tiêu đề câu chuyện" : "Story title"}</span>
          <input maxLength={60} defaultValue="Hoi An 2024" />
        </label>
        <label>
          <span>{l ? "Giới thiệu" : "Intro"}</span>
          <textarea
            maxLength={300}
            placeholder={l ? "Vì sao tôi bắt đầu…" : "Why I started…"}
          />
        </label>
        <label>
          <span>
            {l ? "Tôi đã học được gì" : "What I learned"}{" "}
            <small>{l ? "Không bắt buộc" : "Optional"}</small>
          </span>
          <textarea maxLength={300} />
        </label>
        <button className="cover-picker">
          <img src={image.trip} alt="" />
          <span>
            <ImageIcon />
            {l ? "Chọn ảnh bìa" : "Pick cover photo"}
          </span>
        </button>
        <h3>{l ? "Ẩn ảnh" : "Hide photos"}</h3>
        <div className="hide-photo-grid">
          {Array.from({ length: 12 }).map((_, index) => (
            <button
              className={hidden.includes(index) ? "hidden-photo" : ""}
              key={index}
              onClick={() =>
                setHidden((current) =>
                  current.includes(index)
                    ? current.filter((item) => item !== index)
                    : [...current, index],
                )
              }
            >
              <img
                src={[image.trip, image.cooking, image.reading][index % 3]}
                alt=""
              />
              {hidden.includes(index) && <EyeOff />}
            </button>
          ))}
        </div>
        {(l
          ? [
              "Ẩn số liệu",
              "Ẩn chú thích",
              "Làm mờ ảnh trong bản xem trước liên kết",
            ]
          : ["Hide metrics", "Hide captions", "Blur photos in link previews"]
        ).map((label, index) => (
          <label className="switch-row" key={label}>
            <span>
              <strong>{label}</strong>
            </span>
            <input type="checkbox" defaultChecked={index === 0} />
          </label>
        ))}
        <button className="secondary-wide" onClick={onPreview}>
          {l ? "Xem trước như một người bạn" : "Preview as a friend"}
        </button>
      </div>
    </div>
  )
}

export function ImportedDetail({
  language,
  onBack,
  onShare,
  onInsights,
}: {
  language: Language
  onBack: () => void
  onShare: () => void
  onInsights: () => void
}) {
  const l = language === "vi"
  return (
    <div className="screen imported-detail">
      <BackHeader
        title="Hoi An 2024"
        subtitle="Memory Collectors"
        onBack={onBack}
        action={
          <button aria-label="More">
            <MoreHorizontal />
          </button>
        }
      />
      <img className="imported-cover" src={image.lanterns} alt="" />
      <section>
        <p className="eyebrow">
          {l
            ? "Kể lại · 3–6/2/2024 · theo ngày chụp"
            : "Imported · 3–6 Feb 2024 · by photo date"}
        </p>
        <h1>Hoi An 2024</h1>
        <p>
          {l
            ? "Bốn ngày đi chậm giữa những con phố vàng."
            : "Four slow days among the yellow streets."}
        </p>
        <button className="detail-link-row" onClick={onShare}>
          <Users />
          {l
            ? "Đã chia sẻ với 5 bạn · Đã bật liên kết"
            : "Shared with 5 friends · Link on"}
          <ChevronRight />
        </button>
        <button className="detail-link-row owner-line" onClick={onInsights}>
          <BarChart3 />
          1.2k views · 340 ❤️ · 28 started
          <ChevronRight />
        </button>
      </section>
      <div className="imported-moments">
        {Array.from({ length: 8 }).map((_, index) => (
          <img
            src={[image.trip, image.cooking, image.reading][index % 3]}
            alt=""
            key={index}
          />
        ))}
      </div>
    </div>
  )
}

export function SharedJourney({
  language,
  mode,
  running = false,
  preview = false,
  retold = false,
  onBack,
  onChat,
  onDo,
  onOpenApp,
  onSaved,
}: {
  language: Language
  mode: "friend" | "stranger" | "web" | "revoked"
  running?: boolean
  preview?: boolean
  retold?: boolean
  onBack: () => void
  onChat: () => void
  onDo: () => void
  onOpenApp: () => void
  onSaved: () => void
}) {
  const l = language === "vi"
  const [tab, setTab] = useState("Story")
  const [requested, setRequested] = useState(false)
  const [menu, setMenu] = useState(false)
  const [replying, setReplying] = useState<number | null>(null)
  const [replyCaption, setReplyCaption] = useState("")
  if (mode === "revoked")
    return (
      <div className="screen sharing-screen revoked-state">
        <Lock />
        <h1>
          {l
            ? "Hành trình này đã được đặt riêng tư"
            : "This journey is private now"}
        </h1>
        <button className="secondary-wide" onClick={onBack}>
          {l ? "Quay lại" : "Go back"}
        </button>
      </div>
    )
  return (
    <div
      className={`screen shared-journey-screen ${
        mode === "web" ? "web-viewer-screen" : ""
      }`}
    >
      {preview && (
        <div className="preview-strip">
          {l ? "XEM TRƯỚC NHƯ BẠN BÈ" : "PREVIEW AS A FRIEND"}
        </div>
      )}
      <header className="shared-viewer-nav">
        <button aria-label="Back" onClick={onBack}>
          <ArrowLeft />
        </button>
        <span>
          <strong>{running ? "Couch to 5K" : "Da Lat in 5 photos"}</strong>
          <small>
            <Avatar name={running ? "Nam" : "Hà"} />
            {running ? "Nam Tran" : "Hà Vu"}
            {mode === "stranger" && (
              <button onClick={() => setRequested(true)}>
                {requested
                  ? l
                    ? "Đã gửi"
                    : "Requested"
                  : l
                    ? "Thêm bạn"
                    : "Add friend"}
              </button>
            )}
          </small>
        </span>
        <button aria-label="More" onClick={() => setMenu(!menu)}>
          <MoreHorizontal />
        </button>
        {menu && (
          <div className="overflow-menu">
            <button>{l ? "Báo cáo" : "Report"}</button>
            <button>{l ? "Ẩn khỏi danh sách" : "Hide from my list"}</button>
          </div>
        )}
      </header>
      <img
        className="shared-story-cover"
        src={running ? image.run : image.pine}
        alt=""
      />
      <section className="shared-story-intro">
        <p className="eyebrow">
          {running
            ? l
              ? "TRỰC TIẾP · NGÀY 12"
              : "LIVE · DAY 12"
            : retold
              ? l
                ? "Kể lại · 3–6/2/2024 · theo ngày chụp"
                : "Imported · 3–6 Feb 2024 · by photo date"
              : "MEMORY COLLECTORS"}
        </p>
        <h1>{running ? "Couch to 5K" : "Da Lat in 5 photos"}</h1>
        <p>
          {l
            ? "Năm khoảnh khắc lạnh và trong trên cao nguyên. "
            : "Five cool, clear moments from the highlands. "}
          <button>{l ? "thêm" : "more"}</button>
        </p>
        <div className="viewer-progress">
          {running
            ? l
              ? "Trực tiếp · Ngày 12 · 🔥 12"
              : "Live · Day 12 · 🔥 12"
            : retold
              ? l
                ? "Kể lại · 3–6/2/2024 · theo ngày chụp"
                : "Imported · 3–6 Feb 2024 · by photo date"
              : l
                ? "5/5 ngày · 5 khoảnh khắc · Kết thúc 18 Thg 10"
                : "5/5 days · 5 moments · Finished Oct 18"}
        </div>
        {!running && (
          <details>
            <summary>{l ? "Tôi đã học được gì" : "What I learned"}</summary>
            <p>
              {l ? "Đi chậm để nhìn kỹ hơn." : "Slow down enough to notice."}
            </p>
          </details>
        )}
        {mode === "stranger" && (
          <p className="viewer-counts">
            ❤️ 340 · 28{" "}
            {l ? "người đã làm hành trình này" : "people did this journey"}
          </p>
        )}
      </section>
      <div className="viewer-tabs">
        <button
          className={tab === "Story" ? "selected" : ""}
          onClick={() => setTab("Story")}
        >
          {l ? "Câu chuyện" : "Story"}
        </button>
        <button
          className={tab === "Calendar" ? "selected" : ""}
          onClick={() => setTab("Calendar")}
        >
          {l ? "Lịch" : "Calendar"}
        </button>
      </div>
      <div className="viewer-moments">
        {Array.from({ length: running ? 6 : 5 }).map((_, index) => (
          <article key={index}>
            <div>
              <img
                src={
                  running
                    ? [image.run, image.pine, image.lake][index % 3]
                    : daLatPhotos[index % daLatPhotos.length]
                }
                alt=""
              />
              {running && index > 3 && <span className="new-dot" />}
            </div>
            <small>Day {index + 1}</small>
            {mode !== "web" && (
              <div className="reaction-bar">
                {(retold
                  ? ["💪", "👏", "❤️", "😂"]
                  : ["🔥", "💪", "👏", "❤️", "😂"]
                ).map((reaction) => (
                  <button
                    key={reaction}
                    onClick={mode === "stranger" ? onSaved : undefined}
                  >
                    {reaction}
                  </button>
                ))}
              </div>
            )}
            {mode === "friend" && (
              <>
                <button
                  className="reply-button"
                  onClick={() => setReplying(index)}
                >
                  <Camera />
                  {l ? "Trả lời" : "Reply"}
                </button>
                <p>
                  {l
                    ? "Chỉ Hà thấy câu trả lời của bạn"
                    : "Only Hà sees your reply"}
                </p>
              </>
            )}
          </article>
        ))}
      </div>
      {!running && mode !== "web" && (
        <button className="floating-do" onClick={onDo}>
          {l ? "Làm theo" : "Do this journey"}
        </button>
      )}
      {!running && mode === "web" && (
        <div className="web-viewer-actions">
          <button className="brand-primary" onClick={onDo}>
            {l ? "Làm theo" : "Do this journey"}
          </button>
          <button className="secondary-wide" onClick={onOpenApp}>
            {l ? "Mở ứng dụng để thích" : "Open the app to like"}
          </button>
        </div>
      )}
      {replying !== null && (
        <div
          className="modal-layer profile-layer"
          onMouseDown={() => setReplying(null)}
        >
          <section
            className="bottom-sheet reply-composer"
            onMouseDown={(event) => event.stopPropagation()}
          >
            <div className="sheet-grabber" />
            <header>
              <h2>{l ? "Trả lời bằng ảnh" : "Photo reply"}</h2>
              <button aria-label="Close" onClick={() => setReplying(null)}>
                <X />
              </button>
            </header>
            <img
              src={[image.trip, image.cooking, image.reading][replying % 3]}
              alt=""
            />
            <label>
              <span>{l ? "Chú thích" : "Caption"}</span>
              <textarea
                maxLength={140}
                value={replyCaption}
                onChange={(event) => setReplyCaption(event.target.value)}
              />
            </label>
            <p>
              {l
                ? "Chỉ Hà thấy câu trả lời của bạn"
                : "Only Hà sees your reply"}
            </p>
            <button className="brand-primary" onClick={onChat}>
              <Send />
              {l ? "Gửi" : "Send"}
            </button>
          </section>
        </div>
      )}
    </div>
  )
}

export function InboxScreen({
  language,
  onBack,
  onChat,
  onShared,
  onConsent,
  onRead,
  khoaPending,
  onKhoaHandled,
}: {
  language: Language
  onBack: () => void
  onChat: () => void
  onShared: () => void
  onConsent: () => void
  onRead: () => void
  khoaPending: boolean
  onKhoaHandled: (accept: boolean) => void
}) {
  const l = language === "vi"
  const [filter, setFilter] = useState("All")
  const [expanded, setExpanded] = useState(false)
  const open = (action: () => void) => {
    onRead()
    action()
  }
  return (
    <div className="screen sharing-screen inbox-screen">
      <BackHeader title={l ? "Hộp thư" : "Inbox"} onBack={onBack} />
      <div className="inbox-filters">
        {["All", "Replies", "Invites"].map((item, index) => (
          <button
            className={filter === item ? "selected" : ""}
            key={item}
            onClick={() => setFilter(item)}
          >
            {l ? ["Tất cả", "Trả lời", "Lời mời"][index] : item}
          </button>
        ))}
      </div>
      <div className="inbox-list">
        <button className="inbox-row unread" onClick={() => open(onChat)}>
          <span className="unread-dot" />
          <Avatar name="Nam" />
          <img src={image.reading} alt="" />
          <span>
            <strong>Nam replied to Day 12 of Daily Reading</strong>
            <small>“đọc chương mấy rồi?”</small>
          </span>
          <time>20:14</time>
        </button>
        <button className="inbox-row unread" onClick={() => open(onShared)}>
          <span className="unread-dot" />
          <Avatar name="Hà" index={1} />
          <span>
            <strong>Hà and 3 others reacted to Hoi An 2024</strong>
            <small>❤️ 🔥 👏</small>
          </span>
          <time>18:02</time>
        </button>
        {khoaPending && (
          <div className="inbox-row unread">
            <span className="unread-dot" />
            <Avatar name="Khoa" index={3} />
            <span>
              <strong>
                {l
                  ? "Lời mời kết bạn từ Khoa Le"
                  : "Friend request from Khoa Le"}
              </strong>
              <small>@khoa.le · 17:30</small>
            </span>
            <button onClick={() => onKhoaHandled(true)}>
              {l ? "Chấp nhận" : "Accept"}
            </button>
            <button
              className="quiet-action"
              onClick={() => onKhoaHandled(false)}
            >
              {l ? "Từ chối" : "Decline"}
            </button>
          </div>
        )}
        <button className="inbox-row" onClick={onShared}>
          <Avatar name="Hà" index={1} />
          <span>
            <strong>Hà shared “Da Lat in 5 photos” with you</strong>
            <small>{l ? "Hôm qua" : "Yesterday"}</small>
          </span>
          <b>{l ? "Xem" : "View"}</b>
        </button>
        <button className="inbox-row" onClick={onConsent}>
          <Users />
          <span>
            <strong>Hà wants to share Da Lat Trip outside the squad</strong>
            <small>{l ? "Thứ Ba · Bạn đã đồng ý" : "Tue · You agreed"}</small>
          </span>
          <b>{l ? "Xem lại" : "Review"}</b>
        </button>
        <button
          className="inbox-row requests-summary"
          onClick={() => setExpanded(!expanded)}
        >
          <UserPlus />
          <span>
            <strong>
              8{" "}
              {l
                ? "lời mời từ người đã xem Hoi An 2024"
                : "requests from people who saw Hoi An 2024"}
            </strong>
          </span>
          <ChevronDown />
        </button>
        {expanded && (
          <div className="viewer-requests">
            {["Tuan Vo", "Mia Nguyen", "Linh Dao"].map((name, index) => (
              <div className="person-row" key={name}>
                <Avatar name={name} index={index} />
                <span>
                  <strong>{name}</strong>
                  <small>@{name.toLowerCase().replace(" ", ".")}</small>
                  <small>Saw Hoi An 2024 · 2d</small>
                </span>
                <button>{l ? "Chấp nhận" : "Accept"}</button>
                <button className="quiet-action">
                  {l ? "Từ chối" : "Decline"}
                </button>
                <button aria-label="More">
                  <MoreHorizontal />
                </button>
              </div>
            ))}
            <button className="decline-all">
              {l ? "Từ chối tất cả" : "Decline all"}
            </button>
          </div>
        )}
      </div>
    </div>
  )
}

export function ChatScreen({
  language,
  onBack,
  onJourney,
}: {
  language: Language
  onBack: () => void
  onJourney: () => void
}) {
  const l = language === "vi"
  const [message, setMessage] = useState("")
  const [messages, setMessages] = useState<string[]>([])
  const [menuOpen, setMenuOpen] = useState(false)
  const send = () => {
    if (message.trim()) {
      setMessages((current) => [...current, message.trim()])
      setMessage("")
    }
  }
  return (
    <div className="screen chat-screen">
      <header>
        <button aria-label="Back" onClick={onBack}>
          <ArrowLeft />
        </button>
        <Avatar name="Nam" />
        <button className="chat-person" onClick={onJourney}>
          <strong>Nam Tran</strong>
          <small>Daily Reading</small>
        </button>
        <button aria-label="More" onClick={() => setMenuOpen(!menuOpen)}>
          <MoreHorizontal />
        </button>
        {menuOpen && (
          <div className="overflow-menu chat-menu">
            <button>{l ? "Tắt thông báo" : "Mute"}</button>
            <button>{l ? "Chặn" : "Block"}</button>
            <button>{l ? "Báo cáo" : "Report"}</button>
          </div>
        )}
      </header>
      <div className="chat-thread">
        <article className="photo-reply">
          <div className="reply-context">
            <span>{l ? "Đang trả lời Ngày 12" : "Replying to Day 12"}</span>
            <img src={image.reading} alt="" />
          </div>
          <img className="reply-photo" src={image.coffee} alt="" />
          <p>đọc chương mấy rồi?</p>
          <time>20:14 · Seen</time>
        </article>
        <div className="bubble mine">
          chương 6 rồi, cuốn này hay lắm<time>20:16 · Seen</time>
        </div>
        {messages.map((item, index) => (
          <div className="bubble mine" key={index}>
            {item}
            <time>21:00 · Sent</time>
          </div>
        ))}
      </div>
      <div className="chat-input">
        <button aria-label="Camera">
          <Camera />
        </button>
        <button aria-label="Photo library">
          <ImageIcon />
        </button>
        <input
          maxLength={500}
          value={message}
          onChange={(event) => setMessage(event.target.value)}
          placeholder={l ? "Tin nhắn" : "Message"}
        />
        <button aria-label="Send" onClick={send}>
          <Send />
        </button>
      </div>
    </div>
  )
}

export function DoJourneyScreen({
  language,
  onBack,
  onStart,
}: {
  language: Language
  onBack: () => void
  onStart: (expanded: boolean) => void
}) {
  const l = language === "vi"
  return (
    <div className="screen sharing-screen do-journey-screen">
      <BackHeader
        title={l ? "Làm hành trình này" : "Do this journey"}
        onBack={onBack}
      />
      <article>
        <img src={image.pine} alt="" />
        <p className="eyebrow">MEMORY COLLECTORS</p>
        <h1>
          {l
            ? "Bắt đầu hành trình Memory Collectors của riêng bạn"
            : "Start your own Memory Collectors journey"}
        </h1>
        <div>
          <span>{l ? "5 ngày" : "5 days"}</span>
          <span>{l ? "Hằng ngày" : "Daily"}</span>
          <span>{l ? "Không số liệu" : "No metrics"}</span>
        </div>
      </article>
      <section>
        <h2>{l ? "Bạn sẽ có" : "What you'll get"}</h2>
        {[
          l ? "Cùng phong cách" : "Same style",
          l ? "Cùng nhịp điệu" : "Same rhythm",
          l ? "Cùng chỉ số" : "Same metrics",
        ].map((item) => (
          <p key={item}>
            <Check />
            {item}
          </p>
        ))}
        <strong>
          {l
            ? "Ảnh và số liệu của bạn bắt đầu mới hoàn toàn."
            : "Your photos and numbers start fresh."}
        </strong>
      </section>
      <button className="brand-primary" onClick={() => onStart(false)}>
        {l ? "Bắt đầu hành trình" : "Start this journey"}
      </button>
      <button className="secondary-wide" onClick={() => onStart(true)}>
        {l ? "Thay đổi một chút" : "Change something"}
      </button>
    </div>
  )
}

export function InsightsScreen({
  language,
  onBack,
}: {
  language: Language
  onBack: () => void
}) {
  const l = language === "vi"
  const [range, setRange] = useState("7 days")
  const likers = [
    ["Hà Vu", "@ha.vu", "❤️", "2h", true],
    ["Tuan Vo", "@tuan.vo", "🔥", "3h", false],
    ["Mia Nguyen", "@mia.ng", "👏", "5h", false],
    ["Bao Le", "@bao.le", "❤️", "yesterday", true],
  ] as const
  return (
    <div className="screen sharing-screen insights-screen">
      <BackHeader
        title="Hoi An 2024"
        subtitle={
          l
            ? "Thông tin chi tiết · Memory Collectors"
            : "Insights · Memory Collectors"
        }
        onBack={onBack}
      />
      <div className="insight-numbers">
        {(l
          ? [
              ["Lượt xem", "1.2k", "+56 người xem mới tuần này"],
              ["Lượt thích", "340", "+21 tuần này"],
              ["Đã bắt đầu", "28", "+3 tuần này"],
            ]
          : [
              ["Views", "1.2k", "+56 new viewers this week"],
              ["Likes", "340", "+21 this week"],
              ["Started this journey", "28", "+3 this week"],
            ]
        ).map((stat) => (
          <div key={stat[0]}>
            <small>{stat[0]}</small>
            <strong>{stat[1]}</strong>
            <span>{stat[2]}</span>
          </div>
        ))}
      </div>
      <section className="chart-card">
        <header>
          <div>
            <h2>{l ? "Lượt xem" : "Views"}</h2>
            <p>{l ? "Số người xem mỗi ngày" : "People who viewed each day"}</p>
          </div>
          <select
            value={range}
            onChange={(event) => setRange(event.target.value)}
          >
            <option value="7 days">{l ? "7 ngày" : "7 days"}</option>
            <option value="30 days">{l ? "30 ngày" : "30 days"}</option>
            <option value="Since link on">
              {l ? "Từ khi bật liên kết" : "Since link on"}
            </option>
          </select>
        </header>
        <div className="bar-chart">
          {[42, 68, 54, 90, 75, 112, 83].map((height, index) => (
            <span key={index}>
              <i style={{ height }} />
              <small>{["F", "S", "S", "M", "T", "W", "T"][index]}</small>
            </span>
          ))}
        </div>
      </section>
      <div className="like-split">
        <strong>{l ? "Bạn bè 42" : "Friends 42"}</strong>
        <strong>{l ? "Người khác 298" : "Others 298"}</strong>
      </div>
      <section className="liker-list">
        <h2>{l ? "Lượt thích" : "Likes"}</h2>
        {likers.map((liker, index) => (
          <div className="person-row" key={liker[1]}>
            <Avatar name={liker[0]} index={index} />
            <span>
              <strong>
                {liker[0]} <b>{liker[2]}</b>
              </strong>
              <small>
                {liker[1]} · {liker[3]}
              </small>
            </span>
            {liker[4] ? (
              <em>{l ? "Bạn bè" : "Friend"}</em>
            ) : (
              <>
                <button>{l ? "Thêm bạn" : "Add friend"}</button>
                <button aria-label="More">
                  <MoreHorizontal />
                </button>
              </>
            )}
          </div>
        ))}
      </section>
      <p className="privacy-note">
        {l
          ? "Lượt xem được đếm, không liệt kê. Không ai biết bạn đã xem hành trình của họ."
          : "Views are counted, not listed. Nobody knows you saw their journey either."}
      </p>
      <section className="insight-switches">
        {(l
          ? [
              [
                "Hiện số liệu",
                "Hiện lượt thích và số người làm theo cho người xem",
              ],
              [
                "Cho phép mọi người tương tác",
                "Người có tài khoản Ourney có thể thích",
              ],
              [
                "Cho phép người xem gửi lời mời kết bạn",
                "Người xem có thể gửi lời mời kết bạn",
              ],
            ]
          : [
              ["Show counts", "Show likes and follow-alongs to viewers"],
              ["Let anyone react", "People with an Ourney account can like it"],
              [
                "Allow friend requests from viewers",
                "Viewers can send you a friend request",
              ],
            ]
        ).map(([label, helper]) => (
          <label className="switch-row" key={label}>
            <span>
              <strong>{label}</strong>
              <small>{helper}</small>
            </span>
            <input type="checkbox" defaultChecked />
          </label>
        ))}
      </section>
    </div>
  )
}

export function GetOurneyScreen({
  language,
  onBack,
}: {
  language: Language
  onBack: () => void
}) {
  const l = language === "vi"
  return (
    <div className="screen sharing-screen get-ourney-screen">
      <BackHeader title="Ourney" onBack={onBack} />
      <section>
        <span className="get-ourney-icon">O</span>
        <h1>
          {l
            ? "Làm hành trình Da Lat in 5 photos cùng Ourney"
            : "Do Da Lat in 5 photos with Ourney"}
        </h1>
        <p>
          {l
            ? "Chỉ chép khung lộ trình: mẫu, thời lượng, nhịp, chỉ số và tiêu đề. Không lấy ảnh của Hà."
            : "Only the plan is copied: template, length, rhythm, metrics and title. Not Hà's photos."}
        </p>
        <button>App Store</button>
        <button>Google Play</button>
      </section>
    </div>
  )
}

export function SquadConsentSheet({
  language,
  agreed,
  onClose,
}: {
  language: Language
  agreed: boolean
  onClose: () => void
}) {
  const l = language === "vi"
  return (
    <div className="modal-layer profile-layer" onMouseDown={onClose}>
      <section
        className="bottom-sheet consent-sheet"
        onMouseDown={(event) => event.stopPropagation()}
      >
        <div className="sheet-grabber" />
        <h2>
          {l
            ? "Hà muốn chia sẻ Da Lat Trip ra ngoài nhóm"
            : "Hà wants to share Da Lat Trip outside the squad"}
        </h2>
        <ul>
          <li>
            <Users />
            <span>
              {l
                ? "Bạn bè của thành viên có thể xem; liên kết chỉ mở khi chuyến đi kết thúc và do chủ hành trình thiết lập."
                : "Friends of members can see it; a link opens only after the trip ends and is set by the owner."}
            </span>
          </li>
          <li>
            <Eye />
            <span>
              {l
                ? "Chỉ ảnh của người đồng ý được hiển thị."
                : "Only photos of people who agree are shown."}
            </span>
          </li>
          <li>
            <Undo2 />
            <span>
              {l
                ? "Bạn có thể rút lại ảnh bất cứ lúc nào."
                : "You can take them back anytime."}
            </span>
          </li>
        </ul>
        <div className="consent-photo-grid">
          {Array.from({ length: 4 }).map((_, index) => (
            <img src={daLatPhotos[index]} alt="" key={index} />
          ))}
        </div>
        {agreed ? (
          <>
            <p className="agreed-status">
              <Check />
              {l ? "Bạn đã đồng ý" : "You agreed"}
            </p>
            <button className="danger-wide">
              {l
                ? "Xóa ảnh của tôi khỏi chia sẻ"
                : "Remove my photos from sharing"}
            </button>
          </>
        ) : (
          <>
            <button className="brand-primary" onClick={onClose}>
              {l ? "Chia sẻ ảnh của tôi" : "Share my photos"}
            </button>
            <button className="secondary-wide" onClick={onClose}>
              {l ? "Để sau" : "Not now"}
            </button>
            <button className="danger-wide" onClick={onClose}>
              {l ? "Giữ riêng ảnh của tôi" : "Keep my photos private"}
            </button>
          </>
        )}
      </section>
    </div>
  )
}
