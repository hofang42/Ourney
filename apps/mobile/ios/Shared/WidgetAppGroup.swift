import Foundation

/// Finds the shared container from the metadata shipped with the signed app.
struct WidgetAppGroup: Equatable {
  let identifier: String
  let containerURL: URL

  static let current = resolve(fileManager: .default)

  static func resolve(fileManager: FileManager) -> WidgetAppGroup? {
    resolve(
      bundleURL: Bundle.main.bundleURL,
      bundleIdentifier: Bundle.main.bundleIdentifier,
      infoDictionary: { Bundle(url: $0)?.infoDictionary },
      embeddedProfile: { url in
        try? Data(contentsOf: url.appendingPathComponent("embedded.mobileprovision"))
      },
      containerURL: { fileManager.containerURL(forSecurityApplicationGroupIdentifier: $0) }
    )
  }

  static func resolve(
    bundleURL: URL,
    bundleIdentifier: String?,
    infoDictionary: (URL) -> [String: Any]?,
    embeddedProfile: (URL) -> Data?,
    containerURL: (String) -> URL?
  ) -> WidgetAppGroup? {
    let parentApp = bundleURL.deletingLastPathComponent().deletingLastPathComponent()
    let isExtension = bundleURL.pathExtension == "appex"
    let app = isExtension && parentApp.pathExtension == "app" ? parentApp : bundleURL
    // Both processes read the same bundles in the same order, even if the signer rewrites
    // each bundle's Info.plist independently.
    let widget = app.appendingPathComponent("PlugIns/OurneyWidgetsExtension.appex", isDirectory: true)
    let appInfo = infoDictionary(app)
    let appGroups = appInfo?["ALTAppGroups"] as? [String] ?? []
    let widgetGroups = infoDictionary(widget)?["ALTAppGroups"] as? [String] ?? []
    let advertisedByBoth = appGroups.filter { widgetGroups.contains($0) }

    let suffix = ".OurneyWidgets"
    let fallbackID = bundleIdentifier.map { id in
      id.hasSuffix(suffix) ? String(id.dropLast(suffix.count)) : id
    }
    let appID = appInfo?["CFBundleIdentifier"] as? String ?? fallbackID
    var candidates = advertisedByBoth + appGroups + widgetGroups + ["group.com.hofang42.ourney"]
    if let appID, !appID.isEmpty {
      candidates.append("group.\(appID)")
    }

    var attempted = Set<String>()
    func firstAccessible(_ identifiers: [String]) -> WidgetAppGroup? {
      for identifier in identifiers where !identifier.isEmpty && attempted.insert(identifier).inserted {
        if let url = containerURL(identifier) {
          return WidgetAppGroup(identifier: identifier, containerURL: url)
        }
      }
      return nil
    }

    if let resolved = firstAccessible(candidates) {
      return resolved
    }
    let appProfileGroups = groups(in: embeddedProfile(app))
    let widgetProfileGroups = groups(in: embeddedProfile(widget))
    let provisionedForBoth = appProfileGroups.filter { widgetProfileGroups.contains($0) }
    return firstAccessible(provisionedForBoth + appProfileGroups + widgetProfileGroups)
  }

  /// Reads the legacy plist payload in the CMS wrapper when available. Container lookup
  /// confirms access regardless of which group identifiers this metadata advertises.
  private static func groups(in profile: Data?) -> [String] {
    guard let profile else { return [] }
    let plistData: Data
    if let start = profile.range(of: Data("<plist".utf8)),
       let end = profile.range(of: Data("</plist>".utf8), in: start.upperBound..<profile.endIndex) {
      plistData = profile.subdata(in: start.lowerBound..<end.upperBound)
    } else {
      plistData = profile
    }
    guard let plist = (try? PropertyListSerialization.propertyList(from: plistData, format: nil))
      as? [String: Any], let entitlements = plist["Entitlements"] as? [String: Any] else {
      return []
    }
    return entitlements["com.apple.security.application-groups"] as? [String] ?? []
  }
}
