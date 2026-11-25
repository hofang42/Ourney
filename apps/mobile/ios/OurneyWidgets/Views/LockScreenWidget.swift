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
    let cardState = WidgetSnapshot.resolveTodayCardState(
      snapshot: snapshot,
      pinnedId: entry.pinnedId,
      state: entry.state
    )
    let isPinned = snapshot?.isTodayJourneyPinned(entry.pinnedId) ?? false
    let featured: WidgetJourneyItem? = {
      if case .ready(let item) = cardState { return item }
      return nil
    }()

    let bestStreak: Int = {
      if let item = featured, isPinned {
        return item.currentStreak
      }
      return max(snapshot?.totals.bestActiveStreak ?? 0, featured?.currentStreak ?? 0)
    }()

    let pendingCount: Int = {
      if let item = featured, isPinned {
        return item.checkedInToday ? 0 : 1
      }
      return snapshot?.totals.pendingTodayCount ?? 0
    }()

    let activeCount: Int = {
      if featured != nil && isPinned {
        return 1
      }
      return max(snapshot?.totals.activeCount ?? 1, 1)
    }()

    let completedCount: Int = {
      if let item = featured, isPinned {
        return item.checkedInToday ? 1 : 0
      }
      return snapshot?.totals.completedTodayCount ?? 0
    }()

    let redactTitle = snapshot?.shouldRedactLockScreenTitle(for: featured) ?? true

    let statusTextOverride: String? = {
      switch cardState {
      case .ready:
        return nil
      case .unsynced:
        return WidgetL10n.unsyncedLockScreenStatus(locale: locale)
      case .signedOut:
        return WidgetL10n.signedOutCta(locale: locale)
      case .noJourneys:
        return WidgetL10n.noJourneysCta(locale: locale)
      }
    }()

    let destination: URL = {
      switch cardState {
      case .ready(let item):
        return item.checkedInToday
          ? OurneyDeepLinks.journey(id: item.id)
          : OurneyDeepLinks.capture(journeyId: item.id)
      case .unsynced, .signedOut:
        return OurneyDeepLinks.syncJourneys
      case .noJourneys:
        return OurneyDeepLinks.newJourney
      }
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
            statusOverride: statusTextOverride,
            locale: locale
          )
        } else {
          LockScreenRectangularView(
            journey: featured,
            streak: bestStreak,
            pendingCount: pendingCount,
            redactTitle: redactTitle,
            statusOverride: statusTextOverride,
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
  let statusOverride: String?
  let locale: String

  var body: some View {
    let rawTitle = journey?.title.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let isRedactedToBrand = redactTitle || rawTitle.isEmpty
    let title = isRedactedToBrand
      ? WidgetL10n.lockScreenRedactedTitle(locale: locale)
      : rawTitle
    let days = journey?.weekStrip ?? []
    let footerText = statusOverride ?? WidgetL10n.lockScreenRemaining(pending: pendingCount, locale: locale)

    VStack(alignment: .leading, spacing: 3) {
      HStack(spacing: 4) {
        OurneyIconView(name: "flame", size: 13, flat: true, overrideColor: .primary)
          .ourneyWidgetAccentable()
        Text("\(streak)")
          .font(OurneyWidgetFont.display(14, weight: .bold))
          .ourneyWidgetAccentable()

        // Never apply `.privacySensitive()` when `title` is already redacted to `"Ourney"`
        // (Rank 6.3: avoids turning the brand header into a gray placeholder bar on locked iPhones).
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

      Text(footerText)
        .font(OurneyWidgetFont.body(10, bold: false))
        .foregroundColor(.secondary)
        .lineLimit(1)
    }
  }
}

private struct LockScreenInlineView: View {
  let streak: Int
  let pending: Int
  let statusOverride: String?
  let locale: String

  var body: some View {
    let inlineText: String = {
      if let overrideText = statusOverride {
        return "Ourney · \(overrideText)"
      }
      return WidgetL10n.lockScreenInline(streak: streak, pending: pending, locale: locale)
    }()

    HStack(spacing: 4) {
      OurneyIconView(name: "flame", size: 12, flat: true, overrideColor: .primary)
      Text(inlineText)
    }
  }
}
