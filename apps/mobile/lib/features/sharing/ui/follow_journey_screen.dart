import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/persona_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/color_utils.dart';
import '../../../shared/needs_server_view.dart';
import '../../../shared/ourney_primary_button.dart';
import '../../../shared/template_icons.dart';
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
    final appBar = AppBar(
      centerTitle: true,
      title: SharingNavTitle(title: l10n.sharing_followTitle),
    );
    if (ref.watch(appConfigProvider).localOnly) {
      return Scaffold(
        appBar: appBar,
        body: const SafeArea(child: NeedsServerView()),
      );
    }
    final async = ref.watch(followFrameProvider(journeyId));
    final frame = async.value;
    return Scaffold(
      key: const ValueKey('follow-journey'),
      appBar: appBar,
      body: SafeArea(
        top: false,
        child: frame != null
            ? _FollowBody(frame: frame)
            : async.hasError
            ? SharingErrorView(
                error: async.error!,
                onRetry: () => ref.invalidate(followFrameProvider(journeyId)),
              )
            : const SharingLoading(),
      ),
    );
  }
}

class _FollowBody extends StatelessWidget {
  const _FollowBody({required this.frame});

  final JourneyFrame frame;

  @override
  Widget build(BuildContext context) {
    final l10n = SharingL10n.of(context);
    final c = OurneyColors.of(context);
    final skin = personaSkinForTemplate(
      frame.templateId,
      kind: frame.kind,
      emoji: frame.emoji,
    );
    final brightness = Theme.of(context).brightness;
    final style = OurneyPersonaTheme.forSkin(skin, brightness);
    final dark = brightness == Brightness.dark;
    final cardBg = dark ? c.surface : style.background;
    final cardInk = dark ? c.ink : style.ink;

    Widget chip(String s) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: cardInk.withValues(alpha: 0.5)),
      ),
      child: Text(s, style: sharingLabel(context, size: 12, color: cardInk)),
    );

    Widget gets(String s) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 38),
      child: Row(
        children: [
          Icon(Icons.check_rounded, size: 18, color: c.success),
          const SizedBox(width: 8),
          Expanded(child: Text(s, style: sharingBody(context))),
        ],
      ),
    );

    return SharingColumn(
      builder: (context, gutter) => ListView(
        padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 32),
        children: [
          Container(
            key: const ValueKey('follow-card'),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border.all(color: cardInk),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: style.primaryAccent,
                    border: Border.all(color: cardInk),
                  ),
                  child: Icon(
                    journeyIcon(frame.emoji, frame.templateId),
                    color: readableOn(style.primaryAccent),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  personaStyleName(skin).toUpperCase(),
                  style: eyebrowStyle(color: cardInk),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.sharing_startYourOwn(personaStyleName(skin)),
                  style: displayStyle(
                    size: 24,
                    weight: 700,
                    height: 1.25,
                    color: cardInk,
                  ),
                ),
                const SizedBox(height: 6),
                Text(frame.title, style: sharingBody(context, color: cardInk)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    chip(
                      frame.durationDays == null
                          ? l10n.sharing_openEnded
                          : l10n.sharing_days(frame.durationDays!),
                    ),
                    chip(l10n.sharing_daily),
                    chip(
                      frame.metricName == null
                          ? l10n.sharing_noMetrics
                          : [
                              frame.metricName!,
                              if (frame.metricUnit != null) frame.metricUnit!,
                            ].join(' · '),
                    ),
                  ],
                ),
                if (frame.kind == JourneyKind.group) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.sharing_squadNote,
                    key: const ValueKey('follow-squad-note'),
                    style: sharingLabel(context, size: 13, color: cardInk),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(l10n.sharing_whatYouGet, style: headingStyle(size: 18)),
          ),
          const SizedBox(height: 6),
          gets(l10n.sharing_sameStyle),
          gets(l10n.sharing_sameRhythm),
          gets(l10n.sharing_sameMetrics),
          const SizedBox(height: 10),
          Text(l10n.sharing_startFresh, style: sharingLabel(context, size: 13)),
          const SizedBox(height: 24),
          OurneyPrimaryButton(
            key: const ValueKey('follow-start'),
            label: l10n.sharing_startThis,
            backgroundColor: c.primary,
            foregroundColor: c.onPrimary,
            onPressed: () => context.push(
              FollowJourneyScreen.setupLocation(frame),
              extra: frame,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const ValueKey('follow-change'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder(),
              foregroundColor: c.ink,
              side: BorderSide(color: c.border),
              backgroundColor: c.surface,
            ),
            onPressed: () => context.push(
              FollowJourneyScreen.setupLocation(frame, moreOptions: true),
              extra: frame,
            ),
            child: Text(
              l10n.sharing_changeSomething,
              style: sharingLabel(context, size: 15),
            ),
          ),
        ],
      ),
    );
  }
}
