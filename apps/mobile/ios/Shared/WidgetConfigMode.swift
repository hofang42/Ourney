import Foundation

/// Picks the widget configuration once per process, using inputs fixed at install time.
enum WidgetConfigMode: String {
  case configurable
  case staticPicker = "static"

  static let infoKey = "OurneyWidgetConfigMode"

  static let current: WidgetConfigMode = {
    let isModernOS: Bool
    if #available(iOS 17.0, iOSApplicationExtension 17.0, *) {
      isModernOS = true
    } else {
      isModernOS = false
    }
    return resolve(
      isModernOS: isModernOS,
      bundleURL: Bundle.main.bundleURL,
      override: Bundle.main.object(forInfoDictionaryKey: infoKey) as? String,
      fileExists: { FileManager.default.fileExists(atPath: $0.path) }
    )
  }()

  static func resolve(
    isModernOS: Bool,
    bundleURL: URL,
    override: String?,
    fileExists: (URL) -> Bool
  ) -> WidgetConfigMode {
    guard isModernOS else { return .staticPicker }
    switch override?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
    case "static": return .staticPicker
    case "configurable": return .configurable
    default: break
    }

    // Match WidgetAppGroup's parent-app resolution so both processes check the same profile.
    let parentApp = bundleURL.deletingLastPathComponent().deletingLastPathComponent()
    let app = bundleURL.pathExtension == "appex" && parentApp.pathExtension == "app" ? parentApp : bundleURL
    // App Store and TestFlight strip the embedded profile.
    return fileExists(app.appendingPathComponent("embedded.mobileprovision")) ? .staticPicker : .configurable
  }
}
