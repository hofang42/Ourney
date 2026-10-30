import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../app/theme/motion.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../journeys/domain/journey_progress.dart';
import '../data/share_card_exporter.dart';
import '../data/share_card_providers.dart';
import '../domain/share_card_content.dart';
import '../l10n/generated/share_card_localizations.dart';
import 'public_link_section.dart';
import 'share_card.dart';

/// How long the share flow waits for the chosen photo to decode before
/// rendering anyway (the preview normally has it already).
const Duration _photoWait = Duration(seconds: 3);

/// `/share/:journeyId`: card preview (story / feed), photo and number
/// options, share sheet (FR-E1/E2) and the solo public link (FR-E3).
class ShareCardScreen extends ConsumerStatefulWidget {
  const ShareCardScreen({required this.journeyId, super.key});

  final String journeyId;

  @override
  ConsumerState<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends ConsumerState<ShareCardScreen> {
  ShareCardFormat _format = ShareCardFormat.story;
  ShareCardNumber _number = ShareCardNumber.streak;
  String? _photoCheckInId;
  bool? _blurOverride;
  bool _busy = false;

  final _boundaryKeys = {
    for (final f in ShareCardFormat.values)
      f: GlobalKey(debugLabel: 'share-card-boundary-${f.name}'),
  };
  final _shareButtonKey = GlobalKey(debugLabel: 'share-card-share');

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.journeys);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ShareCardL10n.of(context);
    final app = AppLocalizations.of(context);
    final ui = context.ui;
    final id = widget.journeyId;
    final journeyAsync = ref.watch(shareJourneyProvider(id));
    final backLabel = MaterialLocalizations.of(context).backButtonTooltip;

    if (journeyAsync.hasError && shareNotWired(journeyAsync.error!)) {
      return UiScaffold(
        key: const ValueKey('placeholder-share_card'),
        scroll: false,
        child: UiFillScroll(
          child: UiEmptyState(
            icon: Icons.construction_rounded,
            title: l10n.share_card_title,
            body: app.placeholder_comingSoon,
          ),
        ),
      );
    }
    final journey = journeyAsync.value;
    if (journey == null) {
      return UiScaffold(
        key: const ValueKey('share-card-empty'),
        scroll: false,
        padTop: 0,
        child: Column(
          children: [
            UiBackHeader(
              onBack: _back,
              backLabel: backLabel,
              title: l10n.share_card_title,
            ),
            Expanded(
              child: UiFillScroll(
                child: journeyAsync.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          semanticsLabel: app.common_loading,
                        ),
                      )
                    : UiEmptyState(
                        icon: Icons.search_off_rounded,
                        title: l10n.share_card_notFound,
                        actionLabel: app.common_close,
                        onAction: _back,
                      ),
              ),
            ),
          ],
        ),
      );
    }

    final membership = ref.watch(shareMembershipProvider(id)).value;
    final checkIns = ref.watch(shareCheckInsProvider(id)).value ?? const [];
    final progress = JourneyProgress.compute(
      journey: journey,
      membership: membership,
      checkIns: checkIns,
      now: ref.watch(shareCardClockProvider).now(),
    );
    final content = ShareCardContent.from(
      journey: journey,
      membership: membership,
      streak: progress.summary,
      dayNumber: progress.dayNumber,
      checkIns: checkIns,
      number: _number,
    );
    final candidates = photoCandidates(checkIns);
    final selected =
        candidates.where((c) => c.id == _photoCheckInId).firstOrNull ??
        candidates.firstOrNull;
    final photo = selected == null
        ? null
        : _photoProvider(selected, thumb: false);
    final blur = _blurOverride ?? content.blurPhoto;
    final showLink = canHavePublicLink(
      journey: journey,
      membership: membership,
      currentUserId: ref.watch(currentUserIdProvider),
      hasBackend: ref.watch(appConfigProvider).hasBackend,
    );

    final caption = shareCardCaption(l10n, content);
    final previewLabel = l10n.share_card_previewLabel(
      [?caption.kicker, '${content.number}'].join(' '),
      caption.caption,
      '${content.emoji} ${content.title}',
    );
    final screenHeight = MediaQuery.sizeOf(context).height;
    final previewHeight = (screenHeight * 0.55).clamp(280.0, 620.0);

    return UiScaffold(
      key: const ValueKey('share-card-screen'),
      padTop: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiBackHeader(
            onBack: _back,
            backLabel: backLabel,
            title: l10n.share_card_title,
          ),
          const SizedBox(height: UiSpace.sm),
          _SectionLabel(l10n.share_card_sizeLabel),
          KeyedSubtree(
            key: const ValueKey('share-card-format'),
            child: UiSegmented<ShareCardFormat>(
              segments: [
                UiSegment(
                  value: ShareCardFormat.story,
                  label: l10n.share_card_sizeStory,
                ),
                UiSegment(
                  value: ShareCardFormat.feed,
                  label: l10n.share_card_sizeFeed,
                ),
              ],
              value: _format,
              onChanged: (f) {
                OurneyHaptics.selection();
                setState(() => _format = f);
              },
            ),
          ),
          const SizedBox(height: UiSpace.lg),
          SizedBox(
            height: previewHeight,
            child: AnimatedSwitcher(
              duration: UiMotion.of(context, UiMotion.sheet),
              child: KeyedSubtree(
                key: ValueKey('share-card-preview-${_format.name}'),
                child: Semantics(
                  image: true,
                  label: previewLabel,
                  excludeSemantics: true,
                  child: Center(
                    child: FittedBox(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: ui.shadow,
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: RepaintBoundary(
                          key: _boundaryKeys[_format],
                          child: ShareCard(
                            content: content,
                            format: _format,
                            blur: blur,
                            photo: photo,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: UiSpace.xl),
          KeyedSubtree(
            key: _shareButtonKey,
            child: UiButton(
              key: const ValueKey('share-card-share'),
              label: _busy
                  ? l10n.share_card_preparing
                  : l10n.share_card_shareButton,
              icon: Icons.ios_share_rounded,
              loading: _busy,
              onPressed: _busy
                  ? null
                  : () => _share(journey: journey, photo: photo),
            ),
          ),
          const SizedBox(height: UiSpace.xl),
          _SectionLabel(l10n.share_card_numberLabel),
          KeyedSubtree(
            key: const ValueKey('share-card-number-mode'),
            child: UiSegmented<ShareCardNumber>(
              segments: [
                UiSegment(
                  value: ShareCardNumber.streak,
                  label: l10n.share_card_numberStreak,
                ),
                UiSegment(
                  value: ShareCardNumber.day,
                  label: l10n.share_card_numberDay,
                ),
              ],
              value: _number,
              onChanged: (n) {
                OurneyHaptics.selection();
                setState(() => _number = n);
              },
            ),
          ),
          const SizedBox(height: UiSpace.xl),
          _SectionLabel(l10n.share_card_photoLabel),
          if (candidates.isEmpty)
            Text(
              l10n.share_card_photoNone,
              key: const ValueKey('share-card-photo-none'),
              style: UiText.muted(color: ui.inkMuted, size: 14),
            )
          else ...[
            _PhotoStrip(
              candidates: candidates,
              selectedId: selected?.id,
              thumbnails: [
                for (final c in candidates) _photoProvider(c, thumb: true),
              ],
              onSelect: (c) => setState(() => _photoCheckInId = c.id),
            ),
            UiSwitchRow(
              key: const ValueKey('share-card-blur'),
              label: l10n.share_card_blurPhoto,
              subtitle: content.blurPhoto
                  ? l10n.share_card_blurPhotoHint
                  : null,
              value: blur,
              divider: false,
              onChanged: (v) => setState(() => _blurOverride = v),
            ),
          ],
          if (content.metricHidden)
            Padding(
              padding: const EdgeInsets.only(top: UiSpace.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.visibility_off_outlined, size: 20, color: ui.ink),
                  const SizedBox(width: UiSpace.sm),
                  Expanded(
                    child: Text(
                      l10n.share_card_metricHidden,
                      key: const ValueKey('share-card-metric-hidden'),
                      style: UiText.body(size: 14, height: 1.45, color: ui.ink),
                    ),
                  ),
                ],
              ),
            ),
          if (showLink) ...[
            const SizedBox(height: UiSpace.xl),
            PublicLinkSection(journey: journey),
          ],
        ],
      ),
    );
  }

  /// Resolved photo (on-device file or MediaStore cache) as an image, or
  /// null while it is being resolved / when it cannot be.
  ImageProvider? _photoProvider(CheckIn c, {required bool thumb}) {
    final local = c.localPhotoFile;
    final key = (
      storagePath: thumb ? c.thumbPath : c.photoPath,
      // Thumbnails of uploaded check-ins come from the cache; until upload
      // the only file is the local photo.
      localFile: thumb && c.uploaded ? null : local,
    );
    final path = ref.watch(shareCardPhotoFileProvider(key)).value;
    if (path == null) return null;
    return ResizeImage.resizeIfNeeded(
      thumb ? 216 : null,
      null,
      FileImage(File(path)),
    );
  }

  Future<void> _share({
    required Journey journey,
    required ImageProvider? photo,
  }) async {
    final l10n = ShareCardL10n.of(context);
    final format = _format;
    final exporter = ref.read(shareCardExporterProvider);
    final sharer = ref.read(shareCardSharerProvider);
    setState(() => _busy = true);
    try {
      if (photo != null) {
        await precacheImage(
          photo,
          context,
          onError: (_, _) {},
        ).timeout(_photoWait, onTimeout: () {});
      }
      // Make sure the latest state is painted before capturing.
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _boundaryKeys[format]?.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('share card not laid out');
      final file = await exporter.export(
        boundary,
        format,
        baseName: shareCardBaseName(journey.id, format),
      );
      await sharer.shareImage(
        path: file.path,
        mimeType: file.mimeType,
        text: l10n.share_card_shareText(journey.emoji, journey.title),
        origin: _shareOrigin(),
      );
    } on Object {
      if (mounted) _snack(l10n.share_card_shareError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Rect? _shareOrigin() {
    final box = _shareButtonKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _snack(String message) => showUiToast(context, message);
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: UiSpace.sm),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: UiText.body(
          size: 14,
          weight: FontWeight.w700,
          height: 1.4,
          color: context.ui.ink,
        ),
      ),
    ),
  );
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
    required this.candidates,
    required this.selectedId,
    required this.thumbnails,
    required this.onSelect,
  });

  final List<CheckIn> candidates;
  final String? selectedId;

  /// Same order as [candidates]; null while unresolved.
  final List<ImageProvider?> thumbnails;
  final ValueChanged<CheckIn> onSelect;

  static const double _size = 72;

  @override
  Widget build(BuildContext context) {
    final l10n = ShareCardL10n.of(context);
    final material = MaterialLocalizations.of(context);
    final ui = context.ui;
    return SizedBox(
      height: _size + UiSpace.sm,
      child: ListView.separated(
        key: const ValueKey('share-card-photos'),
        scrollDirection: Axis.horizontal,
        itemCount: candidates.length,
        separatorBuilder: (_, _) => const SizedBox(width: UiSpace.sm),
        itemBuilder: (context, i) {
          final checkIn = candidates[i];
          final selected = checkIn.id == selectedId;
          final d = checkIn.localDate;
          final provider = thumbnails[i];
          return UiPressable(
            key: ValueKey('share-card-photo-${checkIn.id}'),
            onPressed: () => onSelect(checkIn),
            selected: selected,
            semanticLabel: l10n.share_card_photoOfDay(
              material.formatMediumDate(DateTime(d.year, d.month, d.day)),
            ),
            excludeChildSemantics: true,
            borderRadius: BorderRadius.circular(UiRadius.thumb),
            minSize: const Size.square(_size),
            child: Container(
              width: _size,
              height: _size,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: ui.surface,
                borderRadius: BorderRadius.circular(UiRadius.thumb),
                border: Border.all(
                  color: selected ? ui.ink : ui.border,
                  width: selected ? 3 : 1,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (provider == null)
                    Icon(Icons.photo_outlined, color: ui.inkMuted)
                  else
                    Image(
                      image: provider,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stack) =>
                          Icon(Icons.photo_outlined, color: ui.inkMuted),
                    ),
                  // Selection is not shown by color alone.
                  if (selected)
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(UiSpace.xs),
                        decoration: BoxDecoration(
                          color: ui.ink,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: ui.bg,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
