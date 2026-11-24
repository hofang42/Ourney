import SwiftUI
import WidgetKit

// MARK: - Streak Sticker Widget (§3.1 #2)

public struct StreakWidget: Widget {
  public let kind: String = OurneyWidgetKind.streak

  public init() {}

  public var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: OurneyTimelineProvider()) { entry in
      StreakWidgetEntryView(entry: entry)
    }
    .configurationDisplayName(WidgetL10n.tr("widget.streak.gallery.title"))
    .description(WidgetL10n.tr("widget.streak.gallery.desc"))
    .supportedFamilies([.systemSmall])
  }
}

public struct StreakWidgetEntryView: View {
  @Environment(\.colorScheme) private var colorScheme
  public let entry: OurneyWidgetEntry

  public init(entry: OurneyWidgetEntry) {
    self.entry = entry
  }

  public var body: some View {
    let snapshot = entry.snapshot
    let locale = snapshot?.locale ?? "vi"
    let themeMode = snapshot?.themeMode ?? "system"
    let journey = snapshot?.selectedStreakJourney()
    let theme = OurneyWidgetTheme.resolve(
      skinId: journey?.skinId,
      colorVariant: journey?.colorVariant ?? 0,
      themeMode: themeMode,
      systemScheme: colorScheme
    )

    let destination: URL = {
      guard let item = journey, !(snapshot?.isSignedOutOrEmpty ?? true) else {
        return OurneyDeepLinks.journeys
      }
      return item.checkedInToday
        ? OurneyDeepLinks.journey(id: item.id)
        : OurneyDeepLinks.capture(journeyId: item.id)
    }()

    Group {
      if let snap = snapshot, !snap.isSignedOutOrEmpty, let item = journey {
        StreakSmallCardView(snapshot: snap, journey: item, entryDate: entry.date, theme: theme)
      } else {
        OurneyEmptyWidgetView(
          iconName: "flame",
          title: WidgetL10n.emptyTodayTitle(locale: locale),
          subtitle: WidgetL10n.emptyTodaySubtitle(locale: locale),
          ctaLabel: WidgetL10n.openOurney(locale: locale),
          destination: OurneyDeepLinks.journeys,
          theme: theme,
          isSmall: true
        )
      }
    }
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    .ourneyWidgetPadding()
    .ourneyWidgetContainerBackground {
      theme.bg
    }
    .widgetURL(destination)
  }
}

private struct StreakSmallCardView: View {
  let snapshot: WidgetSnapshot
  let journey: WidgetJourneyItem
  let entryDate: Date
  let theme: OurneyWidgetTheme

  var body: some View {
    let locale = snapshot.locale
    let phase = journey.phase(at: entryDate)

    VStack(alignment: .leading, spacing: 5) {
      // Top row: Journey type icon + title + status dot
      HStack(spacing: 5) {
        OurneyIconView(name: journey.typeIcon, size: 16, ink: theme.ink)

        Text(journey.title)
          .font(OurneyWidgetFont.body(11, bold: true))
          .foregroundColor(theme.ink)
          .lineLimit(1)
          .lineSpacing(2)
          .minimumScaleFactor(0.8)

        Spacer(minLength: 2)

        if journey.checkedInToday {
          OurneyIconView(name: "check", size: 13, flat: true, overrideColor: theme.success)
        } else if phase == .urgentAtRisk {
          OurneyIconView(name: "clock", size: 13, ink: theme.ink)
        }
      }

      Spacer(minLength: 0)

      // Center Hero: Giant BricolageGrotesque streak numeral + Two-Tone Ourney Flame Sticker
      HStack(alignment: .center, spacing: 6) {
        ZStack {
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(journey.checkedInToday ? theme.accent : theme.surface)
            .frame(width: 40, height: 40)
            .ourneyStickerCard(
              fill: journey.checkedInToday ? theme.accent : theme.surface,
              outline: theme.outline,
              shadow: theme.hardShadow,
              cornerRadius: 12,
              borderWidth: theme.borderWidth,
              shadowOffset: 2.5
            )
          OurneyIconView(name: "flame", size: 25, ink: theme.ink)
            .ourneyWidgetAccentable()
        }

        VStack(alignment: .leading, spacing: 0) {
          Text("\(journey.currentStreak)")
            .font(OurneyWidgetFont.display(32, weight: .bold))
            .foregroundColor(theme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .ourneyWidgetAccentable()

          Text(WidgetL10n.streakCountLabel(journey.currentStreak, locale: locale).uppercased())
            .font(OurneyWidgetFont.body(9.5, bold: true))
            .foregroundColor(phase == .urgentAtRisk ? theme.warn : theme.inkMuted)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }

        Spacer(minLength: 0)
      }

      Spacer(minLength: 0)

      // Bottom: 7-square compact week chain
      OurneyWeekStripView(days: journey.weekStrip, theme: theme, compact: true, locale: locale)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(
      WidgetL10n.todayVoiceOverLabel(journey: journey, phase: phase, locale: locale)
    )
  }
}
