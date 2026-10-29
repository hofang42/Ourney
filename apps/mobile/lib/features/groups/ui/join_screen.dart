import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart' show inviteCodeLength;

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../ui/ui.dart';
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

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.groups);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    final ui = context.ui;
    final backHeader = UiBackHeader(
      onBack: _back,
      backLabel: MaterialLocalizations.of(context).backButtonTooltip,
      title: l10n.groups_joinTitle,
    );
    if (ref.watch(appConfigProvider).localOnly) {
      return UiScaffold(
        key: const ValueKey('groups-join-screen'),
        scroll: false,
        padTop: 0,
        child: Column(
          children: [
            backHeader,
            const Expanded(child: UiFillScroll(child: GroupsNeedsServer())),
          ],
        ),
      );
    }
    final hasLinkCode = widget.initialCode != null;
    return UiScaffold(
      key: const ValueKey('groups-join-screen'),
      padTop: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          backHeader,
          const SizedBox(height: UiSpace.sm),
          if (hasLinkCode) ...[
            Semantics(
              header: true,
              child: Text(
                l10n.groups_joinPreviewTitle,
                style: UiText.h2(color: ui.ink),
              ),
            ),
            const SizedBox(height: UiSpace.lg),
          ],
          UiTextField(
            fieldKey: const ValueKey('groups-join-code'),
            label: l10n.groups_joinCodeLabel,
            hint: l10n.groups_joinCodeHint,
            controller: _code,
            enabled: !_busy,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(inviteCodeLength),
              TextInputFormatter.withFunction(
                (old, value) => value.copyWith(text: value.text.toUpperCase()),
              ),
            ],
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _join(),
          ),
          const SizedBox(height: UiSpace.md),
          UiCard(
            radius: UiRadius.menu,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.groups_outlined, color: ui.ink),
                const SizedBox(width: UiSpace.md),
                Expanded(
                  child: Text(
                    l10n.groups_joinRules,
                    style: UiText.body(size: 13, height: 1.5, color: ui.ink),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: UiSpace.lg),
            UiInlineError(
              key: const ValueKey('groups-join-error'),
              message: _error!,
            ),
          ],
          const SizedBox(height: UiSpace.xl),
          UiButton(
            key: const ValueKey('groups-join-submit'),
            label: l10n.groups_joinButton,
            icon: Icons.login_rounded,
            loading: _busy,
            onPressed: _busy || !isValidInviteCode(_normalized) ? null : _join,
          ),
        ],
      ),
    );
  }
}
