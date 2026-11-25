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

  public init(kind: String) {
    self.kind = kind
  }

  static func previewEntry(at date: Date = Date()) -> OurneyWidgetEntry {
    OurneyWidgetEntry(date: date, snapshot: WidgetPreviewFixtures.sampleTodaySnapshot, isPreview: true)
  }

  static func buildSnapshotEntry(isPreview: Bool, pinnedId: String?, operation: String) -> OurneyWidgetEntry {
    let now = Date()
    if isPreview { return previewEntry(at: now) }

    let sharedRoot = WidgetSnapshotStore.sharedRootDirectory()
    guard let sharedRoot,
          let loaded = WidgetSnapshotStore.loadSnapshot(at: now, rootDirectory: sharedRoot, onError: {
            WidgetDiagnostics.record("\(operation) error \($0)")
          }) else {
      return OurneyWidgetEntry(
        date: now,
        snapshot: nil,
        pinnedId: pinnedId,
        appGroupAvailable: sharedRoot != nil
      )
    }
    return OurneyWidgetEntry(
      date: now,
      snapshot: loaded,
      state: WidgetSnapshotStore.loadState(rootDirectory: sharedRoot),
      pinnedId: pinnedId
    )
  }

  static func buildTimeline(pinnedId: String?, operation: String) -> Timeline<OurneyWidgetEntry> {
    let now = Date()
    let sharedRoot = WidgetSnapshotStore.sharedRootDirectory()
    guard let sharedRoot,
          let baseSnapshot = WidgetSnapshotStore.loadSnapshot(at: now, rootDirectory: sharedRoot, onError: {
            WidgetDiagnostics.record("\(operation) error \($0)")
          }) else {
      let emptyEntry = OurneyWidgetEntry(
        date: now,
        snapshot: nil,
        pinnedId: pinnedId,
        appGroupAvailable: sharedRoot != nil
      )
      let nextReload = now.addingTimeInterval(3600)
      return Timeline(entries: [emptyEntry], policy: .after(nextReload))
    }
    let state = WidgetSnapshotStore.loadState(rootDirectory: sharedRoot)

    // Entries cover now, the evening cue, the streak alert, and midnight rollover.
    let dates = baseSnapshot.scheduledTimelineDates(from: now)
    let entries = dates.map { entryDate in
      OurneyWidgetEntry(
        date: entryDate,
        snapshot: baseSnapshot.evaluated(at: entryDate),
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

  public func placeholder(in context: Context) -> OurneyWidgetEntry {
    WidgetDiagnostics.trace("static \(kind) placeholder") { Self.previewEntry() }
  }

  public func getSnapshot(in context: Context, completion: @escaping (OurneyWidgetEntry) -> Void) {
    getSnapshot(isPreview: context.isPreview, completion: completion)
  }

  public func getTimeline(in context: Context, completion: @escaping (Timeline<OurneyWidgetEntry>) -> Void) {
    getTimeline(completion: completion)
  }

  // WidgetKit owns Context construction. Keep the callback bodies callable from RunnerTests.
  func getSnapshot(isPreview: Bool, completion: (OurneyWidgetEntry) -> Void) {
    let mode = isPreview ? "preview" : "live"
    let operation = "static \(kind) snapshot \(mode)"
    let entry = WidgetDiagnostics.traceSynchronously(operation) {
      Self.buildSnapshotEntry(isPreview: isPreview, pinnedId: nil, operation: operation)
    }
    completion(entry)
  }

  func getTimeline(completion: (Timeline<OurneyWidgetEntry>) -> Void) {
    let operation = "static \(kind) timeline"
    let timeline = WidgetDiagnostics.traceSynchronously(operation) {
      Self.buildTimeline(pinnedId: nil, operation: operation)
    }
    completion(timeline)
  }
}

#if canImport(AppIntents)
@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public protocol OurneyPinningConfigurationIntent: WidgetConfigurationIntent {
  var pinnedEntityId: String? { get }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct OurneyAppIntentTimelineProvider<ConfigurationIntent: OurneyPinningConfigurationIntent>: AppIntentTimelineProvider {
  public typealias Intent = ConfigurationIntent
  public typealias Entry = OurneyWidgetEntry
  private let kind: String

  public init(kind: String) {
    self.kind = kind
  }

  public func placeholder(in context: Context) -> OurneyWidgetEntry {
    WidgetDiagnostics.trace("appIntent \(kind) placeholder") { OurneyTimelineProvider.previewEntry() }
  }

  public func snapshot(for configuration: ConfigurationIntent, in context: Context) async -> OurneyWidgetEntry {
    snapshot(for: configuration, isPreview: context.isPreview)
  }

  public func timeline(for configuration: ConfigurationIntent, in context: Context) async -> Timeline<OurneyWidgetEntry> {
    timeline(for: configuration)
  }

  func snapshot(for configuration: ConfigurationIntent, isPreview: Bool) -> OurneyWidgetEntry {
    let mode = isPreview ? "preview" : "live"
    let operation = "appIntent \(kind) snapshot \(mode)"
    return WidgetDiagnostics.traceSynchronously(operation) {
      OurneyTimelineProvider.buildSnapshotEntry(
        isPreview: isPreview,
        pinnedId: isPreview ? nil : configuration.pinnedEntityId,
        operation: operation
      )
    }
  }

  func timeline(for configuration: ConfigurationIntent) -> Timeline<OurneyWidgetEntry> {
    let operation = "appIntent \(kind) timeline"
    return WidgetDiagnostics.traceSynchronously(operation) {
      OurneyTimelineProvider.buildTimeline(pinnedId: configuration.pinnedEntityId, operation: operation)
    }
  }
}
#endif
