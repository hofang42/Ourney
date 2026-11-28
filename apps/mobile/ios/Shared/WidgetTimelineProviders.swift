import Foundation
import WidgetKit
#if canImport(AppIntents)
import AppIntents
#endif

public struct OurneyWidgetEntry: TimelineEntry {
  public let date: Date
  public let snapshot: WidgetSnapshot?
  public let state: WidgetInteractiveState
  public let pinnedId: String?
  public let isPreview: Bool
  public let appGroupAvailable: Bool

  public init(
    date: Date,
    snapshot: WidgetSnapshot?,
    state: WidgetInteractiveState = WidgetInteractiveState(),
    pinnedId: String? = nil,
    isPreview: Bool = false,
    appGroupAvailable: Bool = true
  ) {
    self.date = date
    self.snapshot = snapshot
    self.state = state
    self.pinnedId = WidgetSnapshot.normalizedPinnedId(pinnedId)
    self.isPreview = isPreview
    self.appGroupAvailable = appGroupAvailable
  }
}

public struct OurneyTimelineProvider: TimelineProvider {
  private let kind: String
  private let rootDirectory: () -> URL?

  public init(kind: String) {
    self.init(kind: kind, rootDirectory: { WidgetSnapshotStore.sharedRootDirectory() })
  }

  init(kind: String, rootDirectory: @escaping () -> URL?) {
    self.kind = kind
    self.rootDirectory = rootDirectory
  }

  public func placeholder(in context: Context) -> OurneyWidgetEntry {
    Self.previewEntry()
  }

  public func getSnapshot(in context: Context, completion: @escaping (OurneyWidgetEntry) -> Void) {
    getSnapshot(isPreview: context.isPreview, completion: completion)
  }

  public func getTimeline(in context: Context, completion: @escaping (Timeline<OurneyWidgetEntry>) -> Void) {
    getTimeline(completion: completion)
  }

  // WidgetKit owns Context construction. RunnerTests exercise the same callback bodies.
  func getSnapshot(isPreview: Bool, completion: (OurneyWidgetEntry) -> Void) {
    completion(
      Self.buildSnapshotEntry(
        kind: kind,
        isPreview: isPreview,
        pinnedId: nil,
        rootDirectory: rootDirectory
      )
    )
  }

  func getTimeline(completion: (Timeline<OurneyWidgetEntry>) -> Void) {
    completion(
      Self.buildTimeline(
        kind: kind,
        pinnedId: nil,
        rootDirectory: rootDirectory
      )
    )
  }

  static func previewEntry(at date: Date = Date()) -> OurneyWidgetEntry {
    OurneyWidgetEntry(date: date, snapshot: WidgetPreviewFixtures.sampleTodaySnapshot, isPreview: true)
  }

  static func buildSnapshotEntry(
    kind: String,
    isPreview: Bool,
    pinnedId: String?,
    rootDirectory: () -> URL?
  ) -> OurneyWidgetEntry {
    let now = Date()
    if isPreview {
      return previewEntry(at: now)
    }

    let root = rootDirectory()
    let snapshot = loadSnapshot(kind: kind, at: now, root: root, operation: "snapshot")
    let state = snapshot == nil ? WidgetInteractiveState() : WidgetSnapshotStore.loadState(rootDirectory: root)
    return OurneyWidgetEntry(
      date: now,
      snapshot: snapshot,
      state: state,
      pinnedId: pinnedId,
      appGroupAvailable: root != nil
    )
  }

  static func buildTimeline(
    kind: String,
    pinnedId: String?,
    rootDirectory: () -> URL?
  ) -> Timeline<OurneyWidgetEntry> {
    let now = Date()
    let root = rootDirectory()
    guard let snapshot = loadSnapshot(kind: kind, at: now, root: root, operation: "timeline") else {
      let entry = OurneyWidgetEntry(
        date: now,
        snapshot: nil,
        pinnedId: pinnedId,
        appGroupAvailable: root != nil
      )
      return Timeline(entries: [entry], policy: .after(now.addingTimeInterval(3600)))
    }

    let state = WidgetSnapshotStore.loadState(rootDirectory: root)
    // Entries cover now, the evening cue, the streak alert, and midnight rollover.
    let dates = snapshot.scheduledTimelineDates(from: now)
    let entries = dates.map { date in
      OurneyWidgetEntry(
        date: date,
        snapshot: snapshot.evaluated(at: date),
        state: state,
        pinnedId: pinnedId
      )
    }
    let lastDate = dates.last ?? now
    let nextReload = lastDate > now
      ? lastDate.addingTimeInterval(60)
      : now.addingTimeInterval(3600)
    return Timeline(entries: entries, policy: .after(nextReload))
  }

  private static func loadSnapshot(kind: String, at date: Date, root: URL?, operation: String) -> WidgetSnapshot? {
    guard let root else {
      WidgetDiagnostics.record("\(kind) \(operation) appGroupUnavailable", rootDirectory: nil)
      return nil
    }

    var result = "ready"
    let snapshot = WidgetSnapshotStore.loadSnapshot(at: date, rootDirectory: root) { result = $0 }
    WidgetDiagnostics.record("\(kind) \(operation) \(result)", rootDirectory: root)
    return snapshot
  }
}

#if canImport(AppIntents)

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct TodayAppIntentProvider: AppIntentTimelineProvider {
  public typealias Intent = SelectTodayJourneyIntent
  public typealias Entry = OurneyWidgetEntry
  private let rootDirectory: () -> URL?

  public init() {
    self.init(rootDirectory: { WidgetSnapshotStore.sharedRootDirectory() })
  }

  init(rootDirectory: @escaping () -> URL?) {
    self.rootDirectory = rootDirectory
  }

  public func placeholder(in context: Context) -> OurneyWidgetEntry {
    OurneyTimelineProvider.previewEntry()
  }

  public func snapshot(for configuration: SelectTodayJourneyIntent, in context: Context) async -> OurneyWidgetEntry {
    snapshot(for: configuration, isPreview: context.isPreview)
  }

  public func timeline(for configuration: SelectTodayJourneyIntent, in context: Context) async -> Timeline<OurneyWidgetEntry> {
    timeline(for: configuration)
  }

  func snapshot(for configuration: SelectTodayJourneyIntent, isPreview: Bool) -> OurneyWidgetEntry {
    OurneyTimelineProvider.buildSnapshotEntry(
      kind: OurneyWidgetKind.today,
      isPreview: isPreview,
      pinnedId: isPreview ? nil : configuration.pinnedJourneyId,
      rootDirectory: rootDirectory
    )
  }

  func timeline(for configuration: SelectTodayJourneyIntent) -> Timeline<OurneyWidgetEntry> {
    OurneyTimelineProvider.buildTimeline(
      kind: OurneyWidgetKind.today,
      pinnedId: configuration.pinnedJourneyId,
      rootDirectory: rootDirectory
    )
  }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct StreakAppIntentProvider: AppIntentTimelineProvider {
  public typealias Intent = SelectStreakJourneyIntent
  public typealias Entry = OurneyWidgetEntry
  private let rootDirectory: () -> URL?

  public init() {
    self.init(rootDirectory: { WidgetSnapshotStore.sharedRootDirectory() })
  }

  init(rootDirectory: @escaping () -> URL?) {
    self.rootDirectory = rootDirectory
  }

  public func placeholder(in context: Context) -> OurneyWidgetEntry {
    OurneyTimelineProvider.previewEntry()
  }

  public func snapshot(for configuration: SelectStreakJourneyIntent, in context: Context) async -> OurneyWidgetEntry {
    snapshot(for: configuration, isPreview: context.isPreview)
  }

  public func timeline(for configuration: SelectStreakJourneyIntent, in context: Context) async -> Timeline<OurneyWidgetEntry> {
    timeline(for: configuration)
  }

  func snapshot(for configuration: SelectStreakJourneyIntent, isPreview: Bool) -> OurneyWidgetEntry {
    OurneyTimelineProvider.buildSnapshotEntry(
      kind: OurneyWidgetKind.streak,
      isPreview: isPreview,
      pinnedId: isPreview ? nil : configuration.pinnedJourneyId,
      rootDirectory: rootDirectory
    )
  }

  func timeline(for configuration: SelectStreakJourneyIntent) -> Timeline<OurneyWidgetEntry> {
    OurneyTimelineProvider.buildTimeline(
      kind: OurneyWidgetKind.streak,
      pinnedId: configuration.pinnedJourneyId,
      rootDirectory: rootDirectory
    )
  }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct SquadAppIntentProvider: AppIntentTimelineProvider {
  public typealias Intent = SelectSquadIntent
  public typealias Entry = OurneyWidgetEntry
  private let rootDirectory: () -> URL?

  public init() {
    self.init(rootDirectory: { WidgetSnapshotStore.sharedRootDirectory() })
  }

  init(rootDirectory: @escaping () -> URL?) {
    self.rootDirectory = rootDirectory
  }

  public func placeholder(in context: Context) -> OurneyWidgetEntry {
    OurneyTimelineProvider.previewEntry()
  }

  public func snapshot(for configuration: SelectSquadIntent, in context: Context) async -> OurneyWidgetEntry {
    snapshot(for: configuration, isPreview: context.isPreview)
  }

  public func timeline(for configuration: SelectSquadIntent, in context: Context) async -> Timeline<OurneyWidgetEntry> {
    timeline(for: configuration)
  }

  func snapshot(for configuration: SelectSquadIntent, isPreview: Bool) -> OurneyWidgetEntry {
    OurneyTimelineProvider.buildSnapshotEntry(
      kind: OurneyWidgetKind.squad,
      isPreview: isPreview,
      pinnedId: isPreview ? nil : configuration.pinnedSquadId,
      rootDirectory: rootDirectory
    )
  }

  func timeline(for configuration: SelectSquadIntent) -> Timeline<OurneyWidgetEntry> {
    OurneyTimelineProvider.buildTimeline(
      kind: OurneyWidgetKind.squad,
      pinnedId: configuration.pinnedSquadId,
      rootDirectory: rootDirectory
    )
  }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct LockScreenAppIntentProvider: AppIntentTimelineProvider {
  public typealias Intent = SelectLockScreenJourneyIntent
  public typealias Entry = OurneyWidgetEntry
  private let rootDirectory: () -> URL?

  public init() {
    self.init(rootDirectory: { WidgetSnapshotStore.sharedRootDirectory() })
  }

  init(rootDirectory: @escaping () -> URL?) {
    self.rootDirectory = rootDirectory
  }

  public func placeholder(in context: Context) -> OurneyWidgetEntry {
    OurneyTimelineProvider.previewEntry()
  }

  public func snapshot(for configuration: SelectLockScreenJourneyIntent, in context: Context) async -> OurneyWidgetEntry {
    snapshot(for: configuration, isPreview: context.isPreview)
  }

  public func timeline(for configuration: SelectLockScreenJourneyIntent, in context: Context) async -> Timeline<OurneyWidgetEntry> {
    timeline(for: configuration)
  }

  func snapshot(for configuration: SelectLockScreenJourneyIntent, isPreview: Bool) -> OurneyWidgetEntry {
    OurneyTimelineProvider.buildSnapshotEntry(
      kind: OurneyWidgetKind.lockScreen,
      isPreview: isPreview,
      pinnedId: isPreview ? nil : configuration.pinnedJourneyId,
      rootDirectory: rootDirectory
    )
  }

  func timeline(for configuration: SelectLockScreenJourneyIntent) -> Timeline<OurneyWidgetEntry> {
    OurneyTimelineProvider.buildTimeline(
      kind: OurneyWidgetKind.lockScreen,
      pinnedId: configuration.pinnedJourneyId,
      rootDirectory: rootDirectory
    )
  }
}

#endif
