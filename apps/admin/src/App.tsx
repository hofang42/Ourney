import { Navigate, Route, Routes } from 'react-router-dom'
import { adminApi } from './lib/adminRpc'
import { I18nProvider } from './lib/i18n'
import { AuditPage } from './pages/AuditPage'
import { FeatureRequestsPage } from './pages/FeatureRequestsPage'
import { JourneysPage } from './pages/JourneysPage'
import { ModerationPage } from './pages/ModerationPage'
import { OverviewPage } from './pages/OverviewPage'
import { SettingsPage } from './pages/SettingsPage'
import { UsersPage } from './pages/UsersPage'
import { WaitlistPage } from './pages/WaitlistPage'
import { WordsPage } from './pages/WordsPage'
import { AdminAuthGuard, AdminShell } from './ui/Shell'

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
          <Routes>
            <Route path="/" element={<OverviewPage />} />
            <Route path="/moderation" element={<ModerationPage />} />
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
