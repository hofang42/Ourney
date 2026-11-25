import SwiftUI
import WidgetKit

@main
enum OurneyWidgetsLauncher {
  @MainActor static func main() {
    #if canImport(AppIntents)
    if #available(iOSApplicationExtension 17.0, iOS 17.0, *) {
      OurneyConfigurableWidgetsBundle.main()
      return
    }
    #endif
    OurneyLegacyWidgetsBundle.main()
  }
}

#if canImport(AppIntents)
@available(iOSApplicationExtension 17.0, iOS 17.0, *)
struct OurneyConfigurableWidgetsBundle: WidgetBundle {
  @WidgetBundleBuilder
  var body: some Widget {
    TodayConfigurableWidget()
    StreakConfigurableWidget()
    SquadConfigurableWidget()
    LockScreenConfigurableWidget()
    #if canImport(ActivityKit)
    CheckInLiveActivity()
    #endif
  }
}
#endif

struct OurneyLegacyWidgetsBundle: WidgetBundle {
  @WidgetBundleBuilder
  var body: some Widget {
    TodayWidget()
    StreakWidget()
    SquadWidget()
    LockScreenWidget()
    #if canImport(ActivityKit)
    if #available(iOSApplicationExtension 16.2, iOS 16.2, *) {
      CheckInLiveActivity()
    }
    #endif
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
