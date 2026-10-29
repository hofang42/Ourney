import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../ui/ui.dart';
import '../../journeys/journeys_paths.dart';
import '../data/sharing_providers.dart';
import '../l10n/generated/sharing_localizations.dart';
import '../sharing_paths.dart';
import 'sharing_widgets.dart';

/// `/follow/:journeyId` (SCR-87): what "Do this journey" copies (S15), then
/// the prefilled quick setup (`/journeys/new/<template>` with the
/// [JourneyFrame] as `extra`). The create screen calls `markFollowed`.
class FollowJourneyScreen extends ConsumerWidget {
  const FollowJourneyScreen({required this.journeyId, super.key});

  final String journeyId;

  /// Location of the prefilled create form for [frame].
  static String setupLocation(JourneyFrame frame, {bool moreOptions = false}) {
    final base = JourneysPaths.newFromTemplate(frame.templateId);
    return moreOptions ? '$base?${SharingPaths.moreOptionsParam}=1' : base;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = SharingL10n.of(context);
    if (ref.watch(appConfigProvider).localOnly) {
      return SharingPage(
        title: l10n.sharing_followTitle,
        children: const [SharingNeedsServer()],
      );
    }
    final async = ref.watch(followFrameProvider(journeyId));
    final frame = async.value;
    if (frame != null) return _FollowBody(frame: frame);
    return SharingPage(
      scaffoldKey: const ValueKey('follow-journey'),
      title: l10n.sharing_followTitle,
      children: [
        if (async.hasError)
          SharingErrorView(
            error: async.error!,
            onRetry: () => ref.invalidate(followFrameProvider(journeyId)),
          )
        else
          const SharingLoading(),
      ],
    );
  }
}

class _FollowBody extends StatelessWidget {
  const _FollowBody({required this.frame});

  final JourneyFrame frame;

  @override
  Widget build(BuildContext context) {
    final l10n = SharingL10n.of(context);
    final ui = context.ui;
    final style = uiStyleForSkin(
      personaSkinForTemplate(
        frame.templateId,
        kind: frame.kind,
        emoji: frame.emoji,
      ),
    );
    final dark = ui.brightness == Brightness.dark;
    final cardBg = dark ? ui.surface : style.paper;
    final cardInk = dark ? ui.ink : style.ink;

    Widget gets(String s) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        children: [
          Icon(Icons.check_rounded, size: 18, color: ui.success),
          const SizedBox(width: UiSpace.sm),
          Expanded(
            child: Text(s, style: UiText.body(size: 14, color: ui.ink)),
          ),
        ],
      ),
    );

    return SharingPage(
      scaffoldKey: const ValueKey('follow-journey'),
      title: l10n.sharing_followTitle,
      bottom: Builder(
        builder: (context) => Padding(
          padding: EdgeInsets.fromLTRB(
            UiSpace.gutter(MediaQuery.sizeOf(context).width),
            UiSpace.sm,
            UiSpace.gutter(MediaQuery.sizeOf(context).width),
            UiSpace.lg + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UiButton(
                key: const ValueKey('follow-start'),
                label: l10n.sharing_startThis,
                accent: style.accent,
                onAccent: style.onAccent,
                onPressed: () => context.push(
                  FollowJourneyScreen.setupLocation(frame),
                  extra: frame,
                ),
              ),
              const SizedBox(height: UiSpace.sm),
              UiButton.secondary(
                key: const ValueKey('follow-change'),
                label: l10n.sharing_changeSomething,
                onPressed: () => context.push(
                  FollowJourneyScreen.setupLocation(frame, moreOptions: true),
                  extra: frame,
                ),
              ),
            ],
          ),
        ),
      ),
      children: [
        const SizedBox(height: UiSpace.lg),
        Container(
          key: const ValueKey('follow-card'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(UiRadius.card),
            border: Border.all(color: ui.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: style.accent,
                  borderRadius: BorderRadius.circular(UiRadius.thumb),
                ),
                child: Icon(
                  uiJourneyIcon(frame.emoji, frame.templateId),
                  color: style.onAccent,
                ),
              ),
              const SizedBox(height: UiSpace.md),
              UiEyebrow(style.name.toUpperCase(), color: cardInk),
              const SizedBox(height: 4),
              Text(
                l10n.sharing_startYourOwn(style.name),
                style: UiText.h2(size: 24, color: cardInk),
              ),
              const SizedBox(height: 6),
              Text(
                frame.title,
                style: UiText.body(size: 14, color: cardInk),
              ),
              const SizedBox(height: UiSpace.md),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  UiTag(
                    label: frame.durationDays == null
                        ? l10n.sharing_openEnded
                        : l10n.sharing_days(frame.durationDays!),
                    bordered: true,
                  ),
                  UiTag(label: l10n.sharing_daily, bordered: true),
                  UiTag(
                    label: frame.metricName == null
                        ? l10n.sharing_noMetrics
                        : [
                            frame.metricName!,
                            if (frame.metricUnit != null) frame.metricUnit!,
                          ].join(' · '),
                    bordered: true,
                  ),
                ],
              ),
              if (frame.kind == JourneyKind.group) ...[
                const SizedBox(height: UiSpace.md),
                Text(
                  l10n.sharing_squadNote,
                  key: const ValueKey('follow-squad-note'),
                  style: sharingLabel(context, size: 13, color: cardInk),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: UiSpace.xxl),
        UiListHeading(title: l10n.sharing_whatYouGet),
        const SizedBox(height: 6),
        gets(l10n.sharing_sameStyle),
        gets(l10n.sharing_sameRhythm),
        gets(l10n.sharing_sameMetrics),
        const SizedBox(height: UiSpace.sm),
        Text(l10n.sharing_startFresh, style: sharingLabel(context, size: 13)),
      ],
    );
  }
}
