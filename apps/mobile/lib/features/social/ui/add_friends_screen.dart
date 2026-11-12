import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/providers.dart';
import '../../../ui/ui.dart';
import '../data/social_providers.dart';
import '../l10n/generated/social_localizations.dart';
import '../social_paths.dart';
import 'social_common.dart';

/// SCR-81 `/friends/add`: share my invite link, my QR code, find by exact
/// @username (S3). No contact sync, no suggestions.
class AddFriendsScreen extends ConsumerWidget {
  const AddFriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = SocialL10n.of(context);
    return SocialScaffold(
      key: const ValueKey('add-friends-screen'),
      title: l10n.social_addFriends,
      body: const SocialListBody(
        children: [
          SizedBox(height: 18),
          _InviteLinkBlock(),
          SizedBox(height: UiSpace.md),
          _QrBlock(),
          SizedBox(height: 26),
          _UsernameSearch(),
        ],
      ),
    );
  }
}

/// `.sharing-block`: outlined card with a sunken icon tile.
class _Block extends StatelessWidget {
  const _Block({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final head = Row(
      children: [
        leading,
        const SizedBox(width: UiSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: UiText.h2(size: 16, color: ui.ink),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: UiText.body(size: 12, height: 1.4, color: ui.inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
    return UiCard(
      radius: UiRadius.card,
      padding: const EdgeInsets.all(14),
      color: ui.surface,
      borderColor: ui.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onTap == null)
            head
          else
            UiPressable(
              onPressed: onTap,
              borderRadius: BorderRadius.circular(UiRadius.thumb),
              minSize: const Size(UiSize.tap, 62),
              child: head,
            ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: UiSpace.sm,
              runSpacing: UiSpace.sm,
              alignment: WrapAlignment.end,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

class _InviteLinkBlock extends ConsumerStatefulWidget {
  const _InviteLinkBlock();

  @override
  ConsumerState<_InviteLinkBlock> createState() => _InviteLinkBlockState();
}

class _InviteLinkBlockState extends ConsumerState<_InviteLinkBlock> {
  bool _busy = false;

  Future<void> _withLink(Future<void> Function(String link) use) async {
    setState(() => _busy = true);
    await runSocialAction(context, () async {
      final token = await ref.read(myInviteTokenProvider.notifier).ensure();
      await use(SocialPaths.inviteUrl(token));
    });
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SocialL10n.of(context);
    final token = ref.watch(myInviteTokenProvider);
    final link = token == null ? null : SocialPaths.inviteUrl(token);
    return _Block(
      leading: const UiIconCircle(Icons.link_rounded, size: 48),
      title: l10n.social_inviteLinkTitle,
      subtitle: link ?? l10n.social_inviteLinkHint,
      actions: [
        UiButton.secondary(
          key: const ValueKey('invite-copy'),
          label: l10n.social_copy,
          compact: true,
          expand: false,
          onPressed: _busy
              ? null
              : () => _withLink((link) async {
                  await ref.read(socialClipboardProvider)(link);
                  if (!mounted) return;
                  showSocialSnack(this.context, l10n.social_linkCopied);
                }),
        ),
        UiButton(
          key: const ValueKey('invite-share'),
          label: l10n.social_share,
          compact: true,
          expand: false,
          onPressed: _busy
              ? null
              : () => _withLink(
                  (link) => ref.read(socialShareLauncherProvider)(
                    l10n.social_inviteShareText(link),
                  ),
                ),
        ),
      ],
    );
  }
}

class _QrBlock extends ConsumerStatefulWidget {
  const _QrBlock();

  @override
  ConsumerState<_QrBlock> createState() => _QrBlockState();
}

class _QrBlockState extends ConsumerState<_QrBlock> {
  bool _busy = false;

  Future<void> _tap() async {
    final token = ref.read(myInviteTokenProvider);
    if (token != null) return _enlarge(SocialPaths.inviteUrl(token));
    setState(() => _busy = true);
    await runSocialAction(
      context,
      () => ref.read(myInviteTokenProvider.notifier).ensure(),
    );
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _enlarge(String link) {
    final l10n = SocialL10n.of(context);
    return showUiSheet<void>(
      context: context,
      builder: (context) => Column(
        key: const ValueKey('invite-qr-large'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: _QrImage(
              link: link,
              size: 240,
              label: l10n.social_qrSemantics,
            ),
          ),
          const SizedBox(height: UiSpace.md),
          Text(
            link,
            textAlign: TextAlign.center,
            style: UiText.muted(size: 13, color: context.ui.inkMuted),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SocialL10n.of(context);
    final ui = context.ui;
    final token = ref.watch(myInviteTokenProvider);
    final Widget leading;
    if (token != null) {
      leading = _QrImage(
        key: const ValueKey('invite-qr'),
        link: SocialPaths.inviteUrl(token),
        size: 62,
        label: l10n.social_qrSemantics,
      );
    } else {
      leading = SizedBox(
        width: 62,
        height: 62,
        child: _busy
            ? Padding(
                padding: const EdgeInsets.all(18),
                child: CircularProgressIndicator(strokeWidth: 2, color: ui.ink),
              )
            : Icon(Icons.qr_code_2_rounded, size: 54, color: ui.ink),
      );
    }
    return Semantics(
      button: true,
      child: _Block(
        onTap: _busy ? null : _tap,
        leading: leading,
        title: l10n.social_qrTitle,
        subtitle: token == null ? l10n.social_qrShow : l10n.social_qrEnlarge,
      ),
    );
  }
}

/// QR codes are drawn dark-on-white in both themes so cameras can read them.
class _QrImage extends StatelessWidget {
  const _QrImage({
    required this.link,
    required this.size,
    required this.label,
    super.key,
  });

  static const _paper = Color(0xFFFFFFFF);
  static const _ink = Color(0xFF111111);

  final String link;
  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    final pad = size > 100 ? 8.0 : 3.0;
    return Semantics(
      label: label,
      image: true,
      child: Container(
        color: _paper,
        padding: EdgeInsets.all(pad),
        child: QrImageView(
          data: link,
          size: size - pad * 2,
          padding: EdgeInsets.zero,
          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: _ink),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: _ink,
          ),
        ),
      ),
    );
  }
}

enum _SearchState { idle, loading, done, error }

class _UsernameSearch extends ConsumerStatefulWidget {
  const _UsernameSearch();

  @override
  ConsumerState<_UsernameSearch> createState() => _UsernameSearchState();
}

class _UsernameSearchState extends ConsumerState<_UsernameSearch> {
  final _controller = TextEditingController();
  _SearchState _state = _SearchState.idle;
  PersonSummary? _result;
  Object? _error;
  bool _sending = false;
  final Set<String> _sent = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _normalize(String raw) {
    var v = raw.trim();
    while (v.startsWith('@')) {
      v = v.substring(1);
    }
    return v.trim();
  }

  int _searchSeq = 0;

  Future<void> _search() async {
    final seq = ++_searchSeq;
    final username = _normalize(_controller.text);
    if (username.isEmpty) {
      setState(() => _state = _SearchState.idle);
      return;
    }
    setState(() {
      _state = _SearchState.loading;
      _result = null;
      _error = null;
    });
    try {
      final hit = await ref
          .read(friendRepositoryProvider)
          .findByUsername(username);
      // A newer search owns the result.
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _result = hit;
        _state = _SearchState.done;
      });
    } on Object catch (e) {
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _error = e;
        _state = _SearchState.error;
      });
    }
  }

  Future<void> _send(PersonSummary p) async {
    setState(() => _sending = true);
    final ok = await runSocialAction(
      context,
      () => ref.read(friendRepositoryProvider).sendRequest(p.userId),
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok) _sent.add(p.userId);
    });
  }

  Future<void> _accept(PersonSummary p) async {
    setState(() => _sending = true);
    await runSocialAction(
      context,
      () => ref.read(friendRepositoryProvider).respond(p.userId, accept: true),
    );
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SocialL10n.of(context);
    final ui = context.ui;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.social_findByUsername,
            style: UiText.h2(size: 18, color: ui.ink),
          ),
        ),
        const SizedBox(height: UiSpace.md),
        UiTextField(
          fieldKey: const ValueKey('username-field'),
          label: l10n.social_findByUsername,
          controller: _controller,
          hint: l10n.social_usernameHint,
          autocorrect: false,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          onChanged: (_) {
            if (_state != _SearchState.idle) {
              setState(() => _state = _SearchState.idle);
            }
          },
          trailing: UiIconButton(
            key: const ValueKey('username-search'),
            icon: Icons.arrow_forward_rounded,
            label: l10n.social_search,
            onPressed: _search,
          ),
        ),
        const SizedBox(height: UiSpace.xs),
        Text(
          l10n.social_exactMatchHint,
          style: UiText.body(size: 12, height: 1.4, color: ui.inkMuted),
        ),
        const SizedBox(height: UiSpace.sm),
        _resultView(context),
      ],
    );
  }

  Widget _resultView(BuildContext context) {
    final l10n = SocialL10n.of(context);
    final ui = context.ui;
    Widget message(String text, Key key) => Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: UiText.body(size: 13, height: 1.4, color: ui.inkMuted),
      ),
    );

    switch (_state) {
      case _SearchState.idle:
        return const SizedBox.shrink();
      case _SearchState.loading:
        return const Padding(
          padding: EdgeInsets.all(18),
          child: SocialLoading(),
        );
      case _SearchState.error:
        return message(
          socialErrorMessage(context, _error!),
          const ValueKey('username-error'),
        );
      case _SearchState.done:
        final p = _result;
        if (p == null) {
          return message(l10n.social_noOne, const ValueKey('username-none'));
        }
        return PersonRow(
          key: const ValueKey('username-result'),
          person: p,
          trailing: [_relation(context, p)],
        );
    }
  }

  Widget _relation(BuildContext context, PersonSummary p) {
    final l10n = SocialL10n.of(context);
    if (p.userId == ref.watch(currentUserIdProvider)) {
      return UiStateLabel(l10n.social_thatsYou);
    }
    Friendship? link;
    for (final f
        in ref.watch(friendshipsProvider).value ?? const <Friendship>[]) {
      if (f.person.userId == p.userId) link = f;
    }
    if (link != null && link.isFriend) {
      return UiStateLabel(
        l10n.social_alreadyFriends,
        icon: Icons.check_rounded,
        key: const ValueKey('username-friends'),
      );
    }
    if (link != null && link.isIncomingRequest) {
      return UiButton(
        key: const ValueKey('username-accept'),
        label: l10n.social_accept,
        compact: true,
        expand: false,
        onPressed: _sending ? null : () => _accept(p),
      );
    }
    if (link != null || _sent.contains(p.userId)) {
      return UiStateLabel(
        l10n.social_requested,
        key: const ValueKey('username-requested'),
      );
    }
    return UiButton(
      key: const ValueKey('username-add'),
      label: l10n.social_addFriend,
      compact: true,
      expand: false,
      onPressed: _sending ? null : () => _send(p),
    );
  }
}
