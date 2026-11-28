import Foundation
import WidgetKit
#if canImport(AppIntents)
import AppIntents
#endif

#if canImport(AppIntents)

// MARK: - Dynamic Journey & Squad Entities Backed by App Group Snapshot (§B.2 & §C.2)
// Compiled into BOTH Runner and OurneyWidgetsExtension so appintentsmetadataprocessor
// emits complete action/entity metadata in both bundles.

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct JourneyWidgetEntity: AppEntity, Equatable {
  public static var typeDisplayRepresentation: TypeDisplayRepresentation {
    TypeDisplayRepresentation(name: "Journey")
  }

  public static let defaultQuery = JourneyEntityQuery()

  public var id: String
  public var title: String
  public var subtitle: String?

  public init(id: String, title: String, subtitle: String? = nil) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
  }

  public init(option: WidgetEntityOption) {
    self.init(id: option.id, title: option.title, subtitle: option.subtitle)
  }

  public static func automatic(locale: String = "") -> JourneyWidgetEntity {
    JourneyWidgetEntity(option: WidgetSnapshotStore.defaultJourneyEntityOption(fallbackLocale: locale))
  }

  public var displayRepresentation: DisplayRepresentation {
    if let sub = subtitle, !sub.isEmpty {
      return DisplayRepresentation(
        title: "\(title)",
        subtitle: "\(sub)"
      )
    }
    return DisplayRepresentation(
      title: "\(title)"
    )
  }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct JourneyEntityQuery: EntityQuery {
  private let rootDirectory: @Sendable () -> URL?

  public init() {
    self.init(rootDirectory: { WidgetSnapshotStore.sharedRootDirectory() })
  }

  init(rootDirectory: @escaping @Sendable () -> URL?) {
    self.rootDirectory = rootDirectory
  }

  public func entities(for identifiers: [JourneyWidgetEntity.ID]) async throws -> [JourneyWidgetEntity] {
    // Never throws; resolves "auto", active IDs, and archived/unknown IDs even if App Group is nil.
    let root = rootDirectory()
    return WidgetSnapshotStore.journeyEntityOptions(
      for: identifiers,
      rootDirectory: root,
      allowLocalFallback: false
    ).map(JourneyWidgetEntity.init(option:))
  }

  public func suggestedEntities() async throws -> [JourneyWidgetEntity] {
    // Always returns [.automatic] first, followed by active journeys when snapshot_v1.json is readable.
    let root = rootDirectory()
    return WidgetSnapshotStore.suggestedJourneyEntityOptions(
      rootDirectory: root,
      allowLocalFallback: false
    ).map(JourneyWidgetEntity.init(option:))
  }

  public func defaultResult() async -> JourneyWidgetEntity? {
    // O(1) pure in-memory: ZERO disk / App Group I/O so default resolution never blocks or fails.
    .automatic(locale: Locale.preferredLanguages.first ?? "")
  }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct SquadWidgetEntity: AppEntity, Equatable {
  public static var typeDisplayRepresentation: TypeDisplayRepresentation {
    TypeDisplayRepresentation(name: "Squad")
  }

  public static let defaultQuery = SquadEntityQuery()

  public var id: String
  public var title: String
  public var subtitle: String?

  public init(id: String, title: String, subtitle: String? = nil) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
  }

  public init(option: WidgetEntityOption) {
    self.init(id: option.id, title: option.title, subtitle: option.subtitle)
  }

  public static func automatic(locale: String = "") -> SquadWidgetEntity {
    SquadWidgetEntity(option: WidgetSnapshotStore.defaultSquadEntityOption(fallbackLocale: locale))
  }

  public var displayRepresentation: DisplayRepresentation {
    if let sub = subtitle, !sub.isEmpty {
      return DisplayRepresentation(
        title: "\(title)",
        subtitle: "\(sub)"
      )
    }
    return DisplayRepresentation(
      title: "\(title)"
    )
  }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct SquadEntityQuery: EntityQuery {
  private let rootDirectory: @Sendable () -> URL?

  public init() {
    self.init(rootDirectory: { WidgetSnapshotStore.sharedRootDirectory() })
  }

  init(rootDirectory: @escaping @Sendable () -> URL?) {
    self.rootDirectory = rootDirectory
  }

  public func entities(for identifiers: [SquadWidgetEntity.ID]) async throws -> [SquadWidgetEntity] {
    // Never throws; resolves "auto", active IDs, and archived/unknown IDs even if App Group is nil.
    let root = rootDirectory()
    return WidgetSnapshotStore.squadEntityOptions(
      for: identifiers,
      rootDirectory: root,
      allowLocalFallback: false
    ).map(SquadWidgetEntity.init(option:))
  }

  public func suggestedEntities() async throws -> [SquadWidgetEntity] {
    // Always returns [.automatic] first, followed by active squads when snapshot_v1.json is readable.
    let root = rootDirectory()
    return WidgetSnapshotStore.suggestedSquadEntityOptions(
      rootDirectory: root,
      allowLocalFallback: false
    ).map(SquadWidgetEntity.init(option:))
  }

  public func defaultResult() async -> SquadWidgetEntity? {
    // O(1) pure in-memory: ZERO disk / App Group I/O so default resolution never blocks or fails.
    .automatic(locale: Locale.preferredLanguages.first ?? "")
  }
}

// MARK: - WidgetConfigurationIntent Definitions (§B.2 & §C.2)
// `public init() {}` MUST remain completely empty — AppIntents hydrates `@Parameter`
// wrappers via reflection AFTER `init()` returns.

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct SelectTodayJourneyIntent: WidgetConfigurationIntent {
  public static var title: LocalizedStringResource = "Select Today Journey"
  public static var description = IntentDescription("Choose Automatic or pin a specific journey to this Today widget.")

  @Parameter(title: "Journey")
  public var journey: JourneyWidgetEntity?

  public init() {}

  // Tests only. The AppIntents runtime uses the parameterless initializer.
  internal init(journey: JourneyWidgetEntity?) {
    self.journey = journey
  }

  public var pinnedJourneyId: String? {
    WidgetSnapshot.normalizedPinnedId(journey?.id)
  }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct SelectStreakJourneyIntent: WidgetConfigurationIntent {
  public static var title: LocalizedStringResource = "Select Streak Journey"
  public static var description = IntentDescription("Choose Automatic or pin a specific journey to this Streak widget.")

  @Parameter(title: "Journey")
  public var journey: JourneyWidgetEntity?

  public init() {}

  // Tests only. The AppIntents runtime uses the parameterless initializer.
  internal init(journey: JourneyWidgetEntity?) {
    self.journey = journey
  }

  public var pinnedJourneyId: String? {
    WidgetSnapshot.normalizedPinnedId(journey?.id)
  }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct SelectSquadIntent: WidgetConfigurationIntent {
  public static var title: LocalizedStringResource = "Select Squad"
  public static var description = IntentDescription("Choose Automatic or pin a specific Squad or Couple journey to this widget.")

  @Parameter(title: "Squad")
  public var squad: SquadWidgetEntity?

  public init() {}

  // Tests only. The AppIntents runtime uses the parameterless initializer.
  internal init(squad: SquadWidgetEntity?) {
    self.squad = squad
  }

  public var pinnedSquadId: String? {
    WidgetSnapshot.normalizedPinnedId(squad?.id)
  }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
public struct SelectLockScreenJourneyIntent: WidgetConfigurationIntent {
  public static var title: LocalizedStringResource = "Select Lock Screen Journey"
  public static var description = IntentDescription("Choose Automatic or pin a specific journey to this Lock Screen widget.")

  @Parameter(title: "Journey")
  public var journey: JourneyWidgetEntity?

  public init() {}

  // Tests only. The AppIntents runtime uses the parameterless initializer.
  internal init(journey: JourneyWidgetEntity?) {
    self.journey = journey
  }

  public var pinnedJourneyId: String? {
    WidgetSnapshot.normalizedPinnedId(journey?.id)
  }
}

#endif
