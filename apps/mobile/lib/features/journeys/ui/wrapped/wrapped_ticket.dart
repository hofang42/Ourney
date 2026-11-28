import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../../ui/ui.dart';
import '../../domain/wrapped_story.dart';
import '../../l10n/generated/journeys_localizations.dart';
import '../widgets/ticket_paper.dart';
import 'wrapped_visuals.dart';

/// The last story beat, with caller-owned endpoint photos and an optional seal.
class WrappedTicket extends StatefulWidget {
  const WrappedTicket({
    required this.journey,
    required this.skin,
    required this.stats,
    required this.blurPhotos,
    required this.onNext,
    super.key,
  });

  final Journey journey;
  final PersonaSkinId skin;
  final WrappedStats stats;
  final bool blurPhotos;
  final VoidCallback onNext;

  @override
  State<WrappedTicket> createState() => _WrappedTicketState();
}

class _WrappedTicketState extends State<WrappedTicket> {
  static const _stampDelay = Duration(milliseconds: 80);
  static const _stampDuration = UiMotion.page;

  bool _stamped = false;
  bool _settled = false;
  Timer? _settleTimer;

  void _stamp() {
    if (_stamped) return;
    final reduced = UiMotion.reduced(context);
    setState(() {
      _stamped = true;
      _settled = reduced;
    });
    if (reduced) {
      unawaited(UiHaptics.milestoneSuccess());
      return;
    }
    _settleTimer = Timer(_stampDelay + _stampDuration, () {
      setState(() => _settled = true);
      unawaited(UiHaptics.milestoneSuccess());
    });
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final font =
        UiSkinScope.maybeOf(context)?.skin.headingFont ??
        uiSkinById(uiSkinIdFor(widget.skin)).headingFont;
    final journey = widget.journey;
    final stats = widget.stats;
    final trophyValue = journey.dna?['trophy'];
    final trophy = trophyValue is String ? trophyValue.trim() : '';
    final photos = stats.photos;
    final end =
        stats.lastDay ??
        journey.endDate ??
        photos.lastOrNull?.localDate ??
        journey.startDate;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: TicketPaper(
                key: const ValueKey('wrapped-finish-ticket'),
                radius: UiRadius.input,
                seam: TicketSeam.bottom,
                shadow: widget.skin == PersonaSkinId.quietTransformer
                    ? UiShadow.tiny
                    : UiShadow.large,
                grid: widget.skin == PersonaSkinId.minimalistHabit,
                top: ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (photos.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: uiJourneyGlyph(
                              journey.emoji,
                              journey.templateId,
                              size: 56,
                            ),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(child: _photo(photos.first)),
                              if (photos.length > 1) ...[
                                const SizedBox(width: 10),
                                Flexible(child: _photo(photos.last)),
                              ],
                            ],
                          ),
                        const SizedBox(height: 12),
                        Text(
                          journey.title,
                          key: const ValueKey('wrapped-headline'),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.heading(
                            font: font,
                            size: 26,
                            height: 1.3,
                            color: ui.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                stub: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (stats.days > 0)
                      Text(
                        l10n.journeys_wrapped_finishCount(
                          stats.days,
                          stats.moments,
                        ),
                        textAlign: TextAlign.center,
                        style: UiText.body(
                          size: 15,
                          height: 1.35,
                          weight: FontWeight.w800,
                          color: ui.ink,
                        ),
                      ),
                    if (trophy.isNotEmpty)
                      Text(
                        l10n.journeys_wrapped_finishTrophy(trophy),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.body(
                          size: 14,
                          height: 1.35,
                          color: ui.inkMuted,
                        ),
                      ),
                    if (_stamped) ...[
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: UiStamp(
                          l10n.journeys_wrapped_finishStamp(
                            formatWrappedDate(end, l10n.localeName),
                          ),
                          key: const ValueKey('wrapped-finish-stamp'),
                          color: ui.accent,
                          animate: true,
                          haptics: true,
                          skinId: uiSkinIdFor(widget.skin),
                          delay: _stampDelay,
                          duration: _stampDuration,
                        ),
                      ),
                    ],
                    if (_settled) ...[
                      const SizedBox(height: 12),
                      Text(
                        l10n.journeys_wrapped_finishSlogan,
                        textAlign: TextAlign.center,
                        style: UiText.body(
                          size: 14,
                          height: 1.35,
                          color: ui.ink,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_stamped)
              UiButton(
                key: const ValueKey('wrapped-finish-next'),
                label: l10n.journeys_wrapped_finishCta,
                onPressed: widget.onNext,
              )
            else
              Semantics(
                hint: l10n.journeys_wrapped_finishStampHint,
                child: UiButton(
                  key: const ValueKey('wrapped-finish-stamp-button'),
                  label: l10n.journeys_wrapped_finishStampButton,
                  onPressed: _stamp,
                  haptic: false,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _photo(CheckIn checkIn) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final day = widget.journey.startDate.daysUntil(checkIn.localDate) + 1;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 112),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Container(
              decoration: BoxDecoration(
                color: ui.fill,
                border: Border.all(color: ui.outline),
                borderRadius: BorderRadius.circular(UiRadius.thumb),
              ),
              clipBehavior: Clip.antiAlias,
              child: WrappedPhoto(checkIn: checkIn, blur: widget.blurPhotos),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            l10n.journeys_wrapped_finishDay(day.toString().padLeft(2, '0')),
            style: UiText.eyebrow(color: ui.ink),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
