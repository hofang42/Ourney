import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart'
    show appConfigProvider, currentUserIdProvider;
import '../../../app/theme/motion.dart' show OurneyHaptics;
import '../../../personas/persona_contract.dart' show personaSkinOf;
import '../../../ui/ui.dart';
import '../../groups/data/groups_providers.dart'
    show groupBlockedIdsProvider, groupCheckInsProvider, groupTodayProvider;
import '../../groups/domain/group_today.dart';
import '../../journeys/data/journeys_providers.dart';
import '../../journeys/domain/journey_progress.dart';
import '../../journeys/ui/journey_row.dart' show journeyTypeId;
import '../../safety/data/safety_providers.dart' show hiddenCheckInIdsProvider;
import '../data/widget_bridge_gateway.dart';
import '../data/widget_sync_controller.dart';
import '../domain/widget_privacy.dart';
import '../domain/widget_snapshot.dart';
import '../l10n/generated/widgets_localizations.dart';

/// Which widget surface is currently previewed in the `/widgets` gallery.
enum WidgetPreviewKind { today, streak, squad }

/// `/widgets`: Soft Neo-Brutalist preview gallery of Today / Streak / Squad
/// widgets, 3-step OS setup guide, and explicit privacy & Live Activity
/// controls (§3.1 #6, §7.2).
class WidgetsScreen extends ConsumerStatefulWidget {
  const WidgetsScreen({super.key});

  @override
  ConsumerState<WidgetsScreen> createState() => _WidgetsScreenState();
}

class _WidgetsScreenState extends ConsumerState<WidgetsScreen> {
  WidgetPreviewKind _previewKind = WidgetPreviewKind.today;

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = WidgetsL10n.of(context);
    final ui = context.ui;
    final photoMode = ref.watch(widgetPhotoModeProvider);
    final redactTitles = ref.watch(redactLockScreenTitlesProvider);
    final liveEnabled = ref.watch(liveActivityEnabledProvider);
    final defaultJourneyId = ref.watch(defaultWidgetJourneyIdProvider);
    final journeysAsync = ref.watch(journeysListProvider);
    final activeJourneys = [
      for (final j in journeysAsync.asData?.value ?? const <Journey>[])
        if (j.status == JourneyStatus.active) j,
    ];

    Journey? featuredJourney;
    if (defaultJourneyId != null) {
      for (final j in activeJourneys) {
        if (j.id == defaultJourneyId) {
          featuredJourney = j;
          break;
        }
      }
    }
    featuredJourney ??= activeJourneys.firstOrNull;

    Journey? featuredSquadJourney;
    if (featuredJourney != null && featuredJourney.kind == JourneyKind.group) {
      featuredSquadJourney = featuredJourney;
    } else {
      for (final j in activeJourneys) {
        if (j.kind == JourneyKind.group) {
          featuredSquadJourney = j;
          break;
        }
      }
    }

    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final showAppGroupNotice =
        isIOS &&
        ref.watch(widgetCapabilitiesProvider).asData?.value.appGroup == false;

    final photoModeNote = switch (photoMode) {
      WidgetPhotoMode.smart => l10n.widgets_photoModeSmartNote,
      WidgetPhotoMode.blurred => l10n.widgets_photoModeBlurredNote,
      WidgetPhotoMode.off => l10n.widgets_photoModeOffNote,
      WidgetPhotoMode.clear => l10n.widgets_photoModeClearNote,
    };

    return UiScaffold(
      key: const ValueKey('widgets-screen'),
      padTop: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiBackHeader(
            onBack: _close,
            backLabel: l10n.widgets_back,
            title: l10n.widgets_title,
          ),
          const SizedBox(height: UiSpace.sm),
          Text(
            l10n.widgets_intro,
            style: UiText.muted(color: ui.inkMuted),
          ),
          if (showAppGroupNotice) ...[
            const SizedBox(height: UiSpace.md),
            UiCard(
              shadowOffset: 0,
              child: Text(
                l10n.widgets_appGroupUnavailable,
                style: UiText.body(size: 13, height: 1.4, color: ui.inkMuted),
              ),
            ),
          ],
          if (isIOS) ...[
            const SizedBox(height: UiSpace.md),
            const _WidgetDiagnosticsCard(),
          ],
          const SizedBox(height: UiSpace.xl),
          UiListHeading(title: l10n.widgets_secPreview),
          const SizedBox(height: UiSpace.sm),
          Semantics(
            container: true,
            label: l10n.widgets_secPreview,
            child: UiSegmented<WidgetPreviewKind>(
              value: _previewKind,
              onChanged: (next) {
                OurneyHaptics.selection();
                setState(() => _previewKind = next);
              },
              segments: [
                UiSegment(
                  key: const ValueKey('widgets-preview-tab-today'),
                  value: WidgetPreviewKind.today,
                  label: l10n.widgets_tabToday,
                ),
                UiSegment(
                  key: const ValueKey('widgets-preview-tab-streak'),
                  value: WidgetPreviewKind.streak,
                  label: l10n.widgets_tabStreak,
                ),
                UiSegment(
                  key: const ValueKey('widgets-preview-tab-squad'),
                  value: WidgetPreviewKind.squad,
                  label: l10n.widgets_tabSquad,
                ),
              ],
            ),
          ),
          const SizedBox(height: UiSpace.md),
          UiFadeThroughSwitcher(
            duration: UiMotion.fast,
            animateSize: true,
            alignment: Alignment.topCenter,
            child: _WidgetPreviewCard(
              key: ValueKey('widgets-preview-card-${_previewKind.name}'),
              kind: _previewKind,
              journey: featuredJourney,
              squadJourney: featuredSquadJourney,
              photoMode: photoMode,
            ),
          ),
          const SizedBox(height: UiSpace.xl),
          UiListHeading(title: l10n.widgets_secPrivacy),
          const SizedBox(height: UiSpace.xs),
          UiCard(
            radius: UiRadius.card,
            shadowOffset: 0,
            padding: const EdgeInsets.symmetric(horizontal: UiSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      UiEyebrow(l10n.widgets_photoModeEyebrow),
                      const SizedBox(height: UiSpace.sm),
                      UiSegmented<WidgetPhotoMode>(
                        value: photoMode,
                        onChanged: (mode) {
                          OurneyHaptics.selection();
                          unawaited(
                            ref.read(widgetPhotoModeProvider.notifier).set(mode),
                          );
                        },
                        segments: [
                          UiSegment(
                            key: const ValueKey('widgets-photo-mode-smart'),
                            value: WidgetPhotoMode.smart,
                            label: l10n.widgets_photoModeSmart,
                          ),
                          UiSegment(
                            key: const ValueKey('widgets-photo-mode-blurred'),
                            value: WidgetPhotoMode.blurred,
                            label: l10n.widgets_photoModeBlurred,
                          ),
                          UiSegment(
                            key: const ValueKey('widgets-photo-mode-off'),
                            value: WidgetPhotoMode.off,
                            label: l10n.widgets_photoModeOff,
                          ),
                          UiSegment(
                            key: const ValueKey('widgets-photo-mode-clear'),
                            value: WidgetPhotoMode.clear,
                            label: l10n.widgets_photoModeClear,
                          ),
                        ],
                      ),
                      const SizedBox(height: UiSpace.sm),
                      Text(
                        photoModeNote,
                        key: const ValueKey('widgets-photo-mode-note'),
                        style: UiText.body(
                          size: 12,
                          height: 1.4,
                          color: ui.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const UiDivider(),
                UiSwitchRow(
                  key: const ValueKey('widgets-redact-lock-titles'),
                  label: l10n.widgets_redactTitlesLabel,
                  subtitle: isAndroid
                      ? l10n.widgets_redactTitlesSubAndroid
                      : l10n.widgets_redactTitlesSub,
                  value: redactTitles,
                  divider: false,
                  onChanged: (v) {
                    OurneyHaptics.selection();
                    unawaited(
                      ref
                          .read(redactLockScreenTitlesPrefProvider.notifier)
                          .set(v),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: UiSpace.xl),
          UiListHeading(title: l10n.widgets_secLiveActivity),
          const SizedBox(height: UiSpace.xs),
          UiCard(
            radius: UiRadius.card,
            shadowOffset: 0,
            padding: const EdgeInsets.symmetric(horizontal: UiSpace.md),
            child: UiSwitchRow(
              key: const ValueKey('widgets-live-activity-toggle'),
              label: isAndroid
                  ? l10n.widgets_liveActivityLabelAndroid
                  : l10n.widgets_liveActivityLabel,
              subtitle: isAndroid
                  ? l10n.widgets_liveActivitySubAndroid
                  : l10n.widgets_liveActivitySub,
              value: liveEnabled,
              divider: false,
              onChanged: (v) {
                OurneyHaptics.selection();
                unawaited(
                  ref
                      .read(liveActivityEnabledProvider.notifier)
                      .set(enabled: v),
                );
              },
            ),
          ),
          if (activeJourneys.isNotEmpty) ...[
            const SizedBox(height: UiSpace.xl),
            UiListHeading(title: l10n.widgets_secDefaultJourney),
            const SizedBox(height: UiSpace.xs),
            UiCard(
              radius: UiRadius.card,
              shadowOffset: 0,
              padding: const EdgeInsets.symmetric(horizontal: UiSpace.md),
              child: Column(
                children: [
                  _DefaultJourneyOptionRow(
                    rowKey: const ValueKey('widgets-default-journey-auto'),
                    title: l10n.widgets_defaultJourneyAuto,
                    subtitle: l10n.widgets_defaultJourneyAutoSub,
                    leading: const OurneyIcon(name: 'sparkle', size: 22),
                    selected: defaultJourneyId == null,
                    divider: true,
                    onTap: () {
                      OurneyHaptics.selection();
                      unawaited(
                        ref
                            .read(defaultWidgetJourneyIdProvider.notifier)
                            .set(null),
                      );
                    },
                  ),
                  for (var i = 0; i < activeJourneys.length; i++)
                    _DefaultJourneyOptionRow(
                      rowKey: ValueKey(
                        'widgets-default-journey-${activeJourneys[i].id}',
                      ),
                      title: activeJourneys[i].title,
                      leading: UiTypeBadge(
                        type: journeyTypeId(activeJourneys[i]),
                        size: 32,
                      ),
                      selected: defaultJourneyId == activeJourneys[i].id,
                      divider: i < activeJourneys.length - 1,
                      onTap: () {
                        OurneyHaptics.selection();
                        unawaited(
                          ref
                              .read(defaultWidgetJourneyIdProvider.notifier)
                              .set(activeJourneys[i].id),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: UiSpace.xl),
          UiListHeading(title: l10n.widgets_secSetup),
          const SizedBox(height: UiSpace.xs),
          UiCard(
            radius: UiRadius.card,
            shadowOffset: UiShadow.small,
            padding: const EdgeInsets.all(UiSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SetupStepRow(
                  iconName: 'home',
                  title: isAndroid
                      ? l10n.widgets_setupStep1TitleAndroid
                      : l10n.widgets_setupStep1Title,
                  body: l10n.widgets_setupStep1Body,
                ),
                const SizedBox(height: UiSpace.md),
                _SetupStepRow(
                  iconName: 'plus',
                  title: l10n.widgets_setupStep2Title,
                  body: l10n.widgets_setupStep2Body,
                ),
                const SizedBox(height: UiSpace.md),
                _SetupStepRow(
                  iconName: 'camera',
                  title: l10n.widgets_setupStep3Title,
                  body: l10n.widgets_setupStep3Body,
                ),
              ],
            ),
          ),
          const SizedBox(height: UiSpace.xl),
        ],
      ),
    );
  }
}

class _WidgetDiagnosticsCard extends ConsumerStatefulWidget {
  const _WidgetDiagnosticsCard();

  @override
  ConsumerState<_WidgetDiagnosticsCard> createState() =>
      _WidgetDiagnosticsCardState();
}

class _WidgetDiagnosticsCardState
    extends ConsumerState<_WidgetDiagnosticsCard> {
  Future<List<String>>? _read;

  void _toggle() {
    setState(() {
      _read = _read == null
          ? ref.read(widgetBridgeGatewayProvider).getWidgetDiagnostics()
          : null;
    });
  }

  Future<void> _copy(String text, String copiedMessage) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) showUiToast(context, copiedMessage);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = WidgetsL10n.of(context);
    final ui = context.ui;
    final read = _read;
    return UiCard(
      shadowOffset: 0,
      padding: const EdgeInsets.symmetric(horizontal: UiSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            expanded: read != null,
            child: UiRow(
              title: l10n.widgets_diagnosticsTitle,
              showChevron: false,
              divider: read != null,
              trailing: OurneyIcon(
                name: read == null ? 'chevron-down' : 'chevron-up',
                size: 20,
                flat: true,
                color: ui.chevron,
              ),
              onPressed: _toggle,
            ),
          ),
          if (read != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: UiSpace.sm),
              child: FutureBuilder<List<String>>(
                future: read,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: UiSpinner());
                  }
                  final log = snapshot.data?.join('\n') ?? '';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        log.isEmpty ? l10n.widgets_diagnosticsEmpty : log,
                        style: UiText.body(
                          size: 12,
                          height: 1.4,
                          color: ui.inkMuted,
                        ),
                      ),
                      if (log.isNotEmpty)
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: UiButton.ghost(
                            label: l10n.widgets_diagnosticsCopy,
                            glyph: const OurneyIcon(name: 'copy', size: 16),
                            expand: false,
                            onPressed: () => unawaited(
                              _copy(log, l10n.widgets_diagnosticsCopied),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DefaultJourneyOptionRow extends StatelessWidget {
  const _DefaultJourneyOptionRow({
    required this.rowKey,
    required this.title,
    required this.leading,
    required this.selected,
    required this.divider,
    required this.onTap,
    this.subtitle,
  });

  final Key rowKey;
  final String title;
  final String? subtitle;
  final Widget leading;
  final bool selected;
  final bool divider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return UiRow(
      key: rowKey,
      leading: leading,
      title: title,
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: UiText.body(size: 12, height: 1.4, color: ui.inkMuted),
            ),
      selected: selected,
      inMutuallyExclusiveGroup: true,
      showChevron: false,
      divider: divider,
      trailing: OurneyIcon(
        name: selected ? 'radio-on' : 'radio-off',
        size: 20,
        flat: !selected,
        color: selected ? ui.brand : ui.inkMuted,
      ),
      onPressed: onTap,
    );
  }
}

class _SetupStepRow extends StatelessWidget {
  const _SetupStepRow({
    required this.iconName,
    required this.title,
    required this.body,
  });

  final String iconName;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ui.fill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ui.outline, width: UiBorder.thin),
          ),
          child: OurneyIcon(name: iconName, size: 20),
        ),
        const SizedBox(width: UiSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: UiText.body(
                  size: 14,
                  weight: FontWeight.w700,
                  height: 1.35,
                  color: ui.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: UiText.body(
                  size: 13,
                  height: 1.4,
                  color: ui.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Interactive Soft Neo-Brutalist preview of the selected widget surface,
/// rendered in the featured journey's `UiSkinScope` (§5.3).
class _WidgetPreviewCard extends ConsumerWidget {
  const _WidgetPreviewCard({
    required this.kind,
    required this.journey,
    required this.squadJourney,
    required this.photoMode,
    super.key,
  });

  final WidgetPreviewKind kind;
  final Journey? journey;
  final Journey? squadJourney;
  final WidgetPhotoMode photoMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = WidgetsL10n.of(context);
    final j = journey;
    final sq = squadJourney;
    final targetJourney = kind == WidgetPreviewKind.squad ? sq : j;
    final skinId = targetJourney == null
        ? 'squad'
        : uiSkinIdFor(personaSkinOf(targetJourney));
    final variantIndex = (targetJourney?.color ?? 0).clamp(0, 2);

    return Semantics(
      container: true,
      readOnly: true,
      label: l10n.widgets_secPreview,
      child: UiSkinScope(
        skinId: skinId,
        variant: variantIndex,
        child: Builder(
          builder: (context) => switch (kind) {
            WidgetPreviewKind.today => _TodayWidgetPreview(
              journey: j,
              photoMode: photoMode,
            ),
            WidgetPreviewKind.streak => _StreakWidgetPreview(
              journey: j,
            ),
            WidgetPreviewKind.squad => _SquadWidgetPreview(
              journey: sq,
              photoMode: photoMode,
            ),
          },
        ),
      ),
    );
  }
}

class _SamplePreviewPill extends StatelessWidget {
  const _SamplePreviewPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        key: const ValueKey('widgets-preview-sample-badge'),
        margin: const EdgeInsets.only(bottom: UiSpace.sm),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: ui.fill,
          borderRadius: BorderRadius.circular(UiRadius.capsule),
          border: Border.all(color: ui.outline, width: UiBorder.thin),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OurneyIcon(
              name: 'sparkle',
              size: 12,
              flat: true,
              color: ui.inkMuted,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.body(
                  size: 11,
                  weight: FontWeight.w700,
                  height: 1.3,
                  color: ui.inkMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayWidgetPreview extends ConsumerWidget {
  const _TodayWidgetPreview({
    required this.journey,
    required this.photoMode,
  });

  final Journey? journey;
  final WidgetPhotoMode photoMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = WidgetsL10n.of(context);
    final ui = context.ui;
    final j = journey;
    final isSample = j == null;
    final now = ref.watch(journeysNowProvider);
    final checkIns = j == null
        ? const <CheckIn>[]
        : (ref.watch(myCheckInsProvider(j.id)).asData?.value ??
              const <CheckIn>[]);
    final membership = j == null
        ? null
        : ref.watch(myMembershipProvider(j.id)).asData?.value;
    final progress = j == null
        ? null
        : JourneyProgress.compute(
            journey: j,
            membership: membership,
            checkIns: checkIns,
            now: now,
          );

    final title = j?.title ?? l10n.widgets_previewSampleTitle;
    final typeId = j == null ? 'study' : journeyTypeId(j);
    final day = progress?.dayNumber ?? 15;
    final totalDays = progress == null
        ? 30
        : (progress.totalDays ?? j?.durationDays ?? 0);
    final streak = progress?.summary.current ?? 14;
    final checkedInToday = progress?.checkedInToday ?? false;
    final atRisk = progress?.summary.atRisk ?? true;
    final isSensitive =
        j != null && WidgetPrivacyPolicy.isSensitiveMetricJourney(j);

    final photoStatusText = switch (photoMode) {
      WidgetPhotoMode.off => l10n.widgets_previewPhotoHiddenNote,
      WidgetPhotoMode.blurred => l10n.widgets_previewPhotoBlurredNote,
      WidgetPhotoMode.smart =>
        isSensitive
            ? l10n.widgets_previewPhotoBlurredNote
            : l10n.widgets_previewPhotoClearNote,
      WidgetPhotoMode.clear => l10n.widgets_previewPhotoClearNote,
    };
    final photoIcon = switch (photoMode) {
      WidgetPhotoMode.off => 'eye-off',
      WidgetPhotoMode.blurred => 'lock',
      WidgetPhotoMode.smart => isSensitive ? 'lock' : 'image',
      WidgetPhotoMode.clear => 'image',
    };

    final localeCode = Localizations.localeOf(context).languageCode;
    final nowDate = progress?.today ?? const LocalDate(2026, 11, 24);
    final weekLabels = [
      for (var i = 6; i >= 0; i--)
        (
          label: WidgetSnapshotBuilder.weekdayLabel(
            nowDate.addDays(-i),
            isToday: i == 0,
            locale: localeCode,
          ),
          done: progress != null
              ? progress.checkInsByDate.containsKey(nowDate.addDays(-i))
              : i > 0,
          isToday: i == 0,
        ),
    ];

    return UiCard(
      key: const ValueKey('widgets-preview-today-surface'),
      radius: UiRadius.card,
      shadowOffset: UiShadow.large,
      padding: const EdgeInsets.all(UiSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isSample)
            _SamplePreviewPill(label: l10n.widgets_previewSampleBadge),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UiTypeBadge(type: typeId, size: 40),
              const SizedBox(width: UiSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.body(
                        size: 16,
                        weight: FontWeight.w700,
                        height: 1.35,
                        color: ui.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      totalDays > 0
                          ? l10n.widgets_previewDayOf(day, totalDays)
                          : l10n.widgets_previewDayOpen(day),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.body(
                        size: 12,
                        weight: FontWeight.w600,
                        height: 1.35,
                        color: ui.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: UiSpace.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ui.fill,
                  borderRadius: BorderRadius.circular(UiRadius.capsule),
                  border: Border.all(color: ui.outline, width: UiBorder.thin),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const OurneyIcon(name: 'flame', size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$streak',
                      style: UiText.display(
                        size: 15,
                        weight: 800,
                        height: 1.2,
                        color: ui.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: UiSpace.md),
          // 7-square Soft Neo-Brutalist week chain strip.
          Row(
            children: [
              for (var i = 0; i < weekLabels.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        weekLabels[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.body(
                          size: 10,
                          weight: FontWeight.w700,
                          height: 1.3,
                          color: weekLabels[i].isToday ? ui.ink : ui.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: weekLabels[i].done
                                ? ui.accent
                                : ui.fill,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: ui.outline,
                              width: weekLabels[i].isToday
                                  ? UiBorder.standard
                                  : UiBorder.thin,
                            ),
                          ),
                          child: OurneyIcon(
                            name: weekLabels[i].done ? 'check' : 'camera',
                            size: 13,
                            flat: true,
                            color: weekLabels[i].done
                                ? ui.onAccent
                                : ui.inkMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < weekLabels.length - 1) const SizedBox(width: 5),
              ],
            ],
          ),
          const SizedBox(height: UiSpace.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: UiSpace.md,
              vertical: UiSpace.sm,
            ),
            decoration: BoxDecoration(
              color: ui.fill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ui.outline, width: UiBorder.thin),
            ),
            child: Row(
              children: [
                OurneyIcon(
                  name: photoIcon,
                  size: 16,
                  flat: true,
                  color: ui.inkMuted,
                ),
                const SizedBox(width: UiSpace.sm),
                Expanded(
                  child: Text(
                    photoStatusText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.body(
                      size: 12,
                      weight: FontWeight.w600,
                      height: 1.35,
                      color: ui.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: UiSpace.md),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: UiSpace.sm,
            runSpacing: UiSpace.sm,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OurneyIcon(
                    name: checkedInToday
                        ? 'check-circle'
                        : (atRisk ? 'flame' : 'clock'),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      checkedInToday
                          ? l10n.widgets_previewDoneBadge
                          : (atRisk
                                ? l10n.widgets_previewAtRiskBadge
                                : l10n.widgets_previewPendingBadge),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.body(
                        size: 12,
                        weight: FontWeight.w700,
                        height: 1.35,
                        color: checkedInToday
                            ? ui.success
                            : (atRisk ? ui.timeCue : ui.inkMuted),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: ui.brand,
                  borderRadius: BorderRadius.circular(UiRadius.capsule),
                  border: Border.all(color: ui.outline, width: UiBorder.thin),
                  boxShadow: ui.hardShadow(UiShadow.tiny),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OurneyIcon(
                      name: 'camera',
                      size: 16,
                      flat: true,
                      color: ui.onBrand,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.widgets_previewSnapCta,
                      style: UiText.body(
                        size: 13,
                        weight: FontWeight.w700,
                        height: 1.3,
                        color: ui.onBrand,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakWidgetPreview extends ConsumerWidget {
  const _StreakWidgetPreview({required this.journey});

  final Journey? journey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = WidgetsL10n.of(context);
    final ui = context.ui;
    final j = journey;
    final isSample = j == null;
    final now = ref.watch(journeysNowProvider);
    final checkIns = j == null
        ? const <CheckIn>[]
        : (ref.watch(myCheckInsProvider(j.id)).asData?.value ??
              const <CheckIn>[]);
    final membership = j == null
        ? null
        : ref.watch(myMembershipProvider(j.id)).asData?.value;
    final progress = j == null
        ? null
        : JourneyProgress.compute(
            journey: j,
            membership: membership,
            checkIns: checkIns,
            now: now,
          );
    final streak = progress?.summary.current ?? 14;
    final title = j?.title ?? l10n.widgets_previewSampleTitle;
    final nowDate = progress?.today ?? const LocalDate(2026, 11, 24);
    final weekDone = [
      for (var i = 6; i >= 0; i--)
        progress != null
            ? progress.checkInsByDate.containsKey(nowDate.addDays(-i))
            : i > 0,
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: UiCard(
          key: const ValueKey('widgets-preview-streak-surface'),
          radius: UiRadius.card,
          shadowOffset: UiShadow.large,
          padding: const EdgeInsets.all(UiSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSample)
                _SamplePreviewPill(label: l10n.widgets_previewSampleBadge),
              Row(
                children: [
                  const OurneyIcon(name: 'flame', size: 28, active: true),
                  const SizedBox(width: UiSpace.sm),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        '$streak',
                        style: UiText.display(
                          size: 44,
                          weight: 800,
                          height: 1.1,
                          tracking: -0.04,
                          color: ui.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: UiSpace.xs),
              Text(
                l10n.widgets_previewStreakDays(streak),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.body(
                  size: 13,
                  weight: FontWeight.w700,
                  height: 1.35,
                  color: ui.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.body(
                  size: 12,
                  height: 1.35,
                  color: ui.inkMuted,
                ),
              ),
              const SizedBox(height: UiSpace.md),
              Row(
                children: [
                  for (var i = 0; i < weekDone.length; i++) ...[
                    Expanded(
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: weekDone[i] ? ui.accent : ui.fill,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: ui.outline,
                            width: UiBorder.hairline,
                          ),
                        ),
                      ),
                    ),
                    if (i < weekDone.length - 1) const SizedBox(width: 3),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SquadWidgetPreview extends ConsumerWidget {
  const _SquadWidgetPreview({
    required this.journey,
    required this.photoMode,
  });

  final Journey? journey;
  final WidgetPhotoMode photoMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = WidgetsL10n.of(context);
    final ui = context.ui;
    final j = journey;
    final isSample = j == null;
    final title = j?.title ?? l10n.widgets_previewSampleTitle;

    int doneCount;
    int memberCount;
    List<({String name, bool done, int colorIndex})> members;

    if (j != null) {
      final now = ref.watch(journeysNowProvider);
      final myCheckIns =
          ref.watch(myCheckInsProvider(j.id)).asData?.value ?? const <CheckIn>[];
      final membership = ref.watch(myMembershipProvider(j.id)).asData?.value;
      final localOnly = ref.watch(appConfigProvider).localOnly;
      final rawMembers = localOnly
          ? null
          : ref.watch(groupTodayProvider(j.id)).asData?.value;
      final groupCheckIns = localOnly
          ? const <CheckIn>[]
          : (ref.watch(groupCheckInsProvider(j.id)).asData?.value ??
                const <CheckIn>[]);
      final blockedIds = localOnly
          ? const <String>{}
          : (ref.watch(groupBlockedIdsProvider).asData?.value ??
                const <String>{});
      final hiddenCheckInIds = ref.watch(hiddenCheckInIdsProvider);
      final currentUserId = ref.watch(currentUserIdProvider);

      final progress = JourneyProgress.compute(
        journey: j,
        membership: membership,
        checkIns: myCheckIns,
        now: now,
      );
      final combinedCheckIns = <CheckIn>[
        ...groupCheckIns,
        for (final c in myCheckIns)
          if (!groupCheckIns.any((g) => g.id == c.id)) c,
      ];
      final todayCheckIns = progress.checkInsOn(progress.today);
      final myTodayCheckIn = todayCheckIns.isEmpty ? null : todayCheckIns.last;
      final selfUserId = currentUserId ?? membership?.userId ?? j.ownerId;
      final partnerName = j.couplePartnerName?.trim();
      final effectiveMembers = (rawMembers != null && rawMembers.isNotEmpty)
          ? rawMembers
          : <MemberToday>[
              MemberToday(
                userId: selfUserId,
                displayName: j.coupleSelfName ?? l10n.widgets_previewYou,
                role: membership?.role ?? MemberRole.owner,
                currentStreak: progress.summary.current,
                todayCheckIn: myTodayCheckIn,
              ),
              if (partnerName != null && partnerName.isNotEmpty)
                MemberToday(
                  userId: '${j.id}-partner',
                  displayName: partnerName,
                  role: MemberRole.member,
                  currentStreak: 0,
                ),
            ];
      final groupView = GroupTodayView.build(
        journey: j,
        members: effectiveMembers,
        now: now,
        myUserId: currentUserId ?? membership?.userId,
        blockedIds: blockedIds,
        hiddenCheckInIds: hiddenCheckInIds,
        checkIns: combinedCheckIns,
        myMembership: membership,
      );
      final ordered = <GroupMemberEntry>[
        ...groupView.done,
        ...groupView.pending,
      ];
      doneCount = groupView.doneCount;
      memberCount = groupView.memberCount;
      members = [
        for (final entry in ordered.take(j.maxMembers.clamp(1, 10)))
          (
            name: entry.member.displayName.trim().isEmpty
                ? l10n.widgets_previewYou
                : entry.member.displayName,
            done: entry.checkedInToday,
            colorIndex: UiAvatar.indexFor(entry.member.userId),
          ),
      ];
    } else {
      doneCount = 3;
      memberCount = 5;
      members = [
        (name: 'Minh', done: true, colorIndex: 0),
        (name: 'Linh', done: true, colorIndex: 1),
        (name: 'An', done: true, colorIndex: 2),
        (name: 'Khánh', done: false, colorIndex: 3),
        (name: l10n.widgets_previewYou, done: false, colorIndex: 4),
      ];
    }

    final photoStatusText = switch (photoMode) {
      WidgetPhotoMode.off => l10n.widgets_previewPhotoHiddenNote,
      WidgetPhotoMode.blurred => l10n.widgets_previewPhotoBlurredNote,
      WidgetPhotoMode.smart => l10n.widgets_photoModeSmartNote,
      WidgetPhotoMode.clear => l10n.widgets_previewPhotoClearNote,
    };
    final photoIcon = switch (photoMode) {
      WidgetPhotoMode.off => 'eye-off',
      WidgetPhotoMode.blurred => 'lock',
      WidgetPhotoMode.smart => 'lock',
      WidgetPhotoMode.clear => 'image',
    };

    return UiCard(
      key: const ValueKey('widgets-preview-squad-surface'),
      radius: UiRadius.card,
      shadowOffset: UiShadow.large,
      padding: const EdgeInsets.all(UiSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isSample)
            _SamplePreviewPill(label: l10n.widgets_previewSampleBadge),
          Row(
            children: [
              const OurneyIcon(name: 'squad', size: 22),
              const SizedBox(width: UiSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.body(
                        size: 15,
                        weight: FontWeight.w700,
                        height: 1.35,
                        color: ui.ink,
                      ),
                    ),
                    Text(
                      l10n.widgets_previewSquadCount(doneCount, memberCount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.body(
                        size: 12,
                        weight: FontWeight.w600,
                        height: 1.35,
                        color: ui.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: UiSpace.md),
          Wrap(
            spacing: UiSpace.md,
            runSpacing: UiSpace.sm,
            children: [
              for (final member in members)
                _SquadMemberPreviewBubble(
                  name: member.name,
                  done: member.done,
                  colorIndex: member.colorIndex,
                ),
            ],
          ),
          const SizedBox(height: UiSpace.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: UiSpace.md,
              vertical: UiSpace.sm,
            ),
            decoration: BoxDecoration(
              color: ui.fill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ui.outline, width: UiBorder.thin),
            ),
            child: Row(
              children: [
                OurneyIcon(
                  name: photoIcon,
                  size: 16,
                  flat: true,
                  color: ui.inkMuted,
                ),
                const SizedBox(width: UiSpace.sm),
                Expanded(
                  child: Text(
                    photoStatusText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.body(
                      size: 12,
                      weight: FontWeight.w600,
                      height: 1.35,
                      color: ui.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SquadMemberPreviewBubble extends StatelessWidget {
  const _SquadMemberPreviewBubble({
    required this.name,
    required this.done,
    required this.colorIndex,
  });

  final String name;
  final bool done;
  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            UiAvatar(
              name: name,
              colorIndex: colorIndex,
              size: 36,
            ),
            if (done)
              PositionedDirectional(
                end: -2,
                bottom: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ui.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ui.surface,
                      width: UiBorder.thin,
                    ),
                  ),
                  child: OurneyIcon(
                    name: 'check',
                    size: 10,
                    flat: true,
                    color: ui.surface,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: UiText.body(
            size: 11,
            weight: done ? FontWeight.w700 : FontWeight.w500,
            height: 1.3,
            color: done ? ui.ink : ui.inkMuted,
          ),
        ),
      ],
    );
  }
}
