import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/theme/app_theme.dart' show displayStyle;
import '../../app/theme/persona_theme.dart';
import '../../features/journeys/domain/journey_progress.dart';
import '../../features/journeys/ui/journey_photo.dart';
import '../accountability_squad/persona_palette.dart';
import '../accountability_squad/persona_widgets.dart';
import '../accountability_squad/winding_path_painter.dart';
import 'l10n/generated/memory_collectors_localizations.dart';

/// **Task M1** (`PersonaSkinId.memoryCollectors` — `scrapbookThread`):
/// Continuous terracotta stitched thread running vertically down the page,
/// connecting tilted Polaroid photo cards with masking-tape strips at top.
///
/// Reuses [WindingPathPainter] with [WindingPathStyle.stitchedThread] from S1
/// (`docs/TASKS.md` §2 & §3). Uses `CustomScrollView` + `SliverList.builder` so
/// 30+ days scroll smoothly.
class ScrapbookThreadTimeline extends StatelessWidget {
  const ScrapbookThreadTimeline({
    required this.journey,
    required this.days,
    this.onTapDay,
    this.photoBuilder,
    this.shrinkWrap = false,
    this.physics,
    super.key,
  });

  final Journey journey;
  final List<TimelineDay> days;
  final ValueChanged<TimelineDay>? onTapDay;
  final Widget Function(BuildContext context, TimelineDay day)? photoBuilder;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  /// Filters days shown on the scrapbook thread: all past/today days plus Day 1
  /// and end day if the journey is still in the future.
  static List<TimelineDay> visibleScrapbookDays(List<TimelineDay> allDays) {
    if (allDays.isEmpty) return const [];
    final nonFuture = [
      for (final d in allDays)
        if (d.state != DayState.future) d,
    ];
    return nonFuture.isEmpty ? [allDays.first] : nonFuture;
  }

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final l10n = MemoryCollectorsL10n.of(context);
    final items = visibleScrapbookDays(days);

    final titleUpper = journey.title.toUpperCase();
    final headerText = journey.durationDays != null
        ? l10n.memory_collectors_daysHeader(titleUpper, journey.durationDays!)
        : l10n.memory_collectors_openHeader(titleUpper);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final hPad = PersonaLayout.horizontalPadding(width);

        return Stack(
          children: [
            // Faint linen weave: the scrapbook page is paper, not a flat fill.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _LinenPainter(pTheme.ink.withValues(alpha: 0.022)),
                ),
              ),
            ),
            CustomScrollView(
              key: const ValueKey('scrapbook-thread-scroll'),
              shrinkWrap: shrinkWrap,
              physics: physics,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 12),
                        child: Text(
                          headerText,
                          key: const ValueKey('m1-scrapbook-header'),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: displayStyle(
                            size: 16,
                            weight: 600,
                            color: pTheme.ink,
                            height: 1.35,
                          ).copyWith(letterSpacing: 0.4),
                        ),
                      ),
                      Divider(
                        color: pTheme.inkMuted.withValues(alpha: 0.3),
                        thickness: 1,
                        height: 1,
                      ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 28),
                  sliver: SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final day = items[index];
                      return _ScrapbookSegment(
                        key: ValueKey('m1-node-day-${day.dayNumber}'),
                        day: day,
                        isLeft: index.isEven,
                        hasPrev: index > 0,
                        hasNext: index < items.length - 1,
                        l10n: l10n,
                        pTheme: pTheme,
                        onTap: onTapDay == null ? null : () => onTapDay!(day),
                        photoBuilder: photoBuilder,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Subtle woven-paper texture behind the scrapbook page.
class _LinenPainter extends CustomPainter {
  const _LinenPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var y = 0.0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (var x = 0.0; x < size.width; x += 3) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_LinenPainter oldDelegate) => oldDelegate.color != color;
}

class _ScrapbookSegment extends StatelessWidget {
  const _ScrapbookSegment({
    required this.day,
    required this.isLeft,
    required this.hasPrev,
    required this.hasNext,
    required this.l10n,
    required this.pTheme,
    required this.onTap,
    required this.photoBuilder,
    super.key,
  });

  final TimelineDay day;
  final bool isLeft;
  final bool hasPrev;
  final bool hasNext;
  final MemoryCollectorsL10n l10n;
  final OurneyPersonaTheme pTheme;
  final VoidCallback? onTap;
  final Widget Function(BuildContext context, TimelineDay day)? photoBuilder;

  String _captionFor(TimelineDay d) {
    final dayStr = d.dayNumber.toString().padLeft(2, '0');
    final rawCaption = d.checkIn?.caption?.trim();
    if (rawCaption != null && rawCaption.isNotEmpty) {
      return l10n.memory_collectors_dayCaption(
        dayStr,
        rawCaption.toUpperCase(),
      );
    }
    if (d.isToday) {
      return l10n.memory_collectors_dayToday(dayStr);
    }
    return l10n.memory_collectors_dayNumber(dayStr);
  }

  @override
  Widget build(BuildContext context) {
    final caption = _captionFor(day);
    final tilt = isLeft ? -0.055 : 0.05;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.clamp(
          240.0,
          PersonaLayout.maxContentWidth,
        );
        final cardWidth = (maxW * 0.44).clamp(120.0, 190.0);
        // Left and right Polaroids interleave: each overlaps its neighbour's
        // slot vertically, like photos pinned along one string.
        final segmentHeight = cardWidth * 0.78 + 20.0;
        final nodeY = segmentHeight * 0.34;

        // The thread meanders around the page centre and is tied to the inner
        // edge of whichever photo it passes.
        double nodeX(bool left) => left ? maxW * 0.46 : maxW * 0.54;
        final prevNode = Offset(
          hasPrev ? nodeX(!isLeft) : maxW * 0.5,
          hasPrev ? nodeY - segmentHeight : 0,
        );
        final node = Offset(nodeX(isLeft), nodeY);
        final nextNode = Offset(
          hasNext ? nodeX(!isLeft) : maxW * 0.5,
          hasNext ? nodeY + segmentHeight : segmentHeight,
        );
        final tieDx = isLeft
            ? (cardWidth - node.dx) + 6
            : ((maxW - cardWidth) - node.dx) - 6;

        final Widget photoChild;
        if (photoBuilder != null) {
          photoChild = photoBuilder!(context, day);
        } else if (day.checkIn != null) {
          photoChild = JourneyPhoto(checkIn: day.checkIn!, cacheWidth: 280);
        } else {
          photoChild = ColoredBox(
            color: pTheme.surfaceElevated,
            child: Center(
              child: Icon(
                day.isToday
                    ? Icons.photo_camera_outlined
                    : Icons.landscape_outlined,
                color: pTheme.inkMuted,
                size: 28,
              ),
            ),
          );
        }

        final polaroid = SizedBox(
          width: cardWidth,
          child: SquadPolaroidFrame(
            photo: photoChild,
            caption: caption,
            tiltRadians: tilt,
            showMaskingTape: true,
            tapeShift: isLeft ? -0.4 : 0.4,
            photoAspectRatio: 0.95,
            highlighted: day.isToday,
            onTap: onTap,
          ),
        );

        return Center(
          child: SizedBox(
            width: maxW,
            height: segmentHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: WindingPathPainter(
                      waypoints: [prevNode, node, nextNode],
                      activeIndex: 2,
                      style: WindingPathStyle.stitchedThread,
                      activeColor: pTheme.primaryAccent,
                      inactiveColor: pTheme.primaryAccent,
                      outlineColor: pTheme.border,
                      knotTieDx: tieDx,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: isLeft ? 0 : null,
                  right: isLeft ? null : 0,
                  child: polaroid,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
