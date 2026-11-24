import SwiftUI
import WidgetKit

// MARK: - Squad & Couple Today Widget (§3.1 #3)

public struct SquadWidget: Widget {
  public let kind: String = OurneyWidgetKind.squad

  public init() {}

  public var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: OurneyTimelineProvider()) { entry in
      SquadWidgetEntryView(entry: entry)
    }
    .configurationDisplayName(WidgetL10n.tr("widget.squad.gallery.title"))
    .description(WidgetL10n.tr("widget.squad.gallery.desc"))
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

public struct SquadWidgetEntryView: View {
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var colorScheme
  public let entry: OurneyWidgetEntry

  public init(entry: OurneyWidgetEntry) {
    self.entry = entry
  }

  public var body: some View {
    let snapshot = entry.snapshot
    let locale = snapshot?.locale ?? "vi"
    let themeMode = snapshot?.themeMode ?? "system"
    let squad = snapshot?.selectedSquad()
    let theme = OurneyWidgetTheme.resolve(
      skinId: squad?.skinId ?? "squad",
      colorVariant: squad?.colorVariant ?? 0,
      themeMode: themeMode,
      systemScheme: colorScheme
    )

    let rootDestination: URL = {
      guard let item = squad, !(snapshot?.isSignedOutOrEmpty ?? true) else {
        return OurneyDeepLinks.groups
      }
      return OurneyDeepLinks.group(id: item.journeyId)
    }()

    Group {
      if let snap = snapshot, !snap.isSignedOutOrEmpty, let item = squad {
        if family == .systemLarge {
          SquadLargeView(snapshot: snap, squad: item, theme: theme)
        } else {
          SquadMediumView(snapshot: snap, squad: item, theme: theme)
        }
      } else {
        OurneyEmptyWidgetView(
          iconName: "squad",
          title: WidgetL10n.emptySquadTitle(locale: locale),
          subtitle: WidgetL10n.emptySquadSubtitle(locale: locale),
          ctaLabel: WidgetL10n.openOurney(locale: locale),
          destination: OurneyDeepLinks.groups,
          theme: theme,
          isSmall: false
        )
      }
    }
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    .ourneyWidgetPadding()
    .ourneyWidgetContainerBackground {
      theme.bg
    }
    .widgetURL(rootDestination)
  }
}

// MARK: - Squad Medium (4x2)

private struct SquadMediumView: View {
  let snapshot: WidgetSnapshot
  let squad: WidgetSquadItem
  let theme: OurneyWidgetTheme

  var body: some View {
    let locale = snapshot.locale
    let groupURL = OurneyDeepLinks.group(id: squad.journeyId)
    let captureURL = OurneyDeepLinks.capture(journeyId: squad.journeyId)

    VStack(alignment: .leading, spacing: 8) {
      // Header: Type icon + Squad title + Checked-in counter pill
      HStack(spacing: 6) {
        OurneyIconView(name: squad.typeIcon, size: 19, ink: theme.ink)

        Text(squad.title)
          .font(OurneyWidgetFont.title(14))
          .foregroundColor(theme.ink)
          .lineLimit(1)
          .lineSpacing(2)
          .minimumScaleFactor(0.8)

        Spacer(minLength: 4)

        Text(WidgetL10n.squadCheckedInBadge(done: squad.doneCount, total: max(squad.memberCount, squad.members.count), locale: locale))
          .font(OurneyWidgetFont.body(9.5, bold: true))
          .foregroundColor(theme.onAccent)
          .padding(.horizontal, 8)
          .padding(.vertical, 3)
          .ourneyStickerCard(
            fill: theme.accent,
            outline: theme.outline,
            shadow: theme.hardShadow,
            cornerRadius: 8,
            borderWidth: 1.5,
            shadowOffset: 1.5
          )
          .ourneyWidgetAccentable()
      }

      // Middle: Couple Diptych (if isCouple) or 5-member avatar strip (+N overflow)
      if squad.isCouple && squad.members.count >= 2 {
        CoupleDiptychRow(
          members: Array(squad.members.prefix(2)),
          theme: theme
        )
      } else {
        SquadAvatarRow(
          members: squad.members,
          totalMemberCount: max(squad.memberCount, squad.members.count),
          theme: theme
        )
      }

      Spacer(minLength: 0)

      // Footer bar: Day progress on left + Snap yours / View Squad CTA on right
      HStack(spacing: 8) {
        Text(
          squad.isCouple
            ? WidgetL10n.coupleStatusText(doneCount: squad.doneCount, locale: locale)
            : WidgetL10n.dayLabel(dayNumber: squad.dayNumber, totalDays: squad.totalDays, locale: locale)
        )
        .font(OurneyWidgetFont.body(10.5, bold: true))
        .foregroundColor(theme.inkMuted)
        .lineLimit(1)
        .minimumScaleFactor(0.8)

        Spacer(minLength: 4)

        Link(destination: squad.meCheckedInToday ? groupURL : captureURL) {
          HStack(spacing: 5) {
            OurneyIconView(
              name: squad.meCheckedInToday ? "check" : "camera",
              size: 13,
              ink: squad.meCheckedInToday ? theme.ink : theme.onBrand,
              flat: true,
              overrideColor: squad.meCheckedInToday ? theme.ink : theme.onBrand
            )
            Text(squad.meCheckedInToday ? WidgetL10n.viewSquad(locale: locale) : WidgetL10n.snapYours(locale: locale))
              .font(OurneyWidgetFont.body(11, bold: true))
              .foregroundColor(squad.meCheckedInToday ? theme.ink : theme.onBrand)
              .lineLimit(1)
          }
          .padding(.horizontal, 11)
          .frame(minHeight: 32)
          .ourneyStickerCard(
            fill: squad.meCheckedInToday ? theme.surface : theme.brand,
            outline: theme.outline,
            shadow: theme.hardShadow,
            cornerRadius: 10,
            borderWidth: theme.borderWidth,
            shadowOffset: 2.0
          )
          .ourneyWidgetAccentable(!squad.meCheckedInToday)
        }
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(WidgetL10n.squadVoiceOverLabel(squad: squad, locale: locale))
  }
}

// MARK: - Squad Large (4x4 — 2x2 Polaroid Wall / Couple Mosaic)

private struct SquadLargeView: View {
  let snapshot: WidgetSnapshot
  let squad: WidgetSquadItem
  let theme: OurneyWidgetTheme

  var body: some View {
    let locale = snapshot.locale
    let groupURL = OurneyDeepLinks.group(id: squad.journeyId)
    let captureURL = OurneyDeepLinks.capture(journeyId: squad.journeyId)
    let featuredMembers = Array(squad.members.prefix(4))
    let totalCount = max(squad.memberCount, squad.members.count)

    VStack(alignment: .leading, spacing: 8) {
      // Top header
      HStack(spacing: 6) {
        OurneyIconView(name: squad.typeIcon, size: 20, ink: theme.ink)

        VStack(alignment: .leading, spacing: 1) {
          Text(squad.title)
            .font(OurneyWidgetFont.title(14.5))
            .foregroundColor(theme.ink)
            .lineLimit(1)
            .lineSpacing(2)
          Text(WidgetL10n.dayLabel(dayNumber: squad.dayNumber, totalDays: squad.totalDays, locale: locale))
            .font(OurneyWidgetFont.body(10, bold: true))
            .foregroundColor(theme.inkMuted)
        }

        Spacer()

        Text(WidgetL10n.squadCheckedInBadge(done: squad.doneCount, total: totalCount, locale: locale))
          .font(OurneyWidgetFont.body(10, bold: true))
          .foregroundColor(theme.onAccent)
          .padding(.horizontal, 9)
          .padding(.vertical, 4)
          .ourneyStickerCard(
            fill: theme.accent,
            outline: theme.outline,
            shadow: theme.hardShadow,
            cornerRadius: 9,
            borderWidth: 1.5,
            shadowOffset: 2.0
          )
          .ourneyWidgetAccentable()
      }

      // 2x2 Polaroid / Member Grid (`squadPolaroidWall` in CLAUDE.md §4)
      let topRow = Array(featuredMembers.prefix(2))
      let bottomRow = Array(featuredMembers.dropFirst(2).prefix(2))
      let forceBlurPhotos = (snapshot.privacy.photoMode == "blurred")

      VStack(spacing: 8) {
        HStack(spacing: 8) {
          ForEach(Array(topRow.enumerated()), id: \.offset) { _, member in
            SquadMemberPolaroidTile(
              member: member,
              allowsPhotos: snapshot.privacy.allowsPhotosOnHomeScreen,
              forceBlurPhotos: forceBlurPhotos,
              theme: theme
            )
          }
          if topRow.count == 1 {
            Spacer().frame(maxWidth: .infinity)
          }
        }
        if !bottomRow.isEmpty {
          HStack(spacing: 8) {
            ForEach(Array(bottomRow.enumerated()), id: \.offset) { _, member in
              SquadMemberPolaroidTile(
                member: member,
                allowsPhotos: snapshot.privacy.allowsPhotosOnHomeScreen,
                forceBlurPhotos: forceBlurPhotos,
                theme: theme
              )
            }
            if bottomRow.count == 1 {
              Spacer().frame(maxWidth: .infinity)
            }
          }
        }
      }
      .frame(maxHeight: .infinity)

      // Bottom CTA Bar
      Link(destination: squad.meCheckedInToday ? groupURL : captureURL) {
        HStack(spacing: 6) {
          OurneyIconView(
            name: squad.meCheckedInToday ? "check" : "camera",
            size: 15,
            ink: squad.meCheckedInToday ? theme.ink : theme.onBrand,
            flat: true,
            overrideColor: squad.meCheckedInToday ? theme.ink : theme.onBrand
          )
          Text(squad.meCheckedInToday ? WidgetL10n.viewSquad(locale: locale) : WidgetL10n.snapYours(locale: locale))
            .font(OurneyWidgetFont.body(12, bold: true))
            .foregroundColor(squad.meCheckedInToday ? theme.ink : theme.onBrand)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 38)
        .ourneyStickerCard(
          fill: squad.meCheckedInToday ? theme.surface : theme.brand,
          outline: theme.outline,
          shadow: theme.hardShadow,
          cornerRadius: 12,
          borderWidth: theme.borderWidth,
          shadowOffset: 2.5
        )
        .ourneyWidgetAccentable(!squad.meCheckedInToday)
      }
    }
  }
}

// MARK: - Squad Subviews

private struct SquadAvatarRow: View {
  let members: [WidgetSquadMember]
  let totalMemberCount: Int
  let theme: OurneyWidgetTheme

  var body: some View {
    let visible = Array(members.prefix(5))
    let overflow = max(0, totalMemberCount - visible.count)

    HStack(spacing: 8) {
      ForEach(Array(visible.enumerated()), id: \.offset) { _, member in
        VStack(spacing: 2) {
          OurneyAvatarDisc(
            initial: member.initial,
            colorIndex: member.avatarColorIndex,
            avatarFile: member.avatarFile,
            size: 34,
            checkedInToday: member.checkedInToday,
            theme: theme
          )
          Text(member.displayName)
            .font(OurneyWidgetFont.body(9.5, bold: member.checkedInToday))
            .foregroundColor(member.checkedInToday ? theme.ink : theme.inkMuted)
            .lineLimit(1)
            .frame(maxWidth: 46)
        }
      }

      if overflow > 0 {
        VStack(spacing: 2) {
          ZStack {
            Circle()
              .fill(theme.fill)
              .frame(width: 34, height: 34)
              .overlay(Circle().strokeBorder(theme.outline, lineWidth: 1.5))
            Text("+\(overflow)")
              .font(OurneyWidgetFont.body(11, bold: true))
              .foregroundColor(theme.ink)
          }
          Text(" ")
            .font(OurneyWidgetFont.body(9.5))
        }
      }

      Spacer(minLength: 0)
    }
  }
}

private struct CoupleDiptychRow: View {
  let members: [WidgetSquadMember]
  let theme: OurneyWidgetTheme

  var body: some View {
    HStack(spacing: 8) {
      ForEach(Array(members.enumerated()), id: \.offset) { _, member in
        HStack(spacing: 7) {
          OurneyAvatarDisc(
            initial: member.initial,
            colorIndex: member.avatarColorIndex,
            avatarFile: member.avatarFile,
            size: 32,
            checkedInToday: member.checkedInToday,
            theme: theme
          )

          VStack(alignment: .leading, spacing: 1) {
            Text(member.displayName)
              .font(OurneyWidgetFont.body(11, bold: true))
              .foregroundColor(theme.ink)
              .lineLimit(1)

            HStack(spacing: 3) {
              OurneyIconView(name: "flame", size: 12, ink: theme.ink)
              Text("\(member.streak)")
                .font(OurneyWidgetFont.display(12, weight: .bold))
                .foregroundColor(theme.ink)
            }
          }
          Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
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

private struct SquadMemberPolaroidTile: View {
  let member: WidgetSquadMember
  let allowsPhotos: Bool
  let forceBlurPhotos: Bool
  let theme: OurneyWidgetTheme

  var body: some View {
    let shouldBlur = member.todayThumbBlurred || forceBlurPhotos
    VStack(alignment: .leading, spacing: 5) {
      ZStack {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(theme.fill)

        if member.checkedInToday,
           allowsPhotos,
           let uiImage = OurneyThumbLoader.loadDownsampledImage(
             relativePath: member.todayThumbFile,
             maxPixelSize: 160,
             blur: shouldBlur
           ) {
          Image(uiImage: uiImage)
            .resizable()
            .ourneyWidgetAccentedPhoto()
            .scaledToFill()
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .privacySensitive()
        } else {
          OurneyAvatarDisc(
            initial: member.initial,
            colorIndex: member.avatarColorIndex,
            avatarFile: member.avatarFile,
            size: 36,
            checkedInToday: member.checkedInToday,
            theme: theme
          )
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

      HStack(spacing: 4) {
        Text(member.displayName)
          .font(OurneyWidgetFont.body(10.5, bold: true))
          .foregroundColor(theme.ink)
          .lineLimit(1)

        Spacer(minLength: 2)

        HStack(spacing: 2) {
          OurneyIconView(name: "flame", size: 11, ink: theme.ink)
          Text("\(member.streak)")
            .font(OurneyWidgetFont.display(11, weight: .bold))
            .foregroundColor(theme.ink)
        }
      }
    }
    .padding(7)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .ourneyStickerCard(
      fill: theme.surface,
      outline: theme.outline,
      shadow: theme.hardShadow,
      cornerRadius: 12,
      borderWidth: 1.5,
      shadowOffset: 2.0
    )
  }
}
