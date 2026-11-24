import SwiftUI
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit
#endif
#if canImport(AppIntents)
import AppIntents
#endif

#if canImport(ActivityKit)
/// iOS 16.2+ Check-In Window Live Activity for Lock Screen, StandBy, and Dynamic Island (§6.1).
/// Strictly omits photos and weight/health metrics. Uses `Text(timerInterval:countsDown:)` so
/// SpringBoard ticks the countdown every second with zero background app wakeups.
@available(iOSApplicationExtension 16.2, iOS 16.2, *)
public struct CheckInLiveActivity: Widget {
  public init() {}

  public var body: some WidgetConfiguration {
    ActivityConfiguration(for: OurneyCheckInAttributes.self) { context in
      CheckInLockScreenBannerView(
        windowKey: context.attributes.windowKey,
        state: context.state
      )
      .activityBackgroundTint(OurneyWidgetTheme.cameraDark.bg)
      .activitySystemActionForegroundColor(OurneyWidgetTheme.cameraDark.ink)
    } dynamicIsland: { context in
      let state = context.state
      let captureURL = OurneyDeepLinks.capture(journeyId: state.journeyId)
      let isUrgent = state.atRisk && !state.isCompletedCelebration
      let flameNumeralColor = isUrgent
        ? Color(.sRGB, red: 1.0, green: 0.302, blue: 0.427, opacity: 1.0) // #FF4D6D
        : Color(.sRGB, red: 0.949, green: 0.663, blue: 0.231, opacity: 1.0) // #F2A93B
      let headerLabelColor = state.isCompletedCelebration
        ? OurneyWidgetTheme.cameraDark.success
        : flameNumeralColor

      return DynamicIsland {
        // MARK: Expanded Presentation
        DynamicIslandExpandedRegion(.leading) {
          HStack(spacing: 6) {
            OurneyIconView(
              name: state.typeIcon,
              size: 20,
              ink: OurneyWidgetTheme.cameraDark.ink
            )
            VStack(alignment: .leading, spacing: 1) {
              Text(
                state.isCompletedCelebration
                  ? WidgetL10n.checkedInToday(locale: state.locale).uppercased()
                  : WidgetL10n.liveActivityWindowLabel(
                    atRisk: isUrgent,
                    skinId: state.skinId,
                    locale: state.locale
                  )
              )
              .font(OurneyWidgetFont.body(9, bold: true))
              .foregroundColor(headerLabelColor)
              .lineLimit(1)

              Text(state.journeyTitle)
                .font(OurneyWidgetFont.title(13))
                .foregroundColor(OurneyWidgetTheme.cameraDark.ink)
                .lineLimit(1)
                .privacySensitive(state.redactTitleOnLockScreen)
            }
          }
        }

        DynamicIslandExpandedRegion(.trailing) {
          HStack(spacing: 6) {
            HStack(spacing: 3) {
              OurneyIconView(name: "flame", size: 17, ink: OurneyWidgetTheme.cameraDark.ink)
              Text("\(state.currentStreak)")
                .font(OurneyWidgetFont.display(16, weight: .bold))
                .foregroundColor(flameNumeralColor)
            }

            LiveActivityDismissButton(locale: state.locale)
          }
        }

        DynamicIslandExpandedRegion(.bottom) {
          VStack(spacing: 8) {
            // Segmented daily completion bar
            LiveActivitySegmentedBar(
              completed: state.completedCount,
              total: max(state.totalActiveCount, state.completedCount + state.pendingCount)
            )

            HStack(spacing: 10) {
              if state.isCompletedCelebration {
                HStack(spacing: 5) {
                  OurneyIconView(
                    name: "check",
                    size: 15,
                    flat: true,
                    overrideColor: OurneyWidgetTheme.cameraDark.success
                  )
                  Text(
                    WidgetL10n.liveActivityCelebrationTitle(
                      streak: state.currentStreak,
                      locale: state.locale
                    )
                  )
                  .font(OurneyWidgetFont.body(12, bold: true))
                  .foregroundColor(OurneyWidgetTheme.cameraDark.success)
                  .lineLimit(1)
                }
              } else {
                HStack(spacing: 5) {
                  OurneyIconView(name: "clock", size: 14, ink: OurneyWidgetTheme.cameraDark.ink)
                  Text(
                    timerInterval: Self.safeInterval(
                      start: state.windowStartUtc,
                      end: state.deadlineUtc
                    ),
                    countsDown: true
                  )
                  .font(OurneyWidgetFont.display(14, weight: .bold))
                  .monospacedDigit()
                  .foregroundColor(OurneyWidgetTheme.cameraDark.ink)
                  .frame(maxWidth: 72, alignment: .leading)
                }
              }

              Spacer(minLength: 4)

              if !state.isCompletedCelebration {
                Link(destination: captureURL) {
                  HStack(spacing: 5) {
                    OurneyIconView(
                      name: "camera",
                      size: 14,
                      flat: true,
                      overrideColor: OurneyWidgetTheme.cameraDark.onBrand
                    )
                    Text(WidgetL10n.snapNow(locale: state.locale))
                      .font(OurneyWidgetFont.body(12, bold: true))
                      .foregroundColor(OurneyWidgetTheme.cameraDark.onBrand)
                      .lineLimit(1)
                  }
                  .padding(.horizontal, 14)
                  .frame(minHeight: 34)
                  .ourneyStickerCard(
                    fill: OurneyWidgetTheme.cameraDark.brand,
                    outline: OurneyWidgetTheme.cameraDark.ink,
                    shadow: OurneyWidgetTheme.cameraDark.hardShadow,
                    cornerRadius: 11,
                    borderWidth: 1.5,
                    shadowOffset: 2.0
                  )
                }
              }
            }
          }
          .padding(.top, 4)
        }
      } compactLeading: {
        // MARK: Compact Leading (Flame + Streak Count)
        HStack(spacing: 4) {
          OurneyIconView(name: "flame", size: 16, ink: OurneyWidgetTheme.cameraDark.ink)
          Text("\(state.currentStreak)")
            .font(OurneyWidgetFont.display(14, weight: .bold))
            .foregroundColor(flameNumeralColor)
            .lineLimit(1)
        }
      } compactTrailing: {
        // MARK: Compact Trailing (Live System Countdown)
        if state.isCompletedCelebration {
          OurneyIconView(
            name: "check",
            size: 14,
            flat: true,
            overrideColor: OurneyWidgetTheme.cameraDark.success
          )
        } else {
          Text(
            timerInterval: Self.safeInterval(
              start: state.windowStartUtc,
              end: state.deadlineUtc
            ),
            countsDown: true
          )
          .font(OurneyWidgetFont.display(12.5, weight: .bold))
          .monospacedDigit()
          .foregroundColor(OurneyWidgetTheme.cameraDark.ink)
          .frame(maxWidth: 52)
        }
      } minimal: {
        // MARK: Minimal Presentation (Flame inside Circular Progress Ring)
        let total = max(state.totalActiveCount, 1)
        let progress = min(max(Double(state.completedCount) / Double(total), 0.15), 1.0)
        ZStack {
          Circle()
            .stroke(OurneyWidgetTheme.cameraDark.outline.opacity(0.35), lineWidth: 2)
          Circle()
            .trim(from: 0, to: progress)
            .stroke(
              flameNumeralColor,
              style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
          OurneyIconView(name: "flame", size: 13, ink: OurneyWidgetTheme.cameraDark.ink)
        }
      }
      .widgetURL(captureURL)
    }
  }

  static func safeInterval(start: Date, end: Date) -> ClosedRange<Date> {
    let now = Date()
    let safeStart = min(start, end)
    let safeEnd = max(end, safeStart.addingTimeInterval(1), now.addingTimeInterval(1))
    return safeStart...safeEnd
  }
}

// MARK: - Lock Screen / StandBy Banner View (§6.1)

@available(iOSApplicationExtension 16.2, iOS 16.2, *)
private struct CheckInLockScreenBannerView: View {
  let windowKey: String
  let state: OurneyCheckInAttributes.ContentState

  var body: some View {
    let dark = OurneyWidgetTheme.cameraDark
    let captureURL = OurneyDeepLinks.capture(journeyId: state.journeyId)
    let isUrgent = state.atRisk && !state.isCompletedCelebration
    let flameColor = isUrgent
      ? Color(.sRGB, red: 1.0, green: 0.302, blue: 0.427, opacity: 1.0)
      : dark.flame
    let headerLabelColor = state.isCompletedCelebration ? dark.success : flameColor

    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .center, spacing: 8) {
        OurneyIconView(name: state.typeIcon, size: 22, ink: dark.ink)

        VStack(alignment: .leading, spacing: 2) {
          Text(
            state.isCompletedCelebration
              ? WidgetL10n.checkedInToday(locale: state.locale).uppercased()
              : WidgetL10n.liveActivityWindowLabel(
                atRisk: isUrgent,
                skinId: state.skinId,
                locale: state.locale
              )
          )
          .font(OurneyWidgetFont.body(9.5, bold: true))
          .foregroundColor(headerLabelColor)
          .lineLimit(1)

          Text(
            state.isCompletedCelebration
              ? WidgetL10n.liveActivityCelebrationTitle(streak: state.currentStreak, locale: state.locale)
              : state.journeyTitle
          )
          .font(OurneyWidgetFont.title(14.5))
          .foregroundColor(dark.ink)
          .lineLimit(1)
          .lineSpacing(2)
          .privacySensitive(state.redactTitleOnLockScreen)
        }

        Spacer(minLength: 4)

        // Streak pill
        HStack(spacing: 3) {
          OurneyIconView(name: "flame", size: 16, ink: dark.ink)
          Text("\(state.currentStreak)")
            .font(OurneyWidgetFont.display(15, weight: .bold))
            .foregroundColor(flameColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
          RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(dark.surface)
        )
        .overlay(
          RoundedRectangle(cornerRadius: 9, style: .continuous)
            .strokeBorder(dark.outline, lineWidth: 1.2)
        )

        LiveActivityDismissButton(locale: state.locale)
      }

      LiveActivitySegmentedBar(
        completed: state.completedCount,
        total: max(state.totalActiveCount, state.completedCount + state.pendingCount)
      )

      if !state.isCompletedCelebration {
        HStack(alignment: .center, spacing: 10) {
          HStack(spacing: 5) {
            OurneyIconView(name: "clock", size: 15, ink: dark.ink)
            Text(
              timerInterval: CheckInLiveActivity.safeInterval(
                start: state.windowStartUtc,
                end: state.deadlineUtc
              ),
              countsDown: true
            )
            .font(OurneyWidgetFont.display(16, weight: .bold))
            .monospacedDigit()
            .foregroundColor(dark.ink)
          }

          Spacer(minLength: 4)

          Link(destination: captureURL) {
            HStack(spacing: 5) {
              OurneyIconView(
                name: "camera",
                size: 14,
                flat: true,
                overrideColor: dark.onBrand
              )
              Text(WidgetL10n.snapNow(locale: state.locale))
                .font(OurneyWidgetFont.body(12, bold: true))
                .foregroundColor(dark.onBrand)
                .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 36)
            .ourneyStickerCard(
              fill: dark.brand,
              outline: dark.ink,
              shadow: dark.hardShadow,
              cornerRadius: 11,
              borderWidth: 1.5,
              shadowOffset: 2.0
            )
          }
        }
      }
    }
    .padding(14)
    .background(dark.bg)
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .strokeBorder(dark.outline, lineWidth: 1.5)
    )
  }
}

@available(iOSApplicationExtension 16.2, iOS 16.2, *)
private struct LiveActivitySegmentedBar: View {
  let completed: Int
  let total: Int

  var body: some View {
    let segmentCount = min(max(total, 1), 8)
    let filledCount = min(max(completed, 0), segmentCount)
    let dark = OurneyWidgetTheme.cameraDark

    HStack(spacing: 4) {
      ForEach(0..<segmentCount, id: \.self) { index in
        RoundedRectangle(cornerRadius: 3, style: .continuous)
          .fill(index < filledCount ? dark.brand : dark.outline.opacity(0.32))
          .frame(height: 6)
      }
    }
  }
}

@available(iOSApplicationExtension 16.2, iOS 16.2, *)
private struct LiveActivityDismissButton: View {
  let locale: String

  var body: some View {
    #if canImport(AppIntents)
    if #available(iOSApplicationExtension 17.0, iOS 17.0, *) {
      Button(intent: EndCheckInWindowIntent()) {
        dismissGlyph
      }
      .buttonStyle(.plain)
      .accessibilityLabel(WidgetL10n.dismissLiveActivityVoiceOverLabel(locale: locale))
      .padding(-6)
    }
    #endif
  }

  private var dismissGlyph: some View {
    ZStack {
      Circle()
        .fill(OurneyWidgetTheme.cameraDark.surface)
        .frame(width: 28, height: 28)
        .overlay(
          Circle()
            .strokeBorder(OurneyWidgetTheme.cameraDark.outline, lineWidth: 1.2)
        )
      OurneyIconView(
        name: "close",
        size: 12,
        flat: true,
        overrideColor: OurneyWidgetTheme.cameraDark.inkMuted
      )
    }
    .frame(minWidth: 44, minHeight: 44)
    .contentShape(Rectangle())
  }
}
#endif
