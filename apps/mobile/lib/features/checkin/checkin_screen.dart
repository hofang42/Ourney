import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/app_routes.dart';
import '../../app/providers.dart';
import '../../app/theme/persona_theme.dart';
import '../../app/theme/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../personas/persona_contract.dart';
import '../../shared/empty_state.dart';
import '../../shared/ourney_primary_button.dart';
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
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          key: const ValueKey('checkin-replace-dialog'),
          title: Text(l10n.checkin_replaceTitle),
          content: Text(l10n.checkin_replaceMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context).common_cancel),
            ),
            TextButton(
              key: const ValueKey('checkin-replace-confirm'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.checkin_replaceConfirm),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keeps OurneyHaptics.enabled in sync with the user's toggle.
    final haptics = ref.watch(hapticsEnabledProvider);
    final l10n = CheckinL10n.of(context);
    final photo = widget.photo;

    if (photo == null) {
      return _scaffold(
        title: l10n.checkin_title,
        body: EmptyState(
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
      return Scaffold(
        key: const ValueKey('checkin-success'),
        body: SafeArea(
          child: CheckinSuccessView(
            outcome: outcome,
            haptics: haptics,
            onDone: _close,
            onShare: () => _openShare(photo.journeyId),
          ),
        ),
      );
    }

    // Start loading what Post needs while the user types.
    ref
      ..watch(myCheckInsProvider(photo.journeyId))
      ..watch(myMembershipProvider(photo.journeyId));
    final journey = ref.watch(checkinJourneyProvider(photo.journeyId));

    return switch (journey) {
      AsyncData(value: final j?) => _scaffold(
        title: j.title,
        body: _form(context, j, photo),
      ),
      AsyncData() || AsyncError() => _scaffold(
        title: l10n.checkin_title,
        body: EmptyState(
          key: const ValueKey('checkin-missing-journey'),
          title: l10n.checkin_missingJourney,
          actionLabel: AppLocalizations.of(context).common_close,
          onAction: _close,
        ),
      ),
      _ => _scaffold(
        title: l10n.checkin_title,
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }

  Widget _scaffold({required String title, required Widget body}) {
    return Scaffold(
      key: const ValueKey('checkin-screen'),
      appBar: AppBar(
        leading: CloseButton(onPressed: _close),
        centerTitle: true,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _form(BuildContext context, Journey journey, CapturedPhoto photo) {
    final l10n = CheckinL10n.of(context);
    final c = OurneyColors.of(context);
    final text = Theme.of(context).textTheme;
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

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(OurneySpacing.screenMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PhotoPreview(photo: photo),
                const SizedBox(height: OurneySpacing.xl),
                TextField(
                  key: const ValueKey('checkin-caption'),
                  controller: _caption,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [_CodePointLimit(captionMax)],
                  decoration: InputDecoration(
                    labelText: l10n.checkin_captionLabel,
                    hintText: vi
                        ? template.captionPromptVi
                        : template.captionPromptEn,
                    counter: Semantics(
                      label: l10n.checkin_captionCounterSemantics(
                        count,
                        captionMax,
                      ),
                      child: ExcludeSemantics(
                        child: Text(
                          l10n.checkin_captionCounter(count, captionMax),
                          key: const ValueKey('checkin-caption-counter'),
                          style: text.bodySmall?.copyWith(
                            color: count >= captionMax ? c.danger : c.inkMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (metricLabel != null) ...[
                  const SizedBox(height: OurneySpacing.lg),
                  TextField(
                    key: const ValueKey('checkin-metric'),
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
                    decoration: InputDecoration(
                      labelText: metricLabel,
                      errorText: _metricError
                          ? l10n.checkin_metricInvalid
                          : null,
                      helperText: hideMetric
                          ? l10n.checkin_metricPrivate
                          : null,
                      helperMaxLines: 2,
                      prefixIcon: hideMetric
                          ? const Icon(Icons.lock_outline_rounded)
                          : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            OurneySpacing.screenMargin,
            OurneySpacing.sm,
            OurneySpacing.screenMargin,
            OurneySpacing.lg,
          ),
          // V1.0 "Post moment": the journey's accent with its readable ink.
          child: OurneyPrimaryButton(
            key: const ValueKey('checkin-post'),
            label: _posting ? l10n.checkin_posting : l10n.checkin_post,
            icon: Icons.send_rounded,
            backgroundColor: OurneyPersonaTheme.forSkin(
              personaSkinOf(journey),
              Theme.of(context).brightness,
            ).primaryAccent,
            onPressed: _posting ? null : () => _post(journey, photo),
          ),
        ),
      ],
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photo});

  final CapturedPhoto photo;

  @override
  Widget build(BuildContext context) {
    final l10n = CheckinL10n.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.45;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(OurneyRadii.media),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: OurneyColors.cameraBg,
                  child: Semantics(
                    image: true,
                    label: l10n.checkin_photoSemantics,
                    child: Image.file(
                      File(photo.path),
                      fit: BoxFit.cover,
                      cacheWidth: 1080,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                if (photo.fromLibrary)
                  Positioned(
                    left: OurneySpacing.md,
                    bottom: OurneySpacing.md,
                    child: _FromLibraryBadge(label: l10n.checkin_fromLibrary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "From library" label (FR-C3): icon + text, not color alone.
class _FromLibraryBadge extends StatelessWidget {
  const _FromLibraryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('checkin-from-library'),
      padding: const EdgeInsets.symmetric(
        horizontal: OurneySpacing.md,
        vertical: OurneySpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(OurneyRadii.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: OurneySpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: Colors.white),
          ),
        ],
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
