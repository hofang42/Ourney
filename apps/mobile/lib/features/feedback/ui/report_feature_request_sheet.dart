import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../ui/ui.dart';
import '../../safety/l10n/generated/safety_localizations.dart';
import '../../safety/ui/report_form.dart' show kReportNoteMaxLength;
import '../../safety/ui/safety_common.dart';
import '../data/feedback_providers.dart';
import '../l10n/generated/feedback_localizations.dart';

/// Opens the UGC report sheet for a feature request (`0024`
/// `report_feature_request`, 24-hour moderation SLA). Immediately adds
/// [requestId] to [hiddenFeatureRequestIdsProvider] on success and resolves to
/// `true`.
Future<bool> showReportFeatureRequestSheet(
  BuildContext context, {
  required String requestId,
}) async {
  final sent = await showUiSheet<bool>(
    context: context,
    builder: (context) => ReportFeatureRequestForm(
      requestId: requestId,
      onClose: (sent) => Navigator.of(context).pop(sent),
    ),
  );
  return sent ?? false;
}

class ReportFeatureRequestForm extends ConsumerStatefulWidget {
  const ReportFeatureRequestForm({
    required this.requestId,
    required this.onClose,
    super.key,
  });

  final String requestId;
  final ValueChanged<bool> onClose;

  @override
  ConsumerState<ReportFeatureRequestForm> createState() =>
      _ReportFeatureRequestFormState();
}

class _ReportFeatureRequestFormState
    extends ConsumerState<ReportFeatureRequestForm> {
  final _note = TextEditingController();
  ReportReason? _reason;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String _label(SafetyL10n safetyL10n, ReportReason r) => switch (r) {
        ReportReason.spam => safetyL10n.safety_reasonSpam,
        ReportReason.nudity => safetyL10n.safety_reasonNudity,
        ReportReason.harassment => safetyL10n.safety_reasonHarassment,
        ReportReason.selfHarm => safetyL10n.safety_reasonSelfHarm,
        ReportReason.other => safetyL10n.safety_reasonOther,
      };

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _sending) return;
    final safetyL10n = SafetyL10n.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(featureRequestRepositoryProvider).report(
            requestId: widget.requestId,
            reason: reason,
            note: _note.text,
          );
      ref
          .read(hiddenFeatureRequestIdsProvider.notifier)
          .hide(widget.requestId);
      if (!mounted) return;
      widget.onClose(true);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _error = safetyFailureMessage(safetyL10n, e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedbackL10n = FeedbackL10n.of(context);
    final safetyL10n = SafetyL10n.of(context);
    final ui = context.ui;

    return Column(
      key: const ValueKey('feedback-report-form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            feedbackL10n.feedback_reportTitle,
            style: UiText.h2(color: ui.ink),
          ),
        ),
        const SizedBox(height: UiSpace.sm),
        Text(
          safetyL10n.safety_reportPrompt,
          style: UiText.muted(color: ui.inkMuted),
        ),
        const SizedBox(height: UiSpace.md),
        for (final r in ReportReason.values)
          UiRow(
            key: ValueKey('feedback-report-reason-${r.wireName}'),
            title: _label(safetyL10n, r),
            showChevron: false,
            minHeight: 52,
            trailing: OurneyIcon(
              name: _reason == r ? 'radio-on' : 'radio-off',
              flat: true,
              color: _reason == r ? ui.brand : ui.inkMuted,
            ),
            onPressed: () => setState(() {
              _reason = r;
              _error = null;
            }),
          ),
        if (_reason == ReportReason.selfHarm) ...[
          const SizedBox(height: UiSpace.sm),
          const SelfHarmSupportCard(),
        ],
        const SizedBox(height: UiSpace.md),
        UiTextArea(
          fieldKey: const ValueKey('feedback-report-note'),
          controller: _note,
          label: safetyL10n.safety_noteLabel,
          hint: safetyL10n.safety_noteHint,
          maxLength: kReportNoteMaxLength,
          minLines: 2,
          maxLines: 4,
        ),
        if (_error != null) ...[
          const SizedBox(height: UiSpace.sm),
          UiInlineError(
            key: const ValueKey('feedback-report-error'),
            message: _error!,
          ),
        ],
        const SizedBox(height: UiSpace.lg),
        UiButton(
          key: const ValueKey('feedback-report-submit'),
          label: safetyL10n.safety_reportSubmit,
          glyph: const OurneyIcon(name: 'flag', flat: true),
          loading: _sending,
          onPressed: _reason == null || _sending ? null : _submit,
        ),
        const SizedBox(height: UiSpace.sm),
        UiTextAction(
          key: const ValueKey('feedback-report-cancel'),
          label: safetyL10n.safety_reportCancel,
          onPressed: _sending ? null : () => widget.onClose(false),
        ),
      ],
    );
  }
}
