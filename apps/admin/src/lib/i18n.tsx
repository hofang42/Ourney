import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from 'react'

export type Lang = 'vi' | 'en'
export type ThemeMode = 'light' | 'dark'

type I18nContextValue = {
  lang: Lang
  setLang: (lang: Lang) => void
  toggleLang: () => void
  theme: ThemeMode
  setTheme: (theme: ThemeMode) => void
  toggleTheme: () => void
  t: (vi: string, en: string) => string
}

const I18nContext = createContext<I18nContextValue | null>(null)

export function I18nProvider({
  children,
  initialLang,
  initialTheme,
}: {
  children: ReactNode
  initialLang?: Lang
  initialTheme?: ThemeMode
}) {
  const [lang, setLangState] = useState<Lang>(() => {
    if (initialLang) return initialLang
    try {
      const qLang = new URLSearchParams(window.location.search).get('lang')
      if (qLang === 'vi' || qLang === 'en') return qLang
      const saved = window.localStorage.getItem('ourney_admin_lang')
      if (saved === 'vi' || saved === 'en') return saved
    } catch {
      // Ignore storage error in restricted environments
    }
    return 'vi'
  })

  const [theme, setThemeState] = useState<ThemeMode>(() => {
    if (initialTheme) return initialTheme
    try {
      const qTheme = new URLSearchParams(window.location.search).get('theme')
      if (qTheme === 'light' || qTheme === 'dark') return qTheme
      const saved = window.localStorage.getItem('ourney_admin_theme')
      if (saved === 'light' || saved === 'dark') return saved
    } catch {
      // Ignore storage error
    }
    return 'light'
  })

  useEffect(() => {
    document.documentElement.lang = lang
    document.documentElement.dataset.lang = lang
    try {
      window.localStorage.setItem('ourney_admin_lang', lang)
    } catch {
      // Ignore
    }
  }, [lang])

  useEffect(() => {
    document.documentElement.dataset.theme = theme
    try {
      window.localStorage.setItem('ourney_admin_theme', theme)
    } catch {
      // Ignore
    }
  }, [theme])

  const setLang = (next: Lang) => setLangState(next)
  const toggleLang = () => setLangState((prev) => (prev === 'vi' ? 'en' : 'vi'))
  const setTheme = (next: ThemeMode) => setThemeState(next)
  const toggleTheme = () =>
    setThemeState((prev) => (prev === 'light' ? 'dark' : 'light'))

  const t = (vi: string, en: string) => (lang === 'vi' ? vi : en)

  return (
    <I18nContext.Provider
      value={{
        lang,
        setLang,
        toggleLang,
        theme,
        setTheme,
        toggleTheme,
        t,
      }}
    >
      {children}
    </I18nContext.Provider>
  )
}

export function useI18n(): I18nContextValue {
  const ctx = useContext(I18nContext)
  if (!ctx) {
    throw new Error('useI18n must be used inside I18nProvider')
  }
  return ctx
}
