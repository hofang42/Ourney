import 'package:flutter/material.dart';

import '../app/theme/persona_theme.dart';
import '../features/journeys/ui/timeline_grid.dart';
import '../shared/layout.dart';
import '../shared/persona_pill.dart';
import '../shared/template_icons.dart';
import 'persona_contract.dart';

/// Temporary layouts of the personas that are not designed yet (task F1).
///
/// They render real data in the persona's colors so the whole app can switch
/// persona today. Each persona folder wraps these with its own strings and
/// the owner replaces the wrapper with the final layout.

/// Day grid under a [PersonaPill]: the existing `TimelineGrid`.
class PlaceholderTimeline extends StatelessWidget {
  const PlaceholderTimeline({
    required this.data,
    required this.styleName,
    required this.dayLabel,
    super.key,
  });

  final PersonaTimelineData data;
  final String styleName;
  final String dayLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: PersonaPill(label: '$styleName · $dayLabel'),
        ),
        const SizedBox(height: 12),
        TimelineGrid(days: data.days, onTapDay: data.onTapDay ?? (_) {}),
      ],
    );
  }
}

/// [PersonaCameraData.viewfinder] with a label pill over its top edge.
class PlaceholderHud extends StatelessWidget {
  const PlaceholderHud({required this.data, required this.label, super.key});

  final PersonaCameraData data;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        data.viewfinder,
        Positioned(
          top: 12,
          left: 72,
          right: 72,
          child: IgnorePointer(
            child: Center(child: PersonaPill(label: label)),
          ),
        ),
      ],
    );
  }
}

/// Card with the journey title and a few facts.
class PlaceholderShareBoard extends StatelessWidget {
  const PlaceholderShareBoard({
    required this.data,
    required this.styleName,
    required this.facts,
    super.key,
  });

  final PersonaShareData data;
  final String styleName;
  final List<String> facts;

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return Container(
          padding: EdgeInsets.all(OurneyLayout.cardPadding(width)),
          decoration: BoxDecoration(
            color: pTheme.surface,
            borderRadius: BorderRadius.circular(pTheme.cardRadius),
            border: Border.all(color: pTheme.border, width: pTheme.borderWidth),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PersonaPill(label: styleName),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    templateIcon(data.journey.templateId),
                    color: pTheme.ink,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.journey.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: pTheme.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  for (final fact in facts)
                    Text(
                      fact,
                      style: TextStyle(
                        color: pTheme.inkMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
