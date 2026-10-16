import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/app_routes.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/chunky_button.dart';
import '../../shared/empty_state.dart';
import '../../shared/ourney_chip.dart';
import '../checkin/captured_photo.dart';
import 'camera_providers.dart';
import 'camera_session.dart';
import 'capture_services.dart';
import 'l10n/generated/camera_localizations.dart';

enum _Phase { idle, prePrompt, starting, ready, failure }

/// `/capture`: the app's start screen (FR-C1). Camera preview, journey chips
/// (remembering the last one), shutter, front/back switch, flash (FR-C2) and
/// library pick (FR-C3). The OS permission is requested in context after a
/// friendly pre-prompt; a denied state links to Settings.
///
/// Performance (NFR-1): the camera starts from `didChangeDependencies` of the
/// first build, in parallel with the journey stream; nothing else heavy runs
/// on the first frame. It is released whenever the screen is not visible
/// (other tab, `/checkin` on top: `TickerMode` off) or the app is hidden.
class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

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
    _selectedJourneyId = CameraPrefs.readLastJourneyId(
      ref.read(sharedPreferencesProvider),
    );
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
        if (gen == _generation) await session.stop();
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
    unawaited(
      CameraPrefs.writeLastJourneyId(ref.read(sharedPreferencesProvider), id),
    );
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
      Future<void>.delayed(OurneyDurations.flash, () {
        if (mounted) setState(() => _flashOverlay = false);
      });
    }
    final capturedAt = clock.now().toUtc();
    try {
      final path = await s.takePicture();
      if (!mounted) return;
      await _openCheckin(
        CapturedPhoto(
          journeyId: journey.id,
          path: path,
          capturedAt: capturedAt,
        ),
      );
    } on CameraStartException {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(CameraL10n.of(context).camera_captureFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _flashOverlay = false;
        });
      }
    }
  }

  Future<void> _pickFromLibrary(Journey journey) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final path = await ref.read(galleryPickerProvider).pickPhoto();
      if (path == null || !mounted) return;
      await _openCheckin(
        CapturedPhoto(
          journeyId: journey.id,
          path: path,
          capturedAt: clock.now().toUtc(),
          fromLibrary: true,
        ),
      );
    } on Object {
      // Picker unavailable or cancelled by the OS: nothing to do.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openCheckin(CapturedPhoto photo) async {
    unawaited(
      CameraPrefs.writeLastJourneyId(
        ref.read(sharedPreferencesProvider),
        photo.journeyId,
      ),
    );
    await context.push<void>(AppRoutes.checkin, extra: photo);
  }

  @override
  Widget build(BuildContext context) {
    final journeys = ref.watch(captureJourneysProvider);
    final lastId = _selectedJourneyId;
    final list = journeys.value ?? const <Journey>[];
    final selected = pickInitialJourney(list, lastId);

    final Widget body;
    if (journeys.hasValue && list.isEmpty) {
      body = EmptyState(
        key: const ValueKey('capture-no-journeys'),
        icon: Icons.flag_rounded,
        title: CameraL10n.of(context).camera_noJourneyTitle,
        message: CameraL10n.of(context).camera_noJourneyMessage,
        actionLabel: CameraL10n.of(context).camera_noJourneyAction,
        onAction: () => context.go(AppRoutes.journeyNew),
      );
    } else {
      body = Column(
        children: [
          _JourneyBar(
            journeys: journeys,
            selected: selected,
            onSelect: _selectJourney,
            onRetry: () => ref.invalidate(captureJourneysProvider),
          ),
          Expanded(child: _buildViewfinder(context)),
          _buildControls(context, selected),
        ],
      );
    }

    return Theme(
      data: buildAppTheme(Brightness.dark),
      child: Scaffold(
        key: CaptureScreen.screenKey,
        backgroundColor: OurneyColors.cameraBg,
        body: SafeArea(bottom: false, child: body),
      ),
    );
  }

  Widget _buildViewfinder(BuildContext context) {
    final c = OurneyColors.dark;
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
          label: CameraL10n.of(context).camera_starting,
          child: const SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: OurneySpacing.sm),
      child: Center(
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(OurneyRadii.media),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: c.surface, child: content),
                if (_phase == _Phase.ready && (session?.hasFlash ?? false))
                  Positioned(
                    top: OurneySpacing.md,
                    left: OurneySpacing.md,
                    child: _FlashButton(flash: _flash, onTap: _toggleFlash),
                  ),
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _flashOverlay ? 1 : 0,
                    duration: OurneyDurations.flash,
                    child: const ColoredBox(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, Journey? journey) {
    final l10n = CameraL10n.of(context);
    final ready = _phase == _Phase.ready && journey != null && !_busy;
    final canSwitch =
        (_phase == _Phase.ready || _phase == _Phase.starting) &&
        (_session?.canSwitch ?? false) &&
        !_busy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OurneySpacing.xl,
        OurneySpacing.lg,
        OurneySpacing.xl,
        OurneySpacing.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RoundIconButton(
            key: const ValueKey('capture-gallery'),
            icon: Icons.photo_library_rounded,
            label: l10n.camera_gallery,
            onTap: journey == null || _busy
                ? null
                : () => _pickFromLibrary(journey),
          ),
          _ShutterButton(
            label: journey == null
                ? l10n.camera_shutter
                : l10n.camera_shutterFor(journey.title),
            onTap: ready ? () => _capture(journey) : null,
          ),
          _RoundIconButton(
            key: const ValueKey('capture-switch'),
            icon: Icons.cameraswitch_rounded,
            label: l10n.camera_switchLens,
            onTap: canSwitch ? _switchLens : null,
          ),
        ],
      ),
    );
  }
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
    final c = OurneyColors.dark;
    final Widget child;
    if (journeys.hasError && !journeys.hasValue) {
      child = Row(
        children: [
          Icon(Icons.error_outline_rounded, color: c.danger, size: 20),
          const SizedBox(width: OurneySpacing.sm),
          Flexible(
            child: Text(
              l10n.camera_journeysError,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: c.ink),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context).common_retry),
          ),
        ],
      );
    } else if (!journeys.hasValue) {
      child = const SizedBox(height: OurneySizes.minTap);
    } else {
      final list = journeys.requireValue;
      child = Semantics(
        container: true,
        label: l10n.camera_journeyPicker,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final j in list)
                Padding(
                  padding: const EdgeInsets.only(right: OurneySpacing.sm),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: OurneyChip(
                      key: ValueKey('journey-chip-${j.id}'),
                      label: '${j.emoji} ${j.title}',
                      selected: j.id == selected?.id,
                      onTap: () => onSelect(j.id),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OurneySpacing.lg,
        OurneySpacing.sm,
        OurneySpacing.lg,
        OurneySpacing.md,
      ),
      child: child,
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.dark;
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        key: const ValueKey('capture-shutter'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: OurneySizes.captureButton,
          height: OurneySizes.captureButton,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: enabled ? Colors.white : c.inkMuted,
              width: 4,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? c.primary : c.inkMuted.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.dark;
    return IconButton(
      onPressed: onTap,
      tooltip: label,
      iconSize: 26,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(52),
        backgroundColor: c.surface,
        foregroundColor: c.ink,
        disabledBackgroundColor: c.surface.withValues(alpha: 0.5),
        disabledForegroundColor: c.inkMuted,
        side: BorderSide(color: c.border, width: 0.5),
      ),
      icon: Icon(icon),
    );
  }
}

class _FlashButton extends StatelessWidget {
  const _FlashButton({required this.flash, required this.onTap});

  final FlashSetting flash;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = CameraL10n.of(context);
    final (icon, label) = switch (flash) {
      FlashSetting.off => (Icons.flash_off_rounded, l10n.camera_flashOff),
      FlashSetting.auto => (Icons.flash_auto_rounded, l10n.camera_flashAuto),
      FlashSetting.on => (Icons.flash_on_rounded, l10n.camera_flashOn),
    };
    return IconButton(
      key: const ValueKey('capture-flash'),
      onPressed: onTap,
      tooltip: label,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(OurneySizes.minTap),
        backgroundColor: Colors.black.withValues(alpha: 0.45),
        foregroundColor: Colors.white,
      ),
      icon: Icon(icon),
    );
  }
}

/// Shared layout for the pre-prompt and failure panels: scrolls so it never
/// overflows at 2x text.
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
    final c = OurneyColors.dark;
    final text = Theme.of(context).textTheme;
    return Center(
      key: panelKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(OurneySpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(child: Icon(icon, size: 48, color: c.primary)),
            const SizedBox(height: OurneySpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: text.titleLarge?.copyWith(color: c.ink),
            ),
            const SizedBox(height: OurneySpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: c.inkMuted),
            ),
            for (final a in actions) ...[
              const SizedBox(height: OurneySpacing.lg),
              a,
            ],
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
      icon: Icons.camera_alt_outlined,
      title: l10n.camera_prePromptTitle,
      message: l10n.camera_prePromptMessage,
      actions: [
        ChunkyButton(
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
    final c = OurneyColors.dark;
    final retry = ChunkyButton(
      key: const ValueKey('capture-retry'),
      label: common.common_retry,
      onPressed: onRetry,
      variant: ChunkyVariant.neutral,
      expand: false,
    );
    final settings = ChunkyButton(
      key: const ValueKey('capture-open-settings'),
      label: l10n.camera_openSettings,
      onPressed: onOpenSettings,
      expand: false,
    );
    final settingsHint = Text(
      l10n.camera_deniedSettingsPath,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.inkMuted),
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
