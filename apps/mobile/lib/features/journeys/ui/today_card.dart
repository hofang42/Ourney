import 'dart:async';
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../ui/ui.dart';
import '../data/journeys_providers.dart';
import '../domain/journey_progress.dart';
import '../domain/journey_time.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'journey_actions.dart';
import 'journey_photo.dart';
import 'journey_style.dart';

/// The hub's hero (V1.0 `.hub-today-card`): the next journey still waiting
/// for today's photo, drawn in its own style. Square, outlined, editorial.
class TodayCard extends ConsumerWidget {
  const TodayCard({required this.progress, super.key});

  final JourneyProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final journey = progress.journey;
    final style = styleOfJourney(journey);
    final pal = JourneyPalette.of(context, style);
    final latest = latestCheckIn(progress);
    final status = journeyDeadlineText(
      l10n,
      progress,
      ref.watch(journeysNowProvider),
    );

    TextStyle label(double size, {double opacity = 1}) => UiText.body(
      size: size,
      weight: FontWeight.w700,
      height: 1.3,
      tracking: 0.08,
      color: pal.inkAt(opacity),
    );

    return AnimatedContainer(
      key: ValueKey('journeys-today-${journey.id}'),
      duration: UiMotion.of(context, UiMotion.theme),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pal.paper,
        border: Border.all(color: pal.ink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(l10n.journeys_todayLabel.toUpperCase(), style: label(10)),
              const Spacer(),
              Flexible(
                child: Text(
                  style.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: label(10, opacity: 0.72),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Container(
            height: 148,
            decoration: BoxDecoration(
              color: UiCamera.bg,
              border: Border.all(color: pal.ink),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (latest != null)
                  JourneyPhoto(checkIn: latest, thumbnail: false)
                else
                  ColoredBox(
                    color: pal.accent.withValues(alpha: 0.32),
                    child: Icon(
                      uiJourneyIcon(journey.emoji, journey.templateId),
                      size: 44,
                      color: UiCamera.ink.withValues(alpha: 0.85),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.45, 1],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          journey.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.display(
                            size: 20,
                            height: 1.25,
                            color: UiCamera.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        journeyDayShort(l10n, progress),
                        style: UiText.body(
                          size: 12,
                          weight: FontWeight.w700,
                          height: 1.3,
                          color: UiCamera.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(minHeight: 42),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: pal.inkAt(0.28))),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 17,
                  color: ui.flame,
                ),
                const SizedBox(width: 5),
                Text(
                  '${progress.summary.current}',
                  style: UiText.body(
                    size: 12,
                    weight: FontWeight.w700,
                    height: 1.3,
                    color: pal.ink,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    l10n.journeys_streakWord,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.body(
                      size: 10,
                      weight: FontWeight.w600,
                      height: 1.3,
                      color: pal.inkAt(0.72),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded, size: 15, color: ui.warn),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.body(
                            size: 12,
                            weight: FontWeight.w600,
                            height: 1.3,
                            color: ui.warn,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          WeekStrip(progress: progress, pal: pal),
          UiButton(
            key: const ValueKey('journeys-snap-today'),
            label: l10n.journeys_snapToday,
            icon: Icons.photo_camera_outlined,
            accent: pal.accent,
            onAccent: pal.onAccent,
            onPressed: () {
              unawaited(
                ref.read(activeJourneyIdProvider.notifier).select(journey.id),
              );
              unawaited(checkInNow(context, ref, journey.id));
            },
          ),
        ],
      ),
    );
  }
}

/// The last seven days of a journey, oldest first, today last (V1.0
/// `.hero-week`): photo cells with a check badge, a dashed camera cell for
/// today, hairline cells for missed days and nothing before the start.
class WeekStrip extends StatelessWidget {
  const WeekStrip({required this.progress, required this.pal, super.key});

  final JourneyProgress progress;
  final JourneyPalette pal;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = progress.today;
    final weekday = DateFormat.E(locale);
    return Semantics(
      label: l10n.journeys_lastSevenDays,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 11, 0, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 6; i >= 0; i--) ...[
              Expanded(
                child: _DayCell(
                  date: today.addDays(-i),
                  isToday: i == 0,
                  label: i == 0
                      ? l10n.journeys_todayLabel
                      : weekday.format(displayDate(today.addDays(-i))),
                  checkIn: progress.checkInsByDate[today.addDays(-i)],
                  beforeStart: today.addDays(-i).isBefore(progress.memberStart),
                  pal: pal,
                ),
              ),
              if (i > 0) const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isToday,
    required this.label,
    required this.checkIn,
    required this.beforeStart,
    required this.pal,
  });

  final LocalDate date;
  final bool isToday;
  final String label;
  final CheckIn? checkIn;
  final bool beforeStart;
  final JourneyPalette pal;

  @override
  Widget build(BuildContext context) {
    final ink = pal.ink;
    final Widget cell;
    if (checkIn != null) {
      cell = Container(
        decoration: BoxDecoration(border: Border.all(color: ink)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            JourneyPhoto(checkIn: checkIn!, cacheWidth: 120),
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                width: 12,
                height: 12,
                color: ink,
                child: Icon(Icons.check_rounded, size: 9, color: pal.paper),
              ),
            ),
          ],
        ),
      );
    } else if (isToday) {
      cell = CustomPaint(
        painter: _DashedBorderPainter(color: ink),
        child: Center(
          child: Icon(Icons.photo_camera_outlined, size: 14, color: ink),
        ),
      );
    } else if (beforeStart) {
      cell = const SizedBox.shrink();
    } else {
      cell = DecoratedBox(
        decoration: BoxDecoration(border: Border.all(color: pal.inkAt(0.35))),
      );
    }
    return ExcludeSemantics(
      child: Column(
        children: [
          SizedBox(
            height: 20,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: UiText.body(
                  size: 8,
                  weight: FontWeight.w700,
                  height: 1.2,
                  color: isToday ? ink : pal.inkAt(0.72),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          AspectRatio(aspectRatio: 1, child: cell),
          const SizedBox(height: 4),
          Text(
            '${date.day}',
            style: UiText.body(
              size: 9,
              weight: FontWeight.w700,
              height: 1.2,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRect(Offset.zero & size);
    for (final PathMetric m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 3), paint);
        d += 5;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
