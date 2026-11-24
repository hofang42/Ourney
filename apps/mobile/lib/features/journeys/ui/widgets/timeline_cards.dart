import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';
import '../../domain/timeline_window.dart';
import '../../l10n/generated/journeys_localizations.dart';
import 'timeline_common.dart';

/// Spoken / written text of the "Earlier" link of a window.
String earlierText(BuildContext context, TimelineWindow w) => JourneysL10n.of(
  context,
).journeys_earlierLink(w.earlierDays, w.earlierChecked);

/// "Earlier: days 1-199, 182 checked in. View": opens the By month archive
/// at the month just before the Recent window.
class TimelineEarlierLink extends StatelessWidget {
  const TimelineEarlierLink({
    required this.window,
    required this.onPressed,
    super.key,
  });

  final TimelineWindow window;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    final text = earlierText(context, window);
    return Padding(
      key: const ValueKey('timeline-earlier'),
      padding: const EdgeInsets.only(bottom: UiSpace.lg, right: UiShadow.small),
      child: UiPressable(
        onPressed: onPressed,
        semanticLabel: '$text. ${l10n.journeys_earlierView}',
        excludeChildSemantics: true,
        shadowOffset: UiShadow.small,
        borderRadius: BorderRadius.circular(UiRadius.input),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: UiSpace.md,
            vertical: UiSpace.sm,
          ),
          decoration: BoxDecoration(
            color: ui.surface,
            borderRadius: BorderRadius.circular(UiRadius.input),
            border: ui.stickerBorder(UiBorder.thin),
          ),
          child: Row(
            children: [
              const OurneyIcon(name: 'calendar', size: 22),
              const SizedBox(width: UiSpace.md),
              Expanded(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.body(
                    size: 13,
                    weight: FontWeight.w600,
                    height: 1.4,
                    color: ui.ink,
                  ),
                ),
              ),
              const SizedBox(width: UiSpace.sm),
              Text(
                l10n.journeys_earlierView,
                maxLines: 1,
                style: UiText.body(
                  size: 13,
                  weight: FontWeight.w800,
                  height: 1.4,
                  color: timelineAccent(context),
                ),
              ),
              OurneyIcon(
                name: 'chevron-right',
                size: 18,
                flat: true,
                color: ui.ink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Finish card under the window of a fixed-term journey.
class TimelineEndCap extends StatelessWidget {
  const TimelineEndCap({required this.window, super.key});

  final TimelineWindow window;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    final text = window.startsIn != null
        ? l10n.journeys_startsIn(window.startsIn!, window.finishDay ?? 0)
        : l10n.journeys_daysToGo(window.daysToGo ?? 0, window.finishDay ?? 0);
    return Padding(
      padding: const EdgeInsets.only(top: UiSpace.lg),
      child: Semantics(
        key: const ValueKey('timeline-end-cap'),
        label: text,
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.all(UiSpace.md),
          decoration: BoxDecoration(
            color: ui.surface,
            borderRadius: BorderRadius.circular(UiRadius.input),
            border: ui.stickerBorder(UiBorder.thin),
          ),
          child: Row(
            children: [
              const OurneyIcon(name: 'trophy', size: 28),
              const SizedBox(width: UiSpace.md),
              Expanded(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.body(
                    size: 14,
                    weight: FontWeight.w700,
                    height: 1.4,
                    color: ui.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// First stone of the squad path in the Recent window: stands for every
/// earlier day ("1-199") and opens the archive.
class TimelineSectionStone extends StatelessWidget {
  const TimelineSectionStone({
    required this.window,
    required this.size,
    required this.onPressed,
    super.key,
  });

  final TimelineWindow window;
  final double size;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final accent = timelineAccent(context);
    final l10n = JourneysL10n.of(context);
    final text = earlierText(context, window);
    return Semantics(
      key: const ValueKey('timeline-section-stone'),
      button: onPressed != null,
      label: '$text. ${l10n.journeys_earlierView}',
      onTap: onPressed,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.2),
            border: Border.all(color: ui.outline, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OurneyIcon(name: 'flag', size: 20),
              TimelineNumber('1–${window.earlierDays}', size: 10, mono: true),
            ],
          ),
        ),
      ),
    );
  }
}