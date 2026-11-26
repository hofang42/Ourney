import SwiftUI
import WidgetKit

@main
enum OurneyWidgetsLauncher {
  @MainActor static func main() {
    WidgetDiagnostics.recordProcessLaunch()
    OurneyWidgetsBundle.main()
  }
}

struct OurneyWidgetsBundle: WidgetBundle {
  @WidgetBundleBuilder
  var body: some Widget {
    TodayWidget()
    StreakWidget()
    SquadWidget()
    LockScreenWidget()
    if #available(iOSApplicationExtension 17.0, iOS 17.0, *) {
      configurationProbes
    }
    #if canImport(ActivityKit)
    if #available(iOSApplicationExtension 16.2, iOS 16.2, *) {
      CheckInLiveActivity()
    }
    #endif
  }

  @available(iOSApplicationExtension 17.0, iOS 17.0, *)
  @WidgetBundleBuilder
  private var configurationProbes: some Widget {
    ConfigurationProbeAppWidget<ConfigurationProbeEntityIntent>()
    ConfigurationProbeSiriKitWidget()
    ConfigurationProbeAppWidget<ConfigurationProbeEnumIntent>()
  }
}

#if DEBUG
struct OurneyWidgets_Previews: PreviewProvider {
  static var sampleEntry: OurneyWidgetEntry {
    OurneyWidgetEntry(
      date: Date(),
      snapshot: WidgetPreviewFixtures.sampleTodaySnapshot,
      state: WidgetInteractiveState(),
      isPreview: true
    )
  }

  static var previews: some View {
    Group {
      TodayWidgetEntryView(entry: sampleEntry)
        .previewContext(WidgetPreviewContext(family: .systemSmall))
        .previewDisplayName("Today Small (Light)")

      TodayWidgetEntryView(entry: sampleEntry)
        .previewContext(WidgetPreviewContext(family: .systemMedium))
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Today Medium (Dark)")

      TodayWidgetEntryView(entry: sampleEntry)
        .previewContext(WidgetPreviewContext(family: .systemLarge))
        .previewDisplayName("Today Large")

      StreakWidgetEntryView(entry: sampleEntry)
        .previewContext(WidgetPreviewContext(family: .systemSmall))
        .previewDisplayName("Streak Small")

      SquadWidgetEntryView(entry: sampleEntry)
        .previewContext(WidgetPreviewContext(family: .systemMedium))
        .previewDisplayName("Squad Medium")

      SquadWidgetEntryView(entry: sampleEntry)
        .previewContext(WidgetPreviewContext(family: .systemLarge))
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Squad Large (Dark)")
    }
  }
}
#endif
