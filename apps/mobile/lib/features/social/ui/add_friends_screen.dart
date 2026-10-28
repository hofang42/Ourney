import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
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
          SizedBox(height: OurneySpacing.md),
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
    final c = OurneyColors.of(context);
    final radius = BorderRadius.circular(18);
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(OurneyRadii.thumb),
              child: Row(
                children: [
                  leading,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: headingStyle(size: 16, color: c.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kBodyFont,
                            fontSize: 12,
                            height: 1.35,
                            color: c.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: OurneySpacing.sm,
                runSpacing: OurneySpacing.sm,
                alignment: WrapAlignment.end,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 22, color: c.ink),
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
      leading: const _IconTile(Icons.link_rounded),
      title: l10n.social_inviteLinkTitle,
      subtitle: link ?? l10n.social_inviteLinkHint,
      actions: [
        SocialPill(
          key: const ValueKey('invite-copy'),
          label: l10n.social_copy,
          quiet: true,
          onPressed: _busy
              ? null
              : () => _withLink((link) async {
                  await ref.read(socialClipboardProvider)(link);
                  if (!mounted) return;
                  showSocialSnack(this.context, l10n.social_linkCopied);
                }),
        ),
        SocialPill(
          key: const ValueKey('invite-share'),
          label: l10n.social_share,
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
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        key: const ValueKey('invite-qr-large'),
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          child: Padding(
            padding: const EdgeInsets.all(OurneySpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QrImage(link: link, size: 240, label: l10n.social_qrSemantics),
                const SizedBox(height: OurneySpacing.md),
                Text(
                  link,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SocialL10n.of(context);
    final c = OurneyColors.of(context);
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
            ? const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.qr_code_2_rounded, size: 54, color: c.ink),
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

  final String link;
  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      image: true,
      child: Container(
        color: OurneyColors.light.surface,
        padding: EdgeInsets.all(size > 100 ? 8 : 3),
        child: QrImageView(
          data: link,
          size: size - (size > 100 ? 16 : 6),
          padding: EdgeInsets.zero,
          eyeStyle: QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: OurneyColors.light.ink,
          ),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: OurneyColors.light.ink,
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
    final c = OurneyColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.social_findByUsername,
            style: headingStyle(size: 18, color: c.ink),
          ),
        ),
        const SizedBox(height: OurneySpacing.md),
        TextField(
          key: const ValueKey('username-field'),
          controller: _controller,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          onChanged: (_) {
            if (_state != _SearchState.idle) {
              setState(() => _state = _SearchState.idle);
            }
          },
          decoration: InputDecoration(
            hintText: l10n.social_usernameHint,
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: IconButton(
              key: const ValueKey('username-search'),
              tooltip: l10n.social_search,
              icon: const Icon(Icons.arrow_forward_rounded),
              onPressed: _search,
            ),
          ),
        ),
        const SizedBox(height: OurneySpacing.xs),
        Text(
          l10n.social_exactMatchHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
        ),
        const SizedBox(height: OurneySpacing.sm),
        _resultView(context),
      ],
    );
  }

  Widget _resultView(BuildContext context) {
    final l10n = SocialL10n.of(context);
    final c = OurneyColors.of(context);
    Widget message(String text, Key key) => Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: kBodyFont,
          fontSize: 13,
          height: 1.4,
          color: c.inkMuted,
        ),
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
      return SocialStateLabel(l10n.social_thatsYou);
    }
    Friendship? link;
    for (final f
        in ref.watch(friendshipsProvider).value ?? const <Friendship>[]) {
      if (f.person.userId == p.userId) link = f;
    }
    if (link != null && link.isFriend) {
      return SocialStateLabel(
        l10n.social_alreadyFriends,
        icon: Icons.check_rounded,
        key: const ValueKey('username-friends'),
      );
    }
    if (link != null && link.isIncomingRequest) {
      return SocialPill(
        key: const ValueKey('username-accept'),
        label: l10n.social_accept,
        onPressed: _sending ? null : () => _accept(p),
      );
    }
    if (link != null || _sent.contains(p.userId)) {
      return SocialStateLabel(
        l10n.social_requested,
        key: const ValueKey('username-requested'),
      );
    }
    return SocialPill(
      key: const ValueKey('username-add'),
      label: l10n.social_addFriend,
      onPressed: _sending ? null : () => _send(p),
    );
  }
}
