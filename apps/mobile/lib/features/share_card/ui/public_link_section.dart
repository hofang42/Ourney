import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../app/theme/motion.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../domain/share_card_content.dart';
import '../l10n/generated/share_card_localizations.dart';

/// FR-E3: read-only public link of a solo journey. Only shown (by the
/// screen) for the owner of a solo journey with a backend; group journeys
/// and local-only mode never get here (`canHavePublicLink`).
///
/// * No link yet: "Create & copy" -> `setPublicLink(id, enabled: true)`.
/// * Link on: copy the existing link (no rotation), or revoke it with
///   `setPublicLink(id, enabled: false)` after a confirmation.
class PublicLinkSection extends ConsumerStatefulWidget {
  const PublicLinkSection({required this.journey, super.key});

  final Journey journey;

  @override
  ConsumerState<PublicLinkSection> createState() => _PublicLinkSectionState();
}

class _PublicLinkSectionState extends ConsumerState<PublicLinkSection> {
  /// Result of our last setPublicLink call, until the repository stream
  /// reports a new token.
  bool _overridden = false;
  String? _token;
  bool _busy = false;

  @override
  void didUpdateWidget(PublicLinkSection old) {
    super.didUpdateWidget(old);
    if (old.journey.publicToken != widget.journey.publicToken ||
        old.journey.visibility != widget.journey.visibility) {
      _overridden = false;
    }
  }

  String? get _currentToken =>
      _overridden ? _token : activePublicToken(widget.journey);

  Uri? _uriFor(String? token) {
    if (token == null) return null;
    final base = Uri.tryParse(ref.read(appConfigProvider).supabaseUrl);
    if (base == null || !base.hasScheme) return null;
    return publicJourneyUri(base, token);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ShareCardL10n.of(context);
    final ui = context.ui;
    final uri = _uriFor(_currentToken);

    return UiCard(
      key: const ValueKey('share-card-link'),
      radius: UiRadius.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.link_rounded, color: ui.ink),
              const SizedBox(width: UiSpace.sm),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.share_card_linkTitle,
                    style: UiText.body(
                      size: 16,
                      weight: FontWeight.w700,
                      height: 1.4,
                      color: ui.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: UiSpace.sm),
          Text(
            uri == null
                ? l10n.share_card_linkDescription
                : l10n.share_card_linkActive,
            style: UiText.muted(color: ui.inkMuted, size: 14),
          ),
          const SizedBox(height: UiSpace.md),
          if (uri == null)
            UiButton(
              key: const ValueKey('share-card-link-create'),
              icon: Icons.add_link_rounded,
              label: l10n.share_card_linkCreate,
              loading: _busy,
              onPressed: _busy ? null : _create,
            )
          else ...[
            SelectableText(
              uri.toString(),
              key: const ValueKey('share-card-link-url'),
              maxLines: 3,
              style: UiText.body(size: 12, height: 1.45, color: ui.inkMuted),
            ),
            const SizedBox(height: UiSpace.md),
            UiButton(
              key: const ValueKey('share-card-link-copy'),
              icon: Icons.copy_rounded,
              label: l10n.share_card_linkCopy,
              onPressed: _busy ? null : () => _copy(uri),
            ),
            const SizedBox(height: UiSpace.xs),
            UiButton.ghost(
              key: const ValueKey('share-card-link-revoke'),
              icon: Icons.link_off_rounded,
              label: l10n.share_card_linkRevoke,
              onPressed: _busy ? null : _revoke,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      final token = await ref
          .read(journeyRepositoryProvider)
          .setPublicLink(widget.journey.id, enabled: true);
      if (!mounted) return;
      if (token == null || !isValidPublicToken(token)) {
        throw const OurneyException(OurneyErrorCode.unknown, 'bad token');
      }
      setState(() {
        _overridden = true;
        _token = token;
      });
      final uri = _uriFor(token);
      if (uri != null) await _copy(uri);
    } on Object catch (e) {
      if (mounted) _snack(_errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy(Uri uri) async {
    final l10n = ShareCardL10n.of(context);
    await Clipboard.setData(ClipboardData(text: uri.toString()));
    OurneyHaptics.light();
    if (mounted) _snack(l10n.share_card_linkCopied);
  }

  Future<void> _revoke() async {
    final l10n = ShareCardL10n.of(context);
    final app = AppLocalizations.of(context);
    final confirmed = await showUiSheet<bool>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.share_card_linkRevokeTitle,
              style: UiText.h2(color: context.ui.ink),
            ),
          ),
          const SizedBox(height: UiSpace.sm),
          Text(
            l10n.share_card_linkRevokeMessage,
            style: UiText.muted(color: context.ui.inkMuted, size: 14),
          ),
          const SizedBox(height: UiSpace.xl),
          UiButton(
            key: const ValueKey('share-card-link-revoke-confirm'),
            label: l10n.share_card_linkRevoke,
            accent: context.ui.danger,
            onAccent: Colors.white,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: UiSpace.sm),
          UiButton.secondary(
            label: app.common_cancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(journeyRepositoryProvider)
          .setPublicLink(widget.journey.id, enabled: false);
      if (!mounted) return;
      setState(() {
        _overridden = true;
        _token = null;
      });
      _snack(l10n.share_card_linkRevoked);
    } on Object catch (e) {
      if (mounted) _snack(_errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _errorMessage(Object error) {
    final l10n = ShareCardL10n.of(context);
    final app = AppLocalizations.of(context);
    if (error is! OurneyException) return app.common_errorGeneric;
    return switch (error.error) {
      OurneyErrorCode.ended => l10n.share_card_linkErrorEnded,
      OurneyErrorCode.forbidden => l10n.share_card_linkErrorForbidden,
      OurneyErrorCode.offline => app.common_offline,
      _ => app.common_errorGeneric,
    };
  }

  void _snack(String message) {
    showUiToast(context, message);
  }
}
