import { lazy, Suspense } from 'react'
import { Navigate, Route, Routes } from 'react-router-dom'
import { adminApi } from './lib/adminRpc'
import { I18nProvider, useI18n } from './lib/i18n'
import { AdminAuthGuard, AdminShell } from './ui/Shell'

function SessionLoadingFallback() {
  const { t } = useI18n()
  return (
    <div className="card" role="status">
      <span>{t('Đang tải phiên làm việc...', 'Loading session...')}</span>
    </div>
  )
}

const OverviewPage = lazy(() =>
  import('./pages/OverviewPage').then((m) => ({ default: m.OverviewPage })),
)
const ModerationPage = lazy(() =>
  import('./pages/ModerationPage').then((m) => ({ default: m.ModerationPage })),
)
const WordsPage = lazy(() =>
  import('./pages/WordsPage').then((m) => ({ default: m.WordsPage })),
)
const FeatureRequestsPage = lazy(() =>
  import('./pages/FeatureRequestsPage').then((m) => ({
    default: m.FeatureRequestsPage,
  })),
)
const WaitlistPage = lazy(() =>
  import('./pages/WaitlistPage').then((m) => ({ default: m.WaitlistPage })),
)
const UsersPage = lazy(() =>
  import('./pages/UsersPage').then((m) => ({ default: m.UsersPage })),
)
const JourneysPage = lazy(() =>
  import('./pages/JourneysPage').then((m) => ({ default: m.JourneysPage })),
)
const AuditPage = lazy(() =>
  import('./pages/AuditPage').then((m) => ({ default: m.AuditPage })),
)
const SettingsPage = lazy(() =>
  import('./pages/SettingsPage').then((m) => ({ default: m.SettingsPage })),
)

export function AppRoutes() {
  return (
    <AdminAuthGuard>
      {(admin, refreshAdmin) => (
        <AdminShell
          admin={admin}
          onSignOut={async () => {
            await adminApi.signOut()
            await refreshAdmin()
          }}
        >
          <Suspense fallback={<SessionLoadingFallback />}>
            <Routes>
              <Route path="/" element={<OverviewPage />} />
              <Route
                path="/moderation"
                element={<ModerationPage admin={admin} />}
              />
              <Route path="/words" element={<WordsPage />} />
              <Route
                path="/feature-requests"
                element={<FeatureRequestsPage />}
              />
              <Route
                path="/waitlist"
                element={<WaitlistPage admin={admin} />}
              />
              <Route path="/users" element={<UsersPage admin={admin} />} />
              <Route path="/users/:id" element={<UsersPage admin={admin} />} />
              <Route path="/journeys" element={<JourneysPage />} />
              <Route path="/audit" element={<AuditPage />} />
              <Route
                path="/settings"
                element={<SettingsPage admin={admin} />}
              />
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
          </Suspense>
        </AdminShell>
      )}
    </AdminAuthGuard>
  )
}

export function App() {
  return (
    <I18nProvider>
      <AppRoutes />
    </I18nProvider>
  )
}
