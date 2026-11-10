import {
  ArrowLeft,
  Barbell,
  BookOpen,
  Camera,
  Check,
  EnvelopeSimple,
  Heart,
  PencilSimple,
  Scales,
  SuitcaseRolling,
  WarningCircle,
  X,
} from "@phosphor-icons/react"
import {
  useEffect,
  useRef,
  useState,
  type PointerEvent as ReactPointerEvent,
  type ReactNode,
} from "react"
import { Link, useNavigate, useParams } from "react-router"
import { useStore, type Draft, type Journey } from "./store"

const taglines = ["chụp một tấm.", "giữ một chuỗi.", "đi cùng nhau."]

const journeyChoices: Array<{
  type: Journey["type"]
  label: string
  color: string
  icon: ReactNode
}> = [
  { type: "Giảm cân", label: "Giảm cân", color: "#7EE8A2", icon: <Scales /> },
  {
    type: "Tiếng Anh",
    label: "Học tiếng Anh",
    color: "#FFD84D",
    icon: <BookOpen />,
  },
  {
    type: "Tập luyện",
    label: "Tập luyện",
    color: "#CF9FFF",
    icon: <Barbell />,
  },
  {
    type: "Chuyến đi",
    label: "Một chuyến đi",
    color: "#FFB347",
    icon: <SuitcaseRolling />,
  },
  {
    type: "Cặp đôi",
    label: "Nghi thức của hai đứa",
    color: "#FF7E7E",
    icon: (
      <span className="double-heart">
        <Heart />
        <Heart />
      </span>
    ),
  },
  {
    type: "Tự đặt",
    label: "Một thói quen nhỏ",
    color: "#7EC8E3",
    icon: <PencilSimple />,
  },
]

function FlowBack({ onClick }: { onClick: () => void }) {
  return (
    <button className="flow-back" onClick={onClick} aria-label="Quay lại">
      <ArrowLeft size={22} weight="bold" />
    </button>
  )
}

function Wordmark({ loading = false }: { loading?: boolean }) {
  return (
    <div className="flow-wordmark">
      <strong>ourney</strong>
      <i />
      {loading && <span className="returning-loader" aria-label="Đang mở" />}
    </div>
  )
}

export function SplashFlow() {
  const store = useStore()
  const navigate = useNavigate()
  const [tagline, setTagline] = useState(0)

  useEffect(() => {
    if (store.pendingJoin) {
      const timeout = window.setTimeout(
        () => navigate("/login", { replace: true }),
        650,
      )
      return () => window.clearTimeout(timeout)
    }
    if (store.user === "old") {
      const timeout = window.setTimeout(
        () => navigate("/camera", { replace: true }),
        650,
      )
      return () => window.clearTimeout(timeout)
    }
    if (store.reduceMotion) return
    const interval = window.setInterval(
      () => setTagline((current) => (current + 1) % taglines.length),
      1200,
    )
    return () => window.clearInterval(interval)
  }, [navigate, store.pendingJoin, store.reduceMotion, store.user])

  return (
    <button
      className="splash-flow"
      onClick={() =>
        store.pendingJoin
          ? navigate("/login")
          : store.user === "new" && navigate("/onboarding/1")
      }
      aria-label={
        store.pendingJoin
          ? "Tiếp tục đăng nhập"
          : store.user === "new"
            ? "Bắt đầu"
            : "Đang mở camera"
      }
    >
      {store.user === "new" && (
        <div className="splash-stickers" aria-hidden="true">
          {journeyChoices.map((choice, index) => (
            <span
              key={choice.type}
              className={`splash-sticker sticker-${index + 1}`}
              style={{ "--sticker": choice.color } as React.CSSProperties}
            >
              {choice.icon}
            </span>
          ))}
        </div>
      )}
      <Wordmark loading={store.user === "old"} />
      {store.user === "new" && (
        <p key={store.reduceMotion ? "static" : tagline}>
          {store.reduceMotion ? taglines[0] : taglines[tagline]}
        </p>
      )}
    </button>
  )
}

const whoChoices: Array<{
  value: NonNullable<Draft["who"]>
  label: string
  hint: string
}> = [
  { value: "solo", label: "Một mình", hint: "chỉ mình bạn thấy" },
  { value: "group", label: "Rủ hội bạn", hint: "tối đa 10 người" },
  { value: "couple", label: "Chỉ hai đứa", hint: "ghép đôi, chỉ hai người" },
]

const reminderChoices: Array<{
  value: NonNullable<Draft["reminder"]>
  label: string
  hint: string
}> = [
  { value: "07:00", label: "Sáng sớm", hint: "gợi ý nhắc lúc 07:00" },
  { value: "12:00", label: "Trưa", hint: "gợi ý nhắc lúc 12:00" },
  { value: "21:30", label: "Tối muộn", hint: "gợi ý nhắc lúc 21:30" },
]

export function OnboardingFlow() {
  const store = useStore()
  const navigate = useNavigate()
  const params = useParams()
  const step = Math.min(3, Math.max(1, Number(params.step) || 1))
  const selected =
    step === 1
      ? store.draft.type
      : step === 2
        ? store.draft.who
        : store.draft.reminder
  const selectedType =
    journeyChoices.find((choice) => choice.type === store.draft.type) ??
    journeyChoices[1]
  const couple = store.draft.who === "couple"

  function continueFlow() {
    if (!selected) return
    if (step < 3) navigate(`/onboarding/${step + 1}`)
    else {
      store.setOnboardingChoice({
        type: store.draft.type,
        who: store.draft.who,
        reminder: store.draft.reminder,
      })
      navigate("/login")
    }
  }

  return (
    <section className="flow-screen onboarding-flow">
      <header className="onboarding-top">
        {step > 1 ? <FlowBack onClick={() => navigate(-1)} /> : <span />}
        <div>
          <b>Câu {step}/3</b>
          <div className="step-segments" aria-hidden="true">
            {[1, 2, 3].map((item) => (
              <i
                key={item}
                className={
                  item < step ? "done" : item === step ? "current" : ""
                }
              />
            ))}
          </div>
        </div>
        <button className="flow-skip" onClick={() => navigate("/login")}>
          Bỏ qua
        </button>
      </header>

      <div className="onboarding-content">
        <h1>
          {step === 1
            ? "bạn đang muốn kiên trì điều gì?"
            : step === 2
              ? "đi một mình hay có hội?"
              : "bạn hay quên vào lúc nào?"}
        </h1>

        {step === 1 && (
          <div className="choice-grid">
            {journeyChoices.map((choice) => {
              const active = store.draft.type === choice.type
              return (
                <button
                  key={choice.type}
                  className={`answer-choice type-choice ${
                    active ? "selected" : ""
                  }`}
                  style={{ "--choice": choice.color } as React.CSSProperties}
                  onClick={() => store.setDraft({ type: choice.type })}
                >
                  <span>{choice.icon}</span>
                  <b>{choice.label}</b>
                  {active && (
                    <i className="choice-check">
                      <Check size={14} weight="bold" />
                    </i>
                  )}
                </button>
              )
            })}
          </div>
        )}

        {step === 2 && (
          <div className="stacked-choices">
            {whoChoices.map((choice) => {
              const active = store.draft.who === choice.value
              return (
                <button
                  key={choice.value}
                  className={`answer-choice row-choice ${
                    active ? "selected" : ""
                  }`}
                  style={
                    {
                      "--choice":
                        choice.value === "couple" ? "#FF7E7E" : "#FFD84D",
                    } as React.CSSProperties
                  }
                  onClick={() => store.setDraft({ who: choice.value })}
                >
                  <span>
                    <b>{choice.label}</b>
                    <small>{choice.hint}</small>
                  </span>
                  {active && (
                    <i className="choice-check">
                      <Check size={14} weight="bold" />
                    </i>
                  )}
                </button>
              )
            })}
            {couple && (
              <p className="couple-hint">
                mình sẽ dùng phong cách Hai đứa mình
              </p>
            )}
          </div>
        )}

        {step === 3 && (
          <>
            <div className="stacked-choices reminder-choices">
              {reminderChoices.map((choice) => {
                const active = store.draft.reminder === choice.value
                return (
                  <button
                    key={choice.value}
                    className={`answer-choice row-choice ${
                      active ? "selected" : ""
                    }`}
                    style={{ "--choice": "#7EC8E3" } as React.CSSProperties}
                    onClick={() => store.setDraft({ reminder: choice.value })}
                  >
                    <span>
                      <b>{choice.label}</b>
                      <small>{choice.hint}</small>
                    </span>
                    {active && (
                      <i className="choice-check">
                        <Check size={14} weight="bold" />
                      </i>
                    )}
                  </button>
                )
              })}
            </div>
            {store.draft.reminder && (
              <div className="onboarding-result">
                <b>hành trình đầu tiên của bạn.</b>
                <div
                  className="mini-result-card"
                  style={
                    {
                      "--result": couple ? "#FF7E7E" : selectedType.color,
                    } as React.CSSProperties
                  }
                >
                  <span className="result-polaroid">{selectedType.icon}</span>
                  <strong>
                    {couple
                      ? "hai đứa mình."
                      : selectedType.label.toLocaleLowerCase("vi") + "."}
                  </strong>
                  <div>
                    <span>
                      {store.draft.who === "group"
                        ? "Rủ hội bạn"
                        : store.draft.who === "couple"
                          ? "Chỉ hai đứa"
                          : "Một mình"}
                    </span>
                    <span>Nhắc {store.draft.reminder}</span>
                  </div>
                </div>
              </div>
            )}
          </>
        )}
      </div>

      <div className="flow-bottom">
        <button
          className="flow-primary"
          disabled={!selected}
          onClick={continueFlow}
        >
          {step === 3 && selected ? "Bắt đầu thôi" : "Tiếp tục"}
        </button>
      </div>
    </section>
  )
}

export function ErrorMessage({ children }: { children: ReactNode }) {
  return (
    <div className="flow-error" role="alert">
      <WarningCircle size={20} weight="bold" />
      <span>{children}</span>
    </div>
  )
}

export function OfflineBanner({ retry }: { retry?: () => void }) {
  return (
    <div className="flow-offline" role="status">
      <WarningCircle size={20} weight="bold" />
      <span>Chưa có mạng nên chưa gửi được mã. Bật mạng rồi thử lại.</span>
      {retry && <button onClick={retry}>Thử lại</button>}
    </div>
  )
}

export function LoginFlow() {
  const store = useStore()
  const navigate = useNavigate()
  const [email, setEmail] = useState(store.email)
  const [error, setError] = useState("")
  const [sending, setSending] = useState(false)

  function submit() {
    if (store.offline) return
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      setError("Email chưa đúng dạng. Ví dụ: ten@gmail.com")
      return
    }
    setError("")
    setSending(true)
    window.setTimeout(() => {
      setSending(false)
      if (email.toLocaleLowerCase("vi").includes("loi")) {
        setError("Chưa gửi được mã. Thử lại sau ít phút.")
        return
      }
      store.setEmail(email)
      navigate("/otp")
    }, 650)
  }

  return (
    <section className="flow-screen login-flow">
      <div className="flow-scroll">
        <div className="envelope-sticker">
          <EnvelopeSimple size={58} weight="duotone" />
        </div>
        <h1>đăng nhập.</h1>
        <p>Nhập email, mình gửi mã 6 số để vào. Không cần mật khẩu.</p>
        {store.offline && <OfflineBanner retry={() => setError("")} />}
        <label className={`flow-field ${error ? "has-error" : ""}`}>
          <span>Email</span>
          <div>
            <EnvelopeSimple size={22} weight="bold" />
            <input
              type="email"
              value={email}
              disabled={sending}
              placeholder="ten@email.com"
              onChange={(event) => setEmail(event.target.value)}
              autoComplete="email"
            />
          </div>
        </label>
        {error && <ErrorMessage>{error}</ErrorMessage>}
        <button className="flow-primary" disabled={sending} onClick={submit}>
          {sending ? "Đang gửi…" : "Gửi mã"}
        </button>
        <p className="legal-copy">
          Tiếp tục nghĩa là bạn đồng ý
          <Link to="/settings/terms">Điều khoản sử dụng</Link>
          và
          <Link to="/settings/privacy">Chính sách quyền riêng tư.</Link>
        </p>
      </div>
    </section>
  )
}

export function OtpFlow() {
  const store = useStore()
  const navigate = useNavigate()
  const [code, setCode] = useState("")
  const [status, setStatus] =
    useState<"idle" | "checking" | "error" | "success">("idle")
  const [seconds, setSeconds] = useState(30)
  const [toast, setToast] = useState(false)
  const inputRef = useRef<HTMLInputElement | null>(null)

  useEffect(() => {
    if (seconds <= 0) return
    const interval = window.setInterval(
      () => setSeconds((value) => value - 1),
      1000,
    )
    return () => window.clearInterval(interval)
  }, [seconds])

  useEffect(() => {
    if (code.length !== 6 || status !== "idle") return
    checkCode()
  }, [code, status])

  useEffect(() => {
    if (store.otpMode === "expired") {
      setCode("")
      setStatus("idle")
    }
  }, [store.otpMode])

  function checkCode() {
    if (store.offline) return
    if (store.otpMode === "expired" || store.otpMode === "locked") return
    setStatus("checking")
    window.setTimeout(() => {
      if (code === "123456") {
        setStatus("success")
        window.setTimeout(() => {
          if (store.pendingJoin && store.user === "old") {
            store.setSignedIn(true)
            navigate(`/join/${store.pendingJoin}`, { replace: true })
          } else {
            navigate("/profile-setup")
          }
        }, 800)
      } else {
        setStatus("error")
        setCode("")
        inputRef.current?.focus()
      }
    }, 550)
  }

  function resend() {
    if (store.offline) return
    setSeconds(30)
    setCode("")
    setStatus("idle")
    setToast(true)
    window.setTimeout(() => setToast(false), 2200)
  }

  const locked = status === "checking" || store.otpMode === "locked"
  const message =
    store.otpMode === "expired"
      ? "Mã đã hết hạn. Gửi mã mới để tiếp tục."
      : store.otpMode === "locked"
        ? "Bạn đã thử nhiều lần. Chờ vài phút rồi thử lại."
        : status === "error"
          ? "Mã chưa đúng. Kiểm tra lại 6 số trong email rồi nhập lại."
          : ""

  return (
    <section className="flow-screen otp-flow">
      <header className="simple-flow-header">
        <FlowBack onClick={() => navigate(-1)} />
      </header>
      <div className="flow-scroll">
        <h1>nhập mã.</h1>
        <p>
          Mã gồm 6 số vừa gửi tới <b>{store.email}</b>
        </p>
        <button className="text-action" onClick={() => navigate(-1)}>
          Đổi email
        </button>
        {store.offline && (
          <OfflineBanner retry={() => store.setOffline(false)} />
        )}
        <div
          className={`otp-boxes ${
            status === "error" || store.otpMode !== "normal" ? "has-error" : ""
          } ${locked ? "locked" : ""}`}
          onClick={() => inputRef.current?.focus()}
        >
          {[0, 1, 2, 3, 4, 5].map((index) => (
            <span
              key={index}
              className={index === code.length && !locked ? "active" : ""}
            >
              {code[index] ?? ""}
              {status === "success" && <Check size={22} weight="bold" />}
            </span>
          ))}
          <input
            ref={inputRef}
            className="otp-native-input"
            inputMode="numeric"
            autoComplete="one-time-code"
            autoFocus
            disabled={locked}
            value={code}
            onChange={(event) => {
              setStatus("idle")
              setCode(event.target.value.replace(/\D/g, "").slice(0, 6))
            }}
            aria-label="Mã xác nhận 6 số"
          />
        </div>
        {status === "checking" && (
          <p className="checking-copy">Đang kiểm tra…</p>
        )}
        {status === "success" && (
          <p className="success-copy">Xong rồi. Chào bạn.</p>
        )}
        {message && <ErrorMessage>{message}</ErrorMessage>}
        {store.otpMode === "expired" ? (
          <button className="flow-primary" onClick={resend}>
            Gửi mã mới
          </button>
        ) : (
          <button
            className="flow-primary"
            disabled={code.length !== 6 || locked}
            onClick={checkCode}
          >
            Xác nhận
          </button>
        )}
        <div className="resend-row">
          {seconds > 0 ? (
            <>
              <span
                className="timer-ring"
                style={
                  { "--timer": `${seconds * 12}deg` } as React.CSSProperties
                }
              />
              <span>Gửi lại sau {seconds} giây</span>
            </>
          ) : (
            <button onClick={resend}>Gửi lại mã</button>
          )}
        </div>
        <p className="otp-helper">
          Không thấy thư? Xem mục thư rác hoặc quảng cáo.
        </p>
      </div>
      <div className={`flow-toast ${toast ? "show" : ""}`} role="status">
        <Check size={18} weight="bold" />
        Đã gửi mã mới. Mã cũ không dùng được nữa.
      </div>
    </section>
  )
}

const avatarColors = [
  "#7EE8A2",
  "#FFD84D",
  "#CF9FFF",
  "#FFB347",
  "#FF7E7E",
  "#7EC8E3",
]

export function ProfileSetupFlow() {
  const store = useStore()
  const navigate = useNavigate()
  const [avatar, setAvatar] = useState(0)
  const [name, setName] = useState("Linh")
  const [username, setUsername] = useState("linhtran")
  const valid = /^[a-z0-9_.]{3,20}$/.test(username)
  const taken = username === "linh"

  function finish() {
    if (!valid || taken) return
    store.setProfile({ name, username })
    store.setSignedIn(true)
    store.setCameraPermission("unknown")
    navigate(store.pendingJoin ? `/join/${store.pendingJoin}` : "/camera", {
      replace: true,
    })
  }

  return (
    <section className="flow-screen profile-setup-flow">
      <div className="flow-scroll">
        <h1>hồ sơ của bạn.</h1>
        <div
          className="profile-avatar-large"
          style={{ background: avatarColors[avatar] }}
        >
          <span className="avatar-hair" />
          <i className="avatar-eye eye-left" />
          <i className="avatar-eye eye-right" />
          <i className="avatar-smile" />
        </div>
        <div className="avatar-options" aria-label="Chọn màu ảnh đại diện">
          {avatarColors.map((color, index) => (
            <button
              key={color}
              className={avatar === index ? "selected" : ""}
              style={{ background: color }}
              onClick={() => setAvatar(index)}
              aria-label={`Màu đại diện ${index + 1}`}
            >
              {avatar === index && <Check size={17} weight="bold" />}
            </button>
          ))}
        </div>
        <label className="flow-field">
          <span>Tên hiển thị</span>
          <div>
            <input
              value={name}
              onChange={(event) => setName(event.target.value)}
            />
          </div>
        </label>
        <label
          className={`flow-field username-field ${
            !valid || taken ? "has-error" : ""
          }`}
        >
          <span>Tên người dùng</span>
          <div>
            <b>@</b>
            <input
              value={username}
              onChange={(event) =>
                setUsername(event.target.value.toLocaleLowerCase("vi"))
              }
            />
          </div>
          <small>3–20 ký tự: a–z, 0–9, _ .</small>
        </label>
        <div
          className={`username-status ${
            !valid || taken ? "error" : "available"
          }`}
        >
          {!valid || taken ? (
            <WarningCircle size={20} weight="bold" />
          ) : (
            <Check size={20} weight="bold" />
          )}
          <span>
            {!valid
              ? "Chỉ dùng a–z, 0–9, _ ."
              : taken
                ? "Tên này đã có người dùng"
                : "Dùng được"}
          </span>
        </div>
        <button
          className="flow-primary"
          disabled={!valid || taken}
          onClick={finish}
        >
          Xong
        </button>
      </div>
    </section>
  )
}

type PermissionKind = "camera" | "notification" | "session"

export function PermissionSheet({
  kind,
  onClose,
  onConfirm,
  reason,
}: {
  kind: PermissionKind
  onClose: () => void
  onConfirm: () => void
  reason?: string
}) {
  const startY = useRef<number | null>(null)
  const [drag, setDrag] = useState(0)
  const copy = {
    camera: {
      title: "cho ourney dùng camera.",
      body: "Để chụp tấm đầu tiên của hành trình. Ảnh chỉ hiện với người trong hành trình đó.",
      action: "Cho phép",
      icon: <Camera size={38} weight="duotone" />,
    },
    notification: {
      title: "để mình khẽ nhắc trước khi chuỗi đứt.",
      body: "Bật nhắc để mình nhắc theo giờ bạn đặt. Có thể trễ tuỳ máy.",
      action: "Cho phép",
      icon: <Heart size={38} weight="duotone" />,
    },
    session: {
      title: "phiên đăng nhập đã hết.",
      body: "Đăng nhập lại để đồng bộ. Ảnh trên máy vẫn còn nguyên.",
      action: "Gửi mã",
      icon: <WarningCircle size={38} weight="duotone" />,
    },
  }[kind]

  function dragStart(event: ReactPointerEvent<HTMLDivElement>) {
    startY.current = event.clientY
    event.currentTarget.setPointerCapture(event.pointerId)
  }

  function dragMove(event: ReactPointerEvent<HTMLDivElement>) {
    if (startY.current === null) return
    setDrag(Math.max(0, event.clientY - startY.current))
  }

  function dragEnd() {
    if (drag > 70) onClose()
    startY.current = null
    setDrag(0)
  }

  return (
    <div
      className="permission-scrim"
      onPointerDown={(event) =>
        event.target === event.currentTarget && onClose()
      }
    >
      <div
        className="permission-sheet"
        role="dialog"
        aria-modal="true"
        style={{ transform: `translateY(${drag}px)` }}
      >
        <div
          className="permission-drag"
          onPointerDown={dragStart}
          onPointerMove={dragMove}
          onPointerUp={dragEnd}
        >
          <i />
        </div>
        <button
          className="permission-close"
          onClick={onClose}
          aria-label="Đóng"
        >
          <X size={22} weight="bold" />
        </button>
        <div className="permission-sticker">{copy.icon}</div>
        <h2>{copy.title}</h2>
        <p>{reason ?? copy.body}</p>
        <button className="flow-primary" onClick={onConfirm}>
          {copy.action}
        </button>
        {kind !== "session" && (
          <button className="permission-later" onClick={onClose}>
            để sau vậy.
          </button>
        )}
      </div>
    </div>
  )
}
