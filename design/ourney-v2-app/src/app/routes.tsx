import {
  createBrowserRouter,
  Link,
  Navigate,
  Outlet,
  useLocation,
  useNavigate,
  useParams,
} from "react-router"
import {
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
  type CSSProperties,
  type PointerEvent as ReactPointerEvent,
  type ReactNode,
} from "react"
import { OIcon, TypeBadge, type OIconName } from "./icons"
import { PhoneOverlay } from "./overlay"
import { Wordmark } from "./brand"
import StyleGuide, { skins, type Skin } from "../StyleGuide"
import {
  LoginFlow,
  OnboardingFlow,
  OtpFlow,
  PermissionSheet,
  ProfileSetupFlow,
  SplashFlow,
} from "./flow"
import {
  CreateStepFive,
  CreateStepFour,
  CreateStepOne,
  CreateStepTwo,
  CreateStepThree,
  CreateStepThreeExtra,
} from "./create"
import { useStore, type Journey } from "./store"

const typePastel: Record<Journey["type"], string> = {
  "Giảm cân": "#7EE8A2",
  "Tiếng Anh": "#FFD84D",
  "Chuyến đi": "#FFB347",
  "Cặp đôi": "#FF7E7E",
  "Tập luyện": "#CF9FFF",
  "Tự đặt": "#7EC8E3",
}

const reactionOptions = [
  { id: "clap", icon: "react-clap", label: "Vỗ tay" },
  { id: "flex", icon: "react-flex", label: "Cố lên" },
  { id: "heart", icon: "react-heart", label: "Thương" },
  { id: "laugh", icon: "react-laugh", label: "Haha" },
  { id: "fire", icon: "react-fire", label: "Cháy" },
  { id: "wave", icon: "react-wave", label: "Vẫy tay" },
] as const satisfies ReadonlyArray<{
  id: string
  icon: OIconName
  label: string
}>

function ReactionIcon({
  id,
  size = 20,
}: {
  id: typeof reactionOptions[number]["id"]
  size?: number
}) {
  const reaction = reactionOptions.find((item) => item.id === id)
  return reaction ? (
    <OIcon
      name={reaction.icon}
      size={size}
      active
      className={`reaction-${id}`}
    />
  ) : null
}

type StreakValueProps = {
  count: number
  suffix?: string
}

function StreakValue({ count, suffix }: StreakValueProps) {
  return (
    <span className="icon-text">
      <OIcon name="flame" size={17} active /> {count}
      {suffix ? ` ${suffix}` : ""}
    </span>
  )
}

function dateDayOffset(startDate?: string, date?: string) {
  if (!startDate || !date) return 1
  const start = new Date(`${startDate}T12:00:00`)
  const current = new Date(`${date}T12:00:00`)
  return Math.max(
    1,
    Math.round((current.getTime() - start.getTime()) / 86_400_000) + 1,
  )
}

function formatJourneyDate(date?: string) {
  if (!date) return "Chưa có ngày"
  const parsed = new Date(`${date}T12:00:00`)
  return `${parsed.getDate()} THG ${parsed.getMonth() + 1}, ${parsed.getFullYear()}`
}

function journeyLength(journey: Journey) {
  if (journey.totalDays) return journey.totalDays
  if (journey.startDate && journey.endDate) {
    return dateDayOffset(journey.startDate, journey.endDate)
  }
  if (journey.id === "dalat") return 5
  const namedDuration = journey.name.match(/(\d+)\s*ngày/i)
  return namedDuration ? Number(namedDuration[1]) : 30
}

function journeyCheckIns(journey: Journey) {
  if (journey.days?.length) return journey.days.length
  if (journey.importedPhotos) {
    return (
      new Set(journey.importedPhotos.map((photo) => photo.date).filter(Boolean))
        .size + (journey.todayDone ? 1 : 0)
    )
  }
  return Math.min(journey.day, journeyLength(journey))
}

function journeyDayEntry(journey: Journey, day: number) {
  return journey.days?.find((entry) => entry.day === day)
}

function journeyLatestPhotoDay(journey: Journey) {
  return journey.days?.reduce((latest, entry) => Math.max(latest, entry.day), 0)
}

function journeyTodayEntry(journey: Journey) {
  const day = journey.todayDone ? journeyLatestPhotoDay(journey) : journey.day
  return day ? journeyDayEntry(journey, day) : undefined
}

function journeyDisplayDay(journey: Journey) {
  return journey.todayDone
    ? (journeyLatestPhotoDay(journey) ?? Math.max(1, journey.day - 1))
    : journey.day
}

function journeyPhotoCount(journey: Journey) {
  return (journey.days ?? []).reduce(
    (total, entry) => total + entry.photos.length,
    0,
  )
}

function DeletedDayPlaceholder() {
  return (
    <span className="deleted-day-placeholder">
      <i className="deleted-day-check">
        <OIcon name="check" size={20} weight="bold" />
      </i>
      <b>đã điểm danh</b>
      <small>ảnh đã xoá</small>
    </span>
  )
}

function DayPhotoStack({
  journey,
  day,
  children,
}: {
  journey: Journey
  day: number
  children: ReactNode
}) {
  const entry = journeyDayEntry(journey, day)
  const count = entry?.photos.length ?? 0
  if (entry && count === 0) return <DeletedDayPlaceholder />
  if (count < 2) return children
  return (
    <span className="day-photo-stack">
      <i />
      {count > 2 && <i />}
      {children}
      <b aria-label={`${count} ảnh`}>+{count - 1}</b>
    </span>
  )
}

const nativeSkinByType: Record<Journey["type"], string> = {
  "Giảm cân": "quiet",
  "Tiếng Anh": "squad",
  "Chuyến đi": "memory",
  "Cặp đôi": "couple",
  "Tập luyện": "flexer",
  "Tự đặt": "minimal",
}

function hasSwitchedLayout(journey: Journey) {
  return journey.skin !== nativeSkinByType[journey.type]
}

function journeyAttendanceVerb(journey: Journey) {
  if (journey.type === "Tập luyện") {
    return journey.totalKm !== undefined ? "ĐÃ CHẠY" : "ĐÃ TẬP"
  }
  if (journey.type === "Tiếng Anh") return "ĐÃ HỌC"
  return "ĐÃ ĐIỂM DANH"
}

function journeyMetric(journey: Journey) {
  if (journey.skin === "flexer") {
    if (journey.totalKm !== undefined) {
      return `${new Intl.NumberFormat("vi-VN", {
        minimumFractionDigits: 1,
        maximumFractionDigits: 2,
      }).format(journey.totalKm)} KM`
    }
    if (journey.lastMinutes !== undefined) {
      return `${journey.lastMinutes} PHÚT`
    }
    return "ĐÃ CHỤP"
  }
  if (journey.skin === "quiet") {
    return journey.lastWeight !== undefined
      ? `${journey.lastWeight.toFixed(1).replace(".", ",")} KG`
      : "ĐÃ CHỤP"
  }
  if (journey.skin === "memory") {
    if (journey.frameCount !== undefined) {
      return `${journey.frameCount} KHUNG`
    }
    if (journey.lastPlace) return journey.lastPlace.toLocaleUpperCase("vi")
    return "ĐÃ CHỤP"
  }
  if (journey.skin === "couple") {
    return journey.members?.length ? journey.members.join(" | ") : "ĐÃ CHỤP"
  }
  if (journey.totalKm !== undefined) {
    return `${new Intl.NumberFormat("vi-VN", {
      minimumFractionDigits: 1,
      maximumFractionDigits: 2,
    }).format(journey.totalKm)} KM`
  }
  if (journey.lastMinutes !== undefined) {
    return `${journey.lastMinutes} PHÚT`
  }
  return "ĐÃ CHỤP"
}

function journeyDisplayTitle(journey: Journey) {
  return `${journey.name} · NGÀY ${journey.day}/${journeyLength(journey)}`
}

function journeyTimelineRows(journey: Journey) {
  const total = journeyLength(journey)
  const currentDay = journeyDisplayDay(journey)
  const action =
    journey.type === "Tiếng Anh"
      ? "HỌC"
      : journey.type === "Tập luyện"
        ? "TẬP"
        : journey.type === "Giảm cân"
          ? "TIẾN TRÌNH"
          : journey.type === "Cặp đôi"
            ? "CÙNG NHAU"
            : journey.type === "Chuyến đi"
              ? "KỶ NIỆM"
              : "CHECK-IN"
  return [
    { day: currentDay, label: `${action} · HÔM NAY` },
    { day: Math.max(1, Math.ceil(total / 2)), label: `${action} · NỬA CHẶNG` },
    ...(total >= 7 ? [{ day: 7, label: `${action} · TUẦN ĐẦU` }] : []),
    { day: 1, label: `${action} · BẮT ĐẦU` },
  ].filter(
    (row, index, rows) =>
      rows.findIndex((candidate) => candidate.day === row.day) === index,
  )
}

function availableLayoutsForJourney(journey: Journey) {
  const groupJourney = (journey.members?.length ?? 0) >= 2
  return ["quiet", "squad", "memory", "couple", "flexer", "minimal"].filter(
    (skin) => {
      if (skin === "quiet") return journey.lastWeight !== undefined
      if (skin === "couple") return journey.members?.length === 2
      if (skin === "squad") return groupJourney
      if (skin === "flexer") {
        return (
          journey.type === "Tập luyện" ||
          journey.totalKm !== undefined ||
          journey.lastMinutes !== undefined
        )
      }
      return true
    },
  )
}

function Root() {
  const store = useStore()
  const location = useLocation()
  const navigate = useNavigate()
  const [contentScrolled, setContentScrolled] = useState(false)
  const activeJourney = store.journeys.find(
    (journey) => journey.id === store.activeJourneyId,
  )
  const skin = skins.find((item) => item.id === activeJourney?.skin) ?? skins[0]
  const dockMode = location.pathname.endsWith("/camera") ? "dark" : store.theme
  const palette = skin[dockMode]
  const shell =
    store.theme === "light"
      ? { bg: "#FFF8EE", surface: "#FFFFFF", ink: "#1A1A1A", muted: "#5A544C" }
      : { bg: "#121212", surface: "#1C1B19", ink: "#F5F0E6", muted: "#B8B0A4" }
  const baseVariant =
    skin.variants[activeJourney?.variant ?? 0] ?? skin.variants[0]
  const variant =
    skin.id === "minimal" && activeJourney?.variant === 1 && dockMode === "dark"
      ? { ...baseVariant, button: "#F4F4F5", buttonLabel: "#0E0E10" }
      : baseVariant
  const variables = {
    "--bg": shell.bg,
    "--surface": shell.surface,
    "--ink": shell.ink,
    "--muted": shell.muted,
    "--accent": "#FF8A3D",
    "--button": "#FF8A3D",
    "--button-label": "#1A1A1A",
    "--secondary": shell.surface,
    "--heading-font": "'Space Grotesk', 'Be Vietnam Pro', sans-serif",
    "--skin-bg": palette.bg,
    "--skin-surface": palette.surface,
    "--skin-ink": palette.ink,
    "--skin-muted": palette.muted,
    "--skin-accent": variant.accent,
    "--skin-button": variant.button,
    "--skin-button-label": variant.buttonLabel,
    "--skin-secondary": variant.secondary,
  } as CSSProperties

  useEffect(() => {
    store.setJourneyWheelOpen(false)
  }, [location.pathname])

  return (
    <div
      className={`app-root skin-${skin.id} app-${store.theme} ${
        store.largeType ? "app-large-type" : ""
      } ${store.reduceMotion ? "app-reduce-motion" : ""} ${
        store.reduceTransparency ? "app-reduce-transparency" : ""
      } ${contentScrolled ? "app-content-scrolled" : ""}`}
      style={variables}
    >
      <ReviewerPanel skin={skin} activeJourney={activeJourney} />
      <div className="phone-frame" aria-label="Ourney">
        <div className="phone-speaker" aria-hidden="true" />
        <div
          className="phone-screen"
          key={location.key}
          onScrollCapture={(event) =>
            setContentScrolled(
              event.currentTarget !== event.target &&
                (event.target as HTMLElement).scrollTop > 8,
            )
          }
        >
          <Outlet context={{ skin, activeJourney }} />
          {store.reminderBanner && <ReminderNotification />}
          {store.appToast && (
            <div className="system-toast">{store.appToast}</div>
          )}
          {store.missedDay &&
            activeJourney &&
            (activeJourney.skin === "quiet" ||
              activeJourney.skin === "squad") &&
            /^\/j\/[^/]+$/.test(location.pathname) && (
              <MissedDayOverlay journey={activeJourney} />
            )}
          {activeJourney?.todayDone &&
            /^\/j\/[^/]+$/.test(location.pathname) && (
              <button
                className={`today-retake-hero retake-${activeJourney.skin}`}
                onClick={() => navigate(`/j/${activeJourney.id}/camera`)}
              >
                <OIcon name="camera" size={19} weight="bold" /> Chụp thêm ảnh
                hôm nay
              </button>
            )}
          {store.createSheetOpen && (
            <CreateSheet onClose={() => store.setCreateSheetOpen(false)} />
          )}
          {store.inviteSheetOpen && <InviteSheet />}
          <CameraJourneyPicker />
        </div>
      </div>
    </div>
  )
}

type ReminderCopy = {
  daily: string
  streak: string
}

const reminderCopy: Record<string, ReminderCopy> = {
  quiet: {
    daily: "Đến giờ của bạn rồi. Một tấm là đủ.",
    streak: "Chuỗi 21 ngày còn đến 21:00. Vẫn kịp.",
  },
  squad: {
    daily: "Tới giờ điểm danh! Cả hội đang chờ.",
    streak: "Chuỗi 21 sắp đứt lúc 21:00. Chụp ngay nào!",
  },
  memory: {
    daily: "Thêm một khung hình cho cuộn phim?",
    streak: "Cuộn phim còn mở đến 21:00.",
  },
  couple: {
    daily: "Hai đứa ơi, đến giờ rồi.",
    streak: "Chuỗi 18 ngày sắp đứt lúc 21:00.",
  },
  flexer: {
    daily: "ĐẾN GIỜ. CHẠY ĐI.",
    streak: "CHUỖI 21. CÒN ĐẾN 21:00.",
  },
  minimal: {
    daily: "NGÀY 24.",
    streak: "CHUỖI 24. 21:00.",
  },
}

function ReminderNotification() {
  const store = useStore()
  const navigate = useNavigate()
  const startY = useRef(0)
  const banner = store.reminderBanner
  const journey = store.journeys.find((item) => item.id === banner?.journeyId)
  if (!banner || !journey) return null
  const dismiss = () => store.setReminderBanner(null)
  return (
    <div
      className={`reminder-banner reminder-${journey.skin}`}
      onPointerDown={(event) => {
        startY.current = event.clientY
      }}
      onPointerUp={(event) => {
        if (event.clientY < startY.current - 30) dismiss()
      }}
    >
      <button
        className="reminder-open"
        onClick={() => {
          dismiss()
          store.selectJourney(journey.id)
          navigate(`/j/${journey.id}/camera`)
        }}
      >
        <span className="reminder-app-icon">
          <OIcon name="activity" size={19} weight="bold" />
        </span>
        <span className="reminder-copy">
          <small>
            Ourney <i>bây giờ</i>
          </small>
          <b>{journey.type === "Giảm cân" ? "Ourney" : journey.name}</b>
          <span>{reminderCopy[journey.skin][banner.kind]}</span>
        </span>
      </button>
      <button className="reminder-dismiss" onClick={dismiss} aria-label="Đóng">
        <OIcon name="close" size={18} weight="bold" />
      </button>
    </div>
  )
}

function MissedDayOverlay({ journey }: { journey: Journey }) {
  const [open, setOpen] = useState(false)
  const squad = journey.skin === "squad"
  return (
    <div className={`missed-day-overlay missed-${journey.skin}`}>
      <button onClick={() => setOpen(true)}>
        <span>{squad ? "NGÀY 9 · LỠ" : "NGÀY 9 · NGHỈ"}</span>
      </button>
      <div className="system-sheet-host">
        <JourneyActionSheet
          open={open}
          title={squad ? "ngày lỡ." : "ngày nghỉ."}
          body={
            squad
              ? "Lỡ một hôm thôi. Mai về lại đường nào!"
              : "Một ngày nghỉ không xóa hành trình."
          }
          onClose={() => setOpen(false)}
        >
          <button className="sheet-primary" onClick={() => setOpen(false)}>
            Đã hiểu
          </button>
        </JourneyActionSheet>
      </div>
    </div>
  )
}

function ReviewerPanel({
  skin,
  activeJourney,
}: {
  skin: Skin
  activeJourney?: Journey
}) {
  const store = useStore()
  const navigate = useNavigate()
  const location = useLocation()
  const [open, setOpen] = useState(true)
  const [layoutCheckResults, setLayoutCheckResults] = useState<string[] | null>(
    null,
  )
  const [emojiCheckResults, setEmojiCheckResults] = useState<string[] | null>(
    null,
  )
  const [iconCheckResults, setIconCheckResults] = useState<string[] | null>(
    null,
  )
  const iconAuditActive = useRef(false)
  const routes = [
    ["/splash", "mở đầu"],
    ["/onboarding/1", "câu 1"],
    ["/onboarding/2", "câu 2"],
    ["/onboarding/3", "câu 3"],
    ["/login", "đăng nhập"],
    ["/otp", "nhập mã"],
    ["/profile-setup", "tạo hồ sơ"],
    ["/camera", "máy ảnh"],
    ["/hub", "hành trình"],
    ["/squad", "hội"],
    ["/activity", "hoạt động"],
    ["/me", "hồ sơ"],
  ]

  function changeUser(user: "new" | "old") {
    store.setUser(user)
    window.setTimeout(() => navigate("/splash"), 0)
  }

  function checkLayouts() {
    const seedTerms: Record<string, string[]> = {
      quiet: ["30 NGÀY CƠ THỂ", "65,2 KG", "62,0 KG"],
      ielts: ["HỘI IELTS 7.5", "CÚP 7.5"],
      dalat: ["ĐÀ LẠT", "ĐỒI CHÈ", "CUỘN PHIM 12/24"],
      couple: ["30 NGÀY NẤU CHO NHAU", "NAM | LINH"],
      running: ["CHẠY SÁNG", "92,4 KM", "5,42 KM", "5:04"],
      minimal: ["ĐỌC 10 TRANG", "24/30"],
    }
    const failures: string[] = []
    for (const journey of store.journeys) {
      for (const layout of availableLayoutsForJourney(journey)) {
        const auditText = [
          journeyDisplayTitle(journey),
          journeyMetric({ ...journey, skin: layout }),
          ...journeyTimelineRows(journey).map(
            (row) => `${row.day} ${row.label}`,
          ),
          ...(journey.members ?? []),
          journey.lastCaption ?? "",
          journey.lastPlace ?? "",
        ]
          .join(" ")
          .toLocaleUpperCase("vi")
        for (const [seedId, terms] of Object.entries(seedTerms)) {
          if (seedId === journey.id) continue
          const leaked = terms.find((term) => auditText.includes(term))
          if (leaked) {
            failures.push(`${journey.id} × ${layout}: “${leaked}”`)
          }
        }
      }
    }
    const screenText =
      document
        .querySelector(".phone-screen")
        ?.textContent?.toLocaleUpperCase("vi") ?? ""
    if (activeJourney) {
      for (const [seedId, terms] of Object.entries(seedTerms)) {
        if (seedId === activeJourney.id) continue
        const leaked = terms.find((term) => screenText.includes(term))
        if (leaked) failures.push(`màn hiện tại: “${leaked}”`)
      }
    }
    setLayoutCheckResults([...new Set(failures)])
  }

  function checkEmoji() {
    const screenText =
      document.querySelector(".phone-screen")?.textContent ?? ""
    const forbidden =
      /\p{Extended_Pictographic}|[\u25CF\u25CC\u2605\u2606\u2665\u2659\u2601\u2713\u25B2]/gu
    setEmojiCheckResults([...new Set(screenText.match(forbidden) ?? [])])
  }

  function checkIconAlignment() {
    iconAuditActive.current = true
    const screen = document.querySelector(".phone-screen")
    if (!screen) {
      setIconCheckResults(["Không tìm thấy màn điện thoại."])
      return
    }
    const failures: string[] = []
    const badgeSelector = [
      ".choice-check",
      ".corner-check-badge",
      ".ourney-type-badge",
      ".squad-reactions button",
      ".memory-reactions button",
      ".day-reactions button",
      ".camera-top-actions button",
      ".camera-safe-top > button",
      ".camera-state-sticker",
      ".settings-reminder > span",
      ".activity-skin-badge",
      ".squad-avatar-stack i.checked > svg",
      ".activity-dock-icon",
      ".deleted-day-check",
    ].join(",")
    screen
      .querySelectorAll<HTMLElement | SVGElement>(badgeSelector)
      .forEach((badge) => {
        const svg =
          badge instanceof SVGElement
            ? badge
            : badge.querySelector<SVGElement>("svg")
        if (!svg) return
        const badgeRect = badge.getBoundingClientRect()
        if (badgeRect.width > 48 || badgeRect.height > 48) return
        const iconRect = svg.getBoundingClientRect()
        const deltaX = Math.abs(
          iconRect.left +
            iconRect.width / 2 -
            (badgeRect.left + badgeRect.width / 2),
        )
        const deltaY = Math.abs(
          iconRect.top +
            iconRect.height / 2 -
            (badgeRect.top + badgeRect.height / 2),
        )
        if (deltaX > 1 || deltaY > 1) {
          failures.push(
            `${badge.className || badge.tagName}: lệch ${deltaX.toFixed(1)}px ngang, ${deltaY.toFixed(1)}px dọc`,
          )
        }
      })
    screen
      .querySelectorAll<HTMLElement>("[data-corner-badge]")
      .forEach((badge) => {
        const card = badge.closest<HTMLElement>(
          ".answer-choice, .app-icon-picker button, .avatar-picker button, .ticket-choices button, .edit-layout-grid > button, .import-layout-grid > button, .create-deck-card",
        )
        if (!card) return
        const badgeRect = badge.getBoundingClientRect()
        const cardRect = card.getBoundingClientRect()
        const topGap = badgeRect.top - cardRect.top
        const rightGap = cardRect.right - badgeRect.right
        if (topGap < 6 || rightGap < 6) {
          failures.push(
            `badge góc: cách trên ${topGap.toFixed(1)}px, phải ${rightGap.toFixed(1)}px`,
          )
        }
        const intersects = (rect: DOMRect) =>
          badgeRect.left < rect.right &&
          badgeRect.right > rect.left &&
          badgeRect.top < rect.bottom &&
          badgeRect.bottom > rect.top
        const walker = document.createTreeWalker(card, NodeFilter.SHOW_TEXT)
        let textNode = walker.nextNode()
        while (textNode) {
          const parent = textNode.parentElement
          if (
            parent &&
            !badge.contains(parent) &&
            textNode.textContent?.trim()
          ) {
            const range = document.createRange()
            range.selectNodeContents(textNode)
            if (intersects(range.getBoundingClientRect())) {
              failures.push("badge góc: chạm nội dung chữ trong cùng control")
              break
            }
          }
          textNode = walker.nextNode()
        }
        card
          .querySelectorAll<HTMLElement>(
            "svg, .ourney-mark, [role='img'], .create-preview, .layout-preview-card, .library-scene, .avatar-picker button > span, .ticket-choices button > i:not(.corner-check-badge)",
          )
          .forEach((preview) => {
            if (
              preview !== badge &&
              !badge.contains(preview) &&
              intersects(preview.getBoundingClientRect())
            ) {
              failures.push(
                "badge góc: chạm icon hoặc preview trong cùng control",
              )
            }
          })
      })
    setIconCheckResults(failures)
  }

  useEffect(() => {
    if (!iconAuditActive.current) return
    const frame = window.requestAnimationFrame(checkIconAlignment)
    return () => window.cancelAnimationFrame(frame)
  }, [location.pathname, store.theme, store.largeType])

  return (
    <aside className={`reviewer ${open ? "reviewer-open" : ""}`}>
      <button
        className="reviewer-toggle"
        onClick={() => setOpen(!open)}
        aria-expanded={open}
      >
        {open ? "thu bảng" : "mở bảng"}
      </button>
      {open && (
        <div className="reviewer-body">
          <div className="reviewer-title">
            <b>bảng kiểm thử</b>
            <span>không thuộc giao diện ứng dụng</span>
          </div>
          <Control label="người dùng">
            <Segment
              value={store.user}
              options={[
                ["new", "Người mới"],
                ["old", "Người cũ"],
              ]}
              onChange={(value) => changeUser(value as "new" | "old")}
            />
          </Control>
          <button
            className="reviewer-layout-check"
            onClick={() => changeUser("new")}
          >
            Người dùng mới: chạy lại từ đầu
          </button>
          <Control label="chế độ">
            <Segment
              value={store.theme}
              options={[
                ["light", "Sáng"],
                ["dark", "Tối"],
              ]}
              onChange={(value) => store.setTheme(value as "light" | "dark")}
            />
          </Control>
          <Control label="giao diện">
            <select
              value={skin.id}
              disabled={!activeJourney}
              onChange={(event) => store.setActiveSkin(event.target.value)}
            >
              {skins.map((item) => (
                <option value={item.id} key={item.id}>
                  {item.journey}
                </option>
              ))}
            </select>
          </Control>
          <Control label="biến thể">
            <select
              value={activeJourney?.variant ?? 0}
              disabled={!activeJourney}
              onChange={(event) =>
                store.setActiveVariant(Number(event.target.value))
              }
            >
              {skin.variants.map((item, index) => (
                <option value={index} key={item.name}>
                  {item.name}
                </option>
              ))}
            </select>
          </Control>
          <Control label="kiểm tra dữ liệu layout">
            <button className="reviewer-layout-check" onClick={checkLayouts}>
              Kiểm tra giao diện
            </button>
            {layoutCheckResults && (
              <div className="reviewer-layout-results">
                {layoutCheckResults.length ? (
                  layoutCheckResults.map((result) => (
                    <span key={result}>{result}</span>
                  ))
                ) : (
                  <b>Không tìm thấy nội dung từ journey khác.</b>
                )}
              </div>
            )}
          </Control>
          <Control label="quét biểu tượng hệ thống trên màn điện thoại">
            <button className="reviewer-layout-check" onClick={checkEmoji}>
              Kiểm tra emoji
            </button>
            {emojiCheckResults && (
              <div className="reviewer-layout-results">
                <b>{emojiCheckResults.length} kết quả</b>
                {emojiCheckResults.map((result, index) => (
                  <span key={`${result}-${index}`}>
                    U+
                    {result
                      .codePointAt(0)
                      ?.toString(16)
                      .toLocaleUpperCase("vi")}
                  </span>
                ))}
              </div>
            )}
          </Control>
          <Control label="đo tâm icon và khoảng cách badge góc">
            <button
              className="reviewer-layout-check"
              onClick={checkIconAlignment}
            >
              Kiểm tra căn icon
            </button>
            {iconCheckResults && (
              <div className="reviewer-layout-results">
                {iconCheckResults.length ? (
                  iconCheckResults.map((result, index) => (
                    <span key={`${result}-${index}`}>{result}</span>
                  ))
                ) : (
                  <b>0 lỗi căn icon</b>
                )}
              </div>
            )}
          </Control>
          <CheckControl
            label="ngoại tuyến"
            checked={store.offline}
            onChange={store.setOffline}
          />
          <CheckControl
            label="chỉ đọc"
            checked={store.readOnly}
            onChange={store.setReadOnly}
          />
          <CheckControl
            label="ngày lỡ"
            checked={store.missedDay}
            onChange={store.setMissedDay}
          />
          <Control label="trạng thái hành trình">
            <select
              value={store.journeyDemoState}
              onChange={(event) =>
                store.setJourneyDemoState(
                  event.target
                    .value as "normal" | "day1" | "loading" | "error" | "only" | "broken" | "removed" | "hidden",
                )
              }
            >
              <option value="normal">Bình thường</option>
              <option value="day1">Ngày 1</option>
              <option value="loading">Đang tải</option>
              <option value="error">Lỗi</option>
              <option value="only">Chỉ có mình bạn</option>
              <option value="broken">Chuỗi đứt</option>
              <option value="hidden">Ảnh ẩn</option>
              <option value="removed">Bị xoá khỏi nhóm</option>
            </select>
          </Control>
          <Control label="vai trò">
            <Segment
              value={
                (activeJourney?.owner ?? store.journeyOwner)
                  ? "owner"
                  : "member"
              }
              options={[
                ["owner", "Chủ nhóm"],
                ["member", "Thành viên"],
              ]}
              onChange={(value) => {
                const owner = value === "owner"
                store.setJourneyOwner(owner)
                if (activeJourney) {
                  store.updateJourney(activeJourney.id, { owner })
                }
              }}
            />
          </Control>
          <CheckControl
            label="chữ 135%"
            checked={store.largeType}
            onChange={store.setLargeType}
          />
          <CheckControl
            label="giảm chuyển động"
            checked={store.reduceMotion}
            onChange={store.setReduceMotion}
          />
          <CheckControl
            label="giảm trong suốt"
            checked={store.reduceTransparency}
            onChange={store.setReduceTransparency}
          />
          <Control label="dữ liệu hành trình">
            <Segment
              value={String(store.demoJourneyCount)}
              options={[
                ["12", "12 hành trình"],
                ["6", "6 hành trình"],
              ]}
              onChange={(value) =>
                store.setDemoJourneyCount(value === "6" ? 6 : 12)
              }
            />
          </Control>
          <Control label="trạng thái hoạt động">
            <Segment
              value={store.activityState}
              options={[
                ["normal", "Bình thường"],
                ["empty", "Trống"],
                ["loading", "Đang tải"],
              ]}
              onChange={(value) =>
                store.setActivityState(value as "normal" | "empty" | "loading")
              }
            />
          </Control>
          <Control label="trạng thái mã">
            <Segment
              value={store.otpMode}
              options={[
                ["normal", "Bình thường"],
                ["expired", "Hết hạn"],
                ["locked", "Tạm khóa"],
              ]}
              onChange={(value) =>
                store.setOtpMode(value as "normal" | "expired" | "locked")
              }
            />
          </Control>
          <Control label="quyền camera">
            <select
              value={store.cameraPermission}
              onChange={(event) =>
                store.setCameraPermission(
                  event.target
                    .value as "unknown" | "granted" | "deferred" | "denied",
                )
              }
            >
              <option value="unknown">Chưa hỏi</option>
              <option value="granted">Đã cho phép</option>
              <option value="deferred">Để sau</option>
              <option value="denied">Đã tắt</option>
            </select>
          </Control>
          <CheckControl
            label="hết phiên"
            checked={store.sessionExpired}
            onChange={store.setSessionExpired}
          />
          <CheckControl
            label="sheet thông báo"
            checked={store.notificationSheetOpen}
            onChange={store.setNotificationSheetOpen}
          />
          <CheckControl
            label="đã điểm danh"
            checked={store.checkedIn}
            onChange={(value) => {
              store.setCheckedIn(value)
              if (activeJourney) {
                store.updateJourney(activeJourney.id, { todayDone: value })
              }
            }}
          />
          <Control label="trạng thái Hub">
            <select
              value={store.hubState}
              onChange={(event) =>
                store.setHubState(
                  event.target
                    .value as "normal" | "empty" | "loading" | "error",
                )
              }
            >
              <option value="normal">Bình thường</option>
              <option value="empty">Trống</option>
              <option value="loading">Đang tải</option>
              <option value="error">Lỗi</option>
            </select>
          </Control>
          <Control label="hero Hub">
            <select
              value={store.hubHeroState}
              onChange={(event) =>
                store.setHubHeroState(
                  event.target
                    .value as "default" | "done" | "milestone" | "group",
                )
              }
            >
              <option value="default">Mặc định</option>
              <option value="done">Đã xong</option>
              <option value="milestone">Cột mốc</option>
              <option value="group">Hội đang chờ</option>
            </select>
          </Control>
          <Control label="nhảy tới màn">
            <div className="reviewer-routes">
              {routes.map(([path, label]) => (
                <button key={path} onClick={() => navigate(path)}>
                  {label}
                  <code>{path}</code>
                </button>
              ))}
            </div>
          </Control>
          <Control label="thông báo">
            <div className="reviewer-routes reviewer-reminders">
              {store.journeys.map((journey) => (
                <div key={journey.id}>
                  <b>{journey.name}</b>
                  <button
                    disabled={journey.todayDone}
                    title={
                      journey.todayDone ? "Hôm nay đã check-in" : undefined
                    }
                    onClick={() =>
                      store.setReminderBanner({
                        journeyId: journey.id,
                        kind: "daily",
                      })
                    }
                  >
                    Nhắc giờ
                    {journey.todayDone && <small>Hôm nay đã xong</small>}
                  </button>
                  <button
                    disabled={journey.todayDone}
                    title={
                      journey.todayDone ? "Hôm nay đã check-in" : undefined
                    }
                    onClick={() =>
                      store.setReminderBanner({
                        journeyId: journey.id,
                        kind: "streak",
                      })
                    }
                  >
                    Chuỗi sắp đứt 21:00
                    {journey.todayDone && <small>Hôm nay đã xong</small>}
                  </button>
                </div>
              ))}
              <button
                onClick={() => {
                  store.setSignedIn(false)
                  store.setPendingJoin("K7Q2M9XA")
                  navigate("/join/K7Q2M9XA")
                }}
              >
                mở link khi chưa đăng nhập
                <code>ourney://join/K7Q2M9XA</code>
              </button>
            </div>
          </Control>
          <SkinProof />
        </div>
      )}
    </aside>
  )
}

function SkinProof() {
  return (
    <div className="skin-proof">
      <span>so sánh hình dạng</span>
      <div className="skin-proof-row">
        {skins.map((skin) => (
          <div
            className={`skin-proof-set proof-${skin.id}`}
            style={
              {
                "--proof-accent": skin.variants[0].accent,
                "--proof-button": skin.variants[0].button,
              } as CSSProperties
            }
            key={skin.id}
          >
            <b>{skin.short}</b>
            <button>nút</button>
            <span>thẻ chọn</span>
            <div>thẻ nội dung</div>
          </div>
        ))}
      </div>
    </div>
  )
}

function Control({
  label,
  children,
}: {
  label: string
  children: React.ReactNode
}) {
  return (
    <label className="reviewer-control">
      <span>{label}</span>
      {children}
    </label>
  )
}

function Segment({
  value,
  options,
  onChange,
}: {
  value: string
  options: string[][]
  onChange: (value: string) => void
}) {
  return (
    <span className="reviewer-segment">
      {options.map(([option, label]) => (
        <button
          type="button"
          className={value === option ? "active" : ""}
          onClick={() => onChange(option)}
          key={option}
        >
          {label}
        </button>
      ))}
    </span>
  )
}

function CheckControl({
  label,
  checked,
  onChange,
}: {
  label: string
  checked: boolean
  onChange: (value: boolean) => void
}) {
  return (
    <label className="reviewer-check">
      <input
        type="checkbox"
        checked={checked}
        onChange={(event) => onChange(event.target.checked)}
      />
      <span>{label}</span>
    </label>
  )
}

function Entry() {
  return <Navigate replace to="/splash" />
}

function ScreenShell({
  title,
  children,
  camera = false,
  className = "",
  bare = false,
}: {
  title?: string
  children: React.ReactNode
  camera?: boolean
  className?: string
  bare?: boolean
}) {
  const navigate = useNavigate()
  const location = useLocation()
  const store = useStore()

  function goBack() {
    if (window.history.state?.idx > 0) navigate(-1)
    else navigate("/camera")
  }

  return (
    <section
      className={`app-screen ${camera ? "camera-screen" : ""} ${className}`}
    >
      {!camera && !bare && (
        <header className="screen-header">
          {location.pathname === "/hub" || location.pathname === "/activity" ? (
            <span aria-hidden="true" />
          ) : (
            <button onClick={goBack} aria-label="Quay lại">
              <OIcon name="back" size={22} weight="bold" />
            </button>
          )}
          {location.pathname === "/hub" ? (
            <Wordmark size={92} className="hub-wordmark" />
          ) : (
            title && <h1>{title}</h1>
          )}
          {location.pathname === "/hub" || location.pathname === "/activity" ? (
            <span aria-hidden="true" />
          ) : (
            <span aria-hidden="true" />
          )}
        </header>
      )}
      {store.offline && !camera && !bare && (
        <div className="offline-bar">
          <OIcon name="wifi-off" size={15} weight="bold" /> Đang ngoại tuyến
        </div>
      )}
      <div className="screen-content">{children}</div>
      <FloatingDock currentPath={location.pathname} />
    </section>
  )
}

function InviteSheet() {
  const store = useStore()
  const [toast, setToast] = useState("")
  const [shareOpen, setShareOpen] = useState(false)
  const startY = useRef<number | null>(null)
  const [drag, setDrag] = useState(0)
  const close = () => store.setInviteSheetOpen(false)
  const copied = (label: string) => {
    setToast(`${label} đã được sao chép`)
    window.setTimeout(() => setToast(""), 1800)
  }
  return (
    <PhoneOverlay>
      <div
        className="invite-scrim"
        onPointerDown={(event) =>
          event.target === event.currentTarget && close()
        }
      >
        <div
          className="invite-sheet"
          style={{ transform: `translateY(${drag}px)` }}
        >
          <div
            className="invite-drag"
            onPointerDown={(event) => {
              startY.current = event.clientY
              event.currentTarget.setPointerCapture(event.pointerId)
            }}
            onPointerMove={(event) => {
              if (startY.current !== null)
                setDrag(Math.max(0, event.clientY - startY.current))
            }}
            onPointerUp={() => {
              if (drag > 70) close()
              setDrag(0)
              startY.current = null
            }}
          >
            <i />
          </div>
          <button className="invite-close" onClick={close} aria-label="Đóng">
            <OIcon name="close" size={22} weight="bold" />
          </button>
          <h2>mời hội của bạn.</h2>
          <div className="invite-code" aria-label="Mã K7Q2 M9XA">
            {"K7Q2M9XA".split("").map((letter, index) => (
              <span key={`${letter}-${index}`}>{letter}</span>
            ))}
          </div>
          <button className="invite-copy" onClick={() => copied("Mã")}>
            <OIcon name="copy" size={20} weight="bold" /> Sao chép mã
          </button>
          <div className="invite-link">
            <span>ourney://join/K7Q2M9XA</span>
            <button onClick={() => copied("Link")}>Sao chép link</button>
          </div>
          <div className="invite-qr" aria-label="Mã QR">
            {Array.from({ length: 64 }, (_, index) => (
              <i
                key={index}
                className={index % 3 === 0 || index % 7 === 0 ? "on" : ""}
              />
            ))}
          </div>
          <button className="invite-share" onClick={() => setShareOpen(true)}>
            <OIcon name="share" size={20} weight="bold" /> Chia sẻ
          </button>
          <p>
            Chỉ ai có mã hoặc link này mới vào được. Hành trình nhóm không có
            link công khai.
          </p>
          <b className="invite-count">Đã mời 1/10</b>
          <button className="invite-later" onClick={close}>
            Để sau vậy.
          </button>
          {toast && <div className="invite-toast">{toast}</div>}
          {shareOpen && (
            <div className="share-mock">
              <b>Chia sẻ lời mời</b>
              <button onClick={() => setShareOpen(false)}>Tin nhắn</button>
              <button onClick={() => setShareOpen(false)}>Ứng dụng khác</button>
              <button onClick={() => setShareOpen(false)}>Đóng</button>
            </div>
          )}
        </div>
      </div>
    </PhoneOverlay>
  )
}

function QuietTopBar({
  journey,
  gear = false,
  onBack,
}: {
  journey: Journey
  gear?: boolean
  onBack?: () => void
}) {
  const navigate = useNavigate()
  return (
    <header className="quiet-topbar">
      <button
        onClick={onBack ?? (() => navigate("/hub"))}
        aria-label="Quay lại"
      >
        <OIcon name="back" size={21} weight="bold" />
      </button>
      <div>
        <b>{journey.name.toLocaleUpperCase("vi")}</b>
        <span>
          <OIcon name="lock" size={13} weight="fill" /> Riêng tư
        </span>
      </div>
      {gear ? (
        <button
          onClick={() => navigate(`/j/${journey.id}/edit`)}
          aria-label="Cài đặt hành trình"
        >
          <OIcon name="settings" size={21} weight="bold" />
        </button>
      ) : (
        <span className="quiet-top-placeholder" />
      )}
    </header>
  )
}

function QuietPhoto({
  blurred = false,
  scene = 0,
}: {
  blurred?: boolean
  scene?: number
}) {
  return (
    <div
      className={`quiet-photo-placeholder quiet-progress-${scene % 4} ${
        blurred ? "blurred" : ""
      }`}
      role="img"
      aria-label={`Ảnh tiến trình minh hoạ ngày ${scene + 1}`}
    >
      <i />
      <span />
    </div>
  )
}

function QuietJourneyHome({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const [revealed, setRevealed] = useState(false)
  const latestDay = journeyDisplayDay(journey)
  const timeline = [
    { day: latestDay, today: true, value: "18", label: "HÔM NAY" },
    { day: 14, value: "••", label: "NỬA CHẶNG" },
    { day: 9, missed: true, value: "", label: "NGHỈ" },
    { day: 7, value: "18", label: "TUẦN ĐẦU", milestone: true },
  ]
  return (
    <ScreenShell bare className="quiet-journey-screen">
      <QuietTopBar journey={journey} gear />
      <main className="quiet-home">
        {store.offline && (
          <div className="quiet-state-chip">
            <OIcon name="cloud-off" size={17} weight="bold" />
            Đang lưu trên máy · sẽ đồng bộ sau
          </div>
        )}
        {(store.readOnly || journey.archived) && (
          <button
            className="quiet-readonly"
            onClick={() => navigate(`/j/${journey.id}/wrapped`)}
          >
            <OIcon name="lock" size={17} weight="bold" />
            Hành trình đã kết thúc · chỉ xem
          </button>
        )}
        <section className="quiet-home-intro">
          <h1>Nhìn lại từng chút một.</h1>
          <p className="icon-text">
            Ngày {journey.day}/30 · <OIcon name="flame" size={17} active />{" "}
            {journey.streak}
          </p>
        </section>
        <section className="quiet-chart-card">
          <div className="quiet-axis">
            <span>{revealed ? "65,2 KG" : "••,• KG"}</span>
            <span>{revealed ? "62,0 KG" : "••,• KG"}</span>
          </div>
          <svg viewBox="0 0 300 118" role="img" aria-label="Đường tiến trình">
            <defs>
              <linearGradient id="quiet-fill" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0" stopColor="#10B981" stopOpacity=".24" />
                <stop offset="1" stopColor="#10B981" stopOpacity="0" />
              </linearGradient>
            </defs>
            <path
              className="quiet-chart-fill"
              d="M18 30 C72 42 95 48 132 59 S220 78 282 93 L282 116 L18 116 Z"
            />
            <path
              className="quiet-chart-line"
              d="M18 30 C72 42 95 48 132 59 S220 78 282 93"
            />
            <circle cx="18" cy="30" r="5" />
            <circle cx="282" cy="93" r="5" />
          </svg>
          <button
            className="quiet-hold"
            onPointerDown={() => setRevealed(true)}
            onPointerUp={() => setRevealed(false)}
            onPointerCancel={() => setRevealed(false)}
            onPointerLeave={() => setRevealed(false)}
          >
            {revealed ? (
              <OIcon name="eye-off" size={20} />
            ) : (
              <OIcon name="eye" size={20} />
            )}
            {revealed ? "Đang xem" : "Giữ để xem"}
          </button>
        </section>
        <section className="quiet-timeline" aria-label="Dòng thời gian">
          {timeline.map((item, index) => (
            <button
              key={`${item.day}-${index}`}
              className={`${item.today ? "today" : ""} ${
                item.missed ? "missed" : ""
              }`}
              onClick={() => navigate(`/j/${journey.id}/day/${item.day}`)}
            >
              <span className="quiet-timeline-photo">
                {item.missed ? (
                  <i className="quiet-missed-node" />
                ) : (
                  <DayPhotoStack journey={journey} day={item.day}>
                    <QuietPhoto scene={index} />
                  </DayPhotoStack>
                )}
                {store.offline && !item.missed && (
                  <small>
                    <OIcon name="clock" size={12} weight="bold" /> Chờ đồng bộ
                  </small>
                )}
              </span>
              <span className="quiet-node" />
              <span className="quiet-timeline-copy">
                <small>
                  NGÀY {String(item.day).padStart(2, "0")} · {item.label}
                </small>
                {item.value && <b>{revealed ? item.value : "••"}</b>}
                {item.missed && <em>Một ngày nghỉ không xóa hành trình.</em>}
              </span>
            </button>
          ))}
        </section>
        <section className="quiet-milestones">
          {[
            [7, "Tuần đầu", true],
            [14, "Nửa chặng", true],
            [30, "Về đích", false],
          ].map(([day, label, reached]) => (
            <div key={String(day)}>
              <span className={reached ? "reached" : ""}>
                <OIcon
                  name="star"
                  size={17}
                  weight={reached ? "fill" : "regular"}
                />
              </span>
              <small>NGÀY {String(day).padStart(2, "0")}</small>
              <b>{String(label)}</b>
            </div>
          ))}
        </section>
        <div className="quiet-home-actions">
          {journey.shared && (
            <button onClick={() => navigate(`/j/${journey.id}/squad`)}>
              <OIcon name="squad" size={19} weight="bold" /> Hội hôm nay
            </button>
          )}
          <button onClick={() => navigate(`/j/${journey.id}/share`)}>
            <OIcon name="share" size={19} weight="bold" /> Tạo thiệp
          </button>
        </div>
      </main>
    </ScreenShell>
  )
}

function ComposeJourneyTargets({ journey }: { journey: Journey }) {
  const store = useStore()
  const [expanded, setExpanded] = useState(false)
  const choices = store.journeys.filter(
    (item) => !item.archived && item.id !== journey.id,
  )
  return (
    <section className="compose-journey-targets">
      <button
        className="compose-target-chip"
        onClick={() => store.openCameraPicker("compose")}
      >
        <TypeBadge type={journey.type} size={28} />
        <span>
          <small>Đăng vào</small>
          <b>{journey.name}</b>
        </span>
        <OIcon name="caret-down" size={16} weight="bold" />
      </button>
      <button
        className="compose-add-more"
        onClick={() => setExpanded(!expanded)}
        aria-expanded={expanded}
      >
        <OIcon name="plus" size={17} weight="bold" /> Đăng thêm vào…
      </button>
      {expanded && (
        <div className="compose-multi-list">
          {choices.map((item) => {
            const selected = store.crossPostJourneyIds.includes(item.id)
            return (
              <button
                key={item.id}
                className={selected ? "selected" : ""}
                onClick={() => store.toggleCrossPostJourney(item.id)}
                aria-pressed={selected}
              >
                <TypeBadge type={item.type} size={26} />
                <span>{item.name}</span>
                {selected && <OIcon name="check" size={15} weight="bold" />}
              </button>
            )
          })}
        </div>
      )}
    </section>
  )
}

function QuietPost({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const [weight, setWeight] = useState(journey.lastWeight ?? 62)
  const [mood, setMood] = useState(journey.lastMood ?? "")
  const [caption, setCaption] = useState(journey.lastCaption ?? "")
  function submit() {
    if (store.readOnly) return
    const result = store.checkInJourney(journey.id, { caption, mood, weight })
    if (!result.first) {
      store.showToast(`Đã thêm ảnh thứ ${result.count} hôm nay`)
      navigate(`/j/${journey.id}/camera`, { replace: true })
      return
    }
    if (!store.notificationPromptHandled) {
      store.setNotificationSheetOpen(true)
    }
    navigate(`/j/${journey.id}/done`, { replace: true })
  }
  return (
    <section className="quiet-page quiet-post">
      <QuietTopBar journey={journey} />
      <div className="quiet-page-scroll">
        <QuietPhoto />
        <section className="quiet-ruler">
          <div>
            <b>{weight.toFixed(1).replace(".", ",")} KG</b>
            <span>(-3,2 KG)</span>
          </div>
          <input
            type="range"
            min="55"
            max="75"
            step=".1"
            value={weight}
            onChange={(event) => setWeight(Number(event.target.value))}
            aria-label="Cân nặng"
          />
          <label>Cân nặng (không bắt buộc)</label>
          <small>
            <OIcon name="lock" size={13} weight="fill" /> Chỉ mình bạn thấy
          </small>
        </section>
        <section className="quiet-caption">
          <label htmlFor="quiet-caption">Hôm nay bạn cảm thấy thế nào?</label>
          <div className="quiet-moods">
            {["Nhẹ nhõm", "Bình thường", "Hơi mệt"].map((item) => (
              <button
                key={item}
                className={mood === item ? "selected" : ""}
                onClick={() => setMood(item)}
                aria-pressed={mood === item}
              >
                {mood === item && (
                  <OIcon name="check" size={14} weight="bold" />
                )}
                {item}
              </button>
            ))}
          </div>
          <textarea
            id="quiet-caption"
            maxLength={140}
            value={caption}
            onChange={(event) => setCaption(event.target.value)}
            placeholder="Viết một dòng cho riêng bạn..."
          />
          <small>{caption.length}/140</small>
        </section>
        <ComposeJourneyTargets journey={journey} />
        <button className="quiet-post-primary" onClick={submit}>
          {journey.todayDone ? "Thêm ảnh" : "Đăng"}
        </button>
        <button
          className="quiet-post-retake"
          onClick={() =>
            navigate(
              journey.todayDone
                ? `/j/${journey.id}`
                : `/j/${journey.id}/camera`,
            )
          }
        >
          {journey.todayDone ? "Bỏ ảnh này" : "Chụp lại"}
        </button>
      </div>
    </section>
  )
}

function QuietDone({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const doneDay = Math.max(1, journey.day - 1)
  const milestone = doneDay === 7 || doneDay === 30
  useEffect(() => {
    if (store.notificationSheetOpen) return
    const timer = window.setTimeout(
      () => navigate(`/j/${journey.id}`, { replace: true }),
      store.reduceMotion ? 150 : 1800,
    )
    return () => window.clearTimeout(timer)
  }, [store.notificationSheetOpen, store.reduceMotion, journey.id])
  return (
    <section
      className={`quiet-page quiet-done ${milestone ? "milestone" : ""}`}
      onClick={() => {
        if (!store.notificationSheetOpen) {
          navigate(`/j/${journey.id}`, { replace: true })
        }
      }}
    >
      <div className="quiet-celebration">
        <div className="quiet-seal">
          {milestone && (
            <span className="quiet-star-ring">
              {Array.from({ length: 5 }, (_, index) => (
                <OIcon name="star" size={18} key={index} active />
              ))}
            </span>
          )}
          <b>
            NGÀY {doneDay} <OIcon name="check" size={18} />
          </b>
        </div>
        <h1>
          Chuỗi <StreakValue count={journey.streak} suffix="ngày" />
        </h1>
        {milestone && <h2>{doneDay === 7 ? "Tuần đầu" : "Về đích"}</h2>}
        <p>Đã lưu. Chỉ mình bạn thấy.</p>
        {milestone && (
          <button
            onClick={(event) => {
              event.stopPropagation()
              navigate(`/j/${journey.id}/share`)
            }}
          >
            {journey.skin === "memory"
              ? "Chia sẻ poster chuyến đi"
              : journey.skin === "couple"
                ? "Chia sẻ câu chuyện"
                : journey.skin === "flexer"
                  ? "Chia sẻ lên Story"
                  : journey.skin === "minimal"
                    ? "Xuất thẻ"
                    : "Tạo thiệp"}
          </button>
        )}
      </div>
      {store.notificationSheetOpen && (
        <PermissionSheet
          kind="notification"
          onClose={() => {
            store.setNotificationPromptHandled(true)
            store.setNotificationSheetOpen(false)
          }}
          onConfirm={() => {
            store.setNotificationPromptHandled(true)
            store.setNotificationSheetOpen(false)
          }}
        />
      )}
    </section>
  )
}

function QuietSquad({ journey }: { journey: Journey }) {
  const navigate = useNavigate()
  const [shown, setShown] = useState<string[]>([])
  const members = [
    ["An", "Đã chụp 06:10", 6],
    ["Bình", "Chưa chụp", 5],
    ["Hà", "Đã chụp 07:20", 7],
    ["Nam", "Chưa chụp", 4],
  ] as const
  return (
    <section className="quiet-page quiet-squad">
      <QuietTopBar journey={journey} />
      <div className="quiet-page-scroll">
        <h1>Hội hôm nay.</h1>
        <p className="quiet-squad-intro">Xếp theo tên, không theo kết quả.</p>
        <div className="quiet-member-list">
          {members.map(([name, status, count]) => {
            const visible = shown.includes(name)
            return (
              <article key={name}>
                <span className="quiet-member-avatar">{name.slice(0, 1)}</span>
                <div>
                  <b>{name}</b>
                  <small>
                    {status === "Chưa chụp" ? (
                      <OIcon name="clock" size={14} />
                    ) : (
                      <OIcon name="check" size={14} weight="bold" />
                    )}
                    {status}
                  </small>
                  <span className="quiet-seven-dots">
                    {Array.from({ length: 7 }, (_, index) => (
                      <i
                        className={index < count ? "filled" : ""}
                        key={index}
                      />
                    ))}
                    <em>đều đặn {count}/7</em>
                  </span>
                </div>
                <button
                  onClick={() =>
                    setShown((current) =>
                      visible
                        ? current.filter((item) => item !== name)
                        : [...current, name],
                    )
                  }
                >
                  {visible ? "Ẩn ảnh" : "Xem ảnh"}
                </button>
                <QuietPhoto blurred={!visible} />
              </article>
            )
          })}
        </div>
        <footer>
          Không ai bị so cân. Chỉ đếm sự đều đặn.
          <button onClick={() => navigate(`/j/${journey.id}`)}>Quay lại</button>
        </footer>
      </div>
    </section>
  )
}

function QuietPrivacySheet({
  onClose,
  onShow,
}: {
  onClose: () => void
  onShow: () => void
}) {
  const startY = useRef(0)
  const [drag, setDrag] = useState(0)
  return (
    <PhoneOverlay>
      <div
        className="quiet-sheet-scrim"
        onPointerDown={(event) =>
          event.target === event.currentTarget && onClose()
        }
      >
        <div
          className="quiet-sheet"
          style={{ transform: `translateY(${drag}px)` }}
        >
          <div
            className="quiet-sheet-drag"
            onPointerDown={(event) => {
              startY.current = event.clientY
              event.currentTarget.setPointerCapture(event.pointerId)
            }}
            onPointerMove={(event) =>
              setDrag(Math.max(0, event.clientY - startY.current))
            }
            onPointerUp={() => {
              if (drag > 70) onClose()
              setDrag(0)
            }}
          >
            <i />
          </div>
          <button
            className="quiet-sheet-close"
            onClick={onClose}
            aria-label="Đóng"
          >
            <OIcon name="close" size={21} weight="bold" />
          </button>
          <h2>Hiện số kg trên thẻ?</h2>
          <p>Ai xem thẻ đều thấy số này.</p>
          <button className="quiet-sheet-primary" onClick={onClose}>
            Giữ ẩn
          </button>
          <button className="quiet-sheet-secondary" onClick={onShow}>
            Vẫn hiện
          </button>
        </div>
      </div>
    </PhoneOverlay>
  )
}

function QuietShare({ journey }: { journey: Journey }) {
  const navigate = useNavigate()
  const [ratio, setRatio] = useState<"story" | "feed">("story")
  const [hideBrand, setHideBrand] = useState(true)
  const [toast, setToast] = useState("")
  return (
    <section className="quiet-page quiet-share">
      <QuietTopBar journey={journey} onBack={() => navigate(-1)} />
      <div className="quiet-page-scroll">
        <h1>Tạo thiệp.</h1>
        <div className="quiet-ratio-tabs">
          <button
            className={ratio === "story" ? "selected" : ""}
            onClick={() => setRatio("story")}
          >
            9:16
          </button>
          <button
            className={ratio === "feed" ? "selected" : ""}
            onClick={() => setRatio("feed")}
          >
            4:5
          </button>
        </div>
        <div className={`quiet-share-card ${ratio}`}>
          <div>
            <figure>
              <QuietPhoto blurred />
              <figcaption>
                NGÀY {journeyTodayEntry(journey)?.day ?? journey.day}
              </figcaption>
            </figure>
          </div>
          <p>21 ngày đều đặn</p>
          {!hideBrand && <Wordmark size={56} className="share-brand" />}
        </div>
        <div className="quiet-share-controls">
          <p className="quiet-share-private-note">
            <OIcon name="lock" size={15} /> Ảnh đại diện được làm mờ · số kg
            luôn ẩn
          </p>
          <label>
            <span>Ẩn chữ ourney</span>
            <span className="quiet-switch-hit">
              <input
                type="checkbox"
                checked={hideBrand}
                onChange={(event) => setHideBrand(event.target.checked)}
              />
            </span>
          </label>
        </div>
        <button
          className="quiet-export"
          onClick={() => {
            setToast("Đã lưu thẻ.")
            window.setTimeout(() => setToast(""), 1800)
          }}
        >
          Xuất thẻ
        </button>
      </div>
      {toast && <div className="quiet-share-toast">{toast}</div>}
    </section>
  )
}

function SquadTopBar({
  journey,
  onBack,
  gear = false,
}: {
  journey: Journey
  onBack?: () => void
  gear?: boolean
}) {
  const navigate = useNavigate()
  return (
    <header className="squad-journey-topbar">
      <button
        onClick={onBack ?? (() => navigate("/hub"))}
        aria-label="Quay lại"
      >
        <OIcon name="back" size={21} weight="bold" />
      </button>
      <b>{journey.name.toLocaleUpperCase("vi")}</b>
      {gear ? (
        <button
          onClick={() => navigate(`/j/${journey.id}/edit`)}
          aria-label="Cài đặt hành trình"
        >
          <OIcon name="settings" size={21} weight="bold" />
        </button>
      ) : (
        <span />
      )}
    </header>
  )
}

function SquadPhoto({ scene = 0 }: { scene?: number }) {
  const labels = [
    "Bàn học với laptop",
    "Vở ghi và cà phê",
    "Góc học từ vựng",
    "Bàn học buổi sáng",
  ]
  return (
    <div
      className={`squad-photo-placeholder squad-study-scene-${scene % 4}`}
      role="img"
      aria-label={labels[scene % labels.length]}
    >
      <span />
      <i />
      <em />
      <strong />
      <b>IELTS</b>
    </div>
  )
}

function SquadAvatarStack({ attendance }: { attendance: number }) {
  return (
    <span className="squad-avatar-stack" aria-label={`${attendance} trên 5`}>
      {["L", "A", "H", "N", "M"].map((name, index) => (
        <i className={index < attendance ? "checked" : ""} key={name}>
          {name}
          {index < attendance && <OIcon name="check" size={12} />}
        </i>
      ))}
    </span>
  )
}

function SquadJourneyHome({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const attendance = journey.attendance ?? 3
  const today = journeyDisplayDay(journey)
  const stones = [
    { day: 30, label: "VỀ ĐÍCH", future: today < 30 },
    { day: 24, label: "SẮP TỚI", future: today < 24 },
    { day: today, label: "HÔM NAY", current: true },
    { day: 14, label: "TUẦN 2", milestone: true },
    { day: 9, label: "LỠ", missed: true },
    { day: 7, label: "TUẦN 1", milestone: true },
    { day: 1, label: "XUẤT PHÁT" },
  ]
  return (
    <ScreenShell bare className="squad-journey-screen">
      <SquadTopBar journey={journey} gear />
      <main className="squad-journey-home">
        {store.offline && (
          <div className="squad-offline-pill">
            <OIcon name="cloud-off" size={17} weight="bold" />
            CHỜ ĐỒNG BỘ · ĐÃ LƯU TRÊN MÁY
          </div>
        )}
        {(store.readOnly || journey.archived) && (
          <button
            className="squad-ended-stamp"
            onClick={() => navigate(`/j/${journey.id}/wrapped`)}
          >
            <OIcon name="lock" size={16} weight="bold" /> ĐÃ KẾT THÚC · CHỈ XEM
          </button>
        )}
        <button
          className="squad-progress-chip"
          onClick={() => navigate(`/j/${journey.id}/squad`)}
        >
          <span className="icon-text">
            <OIcon name="flame" size={17} active /> HỘI IELTS 7.5 · 30 NGÀY
          </span>
          <span>
            <SquadAvatarStack attendance={attendance} />
            <b>{attendance}/5 HÔM NAY</b>
          </span>
        </button>
        <section className="squad-ribbon-map">
          <button
            className="squad-trophy"
            onClick={() =>
              navigate(
                today >= 30
                  ? `/j/${journey.id}/wrapped`
                  : `/j/${journey.id}/share`,
              )
            }
          >
            <OIcon name="trophy" size={38} weight="fill" />
            <b>CÚP 7.5</b>
            <small>NGÀY 30</small>
          </button>
          <svg
            className="squad-ribbon"
            viewBox="0 0 330 650"
            aria-hidden="true"
          >
            <path
              className="squad-ribbon-border"
              d="M166 630 C55 560 60 470 170 420 S276 276 168 230 S62 102 164 45"
            />
            <path
              className="squad-ribbon-paper"
              d="M166 630 C55 560 60 470 170 420 S276 276 168 230 S62 102 164 45"
            />
            <path
              className="squad-ribbon-flame"
              d="M168 230 C62 102 164 45 164 45"
            />
          </svg>
          <div className="squad-stones">
            {stones.map((stone, index) => (
              <button
                key={`${stone.day}-${index}`}
                className={`squad-stone ${index % 2 ? "left" : "right"} ${
                  stone.current ? "current" : ""
                } ${stone.future ? "future" : ""} ${
                  stone.missed ? "missed" : ""
                }`}
                onClick={() => navigate(`/j/${journey.id}/day/${stone.day}`)}
              >
                {stone.future || stone.missed ? (
                  <span className="squad-empty-photo" />
                ) : (
                  <DayPhotoStack journey={journey} day={stone.day}>
                    <SquadPhoto />
                  </DayPhotoStack>
                )}
                <b>
                  NGÀY {String(stone.day).padStart(2, "0")} ·{" "}
                  {stone.milestone && <OIcon name="star" size={15} active />}{" "}
                  {stone.current && <OIcon name="flame" size={15} active />}{" "}
                  {stone.label}
                </b>
                {stone.missed && (
                  <small>Lỡ một hôm thôi. Mai về lại đường nào!</small>
                )}
              </button>
            ))}
          </div>
        </section>
        <button
          className="squad-group-action"
          onClick={() => navigate(`/j/${journey.id}/share`)}
        >
          <OIcon name="share" size={19} weight="bold" /> Tạo thiệp
        </button>
      </main>
    </ScreenShell>
  )
}

function SquadPost({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const [minutes, setMinutes] = useState<number | null>(
    journey.lastMinutes ?? null,
  )
  const [custom, setCustom] = useState(45)
  const [caption, setCaption] = useState(journey.lastCaption ?? "")
  const choices = [15, 30, 45, 60]
  function submit() {
    const selectedMinutes = minutes === -1 ? custom : minutes
    if (!selectedMinutes || store.readOnly) return
    const result = store.checkInJourney(journey.id, {
      caption,
      mood: "",
      minutes: selectedMinutes,
      person: "Linh",
    })
    if (!result.first) {
      store.showToast(`Đã thêm ảnh thứ ${result.count} hôm nay`)
      navigate(`/j/${journey.id}/camera`, { replace: true })
      return
    }
    if (!store.notificationPromptHandled) {
      store.setNotificationSheetOpen(true)
    }
    navigate(`/j/${journey.id}/done`, { replace: true })
  }
  return (
    <section className="squad-journey-page squad-post">
      <SquadTopBar
        journey={journey}
        onBack={() => navigate(`/j/${journey.id}/camera`)}
      />
      <div className="squad-page-scroll">
        <div className="squad-post-polaroid">
          <SquadPhoto />
          <b>NGÀY {journey.day}</b>
        </div>
        <section className="squad-minutes">
          <h1>hôm nay học bao lâu.</h1>
          <div>
            {choices.map((value) => (
              <button
                key={value}
                className={minutes === value ? "selected" : ""}
                onClick={() => setMinutes(value)}
                aria-pressed={minutes === value}
              >
                {minutes === value && (
                  <OIcon name="check" size={14} weight="bold" />
                )}
                {value}
              </button>
            ))}
            <button
              className={minutes === -1 ? "selected" : ""}
              onClick={() => setMinutes(-1)}
              aria-pressed={minutes === -1}
            >
              {minutes === -1 && <OIcon name="check" size={14} weight="bold" />}
              Khác
            </button>
          </div>
          {minutes === -1 && (
            <div className="squad-stepper">
              <button
                onClick={() => setCustom(Math.max(5, custom - 5))}
                aria-label="Giảm năm phút"
              >
                −
              </button>
              <b>{custom}</b>
              <button
                onClick={() => setCustom(Math.min(180, custom + 5))}
                aria-label="Tăng năm phút"
              >
                +
              </button>
            </div>
          )}
          <span>PHÚT</span>
        </section>
        <section className="squad-caption">
          <label htmlFor="squad-caption">Hôm nay bạn học được gì?</label>
          <textarea
            id="squad-caption"
            maxLength={140}
            value={caption}
            onChange={(event) => setCaption(event.target.value)}
            placeholder="Ghi nhanh một điều..."
          />
          <small>{caption.length}/140</small>
        </section>
        <ComposeJourneyTargets journey={journey} />
        <button
          className="squad-post-primary"
          disabled={minutes === null || store.readOnly}
          onClick={submit}
        >
          {journey.todayDone ? "Thêm ảnh" : "Đăng"}
        </button>
        <button
          className="squad-post-retake"
          onClick={() =>
            navigate(
              journey.todayDone
                ? `/j/${journey.id}`
                : `/j/${journey.id}/camera`,
            )
          }
        >
          {journey.todayDone ? "Bỏ ảnh này" : "Chụp lại"}
        </button>
      </div>
    </section>
  )
}

function SquadDone({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const day = Math.max(1, journey.day - 1)
  const attendance = journey.attendance ?? 4
  const milestone = day === 7 || day === 30
  useEffect(() => {
    if (store.notificationSheetOpen) return
    const timer = window.setTimeout(
      () => navigate(`/j/${journey.id}`, { replace: true }),
      store.reduceMotion ? 150 : 1800,
    )
    return () => window.clearTimeout(timer)
  }, [store.notificationSheetOpen, store.reduceMotion, journey.id])
  return (
    <section
      className={`squad-journey-page squad-done ${
        milestone ? "milestone" : ""
      }`}
      onClick={() => {
        if (!store.notificationSheetOpen) {
          navigate(`/j/${journey.id}`, { replace: true })
        }
      }}
    >
      {milestone && day === 7 && (
        <div className="squad-confetti" aria-hidden="true">
          {Array.from({ length: 14 }, (_, index) => (
            <i key={index} />
          ))}
        </div>
      )}
      <div className="squad-celebration">
        {day === 30 ? (
          <OIcon
            name="trophy"
            className="squad-rising-trophy"
            size={92}
            weight="fill"
          />
        ) : null}
        <div className="squad-checkin-stamp">
          {day === 30
            ? "CÚP 7.5 VỀ TAY"
            : day === 7
              ? "TUẦN 1 XONG"
              : "ĐÃ ĐIỂM DANH"}
        </div>
        <h1 className="icon-text">
          Ngày {day} · chuỗi <StreakValue count={journey.streak} />
        </h1>
        <button
          onClick={(event) => {
            event.stopPropagation()
            navigate(`/j/${journey.id}/squad`)
          }}
        >
          <SquadAvatarStack attendance={attendance} />
          {attendance}/5 đứa đã điểm danh
        </button>
      </div>
      {store.notificationSheetOpen && (
        <PermissionSheet
          kind="notification"
          onClose={() => {
            store.setNotificationPromptHandled(true)
            store.setNotificationSheetOpen(false)
          }}
          onConfirm={() => {
            store.setNotificationPromptHandled(true)
            store.setNotificationSheetOpen(false)
          }}
        />
      )}
    </section>
  )
}

const squadMembers = [
  ["AN", "06:02"],
  ["HÀ", "06:08"],
  ["LINH", "06:10"],
  ["NAM", "06:14"],
] as const

function SquadToday({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const attendance = journey.attendance ?? 4
  const [reaction, setReaction] = useState<Record<string, string>>({})
  const [reminded, setReminded] = useState(false)
  const [toast, setToast] = useState("")
  const reactions = reactionOptions
  const visibleMembers =
    attendance >= 4
      ? squadMembers
      : squadMembers.filter(([name]) => name !== "LINH")
  const todayPhotos = journeyTodayEntry(journey)?.photos ?? []
  return (
    <ScreenShell bare className="squad-journey-screen">
      <SquadTopBar journey={journey} onBack={() => navigate(-1)} />
      <main className="squad-today">
        {store.offline && (
          <div className="squad-offline-pill">
            <OIcon name="cloud-off" size={17} weight="bold" />
            CHỜ ĐỒNG BỘ · ĐÃ LƯU TRÊN MÁY
          </div>
        )}
        {(store.readOnly || journey.archived) && (
          <div className="squad-ended-stamp">
            <OIcon name="lock" size={16} weight="bold" /> ĐÃ KẾT THÚC · CHỈ XEM
          </div>
        )}
        <div className="squad-attendance-bar">
          <span style={{ width: `${(attendance / 5) * 100}%` }} />
          <b>{attendance}/5 ĐÃ ĐIỂM DANH</b>
        </div>
        <p className="squad-updated">Cập nhật lúc 06:12</p>
        <div className="squad-wall">
          {visibleMembers.map(([name, time], index) => {
            const memberPhotos = todayPhotos.filter(
              (photo) =>
                photo.person?.toLocaleUpperCase("vi") ===
                name.toLocaleUpperCase("vi"),
            )
            return (
              <article key={name}>
                <button
                  className="card-open-hit"
                  aria-label={`Mở ảnh hôm nay của ${name}`}
                  onClick={() =>
                    navigate(
                      `/j/${journey.id}/day/${journeyTodayEntry(journey)?.day ?? journey.day}`,
                    )
                  }
                />
                <div className="squad-member-photos">
                  {(memberPhotos.length ? memberPhotos : [null]).map(
                    (photo, photoIndex) => (
                      <span key={photo?.id ?? `${name}-fallback`}>
                        <SquadPhoto scene={index + photoIndex} />
                        <small>{photo?.time ?? time}</small>
                      </span>
                    ),
                  )}
                </div>
                <b>
                  {name} <OIcon name="check" size={14} weight="bold" /> {time}
                </b>
                <span className="squad-reaction-counts">
                  <ReactionIcon id="fire" size={15} />{" "}
                  {4 + (reaction[name] === "fire" ? 1 : 0)} ·{" "}
                  <ReactionIcon id="clap" size={15} />{" "}
                  {3 + (reaction[name] === "clap" ? 1 : 0)}
                  {reaction[name] &&
                    reaction[name] !== "fire" &&
                    reaction[name] !== "clap" && (
                      <>
                        {" "}
                        ·{" "}
                        <ReactionIcon id={reaction[name] as "flex"} size={15} />{" "}
                        1
                      </>
                    )}
                </span>
                <div className="squad-reactions">
                  {reactions.map((item) => (
                    <button
                      key={item.id}
                      className={reaction[name] === item.id ? "selected" : ""}
                      disabled={store.readOnly}
                      aria-pressed={reaction[name] === item.id}
                      aria-label={item.label}
                      onClick={(event) => {
                        event.stopPropagation()
                        setReaction((current) => ({
                          ...current,
                          [name]: current[name] === item.id ? "" : item.id,
                        }))
                      }}
                    >
                      <OIcon name={item.icon} size={20} active />
                    </button>
                  ))}
                </div>
              </article>
            )
          })}
          {!store.blocked.includes("Minh") && (
            <article className="squad-waiting-tile">
              <span className="squad-empty-photo" />
              <b>MINH · ĐANG CHỜ</b>
              <button
                className="squad-remind"
                disabled={store.offline || store.readOnly || reminded}
                onClick={() => {
                  setReminded(true)
                  setToast("Đã nhắc Minh")
                  window.setTimeout(() => setToast(""), 1800)
                }}
              >
                {store.readOnly ? (
                  "Đã lưu trữ"
                ) : store.offline ? (
                  "Cần mạng"
                ) : reminded ? (
                  "Đã nhắc Minh"
                ) : (
                  <>
                    Nhắc Minh <ReactionIcon id="wave" size={16} />
                  </>
                )}
              </button>
            </article>
          )}
        </div>
      </main>
      {toast && <div className="squad-toast">{toast}</div>}
    </ScreenShell>
  )
}

function SquadShareSheet({
  onClose,
  hideBrand,
  onToggleBrand,
}: {
  onClose: () => void
  hideBrand: boolean
  onToggleBrand: () => void
}) {
  const startY = useRef(0)
  const [drag, setDrag] = useState(0)
  return (
    <PhoneOverlay>
      <div
        className="squad-share-scrim"
        onPointerDown={(event) =>
          event.target === event.currentTarget && onClose()
        }
      >
        <div
          className="squad-share-sheet"
          style={{ transform: `translateY(${drag}px)` }}
        >
          <div
            className="squad-share-drag"
            onPointerDown={(event) => {
              startY.current = event.clientY
              event.currentTarget.setPointerCapture(event.pointerId)
            }}
            onPointerMove={(event) =>
              setDrag(Math.max(0, event.clientY - startY.current))
            }
            onPointerUp={() => {
              if (drag > 70) onClose()
              setDrag(0)
            }}
          >
            <i />
          </div>
          <button
            className="squad-share-close"
            onClick={onClose}
            aria-label="Đóng"
          >
            <OIcon name="close" size={21} weight="bold" />
          </button>
          <h2>chia sẻ tấm thiệp.</h2>
          <button className="share-brand-toggle" onClick={onToggleBrand}>
            <OIcon name={hideBrand ? "eye-off" : "eye"} size={20} />
            Ẩn chữ ourney
            <span>{hideBrand ? "Bật" : "Tắt"}</span>
          </button>
          <button onClick={onClose}>Tin nhắn</button>
          <button onClick={onClose}>Ứng dụng khác</button>
          <button onClick={onClose}>Lưu ảnh</button>
        </div>
      </div>
    </PhoneOverlay>
  )
}

function SquadShare({ journey }: { journey: Journey }) {
  const navigate = useNavigate()
  const [ratio, setRatio] = useState<"story" | "feed">("story")
  const [shareOpen, setShareOpen] = useState(false)
  const [hideBrand, setHideBrand] = useState(false)
  return (
    <section className="squad-journey-page squad-share-page">
      <SquadTopBar journey={journey} onBack={() => navigate(-1)} />
      <div className="squad-page-scroll">
        <h1>tạo thiệp.</h1>
        <div className="squad-share-tabs">
          <button
            className={ratio === "story" ? "selected" : ""}
            onClick={() => setRatio("story")}
          >
            9:16
          </button>
          <button
            className={ratio === "feed" ? "selected" : ""}
            onClick={() => setRatio("feed")}
          >
            4:5
          </button>
        </div>
        <div className={`squad-share-poster ${ratio}`}>
          <h2>4/5 ĐÃ ĐIỂM DANH · NGÀY 21</h2>
          <div className="squad-poster-wall">
            {[1, 2, 3, 4].map((item) => (
              <SquadPhoto key={item} />
            ))}
          </div>
          <div className="squad-trophy-stamp">
            <OIcon name="trophy" size={26} weight="fill" /> CÚP 7.5
          </div>
          {!hideBrand && <Wordmark size={56} className="share-brand" />}
        </div>
        <button
          className="squad-share-button"
          onClick={() => setShareOpen(true)}
        >
          <OIcon name="share" size={19} weight="bold" /> Chia sẻ
        </button>
      </div>
      {shareOpen && (
        <SquadShareSheet
          onClose={() => setShareOpen(false)}
          hideBrand={hideBrand}
          onToggleBrand={() => setHideBrand(!hideBrand)}
        />
      )}
    </section>
  )
}

function PosterShareSheet({
  skin,
  title,
  onClose,
  hideBrand,
  onToggleBrand,
}: {
  skin: "memory" | "couple" | "flexer" | "minimal"
  title: string
  onClose: () => void
  hideBrand: boolean
  onToggleBrand: () => void
}) {
  const startY = useRef(0)
  const [drag, setDrag] = useState(0)
  return (
    <PhoneOverlay>
      <div
        className={`poster-share-scrim poster-share-${skin}`}
        onPointerDown={(event) =>
          event.target === event.currentTarget && onClose()
        }
      >
        <div
          className="poster-share-sheet"
          style={{ transform: `translateY(${drag}px)` }}
        >
          <div
            className="poster-share-drag"
            onPointerDown={(event) => {
              startY.current = event.clientY
              event.currentTarget.setPointerCapture(event.pointerId)
            }}
            onPointerMove={(event) =>
              setDrag(Math.max(0, event.clientY - startY.current))
            }
            onPointerUp={() => {
              if (drag > 70) onClose()
              setDrag(0)
            }}
          >
            <i />
          </div>
          <button
            className="poster-share-close"
            onClick={onClose}
            aria-label="Đóng"
          >
            <OIcon name="close" size={21} weight="bold" />
          </button>
          <h2>{title}</h2>
          <button className="share-brand-toggle" onClick={onToggleBrand}>
            <OIcon name={hideBrand ? "eye-off" : "eye"} size={20} />
            Ẩn chữ ourney
            <span>{hideBrand ? "Bật" : "Tắt"}</span>
          </button>
          <button onClick={onClose}>Tin nhắn</button>
          <button onClick={onClose}>Ứng dụng khác</button>
          <button onClick={onClose}>Lưu ảnh</button>
        </div>
      </div>
    </PhoneOverlay>
  )
}

function MemoryTopBar({
  journey,
  onBack,
  gear = false,
}: {
  journey: Journey
  onBack?: () => void
  gear?: boolean
}) {
  const navigate = useNavigate()
  return (
    <header className="memory-topbar">
      <button
        onClick={onBack ?? (() => navigate("/hub"))}
        aria-label="Quay lại"
      >
        <OIcon name="back" size={21} weight="bold" />
      </button>
      <b>
        {journey.name.toLocaleUpperCase("vi")} · NGÀY {journey.day}/
        {journeyLength(journey)}
      </b>
      {gear ? (
        <button
          onClick={() => navigate(`/j/${journey.id}/edit`)}
          aria-label="Cài đặt hành trình"
        >
          <OIcon name="settings" size={21} weight="bold" />
        </button>
      ) : (
        <span />
      )}
    </header>
  )
}

function MemoryPhoto({ scene = 0 }: { scene?: number }) {
  return (
    <div className={`memory-photo-placeholder memory-scene-${scene % 4}`}>
      <span />
      <i />
      <b>
        <OIcon name={scene % 2 ? "cloud" : "pine"} size={24} />
      </b>
    </div>
  )
}

function MemoryJourneyHome({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const frames = journey.frameCount ?? journeyPhotoCount(journey)
  const totalDays = 24
  const ownLabel = (
    journey.lastCaption ||
    journey.lastPlace ||
    journey.name
  ).toLocaleUpperCase("vi")
  const entries = ([
    [journey.day - 1, ownLabel, 3],
    [journey.day - 2, ownLabel, 2],
    [1, ownLabel, 0],
  ] as Array<[number, string, number]>)
    .filter(([day]) => day >= 1)
    .filter(
      ([day], index, list) =>
        list.findIndex(([candidate]) => candidate === day) === index,
    )
  return (
    <ScreenShell bare className="memory-journey-screen">
      <MemoryTopBar journey={journey} gear />
      <main className="memory-home">
        {store.offline && (
          <div className="memory-offline-strip">
            <OIcon name="cloud-off" size={17} weight="bold" />
            Đang lưu trên máy. Có mạng sẽ tự gửi.
          </div>
        )}
        {(store.readOnly || journey.archived) && (
          <div className="memory-closed">
            <span>ĐÃ ĐÓNG SỔ</span>
            <button onClick={() => navigate(`/j/${journey.id}/wrapped`)}>
              Xem tổng kết
            </button>
          </div>
        )}
        <div className="memory-film-chip">
          <OIcon name="film" size={19} weight="bold" />
          CUỘN PHIM {frames}/{totalDays}
        </div>
        {frames >= totalDays && (
          <p className="memory-roll-note">Hết cuộn 24 tấm · mở cuộn mới</p>
        )}
        <section className="memory-thread-timeline">
          <svg viewBox="0 0 330 520" aria-hidden="true">
            <path d="M164 510 C48 455 55 370 170 330 S280 190 164 150 S55 70 166 12" />
          </svg>
          <div className="memory-thread-knot knot-one" />
          <div className="memory-thread-knot knot-two" />
          <div className="memory-thread-knot knot-three" />
          <div className="memory-thread-knot knot-four" />
          <button
            className="memory-polaroid memory-today-slot"
            onClick={() => navigate(`/j/${journey.id}/camera`)}
          >
            <span />
            <b>HÔM NAY · chạm để chụp</b>
          </button>
          {entries.map(([day, label, scene], index) => {
            const missed = store.missedDay && day === 3
            return (
              <button
                key={`${day}-${label}`}
                className={`memory-polaroid memory-entry-${index} ${
                  missed ? "missed" : ""
                }`}
                onClick={() => navigate(`/j/${journey.id}/day/${day}`)}
              >
                {missed ? (
                  <span className="memory-empty-frame" />
                ) : (
                  <DayPhotoStack journey={journey} day={day}>
                    <MemoryPhoto scene={scene} />
                  </DayPhotoStack>
                )}
                <b>
                  NGÀY {String(day).padStart(2, "0")} ·{" "}
                  {missed ? "KHUNG TRỐNG" : label}
                </b>
                {missed && (
                  <small>ngày này chưa có ảnh. cuộn vẫn quay tiếp.</small>
                )}
                {store.offline && index === 0 && (
                  <em>
                    <OIcon name="clock" size={13} weight="bold" /> CHỜ GỬI
                  </em>
                )}
              </button>
            )
          })}
          {(store.readOnly || journey.archived) && (
            <div className="memory-thread-bow">
              <OIcon name="type-custom" size={24} active />
            </div>
          )}
        </section>
        <div className="memory-home-actions">
          <button onClick={() => navigate(`/j/${journey.id}/squad`)}>
            <OIcon name="squad" size={18} weight="bold" /> Hội hôm nay
          </button>
          <button onClick={() => navigate(`/j/${journey.id}/share`)}>
            <OIcon name="share" size={18} weight="bold" /> Tạo poster
          </button>
        </div>
      </main>
    </ScreenShell>
  )
}

function MemoryPost({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const [caption, setCaption] = useState(journey.lastCaption ?? "")
  const [place, setPlace] = useState(journey.lastPlace ?? journey.name)
  function submit() {
    if (store.readOnly) return
    const result = store.checkInJourney(journey.id, {
      caption,
      mood: "",
      place,
    })
    if (!result.first) {
      store.showToast(`Đã thêm ảnh thứ ${result.count} hôm nay`)
      navigate(`/j/${journey.id}/camera`, { replace: true })
      return
    }
    if (!store.notificationPromptHandled) {
      store.setNotificationSheetOpen(true)
    }
    navigate(`/j/${journey.id}/done`, { replace: true })
  }
  return (
    <section className="memory-journey-page memory-post">
      <MemoryTopBar
        journey={journey}
        onBack={() => navigate(`/j/${journey.id}/camera`)}
      />
      <div className="memory-page-scroll">
        <div className="memory-post-photo">
          <MemoryPhoto scene={3} />
        </div>
        <h1>Hôm nay cả bọn lạc ở đâu?</h1>
        <label className="memory-place-field">
          <OIcon name="map-pin" size={19} weight="fill" />
          <input
            value={place}
            onChange={(event) => setPlace(event.target.value)}
            aria-label="Địa điểm"
          />
        </label>
        <label className="memory-caption-field">
          <span>Ghi lại một dòng</span>
          <textarea
            maxLength={140}
            value={caption}
            onChange={(event) => setCaption(event.target.value)}
            placeholder="Hôm nay có chuyện gì đáng nhớ?"
          />
          <small>{caption.length}/140</small>
        </label>
        <ComposeJourneyTargets journey={journey} />
        <button className="memory-post-primary" onClick={submit}>
          {journey.todayDone ? "Thêm vào cuộn" : "Dán vào sổ"}
        </button>
        <button
          className="memory-retake"
          onClick={() =>
            navigate(
              journey.todayDone
                ? `/j/${journey.id}`
                : `/j/${journey.id}/camera`,
            )
          }
        >
          {journey.todayDone ? "Bỏ ảnh này" : "chụp lại"}
        </button>
      </div>
    </section>
  )
}

function MemoryDone({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const frames = journey.frameCount ?? journeyPhotoCount(journey)
  const totalDays = journeyLength(journey)
  const day = Math.max(1, journey.day - 1)
  const milestone = day === 7 || frames === 24
  useEffect(() => {
    if (store.notificationSheetOpen) return
    const timer = window.setTimeout(
      () => navigate(`/j/${journey.id}`, { replace: true }),
      store.reduceMotion ? 150 : 1800,
    )
    return () => window.clearTimeout(timer)
  }, [store.notificationSheetOpen, store.reduceMotion, journey.id])
  return (
    <section
      className={`memory-journey-page memory-done ${
        milestone ? "milestone" : ""
      }`}
      onClick={() => {
        if (!store.notificationSheetOpen) {
          navigate(`/j/${journey.id}`, { replace: true })
        }
      }}
    >
      {milestone && (
        <div className="memory-film-confetti">
          {Array.from({ length: 6 }, (_, index) => (
            <OIcon name="star" size={15} active key={index} />
          ))}
        </div>
      )}
      <div className="memory-developing-photo">
        <span className="memory-tape" />
        <MemoryPhoto scene={3} />
      </div>
      <div className="memory-done-stamp">
        ĐÃ DÁN · KHUNG {frames}/{totalDays}
      </div>
      <h1>
        {frames === totalDays
          ? "Hết cuộn rồi đó."
          : day === 7
            ? "Tuần đầu trên đường"
            : `tấm thứ ${frames} rồi đó.`}
      </h1>
      {milestone && (
        <button
          onClick={(event) => {
            event.stopPropagation()
            navigate(`/j/${journey.id}/share`)
          }}
        >
          Tạo poster
        </button>
      )}
      {store.notificationSheetOpen && (
        <PermissionSheet
          kind="notification"
          onClose={() => {
            store.setNotificationPromptHandled(true)
            store.setNotificationSheetOpen(false)
          }}
          onConfirm={() => {
            store.setNotificationPromptHandled(true)
            store.setNotificationSheetOpen(false)
          }}
        />
      )}
    </section>
  )
}

function MemorySquad({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const [reminded, setReminded] = useState(false)
  const [toast, setToast] = useState("")
  const [reaction, setReaction] = useState<Record<string, string>>({})
  const members = ["AN", "LINH", "MINH", "NAM"].filter(
    (name) => !store.blocked.includes(name === "MINH" ? "Minh" : name),
  )
  const reactions = reactionOptions
  return (
    <ScreenShell bare className="memory-journey-screen">
      <MemoryTopBar journey={journey} onBack={() => navigate(-1)} />
      <main className="memory-squad">
        {store.offline && (
          <div className="memory-offline-strip">
            <OIcon name="cloud-off" size={17} weight="bold" />
            Đang lưu trên máy. Có mạng sẽ tự gửi.
          </div>
        )}
        {(store.readOnly || journey.archived) && (
          <div className="memory-closed">
            <span>ĐÃ ĐÓNG SỔ</span>
          </div>
        )}
        <h1>HÔM NAY · 4/5 ĐÃ CÓ KHUNG</h1>
        <div className="memory-film-strip">
          {members.map((name, index) => (
            <article key={name}>
              <button
                className="card-open-hit"
                aria-label={`Mở khung hình của ${name}`}
                onClick={() => navigate(`/j/${journey.id}/day/${index + 1}`)}
              />
              <span className="memory-sprockets" />
              <MemoryPhoto scene={index} />
              <b>
                {name} · 07:{42 + index}
              </b>
              <div className="memory-reactions">
                {reactions.map((item) => (
                  <button
                    key={item.id}
                    className={reaction[name] === item.id ? "selected" : ""}
                    disabled={store.readOnly}
                    aria-pressed={reaction[name] === item.id}
                    aria-label={item.label}
                    onClick={(event) => {
                      event.stopPropagation()
                      setReaction((current) => ({
                        ...current,
                        [name]: current[name] === item.id ? "" : item.id,
                      }))
                    }}
                  >
                    <OIcon name={item.icon} size={20} active />
                  </button>
                ))}
              </div>
            </article>
          ))}
          <article className="memory-missing-frame">
            <span className="memory-sprockets" />
            <span className="memory-empty-frame" />
            <b>HÀ · CHƯA CÓ KHUNG</b>
            <button
              disabled={store.offline || store.readOnly || reminded}
              onClick={() => {
                setReminded(true)
                setToast("Đã nhắc Hà.")
                window.setTimeout(() => setToast(""), 1800)
              }}
            >
              {store.readOnly
                ? "Đã khép lại"
                : store.offline
                  ? "Cần mạng"
                  : reminded
                    ? "Đã nhắc Hà"
                    : "Nhắc Hà"}
            </button>
          </article>
        </div>
      </main>
      {toast && <div className="memory-toast">{toast}</div>}
    </ScreenShell>
  )
}

function MemoryShare({ journey }: { journey: Journey }) {
  const navigate = useNavigate()
  const [ratio, setRatio] = useState<"story" | "feed">("story")
  const [shareOpen, setShareOpen] = useState(false)
  const [hideBrand, setHideBrand] = useState(false)
  const journeyDays = journeyLength(journey)
  const total = Math.min(ratio === "story" ? 24 : 20, journeyDays)
  const shot = journey.frameCount ?? journeyPhotoCount(journey)
  const posterTitle = `${journeyDays} NGÀY · ${journey.name}`.toLocaleUpperCase(
    "vi",
  )
  return (
    <section className="memory-journey-page memory-share">
      <MemoryTopBar journey={journey} onBack={() => navigate(-1)} />
      <div className="memory-page-scroll">
        <h1>{posterTitle}</h1>
        <div className="memory-share-tabs">
          <button
            className={ratio === "story" ? "selected" : ""}
            onClick={() => setRatio("story")}
          >
            9:16
          </button>
          <button
            className={ratio === "feed" ? "selected" : ""}
            onClick={() => setRatio("feed")}
          >
            4:5
          </button>
        </div>
        <div className={`memory-contact-poster ${ratio}`}>
          <h2>{posterTitle}</h2>
          <div className="memory-contact-sheet">
            {Array.from({ length: total }, (_, index) => (
              <span className={index < shot ? "shot" : ""} key={index}>
                {index < shot ? <MemoryPhoto scene={index} /> : null}
                <b>{String(index + 1).padStart(2, "0")}</b>
              </span>
            ))}
          </div>
          {!hideBrand && <Wordmark size={56} className="share-brand" />}
        </div>
        <button
          className="memory-share-button"
          onClick={() => setShareOpen(true)}
        >
          <OIcon name="share" size={19} weight="bold" />
          Chia sẻ poster chuyến đi
        </button>
      </div>
      {shareOpen && (
        <PosterShareSheet
          skin="memory"
          title="chia sẻ poster chuyến đi."
          onClose={() => setShareOpen(false)}
          hideBrand={hideBrand}
          onToggleBrand={() => setHideBrand(!hideBrand)}
        />
      )}
    </section>
  )
}

function CoupleTopBar({
  journey,
  onBack,
  gear = false,
  showTitle = true,
}: {
  journey: Journey
  onBack?: () => void
  gear?: boolean
  showTitle?: boolean
}) {
  const navigate = useNavigate()
  return (
    <header className="couple-topbar">
      <button
        onClick={onBack ?? (() => navigate("/hub"))}
        aria-label="Quay lại"
      >
        <OIcon name="back" size={21} weight="bold" />
      </button>
      <b>{showTitle ? journey.name.toLocaleUpperCase("vi") : "NAM · LINH"}</b>
      {gear ? (
        <button
          onClick={() => navigate(`/j/${journey.id}/edit`)}
          aria-label="Cài đặt hành trình"
        >
          <OIcon name="settings" size={21} weight="bold" />
        </button>
      ) : (
        <span />
      )}
    </header>
  )
}

function CouplePhoto({
  person,
  scene = 0,
}: {
  person: "Nam" | "Linh"
  scene?: number
}) {
  return (
    <div
      className={`couple-photo-placeholder couple-photo-${person.toLowerCase()} couple-dish-${scene % 4}`}
    >
      <span />
      <i />
    </div>
  )
}

function CouplePair({
  journey,
  day,
  waiting = false,
  missed = false,
  onClick,
}: {
  journey: Journey
  day: number
  waiting?: boolean
  missed?: boolean
  onClick: () => void
}) {
  const photoCount = journeyDayEntry(journey, day)?.photos.length ?? 0
  return (
    <button
      className={`couple-pair ${waiting ? "waiting" : ""} ${
        missed ? "missed" : ""
      }`}
      onClick={onClick}
    >
      <small>
        NGÀY {String(day).padStart(2, "0")} ·{" "}
        {day === 18 ? (
          "HÔM NAY"
        ) : day === 14 ? (
          <>
            <OIcon name="star" size={14} active /> NỬA CHẶNG
          </>
        ) : (
          ""
        )}
      </small>
      {photoCount > 1 && (
        <b className="couple-photo-count" aria-label={`${photoCount} ảnh`}>
          +{photoCount - 1}
        </b>
      )}
      <div className="couple-half couple-left-half">
        {missed ? (
          <span className="couple-dashed-half" />
        ) : (
          <CouplePhoto person="Nam" scene={day} />
        )}
        <b>Nam</b>
        <em>bữa sáng của Nam</em>
      </div>
      <span className="couple-axis-node">
        <OIcon name="heart" size={18} weight={missed ? "regular" : "fill"} />
      </span>
      <div className="couple-half couple-right-half">
        {waiting || missed ? (
          <span className="couple-dashed-half">
            {missed ? "cả hai đều nghỉ" : "đang chờ Linh"}
          </span>
        ) : (
          <CouplePhoto person="Linh" scene={day + 1} />
        )}
        <b>Linh</b>
        {!waiting && !missed && <em>bữa tối của Linh</em>}
      </div>
      {missed && <p>NGÀY 9 · CẢ HAI ĐỀU NGHỈ · mai mình gặp lại nhé.</p>}
    </button>
  )
}

function CoupleJourneyHome({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  return (
    <ScreenShell bare className="couple-journey-screen">
      <CoupleTopBar journey={journey} gear showTitle={false} />
      <main className="couple-home">
        {store.offline && (
          <div className="couple-offline-banner">
            <OIcon name="cloud-off" size={17} weight="bold" />
            Đang lưu trên máy. Có mạng sẽ tự gửi.
          </div>
        )}
        {(store.readOnly || journey.archived) && (
          <div className="couple-finished">
            <span>
              <OIcon name="heart" size={16} weight="fill" /> Hai đứa đã về đích{" "}
              <OIcon name="heart" size={16} weight="fill" />
            </span>
            <button onClick={() => navigate(`/j/${journey.id}/wrapped`)}>
              Xem tổng kết
            </button>
          </div>
        )}
        <h1 className="icon-text">
          30 NGÀY NẤU CHO NHAU · <OIcon name="flame" size={20} active />{" "}
          {journey.streak}
        </h1>
        <div className="couple-timeline">
          <CouplePair
            journey={journey}
            day={journeyDisplayDay(journey)}
            waiting={!journey.pairComplete}
            onClick={() =>
              navigate(
                journey.pairComplete
                  ? `/j/${journey.id}/day/${journey.day}`
                  : `/j/${journey.id}/camera`,
              )
            }
          />
          <CouplePair
            journey={journey}
            day={14}
            onClick={() => navigate(`/j/${journey.id}/day/14`)}
          />
          {store.missedDay && (
            <CouplePair
              journey={journey}
              day={9}
              missed
              onClick={() => navigate(`/j/${journey.id}/day/9`)}
            />
          )}
          <CouplePair
            journey={journey}
            day={1}
            onClick={() => navigate(`/j/${journey.id}/day/1`)}
          />
          <span className="couple-start-label">NGÀY 01 · BẮT ĐẦU</span>
        </div>
        <div className="couple-home-actions">
          <button onClick={() => navigate(`/j/${journey.id}/squad`)}>
            <OIcon name="squad" size={18} weight="bold" /> Hôm nay của hai đứa
          </button>
          <button onClick={() => navigate(`/j/${journey.id}/share`)}>
            <OIcon name="share" size={18} weight="bold" /> Tạo thiệp
          </button>
        </div>
      </main>
    </ScreenShell>
  )
}

function CouplePost({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const [dish, setDish] = useState(journey.lastDish ?? "")
  const [cook, setCook] = useState(journey.lastCook ?? "Linh")
  const [hearts, setHearts] = useState(journey.lastHearts ?? 3)
  const [caption, setCaption] = useState(journey.lastCaption ?? "")
  function submit() {
    if (store.readOnly) return
    const result = store.checkInJourney(journey.id, {
      caption,
      mood: "",
      dish,
      cook,
      hearts,
      person: "Linh",
    })
    if (!result.first) {
      store.showToast(`Đã thêm ảnh thứ ${result.count} hôm nay`)
      navigate(`/j/${journey.id}/camera`, { replace: true })
      return
    }
    if (!store.notificationPromptHandled) {
      store.setNotificationSheetOpen(true)
    }
    navigate(`/j/${journey.id}/done`, { replace: true })
  }
  return (
    <section className="couple-journey-page couple-post">
      <CoupleTopBar
        journey={journey}
        onBack={() => navigate(`/j/${journey.id}/camera`)}
      />
      <div className="couple-page-scroll">
        <div className="couple-post-diptych">
          {journey.partnerShot ? (
            <CouplePhoto person="Nam" />
          ) : (
            <span className="couple-dashed-half">đang chờ Nam</span>
          )}
          <CouplePhoto person="Linh" />
        </div>
        <h1>Hôm nay hai đứa nấu gì?</h1>
        <label className="couple-field">
          <span>Món hôm nay</span>
          <input
            value={dish}
            onChange={(event) => setDish(event.target.value)}
            placeholder="Để trống cũng được"
          />
        </label>
        <div className="couple-cook-chips">
          <span>Ai nấu?</span>
          {["Nam", "Linh"].map((name) => (
            <button
              key={name}
              className={cook === name ? "selected" : ""}
              onClick={() => setCook(name)}
            >
              {cook === name && <OIcon name="check" size={14} weight="bold" />}
              {name}
            </button>
          ))}
        </div>
        <div className="couple-heart-rating">
          <span>Bữa này mấy tim?</span>
          <div>
            {[1, 2, 3, 4, 5].map((value) => (
              <button
                key={value}
                onClick={() => setHearts(value)}
                aria-label={`${value} tim`}
                aria-pressed={value <= hearts}
              >
                <OIcon
                  name="heart"
                  size={24}
                  weight={value <= hearts ? "fill" : "regular"}
                />
              </button>
            ))}
          </div>
        </div>
        <label className="couple-caption">
          <span>Ghi lại một dòng</span>
          <textarea
            maxLength={140}
            value={caption}
            onChange={(event) => setCaption(event.target.value)}
            placeholder="Hôm nay hai đứa thấy sao?"
          />
          <small>{caption.length}/140</small>
        </label>
        <ComposeJourneyTargets journey={journey} />
        <button className="couple-post-primary" onClick={submit}>
          {journey.todayDone
            ? "Thêm ảnh"
            : journey.partnerShot
              ? "Gửi cho cả hai"
              : "Gửi nửa của mình"}
        </button>
        {!journey.partnerShot && <p>đang chờ Nam</p>}
        <button
          className="couple-retake"
          onClick={() =>
            navigate(
              journey.todayDone
                ? `/j/${journey.id}`
                : `/j/${journey.id}/camera`,
            )
          }
        >
          {journey.todayDone ? "Bỏ ảnh này" : "chụp lại"}
        </button>
      </div>
    </section>
  )
}

function CoupleDone({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const day = Math.max(1, journey.day - 1)
  const complete = Boolean(journey.pairComplete)
  const milestone = day === 7 || day === 30
  useEffect(() => {
    if (store.notificationSheetOpen) return
    const timer = window.setTimeout(
      () => navigate(`/j/${journey.id}`, { replace: true }),
      store.reduceMotion ? 150 : 1800,
    )
    return () => window.clearTimeout(timer)
  }, [store.notificationSheetOpen, store.reduceMotion, journey.id])
  return (
    <section
      className={`couple-journey-page couple-done ${
        milestone ? "milestone" : ""
      }`}
      onClick={() => {
        if (!store.notificationSheetOpen) {
          navigate(`/j/${journey.id}`, { replace: true })
        }
      }}
    >
      {milestone && (
        <div className="couple-petals">
          {Array.from({ length: 5 }, (_, index) => (
            <OIcon name="heart" size={18} active key={index} />
          ))}
        </div>
      )}
      <div className="couple-click-halves">
        <CouplePhoto person="Nam" />
        <CouplePhoto person="Linh" />
      </div>
      <div className="couple-heart-seal">
        <OIcon name="heart" size={42} weight="fill" />
      </div>
      <h1>
        Ngày {day} · {complete ? "đủ đôi" : "đang chờ Nam"}
      </h1>
      <p>
        {milestone
          ? day === 30
            ? "Tròn 30 ngày"
            : "Tuần đầu bên nhau"
          : complete
            ? "đủ đôi rồi nè."
            : "nửa của bạn đã được gửi."}
      </p>
      {milestone && (
        <button
          onClick={(event) => {
            event.stopPropagation()
            navigate(`/j/${journey.id}/share`)
          }}
        >
          Tạo thiệp
        </button>
      )}
      {store.notificationSheetOpen && (
        <PermissionSheet
          kind="notification"
          onClose={() => {
            store.setNotificationPromptHandled(true)
            store.setNotificationSheetOpen(false)
          }}
          onConfirm={() => {
            store.setNotificationPromptHandled(true)
            store.setNotificationSheetOpen(false)
          }}
        />
      )}
    </section>
  )
}

function CoupleSquad({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const [reminded, setReminded] = useState(false)
  const [toast, setToast] = useState("")
  const [reaction, setReaction] = useState("")
  const todayPhotos = journeyTodayEntry(journey)?.photos ?? []
  const namPhotos = todayPhotos.filter((photo) => photo.person === "Nam")
  const linhPhotos = todayPhotos.filter((photo) => photo.person === "Linh")
  return (
    <ScreenShell bare className="couple-journey-screen">
      <CoupleTopBar journey={journey} onBack={() => navigate(-1)} />
      <main className="couple-today">
        {store.offline && (
          <div className="couple-offline-banner">
            <OIcon name="cloud-off" size={17} weight="bold" />
            Đang lưu trên máy. Có mạng sẽ tự gửi.
          </div>
        )}
        {(store.readOnly || journey.archived) && (
          <div className="couple-finished">
            <span>Hai đứa đã về đích</span>
          </div>
        )}
        <h1>Hôm nay của hai đứa</h1>
        <div className="couple-today-halves">
          <article>
            {store.offline ? (
              <span className="couple-offline-skeleton">
                ảnh của Nam chưa tải được
              </span>
            ) : (
              <div className="couple-member-photos">
                {(namPhotos.length ? namPhotos : [null]).map((photo, index) => (
                  <span key={photo?.id ?? "nam-fallback"}>
                    <CouplePhoto person="Nam" scene={index} />
                    <small>{photo?.time ?? "07:30"}</small>
                  </span>
                ))}
              </div>
            )}
            <b>Nam · đã chụp 07:30</b>
            <div>
              {reactionOptions.map((item) => (
                <button
                  key={item.id}
                  className={reaction === item.id ? "selected" : ""}
                  disabled={store.readOnly}
                  aria-label={item.label}
                  onClick={() =>
                    setReaction(reaction === item.id ? "" : item.id)
                  }
                >
                  <OIcon name={item.icon} size={20} active />
                </button>
              ))}
            </div>
          </article>
          <article className={journey.ownShot ? "" : "waiting"}>
            {journey.ownShot ? (
              <>
                <div className="couple-member-photos">
                  {(linhPhotos.length ? linhPhotos : [null]).map(
                    (photo, index) => (
                      <span key={photo?.id ?? "linh-fallback"}>
                        <CouplePhoto person="Linh" scene={index + 1} />
                        <small>{photo?.time ?? "07:42"}</small>
                      </span>
                    ),
                  )}
                </div>
                <b>Linh · đã chụp</b>
                {store.offline && (
                  <span className="couple-waiting-sync">
                    <OIcon name="clock" size={13} weight="bold" /> CHỜ GỬI · đã
                    lưu trên máy
                  </span>
                )}
              </>
            ) : (
              <>
                <span className="couple-dashed-half">chưa chụp</span>
                <b>Linh · chưa chụp</b>
                <button
                  disabled={store.offline || store.readOnly || reminded}
                  onClick={() => {
                    setReminded(true)
                    setToast("Đã nhắc Linh.")
                    window.setTimeout(() => setToast(""), 1800)
                  }}
                >
                  {store.readOnly
                    ? "Đã khép lại"
                    : store.offline
                      ? "Cần mạng"
                      : reminded
                        ? "Đã nhắc Linh"
                        : "Nhắc Linh"}
                </button>
              </>
            )}
          </article>
        </div>
        <p className="couple-streak icon-text">
          <OIcon name="flame" size={18} active /> {journey.streak} ngày bên nhau
        </p>
      </main>
      {toast && <div className="couple-toast">{toast}</div>}
    </ScreenShell>
  )
}

function CoupleShare({ journey }: { journey: Journey }) {
  const navigate = useNavigate()
  const [ratio, setRatio] = useState<"story" | "feed">("story")
  const [shareOpen, setShareOpen] = useState(false)
  const [hideBrand, setHideBrand] = useState(false)
  const total = ratio === "story" ? 36 : 16
  return (
    <section className="couple-journey-page couple-share">
      <CoupleTopBar journey={journey} onBack={() => navigate(-1)} />
      <div className="couple-page-scroll">
        <h1>18 NGÀY BÊN NHAU · 36 KHOẢNH KHẮC</h1>
        <div className="couple-share-tabs">
          <button
            className={ratio === "story" ? "selected" : ""}
            onClick={() => setRatio("story")}
          >
            9:16
          </button>
          <button
            className={ratio === "feed" ? "selected" : ""}
            onClick={() => setRatio("feed")}
          >
            4:5
          </button>
        </div>
        <div className={`couple-share-card ${ratio}`}>
          <h2>18 NGÀY BÊN NHAU · 36 KHOẢNH KHẮC</h2>
          <div>
            {Array.from({ length: total }, (_, index) => (
              <CouplePhoto person={index % 2 ? "Linh" : "Nam"} key={index} />
            ))}
          </div>
          {!hideBrand && <Wordmark size={56} className="share-brand" />}
        </div>
        <button
          className="couple-share-button"
          onClick={() => setShareOpen(true)}
        >
          <OIcon name="share" size={19} weight="bold" />
          Chia sẻ câu chuyện của mình
        </button>
      </div>
      {shareOpen && (
        <PosterShareSheet
          skin="couple"
          title="chia sẻ câu chuyện."
          onClose={() => setShareOpen(false)}
          hideBrand={hideBrand}
          onToggleBrand={() => setHideBrand(!hideBrand)}
        />
      )}
    </section>
  )
}

function FlexerTopBar({
  journey,
  onBack,
  gear = false,
}: {
  journey: Journey
  onBack?: () => void
  gear?: boolean
}) {
  const navigate = useNavigate()
  return (
    <header className="flexer-topbar">
      <button
        onClick={onBack ?? (() => navigate("/hub"))}
        aria-label="Quay lại"
      >
        <OIcon name="back" size={21} weight="bold" />
      </button>
      <b>CHẠY SÁNG · NGÀY {journey.day}/30</b>
      {gear ? (
        <button
          onClick={() => navigate(`/j/${journey.id}/edit`)}
          aria-label="Cài đặt hành trình"
        >
          <OIcon name="settings" size={21} weight="bold" />
        </button>
      ) : (
        <span />
      )}
    </header>
  )
}

function FlexerPhoto({ index = 0 }: { index?: number }) {
  const scenes = ["đường sớm", "đường chạy", "công viên", "cây cầu", "mưa"]
  return (
    <div
      className={`flexer-photo flexer-photo-${index % 5}`}
      role="img"
      aria-label={`Cảnh ${scenes[index % 5]}`}
    >
      <span />
      <i />
    </div>
  )
}

function FlexerJourneyHome({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const formatKm = (value: number) =>
    new Intl.NumberFormat("vi-VN", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(value)
  const rows = [
    [journeyDisplayDay(journey), "HÔM NAY", journey.lastKm ?? 5.42],
    [14, "CỘT MỐC · NỬA CHẶNG", 5.18],
    [9, store.missedDay ? "NGHỈ" : "CHẠY NHẸ", 0],
    [7, "CỘT MỐC · TUẦN ĐẦU", 5.0],
    [1, "BẮT ĐẦU", 5.0],
  ] as const
  return (
    <ScreenShell bare className="flexer-journey-screen">
      <FlexerTopBar journey={journey} gear />
      <main className="flexer-home">
        {(store.readOnly || journey.archived) && (
          <button
            className="flexer-readonly"
            onClick={() => navigate(`/j/${journey.id}/wrapped`)}
          >
            <OIcon name="lock" size={17} weight="bold" /> ĐÃ VỀ ĐÍCH · CHỈ ĐỌC
          </button>
        )}
        <button
          className="flexer-attendance-chip"
          onClick={() => navigate(`/j/${journey.id}/squad`)}
        >
          3/4 ĐÃ CHẠY
        </button>
        <section className="flexer-summary">
          <svg viewBox="0 0 320 90" aria-label="Nhịp chạy">
            <path d="M4 72 L36 61 L66 67 L99 39 L128 52 L158 22 L191 35 L224 13 L256 29 L286 10 L316 18" />
          </svg>
          <p>
            {(journey.totalKm ?? 92.4).toFixed(1).replace(".", ",")} KM TỔNG ·{" "}
            {journey.pace ?? "5:04"} /KM NHỊP TB
          </p>
        </section>
        <section className="flexer-axis">
          {rows.map(([day, label, km], index) => {
            const missed = store.missedDay && day === 9
            return (
              <button
                key={`${day}-${label}`}
                className={`${index === 0 ? "today" : ""} ${
                  missed ? "missed" : ""
                }`}
                onClick={() =>
                  navigate(
                    index === 0
                      ? `/j/${journey.id}/camera`
                      : `/j/${journey.id}/day/${day}`,
                  )
                }
              >
                <DayPhotoStack journey={journey} day={day}>
                  <FlexerPhoto index={index} />
                </DayPhotoStack>
                <span className="flexer-node">
                  {String(label).includes("CỘT MỐC") && (
                    <OIcon name="star" size={16} weight="fill" />
                  )}
                </span>
                <span>
                  <small>
                    NGÀY {day} · {label}
                  </small>
                  {index === 0 ? (
                    <b>
                      {formatKm(Number(km))} <em>KM</em>
                    </b>
                  ) : (
                    <strong>
                      {missed ? "CHỜ LẦN TỚI" : `${formatKm(Number(km))} KM`}
                    </strong>
                  )}
                  {store.offline && index === 0 && (
                    <i>
                      <OIcon name="cloud-off" size={13} /> CHỜ ĐỒNG BỘ
                    </i>
                  )}
                </span>
              </button>
            )
          })}
        </section>
      </main>
    </ScreenShell>
  )
}

function FlexerPost({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const [field, setField] = useState<"km" | "pace">("km")
  const [km, setKm] = useState(String(journey.lastKm ?? 5.42).replace(".", ","))
  const [pace, setPace] = useState(journey.pace ?? "5:04")
  const [caption, setCaption] = useState(journey.lastCaption ?? "")
  function typeKey(key: string) {
    if (field === "km") {
      setKm((current) =>
        key === "BACKSPACE"
          ? current.slice(0, -1)
          : `${current}${key}`.slice(-6),
      )
    } else {
      setPace((current) =>
        key === "BACKSPACE"
          ? current.slice(0, -1)
          : `${current}${key}`.slice(-5),
      )
    }
  }
  function submit() {
    const result = store.checkInJourney(journey.id, {
      caption,
      mood: "",
      km: Number(km.replace(",", ".")) || 5.42,
      pace: pace || "5:04",
    })
    if (!result.first) {
      store.showToast(`Đã thêm ảnh thứ ${result.count} hôm nay`)
      navigate(`/j/${journey.id}/camera`, { replace: true })
      return
    }
    navigate(`/j/${journey.id}/done`, { replace: true })
  }
  return (
    <section className="flexer-journey-page flexer-post">
      <FlexerTopBar
        journey={journey}
        onBack={() => navigate(`/j/${journey.id}/camera`)}
      />
      <div className="flexer-page-scroll">
        <FlexerPhoto index={1} />
        <div className="flexer-metrics">
          <button
            className={field === "km" ? "selected" : ""}
            onClick={() => setField("km")}
          >
            <b>{km || "0"}</b> <span>KM</span>
          </button>
          <button
            className={field === "pace" ? "selected" : ""}
            onClick={() => setField("pace")}
          >
            <b>{pace || "0:00"}</b> <span>/KM</span>
          </button>
        </div>
        <div className="flexer-keypad">
          {[
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
            "7",
            "8",
            "9",
            ",",
            "0",
            "BACKSPACE",
          ].map((key) => (
            <button key={key} onClick={() => typeKey(key)}>
              {key === "BACKSPACE" ? <OIcon name="back" size={18} /> : key}
            </button>
          ))}
        </div>
        <label className="flexer-caption">
          <span>Hôm nay chạy thế nào?</span>
          <textarea
            maxLength={140}
            value={caption}
            onChange={(event) => setCaption(event.target.value)}
          />
          <small>{caption.length}/140</small>
        </label>
        <ComposeJourneyTargets journey={journey} />
        <button className="flexer-primary" onClick={submit}>
          {journey.todayDone ? "Thêm ảnh" : "Đăng"}
        </button>
        {journey.todayDone && (
          <button
            className="flexer-keep-old"
            onClick={() => navigate(`/j/${journey.id}`)}
          >
            Bỏ ảnh này
          </button>
        )}
        {store.offline && (
          <p className="flexer-offline-note">
            Đã lưu trên máy, sẽ đồng bộ sau.
          </p>
        )}
      </div>
    </section>
  )
}

function FlexerDone({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const day = Math.max(1, journey.day - 1)
  const milestone = day === 7 || day === 30
  const [displayDay, setDisplayDay] = useState(store.reduceMotion ? day : 0)
  useEffect(() => {
    if (store.reduceMotion) {
      setDisplayDay(day)
      return
    }
    const timer = window.setInterval(
      () => {
        setDisplayDay((current) => {
          if (current >= day) {
            window.clearInterval(timer)
            return day
          }
          return current + 1
        })
      },
      Math.max(20, Math.floor(700 / day)),
    )
    return () => window.clearInterval(timer)
  }, [day, store.reduceMotion])
  useEffect(() => {
    const timer = window.setTimeout(
      () => navigate(`/j/${journey.id}`, { replace: true }),
      store.reduceMotion ? 150 : 1800,
    )
    return () => window.clearTimeout(timer)
  }, [store.reduceMotion, journey.id])
  return (
    <section
      className={`flexer-journey-page flexer-done ${
        milestone ? "milestone" : ""
      }`}
      onClick={() => navigate(`/j/${journey.id}`, { replace: true })}
    >
      {milestone && (
        <div className="flexer-confetti">
          {Array.from({ length: 7 }, (_, index) => (
            <OIcon name="star" size={15} active key={index} />
          ))}
        </div>
      )}
      <div className="flexer-pulse-ring">
        <b>{displayDay}</b>
      </div>
      <h1>
        {milestone
          ? day === 30
            ? "VỀ ĐÍCH. 30/30"
            : "TUẦN ĐẦU XONG"
          : `NGÀY ${day}. ${journey.streak} NGÀY LIỀN.`}
      </h1>
      {milestone && (
        <button
          onClick={(event) => {
            event.stopPropagation()
            navigate(`/j/${journey.id}/share`)
          }}
        >
          Tạo thiệp
        </button>
      )}
    </section>
  )
}

function FlexerSquad({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const [reaction, setReaction] = useState<Record<string, string>>({})
  const [reminded, setReminded] = useState(false)
  const [toast, setToast] = useState("")
  const members = [
    ["AN", "05:50"],
    ["LINH", "06:10"],
    ["NAM", "06:24"],
  ] as const
  return (
    <ScreenShell bare className="flexer-journey-screen">
      <FlexerTopBar journey={journey} onBack={() => navigate(-1)} />
      <main className="flexer-squad">
        <h1>3/4 ĐÃ CHẠY</h1>
        {members.map(([name, time], index) => (
          <article key={name}>
            <span className="flexer-avatar">{name.slice(0, 1)}</span>
            <div>
              <b>{name}</b>
              <small>
                <OIcon name="check" size={14} weight="bold" /> Đã chạy · {time}
              </small>
              {name === "LINH" && <em>5,42 KM · 5:04 /KM</em>}
              <div>
                {reactionOptions.map((item) => (
                  <button
                    key={item.id}
                    className={reaction[name] === item.id ? "selected" : ""}
                    aria-label={item.label}
                    onClick={() =>
                      setReaction((current) => ({
                        ...current,
                        [name]: current[name] === item.id ? "" : item.id,
                      }))
                    }
                  >
                    <OIcon name={item.icon} size={20} active />
                  </button>
                ))}
              </div>
            </div>
            <FlexerPhoto index={index} />
          </article>
        ))}
        {!store.blocked.includes("Minh") && (
          <article className="flexer-waiting">
            <span className="flexer-avatar">M</span>
            <div>
              <b>MINH</b>
              <small>CHƯA CHẠY</small>
            </div>
            <button
              disabled={store.offline || reminded}
              onClick={() => {
                setReminded(true)
                setToast("Đã nhắc Minh.")
                window.setTimeout(() => setToast(""), 1800)
              }}
            >
              {store.offline
                ? "Cần mạng"
                : reminded
                  ? "Đã nhắc Minh"
                  : "Nhắc Minh"}
            </button>
          </article>
        )}
      </main>
      {toast && <div className="flexer-toast">{toast}</div>}
    </ScreenShell>
  )
}

function FlexerShare({ journey }: { journey: Journey }) {
  const navigate = useNavigate()
  const [ratio, setRatio] = useState<"story" | "feed">("story")
  const [shareOpen, setShareOpen] = useState(false)
  const [hideBrand, setHideBrand] = useState(false)
  return (
    <section className="flexer-journey-page flexer-share">
      <FlexerTopBar journey={journey} onBack={() => navigate(-1)} />
      <div className="flexer-page-scroll">
        <div className="flexer-share-tabs">
          {[
            ["story", "9:16"],
            ["feed", "4:5"],
          ].map(([value, label]) => (
            <button
              key={value}
              className={ratio === value ? "selected" : ""}
              onClick={() => setRatio(value as "story" | "feed")}
            >
              {label}
            </button>
          ))}
        </div>
        <div className={`flexer-share-card ${ratio}`}>
          <FlexerPhoto index={2} />
          <div className="flexer-share-hud">
            <b>5,42 KM</b>
            <span>NGÀY 21 · 5:04 /KM</span>
          </div>
          <div className="flexer-bars">
            {Array.from({ length: 21 }, (_, index) => (
              <i className={index % 6 === 0 ? "weak" : ""} key={index} />
            ))}
          </div>
          <p>21 NGÀY HOẠT ĐỘNG</p>
          {!hideBrand && <Wordmark size={56} className="share-brand" />}
        </div>
        <button className="flexer-primary" onClick={() => setShareOpen(true)}>
          Chia sẻ lên Story
        </button>
      </div>
      {shareOpen && (
        <PosterShareSheet
          skin="flexer"
          title="chia sẻ thành tích."
          onClose={() => setShareOpen(false)}
          hideBrand={hideBrand}
          onToggleBrand={() => setHideBrand(!hideBrand)}
        />
      )}
    </section>
  )
}

function MinimalTopBar({
  journey,
  onBack,
  gear = false,
}: {
  journey: Journey
  onBack?: () => void
  gear?: boolean
}) {
  const navigate = useNavigate()
  return (
    <header className="minimal-topbar">
      <button
        onClick={onBack ?? (() => navigate("/hub"))}
        aria-label="Quay lại"
      >
        <OIcon name="back" size={21} />
      </button>
      <b>ĐỌC 10 TRANG</b>
      {gear ? (
        <button
          onClick={() => navigate(`/j/${journey.id}/edit`)}
          aria-label="Cài đặt hành trình"
        >
          <OIcon name="settings" size={21} />
        </button>
      ) : (
        <span />
      )}
    </header>
  )
}

function MinimalPhoto({ index = 0 }: { index?: number }) {
  return (
    <div
      className={`minimal-photo minimal-photo-${index % 4}`}
      style={
        {
          "--minimal-day-photo": `hsl(${(index * 29) % 360} 18% 78%)`,
        } as CSSProperties
      }
    >
      <span />
      <i />
    </div>
  )
}

function MinimalJourneyHome({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const streak = store.missedDay ? 15 : journey.streak
  const days = Array.from({ length: 30 }, (_, index) => index + 1)
  const calendarRef = useRef<HTMLElement | null>(null)
  const [chainRuns, setChainRuns] = useState<string[]>([])
  const [chainSize, setChainSize] = useState({ width: 0, height: 0 })
  useLayoutEffect(() => {
    const calendar = calendarRef.current
    if (!calendar) return
    const measure = () => {
      const wrapper = calendar.getBoundingClientRect()
      const cells = Array.from(
        calendar.querySelectorAll<HTMLButtonElement>(
          "button.done:not(.missed)[data-day]",
        ),
      )
        .map((cell) => {
          const rect = cell.getBoundingClientRect()
          return {
            day: Number(cell.dataset.day),
            x: rect.left - wrapper.left + rect.width / 2,
            y: rect.top - wrapper.top + rect.height / 2,
          }
        })
        .sort((a, b) => a.day - b.day)
      const runs: typeof cells[] = []
      cells.forEach((cell) => {
        const run = runs[runs.length - 1]
        if (!run || cell.day !== run[run.length - 1].day + 1) {
          runs.push([cell])
        } else {
          run.push(cell)
        }
      })
      setChainRuns(
        runs.map((run) => {
          const points: string[] = []
          run.forEach((cell, index) => {
            const previous = run[index - 1]
            if (previous && Math.abs(previous.y - cell.y) > 2) {
              const middleY = (previous.y + cell.y) / 2
              points.push(
                `${wrapper.width + 5},${previous.y}`,
                `${wrapper.width + 5},${middleY}`,
                `-5,${middleY}`,
                `-5,${cell.y}`,
              )
            }
            points.push(`${cell.x},${cell.y}`)
          })
          return points.join(" ")
        }),
      )
      setChainSize({ width: wrapper.width, height: wrapper.height })
    }
    measure()
    const observer = new ResizeObserver(measure)
    observer.observe(calendar)
    window.addEventListener("resize", measure)
    return () => {
      observer.disconnect()
      window.removeEventListener("resize", measure)
    }
  }, [journey.day, store.missedDay])
  return (
    <ScreenShell bare className="minimal-journey-screen">
      <MinimalTopBar journey={journey} gear />
      <main className="minimal-home">
        {(store.readOnly || journey.archived) && (
          <button
            className="minimal-readonly"
            onClick={() => navigate(`/j/${journey.id}/wrapped`)}
          >
            <OIcon name="lock" size={16} /> ĐÃ KẾT THÚC · CHỈ ĐỌC
          </button>
        )}
        <div className="minimal-month-header icon-text">
          <span />
          THÁNG 10 · CHUỖI <StreakValue count={streak} suffix="NGÀY" />
        </div>
        <button
          className="minimal-attendance-chip"
          onClick={() => navigate(`/j/${journey.id}/squad`)}
        >
          3/4 ĐÃ XONG
        </button>
        <div className="minimal-weekdays">
          {["T2", "T3", "T4", "T5", "T6", "T7", "CN"].map((day) => (
            <span key={day}>{day}</span>
          ))}
        </div>
        <section
          ref={calendarRef}
          className={`minimal-calendar ${store.missedDay ? "has-gap" : ""}`}
        >
          <svg
            width={chainSize.width}
            height={chainSize.height}
            viewBox={`0 0 ${chainSize.width} ${chainSize.height}`}
            aria-hidden="true"
          >
            {chainRuns.map((points, index) => (
              <polyline key={`${index}-${points}`} points={points} />
            ))}
          </svg>
          {[0, 1, 2].map((blank) => (
            <span className="minimal-blank" key={`blank-${blank}`} />
          ))}
          {days.map((day) => {
            const future = day > journey.day
            const missed = store.missedDay && day === 9
            return (
              <button
                key={day}
                data-day={day}
                className={`${future ? "future" : "done"} ${
                  day === journey.day ? "today" : ""
                } ${missed ? "missed" : ""}`}
                onClick={() =>
                  navigate(
                    day === journey.day
                      ? `/j/${journey.id}/camera`
                      : `/j/${journey.id}/day/${day}`,
                  )
                }
              >
                <b>{day}</b>
                {future || missed ? (
                  <span />
                ) : (
                  <DayPhotoStack journey={journey} day={day}>
                    <MinimalPhoto index={day} />
                  </DayPhotoStack>
                )}
                {store.offline && day === journey.day && (
                  <i>
                    <OIcon name="clock" size={12} /> CHỜ ĐỒNG BỘ
                  </i>
                )}
              </button>
            )
          })}
        </section>
      </main>
    </ScreenShell>
  )
}

function MinimalPost({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const [count, setCount] = useState(3)
  const [stopped, setStopped] = useState(Boolean(journey.todayDone))
  const [noteOpen, setNoteOpen] = useState(false)
  const [caption, setCaption] = useState(journey.lastCaption ?? "")
  const posted = useRef(false)
  function submit() {
    if (posted.current) return
    posted.current = true
    const result = store.checkInJourney(journey.id, { caption, mood: "" })
    if (!result.first) {
      store.showToast(`Đã thêm ảnh thứ ${result.count} hôm nay`)
      navigate(`/j/${journey.id}/camera`, { replace: true })
      return
    }
    navigate(`/j/${journey.id}/done`, { replace: true })
  }
  useEffect(() => {
    if (stopped || store.reduceMotion) return
    const timer = window.setInterval(() => {
      setCount((current) => {
        if (current <= 1) {
          window.clearInterval(timer)
          window.setTimeout(submit, 0)
          return 0
        }
        return current - 1
      })
    }, 1000)
    return () => window.clearInterval(timer)
  }, [stopped, store.reduceMotion])
  return (
    <section
      className="minimal-journey-page minimal-post"
      onPointerDown={() => setStopped(true)}
    >
      <MinimalTopBar
        journey={journey}
        onBack={() => navigate(`/j/${journey.id}/camera`)}
      />
      <div className="minimal-page-scroll">
        <MinimalPhoto index={journey.day} />
        <ComposeJourneyTargets journey={journey} />
        <div className="minimal-countdown">
          {store.reduceMotion ? (
            <span>Tự đăng sau 3 giây</span>
          ) : (
            <b>{count}</b>
          )}
        </div>
        {noteOpen && (
          <label className="minimal-caption">
            <span>Ghi chú</span>
            <textarea
              maxLength={140}
              value={caption}
              onChange={(event) => setCaption(event.target.value)}
            />
            <small>{caption.length}/140</small>
          </label>
        )}
        <button className="minimal-primary" onClick={submit}>
          {journey.todayDone ? "Thêm ảnh" : "Đăng ngay"}
        </button>
        {journey.todayDone && (
          <button
            className="minimal-add-note"
            onClick={() => navigate(`/j/${journey.id}`)}
          >
            Bỏ ảnh này
          </button>
        )}
        <button className="minimal-add-note" onClick={() => setNoteOpen(true)}>
          Thêm ghi chú
        </button>
      </div>
    </section>
  )
}

function MinimalDone({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const day = Math.max(1, journey.day - 1)
  const milestone = day === 7 || day === 30
  useEffect(() => {
    const timer = window.setTimeout(
      () => navigate(`/j/${journey.id}`, { replace: true }),
      store.reduceMotion ? 150 : 1500,
    )
    return () => window.clearTimeout(timer)
  }, [store.reduceMotion, journey.id])
  return (
    <section
      className={`minimal-journey-page minimal-done ${
        milestone ? "milestone" : ""
      }`}
      onClick={() => navigate(`/j/${journey.id}`, { replace: true })}
    >
      {milestone && (
        <div className="minimal-confetti">
          {Array.from({ length: 6 }, (_, index) => (
            <OIcon name="star" size={13} active key={index} />
          ))}
        </div>
      )}
      <div className="minimal-growing-dot" />
      <h1>
        {milestone ? (day === 30 ? "ĐỦ 30 NGÀY" : "7 NGÀY LIỀN") : "XONG."}
      </h1>
      {milestone && (
        <button
          onClick={(event) => {
            event.stopPropagation()
            navigate(`/j/${journey.id}/share`)
          }}
        >
          Tạo thiệp
        </button>
      )}
    </section>
  )
}

function MinimalSquad({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const [reaction, setReaction] = useState<Record<string, string>>({})
  const [reminded, setReminded] = useState(false)
  const [toast, setToast] = useState("")
  const members = [
    ["AN", "06:03"],
    ["LINH", "06:18"],
    ["NAM", "06:29"],
  ] as const
  return (
    <ScreenShell bare className="minimal-journey-screen">
      <MinimalTopBar journey={journey} onBack={() => navigate(-1)} />
      <main className="minimal-squad">
        <h1>3/4 ĐÃ XONG</h1>
        {members.map(([name, time], index) => (
          <article key={name}>
            <span>{name.slice(0, 1)}</span>
            <div>
              <b>{name}</b>
              <small>{time}</small>
              <div>
                {reactionOptions.map((item) => (
                  <button
                    key={item.id}
                    className={reaction[name] === item.id ? "selected" : ""}
                    aria-label={item.label}
                    onClick={() =>
                      setReaction((current) => ({
                        ...current,
                        [name]: current[name] === item.id ? "" : item.id,
                      }))
                    }
                  >
                    <OIcon name={item.icon} size={20} active />
                  </button>
                ))}
              </div>
            </div>
            <MinimalPhoto index={index} />
          </article>
        ))}
        {!store.blocked.includes("Hà") && (
          <article className="minimal-pending">
            <span>H</span>
            <div>
              <b>HÀ</b>
              <small>CHƯA</small>
            </div>
            <button
              disabled={store.offline || reminded}
              onClick={() => {
                setReminded(true)
                setToast("Đã nhắc Hà.")
                window.setTimeout(() => setToast(""), 1800)
              }}
            >
              {store.offline ? "Cần mạng" : reminded ? "Đã nhắc Hà" : "Nhắc Hà"}
            </button>
          </article>
        )}
      </main>
      {toast && <div className="minimal-toast">{toast}</div>}
    </ScreenShell>
  )
}

function MinimalShare({ journey }: { journey: Journey }) {
  const navigate = useNavigate()
  const [ratio, setRatio] = useState<"story" | "feed">("story")
  const [shareOpen, setShareOpen] = useState(false)
  const [hideBrand, setHideBrand] = useState(false)
  return (
    <section className="minimal-journey-page minimal-share">
      <MinimalTopBar journey={journey} onBack={() => navigate(-1)} />
      <div className="minimal-page-scroll">
        <div className="minimal-share-tabs">
          <button
            className={ratio === "story" ? "selected" : ""}
            onClick={() => setRatio("story")}
          >
            9:16
          </button>
          <button
            className={ratio === "feed" ? "selected" : ""}
            onClick={() => setRatio("feed")}
          >
            4:5
          </button>
        </div>
        <div className={`minimal-share-card ${ratio}`}>
          <h1>
            24/30 NGÀY
            <br />
            80% ĐỀU ĐẶN
          </h1>
          <MinimalPhoto index={24} />
          {!hideBrand && <Wordmark size={56} className="share-brand" />}
        </div>
        <button className="minimal-export" onClick={() => setShareOpen(true)}>
          Xuất thẻ tối giản
        </button>
      </div>
      {shareOpen && (
        <PosterShareSheet
          skin="minimal"
          title="xuất thẻ tối giản."
          onClose={() => setShareOpen(false)}
          hideBrand={hideBrand}
          onToggleBrand={() => setHideBrand(!hideBrand)}
        />
      )}
    </section>
  )
}

function PushedHeader({
  title,
  onBack,
  action,
}: {
  title: string
  onBack?: () => void
  action?: React.ReactNode
}) {
  return (
    <header className="pushed-header">
      {onBack ? (
        <button onClick={onBack} aria-label="Quay lại">
          <OIcon name="back" size={21} weight="bold" />
        </button>
      ) : (
        <span />
      )}
      <b>{title}</b>
      {action ?? <span />}
    </header>
  )
}

function JourneyActionSheet({
  open,
  title,
  body,
  children,
  onClose,
}: {
  open: boolean
  title: string
  body?: string
  children: React.ReactNode
  onClose: () => void
}) {
  const startY = useRef(0)
  const [drag, setDrag] = useState(0)
  if (!open) return null
  return (
    <PhoneOverlay>
      <div
        className="journey-action-scrim"
        onPointerDown={(event) =>
          event.target === event.currentTarget && onClose()
        }
      >
        <div
          className="journey-action-sheet"
          role="dialog"
          aria-modal="true"
          style={{ transform: `translateY(${drag}px)` }}
        >
          <div
            className="journey-action-drag"
            onPointerDown={(event) => {
              startY.current = event.clientY
              event.currentTarget.setPointerCapture(event.pointerId)
            }}
            onPointerMove={(event) =>
              setDrag(Math.max(0, event.clientY - startY.current))
            }
            onPointerUp={() => {
              if (drag > 70) onClose()
              setDrag(0)
            }}
          >
            <i />
          </div>
          <button
            className="journey-action-close"
            onClick={onClose}
            aria-label="Đóng"
          >
            <OIcon name="close" size={21} weight="bold" />
          </button>
          <h2>{title}</h2>
          {body && <p>{body}</p>}
          {children}
        </div>
      </div>
    </PhoneOverlay>
  )
}

const skinDayCopy: Record<string, {
  label: string
  caption: string
  metric: string
}> = {
  quiet: {
    label: "NGÀY 14 · NỬA CHẶNG",
    caption: "Hôm nay mình thấy nhẹ nhõm và bình yên hơn.",
    metric: "••• kg",
  },
  squad: {
    label: "NGÀY 21 · HÔM NAY",
    caption: "Hôm nay mình đã hiểu thêm một dạng bài khó.",
    metric: "45 PHÚT",
  },
  memory: {
    label: "NGÀY 03 · ĐÊM LỬA TRẠI",
    caption: "Sương xuống rất nhanh, cả bọn vẫn ngồi kể chuyện.",
    metric: "18 THG 10 '26 · 15°C · ĐÀ LẠT",
  },
  couple: {
    label: "NGÀY 18 · ĐỦ ĐÔI",
    caption: "Một bữa tối nhỏ nhưng có đủ hai người.",
    metric: "Nam | Linh",
  },
  flexer: {
    label: "NGÀY 21 · HÔM NAY",
    caption: "TIẾP. KHÔNG DỪNG.",
    metric: "5,42 KM · 5:04 /KM",
  },
  minimal: {
    label: "NGÀY 24",
    caption: "XONG.",
    metric: "24 / 30",
  },
}

type DayVisualProps = {
  journey: Journey
  day: number
}

function DayVisual(props: DayVisualProps) {
  const { journey, day } = props
  const entry = journeyDayEntry(journey, day)
  if (entry && entry.photos.length === 0) return <DeletedDayPlaceholder />
  if (journey.skin === "quiet") return <QuietPhoto />
  if (journey.skin === "squad") return <SquadPhoto />
  if (journey.skin === "memory") return <MemoryPhoto scene={day} />
  if (journey.skin === "couple") {
    return (
      <div className="day-couple-diptych">
        <figure>
          <CouplePhoto person="Nam" scene={day} />
          <figcaption>bữa sáng của Nam</figcaption>
        </figure>
        {day % 3 === 0 ? (
          <figure>
            <span className="couple-dashed-half">đang chờ Linh</span>
            <figcaption>nửa của Linh</figcaption>
          </figure>
        ) : (
          <figure>
            <CouplePhoto person="Linh" scene={day + 1} />
            <figcaption>bữa tối của Linh</figcaption>
          </figure>
        )}
      </div>
    )
  }
  if (journey.skin === "flexer") return <FlexerPhoto index={day} />
  return <MinimalPhoto index={day} />
}

function JourneyDayScreen({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const { day = "1" } = useParams()
  const numericDay = Number(day)
  const copy = skinDayCopy[journey.skin] ?? skinDayCopy.minimal
  const dayEntry = journeyDayEntry(journey, numericDay)
  const emptyDay = Boolean(dayEntry && dayEntry.photos.length === 0)
  const coverIndex = Math.max(
    0,
    dayEntry?.photos.findIndex((photo) => photo.id === dayEntry.coverPhotoId) ??
      0,
  )
  const photos = dayEntry?.photos ?? [
    {
      id: `${journey.id}-${numericDay}-legacy`,
      time: "07:30",
      caption: copy.caption,
      mood: "",
      reactions: {},
      imported: numericDay % 4 === 0,
    },
  ]
  const [activePhoto, setActivePhoto] = useState(coverIndex)
  const currentPhoto = photos[Math.min(activePhoto, photos.length - 1)] ?? {
    id: `${journey.id}-${numericDay}-deleted`,
    time: "",
    caption: "",
    mood: "",
    reactions: {},
  }
  const reactionKey = `${journey.id}:${numericDay}:${currentPhoto.id}`
  const selectedReaction = store.reactions[reactionKey] ?? ""
  const [menuOpen, setMenuOpen] = useState(false)
  const [reportOpen, setReportOpen] = useState(false)
  const [blockOpen, setBlockOpen] = useState(false)
  const [deleteOpen, setDeleteOpen] = useState(false)
  const [reason, setReason] = useState("")
  const [hidden, setHidden] = useState(false)
  const [toast, setToast] = useState("")
  const [revealed, setRevealed] = useState(false)
  const [shareMode, setShareMode] = useState<"single" | "collage">("single")
  const reactions = reactionOptions
  return (
    <section className={`journey-pushed day-screen pushed-${journey.skin}`}>
      <PushedHeader
        title={copy.label}
        onBack={() => navigate(-1)}
        action={
          emptyDay ? (
            <span />
          ) : (
            <button
              className="day-menu-button"
              onClick={() => setMenuOpen(!menuOpen)}
              aria-label="Mở tuỳ chọn"
            >
              <OIcon name="more" size={24} weight="bold" />
            </button>
          )
        }
      />
      {menuOpen && (
        <div className="day-overflow-menu">
          {journey.shared ? (
            <>
              <button
                onClick={() => {
                  setMenuOpen(false)
                  setReportOpen(true)
                }}
              >
                Báo cáo
              </button>
              <button
                onClick={() => {
                  setMenuOpen(false)
                  setBlockOpen(true)
                }}
              >
                Chặn
              </button>
            </>
          ) : (
            <button
              onClick={() => {
                setMenuOpen(false)
                setDeleteOpen(true)
              }}
            >
              Xoá ảnh này
            </button>
          )}
        </div>
      )}
      <main className="day-content">
        <article className={`day-photo-card ${hidden ? "hidden-photo" : ""}`}>
          {hidden ? (
            <div className="day-hidden-state">
              <OIcon name="lock" size={25} />
              Ảnh đã ẩn với bạn
            </div>
          ) : emptyDay ? (
            <DeletedDayPlaceholder />
          ) : (
            <DayVisual journey={journey} day={numericDay + activePhoto} />
          )}
          {!emptyDay && currentPhoto.imported && <small>từ thư viện</small>}
        </article>
        {!emptyDay && (
          <div className="day-photo-browser">
            <button
              aria-label="Ảnh trước"
              disabled={activePhoto === 0}
              onClick={() =>
                setActivePhoto((current) => Math.max(0, current - 1))
              }
            >
              <OIcon name="back" size={18} />
            </button>
            <div className="day-photo-strip" aria-label="Ảnh trong ngày">
              {photos.map((photo, index) => (
                <button
                  key={photo.id}
                  className={activePhoto === index ? "selected" : ""}
                  onClick={() => setActivePhoto(index)}
                  aria-label={`Ảnh ${index + 1}, ${photo.time}`}
                >
                  <DayVisual journey={journey} day={numericDay + index} />
                  <span>{photo.time}</span>
                </button>
              ))}
            </div>
            <button
              aria-label="Ảnh sau"
              disabled={activePhoto >= photos.length - 1}
              onClick={() =>
                setActivePhoto((current) =>
                  Math.min(photos.length - 1, current + 1),
                )
              }
            >
              <OIcon name="caret-right" size={18} />
            </button>
          </div>
        )}
        <div className="day-copy">
          <span>
            {emptyDay
              ? `NGÀY ${numericDay} · ĐÃ ĐIỂM DANH`
              : `${copy.label} · ${currentPhoto.time}`}
          </span>
          <h1>{emptyDay ? "ảnh đã xoá" : copy.metric}</h1>
          {!emptyDay && journey.skin === "quiet" && (
            <button
              className="day-hold-weight"
              onPointerDown={() => setRevealed(true)}
              onPointerUp={() => setRevealed(false)}
              onPointerLeave={() => setRevealed(false)}
            >
              <OIcon name="eye" size={17} />
              {revealed ? "62,0 kg" : "Giữ để xem"}
            </button>
          )}
          <p>
            {emptyDay
              ? "Ngày này vẫn được tính cho chuỗi."
              : currentPhoto.caption || copy.caption}
          </p>
          {!emptyDay && currentPhoto.mood && <small>{currentPhoto.mood}</small>}
        </div>
        {!emptyDay && (
          <div className="day-reactions" aria-label="Phản ứng">
            {reactions.map((item) => (
              <button
                key={item.id}
                className={selectedReaction === item.id ? "selected" : ""}
                aria-pressed={selectedReaction === item.id}
                aria-label={item.label}
                onClick={() => {
                  if (selectedReaction !== item.id && dayEntry) {
                    store.reactToJourneyPhoto(
                      journey.id,
                      numericDay,
                      currentPhoto.id,
                      item.id,
                    )
                  }
                  store.setReaction(reactionKey, item.id)
                }}
              >
                <OIcon name={item.icon} size={22} active />
                <b>{currentPhoto.reactions[item.id] ?? 0}</b>
              </button>
            ))}
          </div>
        )}
        {!emptyDay && (
          <div className="day-photo-actions">
            <button
              disabled={!dayEntry || dayEntry.coverPhotoId === currentPhoto.id}
              onClick={() => {
                store.setDayCoverPhoto(journey.id, numericDay, currentPhoto.id)
                setToast("Đã đặt làm ảnh đại diện.")
              }}
            >
              <OIcon name="image" size={17} /> Đặt làm ảnh đại diện
            </button>
            <button onClick={() => setDeleteOpen(true)}>
              <OIcon name="trash" size={17} /> Xoá ảnh này
            </button>
          </div>
        )}
        {!emptyDay && (
          <div className="day-share-mode" aria-label="Kiểu thiệp ngày">
            <button
              className={shareMode === "single" ? "selected" : ""}
              onClick={() => setShareMode("single")}
            >
              1 ảnh
            </button>
            <button
              className={shareMode === "collage" ? "selected" : ""}
              disabled={photos.length < 2}
              onClick={() => setShareMode("collage")}
            >
              Ghép 2–4 ảnh
            </button>
          </div>
        )}
        {!emptyDay && (
          <div
            className={`day-share-preview preview-${shareMode}`}
            aria-label="Xem trước thiệp ngày"
          >
            {(shareMode === "collage"
              ? photos.slice(0, 4)
              : [currentPhoto]
            ).map((photo, index) => (
              <span key={photo.id}>
                <DayVisual journey={journey} day={numericDay + index} />
              </span>
            ))}
            <b>{shareMode === "collage" ? "Ghép ảnh trong ngày" : "1 ảnh"}</b>
          </div>
        )}
      </main>
      <JourneyActionSheet
        open={reportOpen}
        title="Báo cáo ảnh này"
        body="Chỉ đội ngũ Ourney xem báo cáo này. Ảnh sẽ ẩn với bạn ngay."
        onClose={() => setReportOpen(false)}
      >
        <div className="report-reasons">
          {["Spam", "Khoả thân", "Quấy rối", "Tự hại", "Khác"].map((item) => (
            <button
              key={item}
              className={reason === item ? "selected" : ""}
              onClick={() => setReason(item)}
            >
              {reason === item && (
                <OIcon name="check" size={15} weight="bold" />
              )}
              {item}
            </button>
          ))}
        </div>
        <button
          className="sheet-primary"
          disabled={!reason}
          onClick={() => {
            setHidden(true)
            setReportOpen(false)
            setToast("Đã gửi báo cáo.")
          }}
        >
          Gửi báo cáo
        </button>
      </JourneyActionSheet>
      <JourneyActionSheet
        open={blockOpen}
        title="Chặn Minh?"
        body="Hai bên sẽ không thấy nội dung của nhau."
        onClose={() => setBlockOpen(false)}
      >
        <button
          className="sheet-destructive"
          onClick={() => {
            store.blockUser("Minh")
            setBlockOpen(false)
            setHidden(true)
            setToast("Đã chặn Minh.")
          }}
        >
          Chặn
        </button>
        <button className="sheet-secondary" onClick={() => setBlockOpen(false)}>
          Thôi
        </button>
      </JourneyActionSheet>
      <JourneyActionSheet
        open={deleteOpen}
        title={
          photos.length === 1
            ? "Xoá ảnh này? Ngày này vẫn được tính cho chuỗi."
            : "Xoá ảnh này?"
        }
        body={
          photos.length === 1
            ? undefined
            : "Các ảnh còn lại của ngày này vẫn được giữ."
        }
        onClose={() => setDeleteOpen(false)}
      >
        <button
          className="sheet-destructive"
          onClick={() => {
            if (dayEntry) {
              store.deleteJourneyPhoto(journey.id, numericDay, currentPhoto.id)
            } else {
              store.deleteLatestCheckIn(journey.id)
            }
            setDeleteOpen(false)
            if (photos.length === 1) {
              setActivePhoto(0)
              setToast("Đã xoá ảnh. Ngày này vẫn được tính cho chuỗi.")
            } else {
              setActivePhoto(Math.max(0, activePhoto - 1))
              setToast("Đã xoá ảnh.")
            }
          }}
        >
          Xoá ảnh
        </button>
        <button
          className="sheet-secondary"
          onClick={() => setDeleteOpen(false)}
        >
          Thôi
        </button>
      </JourneyActionSheet>
      {toast && <div className="pushed-toast">{toast}</div>}
    </section>
  )
}

const variantNames: Record<string, string[]> = {
  quiet: ["Lục ngọc", "Xanh sage", "Sương mù"],
  squad: ["Lửa", "Tím", "Phấn"],
  memory: ["Sương thông", "Biển muối", "Phố đêm"],
  couple: ["Hồng", "Mâm xôi", "Đào"],
  flexer: ["Lime neon", "San hô điện", "Băng"],
  minimal: ["Cam", "Than", "Trời"],
}

const layoutOptions = [
  ["quiet", "Quiet"],
  ["squad", "Squad"],
  ["memory", "Memory"],
  ["couple", "Couple"],
  ["flexer", "Flexer"],
  ["minimal", "Minimalist"],
] as const

function LayoutPreview({
  skin,
  large = false,
  journey,
}: {
  skin: string
  large?: boolean
  journey?: Journey
}) {
  return (
    <div
      className={`layout-preview layout-preview-${skin} ${
        large ? "large" : ""
      }`}
    >
      <div className="layout-preview-top">
        <i />
        <b>
          {journey
            ? `NGÀY ${journey.day}/${journeyLength(journey)}`
            : "XEM TRƯỚC"}
        </b>
        <i />
      </div>
      <div className="layout-preview-timeline">
        <span />
        <span />
        <span />
      </div>
      <div className="layout-preview-hud">
        <OIcon name="camera" size={large ? 22 : 14} weight="bold" />
        <span>{journey ? journeyMetric(journey) : "HUD máy ảnh"}</span>
      </div>
    </div>
  )
}

function JourneyEditScreen({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const initialMembers =
    journey.members ?? (journey.shared ? ["Linh", "An", "Hà", "Nam"] : ["Linh"])
  const [name, setName] = useState(journey.name)
  const [variant, setVariant] = useState(journey.variant)
  const [layoutPreview, setLayoutPreview] = useState<string | null>(null)
  const [cover, setCover] = useState(journey.cover ?? 0)
  const [reminder, setReminder] = useState(journey.reminderTime ?? "20:30")
  const [visibility, setVisibility] = useState<"private" | "link">(
    journey.visibility ?? "private",
  )
  const [hud, setHud] = useState(journey.hud ?? "HUD đậm")
  const [members, setMembers] = useState(initialMembers)
  const [endOpen, setEndOpen] = useState(false)
  const [leaveOpen, setLeaveOpen] = useState(false)
  const [codeOpen, setCodeOpen] = useState(false)
  const [pinReplaceOpen, setPinReplaceOpen] = useState(false)
  const [toast, setToast] = useState("")
  const isOwner = journey.owner ?? store.journeyOwner
  const groupJourney = (journey.members?.length ?? 0) >= 2
  const canImport =
    !journey.shared ||
    journey.skin === "couple" ||
    journey.members?.length === 2
  const availableLayouts = availableLayoutsForJourney(journey)
  const changed =
    name !== journey.name ||
    variant !== journey.variant ||
    cover !== (journey.cover ?? 0) ||
    reminder !== (journey.reminderTime ?? "20:30") ||
    visibility !== (journey.visibility ?? "private") ||
    hud !== (journey.hud ?? "HUD đậm") ||
    members.join("|") !== initialMembers.join("|")
  function save() {
    store.updateJourney(journey.id, {
      name,
      variant,
      cover,
      reminderTime: reminder,
      members,
      hud,
      visibility,
    })
    navigate(-1)
  }
  return (
    <section className={`journey-pushed edit-screen pushed-${journey.skin}`}>
      <PushedHeader
        title="cập nhật hành trình."
        onBack={() => navigate(-1)}
        action={
          <button className="edit-save-top" disabled={!changed} onClick={save}>
            Lưu
          </button>
        }
      />
      <main className="edit-content">
        {journey.skin === "quiet" && (
          <div className="quiet-edit-lock">
            <OIcon name="lock" size={16} weight="fill" /> Riêng tư
          </div>
        )}
        <section className="edit-section">
          <h2>Tên</h2>
          <input
            value={name}
            onChange={(event) => setName(event.target.value)}
          />
        </section>
        {store.journeys.filter((item) => !item.archived).length > 5 && (
          <section className="edit-section edit-camera-pin">
            <div>
              <h2>Hiện trên camera</h2>
              <p>Ghim hành trình này vào bộ chọn nhanh.</p>
            </div>
            <SystemSwitch
              label="Hiện trên camera"
              checked={store.pinnedCameraJourneyIds.includes(journey.id)}
              onChange={() => {
                if (store.pinnedCameraJourneyIds.includes(journey.id)) {
                  store.unpinCameraJourney(journey.id)
                } else if (!store.pinCameraJourney(journey.id)) {
                  setPinReplaceOpen(true)
                }
              }}
            />
          </section>
        )}
        <section className="edit-section">
          <h2>Bìa</h2>
          <div className="edit-cover-options">
            {[0, 1, 2].map((item) => (
              <button
                key={item}
                className={cover === item ? "selected" : ""}
                onClick={() => setCover(item)}
              >
                <span className={`skin-cover-sticker cover-sticker-${item}`}>
                  <i />
                  <em />
                </span>
                {cover === item && (
                  <OIcon name="check" size={15} weight="bold" />
                )}
              </button>
            ))}
          </div>
        </section>
        <section className="edit-section edit-layout-section">
          <h2>Giao diện</h2>
          {groupJourney && !isOwner ? (
            <div className="edit-layout-readonly">
              <LayoutPreview skin={journey.skin} journey={journey} />
              <p>Chủ nhóm chọn giao diện cho cả hội.</p>
            </div>
          ) : (
            <div className="edit-layout-grid">
              {layoutOptions
                .filter(([skin]) => availableLayouts.includes(skin))
                .map(([skin, label]) => (
                  <button
                    key={skin}
                    className={journey.skin === skin ? "selected" : ""}
                    onClick={() => setLayoutPreview(skin)}
                    aria-label={`Xem trước giao diện ${label}`}
                  >
                    <LayoutPreview skin={skin} journey={journey} />
                    <span>{label}</span>
                    {journey.skin === skin && <b>Đang dùng</b>}
                  </button>
                ))}
            </div>
          )}
          <p className="edit-layout-note">
            Một số giao diện cần thêm dữ liệu nên không hiện.
          </p>
        </section>
        <section className="edit-section">
          <h2>Màu</h2>
          <div className="edit-variant-options">
            {variantNames[journey.skin].map((item, index) => (
              <button
                key={item}
                className={variant === index ? "selected" : ""}
                onClick={() => setVariant(index)}
              >
                <i />
                {item}
                {variant === index && (
                  <OIcon name="check" size={15} weight="bold" />
                )}
              </button>
            ))}
          </div>
        </section>
        {journey.skin === "squad" && (
          <section className="edit-section edit-trophy-field">
            <h2>Tên chiếc cúp</h2>
            <input defaultValue="Cúp 7.5" />
          </section>
        )}
        {journey.skin === "memory" && (
          <section className="edit-section edit-readonly-row">
            <h2>Cuộn phim</h2>
            <span>24 · chỉ xem</span>
          </section>
        )}
        {journey.skin === "couple" && (
          <section className="edit-section edit-couple-fields">
            <h2>Hai đứa mình</h2>
            <div>
              <input defaultValue="Nam" />
              <input defaultValue="Linh" />
            </div>
            <input defaultValue="Nấu cho nhau" />
          </section>
        )}
        {journey.skin === "flexer" && (
          <section className="edit-section">
            <h2>Kiểu HUD</h2>
            <div className="edit-hud-options">
              {["HUD đậm", "Dấu tối giản", "Dải phim"].map((item) => (
                <button
                  key={item}
                  className={hud === item ? "selected" : ""}
                  onClick={() => setHud(item)}
                >
                  {hud === item && (
                    <OIcon name="check" size={14} weight="bold" />
                  )}
                  {item.replace("HUD ", "")}
                </button>
              ))}
            </div>
          </section>
        )}
        <section className="edit-section">
          <h2>Giờ nhắc</h2>
          <input
            type="time"
            value={reminder}
            onChange={(event) => setReminder(event.target.value)}
          />
        </section>
        <section className="edit-section">
          <h2>Ai được xem</h2>
          {journey.shared ? (
            <div className="edit-locked-row">
              <OIcon name="lock" size={17} />
              <span>
                <b>Chỉ thành viên</b>
                hành trình nhóm không có link công khai
              </span>
            </div>
          ) : (
            <div className="edit-visibility-options">
              {[
                ["private", "Chỉ mình tôi"],
                ["link", "Có link xem (thu hồi được)"],
              ].map(([value, label]) => (
                <button
                  key={value}
                  className={visibility === value ? "selected" : ""}
                  onClick={() => setVisibility(value as "private" | "link")}
                >
                  {visibility === value && (
                    <OIcon name="check" size={15} weight="bold" />
                  )}
                  {label}
                </button>
              ))}
              {journey.skin === "quiet" && visibility === "link" && (
                <p>Trang xem luôn ẩn số kg và làm mờ ảnh theo mặc định.</p>
              )}
            </div>
          )}
        </section>
        {journey.skin === "quiet" && (
          <section className="edit-section quiet-private-toggle">
            <span>Ẩn số kg khi chia sẻ</span>
            <input type="checkbox" defaultChecked />
          </section>
        )}
        {journey.shared && (
          <>
            <section className="edit-section">
              <h2>Thành viên · {members.length}/10</h2>
              <div className="edit-members">
                {members.map((member, index) => (
                  <div key={member}>
                    <span>{member.slice(0, 1)}</span>
                    <b>{member}</b>
                    {index === 0 ? (
                      <em>Chủ hành trình</em>
                    ) : isOwner ? (
                      <button
                        onClick={() => {
                          setMembers((current) =>
                            current.filter((item) => item !== member),
                          )
                        }}
                      >
                        Xoá
                      </button>
                    ) : (
                      <em>Thành viên</em>
                    )}
                  </div>
                ))}
              </div>
            </section>
            {isOwner ? (
              <section className="edit-section edit-code">
                <h2>Mã mời</h2>
                <b>{journey.inviteCode ?? "K7Q2M9XA"}</b>
                <button onClick={() => setCodeOpen(true)}>Đổi mã</button>
                <p>Mã cũ sẽ hết hiệu lực.</p>
                <p>Quyền chủ nhóm chuyển cho người vào sớm nhất.</p>
              </section>
            ) : (
              <section className="edit-section edit-readonly-row">
                <h2>Mã mời</h2>
                <span>Chỉ chủ nhóm có thể đổi mã.</span>
              </section>
            )}
          </>
        )}
        {store.blocked.length > 0 && (
          <section className="edit-section">
            <h2>Người bị chặn</h2>
            {store.blocked.map((name) => (
              <div className="blocked-person" key={name}>
                <OIcon name="lock" size={16} /> {name}
              </div>
            ))}
          </section>
        )}
        {canImport && (
          <button
            className="edit-import-button"
            onClick={() => navigate(`/j/${journey.id}/import`)}
          >
            <OIcon name="image" size={18} weight="bold" /> Nhập ảnh cũ
          </button>
        )}
        <button
          className="edit-end-button"
          onClick={() =>
            journey.shared && !isOwner ? setLeaveOpen(true) : setEndOpen(true)
          }
        >
          {journey.shared && !isOwner ? "Rời nhóm" : "Kết thúc hành trình"}
        </button>
      </main>
      <JourneyActionSheet
        open={pinReplaceOpen}
        title="thay hành trình đã ghim."
        body="Bạn đã ghim đủ 3 hành trình. Chọn một hành trình để thay."
        onClose={() => setPinReplaceOpen(false)}
      >
        <div className="camera-pin-replace">
          {store.pinnedCameraJourneyIds.map((id) => {
            const pinnedJourney = store.journeys.find((item) => item.id === id)
            if (!pinnedJourney) return null
            return (
              <button
                key={id}
                onClick={() => {
                  store.pinCameraJourney(journey.id, id)
                  setPinReplaceOpen(false)
                }}
              >
                <TypeBadge type={pinnedJourney.type} size={30} />
                {pinnedJourney.name}
              </button>
            )
          })}
        </div>
      </JourneyActionSheet>
      {layoutPreview && (
        <div className={`layout-full-preview previewing-${layoutPreview}`}>
          <header>
            <button
              onClick={() => setLayoutPreview(null)}
              aria-label="Quay lại"
            >
              <OIcon name="back" size={22} weight="bold" />
            </button>
            <b>{journey.name}</b>
            <span />
          </header>
          <LayoutPreview skin={layoutPreview} large journey={journey} />
          <div className="layout-preview-actions">
            <button
              onClick={() => {
                store.updateJourney(journey.id, {
                  skin: layoutPreview,
                  variant: 0,
                })
                setVariant(0)
                setLayoutPreview(null)
                store.showToast("Đã đổi giao diện cho hành trình.")
              }}
            >
              Dùng giao diện này
            </button>
            <button onClick={() => setLayoutPreview(null)}>Thôi</button>
          </div>
        </div>
      )}
      <JourneyActionSheet
        open={codeOpen}
        title="Đổi mã mời?"
        body="Mã cũ sẽ hết hiệu lực."
        onClose={() => setCodeOpen(false)}
      >
        <button
          className="sheet-primary group-action"
          onClick={() => {
            const nextCode = Math.random()
              .toString(36)
              .slice(2, 10)
              .toUpperCase()
            store.updateJourney(journey.id, { inviteCode: nextCode })
            setCodeOpen(false)
            setToast("Đã đổi mã mời.")
          }}
        >
          Đổi mã
        </button>
        <button className="sheet-secondary" onClick={() => setCodeOpen(false)}>
          Thôi
        </button>
      </JourneyActionSheet>
      <JourneyActionSheet
        open={leaveOpen}
        title="Rời nhóm?"
        body="Bạn sẽ không thấy hành trình này nữa. Muốn vào lại cần mã mời."
        onClose={() => setLeaveOpen(false)}
      >
        <button
          className="sheet-destructive"
          onClick={() => {
            store.showToast("Đã rời nhóm.")
            store.removeJourney(journey.id)
            setLeaveOpen(false)
            navigate("/hub", { replace: true })
          }}
        >
          <OIcon name="sign-out" size={18} weight="bold" /> Rời nhóm
        </button>
        <button className="sheet-secondary" onClick={() => setLeaveOpen(false)}>
          Thôi
        </button>
      </JourneyActionSheet>
      <JourneyActionSheet
        open={endOpen}
        title="Kết thúc hành trình?"
        body="Bạn vẫn xem lại được, nhưng không chụp thêm."
        onClose={() => setEndOpen(false)}
      >
        <button
          className="sheet-destructive"
          onClick={() => {
            store.updateJourney(journey.id, { archived: true })
            navigate(`/j/${journey.id}`, { replace: true })
          }}
        >
          <OIcon name="trash" size={18} weight="bold" /> Kết thúc
        </button>
        <button className="sheet-secondary" onClick={() => setEndOpen(false)}>
          Thôi
        </button>
      </JourneyActionSheet>
      {toast && <div className="pushed-toast">{toast}</div>}
    </section>
  )
}

function wrappedPagesFor(journey: Journey) {
  const total = journeyLength(journey)
  const checkIns = journeyCheckIns(journey)
  const moments =
    journeyPhotoCount(journey) || journey.importedPhotos?.length || checkIns
  const momentSummary = `${moments} khoảnh khắc trong ${checkIns} ngày`
  const dateRange =
    journey.startDate && journey.endDate
      ? `${formatJourneyDate(journey.startDate)} – ${formatJourneyDate(journey.endDate)}`
      : `Ngày ${journey.day}/${total}`
  if (journey.skin === "quiet") {
    return [
      momentSummary,
      journey.name,
      `Chuỗi ${journey.streak} ngày`,
      "Bạn đã về đích.",
    ]
  }
  if (journey.skin === "squad") {
    return [
      momentSummary,
      `${checkIns} lần điểm danh`,
      journey.name,
      "Về đích rồi, cả hội!",
    ]
  }
  if (journey.skin === "memory") {
    return [
      momentSummary,
      `${journey.importedPhotos?.length ?? checkIns} khung hình`,
      dateRange,
      journey.lastPlace || journey.name,
    ]
  }
  if (journey.skin === "couple") {
    return [
      momentSummary,
      journey.name,
      `${total} ngày bên nhau`,
      journey.lastCaption || "Khoảnh khắc đáng nhớ nhất",
    ]
  }
  if (journey.skin === "flexer") {
    return [
      momentSummary.toLocaleUpperCase("vi"),
      `${journey.totalKm ?? 0} KM`,
      journey.pace ? `NHỊP ĐỘ ${journey.pace}` : journey.name,
      `CHUỖI ${journey.streak}.`,
    ]
  }
  return [
    momentSummary.toLocaleUpperCase("vi"),
    `${checkIns}/${total} NGÀY · ${journey.name.toLocaleUpperCase("vi")}`,
  ]
}

type WrappedVisualProps = {
  journey: Journey
  page: number
}

function WrappedVisual(props: WrappedVisualProps) {
  const { journey, page } = props
  if (journey.imported && journey.importedPhotos?.length) {
    return (
      <div className="wrapped-memory-film">
        {journey.importedPhotos.slice(0, 4).map((photo, index) => (
          <span
            key={photo.id}
            className={`library-scene scene-${(index % 6) + 1}`}
            aria-label={`Ảnh ${formatJourneyDate(photo.date)}`}
          />
        ))}
      </div>
    )
  }
  if (journey.skin === "quiet") {
    return page === 2 ? (
      <svg className="wrapped-quiet-curve" viewBox="0 0 280 120">
        <path d="M8 98 C80 76 120 92 168 45 S236 28 272 12" />
      </svg>
    ) : (
      <div className="wrapped-quiet-photos">
        <QuietPhoto blurred />
        <QuietPhoto blurred />
      </div>
    )
  }
  if (journey.skin === "squad") {
    return page === 2 ? (
      <OIcon name="trophy" className="wrapped-trophy" size={94} weight="fill" />
    ) : (
      <div className="wrapped-squad-path">
        {Array.from({ length: 4 }, (_, index) => (
          <OIcon name="crew-dot" size={17} active key={index} />
        ))}
        <OIcon name="trophy" size={25} active />
      </div>
    )
  }
  if (journey.skin === "memory") {
    const photos = journey.importedPhotos
    return (
      <div className="wrapped-memory-film">
        {(photos?.length ? photos.slice(0, 4) : [1, 2, 3, 4]).map(
          (item, index) =>
            typeof item === "number" ? (
              <MemoryPhoto key={item} scene={item} />
            ) : (
              <span
                key={item.id}
                className={`library-scene scene-${(index % 6) + 1}`}
                aria-label={`Ảnh ${formatJourneyDate(item.date)}`}
              />
            ),
        )}
      </div>
    )
  }
  if (journey.skin === "couple") {
    return (
      <div className="wrapped-couple-frame">
        <CouplePhoto person="Nam" scene={page} />
        <OIcon name="heart" size={34} weight="fill" />
        <CouplePhoto person="Linh" scene={page + 1} />
      </div>
    )
  }
  if (journey.skin === "flexer") {
    return page === 2 ? (
      <svg className="wrapped-flexer-chart" viewBox="0 0 280 100">
        <path d="M4 82 L42 68 L77 73 L110 39 L151 54 L187 24 L228 36 L276 8" />
      </svg>
    ) : (
      <div className="wrapped-flexer-bars">
        {Array.from({ length: 30 }, (_, index) => (
          <i key={index} />
        ))}
      </div>
    )
  }
  return (
    <div className="wrapped-minimal-chain">
      {Array.from({ length: 30 }, (_, index) => (
        <i key={index} />
      ))}
    </div>
  )
}

function JourneyWrappedScreen({ journey }: { journey: Journey }) {
  const store = useStore()
  const navigate = useNavigate()
  const pages = wrappedPagesFor(journey)
  const [page, setPage] = useState(0)
  const [ratio, setRatio] = useState<"story" | "feed">("story")
  const [shareOpen, setShareOpen] = useState(false)
  const [toast, setToast] = useState("")
  const [hideKg, setHideKg] = useState(true)
  const [blurred, setBlurred] = useState(true)
  const [hideBrand, setHideBrand] = useState(journey.skin === "quiet")
  const startX = useRef(0)
  const summary = page >= pages.length
  function move(direction: number) {
    setPage((current) =>
      Math.max(0, Math.min(pages.length, current + direction)),
    )
  }
  return (
    <section
      className={`journey-pushed wrapped-screen pushed-${journey.skin}`}
      onPointerDown={(event) => {
        startX.current = event.clientX
      }}
      onPointerUp={(event) => {
        const distance = event.clientX - startX.current
        if (Math.abs(distance) > 40) move(distance < 0 ? 1 : -1)
      }}
    >
      <PushedHeader
        title="Hành trình đã về đích"
        onBack={() => navigate(`/j/${journey.id}`)}
        action={
          <button
            className="wrapped-close"
            onClick={() => navigate(`/j/${journey.id}`)}
            aria-label="Đóng"
          >
            <OIcon name="close" size={21} />
          </button>
        }
      />
      <div className="wrapped-progress">
        {pages.map((label, index) => (
          <button
            key={label}
            className={
              index === Math.min(page, pages.length - 1) ? "selected" : ""
            }
            onClick={() => setPage(index)}
          >
            <i />
            <span>Bước {index + 1}</span>
          </button>
        ))}
      </div>
      {!summary ? (
        <main
          className="wrapped-story"
          onClick={(event) => {
            const bounds = event.currentTarget.getBoundingClientRect()
            move(event.clientX > bounds.left + bounds.width / 2 ? 1 : -1)
          }}
        >
          <WrappedVisual journey={journey} page={page} />
          <h1>{pages[page]}</h1>
          {journey.skin === "memory" && page === pages.length - 1 && (
            <p>Cuộn phim đã hết. Mang đi in thôi.</p>
          )}
        </main>
      ) : (
        <main className="wrapped-summary">
          <div className="wrapped-ratio-tabs">
            <button
              className={ratio === "story" ? "selected" : ""}
              onClick={() => setRatio("story")}
            >
              9:16
            </button>
            <button
              className={ratio === "feed" ? "selected" : ""}
              onClick={() => setRatio("feed")}
            >
              4:5
            </button>
          </div>
          <div
            className={`wrapped-card ${ratio} ${
              journey.skin === "quiet" && blurred ? "blurred-photos" : ""
            }`}
          >
            <WrappedVisual journey={journey} page={pages.length - 1} />
            <h2>
              {journey.skin === "quiet"
                ? "NGÀY 01 vs NGÀY 30"
                : journey.skin === "squad"
                  ? "5/5 ĐÃ VỀ ĐÍCH"
                  : journey.skin === "memory"
                    ? `${journeyLength(journey)} NGÀY · ${journey.name.toLocaleUpperCase("vi")}`
                    : journey.skin === "couple"
                      ? "30 NGÀY BÊN NHAU · 60 KHOẢNH KHẮC"
                      : journey.skin === "flexer"
                        ? "30 NGÀY · 142,6 KM"
                        : "24/30 NGÀY · 80% ĐỀU ĐẶN"}
            </h2>
            {journey.skin === "quiet" && (
              <div className="wrapped-privacy">
                <button onClick={() => setHideKg(!hideKg)}>
                  {hideKg ? (
                    <OIcon name="check" size={14} />
                  ) : (
                    <OIcon name="eye" size={14} />
                  )}
                  Ẩn số kg · {hideKg ? "Bật" : "Tắt"}
                </button>
                <button onClick={() => setBlurred(!blurred)}>
                  {blurred ? (
                    <OIcon name="check" size={14} />
                  ) : (
                    <OIcon name="eye" size={14} />
                  )}
                  Làm mờ ảnh · {blurred ? "Bật" : "Tắt"}
                </button>
                {!hideKg && (
                  <b className="icon-text">
                    65,2 kg <OIcon name="caret-right" size={16} /> 62,0 kg
                  </b>
                )}
              </div>
            )}
            {!hideBrand && <Wordmark size={56} className="share-brand" />}
          </div>
          <button
            className="wrapped-create-card"
            onClick={() => {
              setToast("Thiệp đã sẵn sàng.")
              window.setTimeout(() => setToast(""), 1800)
            }}
          >
            {journey.skin === "memory"
              ? "Chia sẻ poster chuyến đi"
              : journey.skin === "couple"
                ? "Chia sẻ câu chuyện"
                : journey.skin === "flexer"
                  ? "Chia sẻ lên Story"
                  : journey.skin === "minimal"
                    ? "Xuất thẻ"
                    : "Tạo thiệp"}
          </button>
          <div className="wrapped-actions">
            <button onClick={() => setShareOpen(true)}>Chia sẻ</button>
            <button
              onClick={() => {
                setToast("Đã lưu ảnh.")
                window.setTimeout(() => setToast(""), 1800)
              }}
            >
              Lưu ảnh
            </button>
          </div>
        </main>
      )}
      <JourneyActionSheet
        open={shareOpen}
        title="chia sẻ tấm thiệp."
        onClose={() => setShareOpen(false)}
      >
        <button
          className="sheet-secondary share-brand-toggle"
          onClick={() => setHideBrand(!hideBrand)}
        >
          <OIcon name={hideBrand ? "eye-off" : "eye"} size={20} />
          Ẩn chữ ourney
          <span>{hideBrand ? "Bật" : "Tắt"}</span>
        </button>
        <button className="sheet-primary" onClick={() => setShareOpen(false)}>
          Tin nhắn
        </button>
        <button className="sheet-secondary" onClick={() => setShareOpen(false)}>
          Ứng dụng khác
        </button>
      </JourneyActionSheet>
      {toast && <div className="pushed-toast">{toast}</div>}
    </section>
  )
}

function CameraScreen() {
  const store = useStore()
  const navigate = useNavigate()
  const [flashOn, setFlashOn] = useState(false)
  const [frontCamera, setFrontCamera] = useState(false)
  const [ghostOn, setGhostOn] = useState(true)
  const active = store.journeys.find(
    (journey) => journey.id === store.activeJourneyId,
  )
  const cameraReady = store.cameraPermission === "granted"
  const noJourney = store.journeys.length === 0 || !active
  const quiet = active?.skin === "quiet"
  const squad = active?.skin === "squad"
  const memory = active?.skin === "memory"
  const couple = active?.skin === "couple"
  const flexer = active?.skin === "flexer"
  const minimal = active?.skin === "minimal"
  const switchedLayout = Boolean(active && hasSwitchedLayout(active))
  const todayEntry = active ? journeyTodayEntry(active) : undefined

  return (
    <ScreenShell camera>
      <div className="camera-ui">
        <div className="camera-safe-top">
          {active && (
            <button
              className={`active-journey-chip ${
                quiet
                  ? "quiet-camera-pill"
                  : squad
                    ? "squad-camera-pill"
                    : memory
                      ? "memory-camera-pill"
                      : couple
                        ? "couple-camera-pill"
                        : flexer
                          ? "flexer-camera-pill"
                          : minimal
                            ? "minimal-camera-pill"
                            : ""
              }`}
              style={
                { "--journey-pastel": typePastel[active.type] } as CSSProperties
              }
              onClick={() => store.setJourneyWheelOpen(true)}
            >
              {switchedLayout ? (
                <>
                  <TypeBadge type={active.type} size={28} />
                  <b>{journeyDisplayTitle(active).toLocaleUpperCase("vi")}</b>
                </>
              ) : active.todayDone ? (
                <>
                  <OIcon name="image" size={15} weight="bold" />
                  <b>Hôm nay · {todayEntry?.photos.length ?? 1} ảnh</b>
                </>
              ) : quiet ? (
                <>
                  <OIcon name="lock" size={15} weight="fill" />
                  <b>
                    Riêng tư · Ngày{" "}
                    {active.todayDone ? active.day - 1 : active.day}
                  </b>
                </>
              ) : squad ? (
                <b className="icon-text">
                  <OIcon name="book" size={16} /> {active.lastMinutes ?? 45}{" "}
                  PHÚT · <OIcon name="flame" size={16} active /> {active.streak}{" "}
                  LIÊN TIẾP
                </b>
              ) : memory ? (
                <>
                  <OIcon name="film" size={16} weight="fill" />
                  <b>
                    CUỘN PHIM {active.frameCount ?? journeyPhotoCount(active)}
                    /24
                  </b>
                </>
              ) : couple ? (
                <>
                  <OIcon name="heart" size={16} weight="fill" />
                  <b>
                    {active.partnerShot ? "Chụp nửa của Linh" : "Ghép đủ đôi"}
                  </b>
                </>
              ) : flexer ? (
                <b>CHẠY SÁNG · NGÀY {active.day}</b>
              ) : minimal ? (
                <b>ĐỌC 10 TRANG · NGÀY {active.day}</b>
              ) : (
                <>
                  <TypeBadge type={active.type} size={28} />
                  <b>
                    {active.name} · Ngày {active.day}/30
                  </b>
                  <OIcon name="caret-down" size={16} weight="bold" />
                </>
              )}
            </button>
          )}
          {!active && <span />}
          <div className="camera-top-actions">
            {quiet ? (
              <button
                onClick={() => navigate(`/j/${active.id}`)}
                aria-label="Đóng máy ảnh"
              >
                <OIcon name="close" size={21} weight="bold" />
              </button>
            ) : minimal ? (
              <span />
            ) : (
              <>
                <button
                  className={flashOn ? "active" : ""}
                  aria-label="Đèn chớp"
                  aria-pressed={flashOn}
                  onClick={() => setFlashOn(!flashOn)}
                >
                  <OIcon name="lightning" size={21} weight="bold" />
                </button>
                <button
                  className={frontCamera ? "active" : ""}
                  aria-label="Đổi camera"
                  aria-pressed={frontCamera}
                  onClick={() => setFrontCamera(!frontCamera)}
                >
                  <OIcon name="switch-camera" size={21} weight="bold" />
                </button>
              </>
            )}
          </div>
        </div>
        {store.cameraPinHint && (
          <div className="camera-pin-hint">
            <OIcon name="map-pin" size={18} weight="bold" />
            <span>Ghim tối đa 3 hành trình hay chụp lên camera</span>
            <button
              onClick={store.dismissCameraPinHint}
              aria-label="Đóng gợi ý ghim"
            >
              <OIcon name="close" size={16} weight="bold" />
            </button>
          </div>
        )}
        <div
          className={`live-viewfinder ${quiet ? "quiet-live-viewfinder" : ""} ${
            memory ? "memory-live-viewfinder" : ""
          } ${couple ? "couple-live-viewfinder" : ""} ${
            flexer ? "flexer-live-viewfinder" : ""
          } ${minimal ? "minimal-live-viewfinder" : ""} ${
            !cameraReady || noJourney ? "dimmed" : ""
          }`}
        >
          {switchedLayout && active ? (
            <div className={`adaptive-camera-hud adaptive-${active.skin}`}>
              <b>{journeyDisplayTitle(active).toLocaleUpperCase("vi")}</b>
              <span>{journeyMetric(active)}</span>
              {(active.members?.length ?? 0) >= 2 && (
                <small>
                  {active.attendance ?? 0}/{active.members?.length}{" "}
                  {journeyAttendanceVerb(active)}
                </small>
              )}
            </div>
          ) : quiet ? (
            <>
              {ghostOn && <div className="quiet-camera-ghost" />}
              <button
                className={`quiet-ghost-toggle ${ghostOn ? "on" : ""}`}
                onClick={() => setGhostOn(!ghostOn)}
                aria-pressed={ghostOn}
              >
                {ghostOn ? (
                  <OIcon name="eye" size={17} />
                ) : (
                  <OIcon name="eye-off" size={17} />
                )}
                Bóng ngày 1 · {ghostOn ? "Bật" : "Tắt"}
              </button>
            </>
          ) : squad ? (
            <div className="squad-camera-time">06:15</div>
          ) : memory ? (
            <>
              <div className="memory-camera-grain" />
              <div className="memory-camera-stamp">
                <b>
                  {active.endDate
                    ? formatJourneyDate(active.endDate)
                    : `NGÀY ${active.day}/${journeyLength(active)}`}
                </b>
                <span>
                  {(active.lastPlace || active.name).toLocaleUpperCase("vi")}
                </span>
              </div>
            </>
          ) : couple ? (
            <div className="couple-camera-split">
              <div className={active.partnerShot ? "shot" : "empty"}>
                {active.partnerShot ? (
                  <>
                    <CouplePhoto person="Nam" />
                    <span>ẢNH CỦA NAM · 07:30</span>
                  </>
                ) : (
                  <span>Nam chưa chụp. Bạn chụp trước nhé.</span>
                )}
              </div>
              <div className="live-half">
                <input
                  type="range"
                  min="0"
                  max="100"
                  defaultValue="58"
                  aria-label="Điều chỉnh khung hình"
                />
              </div>
            </div>
          ) : flexer ? (
            <>
              <div
                className={`flexer-camera-hud hud-${active.hud ?? "HUD đậm"}`}
              >
                <b className="icon-text">
                  NGÀY {active.day} · <OIcon name="flame" size={17} active />{" "}
                  {active.streak} LIỀN
                </b>
                <span>
                  {(active.lastKm ?? 5.42).toFixed(2).replace(".", ",")} KM ·{" "}
                  {active.pace ?? "5:04"} /KM
                </span>
              </div>
              {store.offline && (
                <div className="flexer-camera-sync">
                  <OIcon name="cloud-off" size={14} /> CHỜ ĐỒNG BỘ
                </div>
              )}
            </>
          ) : minimal ? (
            <>
              <div
                className="minimal-live-scene"
                role="img"
                aria-label="Sách và tách trà trên bàn gỗ"
              >
                <span className="minimal-live-book">
                  <i />
                  <i />
                </span>
                <span className="minimal-live-cup">
                  <i />
                </span>
                <span className="minimal-live-shadow" />
              </div>
              {store.offline && (
                <div className="minimal-camera-sync">
                  <OIcon name="clock" size={14} /> CHỜ ĐỒNG BỘ
                </div>
              )}
            </>
          ) : (
            <>
              <div className="ghost-frame">
                <span />
                <span />
                <span />
                <span />
              </div>
              {cameraReady && !noJourney && <p>Đặt khoảnh khắc vào khung</p>}
            </>
          )}
          {store.offline &&
            cameraReady &&
            !noJourney &&
            !flexer &&
            !minimal && (
              <div className="camera-offline-pill">
                đang lưu trên máy, có mạng sẽ tự gửi
              </div>
            )}
          {active && todayEntry?.photos.length ? (
            <button
              className="camera-latest-photo"
              onClick={() => navigate(`/j/${active.id}/day/${todayEntry.day}`)}
              aria-label={`Mở ${todayEntry.photos.length} ảnh hôm nay`}
            >
              <DayVisual journey={active} day={todayEntry.day} />
              <span>{todayEntry.photos.length} ảnh</span>
            </button>
          ) : null}
          {!cameraReady && !noJourney && (
            <div className="camera-state-card">
              <div className="camera-state-sticker">
                <OIcon name="camera" size={34} weight="duotone" />
              </div>
              <h2>
                {store.cameraPermission === "denied"
                  ? "camera đang tắt."
                  : "camera chưa bật."}
              </h2>
              {store.cameraPermission === "denied" && (
                <p>Vào Cài đặt của máy, mục ourney, để bật lại.</p>
              )}
              {store.cameraPermission !== "denied" && (
                <p>
                  Cho phép camera hoặc chọn một ảnh từ thư viện để tiếp tục.
                </p>
              )}
              <button
                className="camera-card-primary"
                onClick={() =>
                  store.cameraPermission === "denied"
                    ? store.setCameraPermission("granted")
                    : store.setCameraPermission("unknown")
                }
              >
                {store.cameraPermission === "denied" ? (
                  <>
                    <OIcon name="settings" size={20} weight="bold" /> Mở cài đặt
                  </>
                ) : (
                  "Bật camera"
                )}
              </button>
              <button
                className="camera-library-button"
                onClick={() =>
                  active
                    ? navigate(`/j/${active.id}/post`)
                    : (store.beginCreate("/camera"), navigate("/create/1"))
                }
              >
                <OIcon name="image" size={20} weight="bold" /> Chọn ảnh từ thư
                viện
              </button>
            </div>
          )}
          {noJourney && (
            <div className="camera-state-card no-journey-card">
              <div className="camera-state-sticker">
                <OIcon name="book" size={34} active />
              </div>
              <h2>chưa có hành trình nào.</h2>
              <p className="no-journey-helper">
                Mỗi tấm ảnh cần một hành trình để cất.
              </p>
              <button
                className="draft-suggestion"
                onClick={() => {
                  store.beginCreate("/camera", {
                    prefill: store.onboardingChoice ?? {
                      type: "Tự đặt",
                      who: "solo",
                    },
                  })
                  navigate("/create/1")
                }}
              >
                <span>
                  Gợi ý: {store.onboardingChoice?.type ?? "Một thói quen nhỏ"} ·{" "}
                  {store.onboardingChoice?.who === "group"
                    ? "rủ hội bạn"
                    : store.onboardingChoice?.who === "couple"
                      ? "chỉ hai đứa"
                      : "một mình"}
                </span>
                <OIcon name="caret-right" size={19} weight="bold" />
              </button>
              <button
                className="camera-card-primary"
                onClick={() => {
                  store.beginCreate("/camera")
                  navigate(store.resumeCreateRoute)
                }}
              >
                Tạo hành trình đầu tiên
              </button>
            </div>
          )}
        </div>
        {flexer && active && (
          <div className="flexer-hud-chips">
            {["HUD đậm", "Dấu tối giản", "Dải phim"].map((hud) => (
              <button
                key={hud}
                className={active.hud === hud ? "selected" : ""}
                onClick={() => store.setJourneyHud(active.id, hud)}
              >
                {active.hud === hud && (
                  <OIcon name="check" size={13} weight="bold" />
                )}
                {hud}
              </button>
            ))}
          </div>
        )}
      </div>
      {store.signedIn && !noJourney && store.cameraPermission === "unknown" && (
        <PermissionSheet
          kind="camera"
          reason={
            noJourney
              ? "Để chụp ảnh khi bạn bắt đầu. Ảnh chỉ hiện với người bạn chọn."
              : undefined
          }
          onClose={() => store.setCameraPermission("deferred")}
          onConfirm={() => store.setCameraPermission("granted")}
        />
      )}
      {store.notificationSheetOpen && (
        <PermissionSheet
          kind="notification"
          onClose={() => {
            store.setNotificationPromptHandled(true)
            store.setNotificationSheetOpen(false)
          }}
          onConfirm={() => {
            store.setNotificationPromptHandled(true)
            store.setNotificationSheetOpen(false)
          }}
        />
      )}
      {store.sessionExpired && (
        <PermissionSheet
          kind="session"
          onClose={() => store.setSessionExpired(false)}
          onConfirm={() => {
            store.setSessionExpired(false)
            navigate("/otp")
          }}
        />
      )}
    </ScreenShell>
  )
}

function HubScreen() {
  const store = useStore()
  const navigate = useNavigate()
  const [toast, setToast] = useState("")
  const showLoading = store.hubState === "loading"
  const showError = store.hubState === "error"
  const showEmpty =
    !showError && (store.hubState === "empty" || store.journeys.length === 0)
  useEffect(() => {
    if (store.hubState === "empty" || store.hubState === "error") {
      document.querySelector(".hub-screen .screen-content")?.scrollTo(0, 0)
    }
  }, [store.hubState])

  function showSyncToast() {
    store.setOffline(false)
    setToast("đã gửi xong.")
    window.setTimeout(() => setToast(""), 2200)
  }

  return (
    <ScreenShell title="hành trình." className="hub-screen">
      <div className="hub-content">
        <div className="hub-greeting">
          <h1>chào {store.profile?.name || "Linh"}.</h1>
        </div>

        {store.offline && (
          <div className="hub-offline-banner">
            <OIcon name="cloud-off" size={21} weight="bold" />
            <span>đang lưu trên máy, có mạng sẽ tự gửi</span>
          </div>
        )}
        {store.createProgress && (
          <button
            className="hub-create-progress"
            onClick={() => navigate(store.createProgress!.route)}
          >
            <span>
              <b>Tiếp tục tạo hành trình</b>
              <small>
                bước{" "}
                {store.createProgress.route.match(/\/create\/(\d)/)?.[1] ?? "1"}
                /5
              </small>
            </span>
            <OIcon name="caret-right" size={20} weight="bold" />
          </button>
        )}

        {showLoading ? (
          <HubSkeleton />
        ) : showError ? (
          <HubStateCard
            kind="error"
            action={() => {
              store.restoreSeedJourneys()
              store.setHubState("normal")
            }}
          />
        ) : showEmpty ? (
          <HubStateCard
            kind="empty"
            action={() => {
              store.beginCreate("/hub")
              navigate(store.resumeCreateRoute)
            }}
          />
        ) : (
          <>
            <HubHero state={store.hubHeroState} />
            <div className="hub-section-heading">
              <h2>hành trình của bạn.</h2>
              <span>
                <OIcon name="journeys" size={17} weight="bold" />
                {store.journeys.length} đang chạy
              </span>
            </div>
            <div className="hub-list">
              {store.journeys.map((journey) => (
                <JourneyCard
                  journey={journey}
                  key={journey.id}
                  onPendingSync={showSyncToast}
                />
              ))}
              <button
                className="new-journey-card"
                onClick={() => {
                  store.beginCreate("/hub")
                  navigate("/create/1")
                }}
              >
                <span>
                  <OIcon name="paper-plane" size={35} weight="duotone" />
                </span>
                <div>
                  <b>hành trình mới.</b>
                  <small>chọn một thế giới để bắt đầu</small>
                </div>
              </button>
            </div>
          </>
        )}
      </div>
      <div className={`hub-toast ${toast ? "show" : ""}`} role="status">
        <span>
          <OIcon name="type-custom" size={18} active />
        </span>
        {toast}
      </div>
    </ScreenShell>
  )
}

function HubHero({
  state,
}: {
  state: "default" | "done" | "milestone" | "group"
}) {
  const navigate = useNavigate()
  const copy = {
    default: (
      <>
        Còn 3 tiếng để giữ <StreakValue count={21} /> của IELTS 7.5
      </>
    ),
    done: "Hôm nay xong hết rồi. Mai gặp lại.",
    milestone: "Mai là Ngày 30 — về đích!",
    group: "Nam & Hà đang chờ bạn.",
  }[state]
  return (
    <article className={`hub-hero hero-${state}`}>
      <div className="hero-copy-block">
        <span className="today-chip">HÔM NAY</span>
        <h2>{copy}</h2>
        {state === "default" && (
          <div className="hero-timer">
            <OIcon name="timer" size={20} weight="bold" /> 03:12:40
          </div>
        )}
        {state === "group" && (
          <div className="hero-waiting-avatars">
            <i>N</i>
            <i>H</i>
          </div>
        )}
      </div>
      {state === "done" && (
        <div className="hero-state-sticker cat-sticker">
          <OIcon name="cat" size={43} weight="duotone" />
        </div>
      )}
      {state === "milestone" && (
        <div className="hero-state-sticker flag-sticker">
          <OIcon name="flag" size={42} weight="duotone" />
        </div>
      )}
      {state !== "done" && (
        <button onClick={() => navigate("/j/ielts/camera")}>Chụp ngay</button>
      )}
    </article>
  )
}

function HubStateCard({
  kind,
  action,
}: {
  kind: "empty" | "error"
  action: () => void
}) {
  return (
    <div className={`hub-main-state state-${kind}`}>
      <div className="hub-state-sticker">
        {kind === "empty" ? (
          <OIcon name="camera" size={40} weight="duotone" />
        ) : (
          <OIcon name="cloud-off" size={40} weight="duotone" />
        )}
      </div>
      <h2>
        {kind === "empty"
          ? "chưa có hành trình nào."
          : "không tải được. thử lại?"}
      </h2>
      {kind === "empty" && <p>một tấm mỗi ngày, giữ được cả chặng đường.</p>}
      <button onClick={action}>
        {kind === "empty" ? "Tạo hành trình đầu tiên" : "Thử lại"}
      </button>
    </div>
  )
}

function HubSkeleton() {
  return (
    <div className="hub-skeletons" aria-label="Đang tải">
      <div className="hub-hero-skeleton skeleton-piece" />
      {[1, 2, 3].map((item) => (
        <div className="hub-card-skeleton skeleton-piece" key={item}>
          <i />
          <div>
            <b />
            <span />
            <span />
          </div>
        </div>
      ))}
    </div>
  )
}

function JourneyCard({
  journey,
  onPendingSync,
}: {
  journey: Journey
  onPendingSync: () => void
}) {
  const store = useStore()
  const navigate = useNavigate()
  const [menuOpen, setMenuOpen] = useState(false)
  const selected = journey.id === store.activeJourneyId
  const skinClass = `dna-${journey.skin}`
  const totalDays = journeyLength(journey)
  const checkIns = journeyCheckIns(journey)
  const progress = Math.min(100, Math.round((journey.day / totalDays) * 100))
  const detail = {
    stats: `Ngày ${journey.day}/${totalDays}`,
    milestone: journey.archived
      ? `Đã khép lại · ${formatJourneyDate(journey.endDate)}`
      : `Mốc kế: Ngày ${totalDays} · Về đích`,
    attendance:
      hasSwitchedLayout(journey) && (journey.members?.length ?? 0) >= 2
        ? `${journey.attendance ?? 0}/${journey.members?.length} ${journeyAttendanceVerb(journey).toLocaleLowerCase("vi")}`
        : journey.skin === "squad"
          ? `${journey.attendance ?? (store.checkedIn ? 4 : 3)}/${journey.members?.length ?? 5} đã điểm danh`
          : journey.skin === "memory"
            ? `${journey.importedPhotos?.length ?? checkIns}/${totalDays} khung`
            : journey.skin === "couple"
              ? journey.pairComplete
                ? "đủ đôi"
                : "đang chờ một nửa"
              : undefined,
  }

  return (
    <article
      className={`dna-journey-card ${skinClass} ${selected ? "selected" : ""}`}
    >
      <button
        className="card-open-hit"
        aria-label={`Mở hành trình ${journey.name}`}
        onClick={() => navigate(`/j/${journey.id}`)}
      />
      {journey.skin === "memory" && <span className="memory-tape" />}
      <div
        className="dna-cover"
        style={{ "--cover": typePastel[journey.type] } as CSSProperties}
      >
        <TypeBadge type={journey.type} size={38} />
        <i>
          <OIcon
            name={
              ({
                quiet: "scales",
                squad: "trophy",
                memory: "pine",
                couple: "type-couple",
                flexer: "react-flex",
                minimal: "book",
              } as const)[journey.skin] ?? "type-custom"
            }
            size={24}
            active
          />
        </i>
      </div>
      <div className="dna-card-body">
        <div className="dna-title-row">
          <h3>{journey.name}</h3>
          <button
            className="make-primary-button"
            aria-label={`Mở menu của ${journey.name}`}
            onClick={(event) => {
              event.stopPropagation()
              setMenuOpen(!menuOpen)
            }}
          >
            <OIcon name="more" size={20} weight="bold" />
          </button>
          {menuOpen && (
            <div className="journey-card-menu">
              <button
                onClick={(event) => {
                  event.stopPropagation()
                  store.selectJourney(journey.id)
                  setMenuOpen(false)
                }}
              >
                <OIcon name="check" size={17} weight="bold" /> Đặt làm chính
              </button>
            </div>
          )}
        </div>
        {journey.skin === "quiet" && (
          <span className="private-chip">
            <OIcon name="lock" size={14} /> Riêng tư
          </span>
        )}
        {journey.archived ? (
          <span className="active-dna-chip">
            <OIcon name="lock" size={14} weight="bold" /> Đã kết thúc
          </span>
        ) : selected ? (
          <span className="active-dna-chip">
            <OIcon name="check" size={14} weight="bold" /> Đang hoạt động
          </span>
        ) : null}
        <p className="dna-stats icon-text">
          {detail.stats} · <OIcon name="flame" size={15} active />{" "}
          {journey.streak} · {progress}%
        </p>
        {journey.skin === "flexer" && <span className="neon-sparkline" />}
        {journey.skin === "minimal" && <span className="minimal-week-strip" />}
        <div className="dna-progress">
          <i
            style={{
              width: `${progress}%`,
            }}
          />
        </div>
        <div className="dna-meta-row">
          <div className="dna-avatars">
            <i>L</i>
            <i>N</i>
            <i>+3</i>
          </div>
          {detail.attendance && <span>{detail.attendance}</span>}
          {journey.skin === "memory" && (
            <span className="film-counter">
              {journey.importedPhotos?.length ?? checkIns}/{totalDays}
            </span>
          )}
        </div>
        <p className="dna-milestone">{detail.milestone}</p>
        {store.offline && journey.id === "ielts" && (
          <button
            className="pending-chip"
            onClick={(event) => {
              event.stopPropagation()
              onPendingSync()
            }}
          >
            <OIcon name="clock" size={16} weight="bold" /> chờ gửi · 1 ảnh
          </button>
        )}
      </div>
    </article>
  )
}

type MemberSheetProps = {
  name: string
  onClose: () => void
}

function MemberSheet({ name, onClose }: MemberSheetProps) {
  const store = useStore()
  const [view, setView] = useState<"member" | "report" | "block" | "done">(
    "member",
  )
  const [reason, setReason] = useState("")
  const [note, setNote] = useState("")
  return (
    <div className="system-sheet-host">
      <JourneyActionSheet
        open
        title={
          view === "member"
            ? name
            : view === "report"
              ? "báo cáo."
              : view === "block"
                ? `Chặn ${name}?`
                : "Đã nhận báo cáo."
        }
        body={
          view === "member"
            ? `@${name.toLocaleLowerCase("vi")}.ourney`
            : view === "block"
              ? `Bạn và ${name} sẽ không thấy nội dung của nhau. Bạn có thể bỏ chặn trong cài đặt.`
              : view === "done"
                ? "Nội dung này đã được ẩn với bạn."
                : undefined
        }
        onClose={onClose}
      >
        {view === "member" && (
          <>
            <div className="member-sheet-avatar">{name.slice(0, 1)}</div>
            <div className="member-sheet-actions">
              <button onClick={() => setView("report")}>
                <OIcon name="warning" size={19} weight="bold" /> Báo cáo người
                dùng
              </button>
              <button onClick={() => setView("block")}>
                <OIcon name="lock" size={19} weight="bold" /> Chặn
              </button>
            </div>
          </>
        )}
        {view === "report" && (
          <>
            <div className="report-reasons">
              {["Spam", "Khoả thân", "Quấy rối", "Tự hại", "Khác"].map(
                (item) => (
                  <button
                    key={item}
                    className={reason === item ? "selected" : ""}
                    onClick={() => setReason(item)}
                  >
                    <OIcon name="warning" size={17} weight="bold" />
                    {reason === item && (
                      <OIcon name="check" size={15} weight="bold" />
                    )}
                    {item}
                  </button>
                ),
              )}
            </div>
            {reason === "Tự hại" && (
              <p className="self-harm-note">
                Nếu ai đó đang gặp nguy hiểm, hãy liên hệ người thân hoặc dịch
                vụ khẩn cấp ở nơi bạn sống.
              </p>
            )}
            <label className="report-note">
              <span>Ghi chú không bắt buộc</span>
              <textarea
                value={note}
                onChange={(event) => setNote(event.target.value)}
                maxLength={280}
              />
            </label>
            <button
              className="sheet-primary"
              disabled={!reason}
              onClick={() => setView("done")}
            >
              Gửi báo cáo
            </button>
          </>
        )}
        {view === "block" && (
          <>
            <button
              className="sheet-destructive"
              onClick={() => {
                store.blockUser(name)
                onClose()
              }}
            >
              <OIcon name="lock" size={18} weight="bold" /> Chặn
            </button>
            <button className="sheet-secondary" onClick={onClose}>
              Huỷ
            </button>
          </>
        )}
        {view === "done" && (
          <button className="sheet-primary" onClick={onClose}>
            Xong
          </button>
        )}
      </JourneyActionSheet>
    </div>
  )
}

function SquadScreen() {
  const store = useStore()
  const navigate = useNavigate()
  const [code, setCode] = useState("")
  const [inviteVisible, setInviteVisible] = useState(true)
  const [member, setMember] = useState("")
  const [toast, setToast] = useState("")
  const inputRef = useRef<HTMLInputElement | null>(null)
  const groups = store.journeys.filter(
    (journey) => journey.shared && !journey.archived,
  )
  function normalizedCode() {
    return code
      .replace(/[^a-z0-9]/gi, "")
      .toUpperCase()
      .slice(0, 8)
  }
  function nudge(name: string) {
    store.nudge(name)
    setToast(`Đã nhắc ${name}`)
    window.setTimeout(() => setToast(""), 1800)
  }
  return (
    <ScreenShell title="hội." className="all-groups-screen">
      <div className="all-groups-content">
        {!store.signedIn && (
          <div className="groups-locked">
            <OIcon name="lock" size={25} weight="bold" />
            <b>Đăng nhập để dùng nhóm.</b>
            <button onClick={() => navigate("/login")}>Đăng nhập</button>
          </div>
        )}
        {store.offline && (
          <div className="groups-offline">
            <OIcon name="cloud-off" size={18} weight="bold" />
            Đang xem bản đã lưu. Cần có mạng để tham gia hoặc nhắc người khác.
          </div>
        )}
        <section className="join-inline">
          <label htmlFor="join-code">nhập mã mời</label>
          <div>
            <input
              ref={inputRef}
              id="join-code"
              value={
                normalizedCode().length > 4
                  ? `${normalizedCode().slice(0, 4)}-${normalizedCode().slice(4)}`
                  : normalizedCode()
              }
              onChange={(event) => setCode(event.target.value)}
              placeholder="K7Q2-M9XA"
              maxLength={9}
            />
            <button aria-label="Dán mã" onClick={() => setCode("K7Q2M9XA")}>
              <OIcon name="copy" size={20} weight="bold" />
            </button>
          </div>
          <button
            className="system-primary"
            disabled={
              normalizedCode().length !== 8 || store.offline || !store.signedIn
            }
            onClick={() => navigate(`/join/${normalizedCode()}`)}
          >
            Tham gia
          </button>
        </section>
        <section className="groups-today">
          <h2>hôm nay</h2>
          {store.hubState === "loading" ? (
            <div className="groups-skeleton">
              <i />
              <i />
            </div>
          ) : groups.length === 0 ? (
            <div className="groups-empty">
              <span>
                <OIcon name="squad" size={40} weight="duotone" />
              </span>
              <h3>chưa có hội nào.</h3>
              <p>Nhập mã mời để vào nhóm hoặc tạo hành trình nhóm.</p>
              <button onClick={() => inputRef.current?.focus()}>
                Nhập mã mời
              </button>
            </div>
          ) : (
            groups.map((journey, journeyIndex) => {
              const avatars = (
                journey.members ?? ["Linh", "An", "Nam", "Minh", "Hà"]
              ).filter((name) => !store.blocked.includes(name))
              const waiting = avatars[avatars.length - 1] ?? "Minh"
              return (
                <article
                  className={`group-overview-card ${
                    !store.signedIn ? "locked" : ""
                  }`}
                  key={journey.id}
                >
                  <button
                    className="card-open-hit"
                    aria-label={`Mở hội hôm nay của ${journey.name}`}
                    disabled={!store.signedIn}
                    onClick={() => navigate(`/j/${journey.id}/squad`)}
                  />
                  <div className="group-card-heading">
                    <span
                      className="group-type-badge"
                      style={{ background: typePastel[journey.type] }}
                    >
                      <TypeBadge type={journey.type} size={38} />
                    </span>
                    <div>
                      <h3>{journey.name}</h3>
                      <p>
                        {journey.attendance ?? 3}/{Math.max(5, avatars.length)}{" "}
                        đã check-in
                      </p>
                    </div>
                  </div>
                  <div className="group-avatar-row">
                    {avatars.slice(0, 5).map((name, index) => {
                      const checked = index < (journey.attendance ?? 3)
                      return (
                        <button
                          key={name}
                          className={checked ? "checked" : "waiting"}
                          onClick={(event) => {
                            event.stopPropagation()
                            if (store.signedIn) setMember(name)
                          }}
                        >
                          <span>{name.slice(0, 1)}</span>
                          <small>
                            {checked ? (
                              <>
                                <OIcon name="check" size={12} weight="bold" />{" "}
                                {`07:${12 + index}`}
                              </>
                            ) : (
                              <>
                                <OIcon name="clock" size={12} weight="bold" />{" "}
                                chưa
                              </>
                            )}
                          </small>
                        </button>
                      )
                    })}
                    {avatars.length > 5 && <b>+{avatars.length - 5}</b>}
                  </div>
                  <button
                    className="group-nudge"
                    disabled={
                      !store.signedIn ||
                      store.offline ||
                      store.nudged.includes(waiting)
                    }
                    onClick={(event) => {
                      event.stopPropagation()
                      nudge(waiting)
                    }}
                  >
                    {store.nudged.includes(waiting) ? (
                      <>
                        <OIcon name="check" size={15} weight="bold" /> Đã nhắc{" "}
                        {waiting}
                      </>
                    ) : (
                      <>
                        <OIcon name="nudge" size={16} weight="bold" /> Nhắc{" "}
                        {waiting}
                      </>
                    )}
                  </button>
                  <span className="sr-only">Nhóm thứ {journeyIndex + 1}</span>
                </article>
              )
            })
          )}
        </section>
        {inviteVisible && (
          <section className="pending-invites">
            <h2>lời mời đang chờ</h2>
            <article>
              <p>Hà mời bạn vào Hội IELTS 7.5</p>
              <div>
                <button onClick={() => navigate("/join/K7Q2M9XA")}>
                  Tham gia
                </button>
                <button onClick={() => setInviteVisible(false)}>Bỏ qua</button>
              </div>
            </article>
          </section>
        )}
      </div>
      {member && <MemberSheet name={member} onClose={() => setMember("")} />}
      {toast && <div className="system-toast">{toast}</div>}
    </ScreenShell>
  )
}

function JoinScreen() {
  const store = useStore()
  const navigate = useNavigate()
  const params = useParams()
  const [code, setCode] = useState(
    (params.code ?? store.pendingJoin).replace(/[^a-z0-9]/gi, "").toUpperCase(),
  )
  const normalized = code.slice(0, 8)
  const valid = normalized === "K7Q2M9XA"
  const errors: Record<string, string> = {
    AAAAAAAA: "Mã chưa đúng. Kiểm tra lại đủ 8 ký tự nhé.",
    EXPIRED1: "Mã này đã hết hiệu lực. Nhờ chủ nhóm gửi mã mới.",
    FULL0010: "Nhóm đã đủ 10 người.",
    NOJOIN01: "Không thể tham gia nhóm này.",
  }
  const error =
    store.offline && normalized.length === 8
      ? "Cần có mạng để tham gia."
      : (errors[normalized] ??
        (normalized.length === 8 && !valid
          ? "Mã chưa đúng. Kiểm tra lại đủ 8 ký tự nhé."
          : ""))
  useEffect(() => {
    setCode(
      (params.code ?? store.pendingJoin)
        .replace(/[^a-z0-9]/gi, "")
        .toUpperCase(),
    )
  }, [params.code, store.pendingJoin])
  useEffect(() => {
    if (!store.signedIn) {
      store.setPendingJoin(normalized)
      navigate("/splash", { replace: true })
    }
  }, [store.signedIn])
  function addKey(key: string) {
    setCode((current) =>
      key === "BACKSPACE"
        ? current.slice(0, -1)
        : `${current}${key}`.slice(0, 8),
    )
  }
  return (
    <section className="system-pushed join-screen">
      <PushedHeader title="vào nhóm." onBack={() => navigate(-1)} />
      <main>
        <div className="join-code-boxes">
          {Array.from({ length: 8 }, (_, index) => (
            <span key={index}>{normalized[index] ?? ""}</span>
          ))}
        </div>
        {valid && !store.offline && (
          <>
            <article className="join-ticket-preview">
              <div className="join-ticket-head">
                <TypeBadge type="Tiếng Anh" size={38} />
                <div>
                  <h2>Hội IELTS 7.5</h2>
                  <p>Chủ nhóm · Hà</p>
                </div>
              </div>
              <dl>
                <div>
                  <dt>Thành viên</dt>
                  <dd>5/10 người</dd>
                </div>
                <div>
                  <dt>Thời lượng</dt>
                  <dd>30 ngày</dd>
                </div>
                <div>
                  <dt>Tiến độ</dt>
                  <dd>Ngày 21/30</dd>
                </div>
              </dl>
              <p>
                Tiến độ của bạn tính từ ngày bạn vào. Bạn vẫn xem được lịch sử
                nhóm.
              </p>
              <p>
                Nhóm này không có link công khai. Chỉ người có mã mới vào được.
              </p>
            </article>
            <button
              className="system-primary"
              onClick={() => {
                const existing = store.journeys.find(
                  (journey) => journey.inviteCode === normalized,
                )
                if (existing) {
                  store.selectJourney(existing.id)
                  store.showToast("Bạn đã ở trong nhóm này.")
                  navigate(`/j/${existing.id}`, { replace: true })
                  return
                }
                const id = store.addJoinedJourney(normalized)
                navigate(`/j/${id}`, { replace: true })
              }}
            >
              Tham gia
            </button>
            <button className="join-later" onClick={() => navigate("/squad")}>
              Để sau
            </button>
          </>
        )}
        {error && (
          <div className="join-error">
            <OIcon name="warning" size={20} weight="bold" />
            {error}
          </div>
        )}
        {!valid && (
          <div className="join-keyboard">
            {[..."ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", "BACKSPACE"].map(
              (key) => (
                <button key={key} onClick={() => addKey(key)}>
                  {key === "BACKSPACE" ? <OIcon name="back" size={18} /> : key}
                </button>
              ),
            )}
          </div>
        )}
      </main>
    </section>
  )
}

const profileAvatarColors = ["#7EC8E3", "#FFD84D", "#FFB347", "#CF9FFF"]

function ProfileScreen() {
  const store = useStore()
  const navigate = useNavigate()
  const [editOpen, setEditOpen] = useState(false)
  const [name, setName] = useState(store.profile?.name ?? "Linh")
  const [username, setUsername] = useState(
    store.profile?.username ?? "linh.tran",
  )
  const [avatar, setAvatar] = useState(store.profile?.avatar ?? 0)
  const [badgeRule, setBadgeRule] = useState("")
  const completed = store.journeys.slice(0, 3)
  const location = useLocation()
  const resetEdit = () => {
    setName(store.profile?.name ?? "Linh")
    setUsername(store.profile?.username ?? "linh.tran")
    setAvatar(store.profile?.avatar ?? 0)
  }
  const closeEdit = () => {
    resetEdit()
    setEditOpen(false)
  }
  const openEdit = () => {
    resetEdit()
    setEditOpen(true)
  }
  useEffect(() => {
    if (new URLSearchParams(location.search).get("edit") === "1") openEdit()
  }, [location.search])
  return (
    <section className="system-pushed profile-screen">
      <PushedHeader
        title="hồ sơ."
        action={
          <button onClick={() => navigate("/settings")} aria-label="Cài đặt">
            <OIcon name="settings" size={21} weight="bold" />
          </button>
        }
      />
      <main>
        <section className="profile-identity">
          <div
            className="profile-main-avatar"
            style={{
              background:
                profileAvatarColors[store.profile?.avatar ?? avatar] ??
                profileAvatarColors[0],
            }}
          >
            {(store.profile?.name ?? "Linh").slice(0, 1)}
          </div>
          <h1>{store.profile?.name ?? "Linh"}</h1>
          <p>@{store.profile?.username ?? "linh.tran"}</p>
          <button onClick={openEdit}>Sửa hồ sơ</button>
        </section>
        <section className="profile-stats">
          {[
            ["148", "tổng ngày check-in"],
            ["41", "chuỗi dài nhất"],
            ["3", "hành trình đã xong"],
          ].map(([value, label]) => (
            <article key={label}>
              <b>{value}</b>
              <span>{label}</span>
            </article>
          ))}
        </section>
        <section className="profile-badges">
          <h2>huy hiệu đều đặn.</h2>
          <div>
            {[
              ["Đều 7 ngày", true, "Có mặt đủ 7 ngày liên tiếp."],
              ["Đều 30 ngày", true, "Có mặt đủ 30 ngày liên tiếp."],
              ["Về đích đầu tiên", true, "Hoàn thành hành trình đầu tiên."],
              ["Đủ 100 ngày", false, "Check-in đủ 100 ngày."],
            ].map(([label, unlocked, rule]) => (
              <button
                key={String(label)}
                className={unlocked ? "unlocked" : "locked"}
                onClick={() => setBadgeRule(String(rule))}
              >
                <span>
                  {unlocked ? (
                    <OIcon name="check" size={18} weight="bold" />
                  ) : (
                    <OIcon name="lock" size={18} weight="bold" />
                  )}
                </span>
                <b>{String(label)}</b>
              </button>
            ))}
          </div>
          {badgeRule && <p>{badgeRule}</p>}
        </section>
        <section className="profile-shelf">
          <h2>kệ hành trình đã xong.</h2>
          {completed.length ? (
            <div>
              {completed.map((journey, index) => (
                <button
                  key={journey.id}
                  className={`shelf-ticket shelf-${journey.skin}`}
                  aria-label={`Mở hành trình đã hoàn thành ${journey.name}`}
                  style={{ transform: `rotate(${index - 1.5}deg)` }}
                  onClick={() => {
                    store.updateJourney(journey.id, { archived: true })
                    navigate(`/j/${journey.id}`)
                  }}
                >
                  <TypeBadge type={journey.type} size={38} />
                  <b>{journey.name}</b>
                  <small>Đã về đích</small>
                </button>
              ))}
            </div>
          ) : (
            <p>Kệ còn trống. Hành trình xong sẽ về đây.</p>
          )}
        </section>
      </main>
      <JourneyActionSheet
        open={editOpen}
        title="sửa hồ sơ."
        onClose={closeEdit}
      >
        <span className="profile-edit-label">Màu ảnh đại diện</span>
        <div className="avatar-picker">
          {["L", "H", "N", "A"].map((item, index) => (
            <button
              key={item}
              className={avatar === index ? "selected" : ""}
              onClick={() => setAvatar(index)}
              aria-label={`Chọn màu ảnh đại diện ${index + 1}`}
            >
              <span>{name.slice(0, 1) || "L"}</span>
              {avatar === index && (
                <i className="corner-check-badge" data-corner-badge>
                  <OIcon name="check" size={14} weight="bold" />
                </i>
              )}
            </button>
          ))}
        </div>
        <label className="profile-edit-field">
          <span>Tên hiển thị</span>
          <input
            value={name}
            onChange={(event) => setName(event.target.value)}
          />
        </label>
        <label className="profile-edit-field">
          <span>Tên người dùng</span>
          <input
            value={username}
            onChange={(event) =>
              setUsername(
                event.target.value
                  .toLocaleLowerCase("vi")
                  .replace(/[^a-z0-9_.]/g, "")
                  .slice(0, 20),
              )
            }
          />
          <small>3-20 ký tự: a-z, 0-9, _ .</small>
          {username === "ourney" && <em>Tên này đã có người dùng.</em>}
        </label>
        <button
          className="sheet-primary"
          disabled={username.length < 3 || username === "ourney"}
          onClick={() => {
            store.setProfile({ name, username, avatar })
            setEditOpen(false)
          }}
        >
          Lưu
        </button>
        <button className="sheet-secondary" onClick={closeEdit}>
          Huỷ
        </button>
      </JourneyActionSheet>
      <FloatingDock currentPath="/me" />
    </section>
  )
}

function ActivityScreen() {
  const store = useStore()
  const navigate = useNavigate()
  const [inviteVisible, setInviteVisible] = useState(true)

  useEffect(() => {
    store.markActivityRead()
  }, [])

  const today = [
    {
      skin: "squad",
      text: "Minh vừa điểm danh",
      context: "Hội IELTS 7.5",
      time: "07:12",
      path: "/j/ielts/squad",
    },
    {
      skin: "squad",
      text: "An vừa thêm 2 ảnh vào Hội IELTS 7.5",
      context: "Hội IELTS 7.5",
      time: "06:48",
      path: "/j/ielts/day/21",
    },
    {
      skin: "quiet",
      text: "Còn 3 ngày tới mốc Nửa chặng",
      context: "30 ngày cơ thể",
      time: "06:30",
      path: "/j/quiet",
    },
  ]
  const week = [
    {
      skin: "minimal",
      text: "Nhắc giờ",
      context: "Đọc 10 trang · 20:30",
      time: "T2",
      path: "/j/minimal",
    },
  ]

  function eventRow(event: typeof today[number]) {
    const fullSentence = `${event.text} · ${event.context} · ${event.time}`
    return (
      <button
        className="activity-row"
        key={`${event.text}-${event.time}`}
        onClick={() => navigate(event.path)}
        aria-label={fullSentence}
      >
        <span className={`activity-skin-badge badge-${event.skin}`}>
          {event.skin === "squad" ? (
            <OIcon name="trophy" size={20} active />
          ) : event.skin === "quiet" ? (
            <OIcon name="type-weight" size={20} active />
          ) : (
            <OIcon name="book" size={20} active />
          )}
        </span>
        <div>
          <b>{event.text}</b>
          <span>{event.context}</span>
        </div>
        <time>{event.time}</time>
      </button>
    )
  }

  return (
    <ScreenShell title="hoạt động." className="activity-screen">
      <main className="activity-feed">
        {store.offline && (
          <div className="activity-offline">
            <OIcon name="wifi-off" size={17} weight="bold" /> Đang xem bản đã
            lưu.
          </div>
        )}
        {store.activityState === "loading" ? (
          <div className="activity-skeleton" aria-label="Đang tải hoạt động">
            {Array.from({ length: 5 }, (_, index) => (
              <i key={index} />
            ))}
          </div>
        ) : store.activityState === "empty" ? (
          <div className="activity-empty">
            <span>
              <OIcon name="activity" size={38} weight="duotone" />
            </span>
            <h2>chưa có gì mới.</h2>
            <p>Những cập nhật từ hành trình sẽ xuất hiện ở đây.</p>
          </div>
        ) : (
          <>
            <section>
              <h2>Hôm nay</h2>
              {today.map(eventRow)}
            </section>
            <section>
              <h2>Tuần này</h2>
              {inviteVisible && (
                <article className="activity-invite">
                  <button
                    className="activity-row activity-invite-open"
                    onClick={() => navigate("/join/K7Q2M9XA")}
                    aria-label="Hà mời bạn vào Hội IELTS 7.5 · Mã mời K7Q2M9XA · T3"
                  >
                    <span className="activity-skin-badge badge-squad">
                      <OIcon name="trophy" size={20} active />
                    </span>
                    <div>
                      <b>Hà mời bạn vào Hội IELTS 7.5</b>
                      <span>Mã mời K7Q2M9XA</span>
                    </div>
                    <time>T3</time>
                  </button>
                  <div className="activity-invite-actions">
                    <button
                      onClick={(event) => {
                        event.stopPropagation()
                        navigate("/join/K7Q2M9XA")
                      }}
                    >
                      Tham gia
                    </button>
                    <button
                      onClick={(event) => {
                        event.stopPropagation()
                        setInviteVisible(false)
                      }}
                    >
                      Bỏ qua
                    </button>
                  </div>
                </article>
              )}
              {week.map(eventRow)}
            </section>
          </>
        )}
      </main>
    </ScreenShell>
  )
}

function SystemSwitch({
  checked,
  onChange,
  label,
}: {
  checked: boolean
  onChange: () => void
  label: string
}) {
  return (
    <button
      className={`system-switch ${checked ? "on" : ""}`}
      role="switch"
      aria-checked={checked}
      aria-label={label}
      onClick={onChange}
    >
      <span>{checked && <OIcon name="check" size={13} weight="bold" />}</span>
    </button>
  )
}

function SettingsScreen() {
  const store = useStore()
  const navigate = useNavigate()
  const [notice, setNotice] = useState("")
  function showNotice(message: string) {
    setNotice(message)
    window.setTimeout(() => setNotice(""), 1800)
  }
  return (
    <section className="system-pushed settings-screen">
      <PushedHeader title="cài đặt." onBack={() => navigate(-1)} />
      <main>
        <section className="settings-group">
          <h2>tài khoản</h2>
          <div className="settings-card">
            <button onClick={() => navigate("/me?edit=1")}>
              <OIcon name="profile" size={19} weight="bold" /> Sửa hồ sơ
            </button>
            {(["google", "email", "phone"] as const).map((method) => (
              <div className="settings-readonly" key={method}>
                <span>
                  {method === "google"
                    ? "Google"
                    : method === "phone"
                      ? "Số điện thoại"
                      : "Email"}
                </span>
                <b>
                  {store.linkedMethods.includes(method)
                    ? method === "email"
                      ? store.email
                      : "Đã liên kết"
                    : "Chưa liên kết"}
                </b>
              </div>
            ))}
            <button
              onClick={() => {
                store.setHasPassword(true)
                showNotice("Đã đặt mật khẩu cho tài khoản.")
              }}
            >
              <OIcon name="lock" size={19} weight="bold" /> Đặt mật khẩu
            </button>
            <button
              onClick={() => {
                store.setSignedIn(false)
                navigate("/login", { replace: true })
              }}
            >
              <OIcon name="sign-out" size={19} weight="bold" /> Đăng xuất
            </button>
          </div>
        </section>
        <section className="settings-group">
          <h2>nhắc nhở</h2>
          <div className="settings-card">
            {store.journeys
              .filter((journey) => !journey.archived)
              .map((journey) => (
                <div className="settings-reminder" key={journey.id}>
                  <TypeBadge type={journey.type} size={38} />
                  <div>
                    <b>{journey.name}</b>
                    <small>20:30</small>
                  </div>
                  <SystemSwitch
                    label={`Nhắc ${journey.name}`}
                    checked={store.reminderEnabled[journey.id] ?? true}
                    onChange={() =>
                      store.setReminderEnabled(
                        journey.id,
                        !(store.reminderEnabled[journey.id] ?? true),
                      )
                    }
                  />
                </div>
              ))}
            <div className="settings-reminder">
              <span>
                <OIcon name="activity" size={19} weight="bold" />
              </span>
              <div>
                <b>Báo trước khi chuỗi sắp đứt</b>
                <small>21:00</small>
              </div>
              <SystemSwitch
                label="Báo trước khi chuỗi sắp đứt"
                checked={store.streakReminder}
                onChange={() => store.setStreakReminder(!store.streakReminder)}
              />
            </div>
          </div>
          {store.notificationPermission === "denied" && (
            <div className="permission-note">
              <p>Thông báo đang tắt. Bật trong cài đặt của máy.</p>
              <button
                onClick={() => showNotice("Đã mở hướng dẫn cài đặt thông báo.")}
              >
                Mở cài đặt máy
              </button>
            </div>
          )}
        </section>
        <section className="settings-group">
          <h2>giao diện</h2>
          <div className="theme-segmented">
            {[
              ["light", "Sáng", "sun"],
              ["dark", "Tối", "moon"],
              ["system", "Theo máy", "desktop"],
            ].map(([value, label, icon]) => (
              <button
                key={String(value)}
                className={store.themePreference === value ? "active" : ""}
                onClick={() =>
                  store.setThemePreference(value as "light" | "dark" | "system")
                }
              >
                <OIcon name={icon as OIconName} size={18} weight="bold" />
                <span className="theme-option-label">
                  {store.themePreference === value && (
                    <OIcon name="check" size={14} weight="bold" />
                  )}
                  {label as string}
                </span>
              </button>
            ))}
          </div>
          <div className="app-icon-picker">
            <b>Icon ứng dụng</b>
            <div>
              {[
                ["default", "#FF4D6D", "#10B981", "Mặc định"],
                ["quiet", "#DFF7EC", "#10B981", "Giảm cân"],
                ["squad", "#FFF0C7", "#FF9F1C", "Hội"],
                ["memory", "#F3E3C3", "#C2452B", "Ký ức"],
                ["couple", "#FFE0E9", "#E15B72", "Hai đứa"],
                ["flexer", "#14161F", "#3DE88C", "Tập luyện"],
                ["minimal", "#F4F4F5", "#EA580C", "Tối giản"],
              ].map(([value, tile, mark, label]) => (
                <button
                  key={value}
                  className={store.appIcon === value ? "selected" : ""}
                  style={
                    {
                      "--app-icon-tile": tile,
                      "--app-icon-mark": mark,
                    } as CSSProperties
                  }
                  onClick={() => store.setAppIcon(value)}
                  aria-label={`Icon ứng dụng ${label}`}
                >
                  <Wordmark size={42} variant="small" />
                  <span>{label}</span>
                  {store.appIcon === value && (
                    <i className="corner-check-badge" data-corner-badge>
                      <OIcon name="check" size={14} />
                    </i>
                  )}
                </button>
              ))}
            </div>
          </div>
        </section>
        <section className="settings-group">
          <h2>riêng tư</h2>
          <div className="settings-card">
            <div className="privacy-row">
              <span>Ẩn số kg khi chia sẻ</span>
              <SystemSwitch
                label="Ẩn số kg khi chia sẻ"
                checked={store.hideWeightOnShare}
                onChange={() =>
                  store.setHideWeightOnShare(!store.hideWeightOnShare)
                }
              />
            </div>
            <div className="privacy-row">
              <span>Làm mờ ảnh khi chia sẻ</span>
              <SystemSwitch
                label="Làm mờ ảnh khi chia sẻ"
                checked={store.blurPhotosOnShare}
                onChange={() =>
                  store.setBlurPhotosOnShare(!store.blurPhotosOnShare)
                }
              />
            </div>
            <div className="blocked-heading">Người bị chặn</div>
            {store.blocked.length ? (
              store.blocked.map((name) => (
                <div className="blocked-user" key={name}>
                  <span>{name.slice(0, 1)}</span>
                  <b>{name}</b>
                  <button onClick={() => store.unblockUser(name)}>
                    Bỏ chặn
                  </button>
                </div>
              ))
            ) : (
              <p className="blocked-empty">Bạn chưa chặn ai.</p>
            )}
          </div>
        </section>
        <section className="settings-group">
          <h2>thông tin</h2>
          <div className="settings-card info-card">
            {[
              ["Điều khoản sử dụng (EULA)", "/settings/terms"],
              ["Chính sách riêng tư", "/settings/privacy"],
              ["Liên hệ", "/settings/contact"],
            ].map(([label, path]) => (
              <button key={label} onClick={() => navigate(path)}>
                {label}
                <OIcon name="caret-right" size={18} weight="bold" />
              </button>
            ))}
            <div className="settings-readonly">
              <span>Phiên bản</span>
              <b>1.0</b>
            </div>
          </div>
        </section>
        <button
          className="danger-zone"
          onClick={() => navigate("/settings/delete/1")}
        >
          <OIcon name="warning" size={21} weight="bold" />
          Xoá tài khoản
        </button>
      </main>
      {notice && <div className="system-toast">{notice}</div>}
    </section>
  )
}

const legalSections = {
  terms: {
    title: "điều khoản sử dụng.",
    sections: [
      [
        "Dùng Ourney",
        "Dùng Ourney để lưu lại hành trình của bạn một cách an toàn và tôn trọng người khác.",
      ],
      [
        "Nội dung của bạn",
        "Ảnh là của bạn. Chỉ người trong hành trình bạn chọn mới thấy ảnh.",
      ],
      [
        "Điều không được đăng",
        "Không đăng nội dung khoả thân, quấy rối, tự hại hoặc spam.",
      ],
      [
        "Báo cáo và chặn",
        "Bạn có thể báo cáo hoặc chặn. Ourney có thể gỡ nội dung hoặc khoá tài khoản vi phạm.",
      ],
      [
        "Xoá tài khoản",
        "Bạn có thể xoá tài khoản bất cứ lúc nào trong Cài đặt.",
      ],
      [
        "Thay đổi điều khoản",
        "Nếu điều khoản thay đổi đáng kể, Ourney sẽ thông báo trong ứng dụng.",
      ],
    ],
  },
  privacy: {
    title: "chính sách riêng tư.",
    sections: [
      [
        "Mình lưu gì",
        "Ourney lưu email, ảnh, caption và các chỉ số bạn tự nhập.",
      ],
      [
        "Ai thấy ảnh",
        "Người trong hành trình thấy ảnh. Nhóm không có link công khai.",
      ],
      [
        "Giảm cân",
        "Số kg chỉ mình bạn thấy. Ảnh chia sẻ được làm mờ theo mặc định.",
      ],
      [
        "Máy ảnh và thông báo",
        "Ourney xin quyền đúng lúc. Bạn có thể tắt trong cài đặt của máy.",
      ],
      [
        "Xoá dữ liệu",
        "Xoá tài khoản sẽ xoá toàn bộ dữ liệu và ảnh trên máy chủ.",
      ],
    ],
  },
}

function LegalPage({ kind }: { kind: "terms" | "privacy" }) {
  const navigate = useNavigate()
  const page = legalSections[kind]
  return (
    <section className="system-pushed legal-page">
      <PushedHeader title={page.title} onBack={() => navigate(-1)} />
      <main>
        <p className="legal-updated">Cập nhật lần cuối: 01/11/2026</p>
        {page.sections.map(([heading, body]) => (
          <section key={heading}>
            <h2>{heading}</h2>
            <p>{body}</p>
          </section>
        ))}
      </main>
    </section>
  )
}

function ContactPage() {
  const navigate = useNavigate()
  const [toast, setToast] = useState("")
  function notify(message: string) {
    setToast(message)
    window.setTimeout(() => setToast(""), 1800)
  }
  return (
    <section className="system-pushed legal-page contact-page">
      <PushedHeader title="liên hệ." onBack={() => navigate(-1)} />
      <main>
        <p className="legal-updated">Cập nhật lần cuối: 01/11/2026</p>
        <button onClick={() => notify("Đã mở ứng dụng thư")}>
          <OIcon name="paper-plane" size={21} weight="bold" />
          <span>
            <b>Gửi email hỗ trợ</b>
            <small>hotro@ourney.example</small>
          </span>
          <OIcon name="caret-right" size={18} weight="bold" />
        </button>
        <button onClick={() => notify("Đã mở biểu mẫu báo lỗi")}>
          <OIcon name="warning" size={21} weight="bold" />
          <span>
            <b>Báo lỗi</b>
            <small>Mô tả điều chưa ổn</small>
          </span>
          <OIcon name="caret-right" size={18} weight="bold" />
        </button>
      </main>
      {toast && <div className="system-toast">{toast}</div>}
    </section>
  )
}

function DeleteAccountScreen() {
  const store = useStore()
  const navigate = useNavigate()
  const params = useParams()
  const step = params.step ?? "1"
  const [accepted, setAccepted] = useState(false)
  const [otp, setOtp] = useState("")
  const deleteOtpRef = useRef<HTMLInputElement | null>(null)
  const [seconds, setSeconds] = useState(30)
  const [status, setStatus] = useState<"ready" | "deleting" | "done" | "error">(
    "ready",
  )
  useEffect(() => {
    if (step !== "2" || seconds <= 0) return
    const timer = window.setInterval(
      () => setSeconds((current) => current - 1),
      1000,
    )
    return () => window.clearInterval(timer)
  }, [step, seconds])
  if (step === "3") {
    const done = status === "done"
    return (
      <section className="system-pushed delete-screen delete-progress">
        <PushedHeader title="đang xoá…" onBack={() => navigate(-1)} />
        <main>
          {status === "deleting" && (
            <div className="delete-loader" aria-label="Đang xoá" />
          )}
          {done && (
            <div className="delete-done">
              <span>
                <OIcon name="check" size={48} weight="bold" />
              </span>
              <h1>Đã xoá tài khoản.</h1>
              <p>Cảm ơn bạn đã dùng Ourney.</p>
              <button
                className="system-primary"
                onClick={() => {
                  store.resetAccount()
                  navigate("/splash", { replace: true })
                }}
              >
                Về màn đầu
              </button>
            </div>
          )}
          {status === "error" && (
            <div className="delete-error">
              <OIcon name="warning" size={24} weight="bold" />
              <p>
                {store.offline
                  ? "Cần có mạng để xoá tài khoản."
                  : "Chưa xoá được. Dữ liệu của bạn vẫn nguyên. Thử lại sau nhé."}
              </p>
              <button onClick={() => navigate("/settings")}>Về cài đặt</button>
            </div>
          )}
        </main>
      </section>
    )
  }
  if (step === "2") {
    return (
      <section className="system-pushed delete-screen">
        <PushedHeader title="xác nhận bằng mã." onBack={() => navigate(-1)} />
        <main>
          <p className="delete-lead">Mã gồm 6 số vừa gửi tới {store.email}</p>
          <div
            className="delete-otp"
            onClick={() => deleteOtpRef.current?.focus()}
          >
            {Array.from({ length: 6 }, (_, index) => (
              <span key={index}>{otp[index] ?? ""}</span>
            ))}
            <input
              ref={deleteOtpRef}
              className="otp-native-input"
              inputMode="numeric"
              autoComplete="one-time-code"
              autoFocus
              value={otp}
              onChange={(event) =>
                setOtp(event.target.value.replace(/\D/g, "").slice(0, 6))
              }
              aria-label="Mã xác nhận xoá tài khoản gồm 6 số"
            />
          </div>
          <button
            className="resend-code"
            disabled={seconds > 0}
            onClick={() => setSeconds(30)}
          >
            {seconds > 0 ? `Gửi lại sau ${seconds}s` : "Gửi lại mã"}
          </button>
          <button
            className="delete-final"
            disabled={otp.length !== 6}
            onClick={() => {
              setStatus("deleting")
              navigate("/settings/delete/3", { replace: true })
              window.setTimeout(() => {
                if (store.offline || otp !== "123456") setStatus("error")
                else setStatus("done")
              }, 1100)
            }}
          >
            <OIcon name="trash" size={18} weight="bold" /> Xoá vĩnh viễn
          </button>
          {otp.length === 6 && otp !== "123456" && (
            <p className="otp-error">Mã chưa đúng. Kiểm tra lại nhé.</p>
          )}
        </main>
      </section>
    )
  }
  return (
    <section className="system-pushed delete-screen">
      <PushedHeader title="xoá tài khoản." onBack={() => navigate(-1)} />
      <main>
        <div className="delete-warning">
          <OIcon name="warning" size={25} weight="bold" />
          <p>
            Toàn bộ dữ liệu và ảnh trên máy chủ sẽ bị xoá vĩnh viễn. Không thể
            khôi phục.
          </p>
        </div>
        <ul className="delete-list">
          <li>
            <OIcon name="profile" size={20} weight="bold" /> Hồ sơ của bạn
          </li>
          <li>
            <OIcon name="image" size={20} weight="bold" /> Mọi hành trình và ảnh
          </li>
          <li>
            <OIcon name="squad" size={20} weight="bold" /> Tư cách thành viên
            trong các nhóm
          </li>
        </ul>
        <p className="delete-owner-note">
          Nếu bạn là chủ nhóm, quyền chủ nhóm chuyển cho người vào sớm nhất.
        </p>
        <label className="delete-understand">
          <input
            type="checkbox"
            checked={accepted}
            onChange={(event) => setAccepted(event.target.checked)}
          />
          <span>Tôi hiểu việc này không thể hoàn tác.</span>
        </label>
        <button className="keep-account" onClick={() => navigate(-1)}>
          Giữ tài khoản
        </button>
        <button
          className="delete-continue"
          disabled={!accepted}
          onClick={() => navigate("/settings/delete/2")}
        >
          <OIcon name="trash" size={18} weight="bold" /> Tiếp tục
        </button>
      </main>
    </section>
  )
}

function CameraJourneyPicker() {
  const store = useStore()
  const navigate = useNavigate()
  const [query, setQuery] = useState("")
  const [endedOpen, setEndedOpen] = useState(false)
  const [replaceTarget, setReplaceTarget] = useState("")
  const pressTimer = useRef<number | null>(null)
  const longPressed = useRef(false)
  const activeJourneys = store.journeys.filter((journey) => !journey.archived)
  const pinningEnabled = activeJourneys.length > 5
  const matches = (journey: Journey) =>
    journey.name.toLocaleLowerCase("vi").includes(query.toLocaleLowerCase("vi"))
  const pinned = store.pinnedCameraJourneyIds
    .map((id) => store.journeys.find((journey) => journey.id === id))
    .filter((journey): journey is Journey =>
      Boolean(journey && !journey.archived && matches(journey)),
    )
  const pinnedIds = new Set(pinned.map((journey) => journey.id))
  const notShot = activeJourneys.filter(
    (journey) =>
      !pinnedIds.has(journey.id) && !journey.todayDone && matches(journey),
  )
  const shot = activeJourneys.filter(
    (journey) =>
      !pinnedIds.has(journey.id) && journey.todayDone && matches(journey),
  )
  const ended = store.journeys.filter(
    (journey) => journey.archived && matches(journey),
  )

  function selectJourney(journey: Journey) {
    if (longPressed.current) {
      longPressed.current = false
      return
    }
    store.selectJourney(journey.id)
    store.closeCameraPicker()
    setQuery("")
    if (store.cameraPickerMode === "compose") {
      navigate(`/j/${journey.id}/post`)
    }
  }

  function togglePin(journey: Journey) {
    if (!pinningEnabled || journey.archived) return
    if (store.pinnedCameraJourneyIds.includes(journey.id)) {
      store.unpinCameraJourney(journey.id)
      store.showToast("Bỏ ghim khỏi camera")
      return
    }
    if (store.pinCameraJourney(journey.id)) {
      store.showToast("Ghim lên camera")
    } else {
      setReplaceTarget(journey.id)
    }
  }

  function startLongPress(journey: Journey) {
    if (!pinningEnabled || journey.archived) return
    longPressed.current = false
    pressTimer.current = window.setTimeout(() => {
      longPressed.current = true
      togglePin(journey)
    }, 520)
  }

  function stopLongPress() {
    if (pressTimer.current !== null) {
      window.clearTimeout(pressTimer.current)
      pressTimer.current = null
    }
  }

  function renderRow(journey: Journey) {
    const isPinned = store.pinnedCameraJourneyIds.includes(journey.id)
    return (
      <button
        className="camera-picker-row"
        key={journey.id}
        onClick={() => selectJourney(journey)}
        onPointerDown={() => startLongPress(journey)}
        onPointerUp={stopLongPress}
        onPointerCancel={stopLongPress}
        onPointerLeave={stopLongPress}
        onContextMenu={(event) => {
          event.preventDefault()
          togglePin(journey)
        }}
      >
        <TypeBadge type={journey.type} size={38} />
        <span>
          <b>{journey.name}</b>
          <small>
            Ngày {journeyDisplayDay(journey)}/{journeyLength(journey)} · chuỗi{" "}
            {journey.streak}
          </small>
          {isPinned && pinningEnabled && (
            <em>
              <OIcon name="map-pin" size={13} weight="bold" /> Đã ghim
            </em>
          )}
        </span>
        {journey.todayDone && (
          <i aria-label="Đã chụp hôm nay">
            <OIcon name="check" size={16} weight="bold" />
          </i>
        )}
      </button>
    )
  }

  return (
    <JourneyActionSheet
      open={store.cameraPickerOpen}
      title="tất cả hành trình."
      onClose={() => {
        store.closeCameraPicker()
        setQuery("")
        setReplaceTarget("")
        setEndedOpen(false)
      }}
    >
      <label className="camera-picker-search">
        <OIcon name="search" size={19} weight="bold" />
        <input
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder="Tìm hành trình"
        />
      </label>
      {replaceTarget ? (
        <section className="camera-pin-replace">
          <h3>Thay hành trình đã ghim nào?</h3>
          {pinned.map((journey) => (
            <button
              key={journey.id}
              onClick={() => {
                store.pinCameraJourney(replaceTarget, journey.id)
                setReplaceTarget("")
              }}
            >
              <TypeBadge type={journey.type} size={30} />
              {journey.name}
            </button>
          ))}
          <button
            className="sheet-secondary"
            onClick={() => setReplaceTarget("")}
          >
            Thôi
          </button>
        </section>
      ) : (
        <div className="camera-picker-sections">
          {pinningEnabled && pinned.length > 0 && (
            <section>
              <h3>Đã ghim</h3>
              {pinned.map(renderRow)}
            </section>
          )}
          {notShot.length > 0 && (
            <section>
              <h3>Hôm nay chưa chụp</h3>
              {notShot.map(renderRow)}
            </section>
          )}
          {shot.length > 0 && (
            <section>
              <h3>Đã chụp hôm nay</h3>
              {shot.map(renderRow)}
            </section>
          )}
          {ended.length > 0 && (
            <section>
              <button
                className="camera-ended-toggle"
                onClick={() => setEndedOpen(!endedOpen)}
                aria-expanded={endedOpen}
              >
                Đã kết thúc
                <OIcon
                  name={endedOpen ? "caret-down" : "caret-right"}
                  size={16}
                  weight="bold"
                />
              </button>
              {endedOpen && ended.map(renderRow)}
            </section>
          )}
        </div>
      )}
    </JourneyActionSheet>
  )
}

let lastDockTabIndex: number | null = null

function FloatingDock({ currentPath }: { currentPath: string }) {
  const navigate = useNavigate()
  const store = useStore()
  const wheelOpen = store.journeyWheelOpen
  const dockRef = useRef<HTMLElement | null>(null)
  const [selectionGeometry, setSelectionGeometry] = useState({
    x: 0,
    width: 0,
    fromX: null as number | null,
  })
  const pressStartedAt = useRef(0)
  const pressFrame = useRef<number | null>(null)
  const longPressOpened = useRef(false)
  const activeJourney = store.journeys.find(
    (journey) => journey.id === store.activeJourneyId,
  )
  const activeCameraJourneys = store.journeys.filter(
    (journey) => !journey.archived,
  )
  const reminderDistance = (time?: string) => {
    if (!time) return Number.MAX_SAFE_INTEGER
    const [hour, minute] = time.split(":").map(Number)
    const now = new Date()
    const current = now.getHours() * 60 + now.getMinutes()
    const target = hour * 60 + minute
    return (target - current + 24 * 60) % (24 * 60)
  }
  const pinnedQuick = store.pinnedCameraJourneyIds
    .map((id) => activeCameraJourneys.find((journey) => journey.id === id))
    .filter((journey): journey is Journey => Boolean(journey))
  const pinnedQuickIds = new Set(pinnedQuick.map((journey) => journey.id))
  const automaticQuick = activeCameraJourneys
    .filter((journey) => !pinnedQuickIds.has(journey.id) && !journey.todayDone)
    .sort((left, right) => {
      const leftWaiting =
        left.shared &&
        (left.members?.length ?? 0) > (left.attendance ?? 0) &&
        !left.todayDone
      const rightWaiting =
        right.shared &&
        (right.members?.length ?? 0) > (right.attendance ?? 0) &&
        !right.todayDone
      if (leftWaiting !== rightWaiting) return leftWaiting ? -1 : 1
      const reminder =
        reminderDistance(left.reminderTime) -
        reminderDistance(right.reminderTime)
      if (reminder !== 0) return reminder
      if (left.id === store.activeJourneyId) return -1
      if (right.id === store.activeJourneyId) return 1
      return 0
    })
  const quickJourneys =
    activeCameraJourneys.length <= 5
      ? activeCameraJourneys
      : [...pinnedQuick, ...automaticQuick].slice(0, 4)
  const onCamera =
    currentPath === "/camera" || /^\/j\/[^/]+\/camera$/.test(currentPath)
  const journeyOwnedDock = /^\/j\/[^/]+(?:\/.*)?$/.test(currentPath)
  const shutterDisabled =
    store.readOnly ||
    Boolean(activeJourney?.archived) ||
    (onCamera && Boolean(activeJourney) && store.cameraPermission !== "granted")
  const quietDock = journeyOwnedDock && activeJourney?.skin === "quiet"
  const squadDock = journeyOwnedDock && activeJourney?.skin === "squad"
  const memoryDock = journeyOwnedDock && activeJourney?.skin === "memory"
  const coupleDock = journeyOwnedDock && activeJourney?.skin === "couple"
  const flexerDock = journeyOwnedDock && activeJourney?.skin === "flexer"
  const minimalDock = journeyOwnedDock && activeJourney?.skin === "minimal"
  const onJourneyHome = /^\/j\/[^/]+$/.test(currentPath)
  const onJourneySquad = /^\/j\/[^/]+\/squad$/.test(currentPath)
  const hubActive = currentPath === "/hub" || onJourneyHome
  const squadActive = currentPath === "/squad" || onJourneySquad
  const activityActive = currentPath === "/activity"
  const profileActive = currentPath === "/me"
  const activeDockIndex = hubActive
    ? 0
    : squadActive
      ? 1
      : activityActive
        ? 2
        : profileActive
          ? 3
          : -1

  function openWheel() {
    store.setJourneyWheelOpen(true)
  }

  function startPress(event: ReactPointerEvent<HTMLButtonElement>) {
    if (shutterDisabled) return
    if (event.button !== 0) return
    pressStartedAt.current = performance.now()
    longPressOpened.current = false

    const watchPress = (now: number) => {
      if (now - pressStartedAt.current >= 400) {
        longPressOpened.current = true
        openWheel()
        pressFrame.current = null
        return
      }
      pressFrame.current = window.requestAnimationFrame(watchPress)
    }

    pressFrame.current = window.requestAnimationFrame(watchPress)
  }

  function endPress() {
    if (shutterDisabled) return
    if (pressFrame.current !== null) {
      window.cancelAnimationFrame(pressFrame.current)
      pressFrame.current = null
    }
    if (!longPressOpened.current) {
      if (onCamera && activeJourney) {
        navigate(`/j/${activeJourney.id}/post`)
      } else if (activeJourney) {
        navigate(`/j/${activeJourney.id}/camera`)
      } else {
        store.beginCreate("/camera")
        navigate(store.resumeCreateRoute)
      }
    }
  }

  function cancelPress() {
    if (pressFrame.current !== null) {
      window.cancelAnimationFrame(pressFrame.current)
      pressFrame.current = null
    }
  }

  function chooseJourney(id: string) {
    store.selectJourney(id)
    store.setJourneyWheelOpen(false)
  }

  useLayoutEffect(() => {
    const dock = dockRef.current
    if (!dock || activeDockIndex < 0) {
      setSelectionGeometry({ x: 0, width: 0, fromX: null })
      return
    }

    const tabGeometry = (tab: HTMLElement) => ({
      x: tab.offsetLeft,
      width: tab.offsetWidth,
    })
    const activeTab = dock.querySelector<HTMLElement>(
      '.dock-tab[aria-current="page"]',
    )
    if (!activeTab) return

    const previousTab =
      lastDockTabIndex === null
        ? null
        : dock.querySelector<HTMLElement>(
            `[data-dock-index="${lastDockTabIndex}"]`,
          )
    const shouldSlide =
      !store.reduceMotion &&
      previousTab !== null &&
      lastDockTabIndex !== activeDockIndex

    const activeGeometry = tabGeometry(activeTab)
    const previousGeometry = previousTab ? tabGeometry(previousTab) : null
    setSelectionGeometry({
      ...activeGeometry,
      fromX: shouldSlide ? (previousGeometry?.x ?? null) : null,
    })

    // Defer the shared index so React Strict Mode's effect replay keeps the
    // same origin and the remounted route can animate from the previous tab.
    window.setTimeout(() => {
      lastDockTabIndex = activeDockIndex
    }, 0)
    const observer = new ResizeObserver(() => {
      setSelectionGeometry((current) => ({
        ...tabGeometry(activeTab),
        fromX: current.fromX,
      }))
    })
    observer.observe(dock)
    observer.observe(activeTab)
    return () => {
      observer.disconnect()
    }
  }, [activeDockIndex, store.reduceMotion])

  useEffect(
    () => () => {
      if (pressFrame.current !== null) {
        window.cancelAnimationFrame(pressFrame.current)
      }
    },
    [],
  )

  return (
    <>
      {wheelOpen && (
        <div className="journey-wheel-overlay">
          <button
            className="journey-wheel-backdrop"
            aria-label="Đóng vòng chọn hành trình"
            onClick={() => store.setJourneyWheelOpen(false)}
          />
          <button
            className="journey-wheel-close"
            onClick={() => store.setJourneyWheelOpen(false)}
            aria-label="Đóng vòng chọn"
          >
            <OIcon name="close" size={22} weight="bold" />
          </button>
          <div
            className="journey-wheel-container"
            onClick={(event) => event.stopPropagation()}
            onPointerDown={(event) => event.stopPropagation()}
            onPointerUp={(event) => event.stopPropagation()}
          >
            <div className="journey-disc-strip" aria-label="Chọn hành trình">
              {quickJourneys.map((journey) => {
                const journeySkin =
                  skins.find((item) => item.id === journey.skin) ?? skins[0]
                const accent =
                  journeySkin.variants[journey.variant]?.accent ??
                  journeySkin.variants[0].accent
                const selected = store.activeJourneyId === journey.id
                return (
                  <button
                    key={journey.id}
                    className={`journey-disc ${selected ? "selected" : ""}`}
                    data-testid={`journey-disc-${journey.id}`}
                    aria-current={selected}
                    aria-label={`${journey.name}, ngày ${journey.day}`}
                    style={
                      {
                        "--disc-accent": accent,
                        "--disc-text":
                          journey.skin === "couple" || journey.skin === "memory"
                            ? "#FFFFFF"
                            : "#111111",
                      } as CSSProperties
                    }
                    onClick={() => chooseJourney(journey.id)}
                  >
                    <span className="journey-disc-circle">
                      <TypeBadge type={journey.type} size={38} />
                      {selected && (
                        <i>
                          <OIcon name="check" size={12} weight="bold" />
                        </i>
                      )}
                    </span>
                    <b className="journey-disc-day">Ngày {journey.day}</b>
                    <small aria-label={journey.name} title={journey.name}>
                      {journey.name}
                    </small>
                    {activeCameraJourneys.length > 5 &&
                      pinnedQuickIds.has(journey.id) && (
                        <em className="journey-disc-pin">
                          <OIcon name="map-pin" size={12} weight="bold" /> Đã
                          ghim
                        </em>
                      )}
                    {activeCameraJourneys.length > 5 &&
                      !pinnedQuickIds.has(journey.id) &&
                      journey.shared &&
                      (journey.members?.length ?? 0) >
                        (journey.attendance ?? 0) && (
                        <em className="journey-disc-status">
                          {journey.attendance ?? 0}/
                          {journey.members?.length ?? 0} đã điểm danh
                        </em>
                      )}
                  </button>
                )
              })}
              {activeCameraJourneys.length > 5 && (
                <button
                  className="journey-disc journey-disc-all"
                  onClick={() => store.openCameraPicker("camera")}
                >
                  <span className="journey-disc-circle">
                    <OIcon name="journeys" size={24} weight="bold" />
                  </span>
                  <b className="journey-disc-day">
                    Tất cả ({store.journeys.length})
                  </b>
                  <small>tìm hành trình</small>
                </button>
              )}
            </div>
          </div>
        </div>
      )}
      <nav
        ref={dockRef}
        className={`floating-dock app-dock ${
          journeyOwnedDock ? "journey-dock" : "shell-dock"
        } ${quietDock ? "quiet-dock" : ""} ${squadDock ? "squad-dock" : ""} ${
          memoryDock ? "memory-dock" : ""
        } ${coupleDock ? "couple-dock" : ""} ${
          flexerDock ? "flexer-dock" : ""
        } ${minimalDock ? "minimal-dock" : ""} ${
          store.readOnly || activeJourney?.archived ? "dock-readonly" : ""
        }`}
        aria-label="Điều hướng chính"
        style={
          {
            "--dock-selection-x": `${selectionGeometry.x}px`,
            "--dock-selection-width": `${selectionGeometry.width}px`,
            "--dock-selection-from-x": `${selectionGeometry.fromX ?? selectionGeometry.x}px`,
          } as CSSProperties
        }
      >
        <button
          className={`dock-tab ${hubActive ? "active" : ""}`}
          data-dock-index="0"
          aria-current={hubActive ? "page" : undefined}
          onClick={() => navigate("/hub")}
        >
          <span className="dock-icon">
            <OIcon
              name="journeys"
              size={24}
              active={hubActive}
              weight={hubActive ? "fill" : "bold"}
            />
          </span>
          <span>Hành trình</span>
        </button>
        <button
          className={`dock-tab ${squadActive ? "active" : ""}`}
          data-dock-index="1"
          aria-current={squadActive ? "page" : undefined}
          onClick={() => navigate("/squad")}
        >
          <span className="dock-icon">
            <OIcon
              name="squad"
              size={24}
              active={squadActive}
              weight={squadActive ? "fill" : "bold"}
            />
          </span>
          <span>Hội</span>
        </button>
        <button
          className={`shutter ${onCamera ? "active" : ""} ${
            !activeJourney ? "no-journey" : ""
          }`}
          aria-label={
            activeJourney
              ? `Chụp ảnh cho ${activeJourney.name.replace(/^Hội /, "")}. Nhấn giữ để đổi hành trình.`
              : "Tạo hành trình đầu tiên"
          }
          disabled={shutterDisabled}
          onPointerDown={startPress}
          onPointerUp={endPress}
          onPointerCancel={cancelPress}
          onContextMenu={(event) => event.preventDefault()}
        >
          {store.readOnly || activeJourney?.archived ? (
            <>
              <OIcon name="lock" size={28} weight="bold" />
              <span className="readonly-shutter-label">
                {activeJourney?.skin === "memory" ||
                activeJourney?.skin === "couple" ||
                activeJourney?.skin === "flexer" ||
                activeJourney?.skin === "minimal"
                  ? "Đã khép lại"
                  : "Đã lưu trữ"}
              </span>
            </>
          ) : (
            <OIcon name="camera" size={32} active={onCamera} weight="bold" />
          )}
        </button>
        <button
          className={`dock-tab ${activityActive ? "active" : ""}`}
          data-dock-index="2"
          aria-current={activityActive ? "page" : undefined}
          onClick={() => navigate("/activity")}
        >
          <span className="dock-icon activity-dock-icon">
            <OIcon
              name="activity"
              size={24}
              active={activityActive}
              weight={activityActive ? "fill" : "bold"}
            />
            {store.activityUnread && !activityActive && (
              <i className="activity-unread-dot" />
            )}
          </span>
          <span>Hoạt động</span>
        </button>
        <button
          className={`dock-tab ${profileActive ? "active" : ""}`}
          data-dock-index="3"
          aria-current={profileActive ? "page" : undefined}
          onClick={() => navigate("/me")}
        >
          <span className="dock-icon">
            <OIcon
              name="profile"
              size={24}
              active={profileActive}
              weight={profileActive ? "fill" : "bold"}
            />
          </span>
          <span>Hồ sơ</span>
        </button>
        {activeDockIndex >= 0 && selectionGeometry.width > 0 && (
          <span
            key={activeDockIndex}
            className={`dock-selection-capsule ${
              selectionGeometry.fromX === null ? "" : "dock-selection-enter"
            }`}
            aria-hidden="true"
          />
        )}
      </nav>
    </>
  )
}

function CreateSheet({ onClose }: { onClose: () => void }) {
  const startY = useRef<number | null>(null)
  const [drag, setDrag] = useState(0)

  function dragStart(event: ReactPointerEvent<HTMLDivElement>) {
    startY.current = event.clientY
    event.currentTarget.setPointerCapture(event.pointerId)
  }

  function dragging(event: ReactPointerEvent<HTMLDivElement>) {
    if (startY.current === null) return
    setDrag(Math.max(0, event.clientY - startY.current))
  }

  function dragEnd() {
    if (drag > 70) onClose()
    setDrag(0)
    startY.current = null
  }

  return (
    <PhoneOverlay>
      <div
        className="app-sheet-scrim"
        onPointerDown={(event) =>
          event.target === event.currentTarget && onClose()
        }
      >
        <div
          className="app-sheet"
          role="dialog"
          aria-modal="true"
          style={{ transform: `translateY(${drag}px)` }}
        >
          <div
            className="sheet-drag-zone"
            onPointerDown={dragStart}
            onPointerMove={dragging}
            onPointerUp={dragEnd}
          >
            <div className="grab" />
          </div>
          <button className="sheet-close" onClick={onClose} aria-label="Đóng">
            <OIcon name="close" size={22} weight="bold" />
          </button>
          <span>Bắt đầu điều mới</span>
          <h2>tạo hành trình.</h2>
          <div className="coming-card">
            <OIcon name="plus" size={25} weight="bold" />
            <p>sắp có</p>
          </div>
        </div>
      </div>
    </PhoneOverlay>
  )
}

function NotFound() {
  return <Navigate replace to="/camera" />
}

function CreateAttachment() {
  const navigate = useNavigate()
  return (
    <section className="flow-screen create-attachment">
      <header className="simple-flow-header">
        <button
          className="flow-back"
          onClick={() => navigate(-1)}
          aria-label="Quay lại"
        >
          <OIcon name="back" size={22} weight="bold" />
        </button>
      </header>
      <div>
        <h1>tạo hành trình.</h1>
        <p>sắp có</p>
      </div>
    </section>
  )
}

const scenarioCopy: Record<string, {
  day: string
  broken: string
  error: string
  only: string
}> = {
  quiet: {
    day: "Bắt đầu từ hôm nay. Một tấm là đủ.",
    broken: "Chuỗi bắt đầu lại. Hành trình vẫn ở đây.",
    error: "Chưa tải được. Dữ liệu của bạn vẫn an toàn.",
    only: "Mới có mình bạn. Ở đây chỉ đếm sự đều đặn.",
  },
  squad: {
    day: "Chụp tấm đầu tiên nào!",
    broken: "Chuỗi về 0. Hôm nay bắt đầu lại, cả hội đợi!",
    error: "Chưa tải được. Thử lại nha!",
    only: "Hội chưa có ai. Gửi mã mời đi!",
  },
  memory: {
    day: "cuộn phim còn trống.",
    broken: "Cuộn phim vẫn quay tiếp.",
    error: "Cuộn phim chưa tải được. Thử lại nhé.",
    only: "Cuộn phim này mới có mình bạn.",
  },
  couple: {
    day: "Ngày 1 · hai đứa bắt đầu nhé.",
    broken: "Chuỗi chung về 0. Hai đứa bắt đầu lại nhé.",
    error: "Chưa tải được hai nửa. Thử lại nhé.",
    only: "Linh chưa vào. Mời Linh nhé.",
  },
  flexer: {
    day: "NGÀY 01/30 · XUẤT PHÁT.",
    broken: "CHUỖI 0. TIẾP.",
    error: "KHÔNG TẢI ĐƯỢC. THỬ LẠI.",
    only: "MỘT MÌNH. MỜI THÊM.",
  },
  minimal: {
    day: "CHUỖI 0 NGÀY",
    broken: "CHUỖI 0.",
    error: "LỖI. THỬ LẠI.",
    only: "MỘT MÌNH.",
  },
}

function JourneyScenarioScreen({
  journey,
  mode,
}: {
  journey: Journey
  mode: "home" | "squad"
}) {
  const store = useStore()
  const navigate = useNavigate()
  const state = store.journeyDemoState
  const copy = scenarioCopy[journey.skin] ?? scenarioCopy.quiet
  const [toast, setToast] = useState("")
  function showToast(message: string) {
    setToast(message)
    window.setTimeout(() => setToast(""), 1800)
  }
  if (state === "removed") {
    return (
      <ScreenShell bare className={`scenario-screen scenario-${journey.skin}`}>
        <main className="scenario-removed">
          <div className="scenario-sticker">
            <OIcon name="squad" size={36} weight="duotone" />
          </div>
          <h1>Bạn không còn trong nhóm này.</h1>
          <p>
            Chủ nhóm đã bỏ bạn khỏi nhóm. Bạn có thể vào lại nếu được mời lại.
          </p>
          <button
            onClick={() => {
              store.removeJourney(journey.id)
              store.setJourneyDemoState("normal")
              navigate("/hub", { replace: true })
            }}
          >
            Về hành trình
          </button>
        </main>
      </ScreenShell>
    )
  }
  return (
    <ScreenShell bare className={`scenario-screen scenario-${journey.skin}`}>
      <header className="scenario-header">
        <button onClick={() => navigate("/hub")} aria-label="Quay lại">
          <OIcon name="back" size={21} weight="bold" />
        </button>
        <b>{mode === "squad" ? "hội hôm nay." : journey.name}</b>
        <button
          onClick={() => navigate(`/j/${journey.id}/edit`)}
          aria-label="Cài đặt"
        >
          <OIcon name="settings" size={20} weight="bold" />
        </button>
      </header>
      <main className="scenario-content">
        {state === "loading" && (
          <div className={`scenario-skeleton skeleton-${journey.skin}`}>
            <i />
            <i />
            <i />
            <i />
          </div>
        )}
        {state === "error" && (
          <div className="scenario-message">
            <div className="scenario-cache-strip">
              <OIcon name="cloud-off" size={18} weight="bold" />
              Đang xem bản đã lưu
            </div>
            <div
              className={`scenario-cached-content cached-${journey.skin}`}
              aria-label="Nội dung hành trình đã lưu"
            >
              <DayVisual journey={journey} day={journey.day} />
              <div>
                <b>{journey.name}</b>
                <span className="icon-text">
                  Ngày {journey.day} · chuỗi{" "}
                  <StreakValue count={journey.streak} />
                </span>
              </div>
            </div>
            <p className="scenario-error-line">{copy.error}</p>
            <button onClick={() => store.setJourneyDemoState("normal")}>
              <OIcon name="switch-camera" size={18} weight="bold" /> Thử lại
            </button>
          </div>
        )}
        {state === "day1" && (
          <div className="scenario-day-one">
            <span className="scenario-kicker">
              {journey.skin === "quiet"
                ? "NGÀY 1/30"
                : journey.skin === "squad"
                  ? "NGÀY 01 · XUẤT PHÁT"
                  : journey.skin === "memory"
                    ? "CUỘN PHIM 0/24"
                    : journey.skin === "flexer"
                      ? "0,0 KM"
                      : journey.skin === "minimal"
                        ? "THÁNG 11"
                        : "NGÀY 1"}
            </span>
            <div className={`scenario-start-art start-${journey.skin}`}>
              {journey.skin === "couple" ? (
                <>
                  <span>Nam</span>
                  <OIcon name="heart" size={30} weight="regular" />
                  <span>Linh</span>
                </>
              ) : journey.skin === "memory" ? (
                <button onClick={() => navigate(`/j/${journey.id}/camera`)}>
                  <OIcon name="camera" size={22} weight="bold" />
                  HÔM NAY · chạm để chụp
                </button>
              ) : journey.skin === "squad" ? (
                <>
                  <OIcon name="trophy" size={54} weight="duotone" />
                  <span>0/5 HÔM NAY</span>
                </>
              ) : (
                <span />
              )}
            </div>
            <h1>{copy.day}</h1>
            {journey.shared && (
              <button
                className="scenario-invite"
                onClick={() => store.setInviteSheetOpen(true)}
              >
                <OIcon name="squad" size={18} weight="bold" /> Mời bạn
              </button>
            )}
          </div>
        )}
        {state === "only" && (
          <div className="scenario-only">
            <h1>{copy.only}</h1>
            <div className="scenario-only-grid">
              <article>
                <span>L</span>
                <b>Bạn · 07:12</b>
                <OIcon name="check" size={18} weight="bold" />
              </article>
              <button onClick={() => store.setInviteSheetOpen(true)}>
                <OIcon name="plus" size={22} weight="bold" />
                Mời bạn
              </button>
            </div>
          </div>
        )}
        {state === "broken" && (
          <div className="scenario-broken">
            <span>0</span>
            <h1>{copy.broken}</h1>
            <p>chuỗi dài nhất {journey.streak}</p>
          </div>
        )}
        {state === "hidden" && (
          <div className="scenario-hidden-wrap">
            <button
              className={`scenario-hidden hidden-${journey.skin}`}
              onClick={() =>
                showToast(
                  store.blocked.length
                    ? "Bạn đã chặn người này."
                    : "Bạn đã báo cáo ảnh này.",
                )
              }
            >
              <OIcon name="eye-off" size={28} weight="bold" />
              <b>Ảnh đã ẩn</b>
              <span>
                {store.blocked.length
                  ? "Bạn đã chặn người này."
                  : "Bạn đã báo cáo ảnh này."}
              </span>
            </button>
            <div className="scenario-hidden-meta">
              <span>
                {journey.skin === "couple"
                  ? (journey.members
                      ?.find((name) => name !== "Linh")
                      ?.slice(0, 1) ?? "N")
                  : "M"}
              </span>
              <b>
                {journey.skin === "couple"
                  ? (journey.members?.find((name) => name !== "Linh") ?? "Nam")
                  : "Minh"}
              </b>
              <small>07:12</small>
            </div>
          </div>
        )}
      </main>
      {toast && <div className="system-toast">{toast}</div>}
    </ScreenShell>
  )
}

const libraryPhotos = [
  { id: "old-1", date: "2024-04-12", label: "12 THG 4, 2024" },
  { id: "old-2", date: "2024-04-12", label: "12 THG 4, 2024" },
  { id: "old-3", date: "2024-04-15", label: "15 THG 4, 2024" },
  { id: "old-4", date: "2024-04-18", label: "18 THG 4, 2024" },
  { id: "old-5", date: undefined, label: "Không có ngày" },
  { id: "old-6", date: "2024-04-20", label: "20 THG 4, 2024" },
]

function ImportJourneyFlow() {
  const store = useStore()
  const navigate = useNavigate()
  const params = useParams()
  const source = store.journeys.find((journey) => journey.id === params.id)
  const [stage, setStage] = useState<"setup" | "library" | "review">("setup")
  const [type, setType] = useState<Journey["type"]>(source?.type ?? "Chuyến đi")
  const [skin, setSkin] = useState(source?.skin ?? "memory")
  const [selected, setSelected] = useState<string[]>([
    "old-1",
    "old-4",
    "old-5",
    "old-6",
  ])
  const [assignments, setAssignments] = useState<Record<string, string>>({})
  const [startDate, setStartDate] = useState("2024-04-12")
  const [endDate, setEndDate] = useState("2024-04-20")
  const [continues, setContinues] = useState(false)
  const [place, setPlace] = useState(
    source?.lastPlace ?? (source ? source.name : "Hành trình đã qua"),
  )
  const selectedPhotos = libraryPhotos
    .filter((photo) => selected.includes(photo.id))
    .map((photo) => ({ ...photo, date: assignments[photo.id] ?? photo.date }))
  const dated = selectedPhotos.filter((photo) => photo.date)
  const undated = selectedPhotos.filter((photo) => !photo.date)
  const reviewDays = dateDayOffset(startDate, endDate)
  const availableImportLayouts = layoutOptions.filter(([id]) => {
    if (id === "memory" || id === "minimal") return true
    if (id === "quiet") return type === "Giảm cân"
    if (id === "flexer") return type === "Tập luyện"
    return false
  })

  useEffect(() => {
    const dates = selectedPhotos
      .map((photo) => photo.date)
      .filter(Boolean)
      .sort() as string[]
    if (dates.length) {
      setStartDate(dates[0])
      setEndDate(dates[dates.length - 1])
    }
  }, [selected.join("|"), Object.values(assignments).join("|")])

  useEffect(() => {
    if (!availableImportLayouts.some(([id]) => id === skin)) setSkin("memory")
  }, [type, skin])

  if (source && (source.members?.length ?? 0) > 2) {
    return <Navigate replace to={`/j/${source.id}/edit`} />
  }

  function saveImport() {
    const photos = dated.map((photo) => ({
      id: photo.id,
      date: photo.date,
      day: dateDayOffset(startDate, photo.date),
    }))
    const id = store.addImportedJourney({
      type,
      skin,
      photos,
      startDate,
      endDate,
      place,
      totalDays: dateDayOffset(startDate, endDate),
      archived:
        !continues &&
        Boolean(endDate) &&
        new Date(`${endDate}T23:59:59`).getTime() < Date.now(),
    })
    navigate(continues ? `/j/${id}` : `/j/${id}/wrapped`, { replace: true })
  }

  return (
    <section className={`import-flow import-skin-${skin}`}>
      <PushedHeader
        title="nhập hành trình cũ."
        onBack={() =>
          stage === "setup"
            ? navigate(-1)
            : setStage(stage === "review" ? "library" : "setup")
        }
      />
      <main>
        {stage === "setup" && (
          <>
            <h1>Chọn loại và giao diện.</h1>
            <div className="import-type-grid">
              {([
                "Giảm cân",
                "Tiếng Anh",
                "Chuyến đi",
                "Cặp đôi",
                "Tập luyện",
                "Tự đặt",
              ] as Journey["type"][]).map((item) => (
                <button
                  key={item}
                  className={type === item ? "selected" : ""}
                  onClick={() => setType(item)}
                >
                  <TypeBadge type={item} size={36} />
                  {item}
                </button>
              ))}
            </div>
            <label className="import-place-field">
              <span>Tên hoặc địa điểm</span>
              <input
                value={place}
                onChange={(event) => setPlace(event.target.value)}
                placeholder="Hành trình đã qua"
              />
            </label>
            <h2>Giao diện</h2>
            <div className="import-layout-grid">
              {availableImportLayouts.map(([id, label]) => (
                <button
                  key={id}
                  className={skin === id ? "selected" : ""}
                  onClick={() => setSkin(id)}
                >
                  <LayoutPreview skin={id} />
                  <span>{label}</span>
                </button>
              ))}
            </div>
            <p className="edit-layout-note">
              Một số giao diện cần thêm dữ liệu nên không hiện.
            </p>
            <button
              className="import-primary"
              onClick={() => setStage("library")}
            >
              Chọn ảnh cũ
            </button>
          </>
        )}
        {stage === "library" && (
          <>
            <h1>Chọn ảnh cũ.</h1>
            <p className="import-intro">
              Chọn nhiều ảnh. Ourney đọc ngày chụp để xếp vào hành trình.
            </p>
            <div className="import-photo-grid">
              {libraryPhotos.map((photo, index) => {
                const active = selected.includes(photo.id)
                return (
                  <button
                    key={photo.id}
                    className={active ? "selected" : ""}
                    onClick={() =>
                      setSelected((current) =>
                        active
                          ? current.filter((id) => id !== photo.id)
                          : [...current, photo.id],
                      )
                    }
                    aria-pressed={active}
                    aria-label={`${
                      active ? "Bỏ chọn" : "Chọn"
                    } ảnh ${photo.label}`}
                  >
                    <span className={`library-scene scene-${index + 1}`} />
                    <small>{photo.label}</small>
                    {active && (
                      <i>
                        <OIcon name="check" size={15} weight="bold" />
                      </i>
                    )}
                  </button>
                )
              })}
            </div>
            <button
              className="import-primary"
              disabled={!selected.length}
              onClick={() => setStage("review")}
            >
              Xem lại {selected.length} ảnh
            </button>
          </>
        )}
        {stage === "review" && (
          <>
            <h1>Xem lại trong dòng thời gian.</h1>
            <div className={`import-timeline timeline-${skin}`}>
              {Array.from({ length: reviewDays }, (_, index) => index + 1).map(
                (day) => {
                  const photos = dated.filter(
                    (photo) => dateDayOffset(startDate, photo.date) === day,
                  )
                  if (!photos.length) {
                    return (
                      <article className="import-empty-day" key={day}>
                        <span />
                        <div>
                          <b>Ngày {day}</b>
                          <small>Chưa có ảnh</small>
                        </div>
                      </article>
                    )
                  }
                  return photos.map((photo, photoIndex) => (
                    <article className="imported" key={photo.id}>
                      <span
                        className={`library-scene scene-${libraryPhotos.findIndex((item) => item.id === photo.id) + 1}`}
                      />
                      <div>
                        <b>Ngày {day}</b>
                        <small>
                          {formatJourneyDate(photo.date)} · từ thư viện
                        </small>
                        {photoIndex > 0 && <em>ảnh thêm trong ngày</em>}
                      </div>
                    </article>
                  ))
                },
              )}
            </div>
            {undated.length > 0 && (
              <section className="import-undated">
                <h2>Chưa có ngày</h2>
                {undated.map((photo) => (
                  <div key={photo.id}>
                    <span className="library-scene scene-5" />
                    <label>
                      Gán ngày
                      <input
                        type="date"
                        onChange={(event) =>
                          setAssignments((current) => ({
                            ...current,
                            [photo.id]: event.target.value,
                          }))
                        }
                      />
                    </label>
                    <button
                      onClick={() =>
                        setSelected((current) =>
                          current.filter((id) => id !== photo.id),
                        )
                      }
                    >
                      Bỏ
                    </button>
                  </div>
                ))}
              </section>
            )}
            <div className="import-date-range">
              <label>
                Bắt đầu
                <input
                  type="date"
                  value={startDate}
                  onChange={(event) => setStartDate(event.target.value)}
                />
              </label>
              <label>
                Kết thúc
                <input
                  type="date"
                  value={endDate}
                  onChange={(event) => setEndDate(event.target.value)}
                />
              </label>
            </div>
            <label className="import-continue">
              <input
                type="checkbox"
                checked={continues}
                onChange={(event) => setContinues(event.target.checked)}
              />
              <span>
                <b>Chụp tiếp</b>
                Chuỗi bắt đầu từ ảnh chụp thật đầu tiên; ảnh nhập không tính
                chuỗi.
              </span>
            </label>
            {type === "Giảm cân" && (
              <p className="import-private-note">
                <OIcon name="lock" size={15} weight="fill" /> Số kg vẫn ẩn và
                ảnh vẫn làm mờ khi chia sẻ.
              </p>
            )}
            <button
              className="import-primary"
              disabled={!dated.length || undated.length > 0}
              onClick={saveImport}
            >
              Lưu hành trình
            </button>
          </>
        )}
      </main>
    </section>
  )
}

function ImportedJourneyHome({ journey }: { journey: Journey }) {
  const navigate = useNavigate()
  const totalDays = journeyLength(journey)
  return (
    <ScreenShell
      bare
      className={`imported-journey-home imported-${journey.skin}`}
    >
      <PushedHeader
        title={journey.name}
        onBack={() => navigate("/hub")}
        action={
          <button
            onClick={() => navigate(`/j/${journey.id}/edit`)}
            aria-label="Sửa"
          >
            <OIcon name="settings" size={20} />
          </button>
        }
      />
      <main>
        <div className="imported-summary">
          <b>
            {formatJourneyDate(journey.startDate)} –{" "}
            {formatJourneyDate(journey.endDate)}
          </b>
          <span>Chuỗi 0 · ảnh nhập không tính chuỗi</span>
        </div>
        <div className="import-timeline">
          {Array.from({ length: totalDays }, (_, index) => index + 1).map(
            (day) => {
              const photos =
                journey.importedPhotos?.filter((photo) => photo.day === day) ??
                []
              if (!photos.length) {
                return (
                  <article className="import-empty-day" key={day}>
                    <span />
                    <div>
                      <b>Ngày {day}</b>
                      <small>Chưa có ảnh</small>
                    </div>
                  </article>
                )
              }
              const photo = photos[0]
              return (
                <article key={day} className="imported">
                  <DayPhotoStack journey={journey} day={day}>
                    <span className={`library-scene scene-${(day % 6) + 1}`} />
                  </DayPhotoStack>
                  <div>
                    <b>Ngày {day}</b>
                    <small>
                      {formatJourneyDate(photo.date)} · từ thư viện ·{" "}
                      {photos.length} ảnh
                    </small>
                  </div>
                </article>
              )
            },
          )}
          {journey.todayDone && (
            <article className="captured">
              <span className="captured-scene">
                <OIcon name="camera" size={24} weight="bold" />
              </span>
              <div>
                <b>Ảnh chụp mới</b>
                <small>ảnh chụp thật · bắt đầu chuỗi</small>
              </div>
            </article>
          )}
        </div>
        <button
          className="import-primary"
          onClick={() => navigate(`/j/${journey.id}/camera`)}
        >
          <OIcon name="camera" size={18} weight="bold" /> Chụp tiếp
        </button>
      </main>
    </ScreenShell>
  )
}

function ImportedJourneyShare({ journey }: { journey: Journey }) {
  const navigate = useNavigate()
  const [shareOpen, setShareOpen] = useState(false)
  const [hideBrand, setHideBrand] = useState(false)
  return (
    <section className={`journey-pushed imported-share pushed-${journey.skin}`}>
      <PushedHeader title="chia sẻ hành trình." onBack={() => navigate(-1)} />
      <main>
        <h1>{journey.name}</h1>
        <p>
          {journeyLength(journey)} ngày · {journey.importedPhotos?.length ?? 0}{" "}
          ảnh
        </p>
        <small>
          {formatJourneyDate(journey.startDate)} –{" "}
          {formatJourneyDate(journey.endDate)}
        </small>
        <div className="imported-share-grid">
          {journey.importedPhotos?.map((photo, index) => (
            <span
              key={photo.id}
              className={`library-scene scene-${(index % 6) + 1}`}
              aria-label={`Ngày ${photo.day}, ${formatJourneyDate(photo.date)}`}
            />
          ))}
          {!hideBrand && <Wordmark size={56} className="share-brand" />}
        </div>
        <button className="import-primary" onClick={() => setShareOpen(true)}>
          <OIcon name="share" size={18} weight="bold" /> Chia sẻ
        </button>
      </main>
      <JourneyActionSheet
        open={shareOpen}
        title="chia sẻ hành trình."
        onClose={() => setShareOpen(false)}
      >
        <button
          className="sheet-secondary share-brand-toggle"
          onClick={() => setHideBrand(!hideBrand)}
        >
          <OIcon name={hideBrand ? "eye-off" : "eye"} size={20} />
          Ẩn chữ ourney
          <span>{hideBrand ? "Bật" : "Tắt"}</span>
        </button>
        <button className="sheet-primary" onClick={() => setShareOpen(false)}>
          Tin nhắn
        </button>
        <button className="sheet-secondary" onClick={() => setShareOpen(false)}>
          Ứng dụng khác
        </button>
      </JourneyActionSheet>
    </section>
  )
}

function AdaptiveJourneyVisual({
  journey,
  index = 0,
}: {
  journey: Journey
  index?: number
}) {
  return (
    <span
      className={`adaptive-visual adaptive-visual-${journey.skin} visual-${index % 4}`}
      role="img"
      aria-label={`Ảnh ${journey.name}, ngày ${Math.max(1, journey.day - index)}`}
    >
      <i>
        <TypeBadge type={journey.type} size={38} />
      </i>
    </span>
  )
}

function AdaptiveJourneyScreen({
  journey,
  mode,
}: {
  journey: Journey
  mode: "home" | "post" | "done" | "squad" | "share" | "day"
}) {
  const store = useStore()
  const navigate = useNavigate()
  const params = useParams()
  const [caption, setCaption] = useState(journey.lastCaption ?? "")
  const [toast, setToast] = useState("")
  const [hideBrand, setHideBrand] = useState(journey.skin === "quiet")
  const total = journeyLength(journey)
  const members = journey.members ?? []
  const attendance = Math.min(journey.attendance ?? 0, members.length)
  const title = journeyDisplayTitle(journey)
  const metric = journeyMetric(journey)
  const rows = journeyTimelineRows(journey)
  const numericDay = Number(params.day ?? journey.day)

  function header(back = false) {
    return (
      <header className={`adaptive-topbar adaptive-${journey.skin}`}>
        <button
          onClick={() => (back ? navigate(-1) : navigate("/hub"))}
          aria-label="Quay lại"
        >
          <OIcon name="back" size={21} weight="bold" />
        </button>
        <b>{title.toLocaleUpperCase("vi")}</b>
        <button
          onClick={() => navigate(`/j/${journey.id}/edit`)}
          aria-label="Cài đặt hành trình"
        >
          <OIcon name="settings" size={20} weight="bold" />
        </button>
      </header>
    )
  }

  if (mode === "post") {
    return (
      <section
        className={`journey-pushed adaptive-page adaptive-${journey.skin}`}
      >
        {header(true)}
        <main className="adaptive-post">
          <AdaptiveJourneyVisual journey={journey} />
          <h1>{journey.name}</h1>
          <p>{metric}</p>
          <label>
            <span>Ghi lại một dòng</span>
            <textarea
              maxLength={140}
              value={caption}
              onChange={(event) => setCaption(event.target.value)}
            />
          </label>
          <button
            className="adaptive-primary"
            onClick={() => {
              const result = store.checkInJourney(journey.id, {
                caption,
                mood: "",
                minutes: journey.lastMinutes,
                km: journey.totalKm !== undefined ? journey.lastKm : undefined,
                pace: journey.totalKm !== undefined ? journey.pace : undefined,
              })
              if (result.first) {
                navigate(`/j/${journey.id}/done`, { replace: true })
              } else {
                store.showToast(`Đã thêm ảnh thứ ${result.count} hôm nay`)
                navigate(`/j/${journey.id}/camera`, { replace: true })
              }
            }}
          >
            Lưu check-in
          </button>
        </main>
      </section>
    )
  }

  if (mode === "done") {
    return (
      <section
        className={`journey-pushed adaptive-page adaptive-done adaptive-${journey.skin}`}
        onClick={() => navigate(`/j/${journey.id}`, { replace: true })}
      >
        <OIcon name="check" size={54} weight="bold" />
        <h1>
          NGÀY {journey.day}/{total}
        </h1>
        <p className="icon-text">
          {journey.name} · Chuỗi <StreakValue count={journey.streak} />
        </p>
      </section>
    )
  }

  if (mode === "squad") {
    return (
      <ScreenShell
        bare
        className={`adaptive-journey-screen adaptive-${journey.skin}`}
      >
        {header(true)}
        <main className="adaptive-members">
          <h1>{journey.name}</h1>
          {members.length >= 2 && (
            <div className="adaptive-attendance">
              {attendance}/{members.length} {journeyAttendanceVerb(journey)}
            </div>
          )}
          {members.map((member, index) => (
            <article key={member}>
              <span>{member.slice(0, 1)}</span>
              <div>
                <b>{member}</b>
                <small>
                  {index < attendance
                    ? journeyAttendanceVerb(journey)
                    : "CHƯA CHECK-IN"}
                </small>
              </div>
              <AdaptiveJourneyVisual journey={journey} index={index} />
            </article>
          ))}
        </main>
      </ScreenShell>
    )
  }

  if (mode === "share") {
    return (
      <section
        className={`journey-pushed adaptive-page adaptive-${journey.skin}`}
      >
        {header(true)}
        <main className="adaptive-share">
          <div>
            <h1>{journey.name}</h1>
            <b>
              NGÀY {journey.day}/{total}
            </b>
            <AdaptiveJourneyVisual journey={journey} />
            <p>{metric}</p>
            <small className="icon-text">
              Chuỗi <StreakValue count={journey.streak} />
            </small>
            {!hideBrand && <Wordmark size={56} className="share-brand" />}
          </div>
          <button
            className="adaptive-brand-toggle"
            onClick={() => setHideBrand(!hideBrand)}
          >
            <OIcon name={hideBrand ? "eye-off" : "eye"} size={18} />
            Ẩn chữ ourney · {hideBrand ? "Bật" : "Tắt"}
          </button>
          <button
            className="adaptive-primary"
            onClick={() => {
              setToast("Thiệp đã sẵn sàng.")
              window.setTimeout(() => setToast(""), 1600)
            }}
          >
            <OIcon name="share" size={18} weight="bold" /> Tạo thiệp
          </button>
        </main>
        {toast && <div className="system-toast">{toast}</div>}
      </section>
    )
  }

  if (mode === "day") {
    return (
      <section
        className={`journey-pushed adaptive-page adaptive-${journey.skin}`}
      >
        {header(true)}
        <main className="adaptive-day">
          <AdaptiveJourneyVisual journey={journey} index={numericDay} />
          <h1>
            {journey.name} · NGÀY {numericDay}/{total}
          </h1>
          <b>{metric}</b>
          <p>{journey.lastCaption || `${journey.type} · đã check-in`}</p>
        </main>
      </section>
    )
  }

  return (
    <ScreenShell
      bare
      className={`adaptive-journey-screen adaptive-${journey.skin}`}
    >
      {header()}
      <main className="adaptive-home">
        {members.length >= 2 && (
          <button
            className="adaptive-attendance"
            onClick={() => navigate(`/j/${journey.id}/squad`)}
          >
            {attendance}/{members.length} {journeyAttendanceVerb(journey)}
          </button>
        )}
        <section className="adaptive-summary">
          <h1>{journey.name}</h1>
          <b>{metric}</b>
          <span className="icon-text">
            NGÀY {journey.day}/{total} · <OIcon name="flame" size={16} active />{" "}
            {journey.streak}
          </span>
        </section>
        <section className="adaptive-timeline">
          {rows.map((row, index) => (
            <button
              key={row.day}
              onClick={() =>
                navigate(
                  row.day === journey.day
                    ? `/j/${journey.id}/camera`
                    : `/j/${journey.id}/day/${row.day}`,
                )
              }
            >
              <AdaptiveJourneyVisual journey={journey} index={index} />
              <span>
                <small>
                  NGÀY {row.day}/{total}
                </small>
                <b>{row.label}</b>
                {row.day === journey.day && <em>{metric}</em>}
              </span>
            </button>
          ))}
        </section>
        <button
          className="adaptive-share-button"
          onClick={() => navigate(`/j/${journey.id}/share`)}
        >
          <OIcon name="share" size={18} weight="bold" /> Tạo thiệp
        </button>
      </main>
    </ScreenShell>
  )
}

function JourneyAttachment({
  mode = "home",
}: {
  mode?: "home" | "camera" | "post" | "done" | "squad" | "share" | "day" | "edit" | "wrapped"
}) {
  const store = useStore()
  const params = useParams()
  const journey = store.journeys.find((item) => item.id === params.id)

  useEffect(() => {
    if (journey) store.selectJourney(journey.id)
  }, [journey?.id])

  if (mode === "camera") return <CameraScreen />
  if (
    journey &&
    !journey.imported &&
    hasSwitchedLayout(journey) &&
    mode !== "edit" &&
    mode !== "wrapped"
  ) {
    return (
      <AdaptiveJourneyScreen
        journey={journey}
        mode={
          mode === "post" ||
          mode === "done" ||
          mode === "squad" ||
          mode === "share" ||
          mode === "day"
            ? mode
            : "home"
        }
      />
    )
  }
  if (journey && mode === "day") return <JourneyDayScreen journey={journey} />
  if (journey && mode === "edit") return <JourneyEditScreen journey={journey} />
  if (journey && mode === "wrapped") {
    return <JourneyWrappedScreen journey={journey} />
  }
  if (journey?.imported && mode === "share") {
    return <ImportedJourneyShare journey={journey} />
  }
  if (journey?.imported && journey.archived && mode === "home") {
    return <Navigate replace to={`/j/${journey.id}/wrapped`} />
  }
  if (journey?.imported && mode === "home") {
    return <ImportedJourneyHome journey={journey} />
  }
  if (
    journey &&
    store.journeyDemoState !== "normal" &&
    (mode === "home" || mode === "squad")
  ) {
    return (
      <JourneyScenarioScreen
        journey={journey}
        mode={mode === "squad" ? "squad" : "home"}
      />
    )
  }

  if (journey?.skin === "quiet") {
    if (mode === "post") return <QuietPost journey={journey} />
    if (mode === "done") return <QuietDone journey={journey} />
    if (mode === "squad") {
      return journey.shared ? (
        <QuietSquad journey={journey} />
      ) : (
        <Navigate replace to={`/j/${journey.id}`} />
      )
    }
    if (mode === "share") return <QuietShare journey={journey} />
    return <QuietJourneyHome journey={journey} />
  }

  if (journey?.skin === "squad") {
    if (mode === "post") return <SquadPost journey={journey} />
    if (mode === "done") return <SquadDone journey={journey} />
    if (mode === "squad") return <SquadToday journey={journey} />
    if (mode === "share") return <SquadShare journey={journey} />
    return <SquadJourneyHome journey={journey} />
  }

  if (journey?.skin === "memory") {
    if (mode === "post") return <MemoryPost journey={journey} />
    if (mode === "done") return <MemoryDone journey={journey} />
    if (mode === "squad") return <MemorySquad journey={journey} />
    if (mode === "share") return <MemoryShare journey={journey} />
    return <MemoryJourneyHome journey={journey} />
  }

  if (journey?.skin === "couple") {
    if (mode === "post") return <CouplePost journey={journey} />
    if (mode === "done") return <CoupleDone journey={journey} />
    if (mode === "squad") return <CoupleSquad journey={journey} />
    if (mode === "share") return <CoupleShare journey={journey} />
    return <CoupleJourneyHome journey={journey} />
  }

  if (journey?.skin === "flexer") {
    if (mode === "post") return <FlexerPost journey={journey} />
    if (mode === "done") return <FlexerDone journey={journey} />
    if (mode === "squad") return <FlexerSquad journey={journey} />
    if (mode === "share") return <FlexerShare journey={journey} />
    return <FlexerJourneyHome journey={journey} />
  }

  if (journey?.skin === "minimal") {
    if (mode === "post") return <MinimalPost journey={journey} />
    if (mode === "done") return <MinimalDone journey={journey} />
    if (mode === "squad") return <MinimalSquad journey={journey} />
    if (mode === "share") return <MinimalShare journey={journey} />
    return <MinimalJourneyHome journey={journey} />
  }

  return (
    <ScreenShell
      title={
        journey ? `${journey.name.toLocaleLowerCase("vi")}.` : "hành trình."
      }
      className="journey-owned-screen"
    >
      <div className="profile-placeholder">
        <p>sắp có</p>
      </div>
    </ScreenShell>
  )
}

export const router = createBrowserRouter([
  {
    path: "/style-guide",
    Component: StyleGuide,
  },
  {
    path: "/",
    Component: Root,
    children: [
      { index: true, Component: Entry },
      { path: "camera", Component: CameraScreen },
      { path: "hub", Component: HubScreen },
      { path: "squad", Component: SquadScreen },
      { path: "activity", Component: ActivityScreen },
      { path: "join/:code", Component: JoinScreen },
      { path: "me", Component: ProfileScreen },
      { path: "settings", Component: SettingsScreen },
      { path: "settings/terms", element: <LegalPage kind="terms" /> },
      { path: "settings/privacy", element: <LegalPage kind="privacy" /> },
      { path: "settings/contact", Component: ContactPage },
      { path: "settings/delete/:step", Component: DeleteAccountScreen },
      { path: "splash", Component: SplashFlow },
      { path: "onboarding/:step", Component: OnboardingFlow },
      { path: "login", Component: LoginFlow },
      { path: "otp", Component: OtpFlow },
      { path: "profile-setup", Component: ProfileSetupFlow },
      { path: "create/1", Component: CreateStepOne },
      { path: "create/2/:question", Component: CreateStepTwo },
      { path: "create/3", Component: CreateStepThree },
      { path: "create/3/extra/1", element: <CreateStepThreeExtra page={1} /> },
      { path: "create/3/extra/2", element: <CreateStepThreeExtra page={2} /> },
      { path: "create/4", Component: CreateStepFour },
      { path: "create/5", Component: CreateStepFive },
      { path: "import", Component: ImportJourneyFlow },
      { path: "j/:id", element: <JourneyAttachment /> },
      { path: "j/:id/camera", element: <JourneyAttachment mode="camera" /> },
      { path: "j/:id/post", element: <JourneyAttachment mode="post" /> },
      { path: "j/:id/done", element: <JourneyAttachment mode="done" /> },
      { path: "j/:id/squad", element: <JourneyAttachment mode="squad" /> },
      { path: "j/:id/share", element: <JourneyAttachment mode="share" /> },
      { path: "j/:id/day/:day", element: <JourneyAttachment mode="day" /> },
      { path: "j/:id/edit", element: <JourneyAttachment mode="edit" /> },
      { path: "j/:id/import", Component: ImportJourneyFlow },
      { path: "j/:id/wrapped", element: <JourneyAttachment mode="wrapped" /> },
      { path: "*", Component: NotFound },
    ],
  },
])
