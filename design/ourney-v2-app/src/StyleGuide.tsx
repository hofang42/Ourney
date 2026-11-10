import {
  ArrowRight,
  Camera,
  Check,
  Heart,
  MapTrifold,
  Moon,
  Plus,
  Sparkle,
  Sun,
  UsersThree,
  X,
} from "@phosphor-icons/react"
import { useMemo, useState } from "react"

type Mode = "light" | "dark"

export type Variant = {
  name: string
  accent: string
  button: string
  buttonLabel: string
  secondary: string
}

export type Skin = {
  id: string
  short: string
  journey: string
  emoji: string
  heading: string
  mood: string
  light: {
    bg: string
    surface: string
    ink: string
    muted: string
  }
  dark: {
    bg: string
    surface: string
    ink: string
    muted: string
  }
  variants: Variant[]
}

export const skins: Skin[] = [
  {
    id: "quiet",
    short: "Lặng",
    journey: "Giảm cân",
    emoji: "🌿",
    heading: "Fraunces",
    mood: "Lâm sàng dịu nhẹ · nét mảnh",
    light: {
      bg: "#EFF3F0",
      surface: "#FFFFFF",
      ink: "#0F172A",
      muted: "#53605B",
    },
    dark: {
      bg: "#0B0F12",
      surface: "#151C21",
      ink: "#F1F5F9",
      muted: "#A8B2B9",
    },
    variants: [
      {
        name: "Lục ngọc",
        accent: "#10B981",
        button: "#FF4D6D",
        buttonLabel: "#0F172A",
        secondary: "#B7E8D1",
      },
      {
        name: "Xanh sage",
        accent: "#6B9E8A",
        button: "#D9694F",
        buttonLabel: "#0F172A",
        secondary: "#CADBD4",
      },
      {
        name: "Sương mù",
        accent: "#6E9AC0",
        button: "#E8A25C",
        buttonLabel: "#0F172A",
        secondary: "#D4E4F0",
      },
    ],
  },
  {
    id: "squad",
    short: "Đội",
    journey: "Tiếng Anh",
    emoji: "📒",
    heading: "Space Grotesk",
    mood: "Sổ kem · đồng đội rực lửa",
    light: {
      bg: "#F7F1E5",
      surface: "#FFFDF9",
      ink: "#1E1B18",
      muted: "#665F57",
    },
    dark: {
      bg: "#12131A",
      surface: "#1D1F2B",
      ink: "#F8FAFC",
      muted: "#B6BAC8",
    },
    variants: [
      {
        name: "Lửa",
        accent: "#FF9F1C",
        button: "#FF9F1C",
        buttonLabel: "#1E1B18",
        secondary: "#7556F8",
      },
      {
        name: "Tím",
        accent: "#7556F8",
        button: "#FF9F1C",
        buttonLabel: "#1E1B18",
        secondary: "#7556F8",
      },
      {
        name: "Phấn",
        accent: "#4FA36B",
        button: "#E9B949",
        buttonLabel: "#1E1B18",
        secondary: "#7556F8",
      },
    ],
  },
  {
    id: "memory",
    short: "Ký ức",
    journey: "Chuyến đi",
    emoji: "🎟️",
    heading: "Fraunces",
    mood: "Giấy hạt · băng dính · phim",
    light: {
      bg: "#F4EFE6",
      surface: "#FFFFFF",
      ink: "#231F1E",
      muted: "#675E59",
    },
    dark: {
      bg: "#141312",
      surface: "#1F1D1B",
      ink: "#F5F2EB",
      muted: "#B8B0A6",
    },
    variants: [
      {
        name: "Sương thông",
        accent: "#CC4A2F",
        button: "#CC4A2F",
        buttonLabel: "#FFFFFF",
        secondary: "#4A6B53",
      },
      {
        name: "Biển muối",
        accent: "#2F6F8F",
        button: "#2F6F8F",
        buttonLabel: "#FFFFFF",
        secondary: "#D9A441",
      },
      {
        name: "Phố đêm",
        accent: "#7B5EA7",
        button: "#7B5EA7",
        buttonLabel: "#FFFFFF",
        secondary: "#E0A43A",
      },
    ],
  },
  {
    id: "couple",
    short: "Đôi",
    journey: "Cặp đôi",
    emoji: "💌",
    heading: "Playfair Display",
    mood: "Khung đôi · lãng mạn thanh lịch",
    light: {
      bg: "#F9F0EE",
      surface: "#FFFFFF",
      ink: "#261F22",
      muted: "#6D5E64",
    },
    dark: {
      bg: "#171215",
      surface: "#241C21",
      ink: "#FCE7F3",
      muted: "#CDB5C2",
    },
    variants: [
      {
        name: "Hồng",
        accent: "#9D174D",
        button: "#E15B72",
        buttonLabel: "#1A1316",
        secondary: "#9D174D",
      },
      {
        name: "Mâm xôi",
        accent: "#E15B72",
        button: "#9D174D",
        buttonLabel: "#FFFFFF",
        secondary: "#E15B72",
      },
      {
        name: "Đào",
        accent: "#B4533A",
        button: "#F08A6B",
        buttonLabel: "#1A1316",
        secondary: "#B4533A",
      },
    ],
  },
  {
    id: "flexer",
    short: "Năng lượng",
    journey: "Tập luyện",
    emoji: "🏋️",
    heading: "Barlow Condensed",
    mood: "Kính mờ · viền phát sáng",
    light: {
      bg: "#F3F4F6",
      surface: "#FFFFFF",
      ink: "#090A0F",
      muted: "#525660",
    },
    dark: {
      bg: "#090A0F",
      surface: "#14161F",
      ink: "#F8FAFC",
      muted: "#A9AFBD",
    },
    variants: [
      {
        name: "Lime neon",
        accent: "#3DE88C",
        button: "#FF4D6D",
        buttonLabel: "#090A0F",
        secondary: "#263D34",
      },
      {
        name: "San hô điện",
        accent: "#FF4D6D",
        button: "#3DE88C",
        buttonLabel: "#090A0F",
        secondary: "#46252E",
      },
      {
        name: "Băng",
        accent: "#7DD3FC",
        button: "#C4B5FD",
        buttonLabel: "#090A0F",
        secondary: "#293848",
      },
    ],
  },
  {
    id: "minimal",
    short: "Tối giản",
    journey: "Tự đặt",
    emoji: "✦",
    heading: "Space Grotesk",
    mood: "Lưới 1 điểm · không trang trí",
    light: {
      bg: "#F5F3EE",
      surface: "#FFFFFF",
      ink: "#1C1C1E",
      muted: "#626166",
    },
    dark: {
      bg: "#0E0E10",
      surface: "#18181B",
      ink: "#F4F4F5",
      muted: "#A1A1AA",
    },
    variants: [
      {
        name: "Cam",
        accent: "#EA580C",
        button: "#EA580C",
        buttonLabel: "#1C1C1E",
        secondary: "#27272A",
      },
      {
        name: "Than",
        accent: "#27272A",
        button: "#27272A",
        buttonLabel: "#FFFFFF",
        secondary: "#27272A",
      },
      {
        name: "Trời",
        accent: "#0EA5E9",
        button: "#0EA5E9",
        buttonLabel: "#1C1C1E",
        secondary: "#27272A",
      },
    ],
  },
]

function Icon({
  name,
  size = 24,
}: {
  name: "sun" | "moon" | "map" | "camera" | "users" | "check" | "plus" | "close" | "heart" | "spark" | "arrow"
  size?: number
}) {
  const props = { size, weight: "bold" as const, "aria-hidden": true }
  const icons = {
    sun: <Sun {...props} />,
    moon: <Moon {...props} />,
    map: <MapTrifold {...props} />,
    camera: <Camera {...props} />,
    users: <UsersThree {...props} />,
    check: <Check {...props} />,
    plus: <Plus {...props} />,
    close: <X {...props} />,
    heart: <Heart {...props} />,
    spark: <Sparkle {...props} weight="duotone" />,
    arrow: <ArrowRight {...props} />,
  }
  return icons[name]
}

function SectionTitle({
  kicker,
  title,
  note,
}: {
  kicker: string
  title: string
  note: string
}) {
  return (
    <div className="section-title">
      <div>
        <span className="kicker">{kicker}</span>
        <h2>{title}</h2>
      </div>
      <p>{note}</p>
    </div>
  )
}

function Swatch({
  color,
  label,
  value,
  darkText = false,
}: {
  color: string
  label: string
  value: string
  darkText?: boolean
}) {
  return (
    <div
      className="swatch"
      style={{ background: color, color: darkText ? "#171717" : undefined }}
    >
      <span>{label}</span>
      <code>{value}</code>
    </div>
  )
}

function Ticket({
  index,
  accent,
  surface,
  ink,
}: {
  index: number
  accent: string
  surface: string
  ink: string
}) {
  const names = [
    "Giảm cân",
    "Tiếng Anh",
    "Chuyến đi",
    "Cặp đôi",
    "Tập luyện",
    "Tự đặt",
  ]
  return (
    <div
      className="ticket"
      style={
        {
          "--ticket-accent": accent,
          "--ticket-surface": surface,
          "--ticket-ink": ink,
        } as React.CSSProperties
      }
    >
      <span className="ticket-no">0{index + 1}</span>
      <strong>{names[index]}</strong>
      <span>Khởi hành mỗi ngày</span>
      <i />
    </div>
  )
}

export default function App() {
  const [mode, setMode] = useState<Mode>("light")
  const [skinIndex, setSkinIndex] = useState(0)
  const [variantIndex, setVariantIndex] = useState(0)
  const [largeType, setLargeType] = useState(false)
  const [reduceMotion, setReduceMotion] = useState(false)
  const [wheelOpen, setWheelOpen] = useState(false)
  const [sheetOpen, setSheetOpen] = useState(false)
  const [toast, setToast] = useState(false)
  const [selectedChip, setSelectedChip] = useState(0)

  const skin = skins[skinIndex]
  const baseVariant = skin.variants[variantIndex]
  const variant =
    skin.id === "minimal" && variantIndex === 1 && mode === "dark"
      ? { ...baseVariant, button: "#F4F4F5", buttonLabel: "#0E0E10" }
      : baseVariant
  const palette = skin[mode]
  const vars = useMemo(
    () =>
      ({
        "--bg": palette.bg,
        "--surface": palette.surface,
        "--ink": palette.ink,
        "--muted": palette.muted,
        "--accent": variant.accent,
        "--button": variant.button,
        "--button-label": variant.buttonLabel,
        "--secondary": variant.secondary,
        "--heading-font": `'${skin.heading}', 'Be Vietnam Pro', sans-serif`,
      }) as React.CSSProperties,
    [palette, skin, variant],
  )

  function chooseSkin(index: number) {
    setSkinIndex(index)
    setVariantIndex(0)
  }

  function showToast() {
    setToast(true)
    window.setTimeout(() => setToast(false), 2400)
  }

  return (
    <main
      className={`system mode-${mode} skin-${skin.id} ${
        largeType ? "large-type" : ""
      } ${reduceMotion ? "reduce-motion" : ""}`}
      style={vars}
    >
      <header className="topbar">
        <a className="brand" href="#dau-trang" aria-label="Ourney, đầu trang">
          <span>O</span>urney
        </a>
        <nav aria-label="Mục lục">
          <a href="#nen-tang">Nền tảng</a>
          <a href="#giao-dien">Giao diện</a>
          <a href="#thanh-phan">Thành phần</a>
          <a href="#tuong-tac">Tương tác</a>
        </nav>
        <div className="mode-toggle" aria-label="Chế độ màu">
          <button
            className={mode === "light" ? "active" : ""}
            onClick={() => setMode("light")}
            aria-label="Chế độ sáng"
          >
            <Icon name="sun" size={18} />
          </button>
          <button
            className={mode === "dark" ? "active" : ""}
            onClick={() => setMode("dark")}
            aria-label="Chế độ tối"
          >
            <Icon name="moon" size={18} />
          </button>
        </div>
      </header>

      <section className="hero" id="dau-trang">
        <div className="hero-copy">
          <div className="eyebrow">
            <span /> Hệ thống thiết kế · phiên bản 1.0
          </div>
          <h1>
            mỗi ngày,
            <br />
            <em>một dấu mốc.</em>
          </h1>
          <p>
            Bộ ngôn ngữ thị giác cho những hành trình được nuôi lớn bằng một tấm
            ảnh mỗi ngày.
          </p>
          <div className="hero-tags">
            <span>390 × 844</span>
            <span>6 giao diện</span>
            <span>2 chế độ</span>
            <span>3 biến thể</span>
          </div>
        </div>
        <div className="hero-art" aria-label="Minh họa các dấu mốc hành trình">
          <div className="sun-sticker">
            <Icon name="spark" size={34} />
            <b>+1</b>
            <span>ngày hôm nay</span>
          </div>
          <div className="polaroid p-one">
            <div>🌿</div>
            <strong>ngày 12.</strong>
          </div>
          <div className="polaroid p-two">
            <div>🏋️</div>
            <strong>tiếp tục nhé.</strong>
          </div>
          <svg className="hero-line" viewBox="0 0 320 200" aria-hidden="true">
            <path d="M20 156C84 160 62 38 146 58s62 95 154 54" />
            <circle cx="20" cy="156" r="7" />
            <circle cx="146" cy="58" r="7" />
            <circle cx="300" cy="112" r="7" />
          </svg>
        </div>
      </section>

      <section className="doc-section foundation" id="nen-tang">
        <SectionTitle
          kicker="01 · Nền tảng"
          title="xương sống."
          note="Mềm ở hình khối, thẳng thắn ở đường viền. Mỗi thao tác đều có trọng lượng và phản hồi rõ ràng."
        />
        <div className="foundation-grid">
          <article className="foundation-card colors">
            <h3>Màu vỏ ứng dụng</h3>
            <div className="shell-swatches">
              <Swatch
                color={mode === "light" ? "#FFF8EE" : "#121212"}
                label="Nền"
                value={mode === "light" ? "#FFF8EE" : "#121212"}
              />
              <Swatch
                color={mode === "light" ? "#FFFFFF" : "#1C1B19"}
                label="Bề mặt"
                value={mode === "light" ? "#FFFFFF" : "#1C1B19"}
              />
              <Swatch
                color={mode === "light" ? "#1A1A1A" : "#F5F0E6"}
                label="Mực"
                value={mode === "light" ? "#1A1A1A" : "#F5F0E6"}
              />
              <Swatch color="#FF8A3D" label="Chính" value="#FF8A3D" darkText />
            </div>
          </article>
          <article className="foundation-card type-card">
            <h3>Chữ Việt có nhịp</h3>
            <div className="type-sample">
              <strong>hành trình.</strong>
              <span>Space Grotesk · 700</span>
            </div>
            <p>Ghi lại điều nhỏ bé, nhìn thấy mình đi xa.</p>
            <code>ệ ữ ấ ề ố · Be Vietnam Pro</code>
          </article>
          <article className="foundation-card bone-card">
            <h3>Kết cấu “xương”</h3>
            <button className="bone-demo">
              nhấn để cảm nhận.
              <Icon name="arrow" size={20} />
            </button>
            <div className="measure">
              <span>viền 2</span>
              <span>bóng cứng 4 × 4</span>
              <span>110 mili giây</span>
            </div>
          </article>
          <article className="foundation-card pastel-card">
            <h3>Mã loại hành trình</h3>
            <div className="pastels">
              {[
                ["#7EE8A2", "Giảm cân", "🌿"],
                ["#FFD84D", "Tiếng Anh", "📒"],
                ["#FFB347", "Chuyến đi", "🎟️"],
                ["#FF7E7E", "Cặp đôi", "💌"],
                ["#CF9FFF", "Tập luyện", "🏋️"],
                ["#7EC8E3", "Tự đặt", "✦"],
              ].map(([color, label, emoji]) => (
                <span key={label} style={{ background: color }}>
                  {emoji} {label}
                </span>
              ))}
            </div>
          </article>
        </div>
      </section>

      <section className="doc-section skins-section" id="giao-dien">
        <SectionTitle
          kicker="02 · Giao diện"
          title="sáu chất riêng."
          note="Không chỉ đổi màu. Mỗi giao diện có chất liệu, kiểu chữ, đường viền và nhịp điệu riêng nhưng cùng giữ một cấu trúc cốt lõi."
        />
        <div className="skin-tabs" role="tablist" aria-label="Chọn giao diện">
          {skins.map((item, index) => (
            <button
              key={item.id}
              role="tab"
              aria-selected={skinIndex === index}
              onClick={() => chooseSkin(index)}
            >
              <span>{item.emoji}</span>
              <b>{item.short}</b>
              <small>{item.journey}</small>
            </button>
          ))}
        </div>
        <div className="skin-stage">
          <div className="skin-heading">
            <div>
              <span>Giao diện {String(skinIndex + 1).padStart(2, "0")}</span>
              <h3>{skin.journey.toLocaleLowerCase("vi")}.</h3>
              <p>{skin.mood}</p>
            </div>
            <div className="variant-switch" aria-label="Chọn biến thể">
              {skin.variants.map((item, index) => (
                <button
                  key={item.name}
                  className={variantIndex === index ? "active" : ""}
                  onClick={() => setVariantIndex(index)}
                >
                  <i style={{ background: item.accent }} />
                  {item.name}
                </button>
              ))}
            </div>
          </div>
          <div className="token-row">
            <Swatch color={palette.bg} label="Nền" value={palette.bg} />
            <Swatch
              color={palette.surface}
              label="Bề mặt"
              value={palette.surface}
            />
            <Swatch color={palette.ink} label="Mực" value={palette.ink} />
            <Swatch
              color={variant.accent}
              label="Nhấn"
              value={variant.accent}
              darkText={skin.id === "quiet" || skin.id === "flexer"}
            />
            <Swatch
              color={variant.button}
              label="Nút"
              value={variant.button}
              darkText={variant.buttonLabel !== "#FFFFFF"}
            />
            <Swatch
              color={variant.secondary}
              label={skin.id === "squad" ? "Nhóm" : "Phụ"}
              value={variant.secondary}
            />
          </div>
          <div className="skin-preview">
            <article className="journey-card">
              <div className="cover-sticker">{skin.emoji}</div>
              <div className="card-top">
                <span>Ngày 12/30</span>
                <span>🔥 12</span>
              </div>
              <h4>{skin.journey.toLocaleLowerCase("vi")}.</h4>
              <p>Mốc kế tiếp · Ba tuần đều đặn</p>
              <div className="progress">
                <i style={{ width: "40%" }} />
              </div>
              <div className="card-foot">
                <div className="avatars">
                  <b>LA</b>
                  <b>MN</b>
                  <b>+2</b>
                </div>
                <button aria-label="Mở hành trình">
                  <Icon name="arrow" size={20} />
                </button>
              </div>
            </article>
            <div className="preview-stack">
              <div className="milestones">
                <div className="node done">
                  <Icon name="check" size={16} />
                </div>
                <i />
                <div className="node current">12</div>
                <i className="dashed" />
                <div className="node">21</div>
              </div>
              <div className="preview-buttons">
                <button className="primary">
                  Chụp hôm nay <Icon name="camera" size={20} />
                </button>
                <button className="secondary">Xem hành trình</button>
              </div>
              <div className="role-note">
                <span
                  style={{
                    background: variant.button,
                    color: variant.buttonLabel,
                  }}
                >
                  Nhãn cố định
                </span>
                <p>
                  Màu trạng thái luôn đi cùng nhãn hoặc hình dạng, không dùng
                  màu đơn độc.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="doc-section components" id="thanh-phan">
        <SectionTitle
          kicker="03 · Thành phần"
          title="một bộ, nhiều giọng."
          note="Mọi thành phần dùng đúng token của giao diện đang chọn. Thử chế độ chữ lớn để kiểm tra khả năng co giãn."
        />
        <div className="control-strip">
          <div>
            <b>Bản mẫu</b>
            <span>
              Đang áp dụng: {skin.journey} · {variant.name}
            </span>
          </div>
          <label className="switch-label">
            Chữ 135%
            <button
              className={`switch ${largeType ? "on" : ""}`}
              role="switch"
              aria-checked={largeType}
              onClick={() => setLargeType(!largeType)}
            >
              <i />
            </button>
          </label>
          <label className="switch-label">
            Giảm chuyển động
            <button
              className={`switch ${reduceMotion ? "on" : ""}`}
              role="switch"
              aria-checked={reduceMotion}
              onClick={() => setReduceMotion(!reduceMotion)}
            >
              <i />
            </button>
          </label>
        </div>
        <div className="component-grid">
          <article className="component-card wide">
            <header>
              <span>01</span>
              <h3>Nút</h3>
              <code>cao 52 · gọn 44</code>
            </header>
            <div className="button-showcase">
              <button className="primary">Tiếp tục hành trình</button>
              <button className="secondary">Để sau</button>
              <button className="ghost">Xem chi tiết</button>
              <button className="destructive">Xóa hành trình</button>
              <button className="primary pressed">Đang nhấn</button>
              <button className="primary" disabled>
                Chưa sẵn sàng
              </button>
              <button className="primary focus">Đang được chọn</button>
            </div>
          </article>

          <article className="component-card">
            <header>
              <span>02</span>
              <h3>Thẻ chọn</h3>
              <code>vùng chạm ≥ 44</code>
            </header>
            <div className="chips">
              {["Mỗi ngày", "Bạn bè", "Riêng tư"].map((label, index) => (
                <button
                  key={label}
                  className={selectedChip === index ? "selected" : ""}
                  onClick={() => setSelectedChip(index)}
                >
                  {selectedChip === index && <Icon name="check" size={17} />}
                  {label}
                </button>
              ))}
            </div>
            <div className="reaction-bar" aria-label="Phản ứng">
              <button>🔥</button>
              <button>💪</button>
              <button>👏</button>
              <button>❤️</button>
              <button>😂</button>
            </div>
          </article>

          <article className="component-card">
            <header>
              <span>03</span>
              <h3>Trường nhập</h3>
              <code>nhãn luôn hiện</code>
            </header>
            <label className="input-field">
              <span>Tên hành trình</span>
              <input defaultValue="Mình khỏe hơn" />
              <small>18/40 ký tự</small>
            </label>
            <div className="otp" aria-label="Mã xác nhận">
              <input value="2" readOnly />
              <input value="8" readOnly />
              <input value="4" readOnly />
              <input value="" readOnly />
              <input value="" readOnly />
              <input value="" readOnly />
            </div>
          </article>

          <article className="component-card answer-card">
            <header>
              <span>04</span>
              <h3>Thẻ trả lời lớn</h3>
              <code>chọn bằng hình + nhãn</code>
            </header>
            <button>
              <span className="answer-icon">
                <Icon name="heart" size={28} />
              </span>
              <span>
                <b>Cùng nhau</b>
                <small>Cho phép tối đa 10 người</small>
              </span>
              <Icon name="check" size={22} />
            </button>
          </article>

          <article className="component-card states-card">
            <header>
              <span>05</span>
              <h3>Trạng thái</h3>
              <code>không có ngõ cụt</code>
            </header>
            <div className="state-row">
              <div className="empty-state">
                <div>
                  <Icon name="camera" size={26} />
                </div>
                <b>Chưa có ảnh hôm nay</b>
                <span>Khoảnh khắc thật là đủ.</span>
                <button onClick={showToast}>Tạo lời nhắc</button>
              </div>
              <div className="skeleton" aria-label="Đang tải">
                <i />
                <b />
                <span />
                <span />
              </div>
            </div>
          </article>

          <article className="component-card progress-card">
            <header>
              <span>06</span>
              <h3>Tiến độ</h3>
              <code>số lớn 56–96</code>
            </header>
            <div className="ring-wrap">
              <div className="progress-ring">
                <svg viewBox="0 0 120 120">
                  <circle cx="60" cy="60" r="50" />
                  <circle className="value" cx="60" cy="60" r="50" />
                </svg>
                <div>
                  <b>12</b>
                  <span>ngày</span>
                </div>
              </div>
              <div className="streak-badge">
                <span>🔥</span>
                <div>
                  <b>12 ngày</b>
                  <small>Chuỗi dài nhất</small>
                </div>
              </div>
            </div>
          </article>

          <article className="component-card wide tickets-card">
            <header>
              <span>07</span>
              <h3>Vé khởi hành</h3>
              <code>6 loại hành trình</code>
            </header>
            <div className="tickets">
              {skins.map((item, index) => (
                <Ticket
                  key={item.id}
                  index={index}
                  accent={item.variants[0].accent}
                  surface={item.light.surface}
                  ink={item.light.ink}
                />
              ))}
            </div>
          </article>
        </div>
      </section>

      <section className="doc-section interaction" id="tuong-tac">
        <SectionTitle
          kicker="04 · Điều hướng & phản hồi"
          title="luôn trong tầm tay."
          note="Dock giữ nguyên vị trí, kích thước và hành vi. Chất liệu thay đổi theo giao diện; màu nút chụp theo hành trình đang hoạt động."
        />
        <div className="phone-pair">
          <article className="phone-demo">
            <div className="phone-label">
              <span>Thanh nổi · {skin.short}</span>
              <b>358 × 64</b>
            </div>
            <div className="phone-canvas">
              <div className="canvas-title">
                <span>thứ năm, 12 tháng 6</span>
                <h3>hành trình.</h3>
              </div>
              <div className="mini-cards">
                <i />
                <i />
                <i />
              </div>
              <div className={`journey-wheel ${wheelOpen ? "open" : ""}`}>
                <button className="disc one">
                  <span>🌿</span>
                  <b>Ngày 12</b>
                  <small>Giảm cân</small>
                </button>
                <button className="disc two">
                  <span>📒</span>
                  <b>Ngày 8</b>
                  <small>Tiếng Anh</small>
                </button>
                <button className="disc three">
                  <span>＋</span>
                  <b>Mới</b>
                  <small>Tạo thêm</small>
                </button>
              </div>
              <div className="floating-dock">
                <button className="dock-tab active">
                  <Icon name="map" />
                  <span>Hành trình</span>
                </button>
                <button
                  className="shutter"
                  aria-label="Chụp hoặc đổi hành trình"
                  onPointerDown={() => setWheelOpen(true)}
                  onPointerUp={() => setWheelOpen(false)}
                  onPointerLeave={() => setWheelOpen(false)}
                >
                  <Icon name="camera" size={32} />
                </button>
                <button className="dock-tab">
                  <Icon name="users" />
                  <span>Hội</span>
                </button>
              </div>
              <button
                className="wheel-alt"
                onClick={() => setWheelOpen(!wheelOpen)}
              >
                đổi hành trình
              </button>
            </div>
            <p>
              Nhấn giữ nút chụp 400 mili giây để mở vòng chọn. Thả tay để xác
              nhận.
            </p>
          </article>

          <article className="phone-demo camera-demo">
            <div className="phone-label">
              <span>Máy ảnh · luôn tối</span>
              <b>độ tương phản cao</b>
            </div>
            <div className="camera-canvas">
              <div className="camera-top">
                <button aria-label="Đóng">
                  <Icon name="close" />
                </button>
                <span>Ngày 12 · Giảm cân</span>
                <button aria-label="Tùy chọn">
                  <Icon name="spark" />
                </button>
              </div>
              <div className="viewfinder">
                <div className="focus-mark" />
                <span>Giữ khoảnh khắc thật</span>
              </div>
              <div className="camera-controls">
                <button className="gallery" aria-label="Ảnh gần đây" />
                <button className="camera-shutter" aria-label="Chụp ảnh">
                  <i />
                </button>
                <button className="flip" aria-label="Đổi máy ảnh">
                  ↻
                </button>
              </div>
            </div>
            <p>
              Màu giao diện không thay đổi nền máy ảnh; màu nút chụp vẫn nhận từ
              hành trình.
            </p>
          </article>
        </div>

        <div className="a11y-panel">
          <div>
            <span>05 · Trợ năng</span>
            <h2>
              rõ ràng
              <br />
              cho mọi người.
            </h2>
          </div>
          <ul>
            <li>
              <b>4,5:1</b>
              <span>Độ tương phản tối thiểu cho chữ</span>
            </li>
            <li>
              <b>44 điểm</b>
              <span>Vùng chạm tối thiểu</span>
            </li>
            <li>
              <b>135%</b>
              <span>Chữ lớn vẫn ôm nội dung</span>
            </li>
            <li>
              <b>150 mili giây</b>
              <span>Hòa cảnh khi giảm chuyển động</span>
            </li>
          </ul>
          <button className="open-sheet" onClick={() => setSheetOpen(true)}>
            Xem mẫu bảng trượt <Icon name="arrow" size={20} />
          </button>
        </div>
      </section>

      <footer>
        <div className="brand">
          <span>O</span>urney
        </div>
        <p>Hệ thống thiết kế · được tạo cho những tiến bộ có thể nhìn thấy.</p>
        <a href="#dau-trang">Về đầu trang ↑</a>
      </footer>

      {sheetOpen && (
        <div
          className="sheet-scrim"
          onMouseDown={(event) =>
            event.target === event.currentTarget && setSheetOpen(false)
          }
        >
          <div
            className="sheet"
            role="dialog"
            aria-modal="true"
            aria-labelledby="sheet-title"
          >
            <div className="grab" />
            <button
              className="sheet-close"
              onClick={() => setSheetOpen(false)}
              aria-label="Đóng bảng"
            >
              <Icon name="close" />
            </button>
            <span>Mẫu bảng trượt</span>
            <h2 id="sheet-title">giữ nhịp cùng nhau.</h2>
            <p>
              Bạn có thể đóng bằng nút phía trên hoặc chạm ra ngoài bảng này.
            </p>
            <button
              className="primary"
              onClick={() => {
                setSheetOpen(false)
                showToast()
              }}
            >
              Đã hiểu
            </button>
          </div>
        </div>
      )}
      <div className={`toast ${toast ? "show" : ""}`} role="status">
        <Icon name="check" size={19} />
        <span>Đã tạo lời nhắc lúc 20:00</span>
      </div>
    </main>
  )
}
