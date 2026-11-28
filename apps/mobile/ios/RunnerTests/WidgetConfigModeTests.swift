import Foundation
import XCTest
@testable import Runner

final class WidgetConfigModeTests: XCTestCase {
  private let app = URL(fileURLWithPath: "/Applications/Runner.app", isDirectory: true)

  func testOlderOSAlwaysUsesStaticMode() {
    let mode = WidgetConfigMode.resolve(isModernOS: false, bundleURL: app, override: "configurable") { _ in
      XCTFail("Older iOS versions should skip profile detection")
      return false
    }
    XCTAssertEqual(mode, .staticPicker)
  }

  func testExplicitOverrideSkipsProfileDetection() {
    let cases: [(String, WidgetConfigMode)] = [
      ("static", .staticPicker),
      ("configurable", .configurable),
      ("STATIC ", .staticPicker),
    ]
    for (override, expected) in cases {
      let mode = WidgetConfigMode.resolve(isModernOS: true, bundleURL: app, override: override) { _ in
        XCTFail("Explicit overrides should skip profile detection")
        return false
      }
      XCTAssertEqual(mode, expected, "Override: \(override)")
    }
  }

  func testAutomaticModeUsesOnlyTheAppProfileFromEitherBundle() {
    let widget = app.appendingPathComponent("PlugIns/OurneyWidgetsExtension.appex", isDirectory: true)
    let expectedProfile = app.appendingPathComponent("embedded.mobileprovision")
    let automaticOverrides: [String?] = [nil, "", "auto", "garbage"]

    for bundle in [app, widget] {
      for override in automaticOverrides {
        for hasProfile in [true, false] {
          var checkedProfiles: [URL] = []
          let mode = WidgetConfigMode.resolve(
            isModernOS: true, bundleURL: bundle, override: override
          ) { url in
            checkedProfiles.append(url)
            return url == expectedProfile && hasProfile
          }
          XCTAssertEqual(mode, hasProfile ? .staticPicker : .configurable)
          XCTAssertEqual(checkedProfiles, [expectedProfile])
        }
      }
    }
  }

  func testBridgeReportsResolvedMode() {
    let mode = WidgetConfigMode.current
    let capabilities = OurneyWidgetBridge().currentCapabilities()
    XCTAssertEqual(capabilities["configurableWidgets"] as? Bool, mode == .configurable)
    XCTAssertEqual(capabilities["widgetConfigMode"] as? String, mode.rawValue)
  }
}
