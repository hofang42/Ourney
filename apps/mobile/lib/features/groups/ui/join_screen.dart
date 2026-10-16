import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart' show inviteCodeLength;

import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/chunky_button.dart';
import '../../../shared/needs_server_view.dart';
import '../../../shared/ourney_card.dart';
import '../../reminders/data/reminder_scheduler.dart';
import '../domain/invite_code.dart';
import '../groups_paths.dart';
import '../l10n/generated/groups_localizations.dart';
import 'group_errors.dart';

/// `/join` (manual entry) and `/join/:code` (`ourney://join/<code>`), FR-D1.
///
/// There is no "look up a code" RPC in the contract, so the preview shows
/// the code and the group rules; confirming calls
/// `GroupRepository.joinByCode` and opens the group's "Today" screen.
class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({this.initialCode, super.key});

  final String? initialCode;

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  late final TextEditingController _code = TextEditingController(
    text: parseInviteInput(widget.initialCode ?? ''),
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String get _normalized => parseInviteInput(_code.text);

  Future<void> _join() async {
    final code = _normalized;
    if (!isValidInviteCode(code)) {
      setState(() => _error = GroupsL10n.of(context).groups_joinInvalidCode);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final reminders = ref.read(reminderSchedulerProvider);
    try {
      final journeyId = await ref
          .read(groupRepositoryProvider)
          .joinByCode(code);
      unawaited(reminders.reschedule());
      if (!mounted) return;
      context.go(GroupsPaths.today(journeyId));
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = groupErrorMessage(context, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    final text = Theme.of(context).textTheme;
    final c = OurneyColors.of(context);
    if (ref.watch(appConfigProvider).localOnly) {
      return Scaffold(
        key: const ValueKey('groups-join-screen'),
        appBar: AppBar(title: Text(l10n.groups_joinTitle)),
        body: const SafeArea(child: NeedsServerView()),
      );
    }
    final hasLinkCode = widget.initialCode != null;
    return Scaffold(
      key: const ValueKey('groups-join-screen'),
      appBar: AppBar(title: Text(l10n.groups_joinTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(OurneySpacing.screenMargin),
          children: [
            if (hasLinkCode) ...[
              Semantics(
                header: true,
                child: Text(
                  l10n.groups_joinPreviewTitle,
                  style: text.titleLarge,
                ),
              ),
              const SizedBox(height: OurneySpacing.lg),
            ],
            TextField(
              key: const ValueKey('groups-join-code'),
              controller: _code,
              enabled: !_busy,
              autofocus: !hasLinkCode,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              maxLength: inviteCodeLength,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                TextInputFormatter.withFunction(
                  (old, value) =>
                      value.copyWith(text: value.text.toUpperCase()),
                ),
              ],
              style: text.headlineSmall?.copyWith(letterSpacing: 4),
              decoration: InputDecoration(
                labelText: l10n.groups_joinCodeLabel,
                hintText: l10n.groups_joinCodeHint,
              ),
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _join(),
            ),
            const SizedBox(height: OurneySpacing.md),
            OurneyCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.groups_rounded, color: c.accent),
                  const SizedBox(width: OurneySpacing.md),
                  Expanded(
                    child: Text(l10n.groups_joinRules, style: text.bodyMedium),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: OurneySpacing.lg),
              Semantics(
                liveRegion: true,
                child: Row(
                  key: const ValueKey('groups-join-error'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline_rounded, color: c.danger),
                    const SizedBox(width: OurneySpacing.sm),
                    Expanded(
                      child: Text(
                        _error!,
                        style: text.bodyMedium?.copyWith(color: c.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: OurneySpacing.xl),
            ChunkyButton(
              key: const ValueKey('groups-join-submit'),
              label: l10n.groups_joinButton,
              icon: Icons.login_rounded,
              variant: ChunkyVariant.accent,
              onPressed: _busy || !isValidInviteCode(_normalized)
                  ? null
                  : _join,
            ),
            if (_busy) ...[
              const SizedBox(height: OurneySpacing.lg),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
