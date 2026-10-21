import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/theme/app_theme.dart' show displayStyle;
import '../../app/theme/persona_theme.dart';
import '../../features/journeys/ui/journey_photo.dart';
import '../../shared/dashed_placeholder.dart';
import '../../shared/layout.dart';
import '../../shared/ourney_primary_button.dart';
import '../../shared/persona_pill.dart';
import '../persona_contract.dart';
import 'l10n/generated/couple_rituals_localizations.dart';

/// **Task D4** (`PersonaSkinId.coupleRituals` — `coupleMosaicPoster`):
/// Woven couple mosaic poster showing `{days} DAYS · {moments} MOMENTS` with a
/// Rose Coral (`pTheme.primaryAccent`) `Share Our Story` CTA button.
///
/// Enforces **FR-E3**: group / couple journeys never expose a public link
/// (`canShowPublicLink` is always `false`).
class CoupleMosaicPosterShareCard extends StatelessWidget {
  const CoupleMosaicPosterShareCard({required this.data, super.key});

  final PersonaShareData data;

  /// Maximum number of woven tiles displayed in the mosaic grid.
  static const int maxTiles = 12;

  /// FR-E3: couple/group journeys never expose a public link on the share card.
  bool get canShowPublicLink => false;

  /// Interleaves the caller's check-ins and the partner's check-ins in
  /// chronological order so both partners' moments appear side-by-side.
  static List<CheckIn> weaveMoments(
    List<CheckIn> mine,
    List<CheckIn> partner,
  ) {
    final woven = <CheckIn>[...mine, ...partner]
      ..sort((a, b) {
        final cmp = a.localDate.compareTo(b.localDate);
        if (cmp != 0) return cmp;
        return a.capturedAt.compareTo(b.capturedAt);
      });
    if (woven.length <= maxTiles) return woven;
    return woven.sublist(woven.length - maxTiles);
  }

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final l10n = CoupleRitualsL10n.of(context);
    final moments = weaveMoments(data.checkIns, data.partnerCheckIns);
    final totalMoments = data.checkIns.length + data.partnerCheckIns.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final maxW = OurneyLayout.contentMaxWidth(width);
        final pad = OurneyLayout.cardPadding(width);
        const columns = 3;

        final card = Container(
          key: const ValueKey('d4-couple-mosaic-card'),
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: pTheme.surface,
            borderRadius: BorderRadius.circular(pTheme.cardRadius),
            border: Border.all(
              color: pTheme.border,
              width: pTheme.borderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PersonaPill(
                    key: const ValueKey('d4-style-pill'),
                    icon: Icons.favorite_rounded,
                    label: l10n.couple_rituals_name,
                  ),
                  PersonaPill(
                    key: const ValueKey('d4-streak-pill'),
                    icon: Icons.local_fire_department_rounded,
                    label: l10n.couple_rituals_streakLabel(data.currentStreak),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.couple_rituals_mosaicTitle(data.dayNumber, totalMoments),
                key: const ValueKey('d4-mosaic-headline'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: displayStyle(
                  size: 19,
                  weight: 800,
                  color: pTheme.ink,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.journey.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: pTheme.inkMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              if (moments.isEmpty)
                SizedBox(
                  height: 120,
                  child: DashedPlaceholder(
                    key: const ValueKey('d4-mosaic-empty'),
                    icon: Icons.favorite_border_rounded,
                    label: l10n.couple_rituals_checkInsLabel(0),
                  ),
                )
              else
                _WovenMosaicGrid(
                  moments: moments,
                  columns: columns,
                  pTheme: pTheme,
                  photoBuilder: data.photoBuilder,
                ),
              const SizedBox(height: 16),
              OurneyPrimaryButton(
                key: const ValueKey('d4-share-story-btn'),
                label: l10n.couple_rituals_shareStoryButton,
                icon: Icons.favorite_rounded,
                backgroundColor: pTheme.primaryAccent,
                onPressed: data.onShare,
              ),
            ],
          ),
        );

        final constrained = Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: card,
          ),
        );

        if (data.shrinkWrap) return constrained;
        return SingleChildScrollView(
          physics: data.physics,
          child: constrained,
        );
      },
    );
  }
}

class _WovenMosaicGrid extends StatelessWidget {
  const _WovenMosaicGrid({
    required this.moments,
    required this.columns,
    required this.pTheme,
    required this.photoBuilder,
  });

  final List<CheckIn> moments;
  final int columns;
  final OurneyPersonaTheme pTheme;
  final PersonaCheckInPhotoBuilder? photoBuilder;

  @override
  Widget build(BuildContext context) {
    final rowCount = (moments.length / columns).ceil();
    return Column(
      key: const ValueKey('d4-mosaic-grid'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rowCount; r++) ...[
          if (r > 0) const SizedBox(height: 8),
          Row(
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) const SizedBox(width: 8),
                Expanded(
                  child: _buildCell(context, r * columns + c),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCell(BuildContext context, int index) {
    if (index >= moments.length) {
      return const AspectRatio(aspectRatio: 1, child: SizedBox.shrink());
    }
    final checkIn = moments[index];
    final child = photoBuilder != null
        ? photoBuilder!(context, checkIn)
        : JourneyPhoto(checkIn: checkIn, thumbnail: true);
    return AspectRatio(
      key: ValueKey('d4-mosaic-tile-$index'),
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}
