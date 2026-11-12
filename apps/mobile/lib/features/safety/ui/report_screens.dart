import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../shared/needs_server_view.dart';
import '../../../ui/ui.dart';
import '../l10n/generated/safety_localizations.dart';
import 'block_dialogs.dart';
import 'report_form.dart';
import 'safety_common.dart';

/// `/safety/report/checkin/:checkInId` and `/safety/report/user/:userId`.
/// Pops with `true` once a report was sent.
class ReportScreen extends StatelessWidget {
  const ReportScreen({this.checkInId, this.userId, this.name, super.key})
    : assert(checkInId != null || userId != null);

  final String? checkInId;
  final String? userId;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final l10n = SafetyL10n.of(context);
    return SafetyPage(
      pageKey: const ValueKey('safety-report-screen'),
      title: checkInId != null
          ? l10n.safety_reportCheckInTitle
          : l10n.safety_reportUserTitle,
      onBack: () => closeOr(context, AppRoutes.capture, false),
      child: ReportForm(
        checkInId: checkInId,
        userId: userId,
        name: name,
        onClose: (sent) => closeOr(context, AppRoutes.capture, sent),
      ),
    );
  }
}

/// `/safety/block/:userId?name=`: full-page block confirmation. Pops with
/// `true` once blocked.
class BlockUserScreen extends ConsumerStatefulWidget {
  const BlockUserScreen({required this.userId, this.name, super.key});

  final String userId;
  final String? name;

  @override
  ConsumerState<BlockUserScreen> createState() => _BlockUserScreenState();
}

class _BlockUserScreenState extends ConsumerState<BlockUserScreen> {
  bool _busy = false;

  Future<void> _block() async {
    setState(() => _busy = true);
    final ok = await blockUser(
      ProviderScope.containerOf(context, listen: false),
      ScaffoldMessenger.maybeOf(context),
      SafetyL10n.of(context),
      userId: widget.userId,
      name: widget.name,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) closeOr(context, AppRoutes.capture, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SafetyL10n.of(context);
    final ui = context.ui;
    final shown = (widget.name == null || widget.name!.isEmpty)
        ? l10n.safety_unknownUser
        : widget.name!;
    final localOnly = ref.watch(appConfigProvider).localOnly;
    return SafetyPage(
      pageKey: const ValueKey('safety-block-screen'),
      onBack: () => closeOr(context, AppRoutes.capture, false),
      child: localOnly
          ? const NeedsServerView()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: UiSpace.lg),
                Icon(Icons.block_rounded, size: 56, color: ui.danger),
                const SizedBox(height: UiSpace.lg),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.safety_blockTitle(shown),
                    textAlign: TextAlign.center,
                    style: UiText.h2(color: ui.ink),
                  ),
                ),
                const SizedBox(height: UiSpace.md),
                Text(
                  l10n.safety_blockBody,
                  textAlign: TextAlign.center,
                  style: UiText.muted(color: ui.inkMuted),
                ),
                const SizedBox(height: UiSpace.xl),
                UiButton(
                  key: const ValueKey('safety-block-page-confirm'),
                  label: l10n.safety_blockConfirm,
                  icon: Icons.block_rounded,
                  loading: _busy,
                  onPressed: _busy ? null : _block,
                ),
                const SizedBox(height: UiSpace.sm),
                UiTextAction(
                  label: l10n.safety_blockCancel,
                  onPressed: _busy
                      ? null
                      : () => closeOr(context, AppRoutes.capture, false),
                ),
              ],
            ),
    );
  }
}
