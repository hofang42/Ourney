import SwiftUI
import WidgetKit
#if canImport(AppIntents)
import AppIntents

// MARK: - iOS 17+ Configurable Widgets (Edit Widget Per-Instance Journey Picker)

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct TodayConfigurableWidget: Widget {
  public let kind: String = OurneyWidgetKind.today

  public init() {}

  public var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: SelectTodayJourneyIntent.self,
      provider: TodayAppIntentProvider()
    ) { entry in
      TodayWidgetEntryView(entry: entry)
    }
    .configurationDisplayName(WidgetL10n.tr("widget.today.gallery.title"))
    .description(WidgetL10n.tr("widget.today.gallery.desc"))
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct StreakConfigurableWidget: Widget {
  public let kind: String = OurneyWidgetKind.streak

  public init() {}

  public var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: SelectStreakJourneyIntent.self,
      provider: StreakAppIntentProvider()
    ) { entry in
      StreakWidgetEntryView(entry: entry)
    }
    .configurationDisplayName(WidgetL10n.tr("widget.streak.gallery.title"))
    .description(WidgetL10n.tr("widget.streak.gallery.desc"))
    .supportedFamilies([.systemSmall])
  }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct SquadConfigurableWidget: Widget {
  public let kind: String = OurneyWidgetKind.squad

  public init() {}

  public var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: SelectSquadIntent.self,
      provider: SquadAppIntentProvider()
    ) { entry in
      SquadWidgetEntryView(entry: entry)
    }
    .configurationDisplayName(WidgetL10n.tr("widget.squad.gallery.title"))
    .description(WidgetL10n.tr("widget.squad.gallery.desc"))
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct LockScreenConfigurableWidget: Widget {
  public let kind: String = OurneyWidgetKind.lockScreen

  public init() {}

  public var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: SelectLockScreenJourneyIntent.self,
      provider: LockScreenAppIntentProvider()
    ) { entry in
      LockScreenWidgetEntryView(entry: entry)
    }
    .configurationDisplayName(WidgetL10n.tr("widget.lock.gallery.title"))
    .description(WidgetL10n.tr("widget.lock.gallery.desc"))
    .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
  }
}
#endif
