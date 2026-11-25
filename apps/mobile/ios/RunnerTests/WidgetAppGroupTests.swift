import Foundation
import XCTest
@testable import Runner

final class WidgetAppGroupTests: XCTestCase {
  private let app = URL(fileURLWithPath: "/Test/Runner.app", isDirectory: true)
  private var widget: URL {
    app.appendingPathComponent("PlugIns/OurneyWidgetsExtension.appex", isDirectory: true)
  }
  private let original = "group.com.hofang42.ourney"
  private let derived = "group.com.example.ourney"
  private let container = URL(fileURLWithPath: "/Test/Shared", isDirectory: true)

  func testBothTargetsTryTheSameRewrittenGroupsBeforeBuiltInCandidates() {
    let shared = "group.rewritten.shared"
    let appOnly = "group.rewritten.app"
    let widgetOnly = "group.rewritten.widget"
    let metadata: [URL: [String: Any]] = [
      app: ["CFBundleIdentifier": "com.example.ourney", "ALTAppGroups": [appOnly, shared]],
      widget: ["ALTAppGroups": [widgetOnly, shared]],
    ]

    for (bundleURL, bundleID, localGroup) in [
      (app, "com.example.ourney", appOnly),
      (widget, "com.example.ourney.OurneyWidgets", widgetOnly),
    ] {
      var attempted: [String] = []
      let resolved = WidgetAppGroup.resolve(
        bundleURL: bundleURL,
        bundleIdentifier: bundleID,
        infoDictionary: { metadata[$0] },
        embeddedProfile: { _ in
          XCTFail("A resolved ALTAppGroups entry avoids reading profiles")
          return nil
        },
        containerURL: { id in
          attempted.append(id)
          return [shared, localGroup, self.original].contains(id) ? self.container : nil
        }
      )

      XCTAssertEqual(resolved, WidgetAppGroup(identifier: shared, containerURL: container))
      XCTAssertEqual(attempted, [shared])
    }
  }

  func testTriesRemainingRewritesThenOriginalThenContainingAppIdentifier() {
    let unavailable = "group.rewritten.unavailable"
    let widgetOnly = "group.rewritten.widget"
    let metadata: [URL: [String: Any]] = [
      app: ["ALTAppGroups": [unavailable, "", unavailable]],
      widget: ["ALTAppGroups": [widgetOnly]],
    ]

    for (supported, expected) in [
      (original, [unavailable, widgetOnly, original]),
      (derived, [unavailable, widgetOnly, original, derived]),
    ] {
      var attempted: [String] = []
      let resolved = WidgetAppGroup.resolve(
        bundleURL: widget,
        bundleIdentifier: "com.example.ourney.OurneyWidgets",
        infoDictionary: { metadata[$0] },
        embeddedProfile: { _ in
          XCTFail("A built-in candidate resolved")
          return nil
        },
        containerURL: { id in
          attempted.append(id)
          return id == supported ? self.container : nil
        }
      )

      XCTAssertEqual(resolved?.identifier, supported)
      XCTAssertEqual(attempted, expected)
    }
  }

  func testReadsEmbeddedPlistOnlyAfterBundleCandidatesFail() throws {
    let profileGroup = "group.profile.shared"
    let plist = try PropertyListSerialization.data(
      fromPropertyList: ["Entitlements": ["com.apple.security.application-groups": [
        original, profileGroup,
      ]]],
      format: .xml,
      options: 0
    )
    // A CMS payload can have non-UTF-8 bytes surrounding the XML plist.
    let wrappedProfile = Data([0x30, 0x82, 0xFF]) + plist + Data([0x00, 0xFE])
    var attempted: [String] = []
    let resolved = WidgetAppGroup.resolve(
      bundleURL: app,
      bundleIdentifier: "com.example.ourney",
      infoDictionary: { _ in nil },
      embeddedProfile: { $0 == self.app ? wrappedProfile : nil },
      containerURL: { id in
        attempted.append(id)
        return id == profileGroup ? self.container : nil
      }
    )

    XCTAssertEqual(resolved?.identifier, profileGroup)
    XCTAssertEqual(attempted, [original, derived, profileGroup])
  }

  func testReturnsNilForMissingContainerWithMalformedProfile() {
    var attempted: [String] = []
    let resolved = WidgetAppGroup.resolve(
      bundleURL: app,
      bundleIdentifier: "com.hofang42.ourney",
      infoDictionary: { _ in nil },
      embeddedProfile: { _ in Data("<plist invalid".utf8) },
      containerURL: { id in
        attempted.append(id)
        return nil
      }
    )

    XCTAssertNil(resolved)
    XCTAssertEqual(attempted, [original])
  }

  func testMissingContainerIsDistinctFromAnUnsyncedWidget() {
    XCTAssertEqual(
      WidgetSnapshot.resolveTodayCardState(snapshot: nil, appGroupAvailable: false),
      .appGroupUnavailable
    )
    XCTAssertEqual(
      WidgetSnapshot.resolveStreakCardState(snapshot: nil, appGroupAvailable: false),
      .appGroupUnavailable
    )
    XCTAssertEqual(
      WidgetSnapshot.resolveSquadCardState(snapshot: nil, appGroupAvailable: false),
      .appGroupUnavailable
    )
  }
}
