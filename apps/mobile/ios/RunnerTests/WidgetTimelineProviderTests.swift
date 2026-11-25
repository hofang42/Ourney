import AppIntents
import Foundation
import WidgetKit
import XCTest
@testable import Runner

final class WidgetTimelineProviderTests: XCTestCase {
  func testStaticPreviewCompletesWithFixtureWithinFiveSeconds() {
    let delivered = expectation(description: "static preview")
    DispatchQueue.global().async {
      OurneyTimelineProvider(kind: OurneyWidgetKind.todayBasic).getSnapshot(isPreview: true) { entry in
        XCTAssertTrue(entry.isPreview)
        XCTAssertNotNil(entry.snapshot)
        delivered.fulfill()
      }
    }
    wait(for: [delivered], timeout: 5)
  }

  func testStaticTimelineCompletesWithEntryWithinFiveSeconds() {
    let delivered = expectation(description: "static timeline")
    DispatchQueue.global().async {
      OurneyTimelineProvider(kind: OurneyWidgetKind.todayBasic).getTimeline { timeline in
        XCTAssertFalse(timeline.entries.isEmpty)
        delivered.fulfill()
      }
    }
    wait(for: [delivered], timeout: 5)
  }

  func testAppIntentPreviewReturnsFixtureWithinFiveSeconds() throws {
    guard #available(iOS 17.0, *) else { throw XCTSkip("AppIntent widgets require iOS 17.") }
    let delivered = expectation(description: "AppIntent preview")
    let task = Task.detached {
      let provider = OurneyAppIntentTimelineProvider<TestWidgetConfigurationIntent>(kind: OurneyWidgetKind.today)
      let entry = provider.snapshot(for: TestWidgetConfigurationIntent(), isPreview: true)
      XCTAssertTrue(entry.isPreview)
      XCTAssertNotNil(entry.snapshot)
      XCTAssertNil(entry.pinnedId)
      delivered.fulfill()
    }
    defer { task.cancel() }
    wait(for: [delivered], timeout: 5)
  }

  func testAppIntentTimelineReturnsPinnedEntryWithinFiveSeconds() throws {
    guard #available(iOS 17.0, *) else { throw XCTSkip("AppIntent widgets require iOS 17.") }
    let delivered = expectation(description: "AppIntent timeline")
    let task = Task.detached {
      let provider = OurneyAppIntentTimelineProvider<TestWidgetConfigurationIntent>(kind: OurneyWidgetKind.today)
      let intent = TestWidgetConfigurationIntent()
      let timeline = provider.timeline(for: intent)
      XCTAssertEqual(timeline.entries.first?.pinnedId, intent.pinnedEntityId)
      delivered.fulfill()
    }
    defer { task.cancel() }
    wait(for: [delivered], timeout: 5)
  }

  func testSynchronousDiagnosticIsReadableWhenWriteReturns() {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }

    WidgetDiagnostics.recordSynchronously("test snapshot enter", rootDirectory: { root })

    let recent = WidgetDiagnostics.recentLines(rootDirectory: root)
    XCTAssertEqual(recent.count, 1)
    XCTAssertTrue(recent.first?.hasSuffix("test snapshot enter") == true)
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

@available(iOS 17.0, *)
struct TestWidgetConfigurationIntent: WidgetConfigurationIntent, OurneyPinningConfigurationIntent {
  static var title: LocalizedStringResource = "Test Widget Configuration"
  var pinnedEntityId: String? { "test-pin" }
}
