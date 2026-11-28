import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../../ui/ui.dart';
import '../../domain/wrapped_story.dart';
import '../../l10n/generated/journeys_localizations.dart';
import '../widgets/ticket_paper.dart';
import 'wrapped_roll.dart';
import 'wrapped_ticket.dart';
import 'wrapped_visuals.dart';

/// A beat owns its content semantics; controls remain separately focusable.
class WrappedBeatView extends StatefulWidget {
  const WrappedBeatView({
    required this.journey,
    required this.skin,
    required this.stats,
    required this.beat,
    required this.blurPhotos,
    required this.paused,
    required this.onShowPhotos,
    required this.onNext,
    super.key,
  });
  final Journey journey;
  final PersonaSkinId skin;
  final WrappedStats stats;
  final WrappedBeat beat;
  final bool blurPhotos;
  final bool paused;
  final VoidCallback onShowPhotos;
  final VoidCallback onNext;
  @override
  State<WrappedBeatView> createState() => _WrappedBeatViewState();
}

class _WrappedBeatViewState extends State<WrappedBeatView> {
  bool _showKg = false;
  @override
  Widget build(BuildContext context) {
    final w = widget;
    final beat = w.beat;
    final stats = w.stats;
    final ui = context.ui;
    final l = JourneysL10n.of(context);
    final heading = UiText.heading(
      font: UiSkinScope.of(context).headingFont,
      size: w.skin == PersonaSkinId.aestheticFlexer ? 36 : 28,
      color: ui.ink,
      height: 1.35,
    );
    Widget text(
      String value, {
      TextStyle? style,
      int lines = 4,
      TextAlign align = TextAlign.center,
      Key? key,
    }) => Text(
      value,
      key: key,
      textAlign: align,
      maxLines: lines,
      overflow: TextOverflow.ellipsis,
      style: style ?? UiText.body(color: ui.ink, height: 1.4),
    );
    Widget photos(List<CheckIn> list) => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final photo in list)
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: WrappedPhoto(
                      checkIn: photo,
                      blur: w.blurPhotos,
                      cacheWidth: 900,
                      thumbnail: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    Widget visual;
    switch (beat.id) {
      case 'open':
        visual = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: TicketPaper(
            radius: 18,
            seam: TicketSeam.bottom,
            stub: beat.sub == null ? null : text(beat.sub!, lines: 6),
            top: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  uiJourneyGlyph(
                    w.journey.emoji,
                    w.journey.templateId,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  text(
                    beat.headline,
                    style: heading.copyWith(fontSize: 34),
                    lines: 3,
                    key: const ValueKey('wrapped-headline'),
                  ),
                ],
              ),
            ),
          ),
        );
      case 'first':
        final first = photos(
          stats.photos.length <= 3 ? stats.photos : [stats.photos.first],
        );
        visual = WrappedRollPrecache(
          stats: stats,
          child: UiMotion.reduced(context)
              ? first
              : _FirstZoom(
                  key: const ValueKey('wrapped-first-zoom'),
                  duration: beat.duration!,
                  paused: w.paused,
                  child: first,
                ),
        );
      case 'roll':
        visual = WrappedRoll(
          stats: stats,
          blurPhotos: w.blurPhotos,
          paused: w.paused,
        );
      case 'note':
        final note = stats.noteCaption;
        visual = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ui.surface,
            border: Border.all(color: ui.outline, width: 1.5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note != null)
                SizedBox(
                  width: 72,
                  height: 96,
                  child: WrappedPhoto(
                    checkIn: note.checkIn,
                    blur: w.blurPhotos,
                    cacheWidth: 160,
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: text(
                  beat.headline,
                  style: UiText.body(size: 20, color: ui.ink, height: 1.4),
                  lines: 12,
                  align: TextAlign.left,
                  key: const ValueKey('wrapped-headline'),
                ),
              ),
            ],
          ),
        );
      case 'finish':
        visual = WrappedTicket(
          journey: w.journey,
          skin: w.skin,
          stats: stats,
          blurPhotos: w.blurPhotos,
          onNext: w.onNext,
        );
      default:
        visual = switch (beat.signatureKind) {
          WrappedSignatureKind.weight => WrappedCurve(
            values: stats.weightsDownsampled,
            smooth: true,
            paused: w.paused,
          ),
          WrappedSignatureKind.minutes => WrappedBars(
            values: stats.minutesPerDay,
            paused: w.paused,
          ),
          WrappedSignatureKind.run => WrappedBars(
            values: stats.kmPerDay,
            paused: w.paused,
          ),
          WrappedSignatureKind.habit => WrappedChain(
            paused: w.paused,
            days: stats.chainDays,
            start: stats.memberStart,
          ),
          WrappedSignatureKind.places => _Places(places: stats.placesInOrder),
          WrappedSignatureKind.couple => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OurneyIcon(name: 'heart', size: 48),
              const SizedBox(height: 16),
              for (final dates in [
                stats.coupleSelfDays,
                stats.couplePartnerDays,
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final date in {
                        ...stats.coupleSelfDays,
                        ...stats.couplePartnerDays,
                      }.toList()..sort())
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dates.contains(date) ? ui.accent : ui.fill,
                            border: Border.all(color: ui.outline),
                          ),
                        ),
                    ],
                  ),
                ),
              if (stats.coupleSlots.any(
                (slot) => !slot.isMine && slot.checkIn != null,
              )) ...[
                const SizedBox(height: 12),
                WrappedVisual(
                  skin: PersonaSkinId.coupleRituals,
                  stats: stats,
                  page: 3,
                  blurPhotos: w.blurPhotos,
                ),
              ],
            ],
          ),
          WrappedSignatureKind.mood => const OurneyIcon(
            name: 'weight',
            size: 80,
          ),
          _ => uiJourneyGlyph(w.journey.emoji, w.journey.templateId, size: 80),
        };
    }
    final showPhotos =
        w.blurPhotos &&
        stats.photos.isNotEmpty &&
        ['first', 'roll', 'note', 'finish'].contains(beat.id);
    final extra =
        _showKg &&
            beat.signatureKind == WrappedSignatureKind.weight &&
            stats.weights.isNotEmpty
        ? _weightCopy(l)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: [beat.semanticsLabel, ?extra].join('. '),
            container: true,
            child: ExcludeSemantics(
              child: Column(
                children: [
                  if (beat.id != 'finish')
                    MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(disableAnimations: UiMotion.reduced(context)),
                      child: RepaintBoundary(child: visual),
                    ),
                  if (beat.id != 'open' &&
                      beat.id != 'note' &&
                      beat.id != 'finish') ...[
                    const SizedBox(height: 24),
                    text(
                      beat.headline,
                      style: heading,
                      key: const ValueKey('wrapped-headline'),
                    ),
                    if (beat.sub != null) ...[
                      const SizedBox(height: 12),
                      text(beat.sub!, lines: 8),
                    ],
                  ],
                  if (extra != null) ...[
                    const SizedBox(height: 12),
                    text(extra),
                  ],
                ],
              ),
            ),
          ),
          if (beat.id == 'finish') visual,
          if (beat.signatureKind == WrappedSignatureKind.weight && !_showKg)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: UiChip(
                key: const ValueKey('wrapped-show-kg'),
                label: l.journeys_wrapped_showKg,
                onPressed: () => setState(() => _showKg = true),
              ),
            ),
          if (showPhotos)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: UiChip(
                key: const ValueKey('wrapped-show-photos'),
                label: l.journeys_wrapped_showPhotos,
                onPressed: w.onShowPhotos,
              ),
            ),
        ],
      ),
    );
  }

  String _weightCopy(JourneysL10n l) {
    final values = widget.stats.weights;
    final n = NumberFormat('0.#', l.localeName);
    final unit = widget.journey.metricUnit ?? 'kg';
    if (widget.journey.dna?['goal'] == 'lose' && values.last < values.first) {
      return l.journeys_wrapped_sigQuietWeightLess(
        '${n.format(values.first - values.last)} $unit',
      );
    }
    return l.journeys_wrapped_sigQuietRange(
      '${n.format(values.first)} $unit',
      '${n.format(values.last)} $unit',
    );
  }
}

class _Places extends StatelessWidget {
  const _Places({required this.places});
  final List<String> places;
  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return CustomPaint(
      painter: _Stitch(ui.outline),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 16,
          children: [
            for (final place in places.take(6))
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: ui.surface,
                    border: Border.all(color: ui.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    place,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.body(color: ui.ink, height: 1.4),
                  ),
                ),
              ),
            if (places.length > 6)
              Text(
                JourneysL10n.of(context)
                    .journeys_wrapped_rollMore(places.length - 6),
                style: UiText.body(color: ui.ink),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stitch extends CustomPainter {
  const _Stitch(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(math.min(x + 5, size.width), size.height / 2),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_Stitch old) => old.color != color;
}

/// Preserve zoom progress while a story is paused or held.
class _FirstZoom extends StatefulWidget {
  const _FirstZoom({
    required this.duration,
    required this.paused,
    required this.child,
    super.key,
  });
  final Duration duration;
  final bool paused;
  final Widget child;
  @override
  State<_FirstZoom> createState() => _FirstZoomState();
}

class _FirstZoomState extends State<_FirstZoom>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  @override
  void initState() {
    super.initState();
    if (!widget.paused) _controller.forward();
  }

  @override
  void didUpdateWidget(_FirstZoom oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paused) {
      _controller.stop();
    } else if (!_controller.isCompleted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) => Transform.scale(
      scale: 1 + .04 * UiCurves.easeOutStrong.transform(_controller.value),
      child: child,
    ),
  );
}
