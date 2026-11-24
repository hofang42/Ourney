import Foundation
import WidgetKit
#if canImport(AppIntents)
import AppIntents
#endif
#if canImport(ActivityKit)
import ActivityKit
#endif

#if canImport(AppIntents)
/// Cycles between pending today journeys in-place on `OurneyTodayWidget` without opening the app (§3.1, §5.4).
@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct CycleTodayJourneyIntent: AppIntent {
  public static var title: LocalizedStringResource = "Cycle Next Journey"
  public static var description = IntentDescription("Switch the Today widget to the next pending journey.")
  public static var openAppWhenRun: Bool = false

  public init() {}

  public func perform() async throws -> some IntentResult {
    _ = WidgetSnapshotStore.cycleSelectedTodayJourney()
    WidgetCenter.shared.reloadTimelines(ofKind: OurneyWidgetKind.today)
    return .result()
  }
}

/// Ends today's Check-In Window Live Activity directly from the Lock Screen or Dynamic Island
/// and records `dismissedWindowKey` in `state.json` so it does not re-spawn tonight (§6.1, §6.2).
@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct EndCheckInWindowIntent: LiveActivityIntent {
  public static var title: LocalizedStringResource = "Dismiss Check-In Window"
  public static var description = IntentDescription("Dismiss today's check-in window countdown.")
  public static var openAppWhenRun: Bool = false

  public init() {}

  public func perform() async throws -> some IntentResult {
    #if canImport(ActivityKit)
    let activeKey = Activity<OurneyCheckInAttributes>.activities.first?.attributes.windowKey
    _ = WidgetSnapshotStore.recordDismissedWindow(windowKey: activeKey)
    for activity in Activity<OurneyCheckInAttributes>.activities {
      await activity.end(nil, dismissalPolicy: .immediate)
    }
    #else
    _ = WidgetSnapshotStore.recordDismissedWindow(windowKey: nil)
    #endif
    return .result()
  }
}

/// Optional widget configuration intent for selecting a specific journey (§3.1).
@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct SelectJourneyIntent: WidgetConfigurationIntent {
  public static var title: LocalizedStringResource = "Select Journey"
  public static var description = IntentDescription("Choose which journey to highlight.")

  @Parameter(title: "Journey ID")
  public var journeyId: String?

  public init() {}

  public init(journeyId: String?) {
    self.journeyId = journeyId
  }
}

/// Optional widget configuration intent for selecting a specific Squad or Couple journey (§3.1).
@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct SelectGroupIntent: WidgetConfigurationIntent {
  public static var title: LocalizedStringResource = "Select Squad"
  public static var description = IntentDescription("Choose which Squad or Couple journey to display.")

  @Parameter(title: "Squad Journey ID")
  public var groupId: String?

  public init() {}

  public init(groupId: String?) {
    self.groupId = groupId
  }
}
#endif
