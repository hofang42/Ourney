import Foundation

/// Constants shared across the widget extension and host bridge.
public enum OurneyWidgetConstants {
  public static let appGroupId = "group.com.hofang42.ourney"
  public static let directoryName = "ourney_widgets"
  public static let snapshotFileName = "snapshot_v1.json"
  public static let stateFileName = "state.json"
  public static let thumbsSubdirectory = "thumbs"
}

public enum OurneyWidgetKind {
  public static let today = "OurneyTodayWidget"
  public static let streak = "OurneyStreakWidget"
  public static let squad = "OurneySquadWidget"
  public static let lockScreen = "OurneyLockScreenWidget"
}

/// Deep-link builder matching `normalizeDeepLink` in `apps/mobile/lib/app/redirect.dart` (§5.1).
public enum OurneyDeepLinks {
  public static let journeys = URL(string: "ourney://journeys")!
  public static let groups = URL(string: "ourney://groups")!
  public static let bareCapture = URL(string: "ourney://capture")!

  private static let queryValueAllowed: CharacterSet = {
    var cs = CharacterSet.urlQueryAllowed
    cs.remove(charactersIn: "&+=?#")
    return cs
  }()

  public static func capture(journeyId: String?) -> URL {
    guard let raw = journeyId?.trimmingCharacters(in: .whitespacesAndNewlines),
          !raw.isEmpty
    else {
      return bareCapture
    }
    var components = URLComponents()
    components.scheme = "ourney"
    components.host = "capture"
    if let encoded = raw.addingPercentEncoding(withAllowedCharacters: queryValueAllowed) {
      components.percentEncodedQuery = "journeyId=\(encoded)"
    } else {
      components.queryItems = [URLQueryItem(name: "journeyId", value: raw)]
    }
    return components.url ?? bareCapture
  }

  public static func journey(id: String) -> URL {
    let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty,
          let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
          let url = URL(string: "ourney://journey/\(encoded)")
    else {
      return journeys
    }
    return url
  }

  public static func group(id: String) -> URL {
    let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty,
          let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
          let url = URL(string: "ourney://groups/\(encoded)")
    else {
      return groups
    }
    return url
  }
}

/// Visual time-of-day urgency phase for a journey card.
public enum OurneyTimePhase: String, Equatable {
  case daytime
  case eveningCue
  case urgentAtRisk
  case completed
}

/// Root `snapshot_v1.json` contract (§4.3).
/// Privacy-by-omission invariant: contains zero fields for weight (`kg`), metrics,
/// health DNA (`goal`, `reason`), captions, email, or phone.
public struct WidgetSnapshot: Codable, Equatable {
  public var schemaVersion: Int
  public var generatedAtUtc: String
  public var authState: String
  public var locale: String
  public var themeMode: String
  public var privacy: WidgetPrivacySettings
  public var defaultJourneyId: String?
  public var totals: WidgetTotals
  public var journeys: [WidgetJourneyItem]
  public var squads: [WidgetSquadItem]
  public var liveWindow: WidgetLiveWindow?

  public init(
    schemaVersion: Int = 1,
    generatedAtUtc: String = "2026-11-24T00:00:00.000Z",
    authState: String = "ready",
    locale: String = "vi",
    themeMode: String = "system",
    privacy: WidgetPrivacySettings = WidgetPrivacySettings(),
    defaultJourneyId: String? = nil,
    totals: WidgetTotals = WidgetTotals(),
    journeys: [WidgetJourneyItem] = [],
    squads: [WidgetSquadItem] = [],
    liveWindow: WidgetLiveWindow? = nil
  ) {
    self.schemaVersion = schemaVersion
    self.generatedAtUtc = generatedAtUtc
    self.authState = authState
    self.locale = locale
    self.themeMode = themeMode
    self.privacy = privacy
    self.defaultJourneyId = defaultJourneyId
    self.totals = totals
    self.journeys = journeys
    self.squads = squads
    self.liveWindow = liveWindow
  }

  enum CodingKeys: String, CodingKey {
    case schemaVersion
    case generatedAtUtc
    case authState
    case locale
    case themeMode
    case privacy
    case defaultJourneyId
    case totals
    case journeys
    case squads
    case liveWindow
  }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    self.schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
    self.generatedAtUtc = try c.decodeIfPresent(String.self, forKey: .generatedAtUtc) ?? ""
    self.authState = try c.decodeIfPresent(String.self, forKey: .authState) ?? "ready"
    self.locale = try c.decodeIfPresent(String.self, forKey: .locale) ?? "vi"
    self.themeMode = try c.decodeIfPresent(String.self, forKey: .themeMode) ?? "system"
    self.privacy = try c.decodeIfPresent(WidgetPrivacySettings.self, forKey: .privacy) ?? WidgetPrivacySettings()
    self.defaultJourneyId = try c.decodeIfPresent(String.self, forKey: .defaultJourneyId)
    self.totals = try c.decodeIfPresent(WidgetTotals.self, forKey: .totals) ?? WidgetTotals()
    self.journeys = try c.decodeIfPresent([WidgetJourneyItem].self, forKey: .journeys) ?? []
    self.squads = try c.decodeIfPresent([WidgetSquadItem].self, forKey: .squads) ?? []
    self.liveWindow = try c.decodeIfPresent(WidgetLiveWindow.self, forKey: .liveWindow)
  }

  public var isSignedOutOrEmpty: Bool {
    authState == "signedOut" || authState == "unauthenticated" || journeys.isEmpty
  }

  /// Evaluates post-midnight rollover and time-of-day urgency phases at `referenceDate`
  /// with zero background app wakeups (§4.5.2).
  public func evaluated(at referenceDate: Date) -> WidgetSnapshot {
    guard !journeys.isEmpty || !squads.isEmpty else { return self }

    let evaluatedJourneys = journeys.map { $0.evaluated(at: referenceDate, locale: locale) }
    let evaluatedSquads = squads.map { squad in
      let matchingJourney = journeys.first(where: { $0.id == squad.journeyId })
      return squad.evaluated(
        at: referenceDate,
        timezone: matchingJourney?.timezone,
        utcOffsetMinutes: matchingJourney?.utcOffsetMinutes ?? 420
      )
    }

    let completedCount = evaluatedJourneys.filter(\.checkedInToday).count
    let pendingCount = evaluatedJourneys.count - completedCount
    let atRiskCount = evaluatedJourneys.filter { !$0.checkedInToday && $0.atRisk }.count
    let bestStreak = evaluatedJourneys.map(\.currentStreak).max() ?? 0

    let updatedTotals = WidgetTotals(
      activeCount: evaluatedJourneys.count,
      completedTodayCount: completedCount,
      pendingTodayCount: pendingCount,
      atRiskCount: atRiskCount,
      bestActiveStreak: bestStreak
    )

    var updatedWindow = liveWindow
    if let window = liveWindow,
       let deadline = WidgetDateParser.parseISO8601(window.deadlineUtc),
       referenceDate >= deadline {
      updatedWindow = nil
    }

    var copy = self
    copy.journeys = evaluatedJourneys
    copy.squads = evaluatedSquads
    copy.totals = updatedTotals
    copy.liveWindow = updatedWindow
    return copy
  }

  /// Computes up to 4 deterministic timeline refresh timestamps (`now`, `18:00` evening cue,
  /// `21:00` streak alert, and `00:00` earliest journey midnight rollover) for a single
  /// `getTimeline` pass (§4.5.2).
  public func scheduledTimelineDates(from now: Date) -> [Date] {
    var dates: [Date] = [now]
    var candidates: [Date] = []

    for journey in journeys {
      if !journey.checkedInToday {
        if let cue = WidgetDateParser.parseISO8601(journey.eveningCueAtUtc), cue > now {
          candidates.append(cue)
        }
        if let alert = WidgetDateParser.parseISO8601(journey.streakAlertAtUtc), alert > now {
          candidates.append(alert)
        }
      }
      if let midnight = WidgetDateParser.parseISO8601(journey.midnightRolloverUtc), midnight > now {
        candidates.append(midnight)
      }
    }

    for squad in squads {
      if let midnight = WidgetDateParser.parseISO8601(squad.midnightRolloverUtc), midnight > now {
        candidates.append(midnight)
      }
    }

    let sorted = candidates.sorted()
    for candidate in sorted {
      // Deduplicate timestamps within 30 seconds of an existing entry.
      if let last = dates.last, candidate.timeIntervalSince(last) < 30 {
        continue
      }
      dates.append(candidate)
      if dates.count >= 4 {
        break
      }
    }
    return dates
  }

  /// Selects the featured journey for `OurneyTodayWidget`, respecting the interactive
  /// `CycleTodayJourneyIntent` index in `state.json` when multiple pending journeys exist.
  public func selectedTodayJourney(state: WidgetInteractiveState = WidgetInteractiveState()) -> WidgetJourneyItem? {
    guard !journeys.isEmpty else { return nil }
    let pending = journeys.filter { !$0.checkedInToday }
    if !pending.isEmpty {
      if let preferredId = state.selectedTodayJourneyId,
         let match = pending.first(where: { $0.id == preferredId }) {
        return match
      }
      let idx = ((state.selectedTodayIndex % pending.count) + pending.count) % pending.count
      return pending[idx]
    }
    if let defaultId = defaultJourneyId,
       let match = journeys.first(where: { $0.id == defaultId }) {
      return match
    }
    return journeys.first
  }

  /// Selects the featured journey for `OurneyStreakWidget` (prefers `defaultJourneyId`,
  /// otherwise highest active streak or first journey).
  public func selectedStreakJourney(preferredId: String? = nil) -> WidgetJourneyItem? {
    guard !journeys.isEmpty else { return nil }
    if let id = preferredId, !id.isEmpty,
       let match = journeys.first(where: { $0.id == id }) {
      return match
    }
    if let defaultId = defaultJourneyId,
       let match = journeys.first(where: { $0.id == defaultId }) {
      return match
    }
    return journeys.max(by: { a, b in
      if a.currentStreak != b.currentStreak {
        return a.currentStreak < b.currentStreak
      }
      return !a.pinned && b.pinned
    }) ?? journeys.first
  }

  /// Selects the featured squad for `OurneySquadWidget`.
  public func selectedSquad(preferredId: String? = nil) -> WidgetSquadItem? {
    guard !squads.isEmpty else { return nil }
    if let id = preferredId, !id.isEmpty,
       let match = squads.first(where: { $0.journeyId == id }) {
      return match
    }
    if let defaultId = defaultJourneyId,
       let match = squads.first(where: { $0.journeyId == defaultId }) {
      return match
    }
    return squads.first(where: { !$0.meCheckedInToday }) ?? squads.first
  }
}

public struct WidgetPrivacySettings: Codable, Equatable {
  public var photoMode: String
  public var redactLockScreenTitles: Bool
  public var liveActivityEnabled: Bool

  public init(
    photoMode: String = "smart",
    redactLockScreenTitles: Bool = false,
    liveActivityEnabled: Bool = true
  ) {
    self.photoMode = photoMode
    self.redactLockScreenTitles = redactLockScreenTitles
    self.liveActivityEnabled = liveActivityEnabled
  }

  enum CodingKeys: String, CodingKey {
    case photoMode
    case redactLockScreenTitles
    case liveActivityEnabled
  }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    self.photoMode = try c.decodeIfPresent(String.self, forKey: .photoMode) ?? "smart"
    self.redactLockScreenTitles = try c.decodeIfPresent(Bool.self, forKey: .redactLockScreenTitles) ?? false
    self.liveActivityEnabled = try c.decodeIfPresent(Bool.self, forKey: .liveActivityEnabled) ?? true
  }

  public var allowsPhotosOnHomeScreen: Bool {
    photoMode != "off"
  }
}

public struct WidgetTotals: Codable, Equatable {
  public var activeCount: Int
  public var completedTodayCount: Int
  public var pendingTodayCount: Int
  public var atRiskCount: Int
  public var bestActiveStreak: Int

  public init(
    activeCount: Int = 0,
    completedTodayCount: Int = 0,
    pendingTodayCount: Int = 0,
    atRiskCount: Int = 0,
    bestActiveStreak: Int = 0
  ) {
    self.activeCount = activeCount
    self.completedTodayCount = completedTodayCount
    self.pendingTodayCount = pendingTodayCount
    self.atRiskCount = atRiskCount
    self.bestActiveStreak = bestActiveStreak
  }

  enum CodingKeys: String, CodingKey {
    case activeCount
    case completedTodayCount
    case pendingTodayCount
    case atRiskCount
    case bestActiveStreak
  }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    self.activeCount = try c.decodeIfPresent(Int.self, forKey: .activeCount) ?? 0
    self.completedTodayCount = try c.decodeIfPresent(Int.self, forKey: .completedTodayCount) ?? 0
    self.pendingTodayCount = try c.decodeIfPresent(Int.self, forKey: .pendingTodayCount) ?? 0
    self.atRiskCount = try c.decodeIfPresent(Int.self, forKey: .atRiskCount) ?? 0
    self.bestActiveStreak = try c.decodeIfPresent(Int.self, forKey: .bestActiveStreak) ?? 0
  }
}

public struct WidgetJourneyItem: Codable, Equatable, Identifiable {
  public var id: String
  public var title: String
  public var kind: String
  public var skinId: String
  public var colorVariant: Int
  public var typeIcon: String
  public var timezone: String
  public var utcOffsetMinutes: Int
  public var pinned: Bool
  public var dayNumber: Int
  public var totalDays: Int?
  public var currentStreak: Int
  public var bestStreak: Int
  public var checkedInToday: Bool
  public var atRisk: Bool
  public var eveningCueAtUtc: String?
  public var streakAlertAtUtc: String?
  public var midnightRolloverUtc: String?
  public var reminderAtUtc: String?
  public var heroThumbFile: String?
  public var heroThumbBlurred: Bool
  public var weekStrip: [WidgetWeekDay]

  public init(
    id: String,
    title: String,
    kind: String = "solo",
    skinId: String = "minimal",
    colorVariant: Int = 0,
    typeIcon: String = "type-custom",
    timezone: String = "Asia/Ho_Chi_Minh",
    utcOffsetMinutes: Int = 420,
    pinned: Bool = false,
    dayNumber: Int = 1,
    totalDays: Int? = 30,
    currentStreak: Int = 0,
    bestStreak: Int = 0,
    checkedInToday: Bool = false,
    atRisk: Bool = false,
    eveningCueAtUtc: String? = nil,
    streakAlertAtUtc: String? = nil,
    midnightRolloverUtc: String? = nil,
    reminderAtUtc: String? = nil,
    heroThumbFile: String? = nil,
    heroThumbBlurred: Bool = false,
    weekStrip: [WidgetWeekDay] = []
  ) {
    self.id = id
    self.title = title
    self.kind = kind
    self.skinId = skinId
    self.colorVariant = colorVariant
    self.typeIcon = typeIcon
    self.timezone = timezone
    self.utcOffsetMinutes = utcOffsetMinutes
    self.pinned = pinned
    self.dayNumber = dayNumber
    self.totalDays = totalDays
    self.currentStreak = currentStreak
    self.bestStreak = bestStreak
    self.checkedInToday = checkedInToday
    self.atRisk = atRisk
    self.eveningCueAtUtc = eveningCueAtUtc
    self.streakAlertAtUtc = streakAlertAtUtc
    self.midnightRolloverUtc = midnightRolloverUtc
    self.reminderAtUtc = reminderAtUtc
    self.heroThumbFile = heroThumbFile
    self.heroThumbBlurred = heroThumbBlurred
    self.weekStrip = weekStrip
  }

  enum CodingKeys: String, CodingKey {
    case id
    case title
    case kind
    case skinId
    case colorVariant
    case typeIcon
    case timezone
    case utcOffsetMinutes
    case pinned
    case dayNumber
    case totalDays
    case currentStreak
    case bestStreak
    case checkedInToday
    case atRisk
    case eveningCueAtUtc
    case streakAlertAtUtc
    case midnightRolloverUtc
    case reminderAtUtc
    case heroThumbFile
    case heroThumbBlurred
    case weekStrip
  }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try c.decode(String.self, forKey: .id)
    self.title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
    self.kind = try c.decodeIfPresent(String.self, forKey: .kind) ?? "solo"
    self.skinId = try c.decodeIfPresent(String.self, forKey: .skinId) ?? "minimal"
    self.colorVariant = try c.decodeIfPresent(Int.self, forKey: .colorVariant) ?? 0
    self.typeIcon = try c.decodeIfPresent(String.self, forKey: .typeIcon) ?? "type-custom"
    self.timezone = try c.decodeIfPresent(String.self, forKey: .timezone) ?? "Asia/Ho_Chi_Minh"
    self.utcOffsetMinutes = try c.decodeIfPresent(Int.self, forKey: .utcOffsetMinutes) ?? 420
    self.pinned = try c.decodeIfPresent(Bool.self, forKey: .pinned) ?? false
    self.dayNumber = try c.decodeIfPresent(Int.self, forKey: .dayNumber) ?? 1
    self.totalDays = try c.decodeIfPresent(Int.self, forKey: .totalDays)
    self.currentStreak = try c.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
    self.bestStreak = try c.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
    self.checkedInToday = try c.decodeIfPresent(Bool.self, forKey: .checkedInToday) ?? false
    self.atRisk = try c.decodeIfPresent(Bool.self, forKey: .atRisk) ?? false
    self.eveningCueAtUtc = try c.decodeIfPresent(String.self, forKey: .eveningCueAtUtc)
    self.streakAlertAtUtc = try c.decodeIfPresent(String.self, forKey: .streakAlertAtUtc)
    self.midnightRolloverUtc = try c.decodeIfPresent(String.self, forKey: .midnightRolloverUtc)
    self.reminderAtUtc = try c.decodeIfPresent(String.self, forKey: .reminderAtUtc)
    self.heroThumbFile = try c.decodeIfPresent(String.self, forKey: .heroThumbFile)
    self.heroThumbBlurred = try c.decodeIfPresent(Bool.self, forKey: .heroThumbBlurred) ?? false
    self.weekStrip = try c.decodeIfPresent([WidgetWeekDay].self, forKey: .weekStrip) ?? []
  }

  /// Determines the urgency phase at `referenceDate`.
  public func phase(at referenceDate: Date) -> OurneyTimePhase {
    if checkedInToday {
      return .completed
    }
    if let alertDate = WidgetDateParser.parseISO8601(streakAlertAtUtc),
       referenceDate >= alertDate,
       (atRisk || currentStreak > 0) {
      return .urgentAtRisk
    }
    if let cueDate = WidgetDateParser.parseISO8601(eveningCueAtUtc),
       referenceDate >= cueDate {
      return atRisk && streakAlertAtUtc == nil ? .urgentAtRisk : .eveningCue
    }
    return .daytime
  }

  /// Returns a copy of this journey item rolled forward if `referenceDate` has passed
  /// `midnightRolloverUtc` (§4.5.2).
  public func evaluated(at referenceDate: Date, locale: String = "vi") -> WidgetJourneyItem {
    guard let midnightDate = WidgetDateParser.parseISO8601(midnightRolloverUtc) else {
      var copy = self
      if !copy.checkedInToday,
         copy.currentStreak > 0,
         let alertDate = WidgetDateParser.parseISO8601(copy.streakAlertAtUtc),
         referenceDate >= alertDate {
        copy.atRisk = true
      }
      return copy
    }

    if referenceDate < midnightDate {
      var copy = self
      if !copy.checkedInToday,
         copy.currentStreak > 0,
         let alertDate = WidgetDateParser.parseISO8601(copy.streakAlertAtUtc),
         referenceDate >= alertDate {
        copy.atRisk = true
      }
      return copy
    }

    // One or more midnights have passed in the journey's timezone since the snapshot was written.
    let cal = WidgetDateParser.calendar(
      timezoneId: self.timezone,
      utcOffsetMinutes: self.utcOffsetMinutes
    )
    let extraDays = WidgetDateParser.extraDaysPassed(
      from: midnightDate,
      to: referenceDate,
      calendar: cal
    )

    var rolled = self
    let survivedFirstMidnight = (extraDays == 1) && self.checkedInToday
    rolled.checkedInToday = false
    rolled.dayNumber = self.dayNumber + extraDays
    rolled.currentStreak = survivedFirstMidnight ? self.currentStreak : 0
    rolled.atRisk = rolled.currentStreak > 0
    rolled.heroThumbFile = nil
    rolled.heroThumbBlurred = false

    rolled.midnightRolloverUtc = WidgetDateParser.formatISO8601(
      WidgetDateParser.addDays(extraDays, to: midnightDate, calendar: cal)
    )
    if let cue = WidgetDateParser.parseISO8601(self.eveningCueAtUtc) {
      rolled.eveningCueAtUtc = WidgetDateParser.formatISO8601(
        WidgetDateParser.addDays(extraDays, to: cue, calendar: cal)
      )
    }
    if let alert = WidgetDateParser.parseISO8601(self.streakAlertAtUtc) {
      rolled.streakAlertAtUtc = WidgetDateParser.formatISO8601(
        WidgetDateParser.addDays(extraDays, to: alert, calendar: cal)
      )
    }
    if let reminder = WidgetDateParser.parseISO8601(self.reminderAtUtc) {
      rolled.reminderAtUtc = WidgetDateParser.formatISO8601(
        WidgetDateParser.addDays(extraDays, to: reminder, calendar: cal)
      )
    }

    if !self.weekStrip.isEmpty {
      rolled.weekStrip = Self.rollWeekStrip(
        self.weekStrip,
        wasCheckedIn: self.checkedInToday,
        extraDays: extraDays,
        utcOffsetMinutes: self.utcOffsetMinutes,
        referenceDate: referenceDate,
        locale: locale
      )
    }

    return rolled
  }

  private static func rollWeekStrip(
    _ strip: [WidgetWeekDay],
    wasCheckedIn: Bool,
    extraDays: Int,
    utcOffsetMinutes: Int,
    referenceDate: Date,
    locale: String
  ) -> [WidgetWeekDay] {
    guard !strip.isEmpty else { return strip }
    var updated = strip
    if let lastIdx = updated.indices.last {
      // Finalize the snapshot's "today" cell.
      updated[lastIdx].state = wasCheckedIn ? "done" : "missed"
      if let prevDate = WidgetDateParser.parseDateOnly(updated[lastIdx].date) {
        updated[lastIdx].label = WidgetDateParser.weekdayShortLabel(
          for: prevDate,
          isToday: false,
          locale: locale
        )
      }
    }

    let steps = min(extraDays, 7)
    let baseDate: Date = {
      if let last = updated.last, let parsed = WidgetDateParser.parseDateOnly(last.date) {
        return parsed
      }
      return referenceDate.addingTimeInterval(TimeInterval(utcOffsetMinutes * 60))
    }()

    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

    for step in 1...steps {
      guard let nextDate = cal.date(byAdding: .day, value: step, to: baseDate) else { continue }
      let isNewToday = (step == steps)
      let dayNum = cal.component(.day, from: nextDate)
      let dateStr = WidgetDateParser.formatDateOnly(nextDate)
      let label = WidgetDateParser.weekdayShortLabel(
        for: nextDate,
        isToday: isNewToday,
        locale: locale
      )
      updated.append(
        WidgetWeekDay(
          date: dateStr,
          day: dayNum,
          label: label,
          state: isNewToday ? "today" : "missed"
        )
      )
    }

    if updated.count > 7 {
      updated = Array(updated.suffix(7))
    }
    return updated
  }
}

public struct WidgetWeekDay: Codable, Equatable {
  public var date: String
  public var day: Int
  public var label: String
  public var state: String

  public init(date: String, day: Int, label: String, state: String) {
    self.date = date
    self.day = day
    self.label = label
    self.state = state
  }

  public var isDone: Bool { state == "done" }
  public var isToday: Bool { state == "today" }
}

public struct WidgetSquadItem: Codable, Equatable, Identifiable {
  public var id: String { journeyId }
  public var journeyId: String
  public var title: String
  public var skinId: String
  public var colorVariant: Int
  public var typeIcon: String
  public var isCouple: Bool
  public var dayNumber: Int
  public var totalDays: Int?
  public var doneCount: Int
  public var memberCount: Int
  public var meCheckedInToday: Bool
  public var midnightRolloverUtc: String?
  public var members: [WidgetSquadMember]

  public init(
    journeyId: String,
    title: String,
    skinId: String = "squad",
    colorVariant: Int = 0,
    typeIcon: String = "type-study",
    isCouple: Bool = false,
    dayNumber: Int = 1,
    totalDays: Int? = 30,
    doneCount: Int = 0,
    memberCount: Int = 0,
    meCheckedInToday: Bool = false,
    midnightRolloverUtc: String? = nil,
    members: [WidgetSquadMember] = []
  ) {
    self.journeyId = journeyId
    self.title = title
    self.skinId = skinId
    self.colorVariant = colorVariant
    self.typeIcon = typeIcon
    self.isCouple = isCouple
    self.dayNumber = dayNumber
    self.totalDays = totalDays
    self.doneCount = doneCount
    self.memberCount = memberCount
    self.meCheckedInToday = meCheckedInToday
    self.midnightRolloverUtc = midnightRolloverUtc
    self.members = members
  }

  enum CodingKeys: String, CodingKey {
    case journeyId
    case title
    case skinId
    case colorVariant
    case typeIcon
    case isCouple
    case dayNumber
    case totalDays
    case doneCount
    case memberCount
    case meCheckedInToday
    case midnightRolloverUtc
    case members
  }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    self.journeyId = try c.decode(String.self, forKey: .journeyId)
    self.title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
    self.skinId = try c.decodeIfPresent(String.self, forKey: .skinId) ?? "squad"
    self.colorVariant = try c.decodeIfPresent(Int.self, forKey: .colorVariant) ?? 0
    self.typeIcon = try c.decodeIfPresent(String.self, forKey: .typeIcon) ?? "type-study"
    self.isCouple = try c.decodeIfPresent(Bool.self, forKey: .isCouple) ?? false
    self.dayNumber = try c.decodeIfPresent(Int.self, forKey: .dayNumber) ?? 1
    self.totalDays = try c.decodeIfPresent(Int.self, forKey: .totalDays)
    self.doneCount = try c.decodeIfPresent(Int.self, forKey: .doneCount) ?? 0
    self.memberCount = try c.decodeIfPresent(Int.self, forKey: .memberCount) ?? 0
    self.meCheckedInToday = try c.decodeIfPresent(Bool.self, forKey: .meCheckedInToday) ?? false
    self.midnightRolloverUtc = try c.decodeIfPresent(String.self, forKey: .midnightRolloverUtc)
    self.members = try c.decodeIfPresent([WidgetSquadMember].self, forKey: .members) ?? []
  }

  public func evaluated(
    at referenceDate: Date,
    timezone: String? = nil,
    utcOffsetMinutes: Int = 420
  ) -> WidgetSquadItem {
    guard let midnightDate = WidgetDateParser.parseISO8601(midnightRolloverUtc),
          referenceDate >= midnightDate
    else {
      return self
    }
    let cal = WidgetDateParser.calendar(
      timezoneId: timezone,
      utcOffsetMinutes: utcOffsetMinutes
    )
    let extraDays = WidgetDateParser.extraDaysPassed(
      from: midnightDate,
      to: referenceDate,
      calendar: cal
    )

    var rolled = self
    rolled.dayNumber = self.dayNumber + extraDays
    rolled.doneCount = 0
    rolled.meCheckedInToday = false
    rolled.midnightRolloverUtc = WidgetDateParser.formatISO8601(
      WidgetDateParser.addDays(extraDays, to: midnightDate, calendar: cal)
    )
    rolled.members = self.members.map { member in
      var m = member
      let survived = (extraDays == 1) && member.checkedInToday
      m.streak = survived ? member.streak : 0
      m.checkedInToday = false
      m.todayThumbFile = nil
      m.todayThumbBlurred = false
      return m
    }
    return rolled
  }
}

public struct WidgetSquadMember: Codable, Equatable {
  public var displayName: String
  public var initial: String
  public var avatarColorIndex: Int
  public var isMe: Bool
  public var checkedInToday: Bool
  public var streak: Int
  public var avatarFile: String?
  public var todayThumbFile: String?
  public var todayThumbBlurred: Bool

  public init(
    displayName: String,
    initial: String,
    avatarColorIndex: Int = 0,
    isMe: Bool = false,
    checkedInToday: Bool = false,
    streak: Int = 0,
    avatarFile: String? = nil,
    todayThumbFile: String? = nil,
    todayThumbBlurred: Bool = false
  ) {
    self.displayName = displayName
    self.initial = initial
    self.avatarColorIndex = avatarColorIndex
    self.isMe = isMe
    self.checkedInToday = checkedInToday
    self.streak = streak
    self.avatarFile = avatarFile
    self.todayThumbFile = todayThumbFile
    self.todayThumbBlurred = todayThumbBlurred
  }

  enum CodingKeys: String, CodingKey {
    case displayName
    case initial
    case avatarColorIndex
    case isMe
    case checkedInToday
    case streak
    case avatarFile
    case todayThumbFile
    case todayThumbBlurred
  }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    let name = try c.decodeIfPresent(String.self, forKey: .displayName) ?? ""
    self.displayName = name
    if let rawInitial = try c.decodeIfPresent(String.self, forKey: .initial), !rawInitial.isEmpty {
      self.initial = rawInitial
    } else if let first = name.trimmingCharacters(in: .whitespacesAndNewlines).first {
      self.initial = String(first).uppercased()
    } else {
      self.initial = "?"
    }
    self.avatarColorIndex = try c.decodeIfPresent(Int.self, forKey: .avatarColorIndex) ?? 0
    self.isMe = try c.decodeIfPresent(Bool.self, forKey: .isMe) ?? false
    self.checkedInToday = try c.decodeIfPresent(Bool.self, forKey: .checkedInToday) ?? false
    self.streak = try c.decodeIfPresent(Int.self, forKey: .streak) ?? 0
    self.avatarFile = try c.decodeIfPresent(String.self, forKey: .avatarFile)
    self.todayThumbFile = try c.decodeIfPresent(String.self, forKey: .todayThumbFile)
    self.todayThumbBlurred = try c.decodeIfPresent(Bool.self, forKey: .todayThumbBlurred) ?? false
  }
}

public struct WidgetLiveWindow: Codable, Equatable {
  public var windowKey: String
  public var journeyId: String
  public var journeyTitle: String
  public var skinId: String
  public var colorVariant: Int
  public var typeIcon: String
  public var currentStreak: Int
  public var atRisk: Bool
  public var pendingCount: Int
  public var completedCount: Int
  public var totalActiveCount: Int
  public var windowStartUtc: String
  public var deadlineUtc: String

  public init(
    windowKey: String,
    journeyId: String,
    journeyTitle: String,
    skinId: String = "minimal",
    colorVariant: Int = 0,
    typeIcon: String = "type-custom",
    currentStreak: Int = 0,
    atRisk: Bool = false,
    pendingCount: Int = 1,
    completedCount: Int = 0,
    totalActiveCount: Int = 1,
    windowStartUtc: String,
    deadlineUtc: String
  ) {
    self.windowKey = windowKey
    self.journeyId = journeyId
    self.journeyTitle = journeyTitle
    self.skinId = skinId
    self.colorVariant = colorVariant
    self.typeIcon = typeIcon
    self.currentStreak = currentStreak
    self.atRisk = atRisk
    self.pendingCount = pendingCount
    self.completedCount = completedCount
    self.totalActiveCount = totalActiveCount
    self.windowStartUtc = windowStartUtc
    self.deadlineUtc = deadlineUtc
  }

  enum CodingKeys: String, CodingKey {
    case windowKey
    case journeyId
    case journeyTitle
    case skinId
    case colorVariant
    case typeIcon
    case currentStreak
    case atRisk
    case pendingCount
    case completedCount
    case totalActiveCount
    case windowStartUtc
    case deadlineUtc
  }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    self.windowKey = try c.decodeIfPresent(String.self, forKey: .windowKey) ?? ""
    self.journeyId = try c.decodeIfPresent(String.self, forKey: .journeyId) ?? ""
    self.journeyTitle = try c.decodeIfPresent(String.self, forKey: .journeyTitle) ?? ""
    self.skinId = try c.decodeIfPresent(String.self, forKey: .skinId) ?? "minimal"
    self.colorVariant = try c.decodeIfPresent(Int.self, forKey: .colorVariant) ?? 0
    self.typeIcon = try c.decodeIfPresent(String.self, forKey: .typeIcon) ?? "type-custom"
    self.currentStreak = try c.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
    self.atRisk = try c.decodeIfPresent(Bool.self, forKey: .atRisk) ?? false
    self.pendingCount = try c.decodeIfPresent(Int.self, forKey: .pendingCount) ?? 1
    self.completedCount = try c.decodeIfPresent(Int.self, forKey: .completedCount) ?? 0
    self.totalActiveCount = try c.decodeIfPresent(Int.self, forKey: .totalActiveCount) ?? 1
    self.windowStartUtc = try c.decodeIfPresent(String.self, forKey: .windowStartUtc) ?? ""
    self.deadlineUtc = try c.decodeIfPresent(String.self, forKey: .deadlineUtc) ?? ""
  }
}

/// Interactive state persisted in `state.json` by `AppIntent`s (`CycleTodayJourneyIntent`,
/// `EndCheckInWindowIntent`) so interactive widgets never mutate `snapshot_v1.json`.
public struct WidgetInteractiveState: Codable, Equatable {
  public var selectedTodayIndex: Int
  public var selectedTodayJourneyId: String?
  public var dismissedWindowKey: String?
  public var dismissedWindowDate: String?
  public var updatedAtUtc: String?

  public init(
    selectedTodayIndex: Int = 0,
    selectedTodayJourneyId: String? = nil,
    dismissedWindowKey: String? = nil,
    dismissedWindowDate: String? = nil,
    updatedAtUtc: String? = nil
  ) {
    self.selectedTodayIndex = selectedTodayIndex
    self.selectedTodayJourneyId = selectedTodayJourneyId
    self.dismissedWindowKey = dismissedWindowKey
    self.dismissedWindowDate = dismissedWindowDate
    self.updatedAtUtc = updatedAtUtc
  }

  enum CodingKeys: String, CodingKey {
    case selectedTodayIndex
    case selectedTodayJourneyId
    case dismissedWindowKey
    case dismissedWindowDate
    case updatedAtUtc
  }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    self.selectedTodayIndex = try c.decodeIfPresent(Int.self, forKey: .selectedTodayIndex) ?? 0
    self.selectedTodayJourneyId = try c.decodeIfPresent(String.self, forKey: .selectedTodayJourneyId)
    self.dismissedWindowKey = try c.decodeIfPresent(String.self, forKey: .dismissedWindowKey)
    self.dismissedWindowDate = try c.decodeIfPresent(String.self, forKey: .dismissedWindowDate)
    self.updatedAtUtc = try c.decodeIfPresent(String.self, forKey: .updatedAtUtc)
  }
}

/// Thread-safe ISO-8601 & date helpers for widget rollover evaluation.
public enum WidgetDateParser {
  public static func parseISO8601(_ raw: String?) -> Date? {
    guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
      return nil
    }
    let fractional = ISO8601DateFormatter()
    fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = fractional.date(from: raw) {
      return date
    }
    let standard = ISO8601DateFormatter()
    standard.formatOptions = [.withInternetDateTime]
    return standard.date(from: raw)
  }

  public static func formatISO8601(_ date: Date) -> String {
    let fractional = ISO8601DateFormatter()
    fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return fractional.string(from: date)
  }

  public static func parseDateOnly(_ raw: String) -> Date? {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: raw)
  }

  public static func formatDateOnly(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }

  public static func weekdayShortLabel(for date: Date, isToday: Bool, locale: String) -> String {
    let isEn = locale.lowercased().hasPrefix("en")
    if isToday {
      return isEn ? "TD" : "HN"
    }
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    let weekday = cal.component(.weekday, from: date) // 1 = Sun, 2 = Mon ... 7 = Sat
    if isEn {
      let labels = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
      return labels[(weekday - 1) % 7]
    } else {
      let labels = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]
      return labels[(weekday - 1) % 7]
    }
  }

  public static func calendar(timezoneId: String?, utcOffsetMinutes: Int = 420) -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    if let tzId = timezoneId?.trimmingCharacters(in: .whitespacesAndNewlines),
       !tzId.isEmpty,
       let tz = TimeZone(identifier: tzId) {
      cal.timeZone = tz
    } else if let tz = TimeZone(secondsFromGMT: utcOffsetMinutes * 60) {
      cal.timeZone = tz
    } else {
      cal.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    }
    return cal
  }

  /// DST-safe count of midnights crossed (`>= 1` when `referenceDate >= midnightDate`).
  public static func extraDaysPassed(
    from midnightDate: Date,
    to referenceDate: Date,
    calendar: Calendar
  ) -> Int {
    guard referenceDate >= midnightDate else { return 0 }
    if let dayDiff = calendar.dateComponents([.day], from: midnightDate, to: referenceDate).day {
      return max(0, dayDiff) + 1
    }
    return max(0, Int(floor(referenceDate.timeIntervalSince(midnightDate) / 86400.0))) + 1
  }

  /// DST-safe calendar day shift preserving local wall-clock time across DST transitions.
  public static func addDays(_ days: Int, to date: Date, calendar: Calendar) -> Date {
    calendar.date(byAdding: .day, value: days, to: date)
      ?? date.addingTimeInterval(TimeInterval(days) * 86400.0)
  }
}

/// Shared App Group container reader/writer used by both `OurneyWidgetsExtension` and `Runner`.
/// Degrades gracefully when the App Group container is unavailable (e.g., Free Apple ID sideload).
public enum WidgetSnapshotStore {
  /// Returns the shared App Group `ourney_widgets` directory, or `nil` when App Group
  /// entitlement is unavailable (Free Apple ID sideload — Binding Note O2).
  public static func sharedRootDirectory(fileManager: FileManager = .default) -> URL? {
    guard let container = fileManager.containerURL(
      forSecurityApplicationGroupIdentifier: OurneyWidgetConstants.appGroupId
    ) else {
      return nil
    }
    return container
      .appendingPathComponent("Library", isDirectory: true)
      .appendingPathComponent("Application Support", isDirectory: true)
      .appendingPathComponent(OurneyWidgetConstants.directoryName, isDirectory: true)
  }

  /// Fallback local directory inside the process sandbox when App Groups are unavailable.
  public static func localFallbackDirectory(fileManager: FileManager = .default) -> URL? {
    guard let appSupport = fileManager.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    ).first else {
      return nil
    }
    return appSupport.appendingPathComponent(OurneyWidgetConstants.directoryName, isDirectory: true)
  }

  public static func activeRootDirectory(fileManager: FileManager = .default) -> URL? {
    sharedRootDirectory(fileManager: fileManager) ?? localFallbackDirectory(fileManager: fileManager)
  }

  public static func loadSnapshot(
    at referenceDate: Date = Date(),
    rootDirectory: URL? = nil
  ) -> WidgetSnapshot? {
    guard let root = rootDirectory ?? activeRootDirectory() else {
      return nil
    }
    let fileURL = root.appendingPathComponent(OurneyWidgetConstants.snapshotFileName)
    guard let data = try? Data(contentsOf: fileURL) else {
      return nil
    }
    guard let raw = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
      return nil
    }
    return raw.evaluated(at: referenceDate)
  }

  public static func loadState(rootDirectory: URL? = nil) -> WidgetInteractiveState {
    guard let root = rootDirectory ?? activeRootDirectory() else {
      return WidgetInteractiveState()
    }
    let fileURL = root.appendingPathComponent(OurneyWidgetConstants.stateFileName)
    guard let data = try? Data(contentsOf: fileURL),
          let state = try? JSONDecoder().decode(WidgetInteractiveState.self, from: data)
    else {
      return WidgetInteractiveState()
    }
    return state
  }

  @discardableResult
  public static func saveState(
    _ state: WidgetInteractiveState,
    rootDirectory: URL? = nil
  ) -> Bool {
    guard let root = rootDirectory ?? activeRootDirectory() else {
      return false
    }
    do {
      try ensureDirectoryPrepared(root)
      let fileURL = root.appendingPathComponent(OurneyWidgetConstants.stateFileName)
      let data = try JSONEncoder().encode(state)
      try data.write(
        to: fileURL,
        options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
      )
      return true
    } catch {
      return false
    }
  }

  /// Advances `selectedTodayIndex` across pending journeys in `state.json`.
  @discardableResult
  public static func cycleSelectedTodayJourney(
    at referenceDate: Date = Date(),
    rootDirectory: URL? = nil
  ) -> WidgetInteractiveState {
    let snapshot = loadSnapshot(at: referenceDate, rootDirectory: rootDirectory)
    var state = loadState(rootDirectory: rootDirectory)
    let pending = snapshot?.journeys.filter { !$0.checkedInToday } ?? []
    guard pending.count >= 2 else {
      return state
    }

    let currentIdx: Int
    if let currentId = state.selectedTodayJourneyId,
       let idx = pending.firstIndex(where: { $0.id == currentId }) {
      currentIdx = idx
    } else {
      currentIdx = ((state.selectedTodayIndex % pending.count) + pending.count) % pending.count
    }

    let nextIdx = (currentIdx + 1) % pending.count
    state.selectedTodayIndex = nextIdx
    state.selectedTodayJourneyId = pending[nextIdx].id
    state.updatedAtUtc = WidgetDateParser.formatISO8601(referenceDate)
    _ = saveState(state, rootDirectory: rootDirectory)
    return state
  }

  /// Records that the user dismissed today's Check-In Window Live Activity.
  @discardableResult
  public static func recordDismissedWindow(
    windowKey: String?,
    at referenceDate: Date = Date(),
    rootDirectory: URL? = nil
  ) -> WidgetInteractiveState {
    var state = loadState(rootDirectory: rootDirectory)
    let resolvedKey = windowKey
      ?? loadSnapshot(at: referenceDate, rootDirectory: rootDirectory)?.liveWindow?.windowKey
    if let key = resolvedKey, !key.isEmpty {
      state.dismissedWindowKey = key
      if let datePrefix = key.split(separator: ":").first {
        state.dismissedWindowDate = String(datePrefix)
      }
    }
    state.updatedAtUtc = WidgetDateParser.formatISO8601(referenceDate)
    _ = saveState(state, rootDirectory: rootDirectory)
    return state
  }

  /// Returns a cache filename isolated between blurred and unblurred variants so a cached
  /// unblurred thumbnail can never collide with a blurred request (§7.1).
  public static func resolvedThumbFileName(_ rawFileName: String, blurred: Bool) -> String {
    guard blurred else { return rawFileName }
    let ns = rawFileName as NSString
    let ext = ns.pathExtension
    let base = ns.deletingPathExtension
    if base.hasSuffix("_blur") || base.hasPrefix("blur_") {
      return rawFileName
    }
    return ext.isEmpty ? "\(base)_blur" : "\(base)_blur.\(ext)"
  }

  /// Resolves the on-disk URL for a relative thumbnail reference (e.g. `"thumbs/a91f4c82.jpg"`).
  public static func thumbURL(
    for relativePath: String?,
    blurred: Bool = false,
    rootDirectory: URL? = nil
  ) -> URL? {
    guard let raw = relativePath?.trimmingCharacters(in: .whitespacesAndNewlines),
          !raw.isEmpty,
          let root = rootDirectory ?? activeRootDirectory()
    else {
      return nil
    }
    let fileName = (raw as NSString).lastPathComponent
    guard !fileName.isEmpty, fileName != ".", fileName != ".." else {
      return nil
    }
    let thumbsDir = root.appendingPathComponent(OurneyWidgetConstants.thumbsSubdirectory, isDirectory: true)
    if blurred {
      let blurredName = resolvedThumbFileName(fileName, blurred: true)
      let blurredURL = thumbsDir.appendingPathComponent(blurredName, isDirectory: false)
      if FileManager.default.fileExists(atPath: blurredURL.path) {
        return blurredURL
      }
    }
    let url = thumbsDir.appendingPathComponent(fileName, isDirectory: false)
    return FileManager.default.fileExists(atPath: url.path) ? url : nil
  }

  public static func ensureDirectoryPrepared(_ dir: URL, fileManager: FileManager = .default) throws {
    if !fileManager.fileExists(atPath: dir.path) {
      try fileManager.createDirectory(
        at: dir,
        withIntermediateDirectories: true,
        attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
      )
    }
    var mutableURL = dir
    var resourceValues = URLResourceValues()
    resourceValues.isExcludedFromBackup = true
    try? mutableURL.setResourceValues(resourceValues)
  }
}

/// Sample preview fixtures for WidgetKit gallery & SwiftUI `#Preview` blocks.
public enum WidgetPreviewFixtures {
  public static let sampleTodaySnapshot = WidgetSnapshot(
    schemaVersion: 1,
    generatedAtUtc: "2026-11-24T11:55:00.000Z",
    authState: "ready",
    locale: "vi",
    themeMode: "system",
    privacy: WidgetPrivacySettings(
      photoMode: "smart",
      redactLockScreenTitles: false,
      liveActivityEnabled: true
    ),
    defaultJourneyId: "preview-ielts",
    totals: WidgetTotals(
      activeCount: 3,
      completedTodayCount: 1,
      pendingTodayCount: 2,
      atRiskCount: 1,
      bestActiveStreak: 21
    ),
    journeys: [
      WidgetJourneyItem(
        id: "preview-ielts",
        title: "Tự học IELTS 30 ngày",
        kind: "group",
        skinId: "squad",
        colorVariant: 0,
        typeIcon: "type-study",
        timezone: "Asia/Ho_Chi_Minh",
        utcOffsetMinutes: 420,
        pinned: true,
        dayNumber: 15,
        totalDays: 30,
        currentStreak: 14,
        bestStreak: 14,
        checkedInToday: false,
        atRisk: true,
        eveningCueAtUtc: "2026-11-24T11:00:00.000Z",
        streakAlertAtUtc: "2026-11-24T14:00:00.000Z",
        midnightRolloverUtc: "2026-11-24T17:00:00.000Z",
        weekStrip: [
          WidgetWeekDay(date: "2026-11-18", day: 18, label: "T4", state: "done"),
          WidgetWeekDay(date: "2026-11-19", day: 19, label: "T5", state: "done"),
          WidgetWeekDay(date: "2026-11-20", day: 20, label: "T6", state: "done"),
          WidgetWeekDay(date: "2026-11-21", day: 21, label: "T7", state: "done"),
          WidgetWeekDay(date: "2026-11-22", day: 22, label: "CN", state: "done"),
          WidgetWeekDay(date: "2026-11-23", day: 23, label: "T2", state: "done"),
          WidgetWeekDay(date: "2026-11-24", day: 24, label: "HN", state: "today"),
        ]
      ),
      WidgetJourneyItem(
        id: "preview-run",
        title: "Chạy bộ sáng 5km",
        kind: "solo",
        skinId: "flexer",
        colorVariant: 0,
        typeIcon: "type-workout",
        timezone: "Asia/Ho_Chi_Minh",
        utcOffsetMinutes: 420,
        pinned: false,
        dayNumber: 21,
        totalDays: 30,
        currentStreak: 21,
        bestStreak: 21,
        checkedInToday: true,
        atRisk: false,
        weekStrip: [
          WidgetWeekDay(date: "2026-11-18", day: 18, label: "T4", state: "done"),
          WidgetWeekDay(date: "2026-11-19", day: 19, label: "T5", state: "done"),
          WidgetWeekDay(date: "2026-11-20", day: 20, label: "T6", state: "done"),
          WidgetWeekDay(date: "2026-11-21", day: 21, label: "T7", state: "done"),
          WidgetWeekDay(date: "2026-11-22", day: 22, label: "CN", state: "done"),
          WidgetWeekDay(date: "2026-11-23", day: 23, label: "T2", state: "done"),
          WidgetWeekDay(date: "2026-11-24", day: 24, label: "HN", state: "done"),
        ]
      ),
      WidgetJourneyItem(
        id: "preview-quiet",
        title: "Ăn sạch 30 ngày",
        kind: "solo",
        skinId: "quiet",
        colorVariant: 0,
        typeIcon: "type-weight",
        timezone: "Asia/Ho_Chi_Minh",
        utcOffsetMinutes: 420,
        pinned: false,
        dayNumber: 9,
        totalDays: 30,
        currentStreak: 8,
        bestStreak: 12,
        checkedInToday: false,
        atRisk: false
      ),
    ],
    squads: [
      WidgetSquadItem(
        journeyId: "preview-ielts",
        title: "Tự học IELTS 30 ngày",
        skinId: "squad",
        colorVariant: 0,
        typeIcon: "type-study",
        isCouple: false,
        dayNumber: 15,
        totalDays: 30,
        doneCount: 3,
        memberCount: 5,
        meCheckedInToday: false,
        midnightRolloverUtc: "2026-11-24T17:00:00.000Z",
        members: [
          WidgetSquadMember(displayName: "Minh", initial: "M", avatarColorIndex: 3, isMe: false, checkedInToday: true, streak: 14),
          WidgetSquadMember(displayName: "Linh", initial: "L", avatarColorIndex: 0, isMe: false, checkedInToday: true, streak: 15),
          WidgetSquadMember(displayName: "Khánh", initial: "K", avatarColorIndex: 1, isMe: false, checkedInToday: true, streak: 9),
          WidgetSquadMember(displayName: "Bạn", initial: "B", avatarColorIndex: 4, isMe: true, checkedInToday: false, streak: 14),
          WidgetSquadMember(displayName: "An", initial: "A", avatarColorIndex: 2, isMe: false, checkedInToday: false, streak: 6),
        ]
      ),
    ]
  )
}
