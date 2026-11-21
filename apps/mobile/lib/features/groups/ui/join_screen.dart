import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../ui/ui.dart';
import '../../journeys/data/journeys_providers.dart' show rootError;
import '../../profile/share_privacy_sync.dart';
import '../../reminders/data/reminder_scheduler.dart';
import '../data/groups_providers.dart';
import '../domain/invite_code.dart';
import '../groups_paths.dart';
import '../l10n/generated/groups_localizations.dart';
import 'group_errors.dart';
import 'group_preview_card.dart';

/// `/join` (manual entry) and `/join/:code` (`ourney://join/<code>`), FR-D1.
///
/// Figma `JoinScreen`: an 8-box code input; once 8 characters are typed the
/// group is previewed (`preview_group_by_code`: name, owner, members, length,
/// progress) without joining. Confirming calls `GroupRepository.joinByCode`
/// and opens the group's "Today" screen. When the preview is unavailable
/// (offline, not wired) the plain join flow still works.
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
  final FocusNode _focus = FocusNode();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _focus.dispose();
    _code.dispose();
    super.dispose();
  }

  String get _normalized => parseInviteInput(_code.text);

  /// Error of the lookup that proves the join cannot work (unknown code,
  /// throttled). Offline/other failures return null: the plain join flow
  /// stays available.
  OurneyException? _blockingError(AsyncValue<GroupPreview> async) {
    final error = async.error;
    if (error == null) return null;
    final e = rootError(error);
    if (e is OurneyException &&
        (e.error == OurneyErrorCode.notFound ||
            e.error == OurneyErrorCode.rateLimited)) {
      return e;
    }
    return null;
  }

  bool _canConfirm(AsyncValue<GroupPreview>? async) {
    if (!isValidInviteCode(_normalized)) return false;
    if (async == null) return true;
    if (_blockingError(async) != null) return false;
    final p = async.asData?.value;
    if (p == null) return true; // loading, or no preview available
    return p.state == GroupPreviewState.open ||
        p.state == GroupPreviewState.member;
  }

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
      // Carry the Settings share-privacy switches over to the new membership.
      unawaited(pushSharePrivacyToJourney(ref, journeyId));
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

  Widget _rules(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    final ui = context.ui;
    return UiCard(
      radius: UiRadius.menu,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OurneyIcon(name: 'squad', size: 26),
          const SizedBox(width: UiSpace.md),
          Expanded(
            child: Text(
              l10n.groups_joinRules,
              style: UiText.body(size: 13, height: 1.5, color: ui.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewSection(
    BuildContext context,
    AsyncValue<GroupPreview>? async,
  ) {
    final l10n = GroupsL10n.of(context);
    if (async == null) return _rules(context);
    final blocking = _blockingError(async);
    if (blocking != null) {
      return UiInlineError(
        key: const ValueKey('groups-join-preview-error'),
        message: groupErrorMessage(context, blocking),
      );
    }
    final preview = async.asData?.value;
    if (preview != null) {
      final stateMessage = switch (preview.state) {
        GroupPreviewState.ended => l10n.groups_errorEnded,
        GroupPreviewState.full => l10n.groups_errorFull,
        GroupPreviewState.member => l10n.groups_previewAlreadyMember,
        GroupPreviewState.open => null,
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GroupPreviewCard(preview: preview),
          if (stateMessage != null) ...[
            const SizedBox(height: UiSpace.md),
            UiInlineError(
              key: const ValueKey('groups-join-preview-state'),
              message: stateMessage,
            ),
          ],
        ],
      );
    }
    if (async.isLoading) {
      return Semantics(
        label: l10n.groups_previewLoading,
        child: const UiSkeleton(
          key: ValueKey('groups-join-preview-loading'),
          height: 180,
          radius: UiRadius.menu,
        ),
      );
    }
    return _rules(context);
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
    final code = _normalized;
    final async = isValidInviteCode(code)
        ? ref.watch(groupPreviewProvider(code))
        : null;
    final preview = async?.asData?.value;
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
          _CodeBoxes(
            controller: _code,
            focusNode: _focus,
            enabled: !_busy,
            onChanged: () => setState(() => _error = null),
            onSubmitted: _join,
          ),
          const SizedBox(height: UiSpace.md),
          _previewSection(context, async),
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
            label: preview?.state == GroupPreviewState.member
                ? l10n.groups_previewOpenGroup
                : l10n.groups_joinButton,
            glyph: const OurneyIcon(name: 'login', size: 20),
            loading: _busy,
            onPressed: _busy || !_canConfirm(async) ? null : _join,
          ),
          const SizedBox(height: UiSpace.sm),
          // `.join-later`: leave without joining.
          UiButton.ghost(
            key: const ValueKey('groups-join-later'),
            label: l10n.groups_joinLater,
            onPressed: _busy ? null : _back,
          ),
        ],
      ),
    );
  }
}

/// Figma `.join-code-boxes`: eight boxes mirroring one invisible text field
/// laid over them, so paste, autofill and the system keyboard all work.
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    final ui = context.ui;
    return ListenableBuilder(
      listenable: Listenable.merge([controller, focusNode]),
      builder: (context, _) {
        final text = controller.text;
        final active = focusNode.hasFocus
            ? text.length.clamp(0, inviteCodeLength - 1)
            : -1;
        return Semantics(
          container: true,
          label: l10n.groups_joinCodeLabel,
          value: l10n.groups_joinCodeBoxesSemantics(text.length),
          child: SizedBox(
            height: 52,
            child: Stack(
              children: [
                ExcludeSemantics(
                  child: Row(
                    children: [
                      for (var i = 0; i < inviteCodeLength; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            key: ValueKey('groups-join-box-$i'),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: ui.fill,
                              borderRadius: BorderRadius.circular(UiRadius.otp),
                              border: Border.all(
                                color: i == active ? ui.accent : ui.border,
                                width: i == active
                                    ? UiBorder.standard
                                    : UiBorder.thin,
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                i < text.length ? text[i] : '',
                                style: UiText.h2(color: ui.ink)
                                    .copyWith(height: 1.3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      key: const ValueKey('groups-join-code'),
                      controller: controller,
                      focusNode: focusNode,
                      enabled: enabled,
                      autocorrect: false,
                      enableSuggestions: false,
                      showCursor: false,
                      enableInteractiveSelection: false,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp('[A-Za-z0-9]'),
                        ),
                        LengthLimitingTextInputFormatter(inviteCodeLength),
                        TextInputFormatter.withFunction(
                          (old, value) =>
                              value.copyWith(text: value.text.toUpperCase()),
                        ),
                      ],
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => onChanged(),
                      onSubmitted: (_) => onSubmitted(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
