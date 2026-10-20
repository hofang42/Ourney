import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/chunky_button.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/ourney_card.dart';
import '../../../shared/template_icons.dart';
import '../data/notification_gateway.dart';
import '../data/reminder_permission.dart';
import '../data/reminder_scheduler.dart';
import '../data/reminder_settings.dart';
import '../domain/reminder_plan.dart';
import '../l10n/generated/reminders_localizations.dart';

/// Active journeys the user can set reminders for.
final reminderJourneysProvider = StreamProvider.autoDispose<List<Journey>>(
  (ref) => ref
      .watch(journeyRepositoryProvider)
      .watchActive()
      .map(
        (all) => [
          for (final j in all)
            if (j.status == JourneyStatus.active) j,
        ],
      ),
  retry: (_, _) => null,
);

/// `/reminders`: per-journey daily reminder (on/off + time) and the 21:00
/// streak alert switch (FR-G1, FR-G2). The notification permission is asked
/// here, when the user turns on the first reminder (FR-A3).
class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Coming back from system settings: re-check the permission.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.invalidate(reminderPermissionProvider);
        unawaited(_reschedule());
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _reschedule() =>
      ref.read(reminderSchedulerProvider).reschedule();

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.capture);
    }
  }

  /// In-context permission flow. Returns false when the user backs out of
  /// the rationale dialog (the switch then stays off).
  Future<bool> _ensurePermissionAsked() async {
    final permission = await ref.read(reminderPermissionProvider.future);
    if (permission != NotificationPermission.notDetermined) return true;
    if (!mounted) return false;
    final l10n = RemindersL10n.of(context);
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey('reminders-permission-dialog'),
        icon: const Icon(Icons.notifications_active_rounded),
        title: Text(l10n.reminders_permissionTitle),
        content: Text(l10n.reminders_permissionMessage),
        actions: [
          TextButton(
            key: const ValueKey('reminders-permission-later'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.reminders_permissionNotNow),
          ),
          FilledButton(
            key: const ValueKey('reminders-permission-continue'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.reminders_permissionContinue),
          ),
        ],
      ),
    );
    if (proceed != true) return false;
    await requestReminderPermission(ref);
    return true;
  }

  Future<void> _toggle(Journey journey, {required bool on}) async {
    final controller = ref.read(reminderSettingsProvider.notifier);
    final current = controller.of(journey.id);
    if (on && !await _ensurePermissionAsked()) return;
    await controller.save(journey.id, current.copyWith(enabled: on));
    await _reschedule();
  }

  Future<void> _pickTime(Journey journey) async {
    final l10n = RemindersL10n.of(context);
    final controller = ref.read(reminderSettingsProvider.notifier);
    final current = controller.of(journey.id);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: current.time.hour,
        minute: current.time.minute,
      ),
      helpText: l10n.reminders_pickTimeHelp,
    );
    if (picked == null) return;
    await controller.save(
      journey.id,
      current.copyWith(time: ReminderTime(picked.hour, picked.minute)),
    );
    await _reschedule();
  }

  Future<void> _setStreakAlerts(bool enabled) async {
    if (enabled && !await _ensurePermissionAsked()) return;
    await ref.read(streakAlertsEnabledProvider.notifier).set(enabled: enabled);
    await _reschedule();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = RemindersL10n.of(context);
    final journeys = ref.watch(reminderJourneysProvider);
    final settings = ref.watch(reminderSettingsProvider);
    final streakAlerts = ref.watch(streakAlertsEnabledProvider);
    final permission = ref.watch(reminderPermissionProvider).value;
    final anyOn = streakAlerts || settings.values.any((s) => s.enabled);
    final text = Theme.of(context).textTheme;
    final c = OurneyColors.of(context);

    return Scaffold(
      key: const ValueKey('reminders-screen'),
      appBar: AppBar(
        leading: BackButton(onPressed: _close),
        title: Text(l10n.reminders_title),
      ),
      body: SafeArea(
        child: journeys.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => EmptyState(
            key: const ValueKey('reminders-error'),
            icon: Icons.cloud_off_rounded,
            title: l10n.reminders_loadError,
            actionLabel: l10n.reminders_retry,
            onAction: () => ref.invalidate(reminderJourneysProvider),
          ),
          data: (list) => list.isEmpty
              ? EmptyState(
                  key: const ValueKey('reminders-empty'),
                  icon: Icons.notifications_none_rounded,
                  title: l10n.reminders_emptyTitle,
                  message: l10n.reminders_emptyMessage,
                )
              : ListView(
                  padding: const EdgeInsets.all(OurneySpacing.screenMargin),
                  children: [
                    Text(
                      l10n.reminders_intro,
                      style: text.bodyMedium?.copyWith(color: c.inkMuted),
                    ),
                    if (permission == NotificationPermission.denied &&
                        anyOn) ...[
                      const SizedBox(height: OurneySpacing.lg),
                      _DeniedBanner(
                        onOpenSettings: () async {
                          try {
                            await ref
                                .read(notificationGatewayProvider)
                                .openSettings();
                          } on Object {
                            // Nothing else to offer on unsupported platforms.
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: OurneySpacing.xl),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.reminders_journeysHeader,
                        style: text.titleSmall?.copyWith(color: c.inkMuted),
                      ),
                    ),
                    const SizedBox(height: OurneySpacing.sm),
                    for (final j in list) ...[
                      _JourneyReminderTile(
                        journey: j,
                        setting: settings[j.id] ?? ReminderSetting.off,
                        onToggle: (on) => _toggle(j, on: on),
                        onPickTime: () => _pickTime(j),
                      ),
                      const SizedBox(height: OurneySpacing.md),
                    ],
                    const SizedBox(height: OurneySpacing.md),
                    OurneyCard(
                      padding: EdgeInsets.zero,
                      child: SwitchListTile(
                        key: const ValueKey('reminders-streak-alert'),
                        secondary: Icon(
                          Icons.local_fire_department_rounded,
                          color: c.streak,
                        ),
                        title: Text(l10n.reminders_streakAlertTitle),
                        subtitle: Text(l10n.reminders_streakAlertSubtitle),
                        value: streakAlerts,
                        onChanged: _setStreakAlerts,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

String formatReminderTime(BuildContext context, ReminderTime time) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: time.hour, minute: time.minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

class _JourneyReminderTile extends StatelessWidget {
  const _JourneyReminderTile({
    required this.journey,
    required this.setting,
    required this.onToggle,
    required this.onPickTime,
  });

  final Journey journey;
  final ReminderSetting setting;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final l10n = RemindersL10n.of(context);
    final text = Theme.of(context).textTheme;
    final c = OurneyColors.of(context);
    final time = formatReminderTime(context, setting.time);
    return OurneyCard(
      key: ValueKey('reminders-journey-${journey.id}'),
      padding: const EdgeInsets.symmetric(
        horizontal: OurneySpacing.lg,
        vertical: OurneySpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  journeyIcon(journey.emoji, journey.templateId),
                  size: 28,
                ),
              ),
              const SizedBox(width: OurneySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      journey.title,
                      style: text.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      setting.enabled
                          ? l10n.reminders_timeOn(time)
                          : l10n.reminders_timeOff,
                      style: text.bodySmall?.copyWith(color: c.inkMuted),
                    ),
                  ],
                ),
              ),
              Semantics(
                label: l10n.reminders_toggleLabel(journey.title),
                child: Switch(
                  key: ValueKey('reminders-toggle-${journey.id}'),
                  value: setting.enabled,
                  onChanged: onToggle,
                ),
              ),
            ],
          ),
          if (setting.enabled) ...[
            const SizedBox(height: OurneySpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                key: ValueKey('reminders-time-${journey.id}'),
                onPressed: onPickTime,
                icon: const Icon(Icons.schedule_rounded),
                label: Text(l10n.reminders_changeTime(time)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeniedBanner extends StatelessWidget {
  const _DeniedBanner({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = RemindersL10n.of(context);
    final text = Theme.of(context).textTheme;
    final c = OurneyColors.of(context);
    return OurneyCard(
      key: const ValueKey('reminders-denied'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_off_rounded, color: c.danger),
              const SizedBox(width: OurneySpacing.sm),
              Expanded(
                child: Text(
                  l10n.reminders_deniedTitle,
                  style: text.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: OurneySpacing.sm),
          Text(l10n.reminders_deniedMessage, style: text.bodyMedium),
          const SizedBox(height: OurneySpacing.md),
          ChunkyButton(
            key: const ValueKey('reminders-open-settings'),
            label: l10n.reminders_openSettings,
            icon: Icons.settings_rounded,
            variant: ChunkyVariant.neutral,
            onPressed: onOpenSettings,
          ),
        ],
      ),
    );
  }
}
