import AppIntents
import Intents
import SwiftUI
import WidgetKit

struct ConfigurationProbeEntry: TimelineEntry {
  let date: Date
  let name: String
  let option: String

  init(name: String, option: String) {
    date = Date()
    self.name = name
    self.option = option
  }
}

@available(iOS 17.0, *)
private struct ConfigurationProbeView: View {
  let entry: ConfigurationProbeEntry

  var body: some View {
    Text(verbatim: "\(entry.name) \(entry.option) \(entry.date.ISO8601Format())")
      .font(.footnote)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .containerBackground(for: .widget) {
        Color(uiColor: .systemBackground)
      }
  }
}

private func recordProbe(_ event: String) {
  // The shared file is an optional copy for the in-app diagnostics screen.
  // Choice resolution and rendering use only the hardcoded values.
  WidgetDiagnostics.record(event, rootDirectory: WidgetSnapshotStore.sharedRootDirectory())
}

@available(iOS 17.0, *)
enum ConfigurationProbeOption: String, AppEnum {
  case amber = "Amber"
  case blue = "Blue"
  case coral = "Coral"

  static let typeDisplayRepresentation: TypeDisplayRepresentation = "Probe Option"
  static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
    .amber: "Amber",
    .blue: "Blue",
    .coral: "Coral",
  ]
}

@available(iOS 17.0, *)
struct ConfigurationProbeEntity: AppEntity {
  static let typeDisplayRepresentation: TypeDisplayRepresentation = "Probe Option"
  static let defaultQuery = ConfigurationProbeQuery()

  let id: String

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(id)")
  }
}

@available(iOS 17.0, *)
struct ConfigurationProbeQuery: EntityQuery {
  private let options = ConfigurationProbeOption.allCases.map {
    ConfigurationProbeEntity(id: $0.rawValue)
  }

  func entities(for identifiers: [String]) async throws -> [ConfigurationProbeEntity] {
    recordProbe("probe app-entity query identifiers")
    return identifiers.compactMap { identifier in options.first { $0.id == identifier } }
  }

  func suggestedEntities() async throws -> [ConfigurationProbeEntity] {
    recordProbe("probe app-entity query suggestions")
    return options
  }

  func defaultResult() async -> ConfigurationProbeEntity? {
    recordProbe("probe app-entity query default")
    return options.first
  }
}

@available(iOS 17.0, *)
protocol ConfigurationProbeConfiguration {
  static var probeName: String { get }
  static var probeKind: String { get }
  static var probeLogName: String { get }
  var selectedLabel: String { get }
}

@available(iOS 17.0, *)
struct ConfigurationProbeEntityIntent: WidgetConfigurationIntent, ConfigurationProbeConfiguration {
  static let title: LocalizedStringResource = "Probe AppIntent"
  static let probeName = "Probe AppIntent"
  static let probeKind = "OurneyProbeAppIntentEntity"
  static let probeLogName = "app-entity"

  @Parameter(title: "Option")
  var option: ConfigurationProbeEntity?

  var selectedLabel: String { option?.id ?? ConfigurationProbeOption.amber.rawValue }
}

@available(iOS 17.0, *)
struct ConfigurationProbeEnumIntent: WidgetConfigurationIntent, ConfigurationProbeConfiguration {
  static let title: LocalizedStringResource = "Probe AppIntent Static Enum"
  static let probeName = "Probe AppIntent Static Enum"
  static let probeKind = "OurneyProbeAppIntentEnum"
  static let probeLogName = "app-enum"

  @Parameter(title: "Option", default: .amber)
  var option: ConfigurationProbeOption

  var selectedLabel: String { option.rawValue }
}

@available(iOS 17.0, *)
private struct ConfigurationProbeProvider<Intent: WidgetConfigurationIntent & ConfigurationProbeConfiguration>: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> ConfigurationProbeEntry {
    recordProbe("probe \(Intent.probeLogName) placeholder")
    return ConfigurationProbeEntry(name: Intent.probeName, option: "Placeholder")
  }

  func snapshot(for configuration: Intent, in context: Context) async -> ConfigurationProbeEntry {
    recordProbe("probe \(Intent.probeLogName) snapshot preview=\(context.isPreview) option=\(configuration.selectedLabel)")
    return ConfigurationProbeEntry(name: Intent.probeName, option: configuration.selectedLabel)
  }

  func timeline(for configuration: Intent, in context: Context) async -> Timeline<ConfigurationProbeEntry> {
    recordProbe("probe \(Intent.probeLogName) timeline option=\(configuration.selectedLabel)")
    let entry = ConfigurationProbeEntry(name: Intent.probeName, option: configuration.selectedLabel)
    return Timeline(entries: [entry], policy: .never)
  }
}

@available(iOS 17.0, *)
struct ConfigurationProbeAppWidget<Intent: WidgetConfigurationIntent & ConfigurationProbeConfiguration>: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: Intent.probeKind,
      intent: Intent.self,
      provider: ConfigurationProbeProvider<Intent>()
    ) { entry in
      ConfigurationProbeView(entry: entry)
    }
    .configurationDisplayName(Text(verbatim: Intent.probeName))
    .supportedFamilies([.systemSmall])
  }
}

private struct ConfigurationProbeSiriKitProvider: IntentTimelineProvider {
  private let name = "Probe SiriKit"

  func placeholder(in context: Context) -> ConfigurationProbeEntry {
    recordProbe("probe sirikit placeholder")
    return ConfigurationProbeEntry(name: name, option: "Placeholder")
  }

  func getSnapshot(
    for configuration: OurneyProbeSelectionIntent,
    in context: Context,
    completion: @escaping (ConfigurationProbeEntry) -> Void
  ) {
    let option = configuration.option?.displayString ?? "Amber"
    recordProbe("probe sirikit snapshot preview=\(context.isPreview) option=\(option)")
    completion(ConfigurationProbeEntry(name: name, option: option))
  }

  func getTimeline(
    for configuration: OurneyProbeSelectionIntent,
    in context: Context,
    completion: @escaping (Timeline<ConfigurationProbeEntry>) -> Void
  ) {
    let option = configuration.option?.displayString ?? "Amber"
    recordProbe("probe sirikit timeline option=\(option)")
    completion(Timeline(entries: [ConfigurationProbeEntry(name: name, option: option)], policy: .never))
  }
}

@available(iOS 17.0, *)
struct ConfigurationProbeSiriKitWidget: Widget {
  var body: some WidgetConfiguration {
    IntentConfiguration(
      kind: "OurneyProbeSiriKit",
      intent: OurneyProbeSelectionIntent.self,
      provider: ConfigurationProbeSiriKitProvider()
    ) { entry in
      ConfigurationProbeView(entry: entry)
    }
    .configurationDisplayName("Probe SiriKit")
    .supportedFamilies([.systemSmall])
  }
}
