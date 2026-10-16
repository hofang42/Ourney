import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../app/theme/motion.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/chunky_button.dart';
import '../../../shared/ourney_card.dart';
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
    final c = OurneyColors.of(context);
    final text = Theme.of(context).textTheme;
    final uri = _uriFor(_currentToken);

    return OurneyCard(
      key: const ValueKey('share-card-link'),
      child: AnimatedSize(
        duration: OurneyMotion.movement(context, OurneyDurations.tap),
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.link_rounded, color: c.accent),
                const SizedBox(width: OurneySpacing.sm),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.share_card_linkTitle,
                      style: text.titleMedium,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: OurneySpacing.sm),
            Text(
              uri == null
                  ? l10n.share_card_linkDescription
                  : l10n.share_card_linkActive,
              style: text.bodyMedium,
            ),
            const SizedBox(height: OurneySpacing.md),
            if (uri == null)
              ChunkyButton(
                key: const ValueKey('share-card-link-create'),
                variant: ChunkyVariant.accent,
                icon: Icons.add_link_rounded,
                label: l10n.share_card_linkCreate,
                onPressed: _busy ? null : _create,
              )
            else ...[
              SelectableText(
                uri.toString(),
                key: const ValueKey('share-card-link-url'),
                maxLines: 3,
                style: text.bodySmall?.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: OurneySpacing.md),
              ChunkyButton(
                key: const ValueKey('share-card-link-copy'),
                variant: ChunkyVariant.accent,
                icon: Icons.copy_rounded,
                label: l10n.share_card_linkCopy,
                onPressed: _busy ? null : () => _copy(uri),
              ),
              const SizedBox(height: OurneySpacing.sm),
              Align(
                child: TextButton.icon(
                  key: const ValueKey('share-card-link-revoke'),
                  style: TextButton.styleFrom(
                    foregroundColor: c.danger,
                    minimumSize: const Size(0, OurneySizes.minTap),
                  ),
                  icon: const Icon(Icons.link_off_rounded),
                  label: Text(l10n.share_card_linkRevoke),
                  onPressed: _busy ? null : _revoke,
                ),
              ),
            ],
          ],
        ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.share_card_linkRevokeTitle),
        content: SingleChildScrollView(
          child: Text(l10n.share_card_linkRevokeMessage),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(app.common_cancel),
          ),
          TextButton(
            key: const ValueKey('share-card-link-revoke-confirm'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.share_card_linkRevoke),
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
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
