import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsService;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/app_routes.dart';
import '../../app/providers.dart';
import '../../data/group_daily_checkins_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../personas/persona_contract.dart' show personaSkinOf;
import '../../ui/ui.dart';
import '../camera/capture_services.dart' show galleryPickerProvider;
import '../groups/ui/invite_sheet.dart' show showGroupInviteSheet;
import '../journeys/data/journeys_providers.dart'
    show journeyStartingWeightPrefKey, recentTripPlacesProvider;
import '../reminders/data/reminder_scheduler.dart';
import '../reminders/ui/reminder_permission_prompt.dart';
import '../widgets/data/widget_sync_controller.dart' show syncWidgetsNow;
import 'captured_photo.dart';
import 'checkin_audience.dart';
import 'checkin_clock.dart' show checkinClockProvider;
import 'checkin_controller.dart';
import 'checkin_progress.dart';
import 'checkin_success.dart';
import 'l10n/generated/checkin_localizations.dart';
import 'photo_compressor.dart';
import 'post_extras.dart';

/// `/checkin`: photo preview, caption (<= 140 code points), metric when the
/// journey has one, then Post (FR-C4). Shutter + Post = 2 taps; a retake on
/// the same day adds the "replace today's photo" confirmation (FR-C7).
///
/// 2026-11-20 redesign: close button header, Retake on the photo, a rounded
/// caption field (counter from 120 characters), and the photo collapses to a
/// 72x96 thumbnail beside the caption while the keyboard is open. The Post
/// button sits in the bottom bar, which rides on the keyboard.
class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({required this.photo, super.key});

  /// From `state.extra`; null when the route was opened without a photo
  /// (deep link, restored state).
  final CapturedPhoto? photo;

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen>
    with WidgetsBindingObserver {
  final _caption = TextEditingController();
  final _metric = TextEditingController();
  final _extras = PostExtrasController();
  final _captionFocus = FocusNode();
  bool _posting = false;
  bool _limitAnnounced = false;

  /// The caption counter appears from this many code points.
  static const int _counterFrom = 120;
  late final DraftFiles _drafts;
  bool _metricError = false;
  CheckInOutcome? _outcome;
  CapturedPhoto? _overridePhoto;
  final _metricKey = GlobalKey();
  final _extrasKey = GlobalKey();

  CapturedPhoto? get _activePhoto => _overridePhoto ?? widget.photo;

  /// The first-check-in notification offer; the success view waits for it
  /// before closing by itself (B-B2).
  Future<void>? _permissionOffer;

  @override
  void initState() {
    super.initState();
    _drafts = ref.read(draftFilesProvider);
    _caption.addListener(_onCaptionChanged);
    _captionFocus.addListener(_onCaptionFocus);
    WidgetsBinding.instance.addObserver(this);
  }

  bool _keyboardWasUp = false;

  /// The keyboard closing while the caption keeps focus (Android back
  /// gesture) would leave the thumbnail layout stuck: drop the focus so the
  /// full photo comes back.
  @override
  void didChangeMetrics() {
    final nowUp = View.of(context).viewInsets.bottom > 0;
    if (_keyboardWasUp && !nowUp && _captionFocus.hasFocus) {
      _captionFocus.unfocus();
    }
    _keyboardWasUp = nowUp;
  }

  /// The last logged value, shown as a hint (never as text: a stale value
  /// must not be posted by accident), with the locale's decimal separator.
  String? _lastMetricHint(CheckinL10n l10n, bool vi, String journeyId) {
    final last =
        widget.photo?.initialMetricValue ??
        ref
            .read(sharedPreferencesProvider)
            .getDouble(journeyStartingWeightPrefKey(journeyId));
    if (last == null) return null;
    var text = last == last.roundToDouble()
        ? last.toInt().toString()
        : last.toStringAsFixed(1);
    if (vi) text = text.replaceAll('.', ',');
    return l10n.checkin_metricLast(text);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _captionFocus
      ..removeListener(_onCaptionFocus)
      ..dispose();
    _caption
      ..removeListener(_onCaptionChanged)
      ..dispose();
    _metric.dispose();
    _extras.dispose();
    // Left without posting (close, back gesture): the raw camera/picker
    // file is not needed. After a post the poster already cleaned up.
    final photo = _activePhoto;
    if (photo != null && !_posting && _outcome == null) {
      unawaited(_drafts.discard([photo.path]));
    }
    super.dispose();
  }

  void _onCaptionChanged() {
    // One announcement when the 140-character limit is reached (the visible
    // counter is excluded from semantics).
    final atLimit = _caption.text.runes.length >= captionMax;
    if (atLimit && !_limitAnnounced && mounted) {
      unawaited(
        SemanticsService.sendAnnouncement(
          View.of(context),
          CheckinL10n.of(context).checkin_captionLimitReached(captionMax),
          Directionality.of(context),
        ),
      );
    }
    _limitAnnounced = atLimit;
    setState(() {});
  }

  void _onCaptionFocus() => setState(() {});

  /// Pops this screen and opens the share card on top of the camera:
  /// a `pushReplacement` would leave the capture screen's push future
  /// pending forever (go_router 18), so the screen below is told first.
  void _openShare(String journeyId) {
    final router = GoRouter.of(context);
    final target = AppRoutes.share(journeyId);
    if (router.canPop()) {
      router
        ..pop()
        ..push(target);
    } else {
      router.go(target);
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.capture);
    }
  }

  /// `72,5` (vi keyboards) and `72.5` both parse; empty means no value.
  static double? _parseMetric(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  Future<List<CheckIn>> _mine(String journeyId) async {
    final current = ref.read(myCheckInsProvider(journeyId));
    if (current.hasValue) return current.requireValue;
    try {
      return await ref
          .read(myCheckInsProvider(journeyId).future)
          .timeout(const Duration(seconds: 2));
    } on Object {
      // Unknown: the repository upserts anyway (a retake replaces today's).
      return const [];
    }
  }

  Future<void> _repickFromLibrary(CapturedPhoto current) async {
    if (_posting) return;
    final String? picked;
    try {
      picked = await ref.read(galleryPickerProvider).pickPhoto();
    } on Object {
      if (mounted) {
        showUiToast(context, CheckinL10n.of(context).checkin_errorPhoto);
      }
      return;
    }
    if (picked == null || !mounted) return;
    final String path = picked;
    unawaited(_drafts.discard([current.path]));
    setState(() {
      _overridePhoto = CapturedPhoto(
        journeyId: current.journeyId,
        path: path,
        capturedAt: ref.read(checkinClockProvider).nowUtc(),
        fromLibrary: true,
        initialMetricValue: current.initialMetricValue,
      );
    });
  }

  void _rejectValidation(String message, {GlobalKey? targetKey}) {
    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(UiHaptics.reject());
    final ctx = targetKey?.currentContext;
    if (ctx != null) {
      unawaited(
        Scrollable.ensureVisible(
          ctx,
          duration: UiMotion.fast,
          curve: UiCurves.easeOutStrong,
          alignment: 0.3,
        ),
      );
    } else {
      showUiToast(context, message);
    }
  }

  Future<void> _post(Journey journey, CapturedPhoto photo) async {
    if (_posting) return;
    final l10n = CheckinL10n.of(context);
    final caption = _caption.text.trim();
    if (validateCaption(caption) != null) {
      _rejectValidation(
        l10n.checkin_captionLimitReached(captionMax),
        targetKey: _captionKey,
      );
      return;
    }
    final skin = personaSkinOf(journey);
    final sport = journey.dna?['sport'] as String?;
    final measure = journey.dna?['measure'] as String?;
    final unit = (journey.metricUnit ?? '').trim().toLowerCase();
    final isRun =
        (sport == null || sport == 'run') &&
        (measure == null || measure == 'km') &&
        (unit.isEmpty || unit == 'km');
    if (skin == PersonaSkinId.aestheticFlexer &&
        isRun &&
        (_extras.paceInvalid || _extras.kmInvalid)) {
      _rejectValidation(
        _extras.kmInvalid
            ? l10n.checkin_extraKmInvalid
            : l10n.checkin_extraPaceInvalid,
        targetKey: _extrasKey,
      );
      return;
    }
    final extras = _extras.extrasFor(skin, isRunning: isRun);
    if (extras.validate() != null) {
      _rejectValidation(l10n.checkin_metricInvalid, targetKey: _extrasKey);
      return;
    }

    double? metric;
    if (journey.metricName != null) {
      final raw = _metric.text;
      metric = _parseMetric(raw);
      final invalid =
          (raw.trim().isNotEmpty && metric == null) ||
          validateMetricValue(metric) != null;
      setState(() => _metricError = invalid);
      if (invalid) {
        _rejectValidation(l10n.checkin_metricInvalid, targetKey: _metricKey);
        return;
      }
    }

    setState(() => _posting = true);
    final poster = ref.read(checkInPosterProvider);
    final mine = await _mine(journey.id);
    if (!mounted) return;
    // Bug #2: another photo the same day is added, never replaces (FR-C7).

    try {
      final outcome = await poster.post(
        journey: journey,
        membership: ref.read(myMembershipProvider(journey.id)).value,
        photo: photo,
        mine: mine,
        caption: caption.isEmpty ? null : caption,
        metricValue: metric,
        extras: extras,
      );
      if (!mounted) return;
      // Today is done: skip its reminder, move the 21:00 alert (FR-G1/G2).
      unawaited(rescheduleReminders(ref));
      unawaited(syncWidgetsNow(ref));
      // V2: the first check-in offers notifications once, so the 21:00
      // streak alert (on by default) can reach the person (bug #7).
      final offer = offerReminderPermission(
        context,
        ref,
        time: reminderOfferTime(ref, journey.id),
      );
      setState(() {
        _outcome = outcome;
        _permissionOffer = offer;
      });
    } on CheckInPostException catch (e) {
      if (!mounted) return;
      setState(() => _posting = false);
      final message = switch (e.failure) {
        CheckInFailure.photo => l10n.checkin_errorPhoto,
        CheckInFailure.ended => l10n.checkin_errorEnded,
        CheckInFailure.generic => AppLocalizations.of(
          context,
        ).common_errorGeneric,
      };
      showUiToast(context, message);
    } on Object {
      // Never leave the spinner up: anything else is a generic failure.
      if (!mounted) return;
      setState(() => _posting = false);
      showUiToast(context, AppLocalizations.of(context).common_errorGeneric);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keeps OurneyHaptics.enabled in sync with the user's toggle.
    final haptics = ref.watch(hapticsEnabledProvider);
    final l10n = CheckinL10n.of(context);
    final photo = _activePhoto;

    if (photo == null) {
      return _frame(
        body: UiEmptyState(
          key: const ValueKey('checkin-missing-photo'),
          glyph: const OurneyIcon(name: 'camera-off', size: 30),
          title: l10n.checkin_missingPhoto,
          actionLabel: AppLocalizations.of(context).common_close,
          onAction: _close,
        ),
      );
    }

    final outcome = _outcome;
    if (outcome != null) {
      return CheckinSuccessView(
        key: const ValueKey('checkin-success'),
        outcome: outcome,
        journey: ref.watch(checkinJourneyProvider(photo.journeyId)).value,
        haptics: haptics,
        onDone: _close,
        onShare: () => _openShare(photo.journeyId),
        holdAutoClose: _permissionOffer,
      );
    }

    // Start loading what Post needs while the user types.
    ref
      ..watch(myCheckInsProvider(photo.journeyId))
      ..watch(myMembershipProvider(photo.journeyId));
    final journey = ref.watch(checkinJourneyProvider(photo.journeyId));

    return switch (journey) {
      AsyncData(value: final j?) => UiSkinScope(
        skinId: uiSkinIdFor(personaSkinOf(j)),
        child: Builder(builder: (context) => _compose(context, j, photo)),
      ),
      AsyncError() => _frame(
        body: UiEmptyState(
          key: const ValueKey('checkin-journey-error'),
          glyph: const OurneyIcon(name: 'error', size: 30),
          title: AppLocalizations.of(context).common_errorGeneric,
          actionLabel: AppLocalizations.of(context).common_retry,
          onAction: () =>
              ref.invalidate(checkinJourneyProvider(photo.journeyId)),
        ),
      ),
      AsyncData() => _frame(
        body: UiEmptyState(
          key: const ValueKey('checkin-missing-journey'),
          glyph: const OurneyIcon(name: 'flag', size: 30),
          title: l10n.checkin_missingJourney,
          actionLabel: AppLocalizations.of(context).common_close,
          onAction: _close,
        ),
      ),
      _ => _frame(
        body: Center(
          child: UiSpinner(
            semanticsLabel: AppLocalizations.of(context).common_loading,
          ),
        ),
      ),
    };
  }

  /// Plain frame for the empty / loading states.
  Widget _frame({required Widget body}) {
    return UiScaffold(
      key: const ValueKey('checkin-screen'),
      scroll: false,
      child: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: UiIconButton(
              glyph: const OurneyIcon(name: 'close', size: 20),
              label: AppLocalizations.of(context).common_close,
              onPressed: _close,
            ),
          ),
          Expanded(child: UiFillScroll(child: body)),
        ],
      ),
    );
  }

  final _captionKey = GlobalKey();

  Widget _captionField(
    CheckinL10n l10n, {
    required bool vi,
    required JourneyTemplate template,
    required String semanticsLabel,
    required int count,
  }) {
    return UiCaptionField(
      key: _captionKey,
      fieldKey: const ValueKey('checkin-caption'),
      controller: _caption,
      focusNode: _captionFocus,
      readOnly: _posting,
      semanticLabel: semanticsLabel,
      hint: vi ? template.captionPromptVi : template.captionPromptEn,
      inputFormatters: [_CodePointLimit(captionMax)],
      // The counter only shows near the limit; screen readers always get it.
      counter: count >= _counterFrom
          ? l10n.checkin_captionCounter(count, captionMax)
          : null,
      counterKey: const ValueKey('checkin-caption-counter'),
      counterDanger: count >= captionMax,
      counterSemantics: l10n.checkin_captionCounterSemantics(count, captionMax),
    );
  }

  Widget? _couplePartnerPrompt(
    BuildContext context,
    Journey journey,
    CapturedPhoto photo,
  ) {
    if (!isCoupleGroup(journey) || journey.status != JourneyStatus.active) {
      return null;
    }
    final group = ref.watch(groupDailySnapshotProvider(journey));
    final l10n = CheckinL10n.of(context);
    if (group.canInvitePartner) {
      return UiButton.secondary(
        key: const ValueKey('checkin-couple-invite'),
        label: l10n.checkin_coupleInvite,
        glyph: const OurneyIcon(name: 'user-plus', size: 20),
        onPressed: _posting
            ? null
            : () => unawaited(showGroupInviteSheet(context, journey.id)),
      );
    }
    if (group.partnerId == null) return null;
    final date = ref
        .watch(checkinClockProvider)
        .localDate(photo.capturedAt, journey.timezone);
    if (group.partnerPostedOn(date)) return null;
    return Text(
      l10n.checkin_coupleWaiting,
      style: UiText.body(color: context.ui.inkMuted),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );
  }

  Widget _compose(BuildContext context, Journey journey, CapturedPhoto photo) {
    final l10n = CheckinL10n.of(context);
    final ui = context.ui;
    final style = uiStyleForSkin(personaSkinOf(journey));
    final count = _caption.text.runes.length;
    final membership = ref.watch(myMembershipProvider(journey.id)).value;
    final hideMetric = membership?.hideMetric ?? journey.hideMetricDefault;
    final template = templateFor(journey.templateId);
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    // The thumbnail swap follows the caption's focus, not any keyboard (the
    // metric field's keyboard keeps the full photo).
    final typing = _captionFocus.hasFocus;
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
    final metricName = journey.metricName;
    final metricLabel = metricName == null
        ? null
        : journey.metricUnit == null
        ? metricName
        : '$metricName (${journey.metricUnit})';
    final partnerPrompt = _couplePartnerPrompt(context, journey, photo);
    final privacy = switch (watchCheckinAudience(ref, journey)) {
      CheckinAudience.unknown => null,
      CheckinAudience.private => (
        UiPrivacy.private,
        l10n.checkin_privacyPrivate,
      ),
      CheckinAudience.shared => (UiPrivacy.link, l10n.checkin_privacyShared),
      CheckinAudience.couple => (UiPrivacy.couple, l10n.checkin_privacyCouple),
      CheckinAudience.squad => (UiPrivacy.squad, l10n.checkin_privacySquad),
      CheckinAudience.futureMembers => (
        isCoupleGroup(journey) ? UiPrivacy.couple : UiPrivacy.squad,
        l10n.checkin_privacyFutureMembers,
      ),
    };
    // Per-skin copy of the Figma Post screens (primary label, caption label).
    final skin = personaSkinOf(journey);
    final recentPlaces = skin == PersonaSkinId.memoryCollectors
        ? ref.watch(recentTripPlacesProvider).asData?.value ?? const <String>[]
        : const <String>[];
    final sport = journey.dna?['sport'] as String?;
    final measure = journey.dna?['measure'] as String?;
    final unit = (journey.metricUnit ?? '').trim().toLowerCase();
    final isRun =
        (sport == null || sport == 'run') &&
        (measure == null || measure == 'km') &&
        (unit.isEmpty || unit == 'km');
    final postLabel = switch (skin) {
      PersonaSkinId.memoryCollectors => l10n.checkin_postMemory,
      _ => l10n.checkin_post,
    };
    final captionSemantics = switch (skin) {
      PersonaSkinId.memoryCollectors => l10n.checkin_captionLabelMemory,
      PersonaSkinId.aestheticFlexer =>
        isRun ? l10n.checkin_captionLabelFlexer : l10n.checkin_captionLabel,
      _ => l10n.checkin_captionLabel,
    };
    final width = MediaQuery.sizeOf(context).width;
    final gutter = UiSpace.gutter(width);

    return UiScaffold(
      key: const ValueKey('checkin-screen'),
      padTop: 0,
      padBottom: UiSpace.lg,
      bottom: Center(
        child: Padding(
          // UiScaffold's pinned slot already clears the safe area; the
          // bar hugs the keyboard while it is up.
          padding: EdgeInsets.fromLTRB(
            gutter,
            UiSpace.sm,
            gutter,
            keyboardUp ? UiSpace.sm : UiSpace.lg,
          ),
          child: UiButton(
            key: const ValueKey('checkin-post'),
            label: _posting ? l10n.checkin_posting : postLabel,
            glyph: const OurneyIcon(name: 'send', size: 20),
            accent: style.accent,
            onAccent: style.onAccent,
            onPressed: _posting ? null : () => _post(journey, photo),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // `.compose-header`: close | journey + privacy | (empty).
          Row(
            children: [
              UiIconButton(
                key: const ValueKey('checkin-close'),
                glyph: const OurneyIcon(name: 'close', size: 20),
                label: AppLocalizations.of(context).common_close,
                onPressed: _posting ? null : _close,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      journey.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: UiText.body(
                        size: 13,
                        weight: FontWeight.w700,
                        height: 1.4,
                        color: ui.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (privacy == null)
                      Text(
                        l10n.checkin_privacyPending,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.body(
                          size: 11,
                          height: 1.4,
                          weight: FontWeight.w500,
                          color: ui.inkMuted,
                        ),
                      )
                    else
                      UiPrivacyTag(type: privacy.$1, label: privacy.$2),
                  ],
                ),
              ),
              // Keeps the title centred (U21: the bottom Post button is the
              // only Post action).
              const SizedBox(width: UiSize.tap),
            ],
          ),
          const SizedBox(height: UiSpace.sm),
          // Photo + caption (Rank #1 Phase 1c): smoothly morphs between the
          // 520dp preview above the caption and the 72x96 thumbnail beside
          // the caption via AnimatedSize + AnimatedSwitcher while keeping
          // the caption TextField mounted in a single permanent slot so
          // focus and GlobalKey state never teleport or duplicate.
          Align(
            alignment: Alignment.topCenter,
            child: Builder(
              builder: (context) {
                final reduced = UiMotion.reduced(context);
                final previewSwitcher = AnimatedSwitcher(
                  duration: UiMotion.fadeOf(context, UiMotion.medium),
                  switchInCurve: reduced
                      ? Curves.linear
                      : UiCurves.easeOutStrong,
                  switchOutCurve: reduced
                      ? Curves.linear
                      : UiCurves.easeOutStrong.flipped,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: reduced
                        ? child
                        : SizeTransition(
                            axis: Axis.vertical,
                            alignment: Alignment.topCenter,
                            sizeFactor: animation,
                            child: child,
                          ),
                  ),
                  child: typing
                      ? const SizedBox.shrink(
                          key: ValueKey('checkin-preview-collapsed'),
                        )
                      : Padding(
                          key: const ValueKey('checkin-compose-idle'),
                          padding: const EdgeInsets.only(bottom: UiSpace.lg),
                          child: _PhotoPreview(
                            photo: photo,
                            onRetake: _posting
                                ? null
                                : photo.fromLibrary
                                ? () => _repickFromLibrary(photo)
                                : _close,
                          ),
                        ),
                );

                final thumbSwitcher = AnimatedSwitcher(
                  duration: UiMotion.fadeOf(context, UiMotion.medium),
                  switchInCurve: reduced
                      ? Curves.linear
                      : UiCurves.easeOutStrong,
                  switchOutCurve: reduced
                      ? Curves.linear
                      : UiCurves.easeOutStrong.flipped,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: reduced
                        ? child
                        : SizeTransition(
                            axis: Axis.horizontal,
                            alignment: AlignmentDirectional.topStart,
                            sizeFactor: animation,
                            child: child,
                          ),
                  ),
                  child: typing
                      ? Padding(
                          key: const ValueKey('checkin-compose-typing'),
                          padding: const EdgeInsetsDirectional.only(
                            end: UiSpace.md,
                          ),
                          child: _PhotoThumb(
                            photo: photo,
                            onTap: () =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                          ),
                        )
                      : const SizedBox.shrink(
                          key: ValueKey('checkin-thumb-collapsed'),
                        ),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    KeyedSubtree(
                      key: const ValueKey('checkin-preview-size'),
                      child: previewSwitcher,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KeyedSubtree(
                          key: const ValueKey('checkin-thumb-size'),
                          child: thumbSwitcher,
                        ),
                        Expanded(
                          child: _captionField(
                            l10n,
                            vi: vi,
                            template: template,
                            semanticsLabel: captionSemantics,
                            count: count,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          if (metricLabel != null) ...[
            const SizedBox(height: UiSpace.lg),
            KeyedSubtree(
              key: _metricKey,
              child: UiTextField(
                fieldKey: const ValueKey('checkin-metric'),
                label: metricLabel,
                hint: _lastMetricHint(l10n, vi, journey.id),
                controller: _metric,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                ],
                onChanged: (_) {
                  if (_metricError) setState(() => _metricError = false);
                },
                error: _metricError ? l10n.checkin_metricInvalid : null,
                helper: hideMetric ? l10n.checkin_metricPrivate : null,
                trailing: hideMetric
                    ? OurneyIcon(
                        name: 'lock',
                        flat: true,
                        size: 18,
                        color: ui.inkMuted,
                      )
                    : null,
              ),
            ),
          ],
          KeyedSubtree(
            key: _extrasKey,
            child: PostExtrasSection(
              skin: skin,
              controller: _extras,
              selfName: journey.coupleSelfName,
              partnerName: journey.couplePartnerName,
              ritual: journey.dna?['ritual'] as String?,
              isRunning: isRun,
              destination: journey.dna?['place'] as String?,
              recentPlaces: recentPlaces,
            ),
          ),
          if (partnerPrompt != null) ...[
            const SizedBox(height: UiSpace.md),
            partnerPrompt,
          ],
        ],
      ),
    );
  }
}

/// `.compose-photo`: 3:4 photo with 20dp corners, up to 55% of the height
/// (max 520). Retake is a glass button on the photo, bottom-start.
class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photo, required this.onRetake});

  final CapturedPhoto photo;
  final VoidCallback? onRetake;

  @override
  Widget build(BuildContext context) {
    final l10n = CheckinL10n.of(context);
    final mq = MediaQuery.of(context);
    final available = mq.size.height - mq.padding.vertical;
    // Large text leaves little room: the photo shrinks to 45% of the usable
    // height so the caption and fields stay in reach (the form scrolls).
    final big = mq.textScaler.scale(16) / 16 > 1.35;
    final height = (available * (big ? 0.45 : 0.55)).clamp(0.0, 520.0);
    return Center(
      child: LayoutBuilder(
        builder: (context, box) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: math.min(height, box.maxWidth * 4 / 3),
          ),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: UiHero(
              tag: UiHeroTags.capturePhoto(photo.path),
              borderRadiusBegin: BorderRadius.circular(UiRadius.viewfinder),
              borderRadiusEnd: BorderRadius.circular(UiRadius.card),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(UiRadius.card),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: UiCamera.bg,
                      child: Semantics(
                        image: true,
                        label: l10n.checkin_photoSemantics,
                        child: Image.file(
                          File(photo.path),
                          fit: BoxFit.cover,
                          cacheWidth: 1080,
                          errorBuilder: (_, _, _) => const OurneyIcon(
                            name: 'image',
                            flat: true,
                            color: UiCamera.onPhoto,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                    if (photo.fromLibrary)
                      PositionedDirectional(
                        start: UiSpace.md,
                        end: UiSpace.md,
                        top: UiSpace.md,
                        child: Align(
                          alignment: AlignmentDirectional.topStart,
                          child: UiTag(
                            key: const ValueKey('checkin-from-library'),
                            label: l10n.checkin_fromLibrary,
                            glyph: const OurneyIcon(name: 'gallery', size: 20),
                            background: const Color(0xB3000000),
                            foreground: UiCamera.onPhoto,
                            borderColor: UiCamera.outline,
                          ),
                        ),
                      ),
                    PositionedDirectional(
                      start: UiSpace.sm,
                      end: UiSpace.sm,
                      bottom: UiSpace.sm,
                      child: Align(
                        alignment: AlignmentDirectional.bottomStart,
                        child: UiPressable(
                          key: const ValueKey('checkin-retake'),
                          onPressed: onRetake,
                          semanticLabel: photo.fromLibrary
                              ? l10n.checkin_chooseAnother
                              : l10n.checkin_retake,
                          excludeChildSemantics: true,
                          borderRadius: BorderRadius.circular(UiRadius.capsule),
                          child: Container(
                            constraints: const BoxConstraints(
                              minHeight: UiSize.tap,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xB3000000),
                              borderRadius: BorderRadius.circular(
                                UiRadius.capsule,
                              ),
                              border: Border.all(color: UiCamera.dockBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OurneyIcon(
                                  name: photo.fromLibrary
                                      ? 'gallery'
                                      : 'refresh',
                                  flat: true,
                                  size: 18,
                                  color: UiCamera.onPhoto,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    photo.fromLibrary
                                        ? l10n.checkin_chooseAnother
                                        : l10n.checkin_retake,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: UiText.body(
                                      size: 14,
                                      weight: FontWeight.w600,
                                      height: 1.3,
                                      color: UiCamera.onPhoto,
                                    ),
                                  ),
                                ),
                              ],
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
        ),
      ),
    );
  }
}

/// 72x96 thumbnail shown beside the caption while the keyboard is open. Tap
/// closes the keyboard (and brings the full photo back).
class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.photo, required this.onTap});

  final CapturedPhoto photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = CheckinL10n.of(context);
    return UiPressable(
      key: const ValueKey('checkin-photo-thumb'),
      onPressed: onTap,
      semanticLabel: l10n.checkin_photoSemantics,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(UiRadius.thumb),
      child: SizedBox(
        width: 72,
        height: 96,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(UiRadius.thumb),
          child: ColoredBox(
            color: UiCamera.bg,
            child: Image.file(
              File(photo.path),
              fit: BoxFit.cover,
              cacheWidth: 240,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => const Center(
                child: OurneyIcon(
                  name: 'image',
                  flat: true,
                  color: UiCamera.onPhoto,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Limits input to [max] Unicode code points, matching `validateCaption`
/// and the server CHECK (Flutter's `maxLength` counts grapheme clusters).
class _CodePointLimit extends TextInputFormatter {
  const _CodePointLimit(this.max);

  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final runes = newValue.text.runes;
    if (runes.length <= max) return newValue;
    final text = String.fromCharCodes(runes.take(max));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
