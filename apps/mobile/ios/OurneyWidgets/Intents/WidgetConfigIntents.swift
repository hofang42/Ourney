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

  fileprivate static var automatic: JourneyWidgetEntity {
    JourneyWidgetEntity(
      id: WidgetSnapshot.autoEntityId,
      title: WidgetL10n.autoJourneyOptionTitle(locale: ""),
      subtitle: WidgetL10n.autoJourneyOptionSubtitle(locale: "")
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
    let operation = "query journey entities"
    return WidgetDiagnostics.trace(operation) {
      WidgetSnapshotStore.journeyEntityOptions(
        for: identifiers,
        onSnapshotError: { WidgetDiagnostics.record("\(operation) error \($0)") }
      ).map(JourneyWidgetEntity.init(option:))
    }
  }

  public func suggestedEntities() async throws -> [JourneyWidgetEntity] {
    let operation = "query journey suggested"
    return WidgetDiagnostics.trace(operation) {
      let options = WidgetSnapshotStore.suggestedJourneyEntityOptions(
        onSnapshotError: { WidgetDiagnostics.record("\(operation) error \($0)") }
      )
      if options.count == 1 {
        WidgetDiagnostics.record("\(operation) automaticOnly")
      }
      return options.map(JourneyWidgetEntity.init(option:))
    }
  }

  public func defaultResult() async -> JourneyWidgetEntity? {
    let operation = "query journey default"
    return WidgetDiagnostics.trace(operation) {
      JourneyWidgetEntity(option: WidgetSnapshotStore.defaultJourneyEntityOption(
        onSnapshotError: { WidgetDiagnostics.record("\(operation) error \($0)") }
      ))
    }
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

  fileprivate static var automatic: SquadWidgetEntity {
    SquadWidgetEntity(
      id: WidgetSnapshot.autoEntityId,
      title: WidgetL10n.autoSquadOptionTitle(locale: ""),
      subtitle: WidgetL10n.autoSquadOptionSubtitle(locale: "")
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
    let operation = "query squad entities"
    return WidgetDiagnostics.trace(operation) {
      WidgetSnapshotStore.squadEntityOptions(
        for: identifiers,
        onSnapshotError: { WidgetDiagnostics.record("\(operation) error \($0)") }
      ).map(SquadWidgetEntity.init(option:))
    }
  }

  public func suggestedEntities() async throws -> [SquadWidgetEntity] {
    let operation = "query squad suggested"
    return WidgetDiagnostics.trace(operation) {
      let options = WidgetSnapshotStore.suggestedSquadEntityOptions(
        onSnapshotError: { WidgetDiagnostics.record("\(operation) error \($0)") }
      )
      if options.count == 1 {
        WidgetDiagnostics.record("\(operation) automaticOnly")
      }
      return options.map(SquadWidgetEntity.init(option:))
    }
  }

  public func defaultResult() async -> SquadWidgetEntity? {
    let operation = "query squad default"
    return WidgetDiagnostics.trace(operation) {
      SquadWidgetEntity(option: WidgetSnapshotStore.defaultSquadEntityOption(
        onSnapshotError: { WidgetDiagnostics.record("\(operation) error \($0)") }
      ))
    }
  }
}

// MARK: - WidgetConfigurationIntent Definitions (§B.4)

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct SelectTodayJourneyIntent: WidgetConfigurationIntent, OurneyPinningConfigurationIntent {
  public static var title: LocalizedStringResource = "Select Today Journey"
  public static var description = IntentDescription("Choose Automatic or pin a specific journey to this Today widget.")

  @Parameter(title: "Journey")
  public var journey: JourneyWidgetEntity?

  public init() {
    self.journey = .automatic
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
    self.journey = .automatic
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
    self.squad = .automatic
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
    self.journey = .automatic
  }

  public init(journey: JourneyWidgetEntity?) {
    self.journey = journey
  }

  public var pinnedEntityId: String? {
    WidgetSnapshot.normalizedPinnedId(journey?.id)
  }
}

// MARK: - Configurable Widgets

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct TodayConfigurableWidget: Widget {
  public let kind: String = OurneyWidgetKind.today

  public init() {}

  public var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: SelectTodayJourneyIntent.self,
      provider: OurneyAppIntentTimelineProvider<SelectTodayJourneyIntent>(kind: kind)
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
      provider: OurneyAppIntentTimelineProvider<SelectStreakJourneyIntent>(kind: kind)
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
      provider: OurneyAppIntentTimelineProvider<SelectSquadIntent>(kind: kind)
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
      provider: OurneyAppIntentTimelineProvider<SelectLockScreenJourneyIntent>(kind: kind)
    ) { entry in
      LockScreenWidgetEntryView(entry: entry)
    }
    .configurationDisplayName(WidgetL10n.tr("widget.lock.gallery.title"))
    .description(WidgetL10n.tr("widget.lock.gallery.desc"))
    .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
  }
}

#endif
