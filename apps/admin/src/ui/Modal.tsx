import { useEffect, useId, useRef, type ReactNode } from 'react'
import { useI18n } from '../lib/i18n'
import { OIcon } from './Icon'

const FOCUSABLE_SELECTOR =
  'button:not(:disabled), [href], input:not(:disabled), select:not(:disabled), textarea:not(:disabled), [tabindex]:not([tabindex="-1"])'

export function AccessibleModal({
  title,
  onClose,
  variant = 'modal',
  children,
}: {
  title: string
  onClose: () => void
  variant?: 'modal' | 'drawer'
  children: ReactNode
}) {
  const titleId = useId()
  const containerRef = useRef<HTMLDivElement | null>(null)
  const previousFocusRef = useRef<HTMLElement | null>(null)
  const onCloseRef = useRef(onClose)
  onCloseRef.current = onClose

  useEffect(() => {
    previousFocusRef.current =
      document.activeElement instanceof HTMLElement
        ? document.activeElement
        : null

    const container = containerRef.current
    if (container) {
      const firstInput = container.querySelector<HTMLElement>(
        'input:not(:disabled), textarea:not(:disabled), select:not(:disabled), button:not(:disabled)',
      )
      ;(firstInput ?? container).focus()
    }

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault()
        onCloseRef.current()
        return
      }
      if (e.key === 'Tab' && containerRef.current) {
        const focusables = Array.from(
          containerRef.current.querySelectorAll<HTMLElement>(FOCUSABLE_SELECTOR),
        )
        if (focusables.length === 0) {
          e.preventDefault()
          return
        }
        const first = focusables[0]
        const last = focusables[focusables.length - 1]
        if (e.shiftKey && document.activeElement === first) {
          e.preventDefault()
          last.focus()
        } else if (!e.shiftKey && document.activeElement === last) {
          e.preventDefault()
          first.focus()
        }
      }
    }

    document.addEventListener('keydown', handleKeyDown)
    return () => {
      document.removeEventListener('keydown', handleKeyDown)
      if (
        previousFocusRef.current &&
        document.body.contains(previousFocusRef.current)
      ) {
        previousFocusRef.current.focus()
      }
    }
  }, [])

  return (
    <div
      className={variant === 'drawer' ? 'drawer-scrim' : 'modal-scrim'}
      role="dialog"
      aria-modal="true"
      aria-labelledby={titleId}
      onClick={(e) => {
        if (e.target === e.currentTarget) {
          onClose()
        }
      }}
    >
      <div
        ref={containerRef}
        tabIndex={-1}
        className={variant === 'drawer' ? 'drawer-panel' : 'modal-card'}
      >
        <h3 id={titleId} className="sr-only">
          {title}
        </h3>
        {children}
      </div>
    </div>
  )
}

export function PaginationBar({
  total,
  limit,
  offset,
  onChangeOffset,
}: {
  total: number
  limit: number
  offset: number
  onChangeOffset: (nextOffset: number) => void
}) {
  const { t } = useI18n()
  if (total <= limit && offset === 0) return null

  const start = total === 0 ? 0 : offset + 1
  const end = Math.min(total, offset + limit)
  const canPrev = offset > 0
  const canNext = offset + limit < total

  return (
    <div
      className="pagination-bar"
      role="navigation"
      aria-label={t('Phân trang danh sách', 'List pagination')}
    >
      <span className="tabular" style={{ fontWeight: 700, fontSize: '0.84rem' }}>
        {t(
          `Hiển thị ${start}–${end} trên tổng số ${total}`,
          `Showing ${start}–${end} of ${total}`,
        )}
      </span>
      <div style={{ display: 'flex', gap: 8 }}>
        <button
          type="button"
          className="btn"
          disabled={!canPrev}
          onClick={() => onChangeOffset(Math.max(0, offset - limit))}
        >
          <OIcon name="back" size={16} />
          <span>{t('Trang trước', 'Previous')}</span>
        </button>
        <button
          type="button"
          className="btn"
          disabled={!canNext}
          onClick={() => onChangeOffset(offset + limit)}
        >
          <span>{t('Trang sau', 'Next')}</span>
          <OIcon name="caret-right" size={16} />
        </button>
      </div>
    </div>
  )
}
