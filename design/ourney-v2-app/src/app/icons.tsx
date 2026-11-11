import type { CSSProperties, ReactNode, SVGProps } from "react"

export type OIconName = "journeys" | "squad" | "camera" | "activity" | "profile" | "settings" | "back" | "close" | "plus" | "share" | "lock" | "eye" | "eye-off" | "heart" | "star" | "flame" | "trophy" | "map-pin" | "clock" | "image" | "trash" | "more" | "check" | "warning" | "wifi-off" | "cloud-off" | "sun" | "moon" | "desktop" | "sign-out" | "nudge" | "copy" | "caret-right" | "caret-down" | "timer" | "film" | "calendar" | "switch-camera" | "lightning" | "search" | "email" | "phone" | "book" | "fitness" | "scales" | "trip" | "edit" | "paper-plane" | "flag" | "cat" | "type-weight" | "type-study" | "type-trip" | "type-couple" | "type-workout" | "type-custom" | "react-clap" | "react-flex" | "react-heart" | "react-laugh" | "react-fire" | "react-wave" | "pine" | "cloud" | "ghost-body" | "crew-dot" | "crew-dot-empty"

export const oIconNames: OIconName[] = [
  "journeys",
  "squad",
  "camera",
  "activity",
  "profile",
  "settings",
  "back",
  "close",
  "plus",
  "share",
  "lock",
  "eye",
  "eye-off",
  "heart",
  "star",
  "flame",
  "trophy",
  "map-pin",
  "clock",
  "image",
  "trash",
  "more",
  "check",
  "warning",
  "wifi-off",
  "cloud-off",
  "sun",
  "moon",
  "desktop",
  "sign-out",
  "nudge",
  "copy",
  "caret-right",
  "caret-down",
  "timer",
  "film",
  "calendar",
  "switch-camera",
  "lightning",
  "search",
  "email",
  "phone",
  "book",
  "fitness",
  "scales",
  "trip",
  "edit",
  "paper-plane",
  "flag",
  "cat",
  "type-weight",
  "type-study",
  "type-trip",
  "type-couple",
  "type-workout",
  "type-custom",
  "react-clap",
  "react-flex",
  "react-heart",
  "react-laugh",
  "react-fire",
  "react-wave",
  "pine",
  "cloud",
  "ghost-body",
  "crew-dot",
  "crew-dot-empty",
]

export type JourneyType = "Giảm cân" | "Tiếng Anh" | "Chuyến đi" | "Cặp đôi" | "Tập luyện" | "Tự đặt"

type Props = Omit<SVGProps<SVGSVGElement>, "name"> & {
  name: OIconName
  size?: number
  active?: boolean
  weight?: string
}

const P = ({ d }: { d: string }) => <path d={d} />
const C = (props: SVGProps<SVGCircleElement>) => <circle {...props} />

function drawing(name: OIconName): ReactNode {
  switch (name) {
    case "journeys":
      return (
        <>
          <P d="M3.5 5.5 9 3l6 2.5L20.5 3v15.5L15 21l-6-2.5L3.5 21Z" />
          <P d="M9 3v15.5M15 5.5V21" />
          <P d="m6 14 2-2 3 2 4-5 2 2" />
        </>
      )
    case "squad":
      return (
        <>
          <C cx="9" cy="8" r="3" />
          <C cx="17" cy="9" r="2.5" />
          <P d="M3.5 19c.4-4 2.2-6 5.5-6s5.1 2 5.5 6M14 14c3.7-.5 5.8 1.2 6.3 4.5" />
        </>
      )
    case "camera":
      return (
        <>
          <P d="M4 7.5h3l1.5-2h7l1.5 2h3v11H4Z" />
          <C cx="12" cy="13" r="3.5" />
        </>
      )
    case "activity":
      return (
        <>
          <P d="M6.5 17.5h11l-1.5-2V11c0-2.7-1.5-4.6-4-4.8C9.5 6.4 8 8.3 8 11v4.5Z" />
          <P d="M10 19.5c.8 1 3.2 1 4 0M10 4.5h4" />
        </>
      )
    case "profile":
      return (
        <>
          <C cx="12" cy="8" r="3.5" />
          <P d="M5 20c.5-4.6 2.8-7 7-7s6.5 2.4 7 7" />
        </>
      )
    case "settings":
      return (
        <>
          <C cx="12" cy="12" r="3" />
          <P d="m12 3 1 2.2 2.5.8 2.1-1 1.5 1.5-1 2.2.8 2.5L21 12l-2.2 1 .2 2.6 1 2-1.7 1.5-2-1-2.5.8L12 21l-1-2.2-2.6-.8-2.1 1-1.5-1.6 1-2.1L3 12l2.2-1L5 8.5l-1-2 1.7-1.6 2 1 2.5-.8Z" />
        </>
      )
    case "back":
      return (
        <>
          <P d="m10 5-7 7 7 7" />
          <P d="M4 12h17" />
        </>
      )
    case "close":
      return (
        <>
          <P d="m5 5 14 14M19 5 5 19" />
        </>
      )
    case "plus":
      return (
        <>
          <P d="M12 4v16M4 12h16" />
        </>
      )
    case "share":
      return (
        <>
          <C cx="18" cy="5" r="2.5" />
          <C cx="6" cy="12" r="2.5" />
          <C cx="18" cy="19" r="2.5" />
          <P d="m8.2 10.8 7.5-4.5M8.2 13.2l7.5 4.5" />
        </>
      )
    case "lock":
      return (
        <>
          <P d="M6 10h12v10H6Z" />
          <P d="M8.5 10V7.5a3.5 3.5 0 0 1 7 0V10" />
          <P d="M12 14v2.5" />
        </>
      )
    case "eye":
      return (
        <>
          <P d="M2.5 12s3.5-6 9.5-6 9.5 6 9.5 6-3.5 6-9.5 6-9.5-6-9.5-6Z" />
          <C cx="12" cy="12" r="2.8" />
        </>
      )
    case "eye-off":
      return (
        <>
          <P d="M3 4 21 20M5 8c-1.6 1.5-2.5 4-2.5 4s3.5 6 9.5 6c1.5 0 2.8-.4 4-1M9 6.5c1-.4 2-.5 3-.5 6 0 9.5 6 9.5 6s-.7 1.2-1.8 2.5" />
        </>
      )
    case "heart":
      return (
        <P d="M12 20S4 15.5 4 9.5C4 5 9.5 4 12 8c2.5-4 8-3 8 1.5 0 6-8 10.5-8 10.5Z" />
      )
    case "star":
      return (
        <P d="m12 3 2.6 5.4 5.9.8-4.3 4.2 1 5.9-5.2-2.8-5.2 2.8 1-5.9-4.3-4.2 5.9-.8Z" />
      )
    case "flame":
      return (
        <>
          <path
            className="o-flame-outer"
            d="M12 21c-4.4 0-7-2.6-7-6.5 0-3 2-5.2 4.3-7.7.1 2 1.1 3 2 3.5.4-3.5 2.1-5.8 4.3-7.3.1 3.6 3.4 5.7 3.4 10 0 4.8-3 8-7 8Z"
          />
          <path
            className="o-flame-inner"
            d="M12 18.6c-2 0-3.3-1.2-3.3-3 0-1.4.8-2.5 2-3.6.1 1 .6 1.6 1.2 1.9.2-1.7 1-2.8 2-3.6.1 1.7 1.8 2.8 1.8 5.1 0 2-1.5 3.2-3.7 3.2Z"
          />
        </>
      )
    case "trophy":
      return (
        <>
          <P d="M7 4h10v5c0 3.5-2 5.5-5 5.5S7 12.5 7 9Z" />
          <P d="M7 6H4v2c0 2 1.2 3 3.5 3M17 6h3v2c0 2-1.2 3-3.5 3M12 14.5V19M8 20h8" />
        </>
      )
    case "map-pin":
      return (
        <>
          <P d="M12 21s7-6.5 7-12a7 7 0 0 0-14 0c0 5.5 7 12 7 12Z" />
          <C cx="12" cy="9" r="2.5" />
        </>
      )
    case "clock":
    case "timer":
      return (
        <>
          <C cx="12" cy="12" r="8" />
          <P d="M12 7v5l3.5 2M9 2h6" />
        </>
      )
    case "image":
      return (
        <>
          <P d="M3 5h18v14H3Z" />
          <C cx="8" cy="9" r="1.5" />
          <P d="m4 17 5-5 3 3 2-2 6 5" />
        </>
      )
    case "trash":
      return (
        <>
          <P d="M5 7h14M9 4h6l1 3M7 7l1 14h8l1-14M10 11v6M14 11v6" />
        </>
      )
    case "more":
      return (
        <>
          <C cx="5" cy="12" r="1.2" />
          <C cx="12" cy="12" r="1.2" />
          <C cx="19" cy="12" r="1.2" />
        </>
      )
    case "check":
      return <P d="m6 12.5 4 4 8-9" />
    case "warning":
      return (
        <>
          <P d="m12 3 9 17H3Z" />
          <P d="M12 8v5M12 17h.01" />
        </>
      )
    case "wifi-off":
      return (
        <>
          <P d="M3 8c4.8-3.8 10.3-4.2 15.5-1.2M6 12c2.8-2.2 5.7-2.7 8.8-1.4M9.5 16c1.5-1 3.2-.9 4.5.2M3 3l18 18" />
        </>
      )
    case "cloud-off":
      return (
        <>
          <P d="M5.5 17H5a3 3 0 0 1-.8-5.9A6.5 6.5 0 0 1 15 6.5a4.5 4.5 0 0 1 4.2 6.1M3 3l18 18" />
        </>
      )
    case "sun":
      return (
        <>
          <C cx="12" cy="12" r="3.5" />
          <P d="M12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M19 5l-2 2M7 17l-2 2" />
        </>
      )
    case "moon":
      return <P d="M20 15.5A8.5 8.5 0 0 1 8.5 4 8.5 8.5 0 1 0 20 15.5Z" />
    case "desktop":
      return (
        <>
          <P d="M3 4h18v13H3Z" />
          <P d="M9 21h6M12 17v4" />
        </>
      )
    case "sign-out":
      return (
        <>
          <P d="M10 4H4v16h6M14 8l4 4-4 4M8 12h10" />
        </>
      )
    case "nudge":
      return (
        <>
          <P d="M8 12V7a2 2 0 0 1 4 0v4-1M12 10V5a2 2 0 0 1 4 0v6M16 9a2 2 0 0 1 4 0v4c0 5-3 8-7 8h-1c-3 0-5-1.5-7-4l-2-3c-1-2 1.5-3.5 3-2l2 2" />
        </>
      )
    case "copy":
      return (
        <>
          <P d="M8 8h12v12H8Z" />
          <P d="M16 8V4H4v12h4" />
        </>
      )
    case "caret-right":
      return <P d="m9 5 7 7-7 7" />
    case "caret-down":
      return <P d="m5 9 7 7 7-7" />
    case "film":
      return (
        <>
          <P d="M3 5h18v14H3Z" />
          <P d="M7 5v14M17 5v14M3 9h4M17 9h4M3 15h4M17 15h4" />
        </>
      )
    case "calendar":
      return (
        <>
          <P d="M4 6h16v15H4Z" />
          <P d="M8 3v6M16 3v6M4 10h16" />
        </>
      )
    case "switch-camera":
      return (
        <>
          <P d="M5 8h3l1.5-2h5L16 8h3v10H5Z" />
          <P d="m9 12 2-2M9 12l2 2M15 14l-2 2M15 14l-2-2" />
        </>
      )
    case "lightning":
      return <P d="m13 2-8 12h6l-1 8 9-13h-6Z" />
    case "search":
      return (
        <>
          <C cx="10.5" cy="10.5" r="6" />
          <P d="m15 15 5 5" />
        </>
      )
    case "email":
      return (
        <>
          <P d="M3 5h18v14H3Z" />
          <P d="m4 7 8 6 8-6" />
        </>
      )
    case "phone":
      return (
        <>
          <P d="M8 3h8v18H8Z" />
          <P d="M11 17h2" />
        </>
      )
    case "book":
      return (
        <>
          <P d="M4 4h6c2 0 2 2 2 2v14c0-2-2-2-2-2H4ZM20 4h-6c-2 0-2 2-2 2v14c0-2 2-2 2-2h6Z" />
        </>
      )
    case "fitness":
      return (
        <>
          <P d="M7 8v8M4 10v4M17 8v8M20 10v4M7 12h10" />
        </>
      )
    case "scales":
      return (
        <>
          <P d="M12 4v16M7 20h10M5 7h14M5 7l-3 6h6ZM19 7l-3 6h6Z" />
        </>
      )
    case "trip":
      return (
        <>
          <P d="M6 7h12v14H6Z" />
          <P d="M9 7V4h6v3M9 11h6M10 21v1M14 21v1" />
        </>
      )
    case "edit":
      return (
        <>
          <P d="m5 17-1 4 4-1L20 8l-3-3Z" />
          <P d="m14 8 3 3" />
        </>
      )
    case "paper-plane":
      return (
        <>
          <P d="m3 11 18-8-7 18-3-7Z" />
          <P d="m11 14 10-11" />
        </>
      )
    case "flag":
      return (
        <>
          <P d="M5 21V4M5 5h12l-2 4 2 4H5" />
        </>
      )
    case "cat":
      return (
        <>
          <P d="M6 9 5 4l4 2c2-1 4-1 6 0l4-2-1 5c2 5-1 11-6 11S4 14 6 9Z" />
          <P d="M9 12h.01M15 12h.01M10 16c1.2.7 2.8.7 4 0" />
        </>
      )
    case "type-weight":
      return (
        <P d="M12 3.2c5.5 0 9 3.5 9 8.8s-3.5 8.8-9 8.8S3 17.3 3 12s3.5-8.8 9-8.8Zm0 5C9.6 8.2 8.1 9.7 8.1 12s1.5 3.8 3.9 3.8 3.9-1.5 3.9-3.8-1.5-3.8-3.9-3.8Z" />
      )
    case "type-study":
      return (
        <P d="M3.5 3.5h5.7v10.2c0 1.7.9 2.6 2.8 2.6s2.8-.9 2.8-2.6V3.5h5.7v10.8c0 4.4-3.2 7-8.5 7s-8.5-2.6-8.5-7Z" />
      )
    case "type-trip":
      return (
        <>
          <P d="M2.5 3h19v18h-19Z" />
          <P d="M4 4h5.2v2.4C10.5 4.6 12.4 3.6 15 3.6c.8 0 1.6.1 2.2.3l-.6 5.2c-.8-.3-1.6-.5-2.5-.5-3 0-4.5 1.6-4.5 4.9V21H4Z" />
        </>
      )
    case "type-couple":
      return (
        <>
          <P d="M2.2 4.3h19.6v15.4H2.2Z" />
          <P d="M18.3 14.9c-1.7 1.2-3.8 1.8-6.2 1.8-4.5 0-7.4-2.4-7.4-6.3 0-4 3-6.5 7.3-6.5 4.5 0 7.1 2.6 7.1 7.2v1.3H10c.4 1 1.4 1.5 3 1.5 1.5 0 2.8-.4 4.1-1.2ZM10 9.4h3.8c-.1-1.1-.8-1.7-1.9-1.7-1 0-1.7.6-1.9 1.7Z" />
        </>
      )
    case "type-workout":
      return (
        <>
          <P d="M3.5 20.5v-17h5.2l6.6 9.1V3.5h5.2v17h-5.2l-6.6-9v9Z" />
          <C cx="6.2" cy="6.2" r="1.15" />
          <C cx="17.8" cy="17.8" r="1.15" />
          <C cx="17.8" cy="6.2" r=".85" />
        </>
      )
    case "type-custom":
      return <P d="M2.8 3.5h6l3.3 7.1 3.2-7.1h5.9L14.8 16v5H9.2v-5Z" />
    case "react-clap":
      return (
        <>
          <P d="m5 13 5-6 2 2 2-4 2 2 2-2 2 2-5 11c-2 4-8 3-10 0l-2-3Z" />
          <P d="m4 10-2-2M7 6 6 3M11 5l1-3" />
        </>
      )
    case "react-flex":
      return (
        <>
          <P d="M5 17c2-1 2-4 3-6l3 1 1-5 3-1 2 3c4 1 5 4 3 7-2 4-6 5-10 4Z" />
          <P d="M8 11 5 9l-2 3 2 5" />
        </>
      )
    case "react-heart":
      return (
        <P d="M12 20S4 15.5 4 9.5C4 5 9.5 4 12 8c2.5-4 8-3 8 1.5 0 6-8 10.5-8 10.5Z" />
      )
    case "react-laugh":
      return (
        <>
          <C cx="12" cy="12" r="9" />
          <P d="M7 9c1-1 2-1 3 0M14 9c1-1 2-1 3 0M7 14h10c-1 5-9 5-10 0Z" />
        </>
      )
    case "react-fire":
      return (
        <P d="M12 21c-4 0-7-2.8-7-6.5 0-3 2-5.4 4.5-7.8 0 2 1 3.2 2.2 3.8.3-3.8 2.2-6.2 4.5-7.7.1 3.8 3.8 6 3.8 10.2 0 4.5-3.2 7.5-7 7.5Z" />
      )
    case "react-wave":
      return (
        <>
          <P d="M6 13V7a2 2 0 0 1 4 0v4-6a2 2 0 0 1 4 0v6-5a2 2 0 0 1 4 0v6-3a2 2 0 0 1 4 0v6c0 4-3 7-7 7h-2c-4 0-6-2-8-5l-2-3c-1-2 2-3 3-1l2 2" />
        </>
      )
    case "pine":
      return (
        <>
          <P d="m12 2-5 7h3l-5 6h5l-4 5h12l-4-5h5l-5-6h3Z" />
          <P d="M12 20v2" />
        </>
      )
    case "cloud":
      return <P d="M5 18a4 4 0 0 1-.5-8A6 6 0 0 1 16 8a5 5 0 1 1 1 10Z" />
    case "ghost-body":
      return (
        <>
          <C cx="12" cy="5" r="2.5" />
          <P d="M8 21v-7l-2 3M16 21v-7l2 3M8 10c1-2 7-2 8 0v5H8Z" />
        </>
      )
    case "crew-dot":
      return <C cx="12" cy="12" r="6" fill="currentColor" />
    case "crew-dot-empty":
      return <C cx="12" cy="12" r="6" />
  }
}

const typeIcon: Record<JourneyType, OIconName> = {
  "Giảm cân": "type-weight",
  "Tiếng Anh": "type-study",
  "Chuyến đi": "type-trip",
  "Cặp đôi": "type-couple",
  "Tập luyện": "type-workout",
  "Tự đặt": "type-custom",
}

const typeColor: Record<JourneyType, string> = {
  "Giảm cân": "#10B981",
  "Tiếng Anh": "#FF9F1C",
  "Chuyến đi": "#C2452B",
  "Cặp đôi": "#FF4D6D",
  "Tập luyện": "#2AA7E0",
  "Tự đặt": "#A13CC9",
}

const palette: Record<OIconName, string> = {
  journeys: "#C2452B",
  squad: "#FF9F1C",
  camera: "#10B981",
  activity: "#FF4D6D",
  profile: "#A13CC9",
  settings: "#2AA7E0",
  back: "#2AA7E0",
  close: "#C2452B",
  plus: "#10B981",
  share: "#2AA7E0",
  lock: "#2AA7E0",
  eye: "#A13CC9",
  "eye-off": "#A13CC9",
  heart: "#FF4D6D",
  star: "#FF9F1C",
  flame: "#C2452B",
  trophy: "#FF9F1C",
  "map-pin": "#C2452B",
  clock: "#2AA7E0",
  image: "#10B981",
  trash: "#C2452B",
  more: "#A13CC9",
  check: "#10B981",
  warning: "#FF9F1C",
  "wifi-off": "#C2452B",
  "cloud-off": "#2AA7E0",
  sun: "#FF9F1C",
  moon: "#A13CC9",
  desktop: "#2AA7E0",
  "sign-out": "#C2452B",
  nudge: "#FF9F1C",
  copy: "#2AA7E0",
  "caret-right": "#2AA7E0",
  "caret-down": "#2AA7E0",
  timer: "#FF9F1C",
  film: "#C2452B",
  calendar: "#FF4D6D",
  "switch-camera": "#10B981",
  lightning: "#FF9F1C",
  search: "#2AA7E0",
  email: "#FF9F1C",
  phone: "#10B981",
  book: "#FF9F1C",
  fitness: "#A13CC9",
  scales: "#10B981",
  trip: "#C2452B",
  edit: "#A13CC9",
  "paper-plane": "#2AA7E0",
  flag: "#C2452B",
  cat: "#FF9F1C",
  "type-weight": "#10B981",
  "type-study": "#FF9F1C",
  "type-trip": "#C2452B",
  "type-couple": "#FF4D6D",
  "type-workout": "#2AA7E0",
  "type-custom": "#A13CC9",
  "react-clap": "#FF9F1C",
  "react-flex": "#A13CC9",
  "react-heart": "#FF4D6D",
  "react-laugh": "#FF9F1C",
  "react-fire": "#C2452B",
  "react-wave": "#2AA7E0",
  pine: "#10B981",
  cloud: "#2AA7E0",
  "ghost-body": "#A13CC9",
  "crew-dot": "#FF9F1C",
  "crew-dot-empty": "#F3E3C3",
}

const tilts = [-5, 3, -2, 5, -4, 2, -3, 4] as const

type IconArtProps = {
  name: OIconName
  layer: string
}

function IconArt({ name, layer }: IconArtProps) {
  return <g className={`o-icon-art o-icon-${layer}`}>{drawing(name)}</g>
}

export function OIcon({
  name,
  size = 24,
  active = false,
  weight: _weight,
  className = "",
  style,
  ...props
}: Props) {
  const tier =
    size >= 24 ? (active ? "full" : "flat") : size >= 16 ? "mid" : "tiny"
  const tilt =
    tier === "full" ? tilts[oIconNames.indexOf(name) % tilts.length] : 0
  return (
    <svg
      viewBox="0 0 24 24"
      width={size}
      height={size}
      className={`o-icon o-icon-${name} o-icon-${tier} ${
        active ? "o-icon-active" : "o-icon-inactive"
      } ${className}`}
      style={
        {
          "--o-icon-color": palette[name],
          "--o-icon-tilt": `${tilt}deg`,
          ...style,
        } as CSSProperties
      }
      aria-hidden={props["aria-label"] ? undefined : true}
      {...props}
    >
      <g className="o-icon-sticker">
        {tier === "full" && <IconArt name={name} layer="shadow" />}
        {tier === "full" && <IconArt name={name} layer="diecut" />}
        {tier !== "tiny" && <IconArt name={name} layer="ink" />}
        <IconArt name={name} layer="shape" />
      </g>
    </svg>
  )
}

export function TypeBadge({
  type,
  size = 40,
  className = "",
}: {
  type: JourneyType
  size?: number
  className?: string
}) {
  return (
    <span
      className={`ourney-type-badge ${className}`}
      style={
        {
          width: size,
          height: size,
          "--type-badge": typeColor[type],
        } as CSSProperties
      }
      aria-hidden="true"
    >
      <OIcon name={typeIcon[type]} size={Math.round(size * 0.72)} active />
    </span>
  )
}
