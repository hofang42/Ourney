import Flutter
import Photos
import UIKit
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let widgetBridge = OurneyWidgetBridge()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    Self.excludeApplicationSupportFromBackup()
    // flutter_local_notifications README, "General setup": show notifications via the plugin.
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Excludes `Application Support` (SQLite database, private check-in drafts
  /// and cached media) from iCloud/iTunes backups (FS-11, mirrors Android
  /// `android:allowBackup="false"`).
  private static func excludeApplicationSupportFromBackup() {
    guard let url = FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    ).first else { return }
    try? FileManager.default.createDirectory(
      at: url,
      withIntermediateDirectories: true,
      attributes: nil
    )
    var resourceUrl = url
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try? resourceUrl.setResourceValues(values)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // UIScene lifecycle variant from the plugin README (needed for notification actions).
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let appIconChannel = FlutterMethodChannel(
      name: "ourney/app_icon",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    appIconChannel.setMethodCallHandler { [weak self] call, result in
      self?.handleAppIconCall(call, result: result)
    }

    let mediaSaverChannel = FlutterMethodChannel(
      name: "ourney/media_saver",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    mediaSaverChannel.setMethodCallHandler { [weak self] call, result in
      self?.handleMediaSaverCall(call, result: result)
    }

    widgetBridge.register(with: engineBridge.applicationRegistrar.messenger())
  }

  private func handleMediaSaverCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "saveImage" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard
      let args = call.arguments as? [String: Any],
      let path = args["path"] as? String,
      !path.isEmpty,
      FileManager.default.fileExists(atPath: path)
    else {
      result(
        FlutterError(
          code: "INVALID_FILE",
          message: "Source image file does not exist",
          details: nil
        )
      )
      return
    }

    let requestAuth: (@escaping (PHAuthorizationStatus) -> Void) -> Void = { completion in
      if #available(iOS 14, *) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly, handler: completion)
      } else {
        PHPhotoLibrary.requestAuthorization(completion)
      }
    }

    requestAuth { status in
      let authorized: Bool
      if #available(iOS 14, *) {
        authorized = (status == .authorized || status == .limited)
      } else {
        authorized = (status == .authorized)
      }
      guard authorized else {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "PERMISSION_DENIED",
              message: "Photo library add permission denied",
              details: nil
            )
          )
        }
        return
      }

      let fileUrl = URL(fileURLWithPath: path)
      var createdAssetId: String?
      PHPhotoLibrary.shared().performChanges({
        let request = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileUrl)
        createdAssetId = request?.placeholderForCreatedAsset?.localIdentifier
      }) { success, error in
        DispatchQueue.main.async {
          if success {
            result(createdAssetId ?? fileUrl.path)
          } else {
            result(
              FlutterError(
                code: "SAVE_FAILED",
                message: error?.localizedDescription ?? "Could not save image to Photos",
                details: nil
              )
            )
          }
        }
      }
    }
  }

  private static let alternateIconsById: [String: String?] = [
    "default": nil,
    "yellow": "AppIcon-Yellow",
    "green": "AppIcon-Green",
    "coral": "AppIcon-Coral",
    "violet": "AppIcon-Violet",
    "sky": "AppIcon-Sky",
    "dark": "AppIcon-Dark",
    "minimal": "AppIcon-Minimal",
  ]

  private static let validIosIconNames: Set<String> = [
    "AppIcon-Yellow",
    "AppIcon-Green",
    "AppIcon-Coral",
    "AppIcon-Violet",
    "AppIcon-Sky",
    "AppIcon-Dark",
    "AppIcon-Minimal",
  ]

  private func handleAppIconCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "supportsAlternateIcons":
      result(UIApplication.shared.supportsAlternateIcons)
    case "getAlternateIcon":
      result(UIApplication.shared.alternateIconName)
    case "setAlternateIcon":
      guard UIApplication.shared.supportsAlternateIcons else {
        result(false)
        return
      }
      let targetName: String?
      if let args = call.arguments as? [String: Any] {
        if let id = args["id"] as? String, Self.alternateIconsById.keys.contains(id) {
          targetName = Self.alternateIconsById[id] ?? nil
        } else if let iosName = args["iosIconName"] as? String {
          guard Self.validIosIconNames.contains(iosName) else {
            result(false)
            return
          }
          targetName = iosName
        } else {
          targetName = nil
        }
      } else if let arg = call.arguments as? String {
        if Self.alternateIconsById.keys.contains(arg) {
          targetName = Self.alternateIconsById[arg] ?? nil
        } else if Self.validIosIconNames.contains(arg) {
          targetName = arg
        } else {
          result(false)
          return
        }
      } else if call.arguments == nil {
        targetName = nil
      } else {
        result(false)
        return
      }

      if UIApplication.shared.alternateIconName == targetName {
        result(true)
        return
      }
      DispatchQueue.main.async {
        UIApplication.shared.setAlternateIconName(targetName) { error in
          if let error = error {
            result(
              FlutterError(
                code: "ICON_SWITCH_FAILED",
                message: error.localizedDescription,
                details: nil
              )
            )
          } else {
            result(true)
          }
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
