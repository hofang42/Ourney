import { useEffect, useMemo, useRef, useState } from "react"
import {
  ArrowLeft,
  BookOpen,
  CalendarDays,
  Camera,
  Check,
  ChevronDown,
  ChevronRight,
  Circle,
  Clock3,
  Ellipsis,
  Eye,
  Flame,
  Flashlight,
  Grid3X3,
  Heart,
  Image as ImageIcon,
  Inbox,
  Languages,
  Link,
  Lock,
  Map,
  Moon,
  MoreHorizontal,
  Plus,
  RotateCcw,
  Search,
  Send,
  Share2,
  Snowflake,
  Sparkles,
  Sun,
  Timer,
  Type,
  Smile,
  Sticker,
  Activity,
  Users,
  X,
} from "lucide-react"
import LogoConcepts from "./LogoConcepts"
import {
  AddFriendsScreen,
  ChatScreen,
  DoJourneyScreen,
  FriendsScreen,
  GetOurneyScreen,
  ImportedDetail,
  InboxScreen,
  InsightsScreen,
  SharedJourney,
  SharedWithMe,
  ShareJourneySheet,
  SquadConsentSheet,
  StoryEditor,
} from "./Sharing"

type Screen = "hub" | "squad" | "camera" | "compose" | "posted" | "detail" | "wall" | "tokens" | "onboarding" | "signin" | "profileSetup" | "templates" | "quickSetup" | "friends" | "addFriends" | "imported" | "shared" | "inbox" | "chat" | "doJourney" | "insights" | "storyEditor" | "getOurney"
type OpenMode = "today" | "camera" | "journeys"
type Appearance = "system" | "light" | "dark"

const photos = {
  reading:
    "https://images.unsplash.com/photo-1707142979946-a745d1d0092c?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  body: "https://images.unsplash.com/photo-1644055154268-758a78b62d48?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  trip: "https://images.unsplash.com/photo-1660287989246-639df4884ed3?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  study:
    "https://images.unsplash.com/photo-1605915968535-7a95bcd68cab?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  cooking:
    "https://images.unsplash.com/photo-1758522489456-96afe24741dc?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  run: "https://images.unsplash.com/photo-1588786849554-ef79422ee605?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  skin: "https://images.unsplash.com/photo-1556227703-b7668d8cff99?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  baby: "https://images.unsplash.com/photo-1544126592-807ade215a0b?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  pet: "https://images.unsplash.com/photo-1779822038796-ff565c77c9b4?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  home: "https://images.unsplash.com/photo-1773581965471-98ee237dde0a?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  beach:
    "https://images.unsplash.com/photo-1732243395944-cb3ff9311091?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
  lanterns:
    "https://images.unsplash.com/photo-1563354860-799d15199ac3?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=86&w=900",
}

const styles = [
  ["Quiet Transformer", "#10B981", "#EFF3F0", "#0F172A"],
  ["Accountability Squad", "#FF9F1C", "#F7F1E5", "#1E1B18"],
  ["Memory Collectors", "#C2452B", "#F4EFE6", "#231F1E"],
  ["Couple Rituals", "#E15B72", "#F9F0EE", "#261F22"],
  ["Aesthetic Flexer", "#FF4D6D", "#F3F4F6", "#090A0F"],
  ["Minimalist Habit", "#EA580C", "#F5F3EE", "#1C1C1E"],
  ["Glow Ritual", "#A13CC9", "#FBF5FC", "#25112C"],
  ["Little Milestones", "#2AA7E0", "#F1F8FC", "#0B2233"],
  ["Paw Growth", "#6CB021", "#F5F9EC", "#172206"],
  ["Blueprint Makeover", "#1D4ED8", "#EEF3F8", "#10203A"],
] as const
const onAccentColors = [
  "#111114",
  "#111114",
  "#FFFFFF",
  "#111114",
  "#111114",
  "#111114",
  "#FFFFFF",
  "#111114",
  "#111114",
  "#FFFFFF",
] as const

const journeys = [
  {
    id: 1,
    name: "30-Day Body Archive",
    style: 0,
    image: photos.body,
    progress: "Day 22 / 30",
    streak: 21,
    done: false,
    privacy: "Private",
    detail: "Weight Hidden",
    icon: Sparkles,
  },
  {
    id: 2,
    name: "IELTS 7.5 Squad",
    style: 1,
    image: photos.study,
    progress: "Day 21 / 30",
    streak: 21,
    done: true,
    privacy: "Squad",
    detail: "45 min",
    icon: BookOpen,
  },
  {
    id: 3,
    name: "Da Lat Trip",
    style: 2,
    image: photos.trip,
    progress: "Day 4 / 5",
    streak: 4,
    done: true,
    privacy: "Squad",
    detail: "Đà Lạt · 18°C",
    icon: Map,
  },
  {
    id: 4,
    name: "Our Home Cooking",
    style: 3,
    image: photos.cooking,
    progress: "Day 18 / 100",
    streak: 18,
    done: false,
    privacy: "Couple",
    detail: "Khoa posted 07:30",
    icon: Heart,
  },
  {
    id: 5,
    name: "Morning Run Club",
    style: 4,
    image: photos.run,
    progress: "Day 21 / 30",
    streak: 21,
    done: true,
    privacy: "Private",
    detail: "92.4 km · 5:04 /km",
    icon: Flame,
  },
  {
    id: 6,
    name: "Daily Reading",
    style: 5,
    image: photos.reading,
    progress: "Day 25 / 30",
    streak: 24,
    done: false,
    privacy: "Private",
    detail: "Ends in 3h",
    icon: BookOpen,
  },
  {
    id: 7,
    name: "60-Day Skin Reset",
    style: 6,
    image: photos.skin,
    progress: "Day 28 / 60",
    streak: 12,
    done: false,
    privacy: "Private",
    detail: "Not yet today",
    icon: Sparkles,
  },
  {
    id: 8,
    name: "Baby's First Year (Bé Na)",
    style: 7,
    image: photos.baby,
    progress: "Month 6 / 12",
    streak: 6,
    done: true,
    privacy: "Squad",
    detail: "Done this month",
    icon: Heart,
  },
  {
    id: 9,
    name: "Mochi Growing Up",
    style: 8,
    image: photos.pet,
    progress: "Week 18 / 26",
    streak: 18,
    done: true,
    privacy: "Private",
    detail: "Done this week",
    icon: Heart,
  },
  {
    id: 10,
    name: "Our Apartment Makeover",
    style: 9,
    image: photos.home,
    progress: "Day 23 · Ongoing",
    streak: 3,
    done: false,
    privacy: "Couple",
    detail: "2/3 this week",
    icon: Grid3X3,
  },
]

const defaultDoneIds = journeys
  .filter((journey) => journey.done)
  .map((journey) => journey.id)
const todayOrder = [6, 1, 4, 7, 10]
const templateCopy = [
  ["Body Archive", "See small changes add up.", "Solo only"],
  ["Study Together", "Keep the group moving.", "Solo · Group"],
  ["Trip Diary", "Save each day away.", "Solo · Group"],
  ["Home Cooking", "A shared table, remembered.", "Couple only"],
  ["Run Club", "Show up, one run at a time.", "Solo · Group"],
  ["Daily Reading", "Keep a quiet reading rhythm.", "Solo only"],
  ["Skin Reset", "Notice your everyday glow.", "Solo only"],
  ["Little Milestones", "Hold onto every first.", "Solo · Group"],
  ["Growing Up", "Watch their story unfold.", "Solo · Group"],
  ["Home Makeover", "Build the before and after.", "Solo · Group"],
] as const
const templateCopyVi = [
  ["Hành trình cơ thể", "Nhìn những thay đổi nhỏ cộng lại.", "Chỉ cá nhân"],
  ["Cùng nhau học", "Giữ động lực cho cả nhóm.", "Cá nhân · Nhóm"],
  ["Nhật ký chuyến đi", "Lưu lại từng ngày đi xa.", "Cá nhân · Nhóm"],
  ["Bếp nhà mình", "Nhớ về từng bữa ăn chung.", "Chỉ cặp đôi"],
  ["Câu lạc bộ chạy", "Tiến lên qua từng buổi chạy.", "Cá nhân · Nhóm"],
  ["Đọc sách mỗi ngày", "Giữ nhịp đọc sách yên tĩnh.", "Chỉ cá nhân"],
  ["Làn da mới", "Nhìn thấy vẻ rạng rỡ mỗi ngày.", "Chỉ cá nhân"],
  ["Cột mốc nhỏ", "Giữ lại từng lần đầu tiên.", "Cá nhân · Nhóm"],
  ["Lớn lên mỗi ngày", "Theo dõi câu chuyện trưởng thành.", "Cá nhân · Nhóm"],
  ["Tổ ấm mới", "Ghi lại trước và sau.", "Cá nhân · Nhóm"],
] as const

const avatarColors = ["#E15B72", "#6D4BF0", "#2AA7E0", "#10B981", "#FF9F1C"]

function IconButton({
  label,
  children,
  onClick,
  className = "",
}: {
  label: string
  children: React.ReactNode
  onClick?: () => void
  className?: string
}) {
  return (
    <button
      aria-label={label}
      onClick={onClick}
      className={`icon-button ${className}`}
    >
      {children}
    </button>
  )
}

function Avatar({
  name = "L",
  index = 0,
  large = false,
}: {
  name?: string
  index?: number
  large?: boolean
}) {
  return (
    <span
      className={`avatar ${large ? "avatar-large" : ""}`}
      style={{ background: avatarColors[index % avatarColors.length] }}
    >
      {name[0]}
    </span>
  )
}

function Privacy({ type, dark = false }: { type: string dark?: boolean }) {
  const I =
    type === "Private"
      ? Lock
      : type === "Link on"
        ? Link
        : type === "Couple"
          ? Heart
          : Users
  return (
    <span className={`privacy ${dark ? "privacy-dark" : ""}`}>
      <I size={13} />
      {type}
    </span>
  )
}

function Dock({
  active,
  onNavigate,
  accent = "#FF3B5C",
  onToday,
  language,
}: {
  active: "hub" | "squad"
  onNavigate: (s: Screen) => void
  accent?: string
  onToday: () => void
  language: "en" | "vi"
}) {
  return (
    <nav className="dock" aria-label="Primary navigation">
      <button
        className={active === "hub" ? "active" : ""}
        onClick={() => onNavigate("hub")}
      >
        <Map />
        <span>{language === "vi" ? "Hành trình" : "Journeys"}</span>
      </button>
      <button
        className="camera-capsule"
        style={{ background: accent }}
        onClick={onToday}
        aria-label="Open Today"
      >
        <Camera />
      </button>
      <button
        className={active === "squad" ? "active" : ""}
        onClick={() => onNavigate("squad")}
      >
        <Users />
        <span>Squad</span>
      </button>
    </nav>
  )
}

function Hub({
  onOpen,
  onCamera,
  onProfile,
  onInbox,
  onNewJourney,
  onRetell,
  onSharedJourney,
  onImported,
  onShareAlbum,
  onEditImported,
  sensitiveAlbum,
  language,
  hubTab,
  setHubTab,
  onSquad,
  unreadCount,
  sharedSaved,
  doneIds = defaultDoneIds,
  visibleJourneys = journeys,
  firstJourney = false,
}: {
  onOpen: (id: number) => void
  onCamera: (id: number) => void
  onProfile: () => void
  onInbox: () => void
  onNewJourney: () => void
  onRetell: () => void
  onSharedJourney: (running?: boolean) => void
  onImported: () => void
  onShareAlbum: (album: "summer" | "phuQuoc" | "hoiAn" | "skin") => void
  onEditImported: () => void
  sensitiveAlbum: boolean
  language: "en" | "vi"
  hubTab: "active" | "shelf" | "shared"
  setHubTab: (tab: "active" | "shelf" | "shared") => void
  onSquad: () => void
  unreadCount: number
  sharedSaved: boolean
  doneIds?: number[]
  visibleJourneys?: typeof journeys
  firstJourney?: boolean
}) {
  const l = language === "vi"
  const [addMenuOpen, setAddMenuOpen] = useState(false)
  const completedIds = Array.isArray(doneIds) ? doneIds : defaultDoneIds
  const isDone = (j: typeof journeys[number]) => completedIds.includes(j.id)
  const unfinished = visibleJourneys.filter((j) => !isDone(j))
  const allDone = visibleJourneys.length > 0 && unfinished.length === 0
  const nextJourney =
    unfinished.find((journey) => journey.id === 6) ||
    unfinished[0] ||
    visibleJourneys[0]
  const nextStyle = nextJourney ? styles[nextJourney.style] : styles[5]
  const remaining = unfinished.length
  return (
    <div className="screen shell-screen hub-screen">
      <header className="topbar hub-topbar">
        <div>
          <h1>{l ? "Chào buổi tối, Linh" : "Good evening, Linh"}</h1>
        </div>
        <div className="top-actions">
          <IconButton label={l ? "Tìm hành trình" : "Search journeys"}>
            <Search />
          </IconButton>
          <IconButton
            label={l ? "Thêm hành trình" : "Add journey"}
            onClick={() => setAddMenuOpen(!addMenuOpen)}
          >
            <Plus />
          </IconButton>
          <button
            className="inbox-button"
            onClick={onInbox}
            aria-label={
              unreadCount
                ? l
                  ? `Hộp thư, ${unreadCount} chưa đọc`
                  : `Inbox, ${unreadCount} unread`
                : l
                  ? "Hộp thư"
                  : "Inbox"
            }
          >
            <Inbox />
            {unreadCount > 0 && <span aria-hidden="true" />}
          </button>
          <button
            className="avatar-button"
            onClick={onProfile}
            aria-label="Open profile"
          >
            <Avatar large />
          </button>
          {addMenuOpen && (
            <div className="hub-add-menu">
              <button
                onClick={() => {
                  setAddMenuOpen(false)
                  onNewJourney()
                }}
              >
                <Plus />
                {l ? "Hành trình mới" : "New journey"}
              </button>
              <button
                onClick={() => {
                  setAddMenuOpen(false)
                  onRetell()
                }}
              >
                <ImageIcon />
                {l ? "Kể lại một hành trình đã qua" : "Retell a past journey"}
              </button>
            </div>
          )}
        </div>
      </header>
      <p className="hub-prompt">
        {allDone
          ? l
            ? "Hôm nay xong hết rồi. Hẹn bạn ngày mai."
            : "Nothing left for today. See you tomorrow."
          : l
            ? `Còn ${remaining} hành trình chờ ảnh hôm nay.`
            : `${remaining} journeys still need today's photo.`}
      </p>
      {allDone ? (
        <div className="hub-all-done">
          <span>
            <Check />
          </span>
          <strong>{l ? "Xong hết hôm nay" : "All done for today"}</strong>
          <b>
            {visibleJourneys.length}/{visibleJourneys.length}
          </b>
        </div>
      ) : (
        <section
          className="hub-today-card"
          style={
            {
              "--journey-accent": nextStyle[1],
              "--journey-bg": nextStyle[2],
              "--journey-ink": nextStyle[3],
            } as React.CSSProperties
          }
        >
          <div className="hub-today-label">
            <span>{l ? "Hôm nay" : "Today"}</span>
            <span>{nextStyle[0]}</span>
          </div>
          <div className="hub-today-photo">
            <img
              src={nextJourney.image}
              alt={
                l
                  ? "Trà và một cuốn sách mở trên bàn gỗ"
                  : "Tea and an open book on a wooden table"
              }
            />
            <div>
              <strong>
                {l && nextJourney.id === 6
                  ? "Đọc sách mỗi ngày"
                  : nextJourney.name}
              </strong>
              <span>
                {firstJourney
                  ? l
                    ? "Ngày 1/30"
                    : "Day 1/30"
                  : l
                    ? nextJourney.progress
                        .replace("Day", "Ngày")
                        .replaceAll(" / ", "/")
                    : nextJourney.progress.replaceAll(" / ", "/")}
              </span>
            </div>
          </div>
          <div className="hub-today-status">
            <span className="hero-streak">
              <Flame />
              <strong>{firstJourney ? 0 : nextJourney.streak}</strong>
              <span>{l ? "ngày liên tiếp" : "streak"}</span>
            </span>
            <span className="hero-warning">
              <Clock3 />
              {firstJourney
                ? l
                  ? "Bắt đầu hôm nay"
                  : "Starts today"
                : nextJourney.id === 6 || nextJourney.id === 1
                  ? l
                    ? "Còn 3 giờ"
                    : "Ends in 3h"
                  : nextJourney.detail}
            </span>
          </div>
          <div
            className="hero-week"
            aria-label={l ? "Bảy ngày gần nhất" : "Last seven days"}
          >
            {[
              [l ? "T6" : "Fri", "16", photos.reading],
              [l ? "T7" : "Sat", "17", photos.study],
              [l ? "CN" : "Sun", "18", photos.cooking],
              [l ? "T2" : "Mon", "19", photos.trip],
              [l ? "T3" : "Tue", "20", photos.home],
              [l ? "T4" : "Wed", "21", photos.reading],
            ].map(([day, date, image]) => (
              <span className="hero-day" key={date}>
                <small>{day}</small>
                <span className="hero-day-photo">
                  <img src={image} alt="" />
                  <Check />
                </span>
                <b>{date}</b>
              </span>
            ))}
            <span className="hero-day hero-day-today">
              <small>{l ? "Hôm nay" : "Today"}</small>
              <span className="hero-day-empty">
                <Camera />
              </span>
              <b>22</b>
            </span>
          </div>
          <button
            className="hero-snap"
            onClick={() => onCamera(nextJourney.id)}
          >
            <Camera />
            {l ? "Chụp hôm nay" : "Snap today"}
          </button>
        </section>
      )}
      {hubTab === "active" && (
        <div className="list-heading">
          <h2>{l ? "Hành trình của bạn" : "Your journeys"}</h2>
          <button>
            <Grid3X3 /> {l ? "Sắp xếp & lọc" : "Sort & filter"}
          </button>
        </div>
      )}
      <div className="segments hub-segments">
        <button
          className={hubTab === "active" ? "selected" : ""}
          onClick={() => setHubTab("active")}
        >
          {l ? "Đang chạy" : "Active"}
        </button>
        <button
          className={hubTab === "shelf" ? "selected" : ""}
          onClick={() => setHubTab("shelf")}
        >
          {l ? "Trên kệ" : "Shelf"}
        </button>
        <button
          className={hubTab === "shared" ? "selected" : ""}
          onClick={() => setHubTab("shared")}
        >
          <span>
            {l ? "Được chia sẻ" : "Shared with me"}
            <i className="segment-new-dot" />
          </span>
        </button>
      </div>
      {hubTab === "active" ? (
        <div className="journey-list">
          {visibleJourneys.map((j) => (
            <JourneyRow
              key={j.id}
              journey={j}
              language={language}
              done={completedIds.includes(j.id)}
              hideStreak={j.id === nextJourney.id}
              onClick={() => (j.id === 2 ? onSquad() : onOpen(j.id))}
            />
          ))}
        </div>
      ) : hubTab === "shelf" ? (
        <Shelf
          language={language}
          onRetell={onRetell}
          onImported={onImported}
          onShare={onShareAlbum}
          onEdit={onEditImported}
          sensitiveAlbum={sensitiveAlbum}
        />
      ) : (
        <SharedWithMe
          language={language}
          saved={sharedSaved}
          onOpen={onSharedJourney}
        />
      )}
    </div>
  )
}

function JourneyRow({
  journey: j,
  onClick,
  language,
  done,
  hideStreak,
}: {
  journey: typeof journeys[number]
  onClick: () => void
  language: "en" | "vi"
  done: boolean
  hideStreak: boolean
}) {
  const s = styles[j.style]
  const streak = j.id === 6 && done ? 25 : j.streak
  return (
    <button className="journey-row" onClick={onClick}>
      <img src={j.image} alt="" />
      <span className="journey-copy">
        <span className="journey-name">{j.name}</span>
        <span className="style-label">
          <i style={{ background: s[1] }} />
          {s[0]}
        </span>
        <span className="row-meta">
          {!hideStreak && (
            <span>
              <Flame className="flame" />
              {streak}
            </span>
          )}
          <span className={done ? "done" : ""}>
            {done ? <Check /> : <Circle />}
            {done
              ? language === "vi"
                ? "Xong"
                : "Done"
              : language === "vi"
                ? "Chưa"
                : "Not yet"}
          </span>
          <Privacy type={j.privacy} />
        </span>
      </span>
      <ChevronRight className="chevron" />
    </button>
  )
}

function DayZeroHub({
  language,
  onProfile,
  onStart,
}: {
  language: "en" | "vi"
  onProfile: () => void
  onStart: () => void
}) {
  const l = language === "vi"
  return (
    <div className="screen shell-screen hub-screen day-zero-screen">
      <header className="topbar hub-topbar">
        <h1>{l ? "Chào Linh" : "Hi, Linh"}</h1>
        <div className="top-actions">
          <IconButton label={l ? "Tìm hành trình" : "Search journeys"}>
            <Search />
          </IconButton>
          <IconButton
            label={l ? "Thêm hành trình" : "Add journey"}
            onClick={onStart}
          >
            <Plus />
          </IconButton>
          <button
            className="avatar-button"
            onClick={onProfile}
            aria-label={l ? "Mở hồ sơ" : "Open profile"}
          >
            <Avatar large />
          </button>
        </div>
      </header>
      <div className="day-zero-content">
        <p>
          {l
            ? "Mỗi ngày một tấm ảnh để giữ lại hành trình. Bắt đầu với điều bạn quan tâm."
            : "One photo a day keeps your journey. Start with something you care about."}
        </p>
        <button className="day-zero-start" onClick={onStart}>
          {l ? "Bắt đầu hành trình đầu tiên" : "Start your first journey"}
        </button>
      </div>
    </div>
  )
}

function TemplatePicker({
  language,
  onClose,
}: {
  language: "en" | "vi"
  onClose: () => void
}) {
  const l = language === "vi"
  return (
    <div className="modal-layer profile-layer" onMouseDown={onClose}>
      <section
        className="bottom-sheet template-picker"
        onMouseDown={(event) => event.stopPropagation()}
      >
        <div className="sheet-grabber" />
        <h2>{l ? "Chọn một mẫu" : "Choose a template"}</h2>
        <button className="template-choice" onClick={onClose}>
          <span style={{ background: styles[5][2], color: styles[5][3] }}>
            <BookOpen />
          </span>
          <span>
            <strong>{l ? "Đọc sách mỗi ngày" : "Daily Reading"}</strong>
            <small>
              {l
                ? "Thói quen tối giản · 30 ngày"
                : "Minimalist Habit · 30 days"}
            </small>
          </span>
          <ChevronRight />
        </button>
        <button className="secondary-wide" onClick={onClose}>
          <Plus /> {l ? "Tự tạo hành trình" : "Create your own"}
        </button>
      </section>
    </div>
  )
}

function Shelf({
  language,
  onRetell,
  onImported,
  onShare,
  onEdit,
  sensitiveAlbum,
}: {
  language: "en" | "vi"
  onRetell: () => void
  onImported: () => void
  onShare: (album: "summer" | "phuQuoc" | "hoiAn" | "skin") => void
  onEdit: () => void
  sensitiveAlbum: boolean
}) {
  const l = language === "vi"
  const [menu, setMenu] = useState<string | null>(null)
  const albums = [
    [
      "summer",
      "Summer Vietnamese Course",
      photos.study,
      "28 / 30 DAYS",
      "Jun–Jul 2026",
    ],
    ["phuQuoc", "Phu Quoc Trip", photos.beach, "5 / 5 DAYS", "Apr 2026"],
    ["hoiAn", "Hoi An 2024", photos.lanterns, "4 DAYS · 23 PHOTOS", "Feb 2024"],
    ...(sensitiveAlbum
      ? [
          [
            "skin",
            "Summer Skin Reset",
            photos.skin,
            "60 / 60 DAYS",
            "Jun–Aug 2026",
          ],
        ]
      : []),
  ] as const
  return (
    <div className="shelf">
      <p className="shelf-intro">
        {l
          ? "Những hành trình đã xong, được giữ như album."
          : "Completed journeys, kept like albums."}
      </p>
      <div className="album-grid">
        <button className="retell-tile" onClick={onRetell}>
          <Plus />
          <strong>
            {l ? "Kể lại một hành trình đã qua" : "Retell a past journey"}
          </strong>
        </button>
        {albums.map((album, index) => (
          <article className={index > 0 ? "memory" : ""} key={album[0]}>
            <button
              className="album-cover-button"
              onClick={album[0] === "hoiAn" ? onImported : undefined}
            >
              <img src={album[2]} alt="" />
              <span className="album-band">{album[3]}</span>
              {album[0] === "hoiAn" && (
                <span className="album-badge-row">
                  <span className="imported-badge">
                    {l ? "Kể lại" : "Imported"}
                  </span>
                  <span className="album-share-badge">
                    <Users />
                  </span>
                  <span className="album-share-badge">
                    <Link />
                  </span>
                </span>
              )}
            </button>
            <button
              className="album-more"
              aria-label="More"
              onClick={() => setMenu(menu === album[1] ? null : album[1])}
            >
              <MoreHorizontal />
            </button>
            <h3>{album[1]}</h3>
            <p>{album[4]}</p>
            {menu === album[1] && (
              <div className="album-menu">
                <button
                  onClick={() => {
                    setMenu(null)
                    onShare(album[0])
                  }}
                >
                  <Share2 />
                  {l ? "Chia sẻ hành trình này" : "Share this journey"}
                </button>
                <button
                  onClick={() => {
                    setMenu(null)
                    onEdit()
                  }}
                >
                  <Type />
                  {l ? "Sửa câu chuyện" : "Edit story"}
                </button>
              </div>
            )}
          </article>
        ))}
      </div>
    </div>
  )
}

function TodaySheet({
  onClose,
  onCamera,
  language,
  doneIds = defaultDoneIds,
  visibleJourneys = journeys,
}: {
  onClose: () => void
  onCamera: (id: number) => void
  language: "en" | "vi"
  doneIds?: number[]
  visibleJourneys?: typeof journeys
}) {
  const l = language === "vi"
  const completedIds = Array.isArray(doneIds) ? doneIds : defaultDoneIds
  const unfinished = [
    ...todayOrder
      .map((id) => visibleJourneys.find((journey) => journey.id === id))
      .filter((journey): journey is typeof journeys[number] =>
        Boolean(journey),
      ),
    ...visibleJourneys.filter((journey) => !todayOrder.includes(journey.id)),
  ].filter((journey) => !completedIds.includes(journey.id))
  const allDone = visibleJourneys.length > 0 && unfinished.length === 0
  const orderedIds = [6, 1, 4, 7, 10]
  const rows = orderedIds
    .filter((id) => unfinished.some((journey) => journey.id === id))
    .map(
      (id) =>
        [
          id,
          id === 6 || id === 1
            ? l
              ? "Sắp đứt chuỗi"
              : "At risk"
            : id === 4
              ? l
                ? "Nhóm đang chờ"
                : "Squad is waiting"
              : l
                ? "Còn lại"
                : "Everything else",
        ] as const,
    )
  const doneCount = visibleJourneys.length - unfinished.length
  return (
    <div className="modal-layer" onMouseDown={onClose}>
      <div className="camera-underlay">
        <Camera size={40} />
        <span>{l ? "Camera sẵn sàng" : "Camera ready"}</span>
      </div>
      <section
        className="bottom-sheet today-sheet"
        onMouseDown={(e) => e.stopPropagation()}
      >
        <div className="sheet-grabber" />
        {allDone ? (
          <>
            <div className="all-done-illustration">
              <Check />
            </div>
            <div className="all-done-heading">
              <h2>{l ? "Xong hết hôm nay rồi 🎉" : "All done for today 🎉"}</h2>
              <p>
                {doneCount}/{visibleJourneys.length} {l ? "đã xong" : "done"}
              </p>
            </div>
            <div className="today-group all-done-list">
              {visibleJourneys.map((journey) => (
                <button key={journey.id} onClick={() => onCamera(journey.id)}>
                  <span
                    className="template-mark"
                    style={{ background: styles[journey.style][1] }}
                  >
                    <journey.icon />
                  </span>
                  <span className="today-copy">
                    <strong>{journey.name}</strong>
                    <small>{styles[journey.style][0]}</small>
                  </span>
                  <span className="add-more-label">
                    {l ? "Thêm ảnh" : "Add more"}
                  </span>
                </button>
              ))}
            </div>
          </>
        ) : (
          <>
            <header>
              <div>
                <p className="eyebrow">
                  {l ? `CÒN ${unfinished.length}` : `${unfinished.length} LEFT`}
                </p>
                <h2>{l ? "Hôm nay" : "Today"}</h2>
              </div>
              <div className="progress-ring">
                <strong>{doneCount}</strong>
                <span>/{visibleJourneys.length}</span>
              </div>
            </header>
            <button className="secondary-wide" onClick={onClose}>
              {l ? "Mở hành trình" : "Open my journeys"}
              <ChevronRight />
            </button>
            {["At risk", "Squad is waiting", "Everything else"].map(
              (section, si) => {
                const title = l
                  ? ["Sắp đứt chuỗi", "Nhóm đang chờ", "Còn lại"][si]
                  : section
                const group = rows.filter((r) => r[1] === title)
                return (
                  <div className="today-group" key={section}>
                    <h3>{title}</h3>
                    {group.map(([id]) => {
                      const j = journeys.find((x) => x.id === id)!
                      return (
                        <button key={id} onClick={() => onCamera(id)}>
                          <span
                            className="template-mark"
                            style={{ background: styles[j.style][1] }}
                          >
                            <j.icon />
                          </span>
                          <span className="today-copy">
                            <strong>{j.name}</strong>
                            {id === 1 || id === 6 ? (
                              <small className="today-warning">
                                <Clock3 />
                                {l ? "Còn 3 giờ" : "Ends in 3h"}
                              </small>
                            ) : (
                              <small>
                                {id === 4
                                  ? "Khoa posted"
                                  : id === 10
                                    ? "2/3 this week · until Sunday"
                                    : j.detail}
                              </small>
                            )}
                          </span>
                          <span className="today-streak">
                            <Flame />
                            {j.streak}
                          </span>
                          <ChevronRight />
                        </button>
                      )
                    })}
                  </div>
                )
              },
            )}
          </>
        )}
      </section>
    </div>
  )
}

function CameraScreen({
  journeyId,
  setJourneyId,
  onShutter,
  onBack,
  onNavigate,
  language,
  doneIds = defaultDoneIds,
  visibleJourneys = journeys,
  firstJourney = false,
}: {
  journeyId: number
  setJourneyId: (id: number) => void
  onShutter: () => void
  onBack: () => void
  onNavigate: (screen: Screen) => void
  language: "en" | "vi"
  doneIds?: number[]
  visibleJourneys?: typeof journeys
  firstJourney?: boolean
}) {
  const [touchStart, setTouchStart] = useState<number | null>(null)
  const completedIds = Array.isArray(doneIds) ? doneIds : defaultDoneIds
  const unfinished = [
    ...todayOrder
      .map((id) => visibleJourneys.find((journey) => journey.id === id))
      .filter((journey): journey is typeof journeys[number] =>
        Boolean(journey),
      ),
    ...visibleJourneys.filter((journey) => !todayOrder.includes(journey.id)),
  ].filter((journey) => !completedIds.includes(journey.id))
  const j = journeys.find((x) => x.id === journeyId) || journeys[5]
  const s = styles[j.style]
  const next = () => {
    if (unfinished.length < 2) return
    setJourneyId(
      unfinished[
        (unfinished.findIndex((x) => x.id === j.id) + 1) % unfinished.length
      ].id,
    )
  }
  return (
    <div className="screen camera-screen">
      <div className="camera-top">
        <button className="glass-chip" onClick={onBack}>
          <ArrowLeft />
          <span>{j.name}</span>
          <ChevronDown />
        </button>
        <span className="glass-chip count">
          {firstJourney ? (
            <>
              <Flame /> 0
            </>
          ) : (
            "0 today"
          )}
        </span>
      </div>
      <button
        className="viewfinder"
        onClick={next}
        onTouchStart={(e) => setTouchStart(e.touches[0].clientX)}
        onTouchEnd={(e) => {
          if (
            touchStart !== null &&
            Math.abs(e.changedTouches[0].clientX - touchStart) > 35
          )
            next()
          setTouchStart(null)
        }}
        aria-label="Switch to next unfinished journey"
      >
        <img src={j.image} alt={`${j.name} camera preview`} />
        <span className="day-hud">
          {firstJourney ? (
            "Day 1/30"
          ) : (
            <>
              Day{" "}
              {j.id === 6
                ? 25
                : j.id === 1
                  ? 22
                  : j.id === 4
                    ? 18
                    : j.id === 7
                      ? 28
                      : 23}
            </>
          )}
        </span>
        {unfinished.length > 1 && (
          <span className="swipe-hint">Swipe for next journey</span>
        )}
      </button>
      <div className="camera-tools">
        <IconButton label="Flash">
          <Flashlight />
        </IconButton>
        <IconButton label="3 second timer">
          <Timer />
        </IconButton>
        <IconButton label="Grid">
          <Grid3X3 />
        </IconButton>
      </div>
      {unfinished.length > 1 && (
        <div className="page-dots">
          {unfinished.map((x) => (
            <i key={x.id} className={x.id === j.id ? "on" : ""} />
          ))}
        </div>
      )}
      <div className="camera-secondary-controls">
        <button aria-label="Open photo library" className="library-thumb">
          <img src={photos.trip} alt="" />
        </button>
        <span />
        <IconButton label="Flip camera">
          <RotateCcw />
        </IconButton>
      </div>
      <nav className="camera-dock" aria-label="Camera navigation">
        <button onClick={() => onNavigate("hub")}>
          <Map />
          <span>{language === "vi" ? "Hành trình" : "Journeys"}</span>
        </button>
        <button
          aria-label="Take photo"
          className="shutter"
          style={{ "--accent": s[1] } as React.CSSProperties}
          onClick={onShutter}
        >
          <span />
        </button>
        <button onClick={() => onNavigate("squad")}>
          <Users />
          <span>Squad</span>
        </button>
      </nav>
    </div>
  )
}

function Compose({
  journeyId,
  onBack,
  onPost,
}: {
  journeyId: number
  onBack: () => void
  onPost: () => void
}) {
  const j = journeys.find((x) => x.id === journeyId) || journeys[5]
  const s = styles[j.style]
  const [tool, setTool] = useState<string | null>(null)
  return (
    <div
      className="screen compose-screen"
      style={
        {
          "--accent": s[1],
          "--on-accent": s[3],
          "--accent-ink": j.style === 5 ? "#B33A0A" : s[1],
        } as React.CSSProperties
      }
    >
      <header className="compose-header">
        <button onClick={onBack}>Retake</button>
        <div>
          <strong>{j.name}</strong>
          <Privacy type={j.privacy} />
        </div>
        <button className="post-link" onClick={onPost}>
          Post
        </button>
      </header>
      <img className="compose-photo" src={j.image} alt={`${j.name} moment`} />
      <div className="toolbar">
        <button
          className={tool === "Caption" ? "selected" : ""}
          onClick={() => setTool("Caption")}
        >
          <Type />
          <small>Caption</small>
        </button>
        <button
          className={tool === "Mood" ? "selected" : ""}
          onClick={() => setTool("Mood")}
        >
          <Smile />
          <small>Mood</small>
        </button>
        <button
          className={tool === "Sticker" ? "selected" : ""}
          onClick={() => setTool("Sticker")}
        >
          <Sticker />
          <small>Sticker</small>
        </button>
        <button
          className={tool === "Metrics" ? "selected" : ""}
          onClick={() => setTool("Metrics")}
        >
          <Activity />
          <small>Metrics</small>
        </button>
        <button
          className={tool === "More" ? "selected" : ""}
          onClick={() => setTool("More")}
        >
          <Plus />
          <small>More</small>
        </button>
      </div>
      {tool === "Mood" && (
        <div className="mood-picker">
          {["Great", "Good", "Okay", "Tired", "Low", "Proud"].map((m, i) => (
            <button key={m}>
              <span>{["◡", "⌣", "—", "⌢", "︵", "◇"][i]}</span>
              {m}
            </button>
          ))}
        </div>
      )}
      <label className="caption-field">
        <span>Caption</span>
        <textarea maxLength={140} placeholder="What's new today?" />
      </label>
      <button className="primary-wide" onClick={onPost}>
        Post moment
        <Send />
      </button>
    </div>
  )
}

function Posted({
  onNext,
  onDone,
  image,
  firstJourney,
  nextJourney,
  language,
}: {
  onNext: () => void
  onDone: () => void
  image: string
  firstJourney: boolean
  nextJourney?: typeof journeys[number]
  language: "en" | "vi"
}) {
  const l = language === "vi"
  return (
    <div className="screen posted-screen">
      <header>
        <span className="success-mark">
          <Check />
        </span>
        <p>Moment posted</p>
        <h1>Chain kept.</h1>
      </header>
      <div className="mini-calendar">
        <div className="mini-days">
          {["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"].map((d) => (
            <span key={d}>{d}</span>
          ))}
        </div>
        <div className="mini-cells">
          {Array.from({ length: 28 }).map((_, i) => (
            <span
              key={i}
              className={
                firstJourney
                  ? i < 3
                    ? "prestart"
                    : i === 3
                      ? "today-photo"
                      : ""
                  : i === 24
                    ? "today-photo"
                    : i < 24
                      ? "filled"
                      : ""
              }
            >
              {firstJourney && i === 3 ? (
                <img src={image} alt="" />
              ) : !firstJourney && i === 24 ? (
                <img src={image} alt="" />
              ) : !firstJourney && i < 24 ? (
                <Check />
              ) : null}
            </span>
          ))}
        </div>
        <span className="stamp">{firstJourney ? "DAY 1" : "DAY 25"}</span>
      </div>
      <div className="streak-celebrate">
        <Flame />
        <strong>{firstJourney ? 1 : 25}</strong>
        <span>{firstJourney ? (l ? "ngày" : "day") : l ? "ngày" : "days"}</span>
      </div>
      <p className="celebration-copy">
        {firstJourney
          ? l
            ? "Ngày đầu tiên. Con tem đầu tiên."
            : "Day one. The first stamp."
          : "Twenty-five quiet promises kept to yourself."}
      </p>
      <div className="posted-actions">
        {nextJourney && (
          <button className="primary-wide" onClick={onNext}>
            {l ? "Tiếp theo" : "Next"}: {nextJourney.name}
            <ChevronRight />
          </button>
        )}
        <button className="secondary-wide" onClick={onDone}>
          Done
        </button>
      </div>
    </div>
  )
}

function Detail({
  onBack,
  onCheckIn,
  onShare,
  language,
  dailyReadingPosted,
}: {
  onBack: () => void
  onCheckIn: () => void
  onShare: () => void
  language: "en" | "vi"
  dailyReadingPosted: boolean
}) {
  const l = language === "vi"
  const [tab, setTab] = useState("Story")
  const [scale, setScale] = useState("Day")
  const [shareMenu, setShareMenu] = useState(false)
  const dateNumbers = [
    28, 29, 30, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
    19, 20, 21, 22, 23, 24, 25, 26, 27,
  ]
  return (
    <div className="screen detail-screen">
      <header className="detail-nav">
        <IconButton label="Back" onClick={onBack}>
          <ArrowLeft />
        </IconButton>
        <div>
          <strong>Daily Reading</strong>
          <Privacy type="Private" />
        </div>
        <IconButton label="Share journey" onClick={() => setShareMenu(true)}>
          <Share2 />
        </IconButton>
        <IconButton label="More options">
          <MoreHorizontal />
        </IconButton>
      </header>
      <section className="detail-hero">
        <p className="eyebrow">MON 28 SEP — TUE 27 OCT</p>
        <h1>Daily Reading</h1>
        <div className="progress-label">
          <strong>Day 25 / 30</strong>
          <span>83%</span>
        </div>
        <div className="progress-track">
          <i />
        </div>
        <div className="stat-grid">
          <div>
            <span>
              <Flame />
              CURRENT
            </span>
            <strong>
              {dailyReadingPosted ? 25 : 24} <small>days</small>
            </strong>
          </div>
          <div>
            <span>LONGEST</span>
            <strong>{dailyReadingPosted ? 25 : 24}</strong>
          </div>
          <div>
            <span>MOMENTS</span>
            <strong>{dailyReadingPosted ? 25 : 24}</strong>
          </div>
          <div>
            <span>
              <Snowflake />
              FREEZE
            </span>
            <strong>
              2 <small>left</small>
            </strong>
          </div>
        </div>
      </section>
      <div className="detail-tabs">
        {["Story", "Calendar", "Stats"].map((t) => (
          <button
            key={t}
            className={tab === t ? "selected" : ""}
            onClick={() => setTab(t)}
          >
            {t}
          </button>
        ))}
      </div>
      {tab === "Story" && (
        <section className="chain-section">
          <p className="eyebrow">DON'T BREAK THE CHAIN</p>
          <h2>One page at a time.</h2>
          <p className="muted">Every square is a promise you kept.</p>
          <div className="week-head">
            {["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"].map((d) => (
              <span key={d}>{d}</span>
            ))}
          </div>
          <div
            className={`chain-grid ${dailyReadingPosted ? "posted-chain" : ""}`}
          >
            {dateNumbers.map((d, i) => (
              <span
                key={i}
                className={
                  i < 24 || (dailyReadingPosted && i === 24)
                    ? "complete"
                    : i === 24
                      ? "today"
                      : "future"
                }
              >
                {(i < 24 || (dailyReadingPosted && i === 24)) && (
                  <img
                    src={
                      dailyReadingPosted && i === 24
                        ? photos.reading
                        : i % 3 === 0
                          ? photos.reading
                          : i % 3 === 1
                            ? photos.study
                            : photos.cooking
                    }
                    alt=""
                  />
                )}
                <b>{d}</b>
                {i === 24 && !dailyReadingPosted && <Plus />}
              </span>
            ))}
          </div>
        </section>
      )}
      {tab === "Calendar" && (
        <section className="calendar-pane">
          <div className="small-toggle">
            {["Day", "Week", "Month"].map((v) => (
              <button
                key={v}
                className={scale === v ? "selected" : ""}
                onClick={() => setScale(v)}
              >
                {v}
              </button>
            ))}
          </div>
          <CalendarDays />
          <h2>{scale} view</h2>
          <p>Your 24 reading moments are ready to revisit.</p>
        </section>
      )}
      {tab === "Stats" && (
        <section className="calendar-pane">
          <Flame />
          <h2>24-day rhythm</h2>
          <p>
            Most check-ins happen between 8 and 10 PM. Consistency, not
            comparison.
          </p>
        </section>
      )}
      <button className="floating-check" onClick={onCheckIn}>
        <Camera />
        {dailyReadingPosted ? "Add more" : "Check in"}
      </button>
      {shareMenu && (
        <div
          className="modal-layer profile-layer"
          onMouseDown={() => setShareMenu(false)}
        >
          <section
            className="bottom-sheet detail-share-sheet"
            onMouseDown={(event) => event.stopPropagation()}
          >
            <div className="sheet-grabber" />
            <button>
              <ImageIcon />
              <span>
                <strong>
                  {l ? "Tạo thẻ hoặc video" : "Make a card or video"}
                </strong>
                <small>
                  {l
                    ? "Chia sẻ một khoảnh khắc"
                    : "Share a moment from this journey"}
                </small>
              </span>
              <ChevronRight />
            </button>
            <button
              onClick={() => {
                setShareMenu(false)
                onShare()
              }}
            >
              <Share2 />
              <span>
                <strong>
                  {l ? "Chia sẻ hành trình này" : "Share this journey"}
                </strong>
                <small>
                  {l
                    ? "Chọn bạn bè có thể theo dõi"
                    : "Choose friends who can follow along"}
                </small>
              </span>
              <ChevronRight />
            </button>
          </section>
        </div>
      )}
    </div>
  )
}

function SquadWall({ onBack }: { onBack: () => void }) {
  const people = [
    ["Linh", "06:10", "21", photos.reading],
    ["Nam", "06:25", "18", photos.study],
    ["Hà", "07:00", "9", photos.cooking],
    ["Lan", "07:40", "21", photos.trip],
  ]
  return (
    <div className="screen wall-screen">
      <header className="detail-nav">
        <IconButton label="Back" onClick={onBack}>
          <ArrowLeft />
        </IconButton>
        <div>
          <strong>IELTS 7.5 Squad</strong>
          <Privacy type="Squad" />
        </div>
        <IconButton label="More options">
          <MoreHorizontal />
        </IconButton>
      </header>
      <section className="shared-streak">
        <span>
          <Flame /> SHARED STREAK
        </span>
        <strong>
          21 <small>days</small>
        </strong>
        <div>
          <i />
          <span>4/5 checked in today</span>
        </div>
      </section>
      <div className="polaroid-grid">
        {people.map((p, i) => (
          <article className="polaroid" key={p[0]}>
            <div className="polaroid-photo">
              <img src={p[3]} alt={`${p[0]}'s study moment`} />
              <Check />
            </div>
            <div className="polaroid-name">
              <strong>{p[0]}</strong>
              <span>{p[1]}</span>
            </div>
            <small>
              <Flame /> {p[2]} day streak
            </small>
            <div className="reactions">
              <button>🔥</button>
              <button>💪</button>
              <button>👏</button>
              <button>❤️</button>
              <button>😂</button>
            </div>
          </article>
        ))}
        <article className="waiting-tile">
          <Avatar name="M" index={4} large />
          <strong>Minh · waiting</strong>
          <p>The day is still open.</p>
          <button disabled>
            Nudge 👋 <small>Coming soon</small>
          </button>
        </article>
      </div>
    </div>
  )
}

function SquadTab({
  onWall,
  onShare,
}: {
  onWall: () => void
  onShare: () => void
}) {
  const groupIds = [2, 3, 4, 10, 8]
  return (
    <div className="screen shell-screen">
      <header className="topbar">
        <div>
          <p className="eyebrow">YOUR PEOPLE</p>
          <h1>Squad</h1>
        </div>
        <IconButton label="Squad options">
          <MoreHorizontal />
        </IconButton>
      </header>
      <div className="group-actions">
        <button>
          <Link />
          Join with code
        </button>
        <button>
          <Plus />
          Start a group journey
        </button>
      </div>
      <div className="group-list">
        {groupIds.map((id, i) => {
          const j = journeys.find((x) => x.id === id)!
          return (
            <button
              key={id}
              className="group-card"
              onClick={id === 2 ? onWall : id === 3 ? onShare : undefined}
              style={{ "--accent": styles[j.style][1] } as React.CSSProperties}
            >
              <img src={j.image} alt="" />
              <span className="group-copy">
                <small>{styles[j.style][0]}</small>
                <strong>{j.name}</strong>
                <span>{id === 2 ? "4/5 checked in" : j.detail}</span>
                <span className="avatar-stack">
                  {[0, 1, 2].map((a) => (
                    <Avatar key={a} name={["L", "K", "N"][a]} index={a + i} />
                  ))}
                </span>
              </span>
              <ChevronRight />
            </button>
          )
        })}
      </div>
    </div>
  )
}

function ProfileSheet({
  appearance,
  setAppearance,
  language,
  setLanguage,
  onClose,
  onTokens,
  onLogo,
  openMode,
  setOpenMode,
  onRestart,
  onFriends,
  onInsights,
  friendCount,
}: {
  appearance: Appearance
  setAppearance: (a: Appearance) => void
  language: "en" | "vi"
  setLanguage: (l: "en" | "vi") => void
  onClose: () => void
  onTokens: () => void
  onLogo: () => void
  openMode: OpenMode
  setOpenMode: (mode: OpenMode) => void
  onRestart: () => void
  onFriends: () => void
  onInsights: () => void
  friendCount: number
}) {
  const l = language === "vi"
  return (
    <div className="modal-layer profile-layer" onMouseDown={onClose}>
      <section
        className="bottom-sheet profile-sheet"
        onMouseDown={(e) => e.stopPropagation()}
      >
        <div className="sheet-grabber" />
        <header>
          <div className="profile-person">
            <Avatar large />
            <span>
              <strong>Linh Tran</strong>
              <small>@linh.tran · Free plan</small>
            </span>
          </div>
          <IconButton label="Close profile" onClick={onClose}>
            <X />
          </IconButton>
        </header>
        <div className="profile-stats">
          <span>
            <strong>312</strong> moments
          </span>
          <span>
            <strong>41</strong> longest streak
          </span>
          <span>
            <strong>2</strong> freezes left
          </span>
        </div>
        <button
          className="tokens-link profile-sharing-link"
          onClick={onFriends}
        >
          <span>
            <strong>{l ? "Bạn bè" : "Friends"}</strong>
            <small>
              {l
                ? `${friendCount} · chỉ bạn thấy`
                : `${friendCount} · only you see this`}
            </small>
          </span>
          <ChevronRight />
        </button>
        <button
          className="tokens-link profile-sharing-link"
          onClick={onInsights}
        >
          <span>
            <strong>{l ? "Câu chuyện của bạn" : "Your stories"}</strong>
            <small>
              {l
                ? "Đã chạm tới 1.2k người · 340 ❤️ · 28 bắt đầu"
                : "Reached 1.2k people · 340 ❤️ · 28 started"}
            </small>
          </span>
          <ChevronRight />
        </button>
        <h3>
          <Sun />
          Appearance
        </h3>
        <div className="option-row">
          {(["system", "light", "dark"] as Appearance[]).map((a) => (
            <button
              key={a}
              className={appearance === a ? "selected" : ""}
              onClick={() => setAppearance(a)}
            >
              {a === "system" ? (
                <Sparkles />
              ) : a === "light" ? (
                <Sun />
              ) : (
                <Moon />
              )}
              {a[0].toUpperCase() + a.slice(1)}
            </button>
          ))}
        </div>
        <h3>
          <Languages />
          Language
        </h3>
        <div className="option-row two">
          <button
            className={language === "en" ? "selected" : ""}
            onClick={() => setLanguage("en")}
          >
            English
          </button>
          <button
            className={language === "vi" ? "selected" : ""}
            onClick={() => setLanguage("vi")}
          >
            Tiếng Việt
          </button>
        </div>
        <h3>
          <Camera />
          {l ? "Mở app vào" : "Open app on"}
        </h3>
        <div className="option-row open-mode-row">
          {(["today", "camera", "journeys"] as OpenMode[]).map((mode) => (
            <button
              key={mode}
              className={openMode === mode ? "selected" : ""}
              onClick={() => setOpenMode(mode)}
            >
              {mode === "today"
                ? l
                  ? "Bảng hôm nay"
                  : "Today picker"
                : mode === "camera"
                  ? "Camera"
                  : l
                    ? "Hành trình"
                    : "Journeys"}
            </button>
          ))}
        </div>
        <button className="tokens-link" onClick={onTokens}>
          <span>
            <strong>Design tokens</strong>
            <small>Shell and 10 style palettes</small>
          </span>
          <ChevronRight />
        </button>
        <button className="tokens-link logo-concepts-link" onClick={onLogo}>
          <span>
            <strong>Logo concepts</strong>
            <small>Round 1 presentation board</small>
          </span>
          <ChevronRight />
        </button>
        <button className="restart-flow" onClick={onRestart}>
          <RotateCcw />
          {l ? "Khởi động lại luồng" : "Restart flow"}
        </button>
      </section>
    </div>
  )
}

function Tokens({ onBack }: { onBack: () => void }) {
  return (
    <div className="screen tokens-screen">
      <header className="detail-nav">
        <IconButton label="Back" onClick={onBack}>
          <ArrowLeft />
        </IconButton>
        <div>
          <strong>Design tokens</strong>
          <small>Contrast review</small>
        </div>
      </header>
      <section>
        <p className="eyebrow">SHELL · LIGHT</p>
        <h1>Neutral by design.</h1>
        <p className="muted">
          Accent colors lead indicators and fills, never body copy.
        </p>
        <div className="swatch-grid">
          {[
            ["Background", "#FAFAF7", "#111114", "Ink 18.03:1"],
            ["Surface", "#FFFFFF", "#111114", "Ink 18.85:1"],
            ["Brand", "#FF3B5C", "#111114", "On-brand 5.41:1"],
            ["Muted", "#F1F1EC", "#5E5E66", "Muted ink 5.67:1"],
          ].map((x) => (
            <div key={x[0]} style={{ background: x[1], color: x[2] }}>
              <strong>{x[0]}</strong>
              <span>{x[1]}</span>
              <small>{x[3]}</small>
            </div>
          ))}
        </div>
      </section>
      <section>
        <p className="eyebrow">JOURNEY STYLES</p>
        <div className="palette-list">
          {styles.map((s, i) => (
            <article key={s[0]} style={{ background: s[2], color: s[3] }}>
              <i style={{ background: s[1] }} />
              <span>
                <strong>
                  {i + 1}. {s[0]}
                </strong>
                <small>
                  {s[2]} · {s[1]}
                </small>
              </span>
              <b>
                {
                  [
                    "15.94:1",
                    "15.24:1",
                    "14.26:1",
                    "14.39:1",
                    "17.97:1",
                    "15.34:1",
                    "16.37:1",
                    "15.16:1",
                    "15.49:1",
                    "14.59:1",
                  ][i]
                }
              </b>
            </article>
          ))}
        </div>
      </section>
    </div>
  )
}

function Wordmark() {
  return <strong className="wordmark">ourney</strong>
}

function Splash() {
  return (
    <div className="splash-screen">
      <Wordmark />
    </div>
  )
}

function Onboarding({
  language,
  setLanguage,
  onDone,
}: {
  language: "en" | "vi"
  setLanguage: (language: "en" | "vi") => void
  onDone: () => void
}) {
  const [page, setPage] = useState(0)
  const l = language === "vi"
  const titles = l
    ? [
        "Từng tấm ảnh. Cả một câu chuyện.",
        "Hành trình nào cũng được. Một mình, cùng nhóm, hay cùng người thương.",
        "Biến hành trình thành thứ đáng để chia sẻ.",
      ]
    : [
        "One photo at a time. A whole story.",
        "Any journey. Alone, with others, or with your person.",
        "Turn it into something worth sharing.",
      ]
  const body = l
    ? [
        "Ghi lại hôm nay để thấy câu chuyện lớn dần.",
        "Chọn cách đồng hành phù hợp với bạn.",
        "Tạo nên những bản tổng kết bạn muốn giữ mãi.",
      ]
    : [
        "Keep today, then watch the bigger story take shape.",
        "Choose the kind of company that fits your journey.",
        "Make recaps you will want to keep and share.",
      ]
  return (
    <div className="screen first-run-screen onboarding-screen">
      <header className="first-run-top">
        {page === 0 ? (
          <button
            className="language-chip"
            onClick={() => setLanguage(l ? "en" : "vi")}
          >
            <Languages /> {l ? "Tiếng Việt" : "English"}
          </button>
        ) : (
          <span />
        )}
        <button className="text-action" onClick={onDone}>
          {l ? "Bỏ qua" : "Skip"}
        </button>
      </header>
      <div className={`onboarding-art art-${page + 1}`}>
        {page === 0 &&
          [
            photos.reading,
            photos.study,
            photos.trip,
            photos.cooking,
            photos.run,
            photos.home,
          ].map((photo, index) => (
            <img
              src={photo}
              alt=""
              key={photo}
              style={{ "--i": index } as React.CSSProperties}
            />
          ))}
        {page === 1 &&
          styles.map((style, index) => (
            <span
              key={style[0]}
              style={
                {
                  "--i": index,
                  "--card-accent": style[1],
                  "--card-bg": style[2],
                } as React.CSSProperties
              }
            >
              {style[0]}
            </span>
          ))}
        {page === 2 && (
          <>
            <div className="recap-card">
              <img src={photos.reading} alt="" />
              <strong>30 quiet days</strong>
              <small>Daily Reading · October</small>
            </div>
            <div className="recap-story">
              <Share2 />
              <span>Worth sharing</span>
            </div>
          </>
        )}
      </div>
      <div className="onboarding-copy">
        <h1>{titles[page]}</h1>
        <p>{body[page]}</p>
        <div className="page-dots onboarding-dots">
          {[0, 1, 2].map((dot) => (
            <i className={dot === page ? "on" : ""} key={dot} />
          ))}
        </div>
        <button
          className="brand-primary"
          onClick={() => (page === 2 ? onDone() : setPage(page + 1))}
        >
          {l ? "Tiếp tục" : "Continue"}
        </button>
      </div>
    </div>
  )
}

function SignIn({
  language,
  onDone,
}: {
  language: "en" | "vi"
  onDone: () => void
}) {
  const [sent, setSent] = useState(false)
  const [seconds, setSeconds] = useState(60)
  const l = language === "vi"
  useEffect(() => {
    if (!sent || seconds === 0) return
    const timer = window.setTimeout(() => setSeconds(seconds - 1), 1000)
    return () => window.clearTimeout(timer)
  }, [sent, seconds])
  return (
    <div className="screen first-run-screen auth-screen">
      <header>
        <Wordmark />
      </header>
      <section>
        <p className="eyebrow">
          {sent ? (l ? "KIỂM TRA EMAIL" : "CHECK YOUR EMAIL") : "OURNEY"}
        </p>
        <h1>{l ? "Lưu giữ hành trình của bạn" : "Save your journeys"}</h1>
        {!sent ? (
          <>
            <label className="field-label">
              <span>Email</span>
              <input type="email" defaultValue="linh@example.com" />
            </label>
            <button className="brand-primary" onClick={() => setSent(true)}>
              {l ? "Gửi mã" : "Send code"}
            </button>
          </>
        ) : (
          <>
            <div className="otp-row" aria-label="Six digit code">
              {[0, 1, 2, 3, 4, 5].map((digit) => (
                <input
                  key={digit}
                  inputMode="numeric"
                  maxLength={1}
                  defaultValue={digit === 0 ? "2" : ""}
                />
              ))}
            </div>
            <button className="brand-primary" onClick={onDone}>
              {l ? "Xác nhận" : "Verify code"}
            </button>
            <p className="resend-copy">
              {l ? "Gửi lại sau" : "Resend in"} {seconds}s
            </p>
            <button
              className="text-action auth-link"
              onClick={() => {
                setSent(false)
                setSeconds(60)
              }}
            >
              {l ? "Dùng email khác" : "Use a different email"}
            </button>
          </>
        )}
      </section>
      <footer>
        <button>{l ? "Điều khoản" : "Terms"}</button>
        <span>·</span>
        <button>{l ? "Quyền riêng tư" : "Privacy"}</button>
      </footer>
    </div>
  )
}

function ProfileSetup({
  language,
  onDone,
}: {
  language: "en" | "vi"
  onDone: () => void
}) {
  const l = language === "vi"
  const [avatarIndex, setAvatarIndex] = useState(0)
  return (
    <div className="screen first-run-screen setup-form-screen">
      <header>
        <h1>{l ? "Hồ sơ của bạn" : "Your profile"}</h1>
      </header>
      <button
        className="avatar-picker"
        onClick={() => setAvatarIndex((avatarIndex + 1) % avatarColors.length)}
        aria-label={l ? "Chọn ảnh đại diện" : "Pick an avatar"}
      >
        <Avatar name="L" index={avatarIndex} large />
        <Camera />
      </button>
      <label className="field-label">
        <span>{l ? "Tên hiển thị" : "Display name"}</span>
        <input defaultValue="Linh Tran" />
      </label>
      <label className="field-label">
        <span>{l ? "Tên người dùng" : "Username"}</span>
        <span className="verified-field">
          <input defaultValue="linh.tran" />
          <Check />
        </span>
        <small className="available-copy">
          <Check /> {l ? "Có thể sử dụng" : "Available"}
        </small>
      </label>
      <label className="field-label">
        <span>{l ? "Ngày sinh" : "Date of birth"}</span>
        <input type="text" readOnly value={l ? "18/08/1998" : "18 Aug 1998"} />
      </label>
      <p className="helper-copy">
        {l
          ? "Ourney dùng thông tin này để giữ an toàn. Không ai thấy được."
          : "We use this to keep Ourney safe. Not shown to anyone."}
      </p>
      <button className="brand-primary" onClick={onDone}>
        {l ? "Tiếp tục" : "Continue"}
      </button>
    </div>
  )
}

function TemplateGrid({
  language,
  title,
  onPick,
  onSoon,
}: {
  language: "en" | "vi"
  title: string
  onPick: (index: number) => void
  onSoon: () => void
}) {
  const l = language === "vi"
  const templates = l ? templateCopyVi : templateCopy
  return (
    <div className="screen first-run-screen template-grid-screen">
      <header>
        <h1>{title}</h1>
      </header>
      <div className="template-grid">
        {templates.map((template, index) => (
          <button
            key={template[0]}
            onClick={() => onPick(index)}
            style={
              {
                "--template-bg": styles[index][2],
                "--template-ink": styles[index][3],
                "--template-accent": styles[index][1],
              } as React.CSSProperties
            }
          >
            <img src={journeys[index].image} alt="" />
            <strong>{template[0]}</strong>
            <small>{template[1]}</small>
            <span>{template[2]}</span>
          </button>
        ))}
        <button className="custom-template" onClick={() => onPick(5)}>
          <span>
            <Plus />
          </span>
          <strong>{l ? "Tùy chỉnh" : "Custom"}</strong>
          <small>{l ? "Tạo theo cách của bạn." : "Build it your way."}</small>
        </button>
      </div>
      <div className="template-links">
        <button onClick={onSoon}>{l ? "Tôi được mời" : "I was invited"}</button>
        <button onClick={onSoon}>
          {l ? "Nhập hành trình cũ" : "Import a past journey"}
        </button>
      </div>
    </div>
  )
}

function QuickSetup({
  language,
  templateIndex,
  onStart,
  basedOn,
  optionsExpanded = false,
  onBack,
}: {
  language: "en" | "vi"
  templateIndex: number
  onStart: () => void
  basedOn?: string
  optionsExpanded?: boolean
  onBack?: () => void
}) {
  const l = language === "vi"
  const style = styles[templateIndex]
  const Icon = journeys[templateIndex].icon
  const [showBasedOn, setShowBasedOn] = useState(Boolean(basedOn))
  const [moreOpen, setMoreOpen] = useState(optionsExpanded)
  return (
    <div
      className="screen quick-setup-screen"
      style={
        {
          "--setup-bg": style[2],
          "--setup-ink": style[3],
          "--setup-accent": style[1],
          "--setup-on-accent": onAccentColors[templateIndex],
        } as React.CSSProperties
      }
    >
      {basedOn && onBack && (
        <button className="quick-back" aria-label="Back" onClick={onBack}>
          <ArrowLeft />
        </button>
      )}
      <p className="eyebrow">{style[0]}</p>
      <span className="setup-icon">
        <Icon />
      </span>
      <h1>{l ? "Thiết lập nhanh" : "Quick setup"}</h1>
      {showBasedOn && basedOn && (
        <div className="based-on-chip">
          <span>
            {l
              ? `Theo hành trình của ${basedOn}`
              : `Based on ${basedOn}'s journey`}
          </span>
          <button
            aria-label="Remove source journey"
            onClick={() => setShowBasedOn(false)}
          >
            <X />
          </button>
        </div>
      )}
      <label className="field-label">
        <span>{l ? "Tên hành trình" : "Journey name"}</span>
        <input
          defaultValue={(l ? templateCopyVi : templateCopy)[templateIndex][0]}
        />
      </label>
      <p className="locked-style">
        <Lock />{" "}
        {l
          ? "Phong cách không đổi được sau khi tạo"
          : "Style can't be changed later"}
      </p>
      <button className="more-options" onClick={() => setMoreOpen(!moreOpen)}>
        {l ? "Tùy chọn khác" : "More options"}
        <ChevronDown />
      </button>
      {moreOpen && (
        <div className="more-options-panel">
          <span>5 days</span>
          <span>Daily</span>
          <span>No metrics</span>
        </div>
      )}
      <button className="setup-primary" onClick={onStart}>
        {l ? "Bắt đầu hành trình" : "Start journey"}
      </button>
    </div>
  )
}

function CameraPermission({
  language,
  onAllow,
  onNotNow,
}: {
  language: "en" | "vi"
  onAllow: () => void
  onNotNow: () => void
}) {
  const l = language === "vi"
  return (
    <div className="modal-layer permission-layer">
      <section className="bottom-sheet permission-sheet">
        <span className="permission-icon">
          <Camera />
        </span>
        <h2>{l ? "Cho phép dùng camera" : "Camera access"}</h2>
        <p>
          {l
            ? "Ourney cần camera để chụp ảnh hôm nay."
            : "Ourney needs your camera to take today's photo."}
        </p>
        <button className="brand-primary" onClick={onAllow}>
          {l ? "Cho phép camera" : "Allow camera"}
        </button>
        <button className="secondary-wide" onClick={onNotNow}>
          {l ? "Để sau" : "Not now"}
        </button>
      </section>
    </div>
  )
}

function NotificationSheet({
  language,
  onClose,
}: {
  language: "en" | "vi"
  onClose: () => void
}) {
  const l = language === "vi"
  return (
    <div className="modal-layer profile-layer">
      <section className="bottom-sheet permission-sheet">
        <span className="permission-icon">
          <Clock3 />
        </span>
        <h2>
          {l
            ? "Nhắc bạn lúc 21:00 ngày mai nhé?"
            : "Want a nudge tomorrow at 21:00?"}
        </h2>
        <button className="brand-primary" onClick={onClose}>
          {l ? "Bật nhắc nhở" : "Turn on"}
        </button>
        <button className="secondary-wide" onClick={onClose}>
          {l ? "Để sau" : "Not now"}
        </button>
      </section>
    </div>
  )
}

function LaunchPage({ onLaunch }: { onLaunch: (scenario: string) => void }) {
  const scenarios = [
    ["new", "New user"],
    ["five", "Returning · 5 left (21:00)"],
    ["one", "Returning · 1 left"],
    ["all", "Returning · all done"],
    ["camera", "Open app on: Camera"],
    ["journeys", "Open app on: Journeys"],
    ["teen", "Returning · age 16"],
    ["viewer", "Viewer: someone with the link"],
    ["web", "Viewer: web, not signed in"],
    ["sensitive", "Sensitive link (Glow Ritual)"],
    ["revoked", "Viewer: access removed"],
    ["consent", "Squad consent request (as Minh)"],
  ]
  return (
    <main className="launch-page">
      <div>
        <Wordmark />
        <p>App-open flow launcher</p>
      </div>
      <section>
        {scenarios.map(([id, label]) => (
          <button key={id} onClick={() => onLaunch(id)}>
            <span>
              <strong>{label}</strong>
              <small>#/launch/{id}</small>
            </span>
            <ChevronRight />
          </button>
        ))}
      </section>
      <small>
        Every scenario resets mock state and starts from the 600ms splash.
      </small>
    </main>
  )
}

export default function App() {
  const [showLogoPage, setShowLogoPage] = useState(
    window.location.hash === "#/logo",
  )
  const [showLauncher, setShowLauncher] = useState(
    window.location.hash === "#/launch",
  )
  const [dayZero, setDayZero] = useState(window.location.hash === "#/day0")
  const [screen, setScreen] = useState<Screen>("hub")
  const [previous, setPrevious] = useState<Screen>("hub")
  const [todayOpen, setTodayOpen] = useState(false)
  const [profileOpen, setProfileOpen] = useState(false)
  const [permissionOpen, setPermissionOpen] = useState(false)
  const [notificationOpen, setNotificationOpen] = useState(false)
  const [notificationShown, setNotificationShown] = useState(false)
  const [splashing, setSplashing] = useState(false)
  const [toast, setToast] = useState("")
  const [journeyId, setJourneyId] = useState(6)
  const [templateIndex, setTemplateIndex] = useState(5)
  const [firstJourneyId, setFirstJourneyId] = useState(6)
  const [hubTab, setHubTab] = useState<"active" | "shelf" | "shared">("active")
  const [unreadCount, setUnreadCount] = useState(3)
  const [friendRequests, setFriendRequests] = useState(["Khoa Le", "Mai Pham"])
  const [acceptedFriends, setAcceptedFriends] = useState<string[]>([])
  const [shareKind, setShareKind] =
    useState<"running" | "finished" | "imported" | "squad" | null>(null)
  const [shareJourneyId, setShareJourneyId] = useState(6)
  const [shareJourneyName, setShareJourneyName] = useState("Daily Reading")
  const [under18, setUnder18] = useState(false)
  const [sensitiveAlbum, setSensitiveAlbum] = useState(false)
  const [squadConsentOpen, setSquadConsentOpen] = useState(false)
  const [consentAsMinh, setConsentAsMinh] = useState(false)
  const [sharedMode, setSharedMode] =
    useState<"friend" | "stranger" | "web" | "revoked">("friend")
  const [sharedRunning, setSharedRunning] = useState(false)
  const [sharedPreview, setSharedPreview] = useState(false)
  const [sharedSaved, setSharedSaved] = useState(false)
  const [quickBasedOn, setQuickBasedOn] = useState("")
  const [quickExpanded, setQuickExpanded] = useState(false)
  const [appearance, setAppearance] = useState<Appearance>("system")
  const [language, setLanguage] = useState<"en" | "vi">("en")
  const [openMode, setOpenMode] = useState<OpenMode>(() => {
    const saved = window.localStorage.getItem("ourney-open-mode")
    return saved === "camera" || saved === "journeys" ? saved : "today"
  })
  const [doneIds, setDoneIds] = useState<number[]>(defaultDoneIds)
  const [firstJourneyOnly, setFirstJourneyOnly] = useState(false)
  const launchTimerRef = useRef<number | null>(null)
  const launchRunRef = useRef(0)
  const completedIds = Array.isArray(doneIds) ? doneIds : defaultDoneIds
  const visibleJourneys = firstJourneyOnly
    ? [journeys.find((journey) => journey.id === firstJourneyId) || journeys[5]]
    : dayZero
      ? []
      : journeys
  const dailyReadingPosted = completedIds.includes(6)
  const activeJourney = useMemo(
    () => journeys.find((j) => j.id === journeyId) || journeys[5],
    [journeyId],
  )
  const nextJourneyAfterPost = todayOrder
    .map((id) => visibleJourneys.find((journey) => journey.id === id))
    .find(
      (journey) =>
        journey &&
        journey.id !== journeyId &&
        !completedIds.includes(journey.id),
    )
  const openCamera = (id: number) => {
    setJourneyId(id)
    setTodayOpen(false)
    setScreen("camera")
  }
  const openTemplatePicker = () => {
    setTodayOpen(false)
    setScreen("templates")
  }
  const handleDockCamera = () => {
    if (visibleJourneys.length === 0) {
      openTemplatePicker()
      return
    }
    const unfinished = visibleJourneys.filter(
      (journey) => !completedIds.includes(journey.id),
    )
    if (unfinished.length === 1) {
      openCamera(unfinished[0].id)
    } else {
      setTodayOpen(true)
    }
  }
  const openDetail = (id: number) => {
    setJourneyId(id)
    setScreen(id === 6 ? "detail" : id === 2 ? "wall" : "detail")
  }
  const shellScreen = screen === "hub" || screen === "squad"
  const showSoon = () => {
    setToast(language === "vi" ? "Sắp ra mắt" : "Coming soon")
    window.setTimeout(() => setToast(""), 1800)
  }
  const rememberOpenMode = (mode: OpenMode) => {
    setOpenMode(mode)
    window.localStorage.setItem("ourney-open-mode", mode)
  }
  const launchScenario = (scenario: string) => {
    const launchRun = ++launchRunRef.current
    if (launchTimerRef.current !== null)
      window.clearTimeout(launchTimerRef.current)
    const newUser = scenario === "new"
    const nextMode: OpenMode =
      scenario === "camera"
        ? "camera"
        : scenario === "journeys"
          ? "journeys"
          : openMode
    const nextDone =
      scenario === "all"
        ? journeys.map((journey) => journey.id)
        : scenario === "one"
          ? journeys
              .filter((journey) => journey.id !== 6)
              .map((journey) => journey.id)
          : defaultDoneIds

    if (scenario === "camera" || scenario === "journeys")
      rememberOpenMode(nextMode)
    setDoneIds(newUser ? [] : nextDone)
    setFirstJourneyOnly(false)
    setFirstJourneyId(6)
    setJourneyId(6)
    setHubTab("active")
    setUnreadCount(3)
    setFriendRequests(["Khoa Le", "Mai Pham"])
    setAcceptedFriends([])
    setShareKind(null)
    setShareJourneyId(6)
    setShareJourneyName("Daily Reading")
    setUnder18(scenario === "teen")
    setSensitiveAlbum(scenario === "sensitive")
    setSquadConsentOpen(false)
    setSharedMode(
      scenario === "viewer"
        ? "stranger"
        : scenario === "web"
          ? "web"
          : scenario === "revoked"
            ? "revoked"
            : "friend",
    )
    setSharedRunning(false)
    setSharedPreview(false)
    setSharedSaved(false)
    setQuickBasedOn("")
    setQuickExpanded(false)
    setTodayOpen(false)
    setProfileOpen(false)
    setPermissionOpen(false)
    setNotificationOpen(false)
    setNotificationShown(false)
    setScreen("hub")
    setShowLauncher(false)
    setDayZero(false)
    window.history.replaceState(null, "", "#/app")
    setSplashing(true)

    launchTimerRef.current = window.setTimeout(() => {
      if (launchRunRef.current !== launchRun) return
      setSplashing(false)
      if (
        scenario === "viewer" ||
        scenario === "web" ||
        scenario === "revoked"
      ) {
        setScreen("shared")
        return
      }
      if (scenario === "sensitive") {
        setHubTab("shelf")
        setScreen("hub")
        return
      }
      if (scenario === "consent") {
        setConsentAsMinh(true)
        setScreen("hub")
        setSquadConsentOpen(true)
        return
      }
      if (newUser) {
        setScreen("onboarding")
        return
      }
      const unfinished = [6, 1, 4, 7, 10]
        .map((id) => journeys.find((journey) => journey.id === id)!)
        .filter((journey) => !nextDone.includes(journey.id))
      if (nextMode === "journeys" || unfinished.length === 0) {
        setScreen("hub")
      } else if (nextMode === "camera" || unfinished.length === 1) {
        setJourneyId(unfinished[0].id)
        setScreen("camera")
      } else {
        setScreen("hub")
        setTodayOpen(true)
      }
    }, 600)
  }
  useEffect(() => {
    const syncHash = () => {
      const hash = window.location.hash
      const directScenario = hash.match(/^#\/launch\/([^/]+)$/)?.[1]
      setShowLogoPage(hash === "#/logo")
      setShowLauncher(hash === "#/launch")
      setDayZero(hash === "#/day0")
      if (directScenario) launchScenario(directScenario)
    }
    syncHash()
    window.addEventListener("hashchange", syncHash)
    return () => {
      window.removeEventListener("hashchange", syncHash)
    }
  }, [])
  if (showLogoPage) return <LogoConcepts />
  if (showLauncher) return <LaunchPage onLaunch={launchScenario} />
  return (
    <main className={`stage appearance-${appearance}`}>
      <div className="phone" data-screen={screen}>
        {splashing && <Splash />}
        {screen === "hub" &&
          (dayZero ? (
            <DayZeroHub
              language={language}
              onProfile={() => setProfileOpen(true)}
              onStart={openTemplatePicker}
            />
          ) : (
            <Hub
              onOpen={openDetail}
              onCamera={openCamera}
              onProfile={() => setProfileOpen(true)}
              onInbox={() => setScreen("inbox")}
              onNewJourney={openTemplatePicker}
              onRetell={() => showSoon()}
              onSharedJourney={(running = false) => {
                setSharedMode("friend")
                setSharedRunning(running)
                setSharedPreview(false)
                setScreen("shared")
              }}
              onImported={() => setScreen("imported")}
              onShareAlbum={(album) => {
                if (album === "summer") {
                  setShareJourneyId(2)
                  setShareJourneyName("Summer Vietnamese Course")
                  setShareKind("squad")
                } else if (album === "phuQuoc") {
                  setShareJourneyId(12)
                  setShareJourneyName("Phu Quoc Trip")
                  setShareKind("finished")
                } else if (album === "skin") {
                  setShareJourneyId(7)
                  setShareJourneyName("Summer Skin Reset")
                  setShareKind("finished")
                } else {
                  setShareJourneyId(0)
                  setShareJourneyName("Hoi An 2024")
                  setShareKind("imported")
                }
              }}
              onEditImported={() => setScreen("storyEditor")}
              sensitiveAlbum={sensitiveAlbum}
              language={language}
              hubTab={hubTab}
              setHubTab={setHubTab}
              onSquad={() => setScreen("wall")}
              unreadCount={unreadCount}
              sharedSaved={sharedSaved}
              doneIds={completedIds}
              visibleJourneys={visibleJourneys}
              firstJourney={firstJourneyOnly}
            />
          ))}
        {screen === "squad" && (
          <SquadTab
            onWall={() => setScreen("wall")}
            onShare={() => {
              setShareJourneyId(3)
              setShareJourneyName("Da Lat Trip")
              setShareKind("squad")
            }}
          />
        )}
        {screen === "camera" && (
          <CameraScreen
            journeyId={journeyId}
            setJourneyId={setJourneyId}
            onShutter={() => setScreen("compose")}
            onBack={() => setScreen("hub")}
            onNavigate={setScreen}
            language={language}
            doneIds={completedIds}
            visibleJourneys={visibleJourneys}
            firstJourney={firstJourneyOnly}
          />
        )}
        {screen === "compose" && (
          <Compose
            journeyId={journeyId}
            onBack={() => setScreen("camera")}
            onPost={() => {
              setDoneIds((current) =>
                current.includes(journeyId) ? current : [...current, journeyId],
              )
              setScreen("posted")
            }}
          />
        )}
        {screen === "posted" && (
          <Posted
            image={activeJourney.image}
            firstJourney={firstJourneyOnly}
            nextJourney={nextJourneyAfterPost}
            language={language}
            onNext={() => {
              if (nextJourneyAfterPost) openCamera(nextJourneyAfterPost.id)
            }}
            onDone={() => {
              setScreen("hub")
              if (firstJourneyOnly && !notificationShown) {
                setNotificationShown(true)
                setNotificationOpen(true)
              }
            }}
          />
        )}
        {screen === "detail" && (
          <Detail
            onBack={() => setScreen("hub")}
            onCheckIn={() => openCamera(6)}
            onShare={() => {
              setShareJourneyId(journeyId)
              setShareJourneyName(activeJourney.name)
              setShareKind(
                completedIds.includes(journeyId) ? "finished" : "running",
              )
            }}
            language={language}
            dailyReadingPosted={dailyReadingPosted}
          />
        )}
        {screen === "wall" && <SquadWall onBack={() => setScreen("squad")} />}
        {screen === "tokens" && <Tokens onBack={() => setScreen(previous)} />}
        {screen === "friends" && (
          <FriendsScreen
            language={language}
            onBack={() => setScreen("hub")}
            onAdd={() => setScreen("addFriends")}
            requests={friendRequests}
            acceptedFriends={acceptedFriends}
            onRequestHandled={(name, accept) => {
              setFriendRequests((current) =>
                current.filter((request) => request !== name),
              )
              if (accept)
                setAcceptedFriends((current) =>
                  current.includes(name) ? current : [...current, name],
                )
              if (name === "Khoa Le")
                setUnreadCount((count) => Math.max(0, count - 1))
            }}
          />
        )}
        {screen === "addFriends" && (
          <AddFriendsScreen
            language={language}
            onBack={() => setScreen("friends")}
            onToast={(message) => {
              setToast(message)
              window.setTimeout(() => setToast(""), 1800)
            }}
          />
        )}
        {screen === "imported" && (
          <ImportedDetail
            language={language}
            onBack={() => {
              setHubTab("shelf")
              setScreen("hub")
            }}
            onShare={() => {
              setShareJourneyId(0)
              setShareJourneyName("Hoi An 2024")
              setShareKind("imported")
            }}
            onInsights={() => setScreen("insights")}
          />
        )}
        {screen === "shared" && (
          <SharedJourney
            language={language}
            mode={sharedMode}
            running={sharedRunning}
            preview={sharedPreview}
            onBack={() => {
              setHubTab("shared")
              setScreen("hub")
            }}
            onChat={() => setScreen("chat")}
            onDo={() =>
              setScreen(sharedMode === "web" ? "getOurney" : "doJourney")
            }
            onOpenApp={() => setScreen("getOurney")}
            onSaved={() => {
              setSharedSaved(true)
              setToast(language === "vi" ? "Đã lưu" : "Saved")
              window.setTimeout(() => setToast(""), 1800)
            }}
          />
        )}
        {screen === "inbox" && (
          <InboxScreen
            language={language}
            onBack={() => setScreen("hub")}
            onChat={() => setScreen("chat")}
            onShared={() => {
              setSharedMode("friend")
              setSharedRunning(false)
              setScreen("shared")
            }}
            onConsent={() => {
              setConsentAsMinh(false)
              setSquadConsentOpen(true)
            }}
            onRead={() => setUnreadCount((count) => Math.max(0, count - 1))}
            khoaPending={friendRequests.includes("Khoa Le")}
            onKhoaHandled={(accept) => {
              setFriendRequests((current) =>
                current.filter((request) => request !== "Khoa Le"),
              )
              if (accept)
                setAcceptedFriends((current) =>
                  current.includes("Khoa Le")
                    ? current
                    : [...current, "Khoa Le"],
                )
              setUnreadCount((count) => Math.max(0, count - 1))
            }}
          />
        )}
        {screen === "chat" && (
          <ChatScreen
            language={language}
            onBack={() => setScreen("inbox")}
            onJourney={() => setScreen("detail")}
          />
        )}
        {screen === "doJourney" && (
          <DoJourneyScreen
            language={language}
            onBack={() => setScreen("shared")}
            onStart={(expanded) => {
              setTemplateIndex(2)
              setQuickBasedOn("Hà")
              setQuickExpanded(expanded)
              setScreen("quickSetup")
            }}
          />
        )}
        {screen === "getOurney" && (
          <GetOurneyScreen
            language={language}
            onBack={() => setScreen("shared")}
          />
        )}
        {screen === "insights" && (
          <InsightsScreen
            language={language}
            onBack={() => setScreen("imported")}
          />
        )}
        {screen === "storyEditor" && (
          <StoryEditor
            language={language}
            onBack={() => {
              setHubTab("shelf")
              setScreen("hub")
            }}
            onPreview={() => {
              setSharedMode("friend")
              setSharedRunning(false)
              setSharedPreview(true)
              setScreen("shared")
            }}
          />
        )}
        {screen === "onboarding" && (
          <Onboarding
            language={language}
            setLanguage={setLanguage}
            onDone={() => setScreen("signin")}
          />
        )}
        {screen === "signin" && (
          <SignIn
            language={language}
            onDone={() => setScreen("profileSetup")}
          />
        )}
        {screen === "profileSetup" && (
          <ProfileSetup
            language={language}
            onDone={() => setScreen("templates")}
          />
        )}
        {screen === "templates" && (
          <TemplateGrid
            language={language}
            title={
              firstJourneyOnly || dayZero
                ? language === "vi"
                  ? "Bạn đang thực hiện điều gì?"
                  : "What are you working on?"
                : language === "vi"
                  ? "Hành trình đầu tiên của bạn là gì?"
                  : "What's your first journey?"
            }
            onPick={(index) => {
              setTemplateIndex(index)
              setFirstJourneyId(journeys[index].id)
              setQuickBasedOn("")
              setQuickExpanded(false)
              setScreen("quickSetup")
            }}
            onSoon={showSoon}
          />
        )}
        {screen === "quickSetup" && (
          <QuickSetup
            language={language}
            templateIndex={templateIndex}
            onStart={() => setPermissionOpen(true)}
            basedOn={quickBasedOn || undefined}
            optionsExpanded={quickExpanded}
            onBack={quickBasedOn ? () => setScreen("doJourney") : undefined}
          />
        )}
        {shellScreen && (
          <Dock
            active={screen}
            onNavigate={setScreen}
            onToday={handleDockCamera}
            language={language}
          />
        )}
        {todayOpen && (
          <TodaySheet
            onClose={() => setTodayOpen(false)}
            onCamera={openCamera}
            language={language}
            doneIds={completedIds}
            visibleJourneys={visibleJourneys}
          />
        )}
        {profileOpen && (
          <ProfileSheet
            appearance={appearance}
            setAppearance={setAppearance}
            language={language}
            setLanguage={setLanguage}
            openMode={openMode}
            setOpenMode={rememberOpenMode}
            onClose={() => setProfileOpen(false)}
            onTokens={() => {
              setPrevious(screen)
              setProfileOpen(false)
              setScreen("tokens")
            }}
            onLogo={() => {
              setProfileOpen(false)
              window.location.hash = "/logo"
            }}
            onRestart={() => {
              setProfileOpen(false)
              window.location.hash = "/launch"
            }}
            onFriends={() => {
              setProfileOpen(false)
              setScreen("friends")
            }}
            onInsights={() => {
              setProfileOpen(false)
              setScreen("insights")
            }}
            friendCount={12 + acceptedFriends.length}
          />
        )}
        {shareKind && (
          <ShareJourneySheet
            language={language}
            kind={shareKind}
            journeyId={shareJourneyId}
            journeyName={shareJourneyName}
            under18={under18}
            onClose={() => setShareKind(null)}
            onEdit={() => {
              setShareKind(null)
              setScreen("storyEditor")
            }}
            onInsights={() => {
              setShareKind(null)
              setScreen("insights")
            }}
          />
        )}
        {squadConsentOpen && (
          <SquadConsentSheet
            language={language}
            agreed={!consentAsMinh}
            onClose={() => setSquadConsentOpen(false)}
          />
        )}
        {permissionOpen && (
          <CameraPermission
            language={language}
            onAllow={() => {
              setPermissionOpen(false)
              setFirstJourneyOnly(true)
              setDoneIds([])
              openCamera(firstJourneyId)
            }}
            onNotNow={() => {
              setPermissionOpen(false)
              setFirstJourneyOnly(true)
              setDoneIds([])
              setScreen("hub")
            }}
          />
        )}
        {notificationOpen && (
          <NotificationSheet
            language={language}
            onClose={() => setNotificationOpen(false)}
          />
        )}
        {toast && (
          <div className="toast" role="status">
            {toast}
          </div>
        )}
      </div>
    </main>
  )
}
