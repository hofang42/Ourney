import SwiftUI
import WidgetKit
#if canImport(AppIntents)
import AppIntents
#endif

// MARK: - Today Check-In Widget (§3.1 #1)

public struct TodayWidget: Widget {
  public let kind: String = OurneyWidgetKind.today

  public init() {}

  public var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: OurneyTimelineProvider(kind: kind)) { entry in
      TodayWidgetEntryView(entry: entry)
    }
    .configurationDisplayName(WidgetL10n.tr("widget.today.gallery.title"))
    .description(WidgetL10n.tr("widget.today.gallery.desc"))
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

public struct TodayWidgetEntryView: View {
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var colorScheme
  public let entry: OurneyWidgetEntry

  public init(entry: OurneyWidgetEntry) {
    self.entry = entry
  }

  public var body: some View {
    let snapshot = entry.snapshot
    let locale = snapshot?.locale ?? ""
    let themeMode = snapshot?.themeMode ?? "system"
    let cardState = WidgetSnapshot.resolveTodayCardState(
      snapshot: snapshot,
      state: entry.state,
      appGroupAvailable: entry.appGroupAvailable
    )
    let featured: WidgetJourneyItem? = {
      if case .ready(let journey) = cardState { return journey }
      return nil
    }()
    let theme = OurneyWidgetTheme.resolve(
      skinId: featured?.skinId,
      colorVariant: featured?.colorVariant ?? 0,
      themeMode: themeMode,
      systemScheme: colorScheme
    )

    Group {
      switch cardState {
      case .ready(let journey):
        if let snap = snapshot {
          switch family {
          case .systemMedium:
            TodayMediumView(
              snapshot: snap,
              journey: journey,
              entryDate: entry.date,
              theme: theme
            )
          case .systemLarge:
            TodayLargeView(
              snapshot: snap,
              journey: journey,
              entryDate: entry.date,
              theme: theme
            )
          default:
            TodaySmallView(
              snapshot: snap,
              journey: journey,
              entryDate: entry.date,
              theme: theme
            )
          }
        }
      case .appGroupUnavailable:
        AppGroupUnavailableWidgetView(locale: locale, theme: theme, isSmall: family == .systemSmall)
      case .unsynced:
        OurneyEmptyWidgetView(
          iconName: "sparkle",
          title: WidgetL10n.unsyncedTitle(locale: locale),
          subtitle: WidgetL10n.unsyncedSubtitle(locale: locale),
          ctaLabel: WidgetL10n.unsyncedCta(locale: locale),
          destination: OurneyDeepLinks.syncJourneys,
          theme: theme,
          isSmall: family == .systemSmall
        )
      case .signedOut:
        OurneyEmptyWidgetView(
          iconName: "lock",
          title: WidgetL10n.signedOutTitle(locale: locale),
          subtitle: WidgetL10n.signedOutSubtitle(locale: locale),
          ctaLabel: WidgetL10n.signedOutCta(locale: locale),
          destination: OurneyDeepLinks.syncJourneys,
          theme: theme,
          isSmall: family == .systemSmall
        )
      case .noJourneys:
        OurneyEmptyWidgetView(
          iconName: "journeys",
          title: WidgetL10n.noJourneysTitle(locale: locale),
          subtitle: WidgetL10n.noJourneysSubtitle(locale: locale),
          ctaLabel: WidgetL10n.noJourneysCta(locale: locale),
          destination: OurneyDeepLinks.newJourney,
          theme: theme,
          isSmall: family == .systemSmall
        )
      }
    }
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    .ourneyWidgetPadding()
    .ourneyWidgetContainerBackground {
      theme.bg
    }
    .widgetURL(cardState.tapURL)
  }
}

// MARK: - Small (2x2)

private struct TodaySmallView: View {
  let snapshot: WidgetSnapshot
  let journey: WidgetJourneyItem
  let entryDate: Date
  let theme: OurneyWidgetTheme

  var body: some View {
    let locale = snapshot.locale
    let phase = journey.phase(at: entryDate)
    let cyclePool = snapshot.todayCyclePool()
    let cycleIndex = (cyclePool.firstIndex(where: { $0.id == journey.id }) ?? 0) + 1
    let showCycleControl = cyclePool.count >= 2
    let destination = journey.captureURL

    VStack(alignment: .leading, spacing: 6) {
      // Top header: type icon + day pill + interactive cycle button if 2+ journeys
      HStack(spacing: 5) {
        OurneyIconView(name: journey.typeIcon, size: 18, ink: theme.ink)

        Text(WidgetL10n.dayLabel(dayNumber: journey.dayNumber, totalDays: journey.totalDays, locale: locale))
          .font(OurneyWidgetFont.body(10, bold: true))
          .foregroundColor(theme.inkMuted)
          .lineLimit(1)
          .minimumScaleFactor(0.75)

        Spacer(minLength: 2)

        if showCycleControl {
          TodayCycleJourneyButton(
            currentIndex: cycleIndex,
            totalPending: cyclePool.count,
            locale: locale,
            theme: theme
          )
        }
      }

      // Middle: Completed Polaroid preview or Journey title + urgency status
      if journey.checkedInToday,
         snapshot.privacy.allowsPhotosOnHomeScreen,
         let uiImage = OurneyThumbLoader.loadDownsampledImage(
           relativePath: journey.heroThumbFile,
           maxPixelSize: 240
         ) {
        HStack(spacing: 8) {
          Image(uiImage: uiImage)
            .resizable()
            .ourneyWidgetAccentedPhoto()
            .scaledToFill()
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(theme.outline, lineWidth: 1.5)
            )
            .privacySensitive()

          VStack(alignment: .leading, spacing: 2) {
            Text(journey.title)
              .font(OurneyWidgetFont.title(12))
              .foregroundColor(theme.ink)
              .lineLimit(2)
              .lineSpacing(2)
              .minimumScaleFactor(0.8)
            Text(WidgetL10n.checkedInToday(locale: locale))
              .font(OurneyWidgetFont.body(10, bold: true))
              .foregroundColor(theme.success)
              .lineLimit(1)
              .minimumScaleFactor(0.75)
          }
        }
      } else {
        VStack(alignment: .leading, spacing: 3) {
          Text(journey.title)
            .font(OurneyWidgetFont.title(13.5))
            .foregroundColor(theme.ink)
            .lineLimit(2)
            .lineSpacing(2)
            .minimumScaleFactor(0.8)

          TodayPhaseStatusBadge(phase: phase, journey: journey, locale: locale, theme: theme)
        }
      }

      Spacer(minLength: 2)

      // Bottom bar: Streak flame + numeral on left, Snap/Done pill on right
      HStack(alignment: .center, spacing: 6) {
        HStack(spacing: 3) {
          OurneyIconView(name: "flame", size: 18, ink: theme.ink)
            .ourneyWidgetAccentable()
          Text("\(journey.currentStreak)")
            .font(OurneyWidgetFont.display(18, weight: .bold))
            .foregroundColor(theme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .ourneyWidgetAccentable()
        }

        Spacer(minLength: 2)

        Link(destination: destination) {
          HStack(spacing: 4) {
            OurneyIconView(
              name: journey.checkedInToday ? "check" : "camera",
              size: 13,
              ink: journey.checkedInToday ? theme.ink : theme.onBrand,
              flat: true,
              overrideColor: journey.checkedInToday ? theme.ink : theme.onBrand
            )
            Text(journey.checkedInToday ? WidgetL10n.doneShort(locale: locale) : WidgetL10n.snapShort(locale: locale))
              .font(OurneyWidgetFont.body(11, bold: true))
              .foregroundColor(journey.checkedInToday ? theme.ink : theme.onBrand)
              .lineLimit(1)
              .minimumScaleFactor(0.8)
          }
          .padding(.horizontal, 10)
          .frame(minHeight: 32)
          .ourneyStickerCard(
            fill: journey.checkedInToday ? theme.surface : theme.brand,
            outline: theme.outline,
            shadow: theme.hardShadow,
            cornerRadius: 10,
            borderWidth: theme.borderWidth,
            shadowOffset: 2.0
          )
          .ourneyWidgetAccentable(!journey.checkedInToday)
        }
        .accessibilityLabel(
          WidgetL10n.todayVoiceOverLabel(journey: journey, phase: phase, locale: locale)
        )
      }
    }
    .ourneyTodaySmallAccessibility(
      hasInteractiveCycle: showCycleControl,
      label: WidgetL10n.todayVoiceOverLabel(journey: journey, phase: phase, locale: locale)
    )
  }
}

private extension View {
  @ViewBuilder
  func ourneyTodaySmallAccessibility(hasInteractiveCycle: Bool, label: String) -> some View {
    #if canImport(AppIntents)
    if #available(iOSApplicationExtension 17.0, iOS 17.0, *), hasInteractiveCycle {
      self.accessibilityElement(children: .contain)
    } else {
      self
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }
    #else
    self
      .accessibilityElement(children: .combine)
      .accessibilityLabel(label)
    #endif
  }
}

// MARK: - Medium (4x2)

private struct TodayMediumView: View {
  let snapshot: WidgetSnapshot
  let journey: WidgetJourneyItem
  let entryDate: Date
  let theme: OurneyWidgetTheme

  var body: some View {
    let locale = snapshot.locale
    let phase = journey.phase(at: entryDate)
    let cyclePool = snapshot.todayCyclePool()
    let cycleIndex = (cyclePool.firstIndex(where: { $0.id == journey.id }) ?? 0) + 1
    let destination = journey.captureURL

    HStack(spacing: 10) {
      // Left column: Title, urgency status badge, 7-day chain strip
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 6) {
          OurneyIconView(name: journey.typeIcon, size: 18, ink: theme.ink)

          Text(WidgetL10n.dayLabel(dayNumber: journey.dayNumber, totalDays: journey.totalDays, locale: locale))
            .font(OurneyWidgetFont.body(10, bold: true))
            .foregroundColor(theme.inkMuted)
            .lineLimit(1)

          Spacer(minLength: 2)

          if cyclePool.count >= 2 {
            TodayCycleJourneyButton(
              currentIndex: cycleIndex,
              totalPending: cyclePool.count,
              locale: locale,
              theme: theme
            )
          }
        }

        Text(journey.title)
          .font(OurneyWidgetFont.title(14.5))
          .foregroundColor(theme.ink)
          .lineLimit(1)
          .lineSpacing(2)
          .minimumScaleFactor(0.8)

        TodayPhaseStatusBadge(phase: phase, journey: journey, locale: locale, theme: theme)

        Spacer(minLength: 2)

        OurneyWeekStripView(days: journey.weekStrip, theme: theme, compact: true, locale: locale)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      // Right column: Completed Polaroid Frame or Streak Card + Snap CTA
      VStack(spacing: 6) {
        if journey.checkedInToday,
           snapshot.privacy.allowsPhotosOnHomeScreen,
           let uiImage = OurneyThumbLoader.loadDownsampledImage(
             relativePath: journey.heroThumbFile,
             maxPixelSize: 280
           ) {
          Link(destination: destination) {
            VStack(spacing: 3) {
              Image(uiImage: uiImage)
                .resizable()
                .ourneyWidgetAccentedPhoto()
                .scaledToFill()
                .frame(width: 86, height: 74)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .privacySensitive()

              HStack(spacing: 3) {
                OurneyIconView(name: "flame", size: 13, ink: theme.ink)
                Text("\(journey.currentStreak)")
                  .font(OurneyWidgetFont.display(13, weight: .bold))
                  .foregroundColor(theme.ink)
                OurneyIconView(name: "check", size: 12, flat: true, overrideColor: theme.success)
              }
            }
            .padding(5)
            .ourneyStickerCard(
              fill: theme.surface,
              outline: theme.outline,
              shadow: theme.hardShadow,
              cornerRadius: 12,
              borderWidth: theme.borderWidth,
              shadowOffset: 2.5
            )
          }
        } else {
          // Streak Sticker box
          VStack(spacing: 1) {
            HStack(spacing: 4) {
              OurneyIconView(name: "flame", size: 20, ink: theme.ink)
                .ourneyWidgetAccentable()
              Text("\(journey.currentStreak)")
                .font(OurneyWidgetFont.display(22, weight: .bold))
                .foregroundColor(theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .ourneyWidgetAccentable()
            }
            Text(WidgetL10n.streakCountLabel(journey.currentStreak, locale: locale))
              .font(OurneyWidgetFont.body(9.5, bold: true))
              .foregroundColor(theme.inkMuted)
              .lineLimit(1)
              .minimumScaleFactor(0.75)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 6)
          .ourneyStickerCard(
            fill: theme.surface,
            outline: theme.outline,
            shadow: theme.hardShadow,
            cornerRadius: 12,
            borderWidth: theme.borderWidth,
            shadowOffset: 2.0
          )

          // 44pt minimum touch-target CTA button (§5.4)
          Link(destination: destination) {
            HStack(spacing: 5) {
              OurneyIconView(
                name: journey.checkedInToday ? "check" : "camera",
                size: 14,
                ink: journey.checkedInToday ? theme.ink : theme.onBrand,
                flat: true,
                overrideColor: journey.checkedInToday ? theme.ink : theme.onBrand
              )
              Text(journey.checkedInToday ? WidgetL10n.doneShort(locale: locale) : WidgetL10n.snapNow(locale: locale))
                .font(OurneyWidgetFont.body(11.5, bold: true))
                .foregroundColor(journey.checkedInToday ? theme.ink : theme.onBrand)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, minHeight: 40)
            .ourneyStickerCard(
              fill: journey.checkedInToday ? theme.surface : theme.brand,
              outline: theme.outline,
              shadow: theme.hardShadow,
              cornerRadius: 12,
              borderWidth: theme.borderWidth,
              shadowOffset: 2.5
            )
            .ourneyWidgetAccentable(!journey.checkedInToday)
          }
        }
      }
      .frame(width: 102)
    }
  }
}

// MARK: - Large (4x4)

private struct TodayLargeView: View {
  let snapshot: WidgetSnapshot
  let journey: WidgetJourneyItem
  let entryDate: Date
  let theme: OurneyWidgetTheme

  var body: some View {
    let locale = snapshot.locale
    let phase = journey.phase(at: entryDate)
    let cyclePool = snapshot.todayCyclePool()
    let cycleIndex = (cyclePool.firstIndex(where: { $0.id == journey.id }) ?? 0) + 1
    let otherJourneys = snapshot.journeys.filter { $0.id != journey.id }.prefix(2)
    let destination = journey.captureURL

    VStack(alignment: .leading, spacing: 8) {
      // Top summary bar
      HStack(spacing: 6) {
        Text(
          WidgetL10n.todayHeaderProgress(
            completed: snapshot.totals.completedTodayCount,
            total: max(snapshot.totals.activeCount, snapshot.journeys.count),
            locale: locale
          )
        )
        .font(OurneyWidgetFont.body(10.5, bold: true))
        .foregroundColor(theme.inkMuted)
        .lineLimit(1)

        Spacer()

        if cyclePool.count >= 2 {
          TodayCycleJourneyButton(
            currentIndex: cycleIndex,
            totalPending: cyclePool.count,
            locale: locale,
            theme: theme
          )
        }

        HStack(spacing: 3) {
          OurneyIconView(name: "flame", size: 15, ink: theme.ink)
          Text("\(max(snapshot.totals.bestActiveStreak, journey.currentStreak))")
            .font(OurneyWidgetFont.display(14, weight: .bold))
            .foregroundColor(theme.ink)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .ourneyStickerCard(
          fill: theme.surface,
          outline: theme.outline,
          shadow: theme.hardShadow,
          cornerRadius: 9,
          borderWidth: 1.5,
          shadowOffset: 1.5
        )
      }

      // Featured journey card
      VStack(alignment: .leading, spacing: 8) {
        HStack(alignment: .top, spacing: 8) {
          OurneyIconView(name: journey.typeIcon, size: 22, ink: theme.ink)

          VStack(alignment: .leading, spacing: 2) {
            Text(journey.title)
              .font(OurneyWidgetFont.title(15))
              .foregroundColor(theme.ink)
              .lineLimit(1)
              .lineSpacing(2)
              .minimumScaleFactor(0.8)

            HStack(spacing: 6) {
              Text(WidgetL10n.dayLabel(dayNumber: journey.dayNumber, totalDays: journey.totalDays, locale: locale))
                .font(OurneyWidgetFont.body(10, bold: true))
                .foregroundColor(theme.inkMuted)

              TodayPhaseStatusBadge(phase: phase, journey: journey, locale: locale, theme: theme)
            }
          }

          Spacer(minLength: 4)

          HStack(spacing: 3) {
            OurneyIconView(name: "flame", size: 18, ink: theme.ink)
              .ourneyWidgetAccentable()
            Text("\(journey.currentStreak)")
              .font(OurneyWidgetFont.display(19, weight: .bold))
              .foregroundColor(theme.ink)
              .ourneyWidgetAccentable()
          }
        }

        OurneyWeekStripView(days: journey.weekStrip, theme: theme, compact: false, locale: locale)

        Link(destination: destination) {
          HStack(spacing: 6) {
            OurneyIconView(
              name: journey.checkedInToday ? "check" : "camera",
              size: 16,
              ink: journey.checkedInToday ? theme.ink : theme.onBrand,
              flat: true,
              overrideColor: journey.checkedInToday ? theme.ink : theme.onBrand
            )
            Text(journey.checkedInToday ? WidgetL10n.checkedInToday(locale: locale) : WidgetL10n.snapNow(locale: locale))
              .font(OurneyWidgetFont.body(12.5, bold: true))
              .foregroundColor(journey.checkedInToday ? theme.ink : theme.onBrand)
              .lineLimit(1)
          }
          .frame(maxWidth: .infinity, minHeight: 38)
          .ourneyStickerCard(
            fill: journey.checkedInToday ? theme.fill : theme.brand,
            outline: theme.outline,
            shadow: theme.hardShadow,
            cornerRadius: 11,
            borderWidth: theme.borderWidth,
            shadowOffset: 2.0
          )
          .ourneyWidgetAccentable(!journey.checkedInToday)
        }
      }
      .padding(10)
      .ourneyStickerCard(
        fill: theme.surface,
        outline: theme.outline,
        shadow: theme.hardShadow,
        cornerRadius: 14,
        borderWidth: theme.borderWidth,
        shadowOffset: 3.0
      )

      // Additional active journeys queue
      if !otherJourneys.isEmpty {
        VStack(spacing: 6) {
          ForEach(Array(otherJourneys)) { item in
            Link(destination: item.captureURL) {
              HStack(spacing: 8) {
                OurneyIconView(name: item.typeIcon, size: 17, ink: theme.ink)

                Text(item.title)
                  .font(OurneyWidgetFont.body(12, bold: true))
                  .foregroundColor(theme.ink)
                  .lineLimit(1)
                  .lineSpacing(2)

                Spacer(minLength: 4)

                HStack(spacing: 2) {
                  OurneyIconView(name: "flame", size: 14, ink: theme.ink)
                  Text("\(item.currentStreak)")
                    .font(OurneyWidgetFont.display(13, weight: .bold))
                    .foregroundColor(theme.ink)
                }

                ZStack {
                  RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(item.checkedInToday ? theme.successSoft : theme.brand)
                    .frame(width: 26, height: 24)
                    .overlay(
                      RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(theme.outline, lineWidth: 1.4)
                    )
                  OurneyIconView(
                    name: item.checkedInToday ? "check" : "camera",
                    size: 13,
                    flat: true,
                    overrideColor: item.checkedInToday ? theme.success : theme.onBrand
                  )
                }
              }
              .padding(.horizontal, 10)
              .padding(.vertical, 6)
              .ourneyStickerCard(
                fill: theme.surface,
                outline: theme.outline,
                shadow: theme.hardShadow,
                cornerRadius: 11,
                borderWidth: 1.5,
                shadowOffset: 2.0
              )
            }
          }
        }
      }

      Spacer(minLength: 0)
    }
  }
}

// MARK: - Subviews: Interactive Cycle Button, Phase Status Pill & Empty State

private struct TodayCycleJourneyButton: View {
  let currentIndex: Int
  let totalPending: Int
  let locale: String
  let theme: OurneyWidgetTheme

  var body: some View {
    #if canImport(AppIntents)
    if #available(iOSApplicationExtension 17.0, iOS 17.0, *) {
      Button(intent: CycleTodayJourneyIntent()) {
        pillContent(showChevron: true)
          .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(
        WidgetL10n.cycleJourneyVoiceOverLabel(
          currentIndex: currentIndex,
          totalPending: totalPending,
          locale: locale
        )
      )
      .padding(.vertical, -10)
    } else {
      pillContent(showChevron: false)
    }
    #else
    pillContent(showChevron: false)
    #endif
  }

  private func pillContent(showChevron: Bool) -> some View {
    HStack(spacing: 2) {
      Text("\(currentIndex)/\(totalPending)")
        .font(OurneyWidgetFont.body(9.5, bold: true))
        .foregroundColor(theme.ink)
      if showChevron {
        OurneyIconView(name: "chevron-right", size: 11, flat: true, overrideColor: theme.ink)
      }
    }
    .padding(.horizontal, 7)
    .padding(.vertical, 3)
    .ourneyStickerCard(
      fill: theme.surface,
      outline: theme.outline,
      shadow: theme.hardShadow,
      cornerRadius: 8,
      borderWidth: 1.4,
      shadowOffset: 1.5
    )
  }
}

struct TodayPhaseStatusBadge: View {
  let phase: OurneyTimePhase
  let journey: WidgetJourneyItem
  let locale: String
  let theme: OurneyWidgetTheme

  var body: some View {
    let badgeText = WidgetL10n.phaseBadgeText(
      phase: phase,
      skinId: journey.skinId,
      streak: journey.currentStreak,
      locale: locale
    )
    let iconName: String = {
      switch phase {
      case .completed: return "check"
      case .urgentAtRisk: return "flame"
      case .eveningCue, .daytime: return "clock"
      }
    }()
    let textColor: Color = {
      switch phase {
      case .completed: return theme.success
      case .urgentAtRisk: return theme.timeCue
      case .eveningCue: return theme.ink
      case .daytime: return theme.inkMuted
      }
    }()

    HStack(spacing: 4) {
      OurneyIconView(
        name: iconName,
        size: 12,
        ink: theme.ink,
        flat: phase == .completed || phase == .daytime,
        overrideColor: phase == .completed ? theme.success : (phase == .daytime ? theme.inkMuted : nil)
      )
      Text(badgeText)
        .font(OurneyWidgetFont.body(10.5, bold: phase == .urgentAtRisk || phase == .completed))
        .foregroundColor(textColor)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
  }
}

struct AppGroupUnavailableWidgetView: View {
  let locale: String
  let theme: OurneyWidgetTheme
  let isSmall: Bool

  var body: some View {
    OurneyEmptyWidgetView(
      iconName: "lock",
      title: WidgetL10n.appGroupUnavailableTitle(locale: locale),
      subtitle: WidgetL10n.appGroupUnavailableSubtitle(locale: locale),
      ctaLabel: WidgetL10n.openOurney(locale: locale),
      destination: OurneyDeepLinks.journeys,
      theme: theme,
      isSmall: isSmall
    )
  }
}

public struct OurneyEmptyWidgetView: View {
  public let iconName: String
  public let title: String
  public let subtitle: String
  public let ctaLabel: String
  public let destination: URL
  public let theme: OurneyWidgetTheme
  public let isSmall: Bool

  public init(
    iconName: String,
    title: String,
    subtitle: String,
    ctaLabel: String,
    destination: URL,
    theme: OurneyWidgetTheme,
    isSmall: Bool
  ) {
    self.iconName = iconName
    self.title = title
    self.subtitle = subtitle
    self.ctaLabel = ctaLabel
    self.destination = destination
    self.theme = theme
    self.isSmall = isSmall
  }

  public var body: some View {
    Link(destination: destination) {
      VStack(alignment: .leading, spacing: isSmall ? 6 : 8) {
        HStack(spacing: 6) {
          OurneyIconView(name: iconName, size: isSmall ? 22 : 24, ink: theme.ink)
          Text("OURNEY")
            .font(OurneyWidgetFont.display(11, weight: .bold))
            .foregroundColor(theme.inkMuted)
          Spacer()
        }

        Text(title)
          .font(OurneyWidgetFont.title(isSmall ? 13 : 15))
          .foregroundColor(theme.ink)
          .lineLimit(2)
          .lineSpacing(2)
          .minimumScaleFactor(0.8)

        if !isSmall {
          Text(subtitle)
            .font(OurneyWidgetFont.body(11, bold: false))
            .foregroundColor(theme.inkMuted)
            .lineLimit(2)
            .lineSpacing(2)
            .minimumScaleFactor(0.85)
        }

        Spacer(minLength: 2)

        HStack(spacing: 5) {
          OurneyIconView(name: "sparkle", size: 13, ink: theme.onBrand, flat: true, overrideColor: theme.onBrand)
          Text(ctaLabel)
            .font(OurneyWidgetFont.body(11.5, bold: true))
            .foregroundColor(theme.onBrand)
            .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 32)
        .ourneyStickerCard(
          fill: theme.brand,
          outline: theme.outline,
          shadow: theme.hardShadow,
          cornerRadius: 10,
          borderWidth: theme.borderWidth,
          shadowOffset: 2.0
        )
        .ourneyWidgetAccentable()
      }
    }
  }
}
