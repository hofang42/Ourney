import Flutter
import UIKit
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // flutter_local_notifications README, "General setup": show notifications via the plugin.
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
