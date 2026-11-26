import Foundation
import WidgetKit

public struct OurneyWidgetEntry: TimelineEntry {
  public let date: Date
  public let snapshot: WidgetSnapshot?
  public let state: WidgetInteractiveState
  public let isPreview: Bool
  public let appGroupAvailable: Bool

  public init(
    date: Date,
    snapshot: WidgetSnapshot?,
    state: WidgetInteractiveState = WidgetInteractiveState(),
    isPreview: Bool = false,
    appGroupAvailable: Bool = true
  ) {
    self.date = date
    self.snapshot = snapshot
    self.state = state
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
    if isPreview {
      completion(Self.previewEntry())
      return
    }

    let now = Date()
    let root = rootDirectory()
    let snapshot = loadSnapshot(at: now, root: root, operation: "snapshot")
    let state = snapshot == nil ? WidgetInteractiveState() : WidgetSnapshotStore.loadState(rootDirectory: root)
    completion(OurneyWidgetEntry(date: now, snapshot: snapshot, state: state, appGroupAvailable: root != nil))
  }

  func getTimeline(completion: (Timeline<OurneyWidgetEntry>) -> Void) {
    let now = Date()
    let root = rootDirectory()
    guard let snapshot = loadSnapshot(at: now, root: root, operation: "timeline") else {
      let entry = OurneyWidgetEntry(date: now, snapshot: nil, appGroupAvailable: root != nil)
      completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(3600))))
      return
    }

    let state = WidgetSnapshotStore.loadState(rootDirectory: root)
    // Entries cover now, the evening cue, the streak alert, and midnight rollover.
    let dates = snapshot.scheduledTimelineDates(from: now)
    let entries = dates.map { date in
      OurneyWidgetEntry(date: date, snapshot: snapshot.evaluated(at: date), state: state)
    }
    let lastDate = dates.last ?? now
    let nextReload = lastDate > now
      ? lastDate.addingTimeInterval(60)
      : now.addingTimeInterval(3600)
    completion(Timeline(entries: entries, policy: .after(nextReload)))
  }

  private static func previewEntry() -> OurneyWidgetEntry {
    OurneyWidgetEntry(date: Date(), snapshot: WidgetPreviewFixtures.sampleTodaySnapshot, isPreview: true)
  }

  private func loadSnapshot(at date: Date, root: URL?, operation: String) -> WidgetSnapshot? {
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
