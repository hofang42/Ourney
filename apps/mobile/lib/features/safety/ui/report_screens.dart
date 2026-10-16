import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/chunky_button.dart';
import '../../../shared/needs_server_view.dart';
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
    return Scaffold(
      key: const ValueKey('safety-report-screen'),
      appBar: AppBar(
        leading: CloseButton(
          onPressed: () => closeOr(context, AppRoutes.capture, false),
        ),
        title: Text(
          checkInId != null
              ? l10n.safety_reportCheckInTitle
              : l10n.safety_reportUserTitle,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(OurneySpacing.screenMargin),
          child: ReportForm(
            checkInId: checkInId,
            userId: userId,
            name: name,
            onClose: (sent) => closeOr(context, AppRoutes.capture, sent),
          ),
        ),
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
    final text = Theme.of(context).textTheme;
    final shown = (widget.name == null || widget.name!.isEmpty)
        ? l10n.safety_unknownUser
        : widget.name!;
    final localOnly = ref.watch(appConfigProvider).localOnly;
    return Scaffold(
      key: const ValueKey('safety-block-screen'),
      appBar: AppBar(
        leading: CloseButton(
          onPressed: () => closeOr(context, AppRoutes.capture, false),
        ),
      ),
      body: SafeArea(
        child: localOnly
            ? const NeedsServerView()
            : ListView(
                padding: const EdgeInsets.all(OurneySpacing.screenMargin),
                children: [
                  Icon(
                    Icons.block_rounded,
                    size: 56,
                    color: OurneyColors.of(context).danger,
                  ),
                  const SizedBox(height: OurneySpacing.lg),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.safety_blockTitle(shown),
                      textAlign: TextAlign.center,
                      style: text.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: OurneySpacing.md),
                  Text(
                    l10n.safety_blockBody,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: OurneySpacing.xl),
                  ChunkyButton(
                    key: const ValueKey('safety-block-page-confirm'),
                    label: l10n.safety_blockConfirm,
                    icon: Icons.block_rounded,
                    onPressed: _busy ? null : _block,
                  ),
                  const SizedBox(height: OurneySpacing.sm),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => closeOr(context, AppRoutes.capture, false),
                    child: Text(l10n.safety_blockCancel),
                  ),
                ],
              ),
      ),
    );
  }
}
