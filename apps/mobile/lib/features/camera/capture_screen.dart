import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/app_dock.dart';
import '../../app/app_routes.dart';
import '../../app/providers.dart';
import '../../app/theme/motion.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../personas/persona_contract.dart' show personaSkinOf;
import '../../ui/ui.dart';
import '../checkin/captured_photo.dart';
import '../journeys/data/journeys_providers.dart';
import '../journeys/domain/journey_progress.dart';
import '../profile/profile_entry_button.dart';
import 'camera_providers.dart';
import 'camera_session.dart';
import 'capture_services.dart';
import 'l10n/generated/camera_localizations.dart';

enum _Phase { idle, prePrompt, starting, ready, failure }

/// `/capture`: the app's start screen (FR-C1, App.tsx `CameraScreen`).
/// Journey chips (remembering the last one), viewfinder with the day pill,
/// flash (FR-C2), grid, library pick (FR-C3), front/back switch and the hero
/// shutter in the dark camera dock. The OS permission is requested in
/// context after a friendly pre-prompt; a denied state links to Settings.
///
/// Performance (NFR-1): the camera starts from `didChangeDependencies` of the
/// first build, in parallel with the journey stream; nothing else heavy runs
/// on the first frame. It is released whenever the screen is not visible
/// (other tab, `/checkin` on top: `TickerMode` off) or the app is hidden.
/// Switching journey only changes chrome; the session is never restarted.
class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({this.initialJourneyId, super.key});

  /// Query parameter of `/capture` that preselects a journey.
  static const journeyIdParam = 'journeyId';

  /// Journey to preselect (from [journeyIdParam]); wins over the remembered
  /// `camera.lastJourneyId` when it is still active.
  final String? initialJourneyId;

  /// Kept for test/app/{router,accessibility}_test.dart, which locate the
  /// capture tab by the A3 placeholder key.
  static const screenKey = ValueKey('placeholder-camera');

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen>
    with WidgetsBindingObserver {
  CameraSession? _session;
  _Phase _phase = _Phase.idle;
  CameraFailure? _failure;
  FlashSetting _flash = FlashSetting.off;
  bool _front = false;
  bool _busy = false;
  bool _flashOverlay = false;
  bool _grid = false;

  bool _visible = false;
  bool _appVisible = true;
  bool _noJourneys = false;

  /// Bumped whenever the camera is stopped so a start that finishes late
  /// releases the camera instead of showing it.
  int _generation = 0;

  String? _selectedJourneyId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final asked =
        ref
            .read(sharedPreferencesProvider)
            .getBool(CameraPrefs.permissionAsked) ??
        false;
    if (!asked) _phase = _Phase.prePrompt;
    _selectedJourneyId =
        widget.initialJourneyId ?? ref.read(activeJourneyIdProvider);
    final initial = widget.initialJourneyId;
    if (initial != null) _rememberJourney(initial);
    ref.listenManual<AsyncValue<List<Journey>>>(captureJourneysProvider, (
      _,
      next,
    ) {
      final empty = next.hasValue && next.requireValue.isEmpty;
      if (empty != _noJourneys) {
        _noJourneys = empty;
        _sync();
      }
    }, fireImmediately: true);
  }

  @override
  void didUpdateWidget(CaptureScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final id = widget.initialJourneyId;
    if (id != null && id != oldWidget.initialJourneyId) {
      _selectedJourneyId = id;
      _rememberJourney(id);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible != _visible) {
      _visible = visible;
      _sync();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `inactive` also fires for the OS permission dialog and the app
    // switcher; only release the camera once the app is really hidden.
    switch (state) {
      case AppLifecycleState.resumed:
        _appVisible = true;
        // Coming back from Settings: try again if access was blocked.
        if (_phase == _Phase.failure &&
            (_failure == CameraFailure.permissionDeniedPermanently ||
                _failure == CameraFailure.restricted)) {
          _phase = _Phase.idle;
        }
        _sync();
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _appVisible = false;
        _sync();
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    unawaited(_session?.stop());
    super.dispose();
  }

  bool get _wantCamera => _visible && _appVisible && !_noJourneys;

  /// Starts or stops the camera to match visibility and state.
  void _sync() {
    if (!mounted) return;
    if (_wantCamera) {
      // A microtask, not a post-frame callback: runs right after the current
      // (first) frame's synchronous work, so the camera opens without waiting
      // a frame but never calls setState during build.
      if (_phase == _Phase.idle) scheduleMicrotask(_startIfWanted);
    } else if (_phase == _Phase.starting || _phase == _Phase.ready) {
      _stop();
    }
  }

  void _startIfWanted() {
    if (mounted && _wantCamera && _phase == _Phase.idle) unawaited(_start());
  }

  void _stop() {
    _generation++;
    final s = _session;
    if (s != null) unawaited(s.stop());
    _phase = _Phase.idle;
    // May run from didChangeDependencies (tab hidden): rebuild afterwards.
    scheduleMicrotask(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _start() async {
    final gen = ++_generation;
    final session = _session ??= ref.read(cameraSessionFactoryProvider)();
    setState(() {
      _phase = _Phase.starting;
      _failure = null;
    });
    try {
      await session.start(front: _front);
      if (session.hasFlash) {
        try {
          await session.setFlash(_flash);
        } on Object {
          // Flash is best-effort; the preview still works.
        }
      }
      if (!mounted || gen != _generation) {
        // Superseded while starting. Unless a newer start owns the camera,
        // release it (the session also drops a start stopped mid-way).
        if (!mounted || !_wantCamera || _phase == _Phase.idle) {
          await session.stop();
        }
        return;
      }
      setState(() => _phase = _Phase.ready);
    } on CameraStartException catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _phase = _Phase.failure;
        _failure = e.failure;
      });
    } finally {
      unawaited(
        ref
            .read(sharedPreferencesProvider)
            .setBool(CameraPrefs.permissionAsked, true),
      );
    }
  }

  void _acceptPrePrompt() {
    setState(() => _phase = _Phase.idle);
    _sync();
  }

  void _retry() {
    setState(() => _phase = _Phase.idle);
    _sync();
  }

  Future<void> _openSettings() async {
    await ref.read(appSettingsOpenerProvider).open();
  }

  Future<void> _toggleFlash() async {
    final next = FlashSetting.values[(_flash.index + 1) % 3];
    setState(() => _flash = next);
    OurneyHaptics.selection();
    try {
      await _session?.setFlash(next);
    } on Object {
      // Ignore: keeps the chosen setting for the next start.
    }
  }

  Future<void> _switchLens() async {
    final s = _session;
    if (s == null || !s.canSwitch || _busy) return;
    OurneyHaptics.selection();
    final gen = ++_generation;
    setState(() {
      _busy = true;
      _phase = _Phase.starting;
    });
    try {
      await s.switchLens();
      _front = s.isFront;
      if (s.hasFlash) await s.setFlash(_flash);
      if (mounted && gen == _generation) {
        setState(() => _phase = _Phase.ready);
      }
    } on CameraStartException catch (e) {
      if (mounted && gen == _generation) {
        setState(() {
          _phase = _Phase.failure;
          _failure = e.failure;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _selectJourney(String id) {
    setState(() => _selectedJourneyId = id);
    _rememberJourney(id);
  }

  /// Swipe on the viewfinder: the next journey in the chip order.
  void _nextJourney(List<Journey> list, Journey? selected) {
    if (list.length < 2) return;
    final i = list.indexWhere((j) => j.id == selected?.id);
    OurneyHaptics.selection();
    _selectJourney(list[(i + 1) % list.length].id);
  }

  /// Makes [id] the active journey, which also themes the app with its
  /// persona (F2). Deferred: a provider must not change during a widget
  /// lifecycle callback.
  void _rememberJourney(String id) {
    scheduleMicrotask(() {
      if (!mounted) return;
      unawaited(ref.read(activeJourneyIdProvider.notifier).select(id));
    });
  }

  double? _latestMetric(String journeyId) {
    final checkIns = ref.read(myCheckInsProvider(journeyId)).value;
    return checkIns
        ?.where((c) => c.metricValue != null)
        .fold<CheckIn?>(
          null,
          (prev, c) =>
              prev == null || c.localDate.compareTo(prev.localDate) >= 0
              ? c
              : prev,
        )
        ?.metricValue;
  }

  Future<void> _capture(Journey journey) async {
    final s = _session;
    if (_busy || s == null || _phase != _Phase.ready) return;
    final reduced = OurneyMotion.reduced(context);
    setState(() {
      _busy = true;
      _flashOverlay = !reduced;
    });
    OurneyHaptics.medium();
    if (!reduced) {
      Future<void>.delayed(const Duration(milliseconds: 160), () {
        if (mounted) setState(() => _flashOverlay = false);
      });
    }
    final capturedAt = clock.now().toUtc();
    final String path;
    try {
      path = await s.takePicture();
    } on CameraStartException {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(CameraL10n.of(context).camera_captureFailed)),
        );
      }
      return;
    } finally {
      // Never held across the navigation below: /checkin may leave through
      // pop-then-push or `go`, and the shutter must work when we are back.
      // The flash overlay fades out on its own timer.
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    _openCheckin(
      CapturedPhoto(
        journeyId: journey.id,
        path: path,
        capturedAt: capturedAt,
        initialMetricValue: _latestMetric(journey.id),
      ),
    );
  }

  Future<void> _pickFromLibrary(Journey journey) async {
    if (_busy) return;
    setState(() => _busy = true);
    String? path;
    try {
      path = await ref.read(galleryPickerProvider).pickPhoto();
    } on Object {
      // Picker unavailable or cancelled by the OS: nothing to do.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (path == null || !mounted) return;
    _openCheckin(
      CapturedPhoto(
        journeyId: journey.id,
        path: path,
        capturedAt: clock.now().toUtc(),
        fromLibrary: true,
        initialMetricValue: _latestMetric(journey.id),
      ),
    );
  }

  /// Fire and forget: the push future is not awaited (it may never
  /// complete if /checkin is replaced), and no state depends on it.
  void _openCheckin(CapturedPhoto photo) {
    unawaited(
      ref.read(activeJourneyIdProvider.notifier).select(photo.journeyId),
    );
    unawaited(context.push<void>(AppRoutes.checkin, extra: photo));
  }

  void _goTab(int index) {
    OurneyHaptics.selection();
    // In the shell keep each tab's own stack (a journey opened from the
    // Journeys tab is still there); standalone, go to the tab root.
    final shell = StatefulNavigationShell.maybeOf(context);
    if (shell != null) {
      shell.goBranch(index);
    } else {
      context.go(
        index == AppDock.journeysIndex ? AppRoutes.journeys : AppRoutes.groups,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final journeys = ref.watch(captureJourneysProvider);
    // The Hub (or another tab) may pick a journey: follow it without
    // touching the camera.
    ref.listen<String?>(activeJourneyIdProvider, (_, next) {
      if (next != null && next != _selectedJourneyId) {
        setState(() => _selectedJourneyId = next);
      }
    });
    final list = journeys.value ?? const <Journey>[];
    final selected = pickInitialJourney(list, _selectedJourneyId);
    final style = selected == null
        ? null
        : uiStyleForSkin(personaSkinOf(selected));

    // Camera chrome is always dark: the kit widgets read the dark palette.
    return Theme(
      data: OurneyTheme.build(
        Brightness.dark,
        selected == null ? null : personaSkinOf(selected),
      ),
      child: Scaffold(
        key: CaptureScreen.screenKey,
        backgroundColor: UiCamera.bg,
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: UiSpace.maxContent(MediaQuery.sizeOf(context).width),
              ),
              child: journeys.hasValue && list.isEmpty
                  ? _buildEmpty(context)
                  : _buildCamera(context, journeys, list, selected, style),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final l10n = CameraL10n.of(context);
    return Column(
      children: [
        const Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: EdgeInsets.all(UiSpace.sm),
            child: ProfileEntryButton(onDark: true),
          ),
        ),
        Expanded(
          child: UiFillScroll(
            child: UiEmptyState(
              key: const ValueKey('capture-no-journeys'),
              icon: Icons.flag_rounded,
              title: l10n.camera_noJourneyTitle,
              body: l10n.camera_noJourneyMessage,
              actionLabel: l10n.camera_noJourneyAction,
              onAction: () => context.go(AppRoutes.journeyNew),
            ),
          ),
        ),
        _dock(context, null, null),
      ],
    );
  }

  Widget _dock(BuildContext context, Journey? journey, UiJourneyStyle? style) {
    final l10n = CameraL10n.of(context);
    final ready = _phase == _Phase.ready && journey != null && !_busy;
    return AppDock(
      currentIndex: AppDock.captureIndex,
      onSelect: _goTab,
      shutter: KeyedSubtree(
        key: const ValueKey('dock-hero-shutter'),
        child: UiShutter(
          key: const ValueKey('capture-shutter'),
          label: journey == null
              ? l10n.camera_shutter
              : l10n.camera_shutterFor(journey.title),
          accent: style?.accent,
          onPressed: ready ? () => _capture(journey) : null,
        ),
      ),
    );
  }

  Widget _buildCamera(
    BuildContext context,
    AsyncValue<List<Journey>> journeys,
    List<Journey> list,
    Journey? selected,
    UiJourneyStyle? style,
  ) {
    final l10n = CameraL10n.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final gutter = UiSpace.gutter(width);
    final session = _session;
    final canSwitch =
        (_phase == _Phase.ready || _phase == _Phase.starting) &&
        (session?.canSwitch ?? false) &&
        !_busy;
    final hasFlash = _phase == _Phase.ready && (session?.hasFlash ?? false);
    final (flashIcon, flashLabel) = switch (_flash) {
      FlashSetting.off => (Icons.flash_off_rounded, l10n.camera_flashOff),
      FlashSetting.auto => (Icons.flash_auto_rounded, l10n.camera_flashAuto),
      FlashSetting.on => (Icons.flash_on_rounded, l10n.camera_flashOn),
    };
    final index = list.indexWhere((j) => j.id == selected?.id);
    return Column(
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: gutter, end: UiSpace.sm),
          child: Row(
            children: [
              Expanded(
                child: _JourneyBar(
                  journeys: journeys,
                  selected: selected,
                  onSelect: _selectJourney,
                  onRetry: () => ref.invalidate(captureJourneysProvider),
                ),
              ),
              const ProfileEntryButton(onDark: true),
            ],
          ),
        ),
        const SizedBox(height: UiSpace.sm),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: _buildViewfinder(context, list, selected),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasFlash)
              KeyedSubtree(
                key: const ValueKey('capture-flash'),
                child: Tooltip(
                  message: flashLabel,
                  child: UiCameraTool(
                    icon: flashIcon,
                    label: flashLabel,
                    onPressed: _toggleFlash,
                  ),
                ),
              ),
            Tooltip(
              message: l10n.camera_grid,
              child: UiCameraTool(
                key: const ValueKey('capture-grid'),
                icon: _grid ? Icons.grid_on_rounded : Icons.grid_3x3_rounded,
                label: l10n.camera_grid,
                onPressed: () => setState(() => _grid = !_grid),
              ),
            ),
          ],
        ),
        if (list.length > 1)
          UiPageDots(count: list.length, index: index < 0 ? 0 : index)
        else
          const SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Tooltip(
                message: l10n.camera_gallery,
                child: UiLibraryThumb(
                  key: const ValueKey('capture-gallery'),
                  label: l10n.camera_gallery,
                  onPressed: selected == null || _busy
                      ? null
                      : () => _pickFromLibrary(selected),
                ),
              ),
              Tooltip(
                message: l10n.camera_switchLens,
                child: UiCameraTool(
                  key: const ValueKey('capture-switch'),
                  icon: Icons.cameraswitch_outlined,
                  label: l10n.camera_switchLens,
                  onPressed: canSwitch ? _switchLens : null,
                ),
              ),
            ],
          ),
        ),
        _dock(context, selected, style),
      ],
    );
  }

  Widget _buildViewfinder(
    BuildContext context,
    List<Journey> list,
    Journey? journey,
  ) {
    final l10n = CameraL10n.of(context);
    final session = _session;
    final Widget content = switch (_phase) {
      _Phase.ready when session != null => KeyedSubtree(
        key: const ValueKey('capture-preview'),
        child: session.buildPreview(),
      ),
      _Phase.prePrompt => _PrePrompt(onAccept: _acceptPrePrompt),
      _Phase.failure => _FailurePanel(
        failure: _failure ?? CameraFailure.failed,
        settingsSupported: ref.read(appSettingsOpenerProvider).supported,
        onOpenSettings: _openSettings,
        onRetry: _retry,
      ),
      _ => Center(
        child: Semantics(
          label: l10n.camera_starting,
          child: const SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      ),
    };
    final hud = journey == null ? null : _hudFor(journey);

    final viewfinder = ClipRRect(
      borderRadius: BorderRadius.circular(UiRadius.viewfinder),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: const Color(0xFF17171B), child: content),
          if (_grid && _phase == _Phase.ready)
            const IgnorePointer(child: CustomPaint(painter: _GridPainter())),
          if (_phase == _Phase.ready)
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(0, 0.3),
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x88000000)],
                  ),
                ),
              ),
            ),
          if (hud != null)
            Positioned(
              left: 16,
              top: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: UiDayHud(
                      key: const ValueKey('capture-day-hud'),
                      l10n.camera_dayHud(hud.dayNumber),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: l10n.camera_streakChip(hud.summary.current),
                    excludeSemantics: true,
                    child: UiGlassChip(
                      label: '${hud.summary.current}',
                      leading: Icons.local_fire_department_rounded,
                    ),
                  ),
                ],
              ),
            ),
          if (list.length > 1 && _phase == _Phase.ready)
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: IgnorePointer(
                child: Text(
                  l10n.camera_swipeHint,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.body(
                    size: 12,
                    height: 1.4,
                    color: UiCamera.ink,
                  ),
                ),
              ),
            ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _flashOverlay ? 1 : 0,
              duration: UiMotion.of(context, const Duration(milliseconds: 160)),
              child: const ColoredBox(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return Center(
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onHorizontalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0).abs() > 250) {
              _nextJourney(list, journey);
            }
          },
          child: viewfinder,
        ),
      ),
    );
  }

  /// Day number and streak of [journey] for the viewfinder pill; day 1 and
  /// streak 0 until the check-ins load.
  JourneyProgress _hudFor(Journey journey) {
    final membership = ref.watch(myMembershipProvider(journey.id)).value;
    final checkIns =
        ref.watch(myCheckInsProvider(journey.id)).value ?? const <CheckIn>[];
    return JourneyProgress.compute(
      journey: journey,
      membership: membership,
      checkIns: checkIns,
      now: clock.now().toUtc(),
    );
  }
}

/// 3x3 framing grid over the viewfinder.
class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

class _JourneyBar extends StatelessWidget {
  const _JourneyBar({
    required this.journeys,
    required this.selected,
    required this.onSelect,
    required this.onRetry,
  });

  final AsyncValue<List<Journey>> journeys;
  final Journey? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = CameraL10n.of(context);
    final ui = context.ui;
    if (journeys.hasError && !journeys.hasValue) {
      return Row(
        children: [
          Icon(Icons.error_outline_rounded, color: ui.danger, size: 20),
          const SizedBox(width: UiSpace.sm),
          Flexible(
            child: Text(
              l10n.camera_journeysError,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: UiText.body(size: 13, color: ui.ink),
            ),
          ),
          Flexible(
            child: UiTextAction(
              label: AppLocalizations.of(context).common_retry,
              onPressed: onRetry,
            ),
          ),
        ],
      );
    }
    if (!journeys.hasValue) return const SizedBox(height: UiSize.tap);
    return Semantics(
      container: true,
      label: l10n.camera_journeyPicker,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final j in journeys.requireValue)
              Padding(
                padding: const EdgeInsets.only(right: UiSpace.sm),
                child: _JourneyChip(
                  key: ValueKey('journey-chip-${j.id}'),
                  label: j.title,
                  icon: uiJourneyIcon(j.emoji, j.templateId),
                  selected: j.id == selected?.id,
                  onTap: () => onSelect(j.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Journey chip on the camera: the selected one is solid paper with a check,
/// the others are translucent with white text (state is not color only).
class _JourneyChip extends StatelessWidget {
  const _JourneyChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return UiGlassChip(
        label: label,
        leading: Icons.check_rounded,
        trailing: Icons.expand_more_rounded,
        onPressed: onTap,
      );
    }
    return UiPressable(
      onPressed: onTap,
      semanticLabel: label,
      excludeChildSemantics: true,
      centerChild: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40, maxWidth: 200),
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: const Color(0x24FFFFFF),
          borderRadius: BorderRadius.circular(UiRadius.capsule),
          border: Border.all(color: const Color(0x2EFFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: UiCamera.ink),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.body(
                  size: 14,
                  weight: FontWeight.w600,
                  height: 1.3,
                  color: UiCamera.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared layout for the pre-prompt and failure panels: scrolls so it never
/// overflows at large text.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actions,
    this.panelKey,
  });

  final IconData icon;
  final String title;
  final String message;
  final List<Widget> actions;
  final Key? panelKey;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Center(
      key: panelKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(UiSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: UiSize.permissionIcon,
                height: UiSize.permissionIcon,
                decoration: BoxDecoration(
                  color: ui.permissionIconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: ui.ink),
              ),
            ),
            const SizedBox(height: UiSpace.lg),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: UiText.h2(color: ui.ink, size: 20),
              ),
            ),
            const SizedBox(height: UiSpace.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: UiText.muted(color: ui.inkMuted, size: 14),
            ),
            for (final a in actions) ...[const SizedBox(height: UiSpace.md), a],
          ],
        ),
      ),
    );
  }
}

class _PrePrompt extends StatelessWidget {
  const _PrePrompt({required this.onAccept});

  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final l10n = CameraL10n.of(context);
    return _Panel(
      panelKey: const ValueKey('capture-pre-prompt'),
      icon: Icons.photo_camera_outlined,
      title: l10n.camera_prePromptTitle,
      message: l10n.camera_prePromptMessage,
      actions: [
        UiButton(
          label: l10n.camera_prePromptAction,
          onPressed: onAccept,
          expand: false,
        ),
      ],
    );
  }
}

class _FailurePanel extends StatelessWidget {
  const _FailurePanel({
    required this.failure,
    required this.settingsSupported,
    required this.onOpenSettings,
    required this.onRetry,
  });

  final CameraFailure failure;
  final bool settingsSupported;
  final VoidCallback onOpenSettings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = CameraL10n.of(context);
    final common = AppLocalizations.of(context);
    final retry = UiButton.secondary(
      key: const ValueKey('capture-retry'),
      label: common.common_retry,
      onPressed: onRetry,
      expand: false,
    );
    final settings = UiButton(
      key: const ValueKey('capture-open-settings'),
      label: l10n.camera_openSettings,
      onPressed: onOpenSettings,
      expand: false,
    );
    final settingsHint = Text(
      l10n.camera_deniedSettingsPath,
      textAlign: TextAlign.center,
      style: UiText.muted(color: context.ui.inkMuted, size: 13),
    );
    switch (failure) {
      case CameraFailure.permissionDenied:
      case CameraFailure.permissionDeniedPermanently:
        return _Panel(
          panelKey: const ValueKey('capture-denied'),
          icon: Icons.no_photography_outlined,
          title: l10n.camera_deniedTitle,
          message: l10n.camera_deniedMessage,
          actions: [
            if (settingsSupported) settings else settingsHint,
            if (failure == CameraFailure.permissionDenied || !settingsSupported)
              retry,
          ],
        );
      case CameraFailure.restricted:
        return _Panel(
          panelKey: const ValueKey('capture-restricted'),
          icon: Icons.no_photography_outlined,
          title: l10n.camera_deniedTitle,
          message: l10n.camera_restrictedMessage,
          actions: const [],
        );
      case CameraFailure.unavailable:
        return _Panel(
          panelKey: const ValueKey('capture-unavailable'),
          icon: Icons.videocam_off_outlined,
          title: l10n.camera_unavailableTitle,
          message: l10n.camera_unavailableMessage,
          actions: const [],
        );
      case CameraFailure.failed:
        return _Panel(
          panelKey: const ValueKey('capture-failed'),
          icon: Icons.videocam_off_outlined,
          title: l10n.camera_failedTitle,
          message: common.common_errorGeneric,
          actions: [retry],
        );
    }
  }
}
