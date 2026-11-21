import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../groups/data/groups_providers.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'journey_errors.dart';

/// Owner-only sheet to edit the two couple names after creation
/// (`rename_couple`, migration 0010).
Future<void> showCoupleRenameSheet(BuildContext context, Journey journey) =>
    showUiSheet<void>(
      context: context,
      builder: (_) => _CoupleRenameSheet(journey: journey),
    );

class _CoupleRenameSheet extends ConsumerStatefulWidget {
  const _CoupleRenameSheet({required this.journey});

  final Journey journey;

  @override
  ConsumerState<_CoupleRenameSheet> createState() => _CoupleRenameSheetState();
}

class _CoupleRenameSheetState extends ConsumerState<_CoupleRenameSheet> {
  late final _self = TextEditingController(
    text: widget.journey.coupleSelfName ?? '',
  );
  late final _partner = TextEditingController(
    text: widget.journey.couplePartnerName ?? '',
  );
  bool _busy = false;

  @override
  void dispose() {
    _self.dispose();
    _partner.dispose();
    super.dispose();
  }

  bool get _valid =>
      _self.text.trim().isNotEmpty &&
      _partner.text.trim().isNotEmpty &&
      validateCoupleNames(_self.text, _partner.text) == null;

  Future<void> _save() async {
    if (!_valid || _busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(groupInviteAdminRepositoryProvider)
          .renameCouple(widget.journey.id, _self.text, _partner.text);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showJourneySnack(context, journeyErrorMessage(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final app = AppLocalizations.of(context);
    final ui = context.ui;
    return SingleChildScrollView(
      key: const ValueKey('couple-rename-sheet'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.journeys_renameCoupleTitle,
              style: UiText.h2(color: ui.ink),
            ),
          ),
          const SizedBox(height: UiSpace.md),
          UiTextField(
            fieldKey: const ValueKey('rename-self'),
            label: l10n.journeys_coupleNameYou,
            controller: _self,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: UiSpace.md),
          UiTextField(
            fieldKey: const ValueKey('rename-partner'),
            label: l10n.journeys_coupleNameOther,
            controller: _partner,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: UiSpace.lg),
          UiButton(
            key: const ValueKey('rename-save'),
            label: app.common_save,
            loading: _busy,
            onPressed: _valid && !_busy ? _save : null,
          ),
        ],
      ),
    );
  }
}
