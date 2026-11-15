import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../ui/ui.dart';

/// Which reminder the in-app banner shows (V2 `banner.kind`).
enum ReminderBannerKind { daily, streak }

/// Content of one in-app reminder banner (V2 `store.reminderBanner`).
@immutable
class ReminderBannerData {
  const ReminderBannerData({
    required this.journeyId,
    required this.journeyName,
    required this.skinId,
    required this.kind,
    this.streak = 0,
    this.day = 1,
    this.deadline = '21:00',
  });

  final String journeyId;
  final String journeyName;

  /// `quiet`, `squad`, `memory`, `couple`, `flexer` or `minimal`.
  final String skinId;
  final ReminderBannerKind kind;
  final int streak;
  final int day;

  /// Local time (HH:mm) the streak stays open until.
  final String deadline;
}

/// State holder of the in-app banner; `null` means hidden.
class ReminderBannerController extends Notifier<ReminderBannerData?> {
  @override
  ReminderBannerData? build() => null;

  void show(ReminderBannerData data) => state = data;
  void dismiss() => state = null;
}

final reminderBannerProvider =
    NotifierProvider<ReminderBannerController, ReminderBannerData?>(
      ReminderBannerController.new,
    );

/// The localized banner line for [data] (per-skin voice, V2 `reminderCopy`).
String reminderBannerCopy(AppLocalizations l, ReminderBannerData data) {
  final streak = data.streak;
  final time = data.deadline;
  if (data.kind == ReminderBannerKind.daily) {
    return switch (data.skinId) {
      'squad' => l.reminderBanner_daily_squad,
      'memory' => l.reminderBanner_daily_memory,
      'couple' => l.reminderBanner_daily_couple,
      'flexer' => l.reminderBanner_daily_flexer,
      'minimal' => l.reminderBanner_daily_minimal(data.day),
      _ => l.reminderBanner_daily_quiet,
    };
  }
  return switch (data.skinId) {
    'squad' => l.reminderBanner_streak_squad(streak, time),
    'memory' => l.reminderBanner_streak_memory(time),
    'couple' => l.reminderBanner_streak_couple(streak, time),
    'flexer' => l.reminderBanner_streak_flexer(streak, time),
    'minimal' => l.reminderBanner_streak_minimal(streak, time),
    _ => l.reminderBanner_streak_quiet(streak, time),
  };
}

/// V2 `ReminderNotification` / `.reminder-banner`: dark translucent card
/// pinned to the top (220ms slide-in, fade with reduced motion), orange app
/// icon, "Ourney - bây giờ", journey name and the per-skin line. A tap opens
/// the camera ([onOpen]); the close button or an upward swipe dismisses.
/// Dark in both themes on purpose (it imitates a system notification).
class ReminderBanner extends StatelessWidget {
  const ReminderBanner({
    required this.data,
    required this.onOpen,
    required this.onDismiss,
    super.key,
  });

  final ReminderBannerData data;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  static const _card = Color(0xF01C1C1E);
  static const _text = Color(0xFFF8F8F8);
  static const _muted = Color(0xFFBBBBBB);
  static const _icon = Color(0xFFFF8A3D);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final body = reminderBannerCopy(l, data);
    final title = data.journeyName.isEmpty
        ? l.reminderBanner_appName
        : data.journeyName;
    final enter = UiMotion.of(context, const Duration(milliseconds: 220));
    return Dismissible(
      key: ValueKey('reminder-banner-${data.journeyId}'),
      direction: DismissDirection.up,
      dismissThresholds: const {DismissDirection.up: 0.25},
      onDismissed: (_) => onDismiss(),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: enter,
        curve: Curves.easeOut,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, -28 * (1 - t)),
            child: child,
          ),
        ),
        child: Semantics(
          container: true,
          liveRegion: true,
          label: '${l.reminderBanner_appName}, $title, $body',
          child: Container(
            constraints: const BoxConstraints(minHeight: 104),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x38FFFFFF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x52000000),
                  blurRadius: 32,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    key: const ValueKey('reminder-banner-open'),
                    borderRadius: BorderRadius.circular(20),
                    onTap: onOpen,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(13, 13, 8, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _icon,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const OurneyIcon(
                              name: 'activity',
                              size: 19,
                              flat: true,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ExcludeSemantics(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: l.reminderBanner_appName,
                                          style: UiText.body(
                                            size: 12,
                                            weight: FontWeight.w800,
                                            height: 1.3,
                                            color: _text,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '  ${l.reminderBanner_now}',
                                          style: UiText.body(
                                            size: 12,
                                            weight: FontWeight.w500,
                                            height: 1.3,
                                            color: _muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: UiText.body(
                                      size: 14,
                                      weight: FontWeight.w800,
                                      height: 1.3,
                                      color: _text,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    body,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: UiText.body(
                                      size: 13,
                                      height: 1.35,
                                      color: _text,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: l.reminderBanner_close,
                  child: InkWell(
                    key: const ValueKey('reminder-banner-dismiss'),
                    onTap: onDismiss,
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: OurneyIcon(
                          name: 'close',
                          size: 18,
                          flat: true,
                          color: _text,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlays the in-app banner at the top of [child] while
/// [reminderBannerProvider] holds a value. Place it inside the app's
/// `MaterialApp.builder` (needs Directionality and Localizations).
class ReminderBannerHost extends ConsumerWidget {
  const ReminderBannerHost({
    required this.child,
    required this.onOpenJourneyCamera,
    super.key,
  });

  final Widget child;

  /// Opens the camera of the journey whose banner was tapped.
  final void Function(String journeyId) onOpenJourneyCamera;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(reminderBannerProvider);
    final notifier = ref.read(reminderBannerProvider.notifier);
    return Stack(
      children: [
        child,
        if (data != null)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 10,
            right: 10,
            child: ReminderBanner(
              data: data,
              onOpen: () {
                notifier.dismiss();
                onOpenJourneyCamera(data.journeyId);
              },
              onDismiss: notifier.dismiss,
            ),
          ),
      ],
    );
  }
}
