import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsService;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/app_dock.dart';
import '../../app/app_routes.dart';
import '../../app/providers.dart';
import '../../personas/persona_contract.dart' show personaSkinOf;
import '../../ui/ui.dart';
import '../checkin/captured_photo.dart';
import '../checkin/checkin_controller.dart' show checkinJourneyProvider;
import '../journeys/data/journeys_providers.dart';
import 'camera_providers.dart';
import 'camera_session.dart';
import 'capture_journey_data.dart';
import 'capture_overlays.dart';
import 'capture_services.dart';
import 'journey_picker_sheet.dart';
import 'l10n/generated/camera_localizations.dart';
import 'widgets/camera_panels.dart';
import 'widgets/camera_top_bar.dart';
import 'widgets/journey_disc_strip.dart';
import 'widgets/viewfinder_extras.dart';

enum _Phase { idle, prePrompt, starting, ready, failure }

/// `/capture`: the app's start screen (FR-C1), laid out like the Figma V2
/// camera (`routes.tsx` `CameraScreen`, SDS §8.8, design-v2 bugs.md A1) and
/// the 2026-11-20 camera redesign: a top bar with the journey chip
/// ("Name · Day N") and the tools (flash FR-C2, grid, ghost guide for the
/// quiet persona), a large 3:4 viewfinder inset by 8dp (streak chip, status
/// pill, persona guides), one controls row (library, journey discs FR-C3,
/// lens switch), then the dark camera dock with the hero shutter. One shared
/// camera for all personas: the persona only changes the accent. Pieces live
/// in `widgets/` and `capture_journey_data.dart`. Transient state ("Flash:
/// auto", capture failed) shows in a status pill inside the preview, never in
/// a toast (it covered the shutter).
/// The OS permission is requested in context after a friendly pre-prompt; a
/// denied state links to Settings.
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
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraSession? _session;
  _Phase _phase = _Phase.idle;
  CameraFailure? _failure;
  FlashSetting _flash = FlashSetting.off;
  bool _front = false;
  bool _busy = false;
  bool _switchingLens = false;
  bool _grid = false;

  /// Quiet persona: the day-1 ghost silhouette guide.
  bool _ghost = true;

  // Status pill inside the preview (replaces the toast).
  String _statusMessage = '';
  String? _statusGlyph;
  UiCameraStatusTone _statusTone = UiCameraStatusTone.neutral;
  bool _statusVisible = false;
  Timer? _statusTimer;

  bool _visible = false;
  bool _appVisible = true;

  /// Set when we sent the user to system Settings for the permission.
  bool _sentToSettings = false;
  bool _noJourneys = false;

  /// Bumped whenever the camera is stopped so a start that finishes late
  /// releases the camera instead of showing it.
  int _generation = 0;

  String? _selectedJourneyId;
  int _journeyDirection = 1;
  String? _lastCaptureHeroKey;

  /// Shutter flash (Rank #1 Phase 1a): 30ms attack -> 140ms ease-out decay
  /// (170ms total), peaking at 0.88 opacity in warm cream [UiCamera.ink].
  static const Duration _kShutterFlashDuration = Duration(milliseconds: 170);

  late final AnimationController _flashCtrl = AnimationController(
    vsync: this,
    duration: _kShutterFlashDuration,
  );
  late final Animation<double> _flashOpacity = TweenSequence<double>([
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 0.0, end: 0.88).chain(
        CurveTween(curve: UiCurves.easeOutStrong),
      ),
      weight: 30,
    ),
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 0.88, end: 0.0).chain(
        CurveTween(curve: UiCurves.easeOutStrong),
      ),
      weight: 140,
    ),
  ]).animate(_flashCtrl);

  /// Lens flip frosted scrim (Rank #14 item 3): 220ms total (110ms in / 110ms out)
  /// with `ImageFilter.blur(sigmaX: 10, sigmaY: 10)`.
  late final AnimationController _lensFlipCtrl = AnimationController(
    vsync: this,
    duration: UiMotion.press,
    reverseDuration: UiMotion.press,
  )..addStatusListener(_onLensFlipStatus);
  late final CurvedAnimation _lensFlipCurved = CurvedAnimation(
    parent: _lensFlipCtrl,
    curve: UiCurves.easeInOutStrong,
    reverseCurve: UiCurves.easeInOutStrong,
  );

  void _onLensFlipStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted && !_switchingLens) {
      _lensFlipCtrl.reverse();
    }
  }

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
    if (id != null &&
        (id != oldWidget.initialJourneyId || id != _selectedJourneyId)) {
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
        // Android reports a "don't ask again" denial as a plain denial, so
        // that one is retried too when we opened Settings ourselves (U7).
        if (_phase == _Phase.failure &&
            (_failure == CameraFailure.permissionDeniedPermanently ||
                _failure == CameraFailure.restricted ||
                (_sentToSettings &&
                    _failure == CameraFailure.permissionDenied))) {
          _phase = _Phase.idle;
        }
        _sentToSettings = false;
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
    _statusTimer?.cancel();
    _flashCtrl.dispose();
    _lensFlipCtrl.removeStatusListener(_onLensFlipStatus);
    _lensFlipCurved.dispose();
    _lensFlipCtrl.dispose();
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
    // Read before the await: `ref` is unusable once the screen unmounts.
    final prefs = ref.read(sharedPreferencesProvider);
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
      debugPrint('camera: start failed: ${e.failure.name} ${e.detail ?? ''}');
      if (!mounted || gen != _generation) return;
      setState(() {
        _phase = _Phase.failure;
        _failure = e.failure;
      });
    } on Object catch (e) {
      // Not a CameraException (a platform or state error): still end in the
      // failure state with a retry instead of an endless "starting".
      debugPrint('camera: start failed unexpectedly: $e');
      if (!mounted || gen != _generation) return;
      setState(() {
        _phase = _Phase.failure;
        _failure = CameraFailure.failed;
      });
    } finally {
      // The start reached the OS permission prompt, so it was asked even if
      // the user left the screen meanwhile (prefs were read before the
      // await: `ref` is unusable once unmounted).
      unawaited(prefs.setBool(CameraPrefs.permissionAsked, true));
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
    _sentToSettings = true;
    final opened = await ref.read(appSettingsOpenerProvider).open();
    if (!opened) _sentToSettings = false;
  }

  /// Shows [message] in the status pill for 1.2s (1.5s under Reduce Motion)
  /// The message is also announced to screen readers.
  void _showStatus(String message, {String? glyph, bool danger = false}) {
    if (!mounted) return;
    _statusTimer?.cancel();
    final hold = UiMotion.reduced(context)
        ? const Duration(milliseconds: 1500)
        : const Duration(milliseconds: 1200);
    setState(() {
      _statusMessage = message;
      _statusGlyph = glyph;
      _statusTone = danger
          ? UiCameraStatusTone.danger
          : UiCameraStatusTone.neutral;
      _statusVisible = true;
    });
    // Announced through the service, not a live region (which can steal
    // VoiceOver focus), and on every call so an identical repeat within the
    // hold is read again.
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ),
    );
    _statusTimer = Timer(hold, () {
      if (mounted) setState(() => _statusVisible = false);
    });
  }

  static String _flashGlyph(FlashSetting f) => switch (f) {
    FlashSetting.off => 'flash-off',
    FlashSetting.auto => 'flash-auto',
    FlashSetting.on => 'lightning',
  };

  Future<void> _toggleFlash() async {
    final next = FlashSetting.values[(_flash.index + 1) % 3];
    final l10n = CameraL10n.of(context);
    setState(() => _flash = next);
    unawaited(UiHaptics.selection());
    try {
      await _session?.setFlash(next);
      _showStatus(switch (next) {
        FlashSetting.off => l10n.camera_flashOff,
        FlashSetting.auto => l10n.camera_flashAuto,
        FlashSetting.on => l10n.camera_flashOn,
      }, glyph: _flashGlyph(next));
    } on Object {
      // The lens refused the mode (no flash unit): say so, back to off.
      if (!mounted) return;
      setState(() => _flash = FlashSetting.off);
      _showStatus(l10n.camera_flashUnavailable, glyph: 'flash-off');
    }
  }

  void _toggleGhost() {
    final l10n = CameraL10n.of(context);
    unawaited(UiHaptics.selection());
    setState(() => _ghost = !_ghost);
    _showStatus(
      _ghost ? l10n.camera_ghostOn : l10n.camera_ghostOff,
      glyph: _ghost ? 'eye' : 'eye-off',
    );
  }

  Future<void> _switchLens() async {
    final s = _session;
    if (s == null || !s.canSwitch || _busy) return;
    unawaited(UiHaptics.selection());
    final reduced = UiMotion.reduced(context);
    final gen = ++_generation;
    setState(() {
      _busy = true;
      _switchingLens = true;
      _phase = _Phase.starting;
    });
    if (!reduced) {
      _lensFlipCtrl.forward(from: 0.0);
    }
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
    } on Object catch (e) {
      debugPrint('camera: switch lens failed unexpectedly: $e');
      if (mounted && gen == _generation) {
        setState(() {
          _phase = _Phase.failure;
          _failure = CameraFailure.failed;
        });
      }
    } finally {
      _switchingLens = false;
      if (mounted) {
        if (_lensFlipCtrl.status == AnimationStatus.completed) {
          _lensFlipCtrl.reverse();
        }
        setState(() => _busy = false);
      }
    }
  }

  void _selectJourney(
    String id, {
    List<Journey>? list,
    int? direction,
  }) {
    var nextDir = direction;
    if (nextDir == null && list != null && _selectedJourneyId != null) {
      final oldIdx = list.indexWhere((j) => j.id == _selectedJourneyId);
      final newIdx = list.indexWhere((j) => j.id == id);
      if (oldIdx != -1 && newIdx != -1 && oldIdx != newIdx) {
        nextDir = newIdx > oldIdx ? 1 : -1;
      }
    }
    setState(() {
      if (nextDir != null) _journeyDirection = nextDir;
      _selectedJourneyId = id;
    });
    _rememberJourney(id);
    if (widget.initialJourneyId != null && id != widget.initialJourneyId) {
      GoRouter.maybeOf(context)?.go(AppRoutes.capture);
    }
  }

  /// Swipe on the viewfinder: moves to the next/previous journey in the chip
  /// order while keeping the camera hardware session 100% un-reset.
  void _nextJourney(
    List<Journey> list,
    Journey? selected, {
    int direction = 1,
  }) {
    if (list.length < 2) return;
    final i = list.indexWhere((j) => j.id == selected?.id);
    unawaited(UiHaptics.selection());
    final step = direction >= 0 ? 1 : -1;
    _selectJourney(
      list[(i + step + list.length) % list.length].id,
      direction: step,
    );
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
          (prev, c) => prev == null || !c.capturedAt.isBefore(prev.capturedAt)
              ? c
              : prev,
        )
        ?.metricValue;
  }

  Future<void> _capture(Journey journey) async {
    final s = _session;
    if (_busy || s == null || _phase != _Phase.ready) return;
    final reduced = UiMotion.reduced(context);
    setState(() {
      _busy = true;
    });
    unawaited(UiHaptics.shutterMedium());
    if (!reduced) {
      _flashCtrl.forward(from: 0.0);
    } else {
      _flashCtrl.value = 0.0;
    }
    final capturedAt = clock.now().toUtc();
    String? capturedPath;
    try {
      // Some devices drop the flash mode after a lens or lifecycle restart:
      // apply the chosen one again right before the shot.
      if (s.hasFlash) {
        try {
          await s.setFlash(_flash);
        } on Object {
          // Best effort; the photo is still taken.
        }
      }
      capturedPath = await s.takePicture();
    } on CameraStartException {
      if (mounted) {
        _showStatus(
          CameraL10n.of(context).camera_captureFailed,
          glyph: 'error',
          danger: true,
        );
      }
      return;
    } finally {
      // Never held across the navigation below: /checkin may leave through
      // pop-then-push or `go`, and the shutter must work when we are back.
      // The flash overlay fades out on its own controller.
      if (mounted) {
        setState(() {
          if (capturedPath != null) _lastCaptureHeroKey = capturedPath;
          _busy = false;
        });
      }
    }
    if (!mounted) return;
    _openCheckin(
      CapturedPhoto(
        journeyId: journey.id,
        path: capturedPath,
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
      if (mounted) {
        setState(() {
          if (path != null) _lastCaptureHeroKey = path;
          _busy = false;
        });
      }
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
    unawaited(UiHaptics.selection());
    // In the shell keep each tab's own stack (a journey opened from the
    // Journeys tab is still there); standalone, go to the tab root.
    final shell = StatefulNavigationShell.maybeOf(context);
    if (shell != null) {
      shell.goBranch(index);
    } else {
      context.go(switch (index) {
        AppDock.journeysIndex => AppRoutes.journeys,
        AppDock.activityIndex => AppRoutes.inbox,
        AppDock.profileIndex => AppRoutes.profile,
        _ => AppRoutes.groups,
      });
    }
  }

  /// "All journeys" sheet (search, pinned / not shot / shot sections).
  /// Opened from the name chip and from the "All (N)" disc.
  Future<void> _openPicker(List<Journey> active, Journey? selected) async {
    var all = active;
    var shot = const <String>{};
    try {
      all = await ref.read(capturePickerJourneysProvider.future);
      shot = await ref.read(captureShotTodayProvider.future);
    } on Object {
      // Sections are a nicety: fall back to the active list.
    }
    if (!mounted) return;
    final id = await showJourneyPickerSheet(
      context,
      journeys: all,
      selectedId: selected?.id,
      shotTodayIds: shot,
      pinnedIds: ref.read(pinnedJourneyIdsProvider).value ?? const <String>{},
    );
    // Ended journeys cannot take a check-in: not selectable.
    if (id != null && active.any((j) => j.id == id)) _selectJourney(id);
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
    if (selected != null) {
      // Keep the selected journey provider warm so pushing /checkin mounts
      // CheckinScreen with AsyncData on frame 0 (no 1-frame spinner flash and
      // immediate shared-element UiHero flight).
      ref.watch(checkinJourneyProvider(selected.id));
    }
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
        Expanded(
          child: UiFillScroll(
            child: UiEmptyState(
              key: const ValueKey('capture-no-journeys'),
              glyph: const OurneyIcon(name: 'flag', size: 30),
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
          onAccent: style?.onAccent,
          onPressed: ready ? () => _capture(journey) : null,
          // Dim only while the camera itself is not ready, not while a
          // capture is in flight.
          dimmed: _phase != _Phase.ready || journey == null,
        ),
      ),
    );
  }

  /// Flash, framing grid and (quiet persona) the ghost guide. The lens switch
  /// lives in the controls row, opposite the library.
  List<Widget> _tools(
    BuildContext context,
    Journey? journey,
    UiJourneyStyle? style,
  ) {
    final l10n = CameraL10n.of(context);
    final session = _session;
    final hasFlash = _phase == _Phase.ready && (session?.hasFlash ?? false);
    // The state is carried by the glyph shape (slashed bolt, bolt with an A,
    // filled accent disc), not by colour alone.
    final (flashEmphasis, flashLabel) = switch (_flash) {
      FlashSetting.off => (UiCameraToolEmphasis.none, l10n.camera_flashOff),
      FlashSetting.auto => (
        UiCameraToolEmphasis.outline,
        l10n.camera_flashAuto,
      ),
      FlashSetting.on => (UiCameraToolEmphasis.filled, l10n.camera_flashOn),
    };
    final quiet =
        journey != null &&
        personaSkinOf(journey) == PersonaSkinId.quietTransformer;
    return [
      if (quiet)
        Tooltip(
          message: _ghost ? l10n.camera_ghostOn : l10n.camera_ghostOff,
          child: UiCameraTool(
            key: const ValueKey('capture-ghost'),
            glyph: _ghost ? 'eye' : 'eye-off',
            label: _ghost ? l10n.camera_ghostOn : l10n.camera_ghostOff,
            emphasis: _ghost
                ? UiCameraToolEmphasis.filled
                : UiCameraToolEmphasis.none,
            accent: style?.accent,
            onAccent: style?.onAccent,
            onPressed: _toggleGhost,
          ),
        ),
      if (hasFlash)
        KeyedSubtree(
          key: const ValueKey('capture-flash'),
          child: Tooltip(
            message: flashLabel,
            child: UiCameraTool(
              glyph: _flashGlyph(_flash),
              label: flashLabel,
              emphasis: flashEmphasis,
              accent: style?.accent,
              onAccent: style?.onAccent,
              onPressed: _toggleFlash,
            ),
          ),
        ),
      Tooltip(
        message: l10n.camera_grid,
        child: UiCameraTool(
          key: const ValueKey('capture-grid'),
          glyph: 'grid',
          label: l10n.camera_grid,
          emphasis: _grid
              ? UiCameraToolEmphasis.filled
              : UiCameraToolEmphasis.none,
          accent: style?.accent,
          onAccent: style?.onAccent,
          onPressed: () {
            unawaited(UiHaptics.selection());
            setState(() => _grid = !_grid);
          },
        ),
      ),
    ];
  }

  /// Camera layout: top bar (journey chip + tools), the viewfinder, one
  /// controls row (library, disc strip, lens switch), then the camera dock
  /// with the hero shutter.
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
    final data = selected == null ? null : CaptureJourneyData(ref, selected);
    final pinned =
        ref.watch(pinnedJourneyIdsProvider).value ?? const <String>{};
    final shot = {
      ...?ref.watch(captureShotTodayProvider).value,
      if (data != null && data.today.isNotEmpty) selected!.id,
    };
    final session = _session;
    final canSwitch =
        (_phase == _Phase.ready || _phase == _Phase.starting) &&
        (session?.canSwitch ?? false) &&
        !_busy;
    return Column(
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: gutter, end: UiSpace.xs),
          child: CameraTopBar(
            journeys: journeys,
            selected: selected,
            chipLabel: selected == null || data == null
                ? null
                : l10n.camera_chipDay(selected.title, data.progress.dayNumber),
            accent: style?.accent,
            direction: _journeyDirection,
            onOpenPicker: () => _openPicker(list, selected),
            onRetry: () => ref.invalidate(captureJourneysProvider),
            tools: _tools(context, selected, style),
          ),
        ),
        const SizedBox(height: UiSpace.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: UiSpace.sm),
            child: _buildViewfinder(context, list, selected, data),
          ),
        ),
        const SizedBox(height: UiSpace.sm),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: SizedBox(
            height: 56,
            child: Row(
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
                const SizedBox(width: UiSpace.xs),
                Expanded(
                  child: list.length < 2
                      ? const SizedBox(height: UiSize.tap)
                      : LayoutBuilder(
                          builder: (context, box) {
                            // As many discs as fit; the last slot becomes the
                            // "All (N)" disc when there are more journeys.
                            final slots = (box.maxWidth / kCameraDiscSlot)
                                .floor()
                                .clamp(2, kCameraQuickDiscs + 1);
                            return Center(
                              child: JourneyDiscStrip(
                                journeys: quickCameraJourneys(
                                  list,
                                  selectedId: selected?.id,
                                  pinnedIds: pinned,
                                  shotTodayIds: shot,
                                  maxDiscs: slots,
                                ),
                                total: list.length,
                                selectedId: selected?.id,
                                accent: style?.accent,
                                pinnedIds: pinned,
                                shotTodayIds: shot,
                                onSelect: (id) {
                                  unawaited(UiHaptics.selection());
                                  _selectJourney(id, list: list);
                                },
                                onOpenAll: () => _openPicker(list, selected),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(width: UiSpace.xs),
                Tooltip(
                  message: l10n.camera_switchLens,
                  child: UiCameraTool(
                    key: const ValueKey('capture-switch'),
                    glyph: 'switch-camera',
                    label: l10n.camera_switchLens,
                    onPressed: canSwitch ? _switchLens : null,
                  ),
                ),
              ],
            ),
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
    CaptureJourneyData? data,
  ) {
    final l10n = CameraL10n.of(context);
    final session = _session;
    final ready = _phase == _Phase.ready;
    final Widget content = switch (_phase) {
      _Phase.ready when session != null => KeyedSubtree(
        key: const ValueKey('capture-preview'),
        child: session.buildPreview(),
      ),
      _Phase.starting when _switchingLens && session != null =>
        const ColoredBox(color: UiCamera.bg),
      _Phase.prePrompt => CameraPrePrompt(onAccept: _acceptPrePrompt),
      _Phase.failure => CameraFailurePanel(
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
            child: UiSpinner(strokeWidth: 3),
          ),
        ),
      ),
    };
    final viewfinder = ClipRRect(
      borderRadius: BorderRadius.circular(UiRadius.viewfinder),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: UiCamera.bg, child: content),
          if (_grid && ready) const CameraGrid(),
          if (journey != null && data != null && ready)
            Positioned.fill(
              child: CaptureSkinOverlay(
                key: ValueKey('capture-overlay-${journey.id}'),
                skin: personaSkinOf(journey),
                showGhost: _ghost,
                partnerPhotoFile: data.partnerPhoto,
              ),
            ),
          if (data != null && journey != null)
            PositionedDirectional(
              end: 14,
              top: 52,
              child: Semantics(
                label: l10n.camera_streakChip(data.progress.summary.current),
                excludeSemantics: true,
                child: UiGlassChip(
                  key: const ValueKey('capture-streak'),
                  label: '${data.progress.summary.current}',
                  leadingGlyph: 'flame',
                ),
              ),
            ),
          if (ready)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Center(
                child: UiCameraStatusPill(
                  key: const ValueKey('capture-status'),
                  message: _statusMessage,
                  glyph: _statusGlyph,
                  tone: _statusTone,
                  visible: _statusVisible,
                ),
              ),
            ),
          IgnorePointer(
            child: FadeTransition(
              key: const ValueKey('capture-lens-flip-scrim'),
              opacity: _lensFlipCurved,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: ColoredBox(
                    color: UiCamera.bg.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final heroTag = UiHeroTags.capturePhoto(
      _lastCaptureHeroKey ?? journey?.id ?? 'capture',
    );

    return Center(
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v.abs() > 250) {
              _nextJourney(list, journey, direction: v < 0 ? 1 : -1);
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              UiHero(
                tag: heroTag,
                borderRadiusBegin: BorderRadius.circular(UiRadius.viewfinder),
                borderRadiusEnd: BorderRadius.circular(UiRadius.card),
                child: viewfinder,
              ),
              IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(UiRadius.viewfinder),
                  child: FadeTransition(
                    key: const ValueKey('capture-shutter-flash'),
                    opacity: _flashOpacity,
                    child: const ColoredBox(color: UiCamera.ink),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
