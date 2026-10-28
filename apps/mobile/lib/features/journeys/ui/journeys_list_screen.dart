import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/persona_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../personas/persona_contract.dart';
import '../../../shared/color_utils.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/layout.dart';
import '../../../shared/ourney_primary_button.dart';
import '../../../shared/placeholder_screen.dart';
import '../../../shared/profile_button.dart';
import '../../../shared/template_icons.dart';
import '../../profile/profile_providers.dart';
import '../../sharing/sharing.dart';
import '../../social/social.dart';
import '../data/journeys_providers.dart';
import '../domain/journey_progress.dart';
import '../domain/journey_time.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'journey_detail_screen.dart';
import 'journey_errors.dart';
import 'journey_photo.dart';

/// Hub segment: running journeys or the shelf (ended + archived).
enum HubSegment { active, shelf, shared }

/// **Global Hub** (`/journeys`, Ourney V1.0 design):
///
/// * greeting + "N journeys still need today's photo",
/// * the **Today card** for the next journey without a photo today, drawn in
///   that journey's style (paper, ink, accent) with the last seven days and
///   a "Snap today" button; an "All done" row once everything is posted,
/// * "Your journeys" with an Active / Shelf segmented control and flat rows
///   (thumbnail, style dot + name, streak, today status, visibility).
///
/// The shell around it stays on the neutral editorial base
/// (`editorialNeutralBase`); only the Today card takes a persona's colors.
class JourneysListScreen extends ConsumerStatefulWidget {
  const JourneysListScreen({super.key});

  static Future<void> startCreate(BuildContext context, JourneyBuckets b) {
    if (!b.canCreate) return showJourneyLimitDialog(context);
    return context.push(AppRoutes.journeyNew);
  }

  @override
  ConsumerState<JourneysListScreen> createState() => _JourneysListState();
}

class _JourneysListState extends ConsumerState<JourneysListScreen> {
  HubSegment _segment = HubSegment.active;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final journeys = ref.watch(journeysListProvider);

    if (journeys.hasError && isNotWired(journeys.error!)) {
      // Data layer (B1) not wired yet.
      return PlaceholderScreen(id: 'journeys', title: l10n.journeys_title);
    }

    final buckets = journeys.hasValue ? JourneyBuckets(journeys.value!) : null;

    final Widget body;
    if (buckets != null) {
      body = buckets.isEmpty
          ? EmptyState(
              key: const ValueKey('journeys-empty'),
              icon: Icons.route_rounded,
              title: l10n.journeys_emptyTitle,
              message: l10n.journeys_emptyMessage,
              actionLabel: l10n.journeys_newJourney,
              onAction: () => JourneysListScreen.startCreate(context, buckets),
            )
          : _HubBody(
              buckets: buckets,
              segment: _segment,
              onSegment: (s) => setState(() => _segment = s),
            );
    } else if (journeys.hasError) {
      body = EmptyState(
        key: const ValueKey('journeys-error'),
        icon: Icons.error_outline_rounded,
        title: l10n.journeys_loadError,
        message: journeyErrorMessage(context, journeys.error!),
        actionLabel: AppLocalizations.of(context).common_retry,
        onAction: () => ref.invalidate(journeysListProvider),
      );
    } else {
      body = Center(
        child: CircularProgressIndicator(
          semanticsLabel: AppLocalizations.of(context).common_loading,
        ),
      );
    }

    final baseTheme = Theme.of(context);
    final neutralPersona = OurneyPersonaTheme.editorialNeutralBase(
      baseTheme.brightness,
    );

    return Theme(
      data: baseTheme.copyWith(
        scaffoldBackgroundColor: neutralPersona.background,
        extensions: [
          for (final e in baseTheme.extensions.values)
            if (e is! OurneyPersonaTheme) e,
          neutralPersona,
        ],
      ),
      child: Scaffold(
        key: const ValueKey('journeys-list'),
        backgroundColor: neutralPersona.background,
        body: SafeArea(
          bottom: false,
          child: buckets == null || buckets.isEmpty
              ? Column(
                  children: [
                    const _HubHeader(onAdd: null),
                    Expanded(child: body),
                  ],
                )
              : body,
        ),
      ),
    );
  }
}

/// Horizontal page padding for the hub (CLAUDE.md §3 width classes).
double _hubPadding(BuildContext context) =>
    OurneyLayout.horizontalPadding(MediaQuery.sizeOf(context).width);

/// Greeting row: "Good evening, Linh" · add · profile avatar.
class _HubHeader extends ConsumerWidget {
  const _HubHeader({required this.onAdd});

  /// Null hides the add button (empty hub: the empty state offers it).
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    final now = ref.watch(journeysClockProvider).now();
    final greeting = now.hour < 12
        ? l10n.journeys_greetingMorning
        : now.hour < 18
        ? l10n.journeys_greetingAfternoon
        : l10n.journeys_greetingEvening;
    final name = ref.watch(myProfileProvider).value?.displayName.trim();
    final first = name == null || name.isEmpty
        ? null
        : name.split(RegExp(r'\s+')).last;
    final pad = _hubPadding(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, OurneySpacing.md, pad - 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                first == null
                    ? greeting
                    : l10n.journeys_greetingNamed(greeting, first),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(height: 1.3),
              ),
            ),
          ),
          if (onAdd != null)
            IconButton(
              key: const ValueKey('journeys-new'),
              tooltip: l10n.journeys_addJourney,
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
            ),
          const InboxButton(),
          const ProfileButton(),
        ],
      ),
    );
  }
}

/// Progress of every running journey, watched together so the hub can
/// count what is left for today and pick the Today card.
class _HubBody extends ConsumerWidget {
  const _HubBody({
    required this.buckets,
    required this.segment,
    required this.onSegment,
  });

  final JourneyBuckets buckets;
  final HubSegment segment;
  final ValueChanged<HubSegment> onSegment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    final now = ref.watch(journeysClockProvider).now();
    final progress = <String, JourneyProgress>{};
    for (final j in buckets.active) {
      final checkIns = ref.watch(myCheckInsProvider(j.id));
      if (!checkIns.hasValue) continue;
      progress[j.id] = JourneyProgress.compute(
        journey: j,
        membership: ref.watch(myMembershipProvider(j.id)).value,
        checkIns: checkIns.value!,
        now: now,
      );
    }
    final pending = [
      for (final j in buckets.active)
        if (progress[j.id] case final p? when !p.checkedInToday) p,
    ];
    final known = progress.length == buckets.active.length;
    final activeId =
        ref.watch(activeJourneyProvider).value?.id ??
        ref.watch(activeJourneyIdProvider);
    final next = pending.isEmpty
        ? null
        : pending.firstWhere(
            (p) => p.journey.id == activeId,
            orElse: () => pending.first,
          );
    final allDone = known && buckets.active.isNotEmpty && pending.isEmpty;
    final pad = _hubPadding(context);
    final text = Theme.of(context).textTheme;
    final c = OurneyColors.of(context);

    final rows = segment == HubSegment.active
        ? buckets.active
        : buckets.finished;
    final online = !ref.watch(appConfigProvider).localOnly;

    return OurneyResponsiveBody(
      applyHorizontalPadding: false,
      child: ListView(
        padding: EdgeInsets.only(bottom: OurneySpacing.xxl * 2),
        children: [
          _HubHeader(
            onAdd: () => JourneysListScreen.startCreate(context, buckets),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 2, pad, 18),
            child: Text(
              key: const ValueKey('journeys-hub-prompt'),
              allDone
                  ? l10n.journeys_allDonePrompt
                  : l10n.journeys_remainingToday(pending.length),
              style: text.bodyMedium?.copyWith(
                color: c.inkMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          if (next != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: TodayCard(progress: next),
            )
          else if (allDone)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: _AllDoneRow(count: buckets.active.length),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, OurneySpacing.xl, pad, 8),
            child: Semantics(
              header: true,
              child: Text(
                l10n.journeys_yourJourneys,
                style: headingStyle(size: 18, color: c.ink),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 0, pad, OurneySpacing.md),
            child: HubSegments(
              value: segment,
              onChanged: onSegment,
              labels: {
                HubSegment.active:
                    '${l10n.journeys_activeSection} · '
                    '${buckets.activeCount}/$maxActiveJourneys',
                HubSegment.shelf: l10n.journeys_finishedSection,
                if (online) HubSegment.shared: l10n.journeys_sharedSection,
              },
            ),
          ),
          if (segment == HubSegment.shared)
            const SharedWithMeList(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
            )
          else if (rows.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad, vertical: 24),
              child: Text(
                segment == HubSegment.active
                    ? l10n.journeys_activeEmpty
                    : l10n.journeys_shelfEmpty,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: c.inkMuted),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.divider)),
                ),
                child: Column(
                  children: [
                    for (final j in rows)
                      JourneyCard(
                        journey: j,
                        hideStreak: next?.journey.id == j.id,
                      ),
                  ],
                ),
              ),
            ),
          if (segment == HubSegment.shelf && online)
            Padding(
              padding: EdgeInsets.fromLTRB(pad, OurneySpacing.md, pad, 0),
              child: OutlinedButton.icon(
                key: const ValueKey('journeys-retell'),
                onPressed: () => context.push(AppRoutes.retell),
                icon: const Icon(Icons.history_edu_rounded),
                label: Text(l10n.journeys_retell),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pill-shaped segmented control (V1.0 `.segments`): sunken track, the
/// selected segment raised on a surface with a soft shadow.
class HubSegments extends StatelessWidget {
  const HubSegments({
    required this.value,
    required this.onChanged,
    required this.labels,
    super.key,
  });

  final HubSegment value;
  final ValueChanged<HubSegment> onChanged;
  final Map<HubSegment, String> labels;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(OurneyRadii.capsule),
      ),
      child: Row(
        children: [
          for (final s in labels.keys)
            Expanded(
              child: Semantics(
                button: true,
                selected: s == value,
                child: GestureDetector(
                  key: ValueKey('hub-segment-${s.name}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: s == value ? c.surfaceRaised : Colors.transparent,
                      borderRadius: BorderRadius.circular(OurneyRadii.capsule),
                      boxShadow: s == value
                          ? const [
                              BoxShadow(
                                color: Color(0x0D111114),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      labels[s]!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: kBodyFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: c.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AllDoneRow extends StatelessWidget {
  const _AllDoneRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final c = OurneyColors.of(context);
    return Container(
      key: const ValueKey('journeys-all-done'),
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: OurneySpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.successSoft,
            ),
            child: Icon(Icons.check_rounded, size: 18, color: c.onSuccessSoft),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.journeys_allDoneTitle,
              style: TextStyle(
                fontFamily: kBodyFont,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: c.ink,
              ),
            ),
          ),
          Text(
            '$count/$count',
            style: TextStyle(
              fontFamily: kBodyFont,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// The hub's hero: the next journey still waiting for today's photo, in its
/// own style. Square, outlined, editorial (V1.0 `.hub-today-card`).
class TodayCard extends ConsumerWidget {
  const TodayCard({required this.progress, super.key});

  final JourneyProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    final journey = progress.journey;
    final brightness = Theme.of(context).brightness;
    final skin = personaSkinOf(journey);
    final style = OurneyPersonaTheme.forSkin(skin, brightness);
    final dark = brightness == Brightness.dark;
    // Dark mode: every style shares the same near-black card (V1.0).
    final bg = dark ? const Color(0xFF0E0E10) : style.background;
    final ink = dark ? const Color(0xFFF4F4F5) : style.ink;
    final c = OurneyColors.of(context);
    final latest = _latestCheckIn(progress);
    final dayText = progress.totalDays == null
        ? l10n.journeys_dayOpen(progress.dayNumber)
        : l10n.journeys_dayShort(progress.dayNumber, progress.totalDays!);
    final status = _deadlineText(
      l10n,
      progress,
      ref.watch(journeysClockProvider).now(),
    );

    TextStyle label(double size, {double opacity = 1}) => TextStyle(
      fontFamily: kBodyFont,
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.3,
      letterSpacing: size * 0.08,
      color: ink.withValues(alpha: opacity),
    );

    return AnimatedContainer(
      key: ValueKey('journeys-today-${journey.id}'),
      duration: OurneyDurations.personaTheme,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: ink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(l10n.journeys_todayLabel.toUpperCase(), style: label(10)),
              const Spacer(),
              Flexible(
                child: Text(
                  personaStyleName(skin).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: label(10, opacity: 0.72),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Container(
            height: 148,
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              border: Border.all(color: ink),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (latest != null)
                  JourneyPhoto(checkIn: latest, thumbnail: false)
                else
                  ColoredBox(
                    color: style.primaryAccent.withValues(alpha: 0.28),
                    child: Icon(
                      journeyIcon(journey.emoji, journey.templateId),
                      size: 44,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.45, 1],
                      colors: [Color(0x00000000), Color(0xCC000000)],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          journey.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: displayStyle(
                            size: 20,
                            weight: 700,
                            height: 1.25,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dayText,
                        style: const TextStyle(
                          fontFamily: kBodyFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(minHeight: 42),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: ink.withValues(alpha: 0.28)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 17,
                  color: c.flame,
                ),
                const SizedBox(width: 5),
                Text(
                  '${progress.summary.current}',
                  style: TextStyle(
                    fontFamily: kBodyFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  l10n.journeys_streakWord,
                  style: TextStyle(
                    fontFamily: kBodyFont,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: ink.withValues(alpha: 0.72),
                  ),
                ),
                const Spacer(),
                if (status != null)
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: dark
                              ? const Color(0xFFFF9A62)
                              : const Color(0xFFB33A0A),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: kBodyFont,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: dark
                                  ? const Color(0xFFFF9A62)
                                  : const Color(0xFFB33A0A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          WeekStrip(progress: progress, ink: ink),
          OurneyPrimaryButton(
            key: const ValueKey('journeys-snap-today'),
            label: l10n.journeys_snapToday,
            icon: Icons.photo_camera_outlined,
            backgroundColor: style.primaryAccent,
            foregroundColor: readableOn(style.primaryAccent),
            onPressed: () {
              unawaited(
                ref.read(activeJourneyIdProvider.notifier).select(journey.id),
              );
              unawaited(
                JourneyDetailScreen.checkInNow(context, ref, journey.id),
              );
            },
          ),
        ],
      ),
    );
  }

  static CheckIn? _latestCheckIn(JourneyProgress p) {
    CheckIn? latest;
    for (final c in p.checkInsByDate.values) {
      if (latest == null || c.localDate.isAfter(latest.localDate)) latest = c;
    }
    return latest;
  }

  /// "Starts today" on day 1, otherwise the time left before the journey's
  /// local midnight ("Ends in 3h").
  static String? _deadlineText(
    JourneysL10n l10n,
    JourneyProgress p,
    DateTime now,
  ) {
    if (p.journey.startDate == p.today && p.summary.current == 0) {
      return l10n.journeys_startsToday;
    }
    final offset = utcOffsetIn(p.journey.timezone, now);
    final local = now.toUtc().add(offset);
    final minutesLeft = (24 * 60) - (local.hour * 60 + local.minute);
    final hours = minutesLeft ~/ 60;
    return hours < 1
        ? l10n.journeys_endsSoon
        : l10n.journeys_endsInHours(hours);
  }
}

/// The last seven days of a journey, oldest first, today last: photo cells
/// with a check badge, a dashed camera cell for today, hairline empty cells
/// for missed days and nothing before the journey started.
class WeekStrip extends StatelessWidget {
  const WeekStrip({required this.progress, required this.ink, super.key});

  final JourneyProgress progress;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = progress.today;
    final weekday = DateFormat.E(locale);
    return Semantics(
      label: l10n.journeys_lastSevenDays,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 11, 0, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 6; i >= 0; i--) ...[
              Expanded(
                child: _DayCell(
                  date: today.addDays(-i),
                  isToday: i == 0,
                  label: i == 0
                      ? l10n.journeys_todayLabel
                      : weekday.format(displayDate(today.addDays(-i))),
                  checkIn: progress.checkInsByDate[today.addDays(-i)],
                  beforeStart: today.addDays(-i).isBefore(progress.memberStart),
                  ink: ink,
                ),
              ),
              if (i > 0) const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isToday,
    required this.label,
    required this.checkIn,
    required this.beforeStart,
    required this.ink,
  });

  final LocalDate date;
  final bool isToday;
  final String label;
  final CheckIn? checkIn;
  final bool beforeStart;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final Widget cell;
    if (checkIn != null) {
      cell = Container(
        decoration: BoxDecoration(border: Border.all(color: ink)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            JourneyPhoto(checkIn: checkIn!, cacheWidth: 120),
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                width: 12,
                height: 12,
                color: ink,
                child: Icon(
                  Icons.check_rounded,
                  size: 9,
                  color: ink.computeLuminance() > 0.5
                      ? const Color(0xFF0E0E10)
                      : Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (isToday) {
      cell = CustomPaint(
        painter: _DashedBorderPainter(ink),
        child: Center(
          child: Icon(Icons.photo_camera_outlined, size: 14, color: ink),
        ),
      );
    } else if (beforeStart) {
      cell = const SizedBox.shrink();
    } else {
      cell = DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: ink.withValues(alpha: 0.35)),
        ),
      );
    }
    final small = TextStyle(
      fontFamily: kBodyFont,
      fontSize: 8,
      fontWeight: FontWeight.w700,
      height: 1.2,
      color: isToday ? ink : ink.withValues(alpha: 0.72),
    );
    return ExcludeSemantics(
      child: Column(
        children: [
          SizedBox(
            height: 20,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: small,
              ),
            ),
          ),
          const SizedBox(height: 4),
          AspectRatio(aspectRatio: 1, child: cell),
          const SizedBox(height: 4),
          Text(
            '${date.day}',
            style: TextStyle(
              fontFamily: kBodyFont,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dash = 3.0;
    const gap = 2.0;
    void line(Offset a, Offset b) {
      final length = (b - a).distance;
      final dir = (b - a) / length;
      for (var d = 0.0; d < length; d += dash + gap) {
        final end = d + dash > length ? length : d + dash;
        canvas.drawLine(a + dir * d, a + dir * end, paint);
      }
    }

    final r = Offset.zero & size;
    line(r.topLeft, r.topRight);
    line(r.topRight, r.bottomRight);
    line(r.bottomRight, r.bottomLeft);
    line(r.bottomLeft, r.topLeft);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

/// One journey row on the hub (V1.0 `.journey-row`): 66dp thumbnail (latest
/// photo, or the journey icon on its style color), title, style dot + name,
/// then streak, today status (icon + word, not color only) and visibility.
class JourneyCard extends ConsumerWidget {
  const JourneyCard({
    required this.journey,
    this.hideStreak = false,
    super.key,
  });

  final Journey journey;

  /// The Today card already shows this journey's streak.
  final bool hideStreak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = JourneysL10n.of(context);
    final app = AppLocalizations.of(context);
    final c = OurneyColors.of(context);
    final brightness = Theme.of(context).brightness;
    final membership = ref.watch(myMembershipProvider(journey.id));
    final checkIns = ref.watch(myCheckInsProvider(journey.id));
    final progress = checkIns.hasValue
        ? JourneyProgress.compute(
            journey: journey,
            membership: membership.value,
            checkIns: checkIns.value!,
            now: ref.watch(journeysClockProvider).now(),
          )
        : null;
    final active = journey.status == JourneyStatus.active;
    final skin = personaSkinOf(journey);
    final style = OurneyPersonaTheme.forSkin(skin, brightness);
    final latest = progress == null ? null : TodayCard._latestCheckIn(progress);

    final dayText = progress == null
        ? null
        : (progress.totalDays == null
              ? l10n.journeys_dayOpen(progress.dayNumber)
              : l10n.journeys_dayOf(progress.dayNumber, progress.totalDays!));
    final done = active && (progress?.checkedInToday ?? false);
    final statusText = switch (journey.status) {
      JourneyStatus.active =>
        progress == null
            ? null
            : (done ? l10n.journeys_rowDone : l10n.journeys_rowNotYet),
      JourneyStatus.ended => l10n.journeys_statusEnded,
      JourneyStatus.archived => l10n.journeys_statusArchived,
    };
    final statusSemantics = switch (journey.status) {
      JourneyStatus.active =>
        done ? l10n.journeys_checkedToday : l10n.journeys_notCheckedToday,
      _ => statusText,
    };
    final (
      IconData privacyIcon,
      String privacyText,
    ) = switch (journey.visibility) {
      JourneyVisibility.private => (
        Icons.lock_outline_rounded,
        l10n.journeys_privacyPrivate,
      ),
      JourneyVisibility.link => (Icons.link_rounded, l10n.journeys_privacyLink),
      JourneyVisibility.group => (
        Icons.people_outline_rounded,
        l10n.journeys_privacyGroup,
      ),
    };

    final meta = TextStyle(
      fontFamily: kBodyFont,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.35,
      color: c.inkMuted,
    );

    return Semantics(
      button: true,
      label: [
        journey.title,
        personaStyleName(skin),
        ?dayText,
        ?statusSemantics,
        if (progress != null && !hideStreak)
          app.streak_semantics(progress.summary.current),
        privacyText,
      ].join(', '),
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('journey-card-${journey.id}'),
        onTap: () {
          if (active) {
            unawaited(
              ref.read(activeJourneyIdProvider.notifier).select(journey.id),
            );
          }
          context.push(AppRoutes.journey(journey.id));
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 94),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.divider)),
          ),
          child: Row(
            children: [
              ClipRRect(
                key: ValueKey('journey-badge-${journey.id}'),
                borderRadius: BorderRadius.circular(OurneyRadii.thumb),
                child: SizedBox.square(
                  dimension: 66,
                  child: latest != null
                      ? JourneyPhoto(checkIn: latest, cacheWidth: 200)
                      : ColoredBox(
                          color: brightness == Brightness.dark
                              ? style.surfaceElevated
                              : style.background,
                          child: Icon(
                            journeyIcon(journey.emoji, journey.templateId),
                            size: 28,
                            color: style.ink,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      journey.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: kBodyFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: style.primaryAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            [
                              personaStyleName(skin),
                              ?dayText,
                              if (journey.origin == JourneyOrigin.imported)
                                l10n.journeys_imported,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: meta,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 10,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (progress != null && active && !hideStreak)
                          _Meta(
                            icon: Icons.local_fire_department_rounded,
                            iconColor: c.flame,
                            text: '${progress.summary.current}',
                            style: meta,
                          ),
                        if (statusText != null)
                          _Meta(
                            key: ValueKey('journey-status-${journey.id}'),
                            icon: !active
                                ? Icons.flag_outlined
                                : done
                                ? Icons.check_rounded
                                : Icons.circle_outlined,
                            iconColor: done ? c.success : c.inkMuted,
                            text: statusText,
                            style: done
                                ? meta.copyWith(color: c.success)
                                : meta,
                          ),
                        _Meta(
                          icon: privacyIcon,
                          iconColor: c.inkMuted,
                          text: privacyText,
                          style: meta,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, size: 20, color: c.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.style,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 3),
        Text(text, style: style),
      ],
    );
  }
}
