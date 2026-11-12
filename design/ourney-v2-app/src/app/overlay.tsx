import type { ReactNode } from "react"
import { createPortal } from "react-dom"

export function PhoneOverlay({ children }: { children: ReactNode }) {
  const phoneScreen = document.querySelector(".phone-screen")
  return phoneScreen ? createPortal(children, phoneScreen) : children
}
