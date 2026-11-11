import {
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
  type CSSProperties,
  type PointerEvent as ReactPointerEvent,
  type ReactNode,
} from "react"
import { useLocation, useNavigate, useParams } from "react-router"
import { OIcon, TypeBadge } from "./icons"
import { PhoneOverlay } from "./overlay"
import { skins } from "../StyleGuide"
import { PermissionSheet } from "./flow"
import { useStore, type Draft, type Journey } from "./store"

type CreateType = {
  type: Journey["type"]
  skin: string
  name: string
  tagline: string
  icon: ReactNode
}

const createTypes: CreateType[] = [
  {
    type: "Giảm cân",
    skin: "quiet",
    name: "Giảm cân",
    tagline: "nhẹ nhàng, chỉ mình bạn thấy.",
    icon: <OIcon name="scales" size={27} weight="duotone" />,
  },
  {
    type: "Tiếng Anh",
    skin: "squad",
    name: "Học tiếng Anh",
    tagline: "điểm danh đủ hội nào!",
    icon: <OIcon name="book" size={27} weight="duotone" />,
  },
  {
    type: "Tập luyện",
    skin: "flexer",
    name: "30 ngày tập luyện",
    tagline: "km. pace. xong.",
    icon: <OIcon name="fitness" size={27} weight="duotone" />,
  },
  {
    type: "Chuyến đi",
    skin: "memory",
    name: "Chuyến đi",
    tagline: "nhớ từng chặng đường.",
    icon: <OIcon name="trip" size={27} weight="duotone" />,
  },
  {
    type: "Cặp đôi",
    skin: "couple",
    name: "Hai đứa mình",
    tagline: "mỗi ngày một cặp ảnh.",
    icon: <OIcon name="heart" size={27} weight="duotone" />,
  },
  {
    type: "Tự đặt",
    skin: "minimal",
    name: "Tự đặt",
    tagline: "chụp.",
    icon: <OIcon name="camera" size={27} weight="duotone" />,
  },
]

function createVariables(skinId: string | undefined, mode: "light" | "dark") {
  if (!skinId) {
    return {
      "--create-bg": mode === "light" ? "#FFF8EE" : "#121212",
      "--create-surface": mode === "light" ? "#FFFFFF" : "#1C1B19",
      "--create-ink": mode === "light" ? "#1A1A1A" : "#F5F0E6",
      "--create-muted": mode === "light" ? "#5A544C" : "#B8B0A4",
      "--create-accent": "#FF8A3D",
      "--create-label": "#1A1A1A",
      "--create-heading": "'Space Grotesk', sans-serif",
    } as CSSProperties
  }
  const skin = skins.find((item) => item.id === skinId) ?? skins[0]
  const palette = skin[mode]
  const variant = skin.variants[0]
  return {
    "--create-bg": palette.bg,
    "--create-surface": palette.surface,
    "--create-ink": palette.ink,
    "--create-muted": palette.muted,
    "--create-accent": variant.button,
    "--create-label": variant.buttonLabel,
    "--create-heading": `'${skin.heading}', 'Be Vietnam Pro', sans-serif`,
  } as CSSProperties
}

function ExitCreateSheet({
  onStay,
  onKeep,
  onDiscard,
}: {
  onStay: () => void
  onKeep: () => void
  onDiscard: () => void
}) {
  const startY = useRef<number | null>(null)
  const [drag, setDrag] = useState(0)
  function dragStart(event: ReactPointerEvent<HTMLDivElement>) {
    startY.current = event.clientY
    event.currentTarget.setPointerCapture(event.pointerId)
  }
  function dragMove(event: ReactPointerEvent<HTMLDivElement>) {
    if (startY.current === null) return
    setDrag(Math.max(0, event.clientY - startY.current))
  }
  function dragEnd() {
    if (drag > 70) onStay()
    setDrag(0)
    startY.current = null
  }
  return (
    <PhoneOverlay>
      <div
        className="create-sheet-scrim"
        onPointerDown={(event) =>
          event.target === event.currentTarget && onStay()
        }
      >
        <div
          className="create-sheet"
          style={{ transform: `translateY(${drag}px)` }}
        >
          <div
            className="create-sheet-drag"
            onPointerDown={dragStart}
            onPointerMove={dragMove}
            onPointerUp={dragEnd}
          >
            <i />
          </div>
          <button
            className="create-sheet-close"
            onClick={onStay}
            aria-label="Đóng"
          >
            <OIcon name="close" size={22} weight="bold" />
          </button>
          <h2>thoát khỏi việc tạo?</h2>
          <p>Bản nháp được lưu trên máy để bạn tiếp tục sau.</p>
          <button className="create-stay" onClick={onKeep}>
            Thoát, giữ bản nháp
          </button>
          <button className="create-exit" onClick={onDiscard}>
            Bỏ bản nháp
          </button>
        </div>
      </div>
    </PhoneOverlay>
  )
}

function CreateFrame({
  step,
  skinId,
  children,
  action,
  actionLabel,
  actionDisabled = false,
  extra,
}: {
  step: number
  skinId?: string
  children: ReactNode
  action?: () => void
  actionLabel?: string
  actionDisabled?: boolean
  extra?: string
}) {
  const store = useStore()
  const navigate = useNavigate()
  const location = useLocation()
  const [exitOpen, setExitOpen] = useState(false)
  const variables = createVariables(skinId, store.theme)

  useEffect(() => {
    store.saveCreateProgress(location.pathname)
  }, [location.pathname])

  function discardAndExit() {
    store.discardCreate()
    setExitOpen(false)
    navigate(store.createOrigin, { replace: true })
  }

  function keepAndExit() {
    store.saveCreateProgress(location.pathname)
    setExitOpen(false)
    navigate(store.createOrigin, { replace: true })
  }

  return (
    <section
      className={`create-flow create-skin-${skinId ?? "shell"} ${
        store.reduceMotion ? "reduce-create-motion" : ""
      }`}
      style={variables}
    >
      <header className="create-topbar">
        <button onClick={() => navigate(-1)} aria-label="Quay lại">
          <OIcon name="back" size={22} weight="bold" />
        </button>
        <div>
          <b>bước {step}/5</b>
          <div className="create-dots" aria-hidden="true">
            {[1, 2, 3, 4, 5].map((dot) => (
              <i
                key={dot}
                className={dot === step ? "current" : dot < step ? "done" : ""}
              />
            ))}
          </div>
          {extra && <span className="create-extra-chip">{extra}</span>}
        </div>
        <button onClick={() => setExitOpen(true)} aria-label="Đóng">
          <OIcon name="close" size={22} weight="bold" />
        </button>
      </header>
      {store.offline && (
        <div className="create-offline-banner">
          <OIcon name="cloud-off" size={20} weight="bold" />
          <span>đang lưu trên máy, có mạng sẽ tự gửi</span>
        </div>
      )}
      <div className="create-content">{children}</div>
      {action && actionLabel && (
        <div className="create-action-wrap">
          <div className="create-action-bar">
            <button disabled={actionDisabled} onClick={action}>
              {actionLabel}
            </button>
          </div>
        </div>
      )}
      {exitOpen && (
        <ExitCreateSheet
          onStay={() => setExitOpen(false)}
          onKeep={keepAndExit}
          onDiscard={discardAndExit}
        />
      )}
    </section>
  )
}

function PreviewCard({ item }: { item: CreateType }) {
  return (
    <div className={`create-preview preview-${item.skin}`}>
      <div className="preview-card-top">
        <TypeBadge type={item.type} size={40} />
        <b>{item.name}</b>
      </div>
      <div className="preview-live-area">
        {item.skin === "quiet" && (
          <>
            <span className="preview-curve" />
            <div className="preview-nodes">
              <i />
              <i />
              <i />
            </div>
            <span className="preview-private">
              <OIcon name="lock" size={15} weight="bold" /> Riêng tư
            </span>
          </>
        )}
        {item.skin === "squad" && (
          <div className="preview-path">
            <i />
            <i />
            <i />
            <OIcon name="trophy" size={22} active />
          </div>
        )}
        {item.skin === "flexer" && <span className="preview-neon-line" />}
        {item.skin === "memory" && (
          <div className="preview-polaroid">
            <OIcon name="pine" size={26} />
            <i />
          </div>
        )}
        {item.skin === "couple" && (
          <div className="preview-diptych">
            <i />
            <OIcon name="heart" size={20} active />
            <i />
          </div>
        )}
        {item.skin === "minimal" && <span className="preview-seven-grid" />}
      </div>
      <div className="preview-hud">
        {item.skin === "quiet" && (
          <span className="ghost-body">
            <OIcon name="ghost-body" size={28} />
          </span>
        )}
        {item.skin === "squad" && (
          <span className="icon-text">
            <OIcon name="book" size={14} /> 45 PHÚT
            <OIcon name="flame" size={14} active /> 21
          </span>
        )}
        {item.skin === "flexer" && <span>5,2 KM · 5:48</span>}
        {item.skin === "memory" && <span>CUỘN PHIM 12/24</span>}
        {item.skin === "couple" && <span>hai nửa · một ngày</span>}
        {item.skin === "minimal" && <span className="mini-shutter" />}
      </div>
      <p>{item.tagline}</p>
    </div>
  )
}

export function CreateStepOne() {
  const store = useStore()
  const navigate = useNavigate()
  const initial = Math.max(
    0,
    createTypes.findIndex((item) => item.type === store.draft.type),
  )
  const [focused, setFocused] = useState(initial)
  const deckRef = useRef<HTMLDivElement | null>(null)
  const pointerStartX = useRef(0)
  const deckDragged = useRef(false)
  const item = createTypes[focused]
  const onboardingPrefilled =
    store.draft.fromOnboarding && store.draft.type === item.type

  useLayoutEffect(() => {
    if (!store.draft.fromOnboarding) return
    const selectedIndex = createTypes.findIndex(
      (type) => type.type === store.draft.type,
    )
    if (selectedIndex < 0) return
    setFocused(selectedIndex)
    deckRef.current?.children[selectedIndex]?.scrollIntoView({
      behavior: "auto",
      inline: "center",
      block: "nearest",
    })
  }, [store.draft.fromOnboarding, store.draft.type])

  function focusCard(index: number) {
    const next = Math.max(0, Math.min(createTypes.length - 1, index))
    setFocused(next)
    deckRef.current?.children[next]?.scrollIntoView({
      behavior: store.reduceMotion ? "auto" : "smooth",
      inline: "center",
      block: "nearest",
    })
  }

  function chooseType(next: CreateType) {
    const keepOnboardingSkin =
      store.draft.fromOnboarding && store.draft.type === next.type
    store.setDraft({
      type: next.type,
      skin: keepOnboardingSkin ? store.draft.skin : next.skin,
      fromOnboarding: keepOnboardingSkin,
    })
    navigate("/create/2/1")
  }

  function choose() {
    chooseType(item)
  }

  return (
    <CreateFrame
      step={1}
      skinId={onboardingPrefilled ? store.draft.skin : item.skin}
      action={choose}
      actionLabel={onboardingPrefilled ? "Tiếp tục" : "Chọn kiểu này"}
    >
      <div className="create-heading">
        {store.draft.fromOnboarding && store.onboardingChoice && (
          <div className="onboarding-create-summary">
            <span>Từ câu trả lời của bạn:</span>
            <b>
              {store.onboardingChoice.type} ·{" "}
              {store.onboardingChoice.who === "group"
                ? "Rủ hội bạn"
                : store.onboardingChoice.who === "couple"
                  ? "Chỉ hai đứa"
                  : "Một mình"}{" "}
              · Nhắc {store.onboardingChoice.reminder}
            </b>
            <button onClick={() => navigate("/onboarding/1")}>Sửa</button>
          </div>
        )}
        <h1>tạo hành trình.</h1>
        <p>
          {store.draft.fromOnboarding
            ? "đã chọn sẵn theo câu trả lời lúc đầu. vuốt nếu muốn đổi."
            : "vuốt để xem, chạm để chọn."}
        </p>
      </div>
      <div
        ref={deckRef}
        className="create-deck"
        onPointerDown={(event) => {
          pointerStartX.current = event.clientX
          deckDragged.current = false
        }}
        onPointerMove={(event) => {
          if (Math.abs(event.clientX - pointerStartX.current) > 8) {
            deckDragged.current = true
          }
        }}
        onScroll={(event) => {
          const cards = Array.from(
            event.currentTarget.children,
          ) as HTMLElement[]
          const center =
            event.currentTarget.scrollLeft + event.currentTarget.clientWidth / 2
          let nearest = 0
          let distance = Number.POSITIVE_INFINITY
          cards.forEach((card, index) => {
            const cardCenter = card.offsetLeft + card.offsetWidth / 2
            const nextDistance = Math.abs(cardCenter - center)
            if (nextDistance < distance) {
              distance = nextDistance
              nearest = index
            }
          })
          if (nearest !== focused) setFocused(nearest)
        }}
      >
        {createTypes.map((type, index) => (
          <button
            key={type.type}
            className={`create-deck-card ${focused === index ? "focused" : ""}`}
            onClick={() => {
              if (!deckDragged.current) chooseType(type)
            }}
            aria-label={`Thẻ ${index + 1} trên 6, ${type.name}`}
          >
            <PreviewCard item={type} />
            {focused === index && (
              <span className="create-focused-badge">
                <OIcon name="check" size={15} weight="bold" /> Đã chọn
              </span>
            )}
          </button>
        ))}
      </div>
      <div className="deck-controls">
        <button
          onClick={() => focusCard(focused - 1)}
          disabled={focused === 0}
          aria-label="Thẻ trước"
        >
          <OIcon name="back" size={20} weight="bold" />
        </button>
        <span>{focused + 1}/6</span>
        <button
          onClick={() => focusCard(focused + 1)}
          disabled={focused === createTypes.length - 1}
          aria-label="Thẻ sau"
        >
          <OIcon name="caret-right" size={20} weight="bold" />
        </button>
      </div>
      <button
        className="create-import-link"
        onClick={() => navigate("/import")}
      >
        Nhập hành trình đã qua
      </button>
      <p className="sr-only">
        Thẻ {focused + 1} trên 6, {item.name}
      </p>
    </CreateFrame>
  )
}

const questionSets: Partial<Record<Journey["type"], Array<{
  title: string
  key: string
  choices: Array<[string, string]>
  compact?: boolean
}>>> = {
  "Giảm cân": [
    {
      title: "mục tiêu của bạn.",
      key: "goal",
      choices: [
        ["Giảm cân", "nhẹ đi, khỏe hơn mỗi ngày"],
        ["Giữ dáng", "duy trì nhịp sống hiện tại"],
        ["Thay đổi vóc dáng", "theo dõi một phiên bản mới"],
      ],
    },
  ],
  "Tiếng Anh": [
    {
      title: "mục tiêu.",
      key: "goal",
      choices: [
        ["IELTS", "cùng nhau chạm band mục tiêu"],
        ["Giao tiếp", "nói tự nhiên hơn mỗi ngày"],
        ["Đọc sách", "đọc trọn cuốn sách đầu tiên"],
      ],
    },
    {
      title: "mỗi ngày bao nhiêu phút.",
      key: "minutes",
      compact: true,
      choices: ["15", "30", "45", "60"].map((value) => [
        value,
        `${value} phút mỗi ngày`,
      ]),
    },
  ],
  "Tập luyện": [
    {
      title: "môn gì.",
      key: "sport",
      compact: true,
      choices: ["Chạy", "Gym", "Pilates", "Yoga", "Khác"].map((value) => [
        value,
        `30 ngày ${value.toLocaleLowerCase("vi")}`,
      ]),
    },
    {
      title: "đo bằng gì.",
      key: "measure",
      choices: ["km", "phút", "buổi"].map((value) => [
        value,
        `ghi lại theo ${value}`,
      ]),
    },
    {
      title: "kiểu HUD.",
      key: "hud",
      choices: [
        ["HUD đậm", "số lớn, tương phản mạnh"],
        ["Tem tối giản", "gọn như một con tem"],
        ["Dải phim", "khoảnh khắc nối tiếp nhau"],
      ],
    },
  ],
  "Chuyến đi": [
    {
      title: "cuộn phim mấy tấm.",
      key: "film",
      choices: [
        ["24 tấm", "mỗi tấm đều được cân nhắc"],
        ["36 tấm", "thêm chỗ cho điều bất ngờ"],
      ],
    },
  ],
  "Cặp đôi": [
    {
      title: "nghi thức của hai đứa.",
      key: "ritual",
      choices: ["Nấu ăn", "Tiết kiệm", "Yêu xa", "Tự đặt"].map((value) => [
        value,
        `cùng nhau ${value.toLocaleLowerCase("vi")}`,
      ]),
    },
  ],
}

function InlineDateRange({
  value,
  onChange,
}: {
  value: string
  onChange: (value: string) => void
}) {
  const [start, setStart] = useState(value ? 16 : 0)
  const [end, setEnd] = useState(value ? 20 : 0)
  return (
    <div className="inline-calendar">
      <div className="calendar-month">
        <b>Tháng 10</b>
        <span>2025</span>
      </div>
      <div className="calendar-week">
        {["T2", "T3", "T4", "T5", "T6", "T7", "CN"].map((day) => (
          <span key={day}>{day}</span>
        ))}
        {Array.from({ length: 31 }, (_, index) => index + 1).map((day) => {
          const selected = day === start || day === end
          const between = start && end && day > start && day < end
          return (
            <button
              key={day}
              className={`${selected ? "selected" : ""} ${
                between ? "between" : ""
              }`}
              onClick={() => {
                if (!start || end) {
                  setStart(day)
                  setEnd(0)
                  onChange("")
                } else {
                  const nextEnd = Math.max(start, day)
                  setEnd(nextEnd)
                  onChange(`${start}–${nextEnd}/10`)
                }
              }}
              aria-pressed={selected}
            >
              {day}
            </button>
          )
        })}
      </div>
      <button
        className="text-button"
        onClick={() => {
          setEnd(start)
          onChange(`${start || 16}/10 · chưa hẹn ngày về`)
        }}
      >
        chưa hẹn ngày về
      </button>
      <p>{value || "Chọn ngày đi và ngày về"}</p>
    </div>
  )
}

export function CreateStepTwo() {
  const store = useStore()
  const navigate = useNavigate()
  const { question = "1" } = useParams()
  const q = Number(question)
  const type = store.draft.type ?? "Tự đặt"
  const answers = store.draft.answers ?? {}
  const setAnswer = (key: string, value: string | number | boolean) =>
    store.setDraft({ answers: { ...answers, [key]: value } })
  const next = () =>
    navigate(type === "Tự đặt" || q === 3 ? "/create/3" : `/create/2/${q + 1}`)

  let title = ""
  let body: ReactNode
  let ready = true
  let actionLabel = "Tiếp tục"
  let action = next
  let definition = questionSets[type]?.[q - 1]
  if (type === "Chuyến đi") {
    definition = q === 3 ? questionSets["Chuyến đi"]?.[0] : undefined
  }

  if (definition) {
    title = definition.title
    ready = Boolean(answers[definition.key])
    body = (
      <div
        className={`step-two-options ${definition.compact ? "compact" : ""}`}
      >
        {definition.choices.map(([label, hint]) => {
          const selected = answers[definition!.key] === label
          return (
            <button
              key={label}
              className={`step-two-card ${selected ? "selected" : ""}`}
              onClick={() => setAnswer(definition!.key, label)}
              aria-pressed={selected}
            >
              <span className="step-two-sticker">{label.slice(0, 1)}</span>
              <span>
                <b>{label}</b>
                <small>{hint}</small>
              </span>
              {selected && <OIcon name="check" size={20} weight="bold" />}
            </button>
          )
        })}
      </div>
    )
  } else if (type === "Giảm cân" && q === 2) {
    title = "cân nặng hiện tại."
    const weight = Number(answers.weight ?? 70)
    body = (
      <div className="weight-question">
        <div>
          <output>{weight}</output>
          <span>kg</span>
        </div>
        <input
          type="range"
          min="40"
          max="120"
          value={weight}
          onChange={(event) => setAnswer("weight", Number(event.target.value))}
          aria-label="Cân nặng hiện tại"
        />
        <div className="range-ends">
          <span>40</span>
          <span>120 kg</span>
        </div>
        <span className="privacy-chip">
          <OIcon name="lock" size={17} weight="fill" /> Chỉ mình bạn thấy
        </span>
        <label className="private-toggle">
          <span>Ẩn số kg khi chia sẻ</span>
          <input
            type="checkbox"
            defaultChecked
            onChange={(event) => setAnswer("hideWeight", event.target.checked)}
          />
        </label>
        <button className="text-button" onClick={next}>
          Bỏ qua
        </button>
      </div>
    )
    action = () => {
      if (answers.weight === undefined) setAnswer("weight", weight)
      next()
    }
  } else if (type === "Giảm cân") {
    title = "chụp ảnh ngày 1 làm khung căn dáng."
    body = (
      <div className="ghost-capture">
        <div className="ghost-silhouette-large" />
        <p>Ảnh riêng tư này sẽ làm khung căn dáng ở những ngày tiếp theo.</p>
        <button className="text-button" onClick={next}>
          Để sau vậy.
        </button>
      </div>
    )
    actionLabel = "Chụp ngay"
    action = () => {
      store.setDraft({
        answers: { ...answers, ghostRequested: true },
      })
      next()
    }
  } else if (type === "Tiếng Anh") {
    title = "đặt tên chiếc cúp ở đích."
    const value = String(answers.trophy ?? "")
    ready = Boolean(value.trim())
    body = (
      <div className="focused-field trophy-field">
        <OIcon name="trophy" size={76} weight="duotone" />
        <b className="live-trophy-name">{value || "Cúp 7.5"}</b>
        <label>
          <span>Tên chiếc cúp</span>
          <input
            autoFocus
            maxLength={24}
            placeholder="Cúp 7.5"
            value={value}
            onChange={(event) => setAnswer("trophy", event.target.value)}
          />
        </label>
        <small>{value.length}/24</small>
      </div>
    )
  } else if (type === "Chuyến đi" && q === 1) {
    title = "đi đâu."
    const place = String(answers.place ?? "")
    ready = Boolean(place)
    body = (
      <div className="place-question">
        <label className="search-place">
          <OIcon name="search" size={20} />
          <input
            autoFocus
            placeholder="Tìm một nơi..."
            value={place}
            onChange={(event) => setAnswer("place", event.target.value)}
          />
        </label>
        {["Đà Lạt", "Hội An", "Phú Quốc"].map((city) => (
          <button
            key={city}
            className={`place-suggestion ${place === city ? "selected" : ""}`}
            onClick={() => setAnswer("place", city)}
          >
            <OIcon name="map-pin" size={21} weight="fill" />
            <span>
              <b>{city}</b>
              <small>Việt Nam</small>
            </span>
            {place === city && <OIcon name="check" size={19} weight="bold" />}
          </button>
        ))}
        {place === "Đà Lạt" && (
          <div className="pine-sticker">
            <span className="pine-icon-row">
              <OIcon name="pine" size={24} />
              <OIcon name="pine" size={29} />
              <OIcon name="pine" size={22} />
            </span>
            <b>Rừng thông và sương</b>
          </div>
        )}
      </div>
    )
  } else if (type === "Chuyến đi") {
    title = "ngày đi – ngày về."
    const value = String(answers.tripDates ?? store.draft.dates ?? "")
    ready = Boolean(value)
    body = (
      <InlineDateRange
        value={value}
        onChange={(dates) =>
          store.setDraft({
            dates,
            answers: { ...answers, tripDates: dates },
          })
        }
      />
    )
  } else if (type === "Cặp đôi" && q === 2) {
    title = "tên hai người."
    ready = Boolean(answers.nameLeft && answers.nameRight)
    body = (
      <div className="step-two-names">
        <input
          autoFocus
          maxLength={18}
          placeholder="Tên bạn"
          value={String(answers.nameLeft ?? "")}
          onChange={(event) => setAnswer("nameLeft", event.target.value)}
        />
        <input
          maxLength={18}
          placeholder="Tên người ấy"
          value={String(answers.nameRight ?? "")}
          onChange={(event) => setAnswer("nameRight", event.target.value)}
        />
      </div>
    )
  } else if (type === "Cặp đôi") {
    title = "ai chụp nửa nào."
    ready = Boolean(answers.side)
    body = (
      <div className="split-previews">
        {["Mình bên trái", "Mình bên phải"].map((label) => (
          <button
            key={label}
            className={answers.side === label ? "selected" : ""}
            onClick={() => setAnswer("side", label)}
          >
            <span>
              <i />
              <i />
            </span>
            <b>{label}</b>
            {answers.side === label && (
              <OIcon name="check" size={20} weight="bold" />
            )}
          </button>
        ))}
      </div>
    )
  } else {
    title = "thói quen của bạn."
    const habit = String(answers.habit ?? "")
    const reason = String(answers.reason ?? "")
    ready = Boolean(habit.trim() && reason.trim())
    body = (
      <div className="minimal-fields">
        <label>
          <span>Thói quen</span>
          <input
            autoFocus
            maxLength={40}
            placeholder="Đọc 10 trang"
            value={habit}
            onChange={(event) => setAnswer("habit", event.target.value)}
          />
          <small>{habit.length}/40</small>
        </label>
        <label>
          <span>vì sao.</span>
          <input
            maxLength={80}
            placeholder="để ngủ ngon hơn"
            value={reason}
            onChange={(event) => setAnswer("reason", event.target.value)}
          />
          <small>{reason.length}/80</small>
        </label>
      </div>
    )
  }

  return (
    <CreateFrame
      step={2}
      skinId={store.draft.skin}
      extra={type === "Tự đặt" ? undefined : `Câu ${q}/3`}
      action={action}
      actionLabel={actionLabel}
      actionDisabled={!ready}
    >
      <div className="create-heading step-two-heading">
        <h1>{title}</h1>
      </div>
      {body}
      {!ready && <p className="answer-required">chọn một đáp án để tiếp tục</p>}
    </CreateFrame>
  )
}

const whoOptions: Array<{
  value: NonNullable<Draft["who"]>
  title: string
  body: string
  icon: ReactNode
}> = [
  {
    value: "solo",
    title: "Một mình",
    body: "chỉ bạn và chiếc máy ảnh.",
    icon: <OIcon name="profile" size={30} weight="duotone" />,
  },
  {
    value: "group",
    title: "Rủ hội",
    body: "tối đa 10 người, mời bằng mã.",
    icon: <OIcon name="squad" size={30} weight="duotone" />,
  },
  {
    value: "couple",
    title: "Chỉ hai đứa",
    body: "một cặp, một nhịp.",
    icon: <OIcon name="heart" size={30} weight="duotone" />,
  },
]

export function CreateStepThree() {
  const store = useStore()
  const navigate = useNavigate()
  const [toast, setToast] = useState(false)
  const originalSkin = store.draft.previousSkin ?? store.draft.skin

  function chooseWho(value: NonNullable<Draft["who"]>) {
    if (
      value === "couple" &&
      store.draft.type !== "Cặp đôi" &&
      store.draft.skin !== "couple"
    ) {
      store.setDraft({
        who: value,
        previousSkin: store.draft.skin,
        skin: "couple",
      })
      setToast(true)
      return
    }
    store.setDraft({
      who: value,
      skin: value === "couple" ? store.draft.skin : originalSkin,
      previousSkin: value === "couple" ? store.draft.previousSkin : undefined,
    })
  }

  function undo() {
    store.setDraft({
      who: undefined,
      skin: store.draft.previousSkin,
      previousSkin: undefined,
      personOne: undefined,
      personTwo: undefined,
      side: undefined,
    })
    setToast(false)
  }

  function next() {
    if (!store.draft.who) return
    if (store.draft.who === "couple" && store.draft.type !== "Cặp đôi") {
      navigate("/create/3/extra/1")
    } else {
      navigate("/create/4")
    }
  }

  return (
    <CreateFrame
      step={3}
      skinId={store.draft.skin}
      action={next}
      actionLabel="Tiếp tục"
      actionDisabled={!store.draft.who}
    >
      <div className="create-heading">
        <h1>đi cùng ai?</h1>
      </div>
      <div className="create-answer-stack">
        {whoOptions.map((option) => {
          const selected = store.draft.who === option.value
          return (
            <button
              key={option.value}
              className={`create-answer-card ${selected ? "selected" : ""}`}
              onClick={() => chooseWho(option.value)}
            >
              <span>{option.icon}</span>
              <div>
                <b>{option.title}</b>
                <small>{option.body}</small>
                {option.value === "group" && (
                  <em>
                    Mã mời có sau khi khởi hành.
                    {store.offline && " Cần có mạng để tạo mã mời."}
                  </em>
                )}
              </div>
              {selected && (
                <i>
                  <OIcon name="check" size={16} weight="bold" /> Đã chọn
                </i>
              )}
            </button>
          )
        })}
      </div>
      {toast && (
        <div className="create-toast">
          <span className="icon-text">
            chuyển sang phong cách Hai đứa mình
            <OIcon name="type-couple" size={18} />
          </span>
          <button onClick={undo}>Hoàn tác</button>
        </div>
      )}
    </CreateFrame>
  )
}

export function CreateStepThreeExtra({ page }: { page: 1 | 2 }) {
  const store = useStore()
  const navigate = useNavigate()
  const ready =
    page === 1
      ? Boolean(store.draft.personOne && store.draft.personTwo)
      : Boolean(store.draft.side)
  return (
    <CreateFrame
      step={3}
      skinId="couple"
      extra={`Thêm ${page}/2`}
      action={() => navigate(page === 1 ? "/create/3/extra/2" : "/create/4")}
      actionLabel="Tiếp tục"
      actionDisabled={!ready}
    >
      <div className="create-heading">
        <h1>{page === 1 ? "tên hai người." : "ai chụp nửa nào?"}</h1>
      </div>
      {page === 1 ? (
        <div className="create-couple-inputs">
          <label>
            <span>Tên bạn</span>
            <input
              value={store.draft.personOne ?? ""}
              onChange={(event) =>
                store.setDraft({ personOne: event.target.value })
              }
            />
          </label>
          <label>
            <span>Tên người ấy</span>
            <input
              value={store.draft.personTwo ?? ""}
              onChange={(event) =>
                store.setDraft({ personTwo: event.target.value })
              }
            />
          </label>
        </div>
      ) : (
        <div className="create-answer-stack">
          {[
            ["left", "Mình bên trái"],
            ["right", "Mình bên phải"],
          ].map(([value, label]) => {
            const selected = store.draft.side === value
            return (
              <button
                key={value}
                className={`create-answer-card ${selected ? "selected" : ""}`}
                onClick={() =>
                  store.setDraft({ side: value as "left" | "right" })
                }
              >
                <span className={`couple-half-icon half-${value}`}>
                  <i />
                  <i />
                </span>
                <div>
                  <b>{label}</b>
                </div>
                {selected && (
                  <i>
                    <OIcon name="check" size={16} weight="bold" /> Đã chọn
                  </i>
                )}
              </button>
            )
          })}
        </div>
      )}
    </CreateFrame>
  )
}

function CalendarSheet({ onClose }: { onClose: () => void }) {
  const store = useStore()
  const startY = useRef<number | null>(null)
  const [drag, setDrag] = useState(0)
  return (
    <PhoneOverlay>
      <div
        className="create-sheet-scrim"
        onPointerDown={(event) =>
          event.target === event.currentTarget && onClose()
        }
      >
        <div
          className="create-sheet calendar-sheet"
          style={{ transform: `translateY(${drag}px)` }}
        >
          <div
            className="create-sheet-drag"
            onPointerDown={(event) => {
              startY.current = event.clientY
              event.currentTarget.setPointerCapture(event.pointerId)
            }}
            onPointerMove={(event) => {
              if (startY.current === null) return
              setDrag(Math.max(0, event.clientY - startY.current))
            }}
            onPointerUp={() => {
              if (drag > 70) onClose()
              startY.current = null
              setDrag(0)
            }}
          >
            <i />
          </div>
          <button
            className="create-sheet-close"
            onClick={onClose}
            aria-label="Đóng"
          >
            <OIcon name="close" size={22} weight="bold" />
          </button>
          <h2>sửa ngày.</h2>
          <InlineDateRange
            value={store.draft.dates ?? ""}
            onChange={(dates) =>
              store.setDraft({
                dates,
                answers: { ...store.draft.answers, tripDates: dates },
              })
            }
          />
          <button
            className="create-stay"
            onClick={onClose}
            disabled={!store.draft.dates}
          >
            Dùng ngày này
          </button>
        </div>
      </div>
    </PhoneOverlay>
  )
}

export function CreateStepFour() {
  const store = useStore()
  const navigate = useNavigate()
  const [calendarOpen, setCalendarOpen] = useState(false)
  const type = store.draft.type
  const group = store.draft.who === "group"
  const couple = store.draft.who === "couple"
  const duration = store.draft.duration ?? 30
  const showDuration = type !== "Chuyến đi"
  const tripDuration = (() => {
    const match = store.draft.dates?.match(/(\d+)[–-](\d+)/)
    return match ? Number(match[2]) - Number(match[1]) + 1 : 1
  })()

  useEffect(() => {
    if (!store.draft.duration && type !== "Chuyến đi") {
      store.setDraft({ duration: 30 })
    }
    if (!store.draft.visibility) {
      store.setDraft({
        visibility: group ? "group" : couple ? "couple" : "private",
      })
    }
  }, [])

  function toggleReminder() {
    const next = !store.draft.reminderEnabled
    store.setDraft({
      reminderEnabled: next,
      reminderTime: store.draft.reminderTime ?? "20:30",
    })
    if (next && !store.notificationPromptHandled) {
      store.setNotificationSheetOpen(true)
    }
  }

  return (
    <CreateFrame
      step={4}
      skinId={store.draft.skin}
      action={() => navigate("/create/5")}
      actionLabel="Đúc hành trình"
    >
      <div className="create-heading">
        <h1>đặt nhịp.</h1>
      </div>
      <div className="rhythm-blocks">
        <section>
          <h2>Thời lượng</h2>
          {showDuration ? (
            <div className="duration-chips">
              {[7, 14, 21, 30, 66].map((days) => {
                const selected = duration === days && !store.draft.noEnd
                return (
                  <button
                    key={days}
                    className={selected ? "selected" : ""}
                    onClick={() =>
                      store.setDraft({
                        duration: days as 7 | 14 | 21 | 30 | 66,
                        noEnd: false,
                      })
                    }
                  >
                    {selected && <OIcon name="check" size={15} weight="bold" />}
                    {days} ngày {selected && <span>Đã chọn</span>}
                  </button>
                )
              })}
              {(type === "Tự đặt" || couple) && (
                <button
                  className={store.draft.noEnd ? "selected" : ""}
                  onClick={() => store.setDraft({ noEnd: true })}
                >
                  {store.draft.noEnd && (
                    <OIcon name="check" size={15} weight="bold" />
                  )}
                  không hẹn ngày về
                  {store.draft.noEnd && <span>Đã chọn</span>}
                </button>
              )}
            </div>
          ) : (
            <div className="trip-date-card">
              <b>
                {String(store.draft.answers?.place ?? "Đà Lạt")} ·{" "}
                {store.draft.dates ?? "16–20/10"} · {tripDuration} ngày
              </b>
              <button onClick={() => setCalendarOpen(true)}>Sửa ngày</button>
            </div>
          )}
        </section>
        <section>
          <div className="reminder-switch-row">
            <div>
              <h2>Giờ nhắc</h2>
              <span>Nhắc mình mỗi ngày</span>
            </div>
            <button
              className={`create-switch ${
                store.draft.reminderEnabled ? "on" : ""
              }`}
              role="switch"
              aria-checked={store.draft.reminderEnabled}
              onClick={toggleReminder}
            >
              <i />
            </button>
          </div>
          {store.draft.reminderEnabled && (
            <div className="time-wheel">
              <button onClick={() => store.setDraft({ reminderTime: "20:30" })}>
                <OIcon name="timer" size={20} weight="bold" /> 20:30
              </button>
              <p>Mình sẽ khẽ nhắc lúc {store.draft.reminderTime ?? "20:30"}.</p>
            </div>
          )}
        </section>
        <section>
          <h2>Ai được xem</h2>
          <div className="visibility-options">
            {!group && !couple && (
              <>
                <button
                  className={
                    store.draft.visibility === "private" ? "selected" : ""
                  }
                  onClick={() => store.setDraft({ visibility: "private" })}
                >
                  <span>
                    <OIcon name="lock" size={20} weight="bold" /> Chỉ mình tôi
                  </span>
                  {store.draft.visibility === "private" && (
                    <i>
                      <OIcon name="check" size={15} weight="bold" /> Đã chọn
                    </i>
                  )}
                </button>
                <button
                  className={
                    store.draft.visibility === "link" ? "selected" : ""
                  }
                  onClick={() => store.setDraft({ visibility: "link" })}
                >
                  <span>Ai có link (chỉ đọc)</span>
                  {store.draft.visibility === "link" && (
                    <i>
                      <OIcon name="check" size={15} weight="bold" /> Đã chọn
                    </i>
                  )}
                </button>
              </>
            )}
            {(group || couple) && (
              <>
                <button className="selected">
                  <span>{group ? "Cả nhóm" : "Hai đứa"}</span>
                  <i>
                    <OIcon name="check" size={15} weight="bold" /> Đã chọn
                  </i>
                </button>
                <button disabled>
                  <span>Ai có link (chỉ đọc)</span>
                  <small>Hành trình nhóm không có link công khai.</small>
                </button>
              </>
            )}
          </div>
          {type === "Giảm cân" && (
            <div className="locked-share-note">
              <OIcon name="lock" size={19} weight="bold" />
              <span>
                Ảnh làm mờ và ẩn số kg khi chia sẻ, kể cả qua link chỉ đọc.
              </span>
            </div>
          )}
        </section>
      </div>
      {calendarOpen && <CalendarSheet onClose={() => setCalendarOpen(false)} />}
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
    </CreateFrame>
  )
}

export function CreateStepFive() {
  const store = useStore()
  const navigate = useNavigate()
  const [forging, setForging] = useState(!store.reduceMotion)
  const [tab, setTab] = useState<"color" | "cover">("color")
  const [permissionOpen, setPermissionOpen] = useState(false)
  const type = createTypes.find((item) => item.type === store.draft.type)
  const skin = store.draft.skin ?? "minimal"
  const answers = store.draft.answers ?? {}
  const ticketDates = (() => {
    const match = store.draft.dates?.match(/(\d+)[–-](\d+)\/(\d+)/)
    if (!match) return store.draft.dates ?? "16 THG 10 – 20 THG 10"
    return `${match[1]} THG ${match[3]} – ${match[2]} THG ${match[3]}`
  })()
  const tripDays = (() => {
    const match = store.draft.dates?.match(/(\d+)[–-](\d+)/)
    return match ? Number(match[2]) - Number(match[1]) + 1 : 1
  })()
  const durationSummary =
    store.draft.type === "Chuyến đi"
      ? store.draft.dates?.includes("chưa hẹn")
        ? "chưa hẹn ngày về"
        : `${tripDays} ngày`
      : store.draft.noEnd
        ? "không hẹn ngày về"
        : `${store.draft.duration ?? 30} ngày`
  const swatches: Record<string, Array<[string, string]>> = {
    quiet: [
      ["Lục ngọc", "#10B981"],
      ["Xanh sage", "#83A98C"],
      ["Sương mù", "#B6C4C9"],
    ],
    squad: [
      ["Lửa", "#FF9F1C"],
      ["Tím", "#7556F8"],
      ["Phấn", "#F4B8C6"],
    ],
    memory: [
      ["Sương thông", "#4A6B53"],
      ["Biển muối", "#4E8098"],
      ["Phố đêm", "#2E294E"],
    ],
    couple: [
      ["Hồng", "#E15B72"],
      ["Mâm xôi", "#9D174D"],
      ["Đào", "#F29C85"],
    ],
    flexer: [
      ["Lime neon", "#3DE88C"],
      ["San hô điện", "#FF4D6D"],
      ["Băng", "#78DCE8"],
    ],
    minimal: [
      ["Cam", "#EA580C"],
      ["Than", "#303036"],
      ["Trời", "#4B89DC"],
    ],
  }

  useEffect(() => {
    if (store.reduceMotion) return
    const timer = window.setTimeout(() => setForging(false), 1200)
    return () => window.clearTimeout(timer)
  }, [store.reduceMotion])

  function finishLaunch(permission: "granted" | "deferred") {
    store.setCameraPermission(permission)
    const id = store.addJourneyFromDraft()
    store.setInviteSheetOpen(
      store.draft.who === "group" ||
        store.draft.who === "couple" ||
        store.draft.type === "Cặp đôi",
    )
    navigate(`/j/${id}/camera`)
  }

  function launch() {
    if (store.cameraPermission === "unknown") {
      setPermissionOpen(true)
      return
    }
    finishLaunch(store.cameraPermission === "granted" ? "granted" : "deferred")
  }

  if (forging) {
    return (
      <CreateFrame step={5} skinId={skin}>
        <div className="create-handoff">
          <div className="forging-stamp">
            <span>30</span>
          </div>
          <h1>đang đúc DNA…</h1>
          <p>
            {type?.name ?? "Hành trình"} · {durationSummary}
          </p>
        </div>
      </CreateFrame>
    )
  }

  return (
    <CreateFrame step={5} skinId={skin}>
      <div className="ticket-reveal">
        <div
          className={`departure-ticket ticket-${skin} cover-${store.draft.cover ?? 0}`}
          style={
            {
              "--ticket-accent":
                swatches[skin][store.draft.variant ?? 0]?.[1] ??
                swatches[skin][0][1],
            } as CSSProperties
          }
        >
          {skin === "quiet" && (
            <>
              <span className="ticket-lock">
                <OIcon name="lock" size={27} weight="fill" />
              </span>
              <small>HỒ SƠ RIÊNG TƯ</small>
              <h2>Hồ sơ riêng tư · 30 ngày</h2>
              <p>Mục tiêu · {String(answers.goal ?? "Giảm cân")}</p>
              <div className="ticket-milestones">
                Tuần đầu · Nửa chặng · Về đích
              </div>
              <em>Chỉ mình mình thấy. Từng chút một.</em>
            </>
          )}
          {skin === "squad" && (
            <>
              <small>NHIỆM VỤ 30 NGÀY</small>
              <h2>{String(answers.goal ?? "IELTS")}</h2>
              <div className="quest-path">
                {[0, 1, 2, 3].map((item) => (
                  <OIcon name="crew-dot" size={12} key={item} />
                ))}
                <OIcon name="trophy" size={22} active />
              </div>
              <b>{String(answers.trophy ?? "Cúp 7.5")}</b>
              <div className="ticket-crew">
                {[0, 1].map((item) => (
                  <OIcon name="crew-dot" size={13} key={`full-${item}`} />
                ))}
                {[0, 1, 2].map((item) => (
                  <OIcon name="crew-dot-empty" size={13} key={`open-${item}`} />
                ))}
                <span>còn trống</span>
              </div>
              <em>Điểm danh mỗi ngày, cả hội cùng lên!</em>
            </>
          )}
          {skin === "flexer" && (
            <>
              <span className="pin pin-one" />
              <span className="pin pin-two" />
              <span className="pin pin-three" />
              <span className="pin pin-four" />
              <div className="bib-number">30</div>
              <h2>NGÀY · {String(answers.sport ?? "CHẠY")}</h2>
              <small>SỐ ĐEO 001</small>
              <em>Ra khỏi giường. Chạy tiếp.</em>
            </>
          )}
          {skin === "memory" && (
            <>
              <span className="round-stamp">ĐÀ LẠT</span>
              <small>VÉ KÝ ỨC</small>
              <h2 className="icon-text">
                SGN <OIcon name="caret-right" size={20} />{" "}
                {String(answers.place ?? "ĐÀ LẠT").toUpperCase()}
              </h2>
              <p>{ticketDates}</p>
              <small>{durationSummary.toUpperCase()}</small>
              <b>CUỘN PHIM {String(answers.film ?? "24 TẤM").toUpperCase()}</b>
              <div className="ticket-crew">
                {[0, 1, 2].map((item) => (
                  <OIcon name="crew-dot" size={13} key={item} />
                ))}
              </div>
              <b>CUỘN PHIM {String(answers.film ?? "24 TẤM").toUpperCase()}</b>
              <div className="fake-barcode">|||| ||| || |||| |</div>
              <em>Mang về thật nhiều khung hình.</em>
            </>
          )}
          {skin === "couple" && (
            <>
              <div className="ticket-halves">
                <span>{String(answers.nameLeft ?? "Bạn")}</span>
                <b>
                  <OIcon name="heart" size={20} active />
                </b>
                <span>{String(answers.nameRight ?? "Người ấy")}</span>
              </div>
              <h2>
                30 NGÀY {String(answers.ritual ?? "NẤU CHO NHAU").toUpperCase()}
              </h2>
              <em>Mỗi ngày một nửa, ghép lại thành một.</em>
            </>
          )}
          {skin === "minimal" && (
            <>
              <h2>{String(answers.habit ?? "ĐỌC 10 TRANG").toUpperCase()}</h2>
              <p>vì: {String(answers.reason ?? "để ngủ ngon hơn")}</p>
              <small>NGÀY 01 / {store.draft.duration ?? 30}</small>
            </>
          )}
        </div>
        <div className="ticket-tabs" role="tablist">
          <button
            className={tab === "color" ? "selected" : ""}
            onClick={() => setTab("color")}
            role="tab"
          >
            Màu
          </button>
          <button
            className={tab === "cover" ? "selected" : ""}
            onClick={() => setTab("cover")}
            role="tab"
          >
            Bìa
          </button>
        </div>
        {tab === "color" ? (
          <div className="ticket-choices">
            {swatches[skin].map(([name, color], index) => {
              const selected = (store.draft.variant ?? 0) === index
              return (
                <button
                  key={name}
                  className={selected ? "selected" : ""}
                  onClick={() => store.setDraft({ variant: index })}
                  aria-pressed={selected}
                >
                  <i style={{ background: color }} />
                  <span>{name}</span>
                  {selected && (
                    <i className="corner-check-badge" data-corner-badge>
                      <OIcon name="check" size={14} weight="bold" />
                    </i>
                  )}
                </button>
              )
            })}
          </div>
        ) : (
          <div className="ticket-choices cover-choices">
            {["Con dấu", "Nhãn chữ", "Khung ngày"].map((name, index) => {
              const selected = (store.draft.cover ?? 0) === index
              return (
                <button
                  key={name}
                  className={selected ? "selected" : ""}
                  onClick={() => store.setDraft({ cover: index })}
                  aria-pressed={selected}
                  aria-label={`Bìa ${name}`}
                >
                  <i>{index === 0 ? "30" : index === 1 ? "DNA" : "01"}</i>
                  {selected && (
                    <i className="corner-check-badge" data-corner-badge>
                      <OIcon name="check" size={14} weight="bold" />
                    </i>
                  )}
                </button>
              )
            })}
          </div>
        )}
        <button className="launch-button" onClick={launch}>
          Khởi hành
        </button>
        <button
          className="edit-ticket-button"
          onClick={() => navigate("/create/4")}
        >
          Sửa lại
        </button>
        {permissionOpen && (
          <PermissionSheet
            kind="camera"
            onClose={() => finishLaunch("deferred")}
            onConfirm={() => finishLaunch("granted")}
          />
        )}
      </div>
    </CreateFrame>
  )
}
