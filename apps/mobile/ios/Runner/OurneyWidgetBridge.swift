import Flutter
import Foundation
import ImageIO
import UIKit
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Native iOS implementation of `MethodChannel("ourney/widgets")` (§4.4).
/// - Writes `snapshot_v1.json` and content-addressed thumbnails into the shared App Group container
///   (`group.com.hofang42.ourney`) with `.completeFileProtectionUntilFirstUserAuthentication` protection and
///   `isExcludedFromBackup = true`.
/// - Degrades gracefully on Free Apple ID sideloads when the App Group container is unavailable
///   (Binding Note O2): never crashes, falls back to local sandbox storage, and still drives
///   `ActivityKit` Live Activities via direct IPC.
public final class OurneyWidgetBridge {
  public static let channelName = "ourney/widgets"

  private let ioQueue = DispatchQueue(
    label: "com.hofang42.ourney.widgets.io",
    qos: .userInitiated
  )
  private var didLogMissingAppGroup = false

  public init() {}

  public func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "syncSnapshot":
      handleSyncSnapshot(call.arguments, result: result)
    case "syncLiveActivity":
      handleSyncLiveActivity(call.arguments, result: result)
    case "clearAll":
      handleClearAll(result: result)
    case "consumeWidgetState":
      handleConsumeWidgetState(result: result)
    case "getCapabilities":
      result(currentCapabilities())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Capabilities

  public func currentCapabilities() -> [String: Any] {
    let appGroupAvailable = WidgetSnapshotStore.sharedRootDirectory() != nil
    var liveActivityAvailable = false
    #if canImport(ActivityKit)
    if #available(iOS 16.2, *) {
      liveActivityAvailable = ActivityAuthorizationInfo().areActivitiesEnabled
    }
    #endif
    return [
      "widgets": true,
      "liveActivity": liveActivityAvailable,
      "promotedLiveUpdates": false,
      "appGroup": appGroupAvailable,
    ]
  }

  // MARK: - syncSnapshot

  private func handleSyncSnapshot(_ rawArgs: Any?, result: @escaping FlutterResult) {
    guard let args = rawArgs as? [String: Any] else {
      result(false)
      return
    }

    let snapshotData: Data? = {
      if let jsonString = args["snapshotJson"] as? String {
        return jsonString.data(using: .utf8)
      }
      if let snapshotDict = args["snapshot"] as? [String: Any] {
        return try? JSONSerialization.data(withJSONObject: snapshotDict, options: [.sortedKeys])
      }
      return nil
    }()

    guard let validSnapshotData = snapshotData else {
      result(false)
      return
    }

    let thumbSpecs = (args["thumbs"] as? [[String: Any]]) ?? []

    ioQueue.async { [weak self] in
      guard let self = self else {
        DispatchQueue.main.async { result(false) }
        return
      }
      let didUpdate = self.writeSnapshotAndThumbs(
        snapshotData: validSnapshotData,
        thumbSpecs: thumbSpecs
      )
      DispatchQueue.main.async {
        if didUpdate {
          WidgetCenter.shared.reloadAllTimelines()
        }
        result(true)
      }
    }
  }

  /// Writes thumbnails and `snapshot_v1.json` atomically. Returns `true` if WidgetKit timelines
  /// should be reloaded.
  public func writeSnapshotAndThumbs(
    snapshotData: Data,
    thumbSpecs: [[String: Any]],
    overrideRootDirectory: URL? = nil
  ) -> Bool {
    let rootDir: URL
    if let overrideRoot = overrideRootDirectory {
      rootDir = overrideRoot
    } else if let sharedRoot = WidgetSnapshotStore.sharedRootDirectory() {
      rootDir = sharedRoot
    } else if let fallbackRoot = WidgetSnapshotStore.localFallbackDirectory() {
      if !didLogMissingAppGroup {
        didLogMissingAppGroup = true
        NSLog("[OurneyWidgetBridge] App Group container unavailable (free Apple ID sideload); using sandbox fallback.")
      }
      rootDir = fallbackRoot
    } else {
      return false
    }

    let fm = FileManager.default
    let thumbsDir = rootDir.appendingPathComponent(OurneyWidgetConstants.thumbsSubdirectory, isDirectory: true)

    do {
      try WidgetSnapshotStore.ensureDirectoryPrepared(rootDir, fileManager: fm)
      try WidgetSnapshotStore.ensureDirectoryPrepared(thumbsDir, fileManager: fm)
    } catch {
      return false
    }

    let decodedSnapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: snapshotData)
    var referencedThumbNames = Set<String>()
    if let snap = decodedSnapshot {
      for j in snap.journeys {
        if let f = Self.cleanThumbFileName(j.heroThumbFile) {
          referencedThumbNames.insert(f)
        }
      }
      for s in snap.squads {
        for m in s.members {
          if let a = Self.cleanThumbFileName(m.avatarFile) {
            referencedThumbNames.insert(a)
          }
          if let t = Self.cleanThumbFileName(m.todayThumbFile) {
            referencedThumbNames.insert(t)
          }
        }
      }
    }

    var thumbsChanged = false
    for spec in thumbSpecs {
      guard let rawId = spec["id"] as? String,
            let fileName = Self.cleanThumbFileName(rawId),
            let sourcePath = spec["sourcePath"] as? String,
            !sourcePath.isEmpty
      else {
        continue
      }
      referencedThumbNames.insert(fileName)
      let destURL = thumbsDir.appendingPathComponent(fileName, isDirectory: false)
      // Content-addressed cache hit (Dart pre-blurs once at sigma=18 and hashes (sourcePath, maxSide, blur) into id):
      // skip re-encoding if file already exists.
      if fm.fileExists(atPath: destURL.path) {
        continue
      }
      let maxSide = (spec["maxSide"] as? Int) ?? (spec["maxSide"] as? NSNumber)?.intValue ?? 320
      if processAndWriteThumbnail(
        sourcePath: sourcePath,
        destinationURL: destURL,
        maxSide: max(64, min(maxSide, 512))
      ) {
        thumbsChanged = true
      }
    }

    // Prune orphan thumbnail files no longer referenced by snapshot_v1.json.
    if let existingFiles = try? fm.contentsOfDirectory(at: thumbsDir, includingPropertiesForKeys: nil) {
      for fileURL in existingFiles {
        let name = fileURL.lastPathComponent
        if !referencedThumbNames.contains(name) {
          try? fm.removeItem(at: fileURL)
          thumbsChanged = true
        }
      }
    }

    let snapshotURL = rootDir.appendingPathComponent(OurneyWidgetConstants.snapshotFileName, isDirectory: false)
    let existingData = try? Data(contentsOf: snapshotURL)
    let snapshotChanged = (existingData != snapshotData)

    if snapshotChanged {
      do {
        try snapshotData.write(
          to: snapshotURL,
          options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
        )
        var mutableURL = snapshotURL
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? mutableURL.setResourceValues(values)
      } catch {
        return false
      }
    }

    // Safety net: if user signed out or disabled Live Activities, end any running activity.
    if let snap = decodedSnapshot,
       (snap.authState == "signedOut" || snap.authState == "unauthenticated" || !snap.privacy.liveActivityEnabled) {
      endAllLiveActivitiesImmediate()
    }

    return snapshotChanged || thumbsChanged
  }

  private static func cleanThumbFileName(_ raw: String?) -> String? {
    guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
      return nil
    }
    let name = (trimmed as NSString).lastPathComponent
    guard !name.isEmpty, name != ".", name != ".." else {
      return nil
    }
    return name
  }

  private func processAndWriteThumbnail(
    sourcePath: String,
    destinationURL: URL,
    maxSide: Int
  ) -> Bool {
    let sourceURL = URL(fileURLWithPath: sourcePath)
    guard FileManager.default.fileExists(atPath: sourceURL.path) else {
      return false
    }
    let sourceOpts: [CFString: Any] = [kCGImageSourceShouldCache: false]
    guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, sourceOpts as CFDictionary) else {
      return false
    }
    let thumbOpts: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceShouldCacheImmediately: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: maxSide,
    ]
    guard let cgThumb = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOpts as CFDictionary) else {
      return false
    }

    // Dart blurs sensitive thumbnails once (sigma = 18) before invoking syncSnapshot;
    // native code never re-blurs. Re-encoding via UIImage.jpegData strips all EXIF/GPS metadata automatically.
    let finalUIImage = UIImage(cgImage: cgThumb)
    guard let jpegData = finalUIImage.jpegData(compressionQuality: 0.72) else {
      return false
    }
    do {
      try jpegData.write(
        to: destinationURL,
        options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
      )
      var mutableURL = destinationURL
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      try? mutableURL.setResourceValues(values)
      return true
    } catch {
      return false
    }
  }

  // MARK: - syncLiveActivity (§4.4, §6.1, §6.2)

  private func handleSyncLiveActivity(_ rawArgs: Any?, result: @escaping FlutterResult) {
    #if canImport(ActivityKit)
    guard #available(iOS 16.2, *) else {
      result(false)
      return
    }
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      endAllLiveActivitiesImmediate()
      result(false)
      return
    }

    guard let topDict = rawArgs as? [String: Any], !topDict.isEmpty else {
      endAllLiveActivitiesImmediate()
      result(true)
      return
    }

    if (topDict["end"] as? Bool) == true || (topDict["active"] as? Bool) == false {
      endAllLiveActivitiesImmediate()
      result(true)
      return
    }

    let windowDict = (topDict["liveWindow"] as? [String: Any]) ?? topDict
    let celebrateAndDismiss = (topDict["celebrateAndDismiss"] as? Bool)
      ?? (windowDict["celebrateAndDismiss"] as? Bool)
      ?? (windowDict["isCompletedCelebration"] as? Bool)
      ?? false

    guard let journeyId = windowDict["journeyId"] as? String, !journeyId.isEmpty else {
      endAllLiveActivitiesImmediate()
      result(true)
      return
    }

    let windowKey = (windowDict["windowKey"] as? String) ?? "\(journeyId):today"
    let savedState = WidgetSnapshotStore.loadState()
    if !celebrateAndDismiss, savedState.dismissedWindowKey == windowKey {
      endAllLiveActivitiesImmediate()
      result(false)
      return
    }

    let now = Date()
    let windowStartDate = Self.parseDateArg(windowDict["windowStartUtc"]) ?? now
    let deadlineDate = Self.parseDateArg(windowDict["deadlineUtc"]) ?? now.addingTimeInterval(3600)

    if !celebrateAndDismiss && deadlineDate <= now {
      endAllLiveActivitiesImmediate()
      result(false)
      return
    }

    let cachedSnapshot = WidgetSnapshotStore.loadSnapshot(at: now)
    let locale = (topDict["locale"] as? String)
      ?? (windowDict["locale"] as? String)
      ?? cachedSnapshot?.locale
      ?? "vi"
    let redactTitle = Self.resolveRedactLockScreenTitles(
      topDict: topDict,
      windowDict: windowDict,
      cachedSnapshot: cachedSnapshot
    )

    let contentState = OurneyCheckInAttributes.ContentState(
      journeyId: journeyId,
      journeyTitle: (windowDict["journeyTitle"] as? String) ?? "",
      skinId: (windowDict["skinId"] as? String) ?? "minimal",
      colorVariant: (windowDict["colorVariant"] as? Int) ?? 0,
      typeIcon: (windowDict["typeIcon"] as? String) ?? "type-custom",
      currentStreak: (windowDict["currentStreak"] as? Int) ?? 0,
      atRisk: (windowDict["atRisk"] as? Bool) ?? false,
      pendingCount: (windowDict["pendingCount"] as? Int) ?? (celebrateAndDismiss ? 0 : 1),
      completedCount: (windowDict["completedCount"] as? Int) ?? 0,
      totalActiveCount: max((windowDict["totalActiveCount"] as? Int) ?? 1, 1),
      deadlineUtc: deadlineDate,
      windowStartUtc: windowStartDate,
      locale: locale,
      redactTitleOnLockScreen: redactTitle,
      isCompletedCelebration: celebrateAndDismiss
    )

    Task {
      let existingActivities = Activity<OurneyCheckInAttributes>.activities
      if celebrateAndDismiss {
        let dismissDate = Date().addingTimeInterval(120)
        let content = ActivityContent(state: contentState, staleDate: dismissDate)
        for activity in existingActivities {
          if activity.activityState == .ended || activity.activityState == .dismissed {
            await activity.end(nil, dismissalPolicy: .immediate)
          } else {
            await activity.end(content, dismissalPolicy: .after(dismissDate))
          }
        }
        DispatchQueue.main.async { result(true) }
        return
      }

      // Clean up any ended, dismissed, or mismatched-windowKey activities so we never call .update()
      // on a dead/lingering activity or keep a stale windowKey attached (§6.2).
      var matchingActive: [Activity<OurneyCheckInAttributes>] = []
      for activity in existingActivities {
        let isLiveState = (activity.activityState == .active || activity.activityState == .stale)
        if isLiveState && activity.attributes.windowKey == windowKey {
          matchingActive.append(activity)
        } else {
          await activity.end(nil, dismissalPolicy: .immediate)
        }
      }

      let content = ActivityContent(state: contentState, staleDate: deadlineDate)
      if let primary = matchingActive.first {
        await primary.update(content)
        for extra in matchingActive.dropFirst() {
          await extra.end(nil, dismissalPolicy: .immediate)
        }
        DispatchQueue.main.async { result(true) }
        return
      }

      // Activity.request can only succeed while the host app is in the foreground.
      let isForeground = await MainActor.run {
        UIApplication.shared.applicationState == .active
      }
      guard isForeground else {
        DispatchQueue.main.async { result(false) }
        return
      }

      do {
        _ = try Activity<OurneyCheckInAttributes>.request(
          attributes: OurneyCheckInAttributes(windowKey: windowKey),
          content: content,
          pushType: nil
        )
        DispatchQueue.main.async { result(true) }
      } catch {
        DispatchQueue.main.async { result(false) }
      }
    }
    #else
    result(false)
    #endif
  }

  /// Resolves Lock Screen title redaction flag across `syncLiveActivity` payloads,
  /// prioritizing canonical `redactLockScreenTitles` (top-level, `liveWindow`, and `privacy` dicts)
  /// before falling back to legacy `redactTitleOnLockScreen` and cached `snapshot_v1.json`.
  public static func resolveRedactLockScreenTitles(
    topDict: [String: Any],
    windowDict: [String: Any]? = nil,
    cachedSnapshot: WidgetSnapshot? = nil
  ) -> Bool {
    let resolvedWindowDict = windowDict ?? (topDict["liveWindow"] as? [String: Any]) ?? topDict
    let privacyDict = topDict["privacy"] as? [String: Any]
    return (topDict["redactLockScreenTitles"] as? Bool)
      ?? (resolvedWindowDict["redactLockScreenTitles"] as? Bool)
      ?? (privacyDict?["redactLockScreenTitles"] as? Bool)
      ?? (topDict["redactTitleOnLockScreen"] as? Bool)
      ?? (resolvedWindowDict["redactTitleOnLockScreen"] as? Bool)
      ?? cachedSnapshot?.privacy.redactLockScreenTitles
      ?? false
  }

  private static func parseDateArg(_ raw: Any?) -> Date? {
    if let iso = raw as? String {
      return WidgetDateParser.parseISO8601(iso)
    }
    if let ms = raw as? Double {
      return Date(timeIntervalSince1970: ms / 1000.0)
    }
    if let ms = raw as? Int {
      return Date(timeIntervalSince1970: Double(ms) / 1000.0)
    }
    return nil
  }

  private func endAllLiveActivitiesImmediate() {
    #if canImport(ActivityKit)
    if #available(iOS 16.2, *) {
      Task {
        for activity in Activity<OurneyCheckInAttributes>.activities {
          await activity.end(nil, dismissalPolicy: .immediate)
        }
      }
    }
    #endif
  }

  // MARK: - clearAll (§4.4, §7.1 Sign-out / Account Reset)

  private func handleClearAll(result: @escaping FlutterResult) {
    endAllLiveActivitiesImmediate()
    ioQueue.async { [weak self] in
      self?.clearAllFiles()
      DispatchQueue.main.async {
        WidgetCenter.shared.reloadAllTimelines()
        result(true)
      }
    }
  }

  public func clearAllFiles(overrideRootDirectory: URL? = nil) {
    let fm = FileManager.default
    let candidates: [URL] = {
      if let overrideRoot = overrideRootDirectory {
        return [overrideRoot]
      }
      return [
        WidgetSnapshotStore.sharedRootDirectory(fileManager: fm),
        WidgetSnapshotStore.localFallbackDirectory(fileManager: fm),
      ].compactMap { $0 }
    }()

    for dir in candidates where fm.fileExists(atPath: dir.path) {
      try? fm.removeItem(at: dir)
    }
  }

  // MARK: - consumeWidgetState (§4.4)

  private func handleConsumeWidgetState(result: @escaping FlutterResult) {
    ioQueue.async {
      guard let root = WidgetSnapshotStore.activeRootDirectory() else {
        DispatchQueue.main.async { result(nil) }
        return
      }
      let stateURL = root.appendingPathComponent(OurneyWidgetConstants.stateFileName, isDirectory: false)
      guard let data = try? Data(contentsOf: stateURL),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
      else {
        DispatchQueue.main.async { result(nil) }
        return
      }
      DispatchQueue.main.async { result(dict) }
    }
  }
}
