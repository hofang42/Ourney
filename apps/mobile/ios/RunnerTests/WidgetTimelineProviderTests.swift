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

  func testStaticJourneyWidgetsPinTheGlobalJourney() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    try WidgetSnapshotStore.ensureDirectoryPrepared(root)

    let automatic = WidgetJourneyItem(id: "automatic", title: "Automatic", currentStreak: 10)
    let selected = WidgetJourneyItem(id: "selected", title: "Selected")
    let saved = WidgetSnapshot(defaultJourneyId: selected.id, journeys: [automatic, selected])
    try JSONEncoder().encode(saved).write(to: root.appendingPathComponent(OurneyWidgetConstants.snapshotFileName))

    assertStaticEntries(kind: OurneyWidgetKind.today, root: root) { entry in
      XCTAssertEqual(entry.pinnedId, selected.id)
      XCTAssertTrue(entry.snapshot?.isTodayJourneyPinned(entry.pinnedId) == true)
      let card = WidgetSnapshot.resolveTodayCardState(snapshot: entry.snapshot, pinnedId: entry.pinnedId)
      XCTAssertEqual(card.tapURL, selected.captureURL)
    }
    assertStaticEntries(kind: OurneyWidgetKind.streak, root: root) { entry in
      XCTAssertEqual(entry.pinnedId, selected.id)
      let card = WidgetSnapshot.resolveStreakCardState(snapshot: entry.snapshot, pinnedId: entry.pinnedId)
      XCTAssertEqual(card.tapURL, selected.captureURL)
    }
    assertStaticEntries(kind: OurneyWidgetKind.lockScreen, root: root) { entry in
      XCTAssertEqual(entry.pinnedId, selected.id)
      XCTAssertEqual(entry.snapshot?.selectedLockScreenJourney(pinnedId: entry.pinnedId)?.id, selected.id)
    }
  }

  func testStaticSquadUsesTheSquadDefaultBeforeTheJourneyDefault() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    try WidgetSnapshotStore.ensureDirectoryPrepared(root)
    let snapshotFile = root.appendingPathComponent(OurneyWidgetConstants.snapshotFileName)

    let journeyDefault = WidgetSquadItem(journeyId: "journey-default", title: "Journey default")
    let squadDefault = WidgetSquadItem(journeyId: "squad-default", title: "Squad default")
    var saved = WidgetSnapshot(
      defaultJourneyId: journeyDefault.id,
      defaultSquadId: squadDefault.id,
      squads: [WidgetSquadItem(journeyId: "automatic", title: "Automatic"), journeyDefault, squadDefault]
    )
    try JSONEncoder().encode(saved).write(to: snapshotFile)
    assertStaticEntries(kind: OurneyWidgetKind.squad, root: root) { entry in
      XCTAssertEqual(entry.pinnedId, squadDefault.id)
      let card = WidgetSnapshot.resolveSquadCardState(snapshot: entry.snapshot, pinnedId: entry.pinnedId)
      XCTAssertEqual(card.tapURL, squadDefault.captureURL)
    }

    saved.defaultSquadId = nil
    try JSONEncoder().encode(saved).write(to: snapshotFile)
    assertStaticEntries(kind: OurneyWidgetKind.squad, root: root) { entry in
      XCTAssertEqual(entry.pinnedId, journeyDefault.id)
      let card = WidgetSnapshot.resolveSquadCardState(snapshot: entry.snapshot, pinnedId: entry.pinnedId)
      XCTAssertEqual(card.tapURL, journeyDefault.captureURL)
    }
  }

  func testStaticWidgetsFallBackToAutomaticWhenDefaultsHaveNoActiveMatch() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    try WidgetSnapshotStore.ensureDirectoryPrepared(root)

    // Only active journeys and squads appear in the snapshot, so archived defaults cannot match.
    let first = WidgetJourneyItem(id: "first", title: "First", currentStreak: 10)
    let cycled = WidgetJourneyItem(id: "cycled", title: "Cycled")
    let squad = WidgetSquadItem(journeyId: "active-squad", title: "Active squad")
    let saved = WidgetSnapshot(
      defaultJourneyId: "archived-journey",
      defaultSquadId: "unknown-squad",
      journeys: [first, cycled],
      squads: [squad]
    )
    try JSONEncoder().encode(saved).write(to: root.appendingPathComponent(OurneyWidgetConstants.snapshotFileName))
    XCTAssertTrue(WidgetSnapshotStore.saveState(
      WidgetInteractiveState(selectedTodayIndex: 1, selectedTodayJourneyId: cycled.id),
      rootDirectory: root
    ))

    assertStaticEntries(kind: OurneyWidgetKind.today, root: root) { entry in
      XCTAssertFalse(entry.snapshot?.isTodayJourneyPinned(entry.pinnedId) ?? true)
      let card = WidgetSnapshot.resolveTodayCardState(
        snapshot: entry.snapshot, pinnedId: entry.pinnedId, state: entry.state
      )
      XCTAssertEqual(card.tapURL, cycled.captureURL)
    }
    assertStaticEntries(kind: OurneyWidgetKind.streak, root: root) { entry in
      let card = WidgetSnapshot.resolveStreakCardState(snapshot: entry.snapshot, pinnedId: entry.pinnedId)
      XCTAssertEqual(card.tapURL, first.captureURL)
    }
    assertStaticEntries(kind: OurneyWidgetKind.squad, root: root) { entry in
      let card = WidgetSnapshot.resolveSquadCardState(snapshot: entry.snapshot, pinnedId: entry.pinnedId)
      XCTAssertEqual(card.tapURL, squad.captureURL)
    }
  }

  private func assertStaticEntries(kind: String, root: URL, verify: (OurneyWidgetEntry) -> Void) {
    let provider = OurneyTimelineProvider(kind: kind, rootDirectory: { root })
    provider.getSnapshot(isPreview: false, completion: verify)
    provider.getTimeline { timeline in
      XCTAssertFalse(timeline.entries.isEmpty)
      timeline.entries.forEach(verify)
    }
  }

  #if canImport(AppIntents)
  @available(iOS 17.0, *)
  func testAutomaticAppIntentProvidersIgnoreBothGlobalDefaults() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    try WidgetSnapshotStore.ensureDirectoryPrepared(root)
    var saved = WidgetPreviewFixtures.sampleTodaySnapshot(locale: "en")
    saved.defaultJourneyId = saved.journeys[1].id
    saved.defaultSquadId = saved.squads[0].id
    try JSONEncoder().encode(saved).write(to: root.appendingPathComponent(OurneyWidgetConstants.snapshotFileName))

    let today = TodayAppIntentProvider(rootDirectory: { root })
    let streak = StreakAppIntentProvider(rootDirectory: { root })
    let squad = SquadAppIntentProvider(rootDirectory: { root })
    let lockScreen = LockScreenAppIntentProvider(rootDirectory: { root })
    let automaticJourney = JourneyWidgetEntity.automatic(locale: "en")
    let todayIntent = SelectTodayJourneyIntent(journey: automaticJourney)
    let streakIntent = SelectStreakJourneyIntent(journey: automaticJourney)
    let squadIntent = SelectSquadIntent(squad: .automatic(locale: "en"))
    let lockScreenIntent = SelectLockScreenJourneyIntent(journey: automaticJourney)

    let snapshots = [
      today.snapshot(for: todayIntent, isPreview: false),
      streak.snapshot(for: streakIntent, isPreview: false),
      squad.snapshot(for: squadIntent, isPreview: false),
      lockScreen.snapshot(for: lockScreenIntent, isPreview: false),
    ]
    let timelines = [
      today.timeline(for: todayIntent),
      streak.timeline(for: streakIntent),
      squad.timeline(for: squadIntent),
      lockScreen.timeline(for: lockScreenIntent),
    ]
    for timeline in timelines {
      XCTAssertFalse(timeline.entries.isEmpty)
    }
    for entry in snapshots + timelines.flatMap(\.entries) {
      XCTAssertEqual(entry.snapshot?.defaultJourneyId, saved.defaultJourneyId)
      XCTAssertEqual(entry.snapshot?.defaultSquadId, saved.defaultSquadId)
      XCTAssertNil(entry.pinnedId)
    }
  }

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
  func testSignedOutEntityQueriesSuggestOnlyAutomatic() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    try WidgetSnapshotStore.ensureDirectoryPrepared(root)

    // Keep both lists populated to verify the signed-out guard hides any stale entries.
    var saved = WidgetPreviewFixtures.sampleTodaySnapshot(locale: "en")
    saved.authState = "signedOut"
    try JSONEncoder().encode(saved).write(to: root.appendingPathComponent(OurneyWidgetConstants.snapshotFileName))
    let snapshot = try XCTUnwrap(WidgetSnapshotStore.loadSnapshot(rootDirectory: root))
    XCTAssertTrue(snapshot.isSignedOut)
    XCTAssertFalse(snapshot.journeys.isEmpty)
    XCTAssertFalse(snapshot.squads.isEmpty)

    let delivered = expectation(description: "signed-out entity suggestions")
    let queryTask = Task {
      defer { delivered.fulfill() }
      do {
        let journeys = try await JourneyEntityQuery(rootDirectory: { root }).suggestedEntities()
        let squads = try await SquadEntityQuery(rootDirectory: { root }).suggestedEntities()
        XCTAssertEqual(journeys.map(\.id), ["auto"])
        XCTAssertEqual(squads.map(\.id), ["auto"])
      } catch {
        XCTFail("Signed-out entity queries failed: \(error)")
      }
    }
    defer { queryTask.cancel() }
    wait(for: [delivered], timeout: 5)
  }

  @available(iOS 17.0, *)
  func testPinnedLockScreenJourneyHonorsSmartModeAndTitleRedactionToggle() {
    let delivered = expectation(description: "pinned Lock Screen title redaction")
    DispatchQueue.global().async {
      defer { delivered.fulfill() }
      let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
      defer { try? FileManager.default.removeItem(at: root) }
      let sensitive = WidgetJourneyItem(id: "weight", title: "Weight loss", skinId: "weightLoss")
      let study = WidgetJourneyItem(id: "study", title: "Learn English", skinId: "squad")
      let cases = [
        (journey: sensitive, toggle: false, expectedRedaction: true),
        (journey: sensitive, toggle: true, expectedRedaction: true),
        (journey: study, toggle: false, expectedRedaction: false),
        (journey: study, toggle: true, expectedRedaction: true),
      ]

      do {
        try WidgetSnapshotStore.ensureDirectoryPrepared(root)
        let provider = LockScreenAppIntentProvider(rootDirectory: { root })
        let snapshotFile = root.appendingPathComponent(OurneyWidgetConstants.snapshotFileName)
        for testCase in cases {
          let saved = WidgetSnapshot(
            authState: "ready",
            privacy: WidgetPrivacySettings(photoMode: "smart", redactLockScreenTitles: testCase.toggle),
            journeys: [study, sensitive]
          )
          try JSONEncoder().encode(saved).write(to: snapshotFile)
          let pin = JourneyWidgetEntity(id: testCase.journey.id, title: testCase.journey.title)
          let timeline = provider.timeline(for: SelectLockScreenJourneyIntent(journey: pin))
          let entry = try XCTUnwrap(timeline.entries.first)
          XCTAssertEqual(entry.pinnedId, pin.id)
          let snapshot = try XCTUnwrap(entry.snapshot)
          let cardState = WidgetSnapshot.resolveTodayCardState(
            snapshot: snapshot,
            pinnedId: entry.pinnedId,
            state: entry.state,
            appGroupAvailable: entry.appGroupAvailable
          )
          guard case .ready(let featured) = cardState else {
            XCTFail("Expected a ready Lock Screen card for \(pin.id)")
            continue
          }
          XCTAssertEqual(featured.id, pin.id)
          XCTAssertEqual(snapshot.shouldRedactLockScreenTitle(for: featured), testCase.expectedRedaction)
        }
      } catch {
        XCTFail("Failed to build a pinned Lock Screen timeline: \(error)")
      }
    }
    wait(for: [delivered], timeout: 5)
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
