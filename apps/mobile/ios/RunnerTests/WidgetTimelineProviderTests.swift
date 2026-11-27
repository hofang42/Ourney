import Foundation
import WidgetKit
import XCTest
#if canImport(AppIntents)
import AppIntents
#endif
@testable import Runner

final class WidgetTimelineProviderTests: XCTestCase {
  func testStaticGallerySnapshotsReturnFixturesWithinFiveSeconds() {
    let delivered = expectation(description: "static gallery snapshots")
    let kinds = [
      OurneyWidgetKind.today, OurneyWidgetKind.streak, OurneyWidgetKind.squad, OurneyWidgetKind.lockScreen,
    ]
    delivered.expectedFulfillmentCount = kinds.count
    DispatchQueue.global().async {
      for kind in kinds {
        OurneyTimelineProvider(kind: kind, rootDirectory: { nil }).getSnapshot(isPreview: true) { entry in
          XCTAssertTrue(entry.isPreview)
          XCTAssertFalse(entry.snapshot?.journeys.isEmpty ?? true)
          XCTAssertFalse(entry.snapshot?.squads.isEmpty ?? true)
          delivered.fulfill()
        }
      }
    }
    wait(for: [delivered], timeout: 5)
  }

  func testStaticLiveSnapshotAndTimelineReadTheSharedStoreWithinFiveSeconds() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    try WidgetSnapshotStore.ensureDirectoryPrepared(root)

    let liveTitle = "Synced journey title"
    var saved = WidgetPreviewFixtures.sampleTodaySnapshot(locale: "vi")
    saved.journeys[0].title = liveTitle
    try JSONEncoder().encode(saved).write(to: root.appendingPathComponent(OurneyWidgetConstants.snapshotFileName))
    let selectedId = saved.journeys[2].id
    XCTAssertTrue(WidgetSnapshotStore.saveState(
      WidgetInteractiveState(selectedTodayJourneyId: selectedId),
      rootDirectory: root
    ))

    let snapshotDelivered = expectation(description: "live snapshot")
    let timelineDelivered = expectation(description: "live timeline")
    DispatchQueue.global().async {
      let provider = OurneyTimelineProvider(kind: OurneyWidgetKind.today, rootDirectory: { root })
      provider.getSnapshot(isPreview: false) { entry in
        XCTAssertFalse(entry.isPreview)
        XCTAssertEqual(entry.snapshot?.journeys.first?.title, liveTitle)
        XCTAssertEqual(entry.state.selectedTodayJourneyId, selectedId)
        XCTAssertTrue(entry.appGroupAvailable)
        snapshotDelivered.fulfill()
      }
      provider.getTimeline { timeline in
        XCTAssertEqual(timeline.entries.first?.snapshot?.journeys.first?.title, liveTitle)
        XCTAssertEqual(timeline.entries.first?.state.selectedTodayJourneyId, selectedId)
        timelineDelivered.fulfill()
      }
    }
    wait(for: [snapshotDelivered, timelineDelivered], timeout: 5)
  }

  func testStaticTimelineShipsFallbackWhenAppGroupIsUnavailable() {
    let delivered = expectation(description: "unavailable timeline")
    OurneyTimelineProvider(kind: OurneyWidgetKind.streak, rootDirectory: { nil }).getTimeline { timeline in
      XCTAssertEqual(timeline.entries.count, 1)
      XCTAssertEqual(timeline.entries.first?.appGroupAvailable, false)
      XCTAssertNil(timeline.entries.first?.snapshot)
      delivered.fulfill()
    }
    wait(for: [delivered], timeout: 5)
  }

  #if canImport(AppIntents)
  @available(iOS 17.0, *)
  func testProductionWidgetConfigurationIntentsHaveEmptyDefaultInitAndResolveToAutomatic() async throws {
    // Smoking Gun #2 regression test: instantiate the real production intents with @Parameter
    // via their parameterless `public init() {}` and verify `journey`/`squad` is nil (unbound)
    // and normalized pinned IDs default to nil ("Tự động").
    let todayIntent = SelectTodayJourneyIntent()
    XCTAssertNil(todayIntent.journey)
    XCTAssertNil(todayIntent.pinnedJourneyId)

    let streakIntent = SelectStreakJourneyIntent()
    XCTAssertNil(streakIntent.journey)
    XCTAssertNil(streakIntent.pinnedJourneyId)

    let squadIntent = SelectSquadIntent()
    XCTAssertNil(squadIntent.squad)
    XCTAssertNil(squadIntent.pinnedSquadId)

    let lockIntent = SelectLockScreenJourneyIntent()
    XCTAssertNil(lockIntent.journey)
    XCTAssertNil(lockIntent.pinnedJourneyId)

    // Explicit "auto" entity also normalizes to nil pinnedJourneyId/pinnedSquadId.
    let explicitAutoToday = SelectTodayJourneyIntent(journey: .automatic(locale: "vi"))
    XCTAssertEqual(explicitAutoToday.journey?.id, "auto")
    XCTAssertEqual(explicitAutoToday.journey?.title, "Tự động")
    XCTAssertNil(explicitAutoToday.pinnedJourneyId)

    let explicitAutoSquad = SelectSquadIntent(squad: .automatic(locale: "vi"))
    XCTAssertEqual(explicitAutoSquad.squad?.id, "auto")
    XCTAssertEqual(explicitAutoSquad.squad?.title, "Tự động")
    XCTAssertNil(explicitAutoSquad.pinnedSquadId)

    // EntityQuery defaultResult() is pure O(1) in-memory and never fails even when App Group is nil.
    let noDefaultDiskRead: @Sendable () -> URL? = {
      XCTFail("Default result should never resolve the App Group directory")
      return nil
    }
    let journeyDefault = await JourneyEntityQuery(rootDirectory: noDefaultDiskRead).defaultResult()
    XCTAssertEqual(journeyDefault?.id, "auto")
    let squadDefault = await SquadEntityQuery(rootDirectory: noDefaultDiskRead).defaultResult()
    XCTAssertEqual(squadDefault?.id, "auto")

    let journeyQueryNilRoot = JourneyEntityQuery(rootDirectory: { nil })
    let suggestedNoRoot = try await journeyQueryNilRoot.suggestedEntities()
    XCTAssertEqual(suggestedNoRoot.map(\.id), ["auto"])
    let resolvedNoRoot = try await journeyQueryNilRoot.entities(for: ["auto", "archived-id"])
    XCTAssertEqual(resolvedNoRoot.map(\.id), ["auto", "archived-id"])

    let squadQueryNilRoot = SquadEntityQuery(rootDirectory: { nil })
    let suggestedSquadNoRoot = try await squadQueryNilRoot.suggestedEntities()
    XCTAssertEqual(suggestedSquadNoRoot.map(\.id), ["auto"])
  }

  @available(iOS 17.0, *)
  func testConcreteAppIntentProvidersPinIndependentlyAndFallbackWhenAppGroupIsUnavailable() async throws {
    // 1. When App Group is nil, all 4 concrete AppIntentTimelineProviders return a 1-entry
    //    calm fallback timeline with appGroupAvailable == false and never block or return [].
    let start = ProcessInfo.processInfo.systemUptime
    let unavailToday = TodayAppIntentProvider(rootDirectory: { nil }).timeline(for: SelectTodayJourneyIntent())
    XCTAssertLessThan(ProcessInfo.processInfo.systemUptime - start, 1)
    XCTAssertEqual(unavailToday.entries.count, 1)
    XCTAssertFalse(unavailToday.entries.first?.appGroupAvailable ?? true)
    XCTAssertNil(unavailToday.entries.first?.snapshot)

    let unavailStreak = StreakAppIntentProvider(rootDirectory: { nil }).timeline(for: SelectStreakJourneyIntent())
    XCTAssertEqual(unavailStreak.entries.count, 1)
    XCTAssertFalse(unavailStreak.entries.first?.appGroupAvailable ?? true)

    let unavailSquad = SquadAppIntentProvider(rootDirectory: { nil }).timeline(for: SelectSquadIntent())
    XCTAssertEqual(unavailSquad.entries.count, 1)
    XCTAssertFalse(unavailSquad.entries.first?.appGroupAvailable ?? true)

    let unavailLock = LockScreenAppIntentProvider(rootDirectory: { nil }).timeline(for: SelectLockScreenJourneyIntent())
    XCTAssertEqual(unavailLock.entries.count, 1)
    XCTAssertFalse(unavailLock.entries.first?.appGroupAvailable ?? true)

    // 2. When App Group has a valid snapshot with multiple journeys & squads, EntityQuery lists
    //    only journeys/squads (never individual people) and two widget instances can pin
    //    different journeys or stay on Automatic independently.
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    try WidgetSnapshotStore.ensureDirectoryPrepared(root)

    let todayProvider = TodayAppIntentProvider(rootDirectory: { root })
    let emptyEntry = try XCTUnwrap(todayProvider.timeline(for: SelectTodayJourneyIntent()).entries.first)
    XCTAssertFalse(emptyEntry.isPreview)
    XCTAssertTrue(emptyEntry.appGroupAvailable)
    XCTAssertEqual(WidgetSnapshot.resolveTodayCardState(snapshot: emptyEntry.snapshot), .unsynced)

    let saved = WidgetPreviewFixtures.sampleTodaySnapshot(locale: "vi")
    try JSONEncoder().encode(saved).write(to: root.appendingPathComponent(OurneyWidgetConstants.snapshotFileName))

    let journeyQuery = JourneyEntityQuery(rootDirectory: { root })
    let suggestedJourneys = try await journeyQuery.suggestedEntities()
    XCTAssertEqual(
      suggestedJourneys.map(\.id),
      ["auto", "preview-ielts", "preview-run", "preview-quiet"]
    )
    XCTAssertEqual(suggestedJourneys.first?.title, "Tự động")

    let squadQuery = SquadEntityQuery(rootDirectory: { root })
    let suggestedSquads = try await squadQuery.suggestedEntities()
    XCTAssertEqual(suggestedSquads.map(\.id), ["auto", "preview-ielts"])
    XCTAssertEqual(suggestedSquads.first?.title, "Tự động")

    let pinnedRunEntity = JourneyWidgetEntity(id: "preview-run", title: "Chạy bộ sáng 5km")
    let pinnedEntry = try XCTUnwrap(todayProvider.timeline(
      for: SelectTodayJourneyIntent(journey: pinnedRunEntity)
    ).entries.first)
    let autoEntry = try XCTUnwrap(todayProvider.timeline(for: SelectTodayJourneyIntent()).entries.first)

    XCTAssertEqual(pinnedEntry.pinnedId, "preview-run")
    XCTAssertNil(autoEntry.pinnedId)

    let pinnedState = WidgetSnapshot.resolveTodayCardState(
      snapshot: pinnedEntry.snapshot,
      pinnedId: pinnedEntry.pinnedId,
      state: pinnedEntry.state
    )
    let autoState = WidgetSnapshot.resolveTodayCardState(
      snapshot: autoEntry.snapshot,
      pinnedId: autoEntry.pinnedId,
      state: autoEntry.state
    )
    XCTAssertEqual(pinnedState.tapURL, saved.journeys[1].captureURL)
    XCTAssertEqual(autoState.tapURL, saved.journeys[0].captureURL)
    XCTAssertTrue(pinnedEntry.snapshot?.isTodayJourneyPinned(pinnedEntry.pinnedId) == true)
    XCTAssertFalse(autoEntry.snapshot?.isTodayJourneyPinned(autoEntry.pinnedId) == true)
  }
  #endif

  func testSynchronousDiagnosticIsReadableWhenWriteReturns() {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }

    WidgetDiagnostics.record("test snapshot ready", rootDirectory: root)

    let recent = WidgetDiagnostics.recentLines(rootDirectory: root)
    XCTAssertEqual(recent.count, 1)
    XCTAssertTrue(recent.first?.hasSuffix("test snapshot ready") == true)
  }

  func testDiagnosticsBoundStorageAndReturnLatestTwentyLines() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }

    for index in 0..<60 {
      WidgetDiagnostics.append("test event \(index)", rootDirectory: root)
    }

    let files = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
    let ring = try String(contentsOf: XCTUnwrap(files.first), encoding: .utf8)
    XCTAssertEqual(ring.split(separator: "\n").count, 48)
    let recent = WidgetDiagnostics.recentLines(rootDirectory: root)
    XCTAssertEqual(recent.count, 20)
    XCTAssertTrue(recent.first?.hasSuffix("test event 40") == true)
    XCTAssertTrue(recent.last?.hasSuffix("test event 59") == true)
    XCTAssertNotNil(recent.last?.split(separator: " ").first.flatMap {
      ISO8601DateFormatter().date(from: String($0))
    })
    XCTAssertEqual(WidgetDiagnostics.recentLines(rootDirectory: nil), [])
  }
}
