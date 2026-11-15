import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../ui/ui.dart';
import '../../l10n/generated/journeys_localizations.dart';

/// True while the device has no network (Figma `store.offline`). Falls back
/// to online when connectivity cannot be read (tests, unsupported platform).
final journeyHomeOfflineProvider = StreamProvider.autoDispose<bool>((ref) {
  final c = StreamController<bool>();
  Future<void> start() async {
    try {
      final conn = Connectivity();
      c.add(
        (await conn.checkConnectivity()).every(
          (r) => r == ConnectivityResult.none,
        ),
      );
      final sub = conn.onConnectivityChanged.listen(
        (r) => c.add(r.every((x) => x == ConnectivityResult.none)),
        onError: (_) {},
      );
      ref.onDispose(sub.cancel);
    } on Object {
      c.add(false);
    }
  }

  unawaited(start());
  ref.onDispose(c.close);
  return c.stream;
});

/// The per-skin top of a Journey Home (`Quiet/Squad/Memory/Couple/Flexer/
/// MinimalJourneyHome` in routes.tsx): state chips (offline, read-only),
/// then the skin's own headline and day/streak line.
class JourneyHomeIntro extends StatelessWidget {
  const JourneyHomeIntro({
    required this.skin,
    required this.day,
    required this.streak,
    required this.now,
    this.total,
    this.offline = false,
    this.readOnly = false,
    super.key,
  });

  /// `quiet | squad | memory | couple | flexer | minimal`.
  final String skin;
  final int day;
  final int? total;
  final int streak;
  final DateTime now;
  final bool offline;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final offlineText = switch (skin) {
      'squad' => l10n.journeys_home_offlineSquad,
      'memory' || 'couple' => l10n.journeys_home_offlineMemory,
      _ => l10n.journeys_home_offlineQuiet,
    };
    final readOnlyText = switch (skin) {
      'flexer' => l10n.journeys_home_readOnlyFlexer,
      'minimal' => l10n.journeys_home_readOnlyMinimal,
      _ => l10n.journeys_home_readOnlyQuiet,
    };
    final headline = switch (skin) {
      'quiet' => l10n.journeys_home_introQuiet,
      'squad' => l10n.journeys_home_introSquad,
      'memory' => l10n.journeys_home_introMemory,
      'couple' => l10n.journeys_home_introCouple,
      _ => null,
    };
    final line = skin == 'minimal'
        ? l10n.journeys_home_monthStreak(
            streak,
            DateFormat.MMMM(locale).format(now).toUpperCase(),
          )
        : total == null
        ? l10n.journeys_home_dayStreakOpen(day, streak)
        : l10n.journeys_home_dayStreak(day, total!, streak);
    return Column(
      key: ValueKey('journey-home-intro-$skin'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (offline)
          _Chip(
            key: const ValueKey('journey-home-offline'),
            icon: 'cloud-off',
            text: offlineText,
          ),
        if (readOnly)
          _Chip(
            key: const ValueKey('journey-home-readonly'),
            icon: 'lock',
            text: readOnlyText,
          ),
        if (headline != null)
          Semantics(
            header: true,
            child: Text(
              headline,
              key: const ValueKey('journey-home-headline'),
              style: UiText.h1(color: ui.ink).copyWith(height: 1.2),
            ),
          ),
        const SizedBox(height: UiSpace.xs),
        Row(
          children: [
            Flexible(
              child: Text(
                line,
                key: const ValueKey('journey-home-line'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: UiText.muted(color: ui.inkMuted).copyWith(height: 1.4),
              ),
            ),
            if (streak > 0) ...[
              const SizedBox(width: UiSpace.xs),
              const OurneyIcon(name: 'flame', size: 17),
            ],
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text, super.key});
  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Padding(
      padding: const EdgeInsets.only(bottom: UiSpace.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: UiSpace.md,
          vertical: UiSpace.sm,
        ),
        decoration: BoxDecoration(
          color: ui.fill,
          borderRadius: BorderRadius.circular(UiRadius.capsule),
          border: Border.all(color: ui.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OurneyIcon(name: icon, size: 17, color: ui.ink),
            const SizedBox(width: UiSpace.sm),
            Flexible(
              child: Text(
                text,
                style: UiText.body(
                  size: 13,
                  weight: FontWeight.w600,
                  height: 1.4,
                  color: ui.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
