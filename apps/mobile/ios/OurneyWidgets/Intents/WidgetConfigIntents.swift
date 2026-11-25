import Foundation
import SwiftUI
import WidgetKit
#if canImport(AppIntents)
import AppIntents
#endif

#if canImport(AppIntents)

// MARK: - Dynamic Journey & Squad Entities Backed by App Group Snapshot (§B.2 & §B.4)

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct JourneyWidgetEntity: AppEntity, Equatable {
  public static var typeDisplayRepresentation: TypeDisplayRepresentation {
    TypeDisplayRepresentation(name: "Journey")
  }

  public static var defaultQuery = JourneyEntityQuery()

  public var id: String
  public var title: String
  public var subtitle: String?

  public init(id: String, title: String, subtitle: String? = nil) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
  }

  public init(option: WidgetEntityOption) {
    self.id = option.id
    self.title = option.title
    self.subtitle = option.subtitle
  }

  public static func auto(
    at referenceDate: Date = Date(),
    rootDirectory: URL? = nil,
    fallbackLocale: String? = nil
  ) -> JourneyWidgetEntity {
    JourneyWidgetEntity(
      option: WidgetSnapshotStore.defaultJourneyEntityOption(
        at: referenceDate,
        rootDirectory: rootDirectory,
        fallbackLocale: fallbackLocale
      )
    )
  }

  public var displayRepresentation: DisplayRepresentation {
    if let sub = subtitle, !sub.isEmpty {
      return DisplayRepresentation(
        title: LocalizedStringResource(stringLiteral: title),
        subtitle: LocalizedStringResource(stringLiteral: sub)
      )
    }
    return DisplayRepresentation(
      title: LocalizedStringResource(stringLiteral: title)
    )
  }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct JourneyEntityQuery: EntityQuery {
  public init() {}

  public func entities(for identifiers: [JourneyWidgetEntity.ID]) async throws -> [JourneyWidgetEntity] {
    WidgetSnapshotStore.journeyEntityOptions(for: identifiers).map(JourneyWidgetEntity.init(option:))
  }

  public func suggestedEntities() async throws -> [JourneyWidgetEntity] {
    WidgetSnapshotStore.suggestedJourneyEntityOptions().map(JourneyWidgetEntity.init(option:))
  }

  public func defaultResult() async -> JourneyWidgetEntity? {
    JourneyWidgetEntity.auto()
  }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct SquadWidgetEntity: AppEntity, Equatable {
  public static var typeDisplayRepresentation: TypeDisplayRepresentation {
    TypeDisplayRepresentation(name: "Squad")
  }

  public static var defaultQuery = SquadEntityQuery()

  public var id: String
  public var title: String
  public var subtitle: String?

  public init(id: String, title: String, subtitle: String? = nil) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
  }

  public init(option: WidgetEntityOption) {
    self.id = option.id
    self.title = option.title
    self.subtitle = option.subtitle
  }

  public static func auto(
    at referenceDate: Date = Date(),
    rootDirectory: URL? = nil,
    fallbackLocale: String? = nil
  ) -> SquadWidgetEntity {
    SquadWidgetEntity(
      option: WidgetSnapshotStore.defaultSquadEntityOption(
        at: referenceDate,
        rootDirectory: rootDirectory,
        fallbackLocale: fallbackLocale
      )
    )
  }

  public var displayRepresentation: DisplayRepresentation {
    if let sub = subtitle, !sub.isEmpty {
      return DisplayRepresentation(
        title: LocalizedStringResource(stringLiteral: title),
        subtitle: LocalizedStringResource(stringLiteral: sub)
      )
    }
    return DisplayRepresentation(
      title: LocalizedStringResource(stringLiteral: title)
    )
  }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct SquadEntityQuery: EntityQuery {
  public init() {}

  public func entities(for identifiers: [SquadWidgetEntity.ID]) async throws -> [SquadWidgetEntity] {
    WidgetSnapshotStore.squadEntityOptions(for: identifiers).map(SquadWidgetEntity.init(option:))
  }

  public func suggestedEntities() async throws -> [SquadWidgetEntity] {
    WidgetSnapshotStore.suggestedSquadEntityOptions().map(SquadWidgetEntity.init(option:))
  }

  public func defaultResult() async -> SquadWidgetEntity? {
    SquadWidgetEntity.auto()
  }
}

// MARK: - WidgetConfigurationIntent Definitions (§B.4)

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public protocol OurneyPinningConfigurationIntent: WidgetConfigurationIntent {
  var pinnedEntityId: String? { get }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct SelectTodayJourneyIntent: WidgetConfigurationIntent, OurneyPinningConfigurationIntent {
  public static var title: LocalizedStringResource = "Select Today Journey"
  public static var description = IntentDescription("Choose Automatic or pin a specific journey to this Today widget.")

  @Parameter(title: "Journey")
  public var journey: JourneyWidgetEntity?

  public init() {
    self.journey = .auto()
  }

  public init(journey: JourneyWidgetEntity?) {
    self.journey = journey
  }

  public var pinnedEntityId: String? {
    WidgetSnapshot.normalizedPinnedId(journey?.id)
  }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct SelectStreakJourneyIntent: WidgetConfigurationIntent, OurneyPinningConfigurationIntent {
  public static var title: LocalizedStringResource = "Select Streak Journey"
  public static var description = IntentDescription("Choose Automatic or pin a specific journey to this Streak widget.")

  @Parameter(title: "Journey")
  public var journey: JourneyWidgetEntity?

  public init() {
    self.journey = .auto()
  }

  public init(journey: JourneyWidgetEntity?) {
    self.journey = journey
  }

  public var pinnedEntityId: String? {
    WidgetSnapshot.normalizedPinnedId(journey?.id)
  }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct SelectSquadIntent: WidgetConfigurationIntent, OurneyPinningConfigurationIntent {
  public static var title: LocalizedStringResource = "Select Squad"
  public static var description = IntentDescription("Choose Automatic or pin a specific Squad or Couple journey to this widget.")

  @Parameter(title: "Squad")
  public var squad: SquadWidgetEntity?

  public init() {
    self.squad = .auto()
  }

  public init(squad: SquadWidgetEntity?) {
    self.squad = squad
  }

  public var pinnedEntityId: String? {
    WidgetSnapshot.normalizedPinnedId(squad?.id)
  }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct SelectLockScreenJourneyIntent: WidgetConfigurationIntent, OurneyPinningConfigurationIntent {
  public static var title: LocalizedStringResource = "Select Lock Screen Journey"
  public static var description = IntentDescription("Choose Automatic or pin a specific journey to this Lock Screen widget.")

  @Parameter(title: "Journey")
  public var journey: JourneyWidgetEntity?

  public init() {
    self.journey = .auto()
  }

  public init(journey: JourneyWidgetEntity?) {
    self.journey = journey
  }

  public var pinnedEntityId: String? {
    WidgetSnapshot.normalizedPinnedId(journey?.id)
  }
}

// MARK: - iOS 17+ AppIntentTimelineProvider & Configurable Widgets (§B.2)

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct OurneyAppIntentTimelineProvider<ConfigurationIntent: OurneyPinningConfigurationIntent>: AppIntentTimelineProvider {
  public typealias Entry = OurneyWidgetEntry
  public typealias Intent = ConfigurationIntent

  public init() {}

  public func placeholder(in context: Context) -> OurneyWidgetEntry {
    OurneyWidgetEntry(
      date: Date(),
      snapshot: WidgetPreviewFixtures.sampleTodaySnapshot,
      state: WidgetInteractiveState(),
      pinnedId: nil,
      isPreview: true
    )
  }

  public func snapshot(for configuration: ConfigurationIntent, in context: Context) async -> OurneyWidgetEntry {
    OurneyTimelineProvider.buildSnapshotEntry(
      isPreview: context.isPreview,
      pinnedId: configuration.pinnedEntityId
    )
  }

  public func timeline(for configuration: ConfigurationIntent, in context: Context) async -> Timeline<OurneyWidgetEntry> {
    OurneyTimelineProvider.buildTimeline(pinnedId: configuration.pinnedEntityId)
  }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct TodayConfigurableWidget: Widget {
  public let kind: String = OurneyWidgetKind.today

  public init() {}

  public var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: SelectTodayJourneyIntent.self,
      provider: OurneyAppIntentTimelineProvider<SelectTodayJourneyIntent>()
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
      provider: OurneyAppIntentTimelineProvider<SelectStreakJourneyIntent>()
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
      provider: OurneyAppIntentTimelineProvider<SelectSquadIntent>()
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
      provider: OurneyAppIntentTimelineProvider<SelectLockScreenJourneyIntent>()
    ) { entry in
      LockScreenWidgetEntryView(entry: entry)
    }
    .configurationDisplayName(WidgetL10n.tr("widget.lock.gallery.title"))
    .description(WidgetL10n.tr("widget.lock.gallery.desc"))
    .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
  }
}

#endif
