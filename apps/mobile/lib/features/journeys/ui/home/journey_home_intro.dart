import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../../ui/ui.dart';
import '../../l10n/generated/journeys_localizations.dart';

/// True while the device has no network (Figma `store.offline`). Falls back
/// to online when connectivity cannot be read (tests, unsupported platform).
final journeyHomeOfflineProvider = StreamProvider.autoDispose<bool>((ref) {
  final c = StreamController<bool>();
  // The provider may be disposed (screen left) while the platform call is
  // in flight: never add to the closed controller (B-B15).
  void emit(bool offline) {
    if (!c.isClosed) c.add(offline);
  }

  Future<void> start() async {
    try {
      final conn = Connectivity();
      final now = await conn.checkConnectivity();
      if (c.isClosed) return;
      emit(now.every((r) => r == ConnectivityResult.none));
      final sub = conn.onConnectivityChanged.listen(
        (r) => emit(r.every((x) => x == ConnectivityResult.none)),
        onError: (_) {},
      );
      ref.onDispose(sub.cancel);
    } on Object {
      emit(false);
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
    required this.today,
    this.total,
    this.offline = false,
    this.squadUploadPending = false,
    this.couple = false,
    this.readOnly = false,
    this.ritual,
    super.key,
  });

  /// `quiet | squad | memory | couple | flexer | minimal`.
  final String skin;
  final int day;
  final int? total;
  final int streak;

  /// Today in the journey's time zone (not the device clock).
  final LocalDate today;
  final bool offline;
  final bool squadUploadPending;
  final bool couple;
  final bool readOnly;

  /// Couple ritual code (`cook`, `save`, `ldr`, `custom`).
  final String? ritual;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final pendingText = couple
        ? l10n.journeys_home_offlineCouple
        : l10n.journeys_home_offlineSquad;
    final offlineText = switch (skin) {
      'squad' =>
        squadUploadPending ? pendingText : l10n.journeys_home_offline,
      'memory' || 'couple' =>
        squadUploadPending ? pendingText : l10n.journeys_home_offlineMemory,
      _ =>
        squadUploadPending ? pendingText : l10n.journeys_home_offlineQuiet,
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
      'couple' => switch (ritual) {
        'save' => l10n.journeys_home_introCoupleSave,
        'ldr' => l10n.journeys_home_introCoupleLdr,
        'custom' => l10n.journeys_home_introCoupleCustom,
        _ => l10n.journeys_home_introCouple,
      },
      _ => null,
    };
    final line = skin == 'minimal'
        ? l10n.journeys_home_monthStreak(
            streak,
            DateFormat.MMMM(locale)
                .format(DateTime(today.year, today.month, today.day))
                .toUpperCase(),
          )
        : total == null
        ? l10n.journeys_home_dayStreakOpen(day, streak)
        : l10n.journeys_home_dayStreak(day, total!, streak);
    return Column(
      key: ValueKey('journey-home-intro-$skin'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (offline || squadUploadPending)
          _Chip(
            key: const ValueKey('journey-home-offline'),
            icon: offline ? 'cloud-off' : 'clock',
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
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: Text(
                headline,
                key: const ValueKey('journey-home-headline'),
                style: UiText.h1(color: ui.ink).copyWith(height: 1.2),
              ),
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
            OurneyIcon(name: icon, size: 17, color: ui.ink, flat: true),
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
