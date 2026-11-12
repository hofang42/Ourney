import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../ui/ui.dart';
import '../data/journeys_providers.dart';
import '../domain/journey_progress.dart';
import '../domain/journey_time.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'journey_actions.dart';
import 'journey_photo.dart';
import 'journey_style.dart';

/// Hub "Shelf" segment (V1.0 `Shelf`): finished journeys kept like albums in
/// a two-column grid, with the dashed **Retell a past journey** tile first.
class ShelfView extends StatelessWidget {
  const ShelfView({required this.journeys, required this.online, super.key});

  final List<Journey> journeys;

  /// Retelling needs the server (photo import + story).
  final bool online;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final tiles = <Widget>[
      if (online) const _RetellTile(),
      for (final j in journeys) _AlbumCard(journey: j),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          journeys.isEmpty
              ? l10n.journeys_shelfEmpty
              : l10n.journeys_shelfIntro,
          style: UiText.muted(color: ui.inkMuted),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 16.0;
            final w = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [for (final t in tiles) SizedBox(width: w, child: t)],
            );
          },
        ),
      ],
    );
  }
}

const _albumRadius = BorderRadius.only(
  topLeft: Radius.circular(4),
  bottomLeft: Radius.circular(4),
  topRight: Radius.circular(14),
  bottomRight: Radius.circular(14),
);

class _RetellTile extends StatelessWidget {
  const _RetellTile();

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final label = JourneysL10n.of(context).journeys_retell;
    return UiPressable(
      key: const ValueKey('journeys-retell'),
      onPressed: () => context.push(AppRoutes.retell),
      semanticLabel: label,
      excludeChildSemantics: true,
      borderRadius: _albumRadius,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: CustomPaint(
          foregroundPainter: _DashedRRectPainter(color: ui.chevron),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ui.fill,
              borderRadius: _albumRadius,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 28, color: ui.ink),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.body(
                    size: 14,
                    weight: FontWeight.w700,
                    height: 1.35,
                    color: ui.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlbumCard extends ConsumerWidget {
  const _AlbumCard({required this.journey});

  final Journey journey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final locale = Localizations.localeOf(context).toString();
    final checkIns = ref.watch(myCheckInsProvider(journey.id));
    final progress = checkIns.hasValue
        ? JourneyProgress.compute(
            journey: journey,
            membership: ref.watch(myMembershipProvider(journey.id)).value,
            checkIns: checkIns.value!,
            now: ref.watch(journeysNowProvider),
          )
        : null;
    final style = styleOfJourney(journey);
    final pal = JourneyPalette.of(context, style);
    final latest = progress == null ? null : latestCheckIn(progress);
    final month = DateFormat.yMMM(locale);
    final start = month.format(displayDate(journey.startDate));
    final end = journey.endDate == null
        ? null
        : month.format(displayDate(journey.endDate!));
    final range = end == null || end == start ? start : '$start – $end';
    final status = journey.status == JourneyStatus.archived
        ? l10n.journeys_statusArchived
        : l10n.journeys_statusEnded;
    final count = progress?.checkInsByDate.length;
    final band = count == null
        ? null
        : (journey.durationDays == null
              ? l10n.journeys_albumMoments(count)
              : l10n.journeys_albumDays(count, journey.durationDays!));

    return UiPressable(
      key: ValueKey('journey-card-${journey.id}'),
      onPressed: () => context.push(AppRoutes.journey(journey.id)),
      semanticLabel: [journey.title, status, ?band, range].join(', '),
      excludeChildSemantics: true,
      borderRadius: _albumRadius,
      minSize: const Size(UiSize.tap, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: _albumRadius,
                  child: latest != null
                      ? JourneyPhoto(checkIn: latest, cacheWidth: 400)
                      : ColoredBox(
                          color: pal.paper,
                          child: Icon(
                            uiJourneyIcon(journey.emoji, journey.templateId),
                            size: 40,
                            color: pal.ink,
                          ),
                        ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: _albumRadius,
                    border: Border.all(color: ui.border),
                  ),
                ),
                if (band != null)
                  Positioned(
                    top: 12,
                    left: -4,
                    right: 12,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        color: UiCamera.bg,
                        child: Text(
                          band.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.body(
                            size: 9,
                            weight: FontWeight.w700,
                            height: 1.3,
                            tracking: 0.08,
                            color: UiCamera.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (journey.origin == JourneyOrigin.imported)
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: UiTag(
                      label: l10n.journeys_imported,
                      background: UiCamera.bg,
                      foreground: UiCamera.ink,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            journey.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: UiText.body(
              size: 15,
              weight: FontWeight.w700,
              height: 1.35,
              color: ui.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            range,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: UiText.muted(size: 13, color: ui.inkMuted),
          ),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: UiText.muted(size: 12, color: ui.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(_albumRadius.toRRect(Offset.zero & size));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 6), paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) => old.color != color;
}
