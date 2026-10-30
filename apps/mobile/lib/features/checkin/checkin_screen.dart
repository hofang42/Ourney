import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/app_routes.dart';
import '../../app/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../personas/persona_contract.dart' show personaSkinOf;
import '../../ui/ui.dart';
import '../reminders/data/reminder_scheduler.dart';
import 'captured_photo.dart';
import 'checkin_controller.dart';
import 'checkin_progress.dart';
import 'checkin_success.dart';
import 'l10n/generated/checkin_localizations.dart';
import 'photo_compressor.dart';

/// `/checkin`: photo preview, caption (<= 140 code points), metric when the
/// journey has one, then Post (FR-C4). Shutter + Post = 2 taps; a retake on
/// the same day adds the "replace today's photo" confirmation (FR-C7).
class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({required this.photo, super.key});

  /// From `state.extra`; null when the route was opened without a photo
  /// (deep link, restored state).
  final CapturedPhoto? photo;

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  final _caption = TextEditingController();
  final _metric = TextEditingController();
  bool _posting = false;
  late final DraftFiles _drafts;
  bool _metricError = false;
  CheckInOutcome? _outcome;

  @override
  void initState() {
    super.initState();
    _drafts = ref.read(draftFilesProvider);
    _caption.addListener(_onCaptionChanged);
    final initialMetric = widget.photo?.initialMetricValue;
    if (initialMetric != null) {
      _metric.text = initialMetric == initialMetric.roundToDouble()
          ? initialMetric.toInt().toString()
          : initialMetric.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _caption
      ..removeListener(_onCaptionChanged)
      ..dispose();
    _metric.dispose();
    // Left without posting (close, back gesture): the raw camera/picker
    // file is not needed. After a post the poster already cleaned up.
    final photo = widget.photo;
    if (photo != null && !_posting && _outcome == null) {
      unawaited(_drafts.discard([photo.path]));
    }
    super.dispose();
  }

  void _onCaptionChanged() => setState(() {});

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

  Future<void> _post(Journey journey, CapturedPhoto photo) async {
    if (_posting) return;
    final l10n = CheckinL10n.of(context);
    final caption = _caption.text.trim();
    if (validateCaption(caption) != null) return;

    double? metric;
    if (journey.metricName != null) {
      final raw = _metric.text;
      metric = _parseMetric(raw);
      final invalid =
          (raw.trim().isNotEmpty && metric == null) ||
          validateMetricValue(metric) != null;
      setState(() => _metricError = invalid);
      if (invalid) return;
    }

    setState(() => _posting = true);
    final poster = ref.read(checkInPosterProvider);
    final mine = await _mine(journey.id);
    if (!mounted) return;
    if (poster.replacesExisting(journey, photo, mine)) {
      final ok = await showUiSheet<bool>(
        context: context,
        builder: (context) => Column(
          key: const ValueKey('checkin-replace-dialog'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.checkin_replaceTitle,
              style: UiText.h2(color: context.ui.ink),
            ),
            const SizedBox(height: UiSpace.sm),
            Text(
              l10n.checkin_replaceMessage,
              style: UiText.muted(color: context.ui.inkMuted, size: 14),
            ),
            const SizedBox(height: UiSpace.xl),
            UiButton(
              key: const ValueKey('checkin-replace-confirm'),
              label: l10n.checkin_replaceConfirm,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: UiSpace.sm),
            UiButton.secondary(
              label: AppLocalizations.of(context).common_cancel,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (ok != true) {
        setState(() => _posting = false);
        return;
      }
    }

    try {
      final outcome = await poster.post(
        journey: journey,
        membership: ref.read(myMembershipProvider(journey.id)).value,
        photo: photo,
        mine: mine,
        caption: caption.isEmpty ? null : caption,
        metricValue: metric,
      );
      if (!mounted) return;
      setState(() => _outcome = outcome);
      // Today is done: skip its reminder, move the 21:00 alert (FR-G1/G2).
      unawaited(rescheduleReminders(ref));
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
    final photo = widget.photo;

    if (photo == null) {
      return _frame(
        body: UiEmptyState(
          key: const ValueKey('checkin-missing-photo'),
          icon: Icons.no_photography_outlined,
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
      );
    }

    // Start loading what Post needs while the user types.
    ref
      ..watch(myCheckInsProvider(photo.journeyId))
      ..watch(myMembershipProvider(photo.journeyId));
    final journey = ref.watch(checkinJourneyProvider(photo.journeyId));

    return switch (journey) {
      AsyncData(value: final j?) => _compose(context, j, photo),
      AsyncData() || AsyncError() => _frame(
        body: UiEmptyState(
          key: const ValueKey('checkin-missing-journey'),
          icon: Icons.flag_outlined,
          title: l10n.checkin_missingJourney,
          actionLabel: AppLocalizations.of(context).common_close,
          onAction: _close,
        ),
      ),
      _ => _frame(body: const Center(child: CircularProgressIndicator())),
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
              icon: Icons.close_rounded,
              label: AppLocalizations.of(context).common_close,
              onPressed: _close,
            ),
          ),
          Expanded(child: UiFillScroll(child: body)),
        ],
      ),
    );
  }

  Widget _compose(BuildContext context, Journey journey, CapturedPhoto photo) {
    final l10n = CheckinL10n.of(context);
    final ui = context.ui;
    final style = uiStyleForSkin(personaSkinOf(journey));
    // `--accent-ink`: the accent as text, the warm ink where the accent is
    // too light to read on paper.
    final accentInk = ui.isDark ? style.accent : ui.warn;
    final count = _caption.text.runes.length;
    final membership = ref.watch(myMembershipProvider(journey.id)).value;
    final hideMetric = membership?.hideMetric ?? journey.hideMetricDefault;
    final template = templateFor(journey.templateId);
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    final metricName = journey.metricName;
    final metricLabel = metricName == null
        ? null
        : journey.metricUnit == null
        ? metricName
        : '$metricName (${journey.metricUnit})';
    final privacy = journey.kind == JourneyKind.solo
        ? (UiPrivacy.private, l10n.checkin_privacyPrivate)
        : journey.maxMembers == 2
        ? (UiPrivacy.couple, l10n.checkin_privacyCouple)
        : (UiPrivacy.squad, l10n.checkin_privacySquad);
    final width = MediaQuery.sizeOf(context).width;
    final gutter = UiSpace.gutter(width);

    return UiScaffold(
      key: const ValueKey('checkin-screen'),
      padTop: 0,
      padBottom: UiSpace.lg,
      bottom: Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, UiSpace.sm, gutter, UiSpace.lg),
          child: SafeArea(
            top: false,
            child: UiButton(
              key: const ValueKey('checkin-post'),
              label: _posting ? l10n.checkin_posting : l10n.checkin_post,
              icon: Icons.send_rounded,
              accent: style.accent,
              onAccent: style.onAccent,
              onPressed: _posting ? null : () => _post(journey, photo),
            ),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // `.compose-header`: Retake | journey + privacy | Post.
          Row(
            children: [
              Expanded(
                child: UiTextAction(
                  key: const ValueKey('checkin-retake'),
                  label: l10n.checkin_retake,
                  onPressed: _posting ? null : _close,
                  alignment: AlignmentDirectional.centerStart,
                  size: 14,
                ),
              ),
              Expanded(
                flex: 2,
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
                    UiPrivacyTag(type: privacy.$1, label: privacy.$2),
                  ],
                ),
              ),
              Expanded(
                child: UiTextAction(
                  key: const ValueKey('checkin-post-link'),
                  label: l10n.checkin_post,
                  onPressed: _posting ? null : () => _post(journey, photo),
                  alignment: AlignmentDirectional.centerEnd,
                  color: accentInk,
                  size: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: UiSpace.sm),
          _PhotoPreview(photo: photo),
          const SizedBox(height: UiSpace.lg),
          // `.caption-field`: label + underlined textarea.
          Text(
            l10n.checkin_captionLabel,
            style: UiText.fieldLabel(color: ui.inkMuted),
          ),
          TextField(
            key: const ValueKey('checkin-caption'),
            controller: _caption,
            minLines: 1,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [_CodePointLimit(captionMax)],
            cursorColor: ui.ink,
            style: UiText.body(size: 16, height: 1.45, color: ui.ink),
            decoration: InputDecoration(
              isDense: true,
              hintText: vi
                  ? template.captionPromptVi
                  : template.captionPromptEn,
              hintStyle: UiText.body(
                size: 16,
                height: 1.45,
                color: ui.inkMuted,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: ui.border),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: ui.ink, width: 2),
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Semantics(
              label: l10n.checkin_captionCounterSemantics(count, captionMax),
              child: ExcludeSemantics(
                child: Text(
                  l10n.checkin_captionCounter(count, captionMax),
                  key: const ValueKey('checkin-caption-counter'),
                  style: UiText.body(
                    size: 12,
                    color: count >= captionMax ? ui.danger : ui.inkMuted,
                  ),
                ),
              ),
            ),
          ),
          if (metricLabel != null) ...[
            const SizedBox(height: UiSpace.md),
            UiTextField(
              fieldKey: const ValueKey('checkin-metric'),
              label: metricLabel,
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
                  ? Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: ui.inkMuted,
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

/// `.compose-photo`: 3:4 photo with 20dp corners, capped in height.
class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photo});

  final CapturedPhoto photo;

  @override
  Widget build(BuildContext context) {
    final l10n = CheckinL10n.of(context);
    final height = (MediaQuery.sizeOf(context).height * 0.45).clamp(0.0, 462.0);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height),
        child: AspectRatio(
          aspectRatio: 3 / 4,
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
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: UiCamera.ink,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                if (photo.fromLibrary)
                  Positioned(
                    left: UiSpace.md,
                    bottom: UiSpace.md,
                    child: UiTag(
                      key: const ValueKey('checkin-from-library'),
                      label: l10n.checkin_fromLibrary,
                      icon: Icons.photo_library_outlined,
                      background: const Color(0xB3000000),
                      foreground: UiCamera.ink,
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
