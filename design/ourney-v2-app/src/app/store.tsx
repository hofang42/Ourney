import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react"

export type UserKind = "new" | "old"
export type Theme = "light" | "dark"
export type ThemePreference = Theme | "system"
export type OtpMode = "normal" | "expired" | "locked"
export type CameraPermission = "unknown" | "granted" | "deferred" | "denied"
export type AuthMethod = "email" | "phone" | "google"
export type OtpPurpose = "login" | "reset-password"
export type HubState = "normal" | "empty" | "loading" | "error"
export type HubHeroState = "default" | "done" | "milestone" | "group"
export type ActivityState = "normal" | "empty" | "loading"
export type JourneyDemoState = "normal" | "day1" | "loading" | "error" | "only" | "broken" | "removed" | "hidden"
export type ReminderBanner = {
  journeyId: string
  kind: "daily" | "streak"
} | null
export type Draft = {
  type?: Journey["type"]
  skin?: string
  previousSkin?: string
  who?: "solo" | "group" | "couple"
  reminder?: "07:00" | "12:00" | "21:30"
  personOne?: string
  personTwo?: string
  side?: "left" | "right"
  duration?: 7 | 14 | 21 | 30 | 66
  noEnd?: boolean
  reminderEnabled?: boolean
  reminderTime?: string
  visibility?: "private" | "link" | "group" | "couple"
  dates?: string
  answers?: Record<string, string | number | boolean>
  variant?: number
  cover?: number
  ghostCaptured?: boolean
  ghostPhoto?: string
  fromOnboarding?: boolean
}
export type OnboardingChoice = Pick<Draft, "type" | "who" | "reminder">
export type CreateProgress = {
  route: string
  draft: Draft
}
export type ImportedPhoto = {
  id: string
  date?: string
  day?: number
  extra?: boolean
}
type ImportedJourneyInput = {
  type: Journey["type"]
  skin: string
  photos: ImportedPhoto[]
  startDate: string
  endDate: string
  archived: boolean
  place: string
  totalDays: number
}
export type Profile = {
  name: string
  username: string
  avatar?: number
}

export type Journey = {
  id: string
  type: "Giảm cân" | "Tiếng Anh" | "Chuyến đi" | "Cặp đôi" | "Tập luyện" | "Tự đặt"
  skin: string
  variant: number
  name: string
  day: number
  streak: number
  todayDone?: boolean
  shared?: boolean
  lastCaption?: string
  lastMood?: string
  lastWeight?: number
  lastMinutes?: number
  attendance?: number
  frameCount?: number
  lastPlace?: string
  partnerShot?: boolean
  ownShot?: boolean
  pairComplete?: boolean
  lastDish?: string
  lastCook?: string
  lastHearts?: number
  totalKm?: number
  lastKm?: number
  pace?: string
  hud?: string
  archived?: boolean
  cover?: number
  reminderTime?: string
  inviteCode?: string
  members?: string[]
  visibility?: "private" | "link"
  owner?: boolean
  imported?: boolean
  importedPhotos?: ImportedPhoto[]
  startDate?: string
  endDate?: string
  totalDays?: number
}

type CheckInPayload = {
  caption: string
  mood: string
  weight?: number
  minutes?: number
  place?: string
  dish?: string
  cook?: string
  hearts?: number
  km?: number
  pace?: string
}

const seededJourneys: Journey[] = [
  {
    id: "quiet",
    type: "Giảm cân",
    skin: "quiet",
    variant: 0,
    name: "30 ngày cơ thể",
    day: 21,
    streak: 21,
    shared: false,
    lastWeight: 62,
  },
  {
    id: "ielts",
    type: "Tiếng Anh",
    skin: "squad",
    variant: 0,
    name: "Hội IELTS 7.5",
    day: 21,
    streak: 18,
    shared: true,
    attendance: 3,
    lastMinutes: 45,
    inviteCode: "K7Q2M9XA",
    members: ["Linh", "An", "Hà", "Nam", "Minh"],
    owner: true,
  },
  {
    id: "dalat",
    type: "Chuyến đi",
    skin: "memory",
    variant: 0,
    name: "Đà Lạt 5 ngày",
    day: 3,
    streak: 3,
    shared: true,
    attendance: 4,
    frameCount: 12,
    lastPlace: "Đồi chè Cầu Đất",
    inviteCode: "DLAT2026",
    members: ["Hà", "Linh", "An", "Nam", "Minh"],
    owner: false,
  },
  {
    id: "couple",
    type: "Cặp đôi",
    skin: "couple",
    variant: 0,
    name: "30 ngày nấu cho nhau",
    day: 18,
    streak: 18,
    shared: true,
    partnerShot: true,
    ownShot: false,
    pairComplete: false,
    lastHearts: 3,
    inviteCode: "NAMLINH2",
    members: ["Linh", "Nam"],
    owner: true,
  },
  {
    id: "running",
    type: "Tập luyện",
    skin: "flexer",
    variant: 0,
    name: "Chạy sáng 30 ngày",
    day: 21,
    streak: 21,
    shared: true,
    attendance: 3,
    totalKm: 92.4,
    lastKm: 5.42,
    pace: "5:04",
    hud: "HUD đậm",
    inviteCode: "RUNN2026",
    members: ["Minh", "Linh", "An", "Nam"],
    owner: false,
  },
  {
    id: "minimal",
    type: "Tự đặt",
    skin: "minimal",
    variant: 0,
    name: "Đọc 10 trang",
    day: 24,
    streak: 24,
    shared: true,
    attendance: 3,
    inviteCode: "DOCS1024",
    members: ["Linh", "An", "Nam", "Hà"],
    owner: true,
  },
]

function mergeSeedJourneys(current: Journey[]) {
  const existingIds = new Set(current.map((journey) => journey.id))
  const missing = seededJourneys.filter(
    (journey) => !existingIds.has(journey.id),
  )
  return missing.length ? [...current, ...missing] : current
}

type AppStore = {
  user: UserKind
  setUser: (user: UserKind) => void
  journeys: Journey[]
  activeJourneyId: string | null
  setActiveJourneyId: (id: string) => void
  selectJourney: (id: string) => void
  theme: Theme
  setTheme: (theme: Theme) => void
  themePreference: ThemePreference
  setThemePreference: (theme: ThemePreference) => void
  offline: boolean
  setOffline: (value: boolean) => void
  readOnly: boolean
  setReadOnly: (value: boolean) => void
  missedDay: boolean
  setMissedDay: (value: boolean) => void
  largeType: boolean
  setLargeType: (value: boolean) => void
  reduceMotion: boolean
  setReduceMotion: (value: boolean) => void
  reduceTransparency: boolean
  setReduceTransparency: (value: boolean) => void
  appIcon: string
  setAppIcon: (value: string) => void
  activityState: ActivityState
  setActivityState: (value: ActivityState) => void
  activityUnread: boolean
  markActivityRead: () => void
  createSheetOpen: boolean
  setCreateSheetOpen: (value: boolean) => void
  openCreateJourney: () => void
  setActiveSkin: (skin: string) => void
  setActiveVariant: (variant: number) => void
  signedIn: boolean
  setSignedIn: (value: boolean) => void
  email: string
  setEmail: (value: string) => void
  draft: Draft
  setDraft: (draft: Partial<Draft>) => void
  createProgress: CreateProgress | null
  saveCreateProgress: (route: string) => void
  resumeCreateRoute: string
  onboardingChoice: OnboardingChoice | null
  setOnboardingChoice: (choice: OnboardingChoice) => void
  skipOnboarding: () => void
  authMethod: AuthMethod
  authDestination: string
  otpPurpose: OtpPurpose
  setAuthAttempt: (
    method: AuthMethod,
    destination: string,
    purpose?: OtpPurpose,
  ) => void
  linkedMethods: AuthMethod[]
  linkAuthMethod: (method: AuthMethod) => void
  hasPassword: boolean
  setHasPassword: (value: boolean) => void
  otpMode: OtpMode
  setOtpMode: (mode: OtpMode) => void
  cameraPermission: CameraPermission
  setCameraPermission: (value: CameraPermission) => void
  sessionExpired: boolean
  setSessionExpired: (value: boolean) => void
  notificationSheetOpen: boolean
  setNotificationSheetOpen: (value: boolean) => void
  notificationPromptHandled: boolean
  setNotificationPromptHandled: (value: boolean) => void
  journeyWheelOpen: boolean
  setJourneyWheelOpen: (value: boolean) => void
  profile: Profile | null
  setProfile: (profile: Profile) => void
  hubState: HubState
  setHubState: (state: HubState) => void
  hubHeroState: HubHeroState
  setHubHeroState: (state: HubHeroState) => void
  createOrigin: "/hub" | "/camera"
  beginCreate: (
    origin: "/hub" | "/camera",
    options?: {
      fromOnboarding?: boolean
      prefill?: OnboardingChoice
    },
  ) => void
  discardCreate: () => void
  restoreSeedJourneys: () => void
  checkedIn: boolean
  setCheckedIn: (value: boolean) => void
  inviteSheetOpen: boolean
  setInviteSheetOpen: (value: boolean) => void
  addJourneyFromDraft: () => string
  addImportedJourney: (input: ImportedJourneyInput) => string
  checkInJourney: (id: string, payload: CheckInPayload) => void
  setJourneyHud: (id: string, hud: string) => void
  updateJourney: (id: string, patch: Partial<Journey>) => void
  reactions: Record<string, string>
  reactionCounts: Record<string, Record<string, number>>
  setReaction: (key: string, reaction: string) => void
  blocked: string[]
  blockUser: (name: string) => void
  deleteLatestCheckIn: (id: string) => void
  nudged: string[]
  nudge: (name: string) => void
  pendingJoin: string
  setPendingJoin: (code: string) => void
  addJoinedJourney: (code: string) => string
  unblockUser: (name: string) => void
  reminderEnabled: Record<string, boolean>
  setReminderEnabled: (id: string, enabled: boolean) => void
  streakReminder: boolean
  setStreakReminder: (enabled: boolean) => void
  hideWeightOnShare: boolean
  setHideWeightOnShare: (enabled: boolean) => void
  blurPhotosOnShare: boolean
  setBlurPhotosOnShare: (enabled: boolean) => void
  notificationPermission: "granted" | "denied"
  journeyDemoState: JourneyDemoState
  setJourneyDemoState: (state: JourneyDemoState) => void
  journeyOwner: boolean
  setJourneyOwner: (owner: boolean) => void
  reminderBanner: ReminderBanner
  setReminderBanner: (banner: ReminderBanner) => void
  appToast: string
  showToast: (message: string) => void
  removeJourney: (id: string) => void
  resetAccount: () => void
}

const StoreContext = createContext<AppStore | null>(null)

const CREATE_PROGRESS_KEY = "ourney-create-progress"

function readCreateProgress(): CreateProgress | null {
  try {
    const value = window.localStorage.getItem(CREATE_PROGRESS_KEY)
    return value ? JSON.parse(value) as CreateProgress : null
  } catch {
    return null
  }
}

function writeCreateProgress(progress: CreateProgress | null) {
  try {
    if (progress) {
      window.localStorage.setItem(CREATE_PROGRESS_KEY, JSON.stringify(progress))
    } else {
      window.localStorage.removeItem(CREATE_PROGRESS_KEY)
    }
  } catch {
    // The in-memory draft still works when storage is unavailable.
  }
}

export function StoreProvider({ children }: { children: ReactNode }) {
  const initialCreateProgress = useRef(readCreateProgress())
  const [user, setUserState] = useState<UserKind>("old")
  const [journeys, setJourneys] = useState<Journey[]>(seededJourneys)
  const [activeJourneyId, setActiveJourneyIdState] = useState<string | null>(
    "ielts",
  )
  const [theme, setTheme] = useState<Theme>("light")
  const [themePreference, setThemePreferenceState] =
    useState<ThemePreference>("light")
  const [offline, setOffline] = useState(false)
  const [readOnly, setReadOnly] = useState(false)
  const [missedDay, setMissedDay] = useState(false)
  const [largeType, setLargeType] = useState(false)
  const [reduceMotion, setReduceMotion] = useState(false)
  const [reduceTransparency, setReduceTransparency] = useState(false)
  const [appIcon, setAppIcon] = useState("default")
  const [activityState, setActivityState] = useState<ActivityState>("normal")
  const [activityUnread, setActivityUnread] = useState(true)
  const [createSheetOpen, setCreateSheetOpen] = useState(false)
  const [signedIn, setSignedIn] = useState(true)
  const [email, setEmail] = useState("linh.tran@gmail.com")
  const [draft, setDraftState] = useState<Draft>(
    initialCreateProgress.current?.draft ?? {},
  )
  const [createProgress, setCreateProgress] = useState<CreateProgress | null>(
    initialCreateProgress.current,
  )
  const [onboardingChoice, setOnboardingChoiceState] =
    useState<OnboardingChoice | null>(null)
  const [authMethod, setAuthMethod] = useState<AuthMethod>("email")
  const [authDestination, setAuthDestination] = useState("linh.tran@gmail.com")
  const [otpPurpose, setOtpPurpose] = useState<OtpPurpose>("login")
  const [linkedMethods, setLinkedMethods] = useState<AuthMethod[]>(["email"])
  const [hasPassword, setHasPassword] = useState(true)
  const [otpMode, setOtpMode] = useState<OtpMode>("normal")
  const [cameraPermission, setCameraPermission] =
    useState<CameraPermission>("granted")
  const [sessionExpired, setSessionExpired] = useState(false)
  const [notificationSheetOpen, setNotificationSheetOpen] = useState(false)
  const [notificationPromptHandled, setNotificationPromptHandled] =
    useState(false)
  const [journeyWheelOpen, setJourneyWheelOpen] = useState(false)
  const [profile, setProfile] = useState<Profile | null>(null)
  const [hubState, setHubState] = useState<HubState>("normal")
  const [hubHeroState, setHubHeroState] = useState<HubHeroState>("default")
  const [createOrigin, setCreateOrigin] = useState<"/hub" | "/camera">("/hub")
  const [checkedIn, setCheckedIn] = useState(false)
  const [inviteSheetOpen, setInviteSheetOpen] = useState(false)
  const [reactions, setReactions] = useState<Record<string, string>>({})
  const [reactionCounts, setReactionCounts] =
    useState<Record<string, Record<string, number>>>({})
  const reactionsRef = useRef<Record<string, string>>({})
  const [blocked, setBlocked] = useState<string[]>([])
  const [nudged, setNudged] = useState<string[]>([])
  const [pendingJoin, setPendingJoin] = useState("")
  const [reminderEnabled, setReminderEnabledState] =
    useState<Record<string, boolean>>({})
  const [streakReminder, setStreakReminder] = useState(true)
  const [hideWeightOnShare, setHideWeightOnShare] = useState(true)
  const [blurPhotosOnShare, setBlurPhotosOnShare] = useState(true)
  const [journeyDemoState, setJourneyDemoState] =
    useState<JourneyDemoState>("normal")
  const [journeyOwner, setJourneyOwner] = useState(true)
  const [reminderBanner, setReminderBanner] = useState<ReminderBanner>(null)
  const [appToast, setAppToast] = useState("")

  useEffect(() => {
    if (user === "old") setJourneys(mergeSeedJourneys)
  }, [user])

  function setUser(nextUser: UserKind) {
    setUserState(nextUser)
    if (nextUser === "new") {
      setJourneys([])
      setActiveJourneyIdState(null)
      setSignedIn(false)
      setEmail("")
      setCameraPermission("unknown")
      setDraftState({})
      setCreateProgress(null)
      writeCreateProgress(null)
      setOnboardingChoiceState(null)
      setProfile(null)
      setLinkedMethods([])
      setHasPassword(false)
      setAuthMethod("email")
      setAuthDestination("")
      setOtpPurpose("login")
    } else {
      setJourneys((current) => mergeSeedJourneys(current))
      setActiveJourneyIdState("ielts")
      setSignedIn(true)
      setEmail("linh.tran@gmail.com")
      setCameraPermission("granted")
      setLinkedMethods(["email"])
      setHasPassword(true)
      setOnboardingChoiceState(null)
      setDraftState({})
      setCreateProgress(null)
      writeCreateProgress(null)
      setAuthMethod("email")
      setAuthDestination("linh.tran@gmail.com")
      setOtpPurpose("login")
    }
  }

  function updateActive(patch: Partial<Journey>) {
    if (!activeJourneyId) return
    setJourneys((current) =>
      current.map((journey) =>
        journey.id === activeJourneyId ? { ...journey, ...patch } : journey,
      ),
    )
  }

  const value = useMemo(
    () => ({
      user,
      setUser,
      journeys,
      activeJourneyId,
      setActiveJourneyId: setActiveJourneyIdState,
      selectJourney: (id: string) => setActiveJourneyIdState(id),
      theme,
      setTheme,
      themePreference,
      setThemePreference: (preference: ThemePreference) => {
        setThemePreferenceState(preference)
        if (preference === "system") {
          setTheme(
            window.matchMedia?.("(prefers-color-scheme: dark)").matches
              ? "dark"
              : "light",
          )
        } else {
          setTheme(preference)
        }
      },
      offline,
      setOffline,
      readOnly,
      setReadOnly,
      missedDay,
      setMissedDay,
      largeType,
      setLargeType,
      reduceMotion,
      setReduceMotion,
      reduceTransparency,
      setReduceTransparency,
      appIcon,
      setAppIcon,
      activityState,
      setActivityState,
      activityUnread,
      markActivityRead: () => setActivityUnread(false),
      createSheetOpen,
      setCreateSheetOpen,
      openCreateJourney: () => setCreateSheetOpen(true),
      setActiveSkin: (skin: string) => updateActive({ skin, variant: 0 }),
      setActiveVariant: (variant: number) => updateActive({ variant }),
      signedIn,
      setSignedIn,
      email,
      setEmail,
      draft,
      setDraft: (nextDraft: Partial<Draft>) => {
        const next = { ...draft, ...nextDraft }
        setDraftState(next)
        if (createProgress) {
          const updated = { ...createProgress, draft: next }
          setCreateProgress(updated)
          writeCreateProgress(updated)
        }
      },
      createProgress,
      saveCreateProgress: (route: string) => {
        const progress = { route, draft }
        setCreateProgress(progress)
        writeCreateProgress(progress)
      },
      resumeCreateRoute: createProgress?.route ?? "/create/1",
      onboardingChoice,
      setOnboardingChoice: (choice: OnboardingChoice) => {
        setOnboardingChoiceState(choice)
      },
      skipOnboarding: () => {
        setOnboardingChoiceState(null)
        setDraftState({})
        setCreateProgress(null)
        writeCreateProgress(null)
      },
      authMethod,
      authDestination,
      otpPurpose,
      setAuthAttempt: (
        method: AuthMethod,
        destination: string,
        purpose: OtpPurpose = "login",
      ) => {
        setAuthMethod(method)
        setAuthDestination(destination)
        setOtpPurpose(purpose)
      },
      linkedMethods,
      linkAuthMethod: (method: AuthMethod) =>
        setLinkedMethods((current) =>
          current.includes(method) ? current : [...current, method],
        ),
      hasPassword,
      setHasPassword,
      otpMode,
      setOtpMode,
      cameraPermission,
      setCameraPermission,
      sessionExpired,
      setSessionExpired,
      notificationSheetOpen,
      setNotificationSheetOpen,
      notificationPromptHandled,
      setNotificationPromptHandled,
      journeyWheelOpen,
      setJourneyWheelOpen,
      profile,
      setProfile,
      hubState,
      setHubState,
      hubHeroState,
      setHubHeroState,
      createOrigin,
      beginCreate: (
        origin: "/hub" | "/camera",
        options?: {
          fromOnboarding?: boolean
          prefill?: OnboardingChoice
        },
      ) => {
        setCreateOrigin(origin)
        if (createProgress && !options) {
          setDraftState(createProgress.draft)
          return
        }
        const onboarding =
          options?.prefill ??
          (options?.fromOnboarding ? onboardingChoice : null)
        if (onboarding?.type) {
          const defaultSkin: Record<Journey["type"], string> = {
            "Giảm cân": "quiet",
            "Tiếng Anh": "squad",
            "Chuyến đi": "memory",
            "Cặp đôi": "couple",
            "Tập luyện": "flexer",
            "Tự đặt": "minimal",
          }
          const nextDraft: Draft = {
            type: onboarding.type,
            skin:
              onboarding.who === "couple"
                ? "couple"
                : defaultSkin[onboarding.type],
            who: onboarding.who,
            reminderEnabled: true,
            reminder: onboarding.reminder,
            reminderTime: onboarding.reminder,
            fromOnboarding: true,
          }
          setDraftState(nextDraft)
          const progress = { route: "/create/1", draft: nextDraft }
          setCreateProgress(progress)
          writeCreateProgress(progress)
          return
        }
        const nextDraft = options?.prefill ?? {}
        setDraftState(nextDraft)
        const progress = { route: "/create/1", draft: nextDraft }
        setCreateProgress(progress)
        writeCreateProgress(progress)
      },
      discardCreate: () => {
        setDraftState({})
        setCreateProgress(null)
        writeCreateProgress(null)
      },
      restoreSeedJourneys: () => {
        setJourneys(seededJourneys)
        setActiveJourneyIdState("ielts")
      },
      checkedIn,
      setCheckedIn,
      inviteSheetOpen,
      setInviteSheetOpen,
      addJourneyFromDraft: () => {
        const id = `journey-${Date.now()}`
        const type = draft.type ?? "Tự đặt"
        const defaultNames: Record<Journey["type"], string> = {
          "Giảm cân": "Hồ sơ riêng tư",
          "Tiếng Anh": String(draft.answers?.trophy || "Cúp 7.5"),
          "Tập luyện": `30 ngày ${String(draft.answers?.sport || "Chạy").toLocaleLowerCase("vi")}`,
          "Chuyến đi": String(draft.answers?.place || "Đà Lạt"),
          "Cặp đôi": "30 ngày nấu cho nhau",
          "Tự đặt": String(draft.answers?.habit || "Thói quen mới"),
        }
        const nextJourney: Journey = {
          id,
          type,
          skin: draft.skin ?? "minimal",
          variant: draft.variant ?? 0,
          name: defaultNames[type],
          day: 1,
          streak: 0,
          shared: draft.who === "group" || draft.who === "couple",
          frameCount: type === "Chuyến đi" ? 0 : undefined,
          partnerShot: type === "Cặp đôi" ? false : undefined,
          ownShot: type === "Cặp đôi" ? false : undefined,
          pairComplete: type === "Cặp đôi" ? false : undefined,
          totalKm: type === "Tập luyện" ? 0 : undefined,
          lastKm: type === "Tập luyện" ? 0 : undefined,
          pace: type === "Tập luyện" ? "0:00" : undefined,
          hud:
            type === "Tập luyện"
              ? String(draft.answers?.hud || "HUD đậm")
              : undefined,
        }
        setJourneys((current) => [nextJourney, ...current])
        setActiveJourneyIdState(id)
        setCreateProgress(null)
        writeCreateProgress(null)
        setDraftState({})
        return id
      },
      addImportedJourney: ({
        type,
        skin,
        photos,
        startDate,
        endDate,
        archived,
        place,
        totalDays,
      }: ImportedJourneyInput) => {
        const id = `imported-${Date.now()}`
        const imported: Journey = {
          id,
          type,
          skin,
          variant: 0,
          name: place || `Ký ức ${type.toLocaleLowerCase("vi")}`,
          day: totalDays,
          streak: 0,
          shared: false,
          visibility: "private",
          imported: true,
          importedPhotos: photos,
          startDate,
          endDate,
          totalDays,
          archived,
          owner: true,
          members: ["Linh"],
          lastWeight: type === "Giảm cân" ? 62 : undefined,
          totalKm: type === "Tập luyện" ? 0 : undefined,
          lastPlace: place,
        }
        setJourneys((current) => [imported, ...current])
        setActiveJourneyIdState(id)
        return id
      },
      checkInJourney: (id: string, payload: CheckInPayload) => {
        setJourneys((current) =>
          current.map((journey) =>
            journey.id === id
              ? {
                  ...journey,
                  day: journey.todayDone ? journey.day : journey.day + 1,
                  streak: journey.todayDone
                    ? journey.streak
                    : journey.streak + 1,
                  todayDone: true,
                  lastCaption: payload.caption,
                  lastMood: payload.mood,
                  lastWeight: payload.weight,
                  lastMinutes: payload.minutes,
                  attendance:
                    journey.skin === "squad" && !journey.todayDone
                      ? Math.min(5, (journey.attendance ?? 3) + 1)
                      : journey.attendance,
                  frameCount:
                    journey.skin === "memory" && !journey.todayDone
                      ? Math.min(24, (journey.frameCount ?? 12) + 1)
                      : journey.frameCount,
                  lastPlace: payload.place ?? journey.lastPlace,
                  ownShot: journey.skin === "couple" ? true : journey.ownShot,
                  pairComplete:
                    journey.skin === "couple"
                      ? Boolean(journey.partnerShot)
                      : journey.pairComplete,
                  lastDish: payload.dish ?? journey.lastDish,
                  lastCook: payload.cook ?? journey.lastCook,
                  lastHearts: payload.hearts ?? journey.lastHearts,
                  totalKm:
                    journey.skin === "flexer" && !journey.todayDone
                      ? Number(
                          (
                            (journey.totalKm ?? 92.4) +
                            (payload.km ?? journey.lastKm ?? 5.42)
                          ).toFixed(2),
                        )
                      : journey.totalKm,
                  lastKm: payload.km ?? journey.lastKm,
                  pace: payload.pace ?? journey.pace,
                }
              : journey,
          ),
        )
      },
      setJourneyHud: (id: string, hud: string) => {
        setJourneys((current) =>
          current.map((journey) =>
            journey.id === id ? { ...journey, hud } : journey,
          ),
        )
      },
      updateJourney: (id: string, patch: Partial<Journey>) => {
        setJourneys((current) =>
          current.map((journey) =>
            journey.id === id ? { ...journey, ...patch } : journey,
          ),
        )
      },
      reactions,
      reactionCounts,
      setReaction: (key: string, reaction: string) => {
        const previous = reactionsRef.current[key] ?? ""
        const next = previous === reaction ? "" : reaction
        reactionsRef.current = { ...reactionsRef.current, [key]: next }
        setReactions(reactionsRef.current)
        setReactionCounts((counts) => {
          const row = { ...(counts[key] ?? {}) }
          if (previous) row[previous] = Math.max(0, (row[previous] ?? 0) - 1)
          if (next) row[next] = (row[next] ?? 0) + 1
          return { ...counts, [key]: row }
        })
      },
      blocked,
      blockUser: (name: string) =>
        setBlocked((current) =>
          current.includes(name) ? current : [...current, name],
        ),
      deleteLatestCheckIn: (id: string) => {
        setJourneys((current) =>
          current.map((journey) =>
            journey.id === id
              ? {
                  ...journey,
                  day: Math.max(1, journey.day - 1),
                  streak: Math.max(0, journey.streak - 1),
                  todayDone: false,
                }
              : journey,
          ),
        )
      },
      nudged,
      nudge: (name: string) =>
        setNudged((current) =>
          current.includes(name) ? current : [...current, name],
        ),
      pendingJoin,
      setPendingJoin,
      addJoinedJourney: (code: string) => {
        const existing = journeys.find((journey) => journey.id === "ielts")
        if (existing) {
          setActiveJourneyIdState(existing.id)
          setPendingJoin("")
          return existing.id
        }
        const id = `joined-${code.toLocaleLowerCase()}`
        const joined: Journey = {
          id,
          type: "Tiếng Anh",
          skin: "squad",
          variant: 0,
          name: "Hội IELTS 7.5",
          day: 21,
          streak: 0,
          shared: true,
          attendance: 5,
          inviteCode: code,
          members: ["Hà", "Linh", "An", "Nam", "Minh"],
        }
        setJourneys((current) => [joined, ...current])
        setActiveJourneyIdState(id)
        setPendingJoin("")
        return id
      },
      unblockUser: (name: string) =>
        setBlocked((current) => current.filter((item) => item !== name)),
      reminderEnabled,
      setReminderEnabled: (id: string, enabled: boolean) =>
        setReminderEnabledState((current) => ({ ...current, [id]: enabled })),
      streakReminder,
      setStreakReminder,
      hideWeightOnShare,
      setHideWeightOnShare,
      blurPhotosOnShare,
      setBlurPhotosOnShare,
      notificationPermission:
        cameraPermission === "denied" ? "denied" as const : "granted" as const,
      journeyDemoState,
      setJourneyDemoState,
      journeyOwner,
      setJourneyOwner,
      reminderBanner,
      setReminderBanner,
      appToast,
      showToast: (message: string) => {
        setAppToast(message)
        window.setTimeout(() => setAppToast(""), 1800)
      },
      removeJourney: (id: string) => {
        setJourneys((current) => current.filter((journey) => journey.id !== id))
        setActiveJourneyIdState((current) => (current === id ? null : current))
      },
      resetAccount: () => {
        setJourneys([])
        setActiveJourneyIdState(null)
        setProfile(null)
        setSignedIn(false)
        setBlocked([])
        setNudged([])
        setPendingJoin("")
        setDraftState({})
        setCreateProgress(null)
        writeCreateProgress(null)
        setOnboardingChoiceState(null)
        setLinkedMethods([])
        setHasPassword(false)
        setReminderEnabledState({})
        setJourneyDemoState("normal")
        setReminderBanner(null)
        setAppToast("")
      },
    }),
    [
      user,
      journeys,
      activeJourneyId,
      theme,
      themePreference,
      offline,
      readOnly,
      missedDay,
      largeType,
      reduceMotion,
      reduceTransparency,
      appIcon,
      activityState,
      activityUnread,
      createSheetOpen,
      signedIn,
      email,
      draft,
      createProgress,
      onboardingChoice,
      authMethod,
      authDestination,
      otpPurpose,
      linkedMethods,
      hasPassword,
      otpMode,
      cameraPermission,
      sessionExpired,
      notificationSheetOpen,
      notificationPromptHandled,
      journeyWheelOpen,
      profile,
      hubState,
      hubHeroState,
      createOrigin,
      checkedIn,
      inviteSheetOpen,
      reactions,
      reactionCounts,
      blocked,
      nudged,
      pendingJoin,
      reminderEnabled,
      streakReminder,
      hideWeightOnShare,
      blurPhotosOnShare,
      journeyDemoState,
      journeyOwner,
      reminderBanner,
      appToast,
    ],
  )

  return <StoreContext.Provider value={value}>{children}</StoreContext.Provider>
}

export function useStore() {
  const store = useContext(StoreContext)
  if (!store) throw new Error("StoreProvider is missing")
  return store
}
