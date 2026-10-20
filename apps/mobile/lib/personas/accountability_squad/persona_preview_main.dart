import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/config.dart';
import '../../app/localization.dart';
import '../../app/providers.dart';
import '../../app/theme/persona_theme.dart';
import '../../features/groups/data/groups_providers.dart';
import '../../features/groups/domain/group_today.dart';
import '../../features/journeys/domain/journey_progress.dart';
import '../memory_collectors/camera_hud.dart';
import '../memory_collectors/l10n/generated/memory_collectors_localizations.dart';
import '../memory_collectors/share_card.dart';
import '../memory_collectors/timeline.dart';
import 'camera_hud.dart';
import 'l10n/generated/accountability_squad_localizations.dart';
import 'persona_preview_chrome.dart';
import 'persona_preview_scenes.dart';
import 'share_card.dart';
import 'timeline.dart';

void main() {
  // Root scope (riverpod_lint requires one); the harness re-scopes the app
  // config and group data below so each toggle gets fresh providers.
  runApp(const ProviderScope(child: PersonaPreviewApp()));
}

enum _PreviewScreen {
  s1Timeline('S1 · Stepping Stone'),
  s2Camera('S2 · Study Timer HUD'),
  s3Squad('S3 · Squad Polaroid Wall'),
  m1Timeline('M1 · Scrapbook Thread'),
  m2Camera('M2 · Film Stamp HUD'),
  m3Share('M3 · 35mm Contact Sheet');

  const _PreviewScreen(this.label);
  final String label;
}

/// Interactive preview harness for all 6 screens owned by `@nguyenductien-qnm`
/// (`S1`–`S3` in `accountability_squad` and `M1`–`M3` in `memory_collectors`).
class PersonaPreviewApp extends StatefulWidget {
  const PersonaPreviewApp({super.key});

  @override
  State<PersonaPreviewApp> createState() => _PersonaPreviewAppState();
}

class _PersonaPreviewAppState extends State<PersonaPreviewApp> {
  // `--dart-define=SCREEN=s2Camera --dart-define=DARK=true --dart-define=LOCALE=en`
  // opens a given screen directly (handy for screenshots).
  _PreviewScreen _screen = _PreviewScreen.values.firstWhere(
    (e) => e.name == const String.fromEnvironment('SCREEN'),
    orElse: () => _PreviewScreen.s1Timeline,
  );
  Brightness _brightness = const bool.fromEnvironment('DARK')
      ? Brightness.dark
      : Brightness.light;
  Locale _locale = Locale(
    const String.fromEnvironment('LOCALE', defaultValue: 'vi'),
  );
  bool _localOnlyMode = false;
  bool _m3GroupMode = false;
  bool _s2HasMetric = true;

  bool get _isMemoryPersona =>
      _screen == _PreviewScreen.m1Timeline ||
      _screen == _PreviewScreen.m2Camera ||
      _screen == _PreviewScreen.m3Share;

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.forSkin(
      _isMemoryPersona
          ? PersonaSkinId.memoryCollectors
          : PersonaSkinId.accountabilitySquad,
      _brightness,
    );

    final config = _localOnlyMode
        ? const AppConfig(supabaseUrl: '', supabaseAnonKey: '')
        : const AppConfig(
            supabaseUrl: 'https://example.supabase.co',
            supabaseAnonKey: 'anon',
          );

    return ProviderScope(
      overrides: [
        // The providers below are intentionally re-scoped per toggle in this
        // dev-only harness, so they declare no `dependencies`.
        // ignore: riverpod_lint/scoped_providers_should_specify_dependencies
        appConfigProvider.overrideWithValue(config),
        // ignore: riverpod_lint/scoped_providers_should_specify_dependencies
        currentUserIdProvider.overrideWithValue('u-1'),
        groupBlockedIdsProvider.overrideWith((ref) => Stream.value(const {})),
        for (var i = 1; i <= 5; i++)
          groupReactionsProvider('ci-u-$i').overrideWith(
            (ref) => Stream.value([
              Reaction(
                checkInId: 'ci-u-$i',
                userId: 'u-2',
                emoji: '🔥',
                createdAt: DateTime.utc(2026, 10, 19),
              ),
              Reaction(
                checkInId: 'ci-u-$i',
                userId: 'u-3',
                emoji: '👏',
                createdAt: DateTime.utc(2026, 10, 19),
              ),
            ]),
          ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: _locale,
        localizationsDelegates: const [
          ...ourneyLocalizationsDelegates,
          AccountabilitySquadL10n.delegate,
          MemoryCollectorsL10n.delegate,
        ],
        supportedLocales: ourneySupportedLocales,
        theme: pTheme.toThemeData(_brightness),
        home: Scaffold(
          backgroundColor: pTheme.background,
          appBar: AppBar(
            toolbarHeight: 44,
            backgroundColor: pTheme.surface,
            foregroundColor: pTheme.ink,
            elevation: 0,
            titleSpacing: 12,
            // One tap opens the list of all six screens; the bar replaces the
            // old row of chips that ate a third of the preview.
            title: PopupMenuButton<_PreviewScreen>(
              tooltip: 'Chọn màn hình',
              initialValue: _screen,
              position: PopupMenuPosition.under,
              color: pTheme.surface,
              onSelected: (v) => setState(() => _screen = v),
              itemBuilder: (_) => [
                for (final item in _PreviewScreen.values)
                  CheckedPopupMenuItem<_PreviewScreen>(
                    value: item,
                    checked: item == _screen,
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: pTheme.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _screen.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: pTheme.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down_rounded, color: pTheme.ink),
                ],
              ),
            ),
            actions: [
              if (_hasOption)
                PopupMenuButton<VoidCallback>(
                  tooltip: 'Tuỳ chọn',
                  icon: Icon(Icons.tune_rounded, color: pTheme.ink),
                  color: pTheme.surface,
                  onSelected: (run) => run(),
                  itemBuilder: (_) => _optionItems(pTheme),
                ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _locale = _locale.languageCode == 'vi'
                        ? const Locale('en')
                        : const Locale('vi');
                  });
                },
                child: Text(
                  _locale.languageCode.toUpperCase(),
                  style: TextStyle(
                    color: pTheme.primaryAccent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Dark / Light',
                onPressed: () {
                  setState(() {
                    _brightness = _brightness == Brightness.light
                        ? Brightness.dark
                        : Brightness.light;
                  });
                },
                icon: Icon(
                  _brightness == Brightness.light
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  color: pTheme.ink,
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: KeyedSubtree(
                    key: ValueKey(
                      '${_screen.name}-${_brightness.name}-${_locale.languageCode}-$_localOnlyMode-$_m3GroupMode-$_s2HasMetric',
                    ),
                    child: _buildActiveScreen(pTheme),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Per-screen switches live in the app bar's tune menu, not on the page.
  bool get _hasOption =>
      _screen == _PreviewScreen.s2Camera ||
      _screen == _PreviewScreen.s3Squad ||
      _screen == _PreviewScreen.m3Share;

  List<PopupMenuEntry<VoidCallback>> _optionItems(OurneyPersonaTheme pTheme) {
    final style = TextStyle(color: pTheme.ink, fontWeight: FontWeight.w700);
    switch (_screen) {
      case _PreviewScreen.s2Camera:
        return [
          CheckedPopupMenuItem<VoidCallback>(
            value: () => setState(() => _s2HasMetric = !_s2HasMetric),
            checked: _s2HasMetric,
            child: Text('Có chỉ số: 45 phút', style: style),
          ),
        ];
      case _PreviewScreen.s3Squad:
        return [
          CheckedPopupMenuItem<VoidCallback>(
            value: () => setState(() => _localOnlyMode = !_localOnlyMode),
            checked: _localOnlyMode,
            child: Text('Chế độ không máy chủ', style: style),
          ),
        ];
      case _PreviewScreen.m3Share:
        return [
          CheckedPopupMenuItem<VoidCallback>(
            value: () => setState(() => _m3GroupMode = !_m3GroupMode),
            checked: _m3GroupMode,
            child: Text('Hành trình nhóm (ẩn link)', style: style),
          ),
        ];
      case _PreviewScreen.s1Timeline:
      case _PreviewScreen.m1Timeline:
      case _PreviewScreen.m2Camera:
        return const [];
    }
  }

  Widget _buildActiveScreen(OurneyPersonaTheme pTheme) {
    switch (_screen) {
      case _PreviewScreen.s1Timeline:
        return _withDock(
          SteppingStoneQuestTimeline(
            journey: _sampleSquadJourney(),
            days: _sampleSquadDays(),
            photoBuilder: (_, d) => SampleScene(
              SampleScene.studyKind(d.dayNumber),
              seed: d.dayNumber,
            ),
          ),
          const PreviewTabDock(),
        );
      case _PreviewScreen.s2Camera:
        return ColoredBox(
          color: Colors.black,
          child: Column(
            children: [
              Expanded(
                child: StudyTimerSnapHud(
                  journey: _sampleSquadJourney(withMetric: _s2HasMetric),
                  streak: 21,
                  metricValue: _s2HasMetric ? 45 : null,
                  capturedAt: DateTime(2026, 10, 16, 6, 15),
                  borderRadius: 0,
                  viewfinderChild: const SampleScene(
                    SampleSceneKind.desk,
                    seed: 3,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const PreviewTabDock(
                dark: true,
                center: PreviewShutter(color: Color(0xFFFF5A5F)),
              ),
            ],
          ),
        );
      case _PreviewScreen.s3Squad:
        return _withDock(
          SquadPolaroidWall(
            journey: _sampleSquadJourney(),
            members: _sampleSquadMembers(),
            onNudge: (_) {},
            photoBuilder: (_, entry) => SampleScene(
              SampleScene.studyKind(entry.member.userId.hashCode),
              seed: entry.member.userId.hashCode,
            ),
          ),
          const PreviewTabDock(),
        );
      case _PreviewScreen.m1Timeline:
        return _withDock(
          ScrapbookThreadTimeline(
            journey: _sampleMemoryJourney(durationDays: 5),
            days: _sampleMemoryDays(),
            photoBuilder: (_, d) => SampleScene(
              SampleScene.travelKind(d.dayNumber - 1),
              seed: d.dayNumber,
            ),
          ),
          const PreviewTabDock(
            leftIcon: Icons.map_outlined,
            centerIcon: Icons.photo_camera_outlined,
          ),
        );
      case _PreviewScreen.m2Camera:
        return DisposableFilmStampHud(
          journey: _sampleMemoryJourney(durationDays: 36),
          checkInCount: 24,
          date: const LocalDate(2026, 10, 16),
          viewfinderChild: const SampleScene(SampleSceneKind.group, seed: 5),
          bottomBar: const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: PreviewShutter(
              color: Color(0xFFD95338),
              ring: Color(0xFFF4EFE6),
            ),
          ),
        );
      case _PreviewScreen.m3Share:
        final journey = _sampleMemoryJourney(
          kind: _m3GroupMode ? JourneyKind.group : JourneyKind.solo,
        );
        return _withDock(
          FilmContactSheetShareCard(
            journey: journey,
            checkIns: _sampleMemoryCheckIns(15),
            onSharePoster: () {},
            photoBuilder: (_, c) => SampleScene(
              SampleScene.travelKind(c.localDate.day - 1),
              seed: c.localDate.day,
            ),
            publicLinkSection: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: pTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: pTheme.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.link_rounded, color: pTheme.primaryAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'https://ourney.app/s/da-lat-2026 (Solo public link)',
                      style: TextStyle(
                        color: pTheme.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const PreviewTabDock(
            leftIcon: Icons.map_outlined,
            middleLabel: '3-tab',
            middleIcon: Icons.web_asset_outlined,
          ),
        );
    }
  }

  Widget _withDock(Widget body, Widget dock) => Column(
    children: [
      Expanded(child: body),
      dock,
    ],
  );
}

Journey _sampleSquadJourney({bool withMetric = true}) {
  return Journey(
    id: 'squad-j1',
    ownerId: 'u-1',
    title: 'IELTS 7.5 Squad',
    emoji: '🔥',
    templateId: TemplateId.englishDaily,
    kind: JourneyKind.group,
    startDate: const LocalDate(2026, 10, 1),
    durationDays: 30,
    timezone: 'Asia/Ho_Chi_Minh',
    visibility: JourneyVisibility.group,
    status: JourneyStatus.active,
    metricName: withMetric ? 'Thời gian học' : null,
    metricUnit: withMetric ? 'phút' : null,
  );
}

List<TimelineDay> _sampleSquadDays() {
  const start = LocalDate(2026, 10, 1);
  return List<TimelineDay>.generate(30, (idx) {
    final dayNumber = idx + 1;
    final date = start.addDays(idx);
    final DayState state;
    CheckIn? checkIn;
    if (dayNumber <= 21) {
      state = dayNumber == 21 ? DayState.today : DayState.checkedIn;
      checkIn = CheckIn(
        id: 'sq-c-$dayNumber',
        journeyId: 'squad-j1',
        userId: 'u-1',
        localDate: date,
        capturedAt: DateTime(2026, 10, dayNumber, 6, 15),
        photoPath: 'local/sq_$dayNumber.jpg',
        thumbPath: 'local/sq_${dayNumber}_t.jpg',
        metricValue: 45,
        uploaded: true,
      );
    } else {
      state = DayState.future;
    }
    return TimelineDay(
      dayNumber: dayNumber,
      date: date,
      isToday: dayNumber == 21,
      state: state,
      checkIn: checkIn,
    );
  });
}

List<GroupMemberEntry> _sampleSquadMembers() {
  const names = ['Linh', 'Nam', 'Hà', 'Trang', 'Minh'];
  return [
    for (var i = 0; i < names.length; i++)
      () {
        final done = i < 4;
        final uid = 'u-${i + 1}';
        final checkIn = done
            ? CheckIn(
                id: 'ci-$uid',
                journeyId: 'squad-j1',
                userId: uid,
                localDate: const LocalDate(2026, 10, 19),
                capturedAt: DateTime(2026, 10, 19, 6, 10 + i * 5),
                photoPath: 'local/$uid.jpg',
                thumbPath: 'local/${uid}_t.jpg',
                uploaded: true,
              )
            : null;
        return GroupMemberEntry(
          member: MemberToday(
            userId: uid,
            displayName: names[i],
            role: i == 0 ? MemberRole.owner : MemberRole.member,
            todayCheckIn: checkIn,
            currentStreak: done ? 21 : 5,
          ),
          isMe: i == 0,
          checkedInToday: done,
          streak: done ? 21 : 5,
          photo: checkIn,
          photoIsToday: done,
        );
      }(),
  ];
}

Journey _sampleMemoryJourney({
  int durationDays = 12,
  JourneyKind kind = JourneyKind.solo,
}) {
  return Journey(
    id: 'mem-j1',
    ownerId: 'u-1',
    title: 'Da Lat Trip',
    emoji: '✈️',
    templateId: TemplateId.travel,
    kind: kind,
    startDate: const LocalDate(2026, 10, 1),
    durationDays: durationDays,
    timezone: 'Asia/Ho_Chi_Minh',
    visibility: defaultVisibilityFor(kind),
    status: JourneyStatus.active,
  );
}

List<CheckIn> _sampleMemoryCheckIns(int count) {
  const start = LocalDate(2026, 10, 1);
  const captions = [
    'Rừng thông bình minh',
    'Săn mây Cầu Đất',
    'Đêm lửa trại cùng hội bạn',
    'Cà phê Tùng sáng sớm',
    'Dốc Nhà Bò chiều tà',
    'Hồ Tuyền Lâm tĩnh lặng',
  ];
  return List<CheckIn>.generate(count, (idx) {
    final dayNumber = idx + 1;
    final date = start.addDays(idx);
    return CheckIn(
      id: 'mem-c-$dayNumber',
      journeyId: 'mem-j1',
      userId: 'u-1',
      localDate: date,
      capturedAt: DateTime(2026, 10, 1, 7, 30),
      photoPath: 'local/mem_$dayNumber.jpg',
      thumbPath: 'local/mem_${dayNumber}_t.jpg',
      caption: captions[idx % captions.length],
      uploaded: true,
    );
  });
}

List<TimelineDay> _sampleMemoryDays() {
  final checkIns = _sampleMemoryCheckIns(4);
  return List<TimelineDay>.generate(checkIns.length, (idx) {
    final c = checkIns[idx];
    return TimelineDay(
      dayNumber: idx + 1,
      date: c.localDate,
      isToday: idx == 3,
      state: idx == 3 ? DayState.today : DayState.checkedIn,
      checkIn: c,
    );
  });
}
