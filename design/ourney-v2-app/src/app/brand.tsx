type WordmarkProps = {
  size?: number
  variant?: "color" | "mono" | "small"
  className?: string
}

const letters = ["o", "u", "r", "n", "e", "y"] as const

export function Wordmark({
  size = 132,
  variant = "color",
  className = "",
}: WordmarkProps) {
  if (variant === "small") {
    return (
      <span
        className={`ourney-mark ${className}`}
        style={{ "--wordmark-size": `${size}px` } as CSSProperties}
        aria-label="ourney"
      >
        <i>o</i>
      </span>
    )
  }
  return (
    <span
      className={`ourney-wordmark wordmark-${variant} ${className}`}
      style={{ "--wordmark-size": `${size}px` } as CSSProperties}
      aria-label="ourney"
    >
      {letters.map((letter) => (
        <i key={letter} className={`wordmark-${letter}`}>
          {letter}
        </i>
      ))}
    </span>
  )
}
import type { CSSProperties } from "react"
