import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/theme/app_theme.dart' show displayStyle;
import '../../app/theme/persona_theme.dart';
import '../../features/journeys/ui/journey_photo.dart';
import '../accountability_squad/persona_palette.dart';
import '../accountability_squad/persona_widgets.dart';
import 'l10n/generated/memory_collectors_localizations.dart';

/// **Task M3** (`PersonaSkinId.memoryCollectors` — `filmContactSheet`):
/// 35mm Kodak-style film contact sheet mosaic on a dark `#141312` film strip:
/// - Up to 20 frames (`maxFrames = 20`) with amber frame numbers (`01`..`20`)
///   and film sprocket holes along each row.
/// - Olive Sage (`pTheme.secondaryAccent`) `Share Trip Poster` CTA button.
/// - Enforces **FR-E3**: group journeys only ever share the poster image and
///   never expose a public link (`canShowPublicLink` is always `false` for
///   `JourneyKind.group`).
class FilmContactSheetShareCard extends StatelessWidget {
  const FilmContactSheetShareCard({
    required this.journey,
    required this.checkIns,
    this.onSharePoster,
    this.publicLinkSection,
    this.photoBuilder,
    this.shrinkWrap = false,
    this.physics,
    super.key,
  });

  final Journey journey;
  final List<CheckIn> checkIns;
  final VoidCallback? onSharePoster;

  /// Optional public-link widget; only rendered when [canShowPublicLink] is
  /// true (solo journeys only — group journeys never render it per FR-E3).
  final Widget? publicLinkSection;
  final Widget Function(BuildContext context, CheckIn checkIn)? photoBuilder;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  /// Maximum number of 35mm frames displayed on the contact sheet (`TASKS.md` M3).
  static const int maxFrames = 20;

  /// Dark film strip surface color (`#141312`, `CLAUDE.md` §2.2).
  static const Color filmSurfaceColor = PersonaPalette.filmBlack;

  /// FR-E3 guard: group journeys never expose a public link.
  bool get canShowPublicLink => journey.kind == JourneyKind.solo;

  /// Returns up to [maxFrames] check-ins ordered chronologically.
  static List<CheckIn> selectFrames(Iterable<CheckIn> all) {
    final sorted = all.toList()
      ..sort((a, b) => a.localDate.compareTo(b.localDate));
    if (sorted.length <= maxFrames) return sorted;
    return sorted.sublist(0, maxFrames);
  }

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final l10n = MemoryCollectorsL10n.of(context);
    final frames = selectFrames(checkIns);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final hPad = PersonaLayout.horizontalPadding(maxW);
        // Three frames per row, as on the reference sheet (up to 7 rows for
        // 20 frames).
        const columns = 3;

        return ListView(
          key: const ValueKey('film-contact-sheet-scroll'),
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: PersonaLayout.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      journey.title.toUpperCase(),
                      key: const ValueKey('m3-poster-title'),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: displayStyle(
                        size: 20,
                        weight: 700,
                        color: pTheme.ink,
                        height: 1.3,
                      ).copyWith(letterSpacing: 0.6),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.memory_collectors_contactSheetSubtitle(
                        frames.length,
                      ),
                      key: const ValueKey('m3-poster-subtitle'),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: pTheme.inkMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FilmContactSheetBoard(
                      frames: frames,
                      columns: columns,
                      emptyLabel: l10n.memory_collectors_emptyFilmStrip,
                      photoBuilder: photoBuilder,
                    ),
                    const SizedBox(height: 18),
                    PersonaPrimaryButton(
                      key: const ValueKey('m3-share-poster-btn'),
                      label: l10n.memory_collectors_sharePosterCta,
                      backgroundColor: pTheme.secondaryAccent,
                      foregroundColor: PersonaPalette.onAccent(
                        pTheme.secondaryAccent,
                      ),
                      onPressed: onSharePoster,
                    ),
                    // FR-E3: group journeys NEVER render public link UI.
                    if (canShowPublicLink && publicLinkSection != null) ...[
                      const SizedBox(height: 20),
                      KeyedSubtree(
                        key: const ValueKey('m3-solo-public-link'),
                        child: publicLinkSection!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilmContactSheetBoard extends StatelessWidget {
  const _FilmContactSheetBoard({
    required this.frames,
    required this.columns,
    required this.emptyLabel,
    required this.photoBuilder,
  });

  final List<CheckIn> frames;
  final int columns;
  final String emptyLabel;
  final Widget Function(BuildContext context, CheckIn checkIn)? photoBuilder;

  @override
  Widget build(BuildContext context) {
    if (frames.isEmpty) {
      return Container(
        key: const ValueKey('m3-contact-sheet-empty'),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        decoration: BoxDecoration(
          color: FilmContactSheetShareCard.filmSurfaceColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          emptyLabel,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: PersonaPalette.filmMuted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      );
    }

    final rowCount = (frames.length / columns).ceil();

    return Container(
      key: const ValueKey('m3-contact-sheet-board'),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
      decoration: const BoxDecoration(
        color: FilmContactSheetShareCard.filmSurfaceColor,
        borderRadius: BorderRadius.all(Radius.circular(3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < rowCount; r++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var c = 0; c < columns; c++) ...[
                  if (c > 0) const SizedBox(width: 6),
                  Expanded(child: _buildCell(context, index: r * columns + c)),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCell(BuildContext context, {required int index}) {
    if (index >= frames.length) {
      return const AspectRatio(aspectRatio: 1, child: SizedBox.shrink());
    }
    final checkIn = frames[index];
    final frameNumber = (index + 1).toString().padLeft(2, '0');

    final Widget imageChild = photoBuilder != null
        ? photoBuilder!(context, checkIn)
        : JourneyPhoto(checkIn: checkIn, cacheWidth: 200);

    return Column(
      key: ValueKey('m3-film-frame-$frameNumber'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1.08,
          child: ColoredBox(color: PersonaPalette.filmFrame, child: imageChild),
        ),
        // Edge number, printed in the black gutter like a real contact sheet.
        Padding(
          padding: const EdgeInsets.fromLTRB(1, 2, 0, 3),
          child: Text(
            frameNumber,
            maxLines: 1,
            textScaler: TextScaler.noScaling,
            style: const TextStyle(
              color: PersonaPalette.filmAmber,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              fontFamily: PersonaPalette.stampFontFamily,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}
