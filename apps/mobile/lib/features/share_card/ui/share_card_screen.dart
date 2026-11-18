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
import '../../profile/settings_providers.dart';
import '../../sharing/data/sharing_providers.dart';
import '../data/share_card_exporter.dart';
import '../data/share_card_providers.dart';
import '../domain/share_card_content.dart';
import '../l10n/generated/share_card_localizations.dart';
import 'public_link_section.dart';
import 'share_card.dart';
import 'share_skin_chrome.dart';

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
  bool? _hideBrand;
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
    final id = widget.journeyId;
    final journeyAsync = ref.watch(shareJourneyProvider(id));
    final backLabel = MaterialLocalizations.of(context).backButtonTooltip;

    if (journeyAsync.hasError && shareNotWired(journeyAsync.error!)) {
      return UiScaffold(
        key: const ValueKey('placeholder-share_card'),
        scroll: false,
        child: UiFillScroll(
          child: UiEmptyState(
            glyph: const OurneyIcon(name: 'warning', size: 30),
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
                        glyph: const OurneyIcon(name: 'search', size: 30),
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
    final hasBackend = ref.watch(appConfigProvider).hasBackend;
    // Every check-in counts for the streak / numbers; only the photos
    // offered on the card are filtered.
    final checkIns = ref.watch(shareCheckInsProvider(id)).value ?? const [];
    // S11: photos hidden from every share never reach the card. Only the
    // server knows the flag (`hidden_in_share`), so local-only has none.
    // Fail closed: with a backend, no photo is offered (and nothing can be
    // exported) until that flag has loaded; on error the user can retry.
    final stateAsync = hasBackend ? ref.watch(shareStateProvider(id)) : null;
    final stateReady = stateAsync == null || stateAsync.hasValue;
    final stateFailed =
        stateAsync != null && stateAsync.hasError && !stateAsync.hasValue;
    final hiddenInShare =
        stateAsync?.value?.hiddenCheckInIds ?? const <String>{};
    final shareable = stateReady
        ? [
            for (final c in checkIns)
              if (!hiddenInShare.contains(c.id)) c,
          ]
        : const <CheckIn>[];
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
      // Global Settings > privacy switches (FR-B7).
      hideMetricOnShare: ref.watch(hideWeightOnShareProvider),
      blurPhotosOnShare: ref.watch(blurPhotosOnShareProvider),
    );
    final candidates = photoCandidates(shareable);
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
      hasBackend: hasBackend,
    );

    final caption = shareCardCaption(l10n, content);
    final previewLabel = l10n.share_card_previewLabel(
      [?caption.kicker, '${content.number}'].join(' '),
      caption.caption,
      '${content.emoji} ${content.title}',
    );
    final skinId = uiSkinIdFor(
      personaSkinForTemplate(
        journey.templateId,
        kind: journey.kind,
        maxMembers: journey.maxMembers,
        emoji: journey.emoji,
      ),
    );
    final hideBrand = _hideBrand ?? shareCardHidesBrandByDefault(skinId);
    final gallery = <ImageProvider>[
      for (final c in candidates.take(36)) ?_photoProvider(c, thumb: true),
    ];
    final screenHeight = MediaQuery.sizeOf(context).height;
    final previewHeight = (screenHeight * 0.55).clamp(280.0, 620.0);
    final quiet = skinId == 'quiet';
    void openSheet() => showShareSheet(
      context: context,
      skinId: skinId,
      title: switch (skinId) {
        'squad' => l10n.share_card_squadSheetTitle,
        'memory' => l10n.share_card_memorySheetTitle,
        'couple' => l10n.share_card_coupleSheetTitle,
        'flexer' => l10n.share_card_flexerSheetTitle,
        _ => l10n.share_card_minimalSheetTitle,
      },
      hideBrand: hideBrand,
      onHideBrand: (v) => setState(() => _hideBrand = v),
      onAction: () => _share(journey: journey, photo: photo, skinId: skinId),
    );
    final actionLabel = switch (skinId) {
      'quiet' => l10n.share_card_export,
      'squad' => l10n.share_card_squadShare,
      'memory' => l10n.share_card_memoryShare,
      'couple' => l10n.share_card_coupleShare,
      'flexer' => l10n.share_card_flexerShare,
      _ => l10n.share_card_minimalExport,
    };

    return UiSkinScope(
      skinId: skinId,
      child: Builder(
        builder: (context) {
          final ui = context.ui;
          final heading = switch (skinId) {
            'quiet' => Text(
              l10n.share_card_quietTitle,
              key: const ValueKey('share-card-heading'),
              style: UiText.heading(
                font: 'Fraunces',
                size: 28,
                weight: 300,
                height: 1.2,
                tracking: -0.025,
                color: ui.ink,
              ),
            ),
            'squad' => Text(
              l10n.share_card_squadTitle,
              key: const ValueKey('share-card-heading'),
              style: UiText.heading(
                font: 'Space Grotesk',
                size: 25,
                weight: 700,
                height: 1.2,
                tracking: -0.03,
                color: ui.ink,
              ),
            ),
            'memory' => Text(
              l10n.share_card_tripPosterTitle(
                content.totalDays ?? content.dayNumber,
                content.title.toUpperCase(),
              ),
              key: const ValueKey('share-card-heading'),
              style: UiText.heading(
                font: 'Fraunces',
                size: 26,
                weight: 300,
                height: 1.25,
                color: ui.ink,
              ),
            ),
            'couple' => DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: ui.ink.withValues(alpha: 0.28)),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  l10n.share_card_coupleTitle(
                    content.dayNumber.clamp(1, 100000),
                    content.photoCount,
                  ),
                  key: const ValueKey('share-card-heading'),
                  style: UiText.heading(
                    font: 'Playfair Display',
                    size: 18,
                    weight: 600,
                    height: 1.35,
                    tracking: 0.08,
                    color: ui.ink,
                  ),
                ),
              ),
            ),
            _ => null,
          };
          return UiScaffold(
            key: const ValueKey('share-card-screen'),
            padTop: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ShareTopBar(
                  skinId: skinId,
                  title: journey.title,
                  onBack: _back,
                  backLabel: backLabel,
                ),
                const SizedBox(height: UiSpace.md),
                ?heading,
                if (heading != null) const SizedBox(height: UiSpace.md),
                ShareRatioTabs<ShareCardFormat>(
                  skinId: skinId,
                  values: const [
                    (ShareCardFormat.story, '9:16'),
                    (ShareCardFormat.feed, '4:5'),
                  ],
                  value: _format,
                  onChanged: (f) => setState(() => _format = f),
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
                                  // The quiet card always blurs its portrait.
                                  blur: quiet ? true : blur,
                                  photo: photo,
                                  gallery: gallery,
                                  skinId: skinId,
                                  hideBrand: hideBrand,
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
                if (quiet) ...[
                  QuietShareControls(
                    note: _quietNote(l10n, blur || quiet, content.metricHidden),
                    hideBrand: hideBrand,
                    onHideBrand: (v) => setState(() => _hideBrand = v),
                  ),
                  const SizedBox(height: UiSpace.md),
                ],
                if (!stateReady) ...[
                  if (stateFailed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: UiSpace.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.share_card_stateError,
                            key: const ValueKey('share-card-state-error'),
                            style: UiText.body(
                              size: 14,
                              height: 1.45,
                              color: ui.ink,
                            ),
                          ),
                          const SizedBox(height: UiSpace.sm),
                          UiButton.ghost(
                            key: const ValueKey('share-card-state-retry'),
                            label: app.common_retry,
                            onPressed: () =>
                                ref.invalidate(shareStateProvider(id)),
                          ),
                        ],
                      ),
                    ),
                ],
                KeyedSubtree(
                  key: _shareButtonKey,
                  child: ShareActionButton(
                    key: const ValueKey('share-card-share'),
                    skinId: skinId,
                    label: _busy ? l10n.share_card_preparing : actionLabel,
                    glyph: quiet ? null : 'share',
                    loading: _busy,
                    onPressed: _busy || !stateReady
                        ? null
                        : quiet
                        ? () => _share(
                            journey: journey,
                            photo: photo,
                            skinId: skinId,
                          )
                        : openSheet,
                  ),
                ),
                const SizedBox(height: UiSpace.xl),
                _SectionLabel(l10n.share_card_moreOptions),
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
                      for (final c in candidates)
                        _photoProvider(c, thumb: true),
                    ],
                    onSelect: (c) => setState(() => _photoCheckInId = c.id),
                  ),
                  // The quiet card always blurs its portrait: the switch
                  // shows that and cannot be turned off there.
                  UiSwitchRow(
                    key: const ValueKey('share-card-blur'),
                    label: l10n.share_card_blurPhoto,
                    subtitle: quiet
                        ? l10n.share_card_blurPhotoLocked
                        : content.blurPhoto
                        ? l10n.share_card_blurPhotoHint
                        : null,
                    value: quiet || blur,
                    divider: false,
                    onChanged: quiet
                        ? null
                        : (v) => setState(() => _blurOverride = v),
                  ),
                ],
                if (content.metricHidden && !quiet)
                  Padding(
                    padding: const EdgeInsets.only(top: UiSpace.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OurneyIcon(
                          name: 'lock',
                          flat: true,
                          size: 20,
                          color: ui.ink,
                        ),
                        const SizedBox(width: UiSpace.sm),
                        Expanded(
                          child: Text(
                            l10n.share_card_metricHidden,
                            key: const ValueKey('share-card-metric-hidden'),
                            style: UiText.body(
                              size: 14,
                              height: 1.45,
                              color: ui.ink,
                            ),
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
        },
      ),
    );
  }

  String? _quietNote(ShareCardL10n l10n, bool blur, bool metricHidden) =>
      blur && metricHidden
      ? l10n.share_card_noteBoth
      : blur
      ? l10n.share_card_noteBlur
      : metricHidden
      ? l10n.share_card_noteMetric
      : null;

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
    required String skinId,
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
                  color: selected ? ui.outline : ui.border,
                  width: selected ? UiBorder.standard : UiBorder.hairline,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (provider == null)
                    OurneyIcon(name: 'image', flat: true, color: ui.inkMuted)
                  else
                    Image(
                      image: provider,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stack) => OurneyIcon(
                        name: 'image',
                        flat: true,
                        color: ui.inkMuted,
                      ),
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
                        child: OurneyIcon(
                          name: 'check',
                          flat: true,
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
