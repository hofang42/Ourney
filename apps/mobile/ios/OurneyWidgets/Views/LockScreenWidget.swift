import SwiftUI
import WidgetKit

// MARK: - Lock Screen & StandBy Accessory Widgets (§3.1 #4)
// Zero photos, zero metrics. Honors `redactLockScreenTitles` and `.privacySensitive()`.

public struct LockScreenWidget: Widget {
  public let kind: String = OurneyWidgetKind.lockScreen

  public init() {}

  private var supportedAccessoryFamilies: [WidgetFamily] {
    if #available(iOSApplicationExtension 16.0, iOS 16.0, *) {
      return [.accessoryCircular, .accessoryRectangular, .accessoryInline]
    } else {
      return []
    }
  }

  public var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: OurneyTimelineProvider()) { entry in
      LockScreenWidgetEntryView(entry: entry)
    }
    .configurationDisplayName(WidgetL10n.tr("widget.lock.gallery.title"))
    .description(WidgetL10n.tr("widget.lock.gallery.desc"))
    .supportedFamilies(supportedAccessoryFamilies)
  }
}

public struct LockScreenWidgetEntryView: View {
  @Environment(\.widgetFamily) private var family
  public let entry: OurneyWidgetEntry

  public init(entry: OurneyWidgetEntry) {
    self.entry = entry
  }

  public var body: some View {
    let snapshot = entry.snapshot
    let locale = snapshot?.locale ?? ""
    let featured = snapshot?.selectedTodayJourney(state: entry.state)
    let bestStreak = max(snapshot?.totals.bestActiveStreak ?? 0, featured?.currentStreak ?? 0)
    let pendingCount = snapshot?.totals.pendingTodayCount ?? 0
    let activeCount = max(snapshot?.totals.activeCount ?? 1, 1)
    let completedCount = snapshot?.totals.completedTodayCount ?? 0
    let redactTitle = snapshot?.privacy.redactLockScreenTitles ?? false

    let destination: URL = {
      if let item = featured, !item.checkedInToday {
        return OurneyDeepLinks.capture(journeyId: item.id)
      }
      return OurneyDeepLinks.journeys
    }()

    Group {
      if #available(iOSApplicationExtension 16.0, iOS 16.0, *) {
        if family == .accessoryCircular {
          LockScreenCircularView(
            streak: bestStreak,
            completed: completedCount,
            total: activeCount
          )
        } else if family == .accessoryInline {
          LockScreenInlineView(
            streak: bestStreak,
            pending: pendingCount,
            locale: locale
          )
        } else {
          LockScreenRectangularView(
            journey: featured,
            streak: bestStreak,
            pendingCount: pendingCount,
            redactTitle: redactTitle,
            locale: locale
          )
        }
      } else {
        EmptyView()
      }
    }
    .ourneyWidgetContainerBackground {
      Color.clear
    }
    .widgetURL(destination)
  }
}

private struct LockScreenCircularView: View {
  let streak: Int
  let completed: Int
  let total: Int

  var body: some View {
    let progress = total > 0 ? min(max(Double(completed) / Double(total), 0.12), 1.0) : 0.12
    ZStack {
      Circle()
        .stroke(Color.primary.opacity(0.22), lineWidth: 5)

      Circle()
        .trim(from: 0, to: progress)
        .stroke(
          Color.primary,
          style: StrokeStyle(lineWidth: 5, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
        .ourneyWidgetAccentable()

      VStack(spacing: 0) {
        OurneyIconView(name: "flame", size: 14, flat: true, overrideColor: .primary)
          .ourneyWidgetAccentable()
        Text("\(streak)")
          .font(OurneyWidgetFont.display(15, weight: .bold))
          .minimumScaleFactor(0.7)
          .lineLimit(1)
      }
    }
    .padding(2)
  }
}

private struct LockScreenRectangularView: View {
  let journey: WidgetJourneyItem?
  let streak: Int
  let pendingCount: Int
  let redactTitle: Bool
  let locale: String

  var body: some View {
    let rawTitle = journey?.title.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let title = (redactTitle || rawTitle.isEmpty)
      ? WidgetL10n.lockScreenRedactedTitle(locale: locale)
      : rawTitle
    let days = journey?.weekStrip ?? []

    VStack(alignment: .leading, spacing: 3) {
      HStack(spacing: 4) {
        OurneyIconView(name: "flame", size: 13, flat: true, overrideColor: .primary)
          .ourneyWidgetAccentable()
        Text("\(streak)")
          .font(OurneyWidgetFont.display(14, weight: .bold))
          .ourneyWidgetAccentable()

        Text(title)
          .font(OurneyWidgetFont.body(11.5, bold: true))
          .lineLimit(1)
      }

      // 7-day mini chain bar
      HStack(spacing: 3) {
        let strip = days.isEmpty ? Array(repeating: false, count: 7) : days.suffix(7).map(\.isDone)
        ForEach(Array(strip.enumerated()), id: \.offset) { _, isDone in
          RoundedRectangle(cornerRadius: 2.5, style: .continuous)
            .fill(isDone ? Color.primary : Color.primary.opacity(0.22))
            .frame(height: 6)
        }
      }
      .ourneyWidgetAccentable()

      Text(WidgetL10n.lockScreenRemaining(pending: pendingCount, locale: locale))
        .font(OurneyWidgetFont.body(10, bold: false))
        .foregroundColor(.secondary)
        .lineLimit(1)
    }
  }
}

private struct LockScreenInlineView: View {
  let streak: Int
  let pending: Int
  let locale: String

  var body: some View {
    HStack(spacing: 4) {
      OurneyIconView(name: "flame", size: 12, flat: true, overrideColor: .primary)
      Text(WidgetL10n.lockScreenInline(streak: streak, pending: pending, locale: locale))
    }
  }
}
