import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/chunky_button.dart';
import '../data/safety_providers.dart';
import '../l10n/generated/safety_localizations.dart';
import 'block_dialogs.dart';
import 'safety_common.dart';

/// Server limit on `reports.note` (CHECK char_length <= 500).
const int kReportNoteMaxLength = 500;

/// Opens the report sheet (FR-F1) for a check-in ([checkInId]) or a user
/// ([userId] only). Pass the author's [userId] and [name] with a check-in to
/// offer "also block" after sending. Returns true when a report was sent.
///
/// The reported check-in is added to `hiddenCheckInIdsProvider` at once;
/// filter cached lists with it (the server also hides it, FR-F2).
Future<bool> showReportSheet(
  BuildContext context, {
  String? checkInId,
  String? userId,
  String? name,
}) async {
  assert(checkInId != null || userId != null, 'report needs a target');
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          OurneySpacing.screenMargin,
          0,
          OurneySpacing.screenMargin,
          OurneySpacing.screenMargin,
        ),
        child: ReportForm(
          checkInId: checkInId,
          userId: userId,
          name: name,
          showTitle: true,
          onClose: (sent) => Navigator.of(context).pop(sent),
        ),
      ),
    ),
  );
  return sent ?? false;
}

/// Reason picker + optional note + submit, then a confirmation step. Used
/// by [showReportSheet] and the `/safety/report/...` pages.
class ReportForm extends ConsumerStatefulWidget {
  const ReportForm({
    required this.onClose,
    this.checkInId,
    this.userId,
    this.name,
    this.showTitle = false,
    super.key,
  });

  final String? checkInId;
  final String? userId;
  final String? name;
  final bool showTitle;

  /// Called with `true` after a report was sent, `false` on cancel.
  final ValueChanged<bool> onClose;

  @override
  ConsumerState<ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends ConsumerState<ReportForm> {
  final _note = TextEditingController();
  ReportReason? _reason;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _sending) return;
    final l10n = SafetyL10n.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(safetyActionsProvider)
          .report(
            checkInId: widget.checkInId,
            userId: widget.userId,
            reason: reason,
            note: _note.text,
          );
      if (!mounted) return;
      setState(() => _sent = true);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _error = safetyFailureMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _alsoBlock() async {
    final userId = widget.userId;
    if (userId == null) return;
    final blocked = await confirmBlock(
      context,
      userId: userId,
      name: widget.name,
    );
    if (blocked && mounted) widget.onClose(true);
  }

  String _label(SafetyL10n l10n, ReportReason r) => switch (r) {
    ReportReason.spam => l10n.safety_reasonSpam,
    ReportReason.nudity => l10n.safety_reasonNudity,
    ReportReason.harassment => l10n.safety_reasonHarassment,
    ReportReason.selfHarm => l10n.safety_reasonSelfHarm,
    ReportReason.other => l10n.safety_reasonOther,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = SafetyL10n.of(context);
    final text = Theme.of(context).textTheme;
    final c = OurneyColors.of(context);
    final title = widget.checkInId != null
        ? l10n.safety_reportCheckInTitle
        : l10n.safety_reportUserTitle;

    if (ref.watch(appConfigProvider).localOnly) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: OurneySpacing.xl),
        child: Text(
          l10n.safety_needsAccount,
          key: const ValueKey('safety-report-needs-server'),
          style: text.bodyLarge,
        ),
      );
    }

    if (_sent) {
      return Column(
        key: const ValueKey('safety-report-sent'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.check_circle_rounded, size: 56, color: c.success),
          const SizedBox(height: OurneySpacing.md),
          Text(
            l10n.safety_reportSent,
            textAlign: TextAlign.center,
            style: text.titleMedium,
          ),
          if (_reason == ReportReason.selfHarm) ...[
            const SizedBox(height: OurneySpacing.lg),
            const SelfHarmSupportCard(),
          ],
          const SizedBox(height: OurneySpacing.xl),
          if (widget.userId != null) ...[
            ChunkyButton(
              key: const ValueKey('safety-report-also-block'),
              label: l10n.safety_reportAlsoBlock,
              icon: Icons.block_rounded,
              variant: ChunkyVariant.neutral,
              onPressed: _alsoBlock,
            ),
            const SizedBox(height: OurneySpacing.md),
          ],
          ChunkyButton(
            key: const ValueKey('safety-report-done'),
            label: l10n.safety_reportDone,
            onPressed: () => widget.onClose(true),
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey('safety-report-form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showTitle) ...[
          Semantics(
            header: true,
            child: Text(title, style: text.headlineSmall),
          ),
          const SizedBox(height: OurneySpacing.sm),
        ],
        Text(
          l10n.safety_reportPrompt,
          style: text.bodyMedium?.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: OurneySpacing.md),
        RadioGroup<ReportReason>(
          groupValue: _reason,
          onChanged: (r) => setState(() {
            _reason = r;
            _error = null;
          }),
          child: Column(
            children: [
              for (final r in ReportReason.values)
                RadioListTile<ReportReason>(
                  key: ValueKey('safety-reason-${r.wireName}'),
                  value: r,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_label(l10n, r)),
                ),
            ],
          ),
        ),
        if (_reason == ReportReason.selfHarm) ...[
          const SizedBox(height: OurneySpacing.sm),
          const SelfHarmSupportCard(),
        ],
        const SizedBox(height: OurneySpacing.md),
        TextField(
          key: const ValueKey('safety-report-note'),
          controller: _note,
          maxLength: kReportNoteMaxLength,
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: l10n.safety_noteLabel,
            hintText: l10n.safety_noteHint,
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: OurneySpacing.sm),
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: c.danger),
                const SizedBox(width: OurneySpacing.sm),
                Expanded(
                  child: Text(
                    _error!,
                    key: const ValueKey('safety-report-error'),
                    style: text.bodyMedium?.copyWith(color: c.danger),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: OurneySpacing.lg),
        ChunkyButton(
          key: const ValueKey('safety-report-submit'),
          label: l10n.safety_reportSubmit,
          icon: Icons.flag_rounded,
          onPressed: _reason == null || _sending ? null : _submit,
        ),
        const SizedBox(height: OurneySpacing.sm),
        TextButton(
          key: const ValueKey('safety-report-cancel'),
          onPressed: _sending ? null : () => widget.onClose(false),
          child: Text(l10n.safety_reportCancel),
        ),
      ],
    );
  }
}
