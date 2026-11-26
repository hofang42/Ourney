import Foundation
import WidgetKit
import XCTest
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
