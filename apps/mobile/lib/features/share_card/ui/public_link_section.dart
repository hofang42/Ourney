import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../app/theme/motion.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../profile/settings_providers.dart' show hideWeightOnShareProvider;
import '../../sharing/data/sharing_providers.dart' show shareStateProvider;
import '../../sharing/ui/share_journey_sheet.dart'
    show choosePublicLinkTitle, isSensitiveTemplate, showSensitiveLinkWarning;
import '../data/share_card_providers.dart' show shareMembershipProvider;
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

  bool _hideTitle(Membership? membership, bool hideWeight) => shareMetricHidden(
    widget.journey,
    membership,
    forceHideMetric: false,
    hideWeight: hideWeight,
  );

  bool get _hideTitleNow => _hideTitle(
    ref.read(shareMembershipProvider(widget.journey.id)).value,
    ref.read(hideWeightOnShareProvider),
  );

  Uri? _uriFor(String? token) {
    if (token == null) return null;
    final base = Uri.tryParse(ref.read(appConfigProvider).supabaseUrl);
    if (base == null || !base.hasScheme) return null;
    return publicJourneyShareUri(token);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ShareCardL10n.of(context);
    final ui = context.ui;
    final journey = widget.journey;
    final hideTitle = _hideTitle(
      ref.watch(shareMembershipProvider(journey.id)).value,
      ref.watch(hideWeightOnShareProvider),
    );
    final cachedToken = _overridden ? _token : activePublicToken(journey);
    final state = ref.watch(shareStateProvider(journey.id)).value;
    final token =
        isTitledPublicSlug(cachedToken) && (hideTitle || state?.linkOn == true)
        ? state?.publicAddress(hideTitle: hideTitle)
        : cachedToken;
    final uri = _uriFor(token);
    final hasLink = cachedToken != null;
    // S9: a running journey cannot get a link yet (revoking one stays).
    final eligible = publicLinkEligible(widget.journey);

    return UiCard(
      key: const ValueKey('share-card-link'),
      radius: UiRadius.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              OurneyIcon(name: 'link', flat: true, color: ui.ink),
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
            hasLink
                ? l10n.share_card_linkActive
                : eligible
                ? l10n.share_card_linkDescription
                : l10n.share_card_linkNotYet,
            style: UiText.muted(color: ui.inkMuted, size: 14),
          ),
          const SizedBox(height: UiSpace.md),
          if (!hasLink && !eligible)
            const SizedBox.shrink()
          else if (!hasLink)
            UiButton(
              key: const ValueKey('share-card-link-create'),
              glyph: const OurneyIcon(name: 'link', size: 20),
              label: l10n.share_card_linkCreate,
              loading: _busy,
              onPressed: _busy ? null : _create,
            )
          else ...[
            if (uri != null)
              SelectableText(
                uri.toString(),
                key: const ValueKey('share-card-link-url'),
                maxLines: 3,
                style: UiText.body(size: 12, height: 1.45, color: ui.inkMuted),
              ),
            const SizedBox(height: UiSpace.md),
            UiButton(
              key: const ValueKey('share-card-link-copy'),
              glyph: const OurneyIcon(name: 'copy', size: 20),
              label: l10n.share_card_linkCopy,
              onPressed: _busy
                  ? null
                  : () => _getAndCopy(existingOnly: true, displayedUri: uri),
            ),
            const SizedBox(height: UiSpace.xs),
            UiButton.ghost(
              key: const ValueKey('share-card-link-revoke'),
              glyph: const OurneyIcon(name: 'link-off', size: 20),
              label: l10n.share_card_linkRevoke,
              onPressed: _busy ? null : _revoke,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _create() async {
    final journey = widget.journey;
    String? approvedTitle;
    // S10: a sensitive journey asks before it gets a public link.
    if (isSensitiveTemplate(journey.templateId)) {
      if (!await showSensitiveLinkWarning(context) || !mounted) return;
    } else if (!_hideTitleNow) {
      final useTitle = await choosePublicLinkTitle(context, journey);
      if (useTitle == null || !mounted) return;
      if (useTitle) approvedTitle = journey.title;
    }
    await _getAndCopy(approvedTitle: approvedTitle);
  }

  void _showLink(PublicLinkResult result) {
    final provider = shareStateProvider(widget.journey.id);
    if (ref.read(provider).value?.publicToken != result.address()) {
      ref.invalidate(provider);
    }
    setState(() {
      _overridden = true;
      _token = result.address(hideTitle: _hideTitleNow);
    });
  }

  Future<void> _getAndCopy({
    String? approvedTitle,
    bool existingOnly = false,
    Uri? displayedUri,
  }) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(journeyRepositoryProvider);
      final id = widget.journey.id;
      final title = _hideTitleNow ? null : approvedTitle;
      var result = await repo.setPublicLink(
        id,
        enabled: true,
        approvedTitle: title,
        existingOnly: existingOnly,
        hideWeight: ref.read(hideWeightOnShareProvider),
      );
      if (!mounted) return;
      _showLink(result);
      final uri = _uriFor(_token);
      if (uri == null && existingOnly) return;
      if (uri != null &&
          !result.issued &&
          result.title != null &&
          (existingOnly ? uri != displayedUri : result.title != title) &&
          !_hideTitleNow) {
        final copy = await _confirmExisting(uri);
        if (!mounted || copy == null) return;
        if (!copy) {
          result = await repo.setPublicLink(
            id,
            enabled: true,
            reset: true,
            expectedSlug: result.slug,
            approvedTitle: _hideTitleNow ? null : title,
            hideWeight: ref.read(hideWeightOnShareProvider),
          );
          if (!mounted) return;
          _showLink(result);
          if (!result.issued) return;
        } else {
          result = await repo.setPublicLink(
            id,
            enabled: true,
            existingOnly: true,
            hideWeight: ref.read(hideWeightOnShareProvider),
          );
          if (!mounted) return;
          _showLink(result);
          if (_uriFor(_token) != uri) return;
        }
      }
      final address = result.address(hideTitle: _hideTitleNow);
      if (address == null || !isValidPublicToken(address)) {
        throw const OurneyException(OurneyErrorCode.unknown, 'bad token');
      }
      final copyUri = _uriFor(address);
      if (copyUri != null) await _copy(copyUri);
    } on Object catch (e) {
      if (mounted) _snack(_errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirmExisting(Uri uri) {
    final l10n = ShareCardL10n.of(context);
    final app = AppLocalizations.of(context);
    return showUiSheet<bool>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.share_card_linkAlreadyActive,
            style: UiText.h2(color: context.ui.ink),
          ),
          const SizedBox(height: UiSpace.sm),
          Text(
            l10n.share_card_linkConflict,
            style: UiText.muted(color: context.ui.inkMuted, size: 14),
          ),
          const SizedBox(height: UiSpace.sm),
          Text(
            uri.toString(),
            style: UiText.body(size: 14, height: 1.4, color: context.ui.ink),
          ),
          const SizedBox(height: UiSpace.lg),
          UiButton(
            key: const ValueKey('share-card-link-conflict-copy'),
            label: l10n.share_card_linkCopy,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: UiSpace.sm),
          UiButton.secondary(
            key: const ValueKey('share-card-link-conflict-reset'),
            label: l10n.share_card_linkResetAndCopy,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          const SizedBox(height: UiSpace.sm),
          UiButton.ghost(
            key: const ValueKey('share-card-link-conflict-cancel'),
            label: app.common_cancel,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
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
            onAccent: context.ui.onDanger,
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
      OurneyErrorCode.serverOutdated => app.common_serverOutdated,
      OurneyErrorCode.offline => app.common_offline,
      _ => app.common_errorGeneric,
    };
  }

  void _snack(String message) {
    showUiToast(context, message);
  }
}
