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
import '../../../app/theme/tokens.dart';
import '../../../data/group_daily_checkins_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../personas/persona_contract.dart';
import '../../../personas/persona_switchers.dart';
import '../../../shared/chunky_button.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/placeholder_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = ShareCardL10n.of(context);
    final app = AppLocalizations.of(context);
    final id = widget.journeyId;
    final journeyAsync = ref.watch(shareJourneyProvider(id));

    if (journeyAsync.hasError && shareNotWired(journeyAsync.error!)) {
      return PlaceholderScreen(id: 'share_card', title: l10n.share_card_title);
    }
    final journey = journeyAsync.value;
    if (journey == null) {
      return Scaffold(
        key: const ValueKey('share-card-empty'),
        appBar: AppBar(title: Text(l10n.share_card_title)),
        body: SafeArea(
          child: journeyAsync.isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: app.common_loading,
                  ),
                )
              : EmptyState(
                  icon: Icons.search_off_rounded,
                  title: l10n.share_card_notFound,
                  actionLabel: app.common_close,
                  onAction: () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.journeys),
                ),
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
    final text = Theme.of(context).textTheme;

    return Scaffold(
      key: const ValueKey('share-card-screen'),
      appBar: AppBar(title: Text(l10n.share_card_title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(OurneySpacing.screenMargin),
          children: [
            _SectionLabel(l10n.share_card_sizeLabel),
            SegmentedButton<ShareCardFormat>(
              key: const ValueKey('share-card-format'),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ShareCardFormat.story,
                  icon: const Icon(Icons.crop_portrait_rounded),
                  label: Text(
                    l10n.share_card_sizeStory,
                    key: const ValueKey('share-card-format-story'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ButtonSegment(
                  value: ShareCardFormat.feed,
                  icon: const Icon(Icons.crop_3_2_rounded),
                  label: Text(
                    l10n.share_card_sizeFeed,
                    key: const ValueKey('share-card-format-feed'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              selected: {_format},
              onSelectionChanged: (s) {
                OurneyHaptics.selection();
                setState(() => _format = s.first);
              },
            ),
            const SizedBox(height: OurneySpacing.lg),
            SizedBox(
              height: previewHeight,
              child: AnimatedSwitcher(
                duration: OurneyMotion.duration(
                  context,
                  OurneyDurations.navigation,
                ),
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
                                color: OurneyColors.mediaBlack.withValues(
                                  alpha: 0.18,
                                ),
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
            const SizedBox(height: OurneySpacing.xl),
            KeyedSubtree(
              key: _shareButtonKey,
              child: ChunkyButton(
                key: const ValueKey('share-card-share'),
                label: _busy
                    ? l10n.share_card_preparing
                    : l10n.share_card_shareButton,
                icon: Icons.ios_share_rounded,
                onPressed: _busy
                    ? null
                    : () => _share(journey: journey, photo: photo),
              ),
            ),
            const SizedBox(height: OurneySpacing.xl),
            PersonaShareSwitcher(
              skin: personaSkinOf(journey),
              data: PersonaShareData(
                journey: journey,
                checkIns: checkIns,
                partnerCheckIns: ref
                    .watch(groupDailySnapshotProvider(journey))
                    .partnerCheckIns,
                currentStreak: progress.summary.current,
                dayNumber: progress.dayNumber,
                hideMetric: content.metricHidden,
                onShare: _busy
                    ? null
                    : () => _share(journey: journey, photo: photo),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              ),
            ),
            const SizedBox(height: OurneySpacing.xl),
            _SectionLabel(l10n.share_card_numberLabel),
            SegmentedButton<ShareCardNumber>(
              key: const ValueKey('share-card-number-mode'),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ShareCardNumber.streak,
                  label: Text(
                    l10n.share_card_numberStreak,
                    key: const ValueKey('share-card-number-streak'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ButtonSegment(
                  value: ShareCardNumber.day,
                  label: Text(
                    l10n.share_card_numberDay,
                    key: const ValueKey('share-card-number-day'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              selected: {_number},
              onSelectionChanged: (s) {
                OurneyHaptics.selection();
                setState(() => _number = s.first);
              },
            ),
            const SizedBox(height: OurneySpacing.xl),
            _SectionLabel(l10n.share_card_photoLabel),
            if (candidates.isEmpty)
              Text(
                l10n.share_card_photoNone,
                key: const ValueKey('share-card-photo-none'),
                style: text.bodyMedium,
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
              SwitchListTile(
                key: const ValueKey('share-card-blur'),
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.blur_on_rounded),
                title: Text(l10n.share_card_blurPhoto),
                subtitle: content.blurPhoto
                    ? Text(l10n.share_card_blurPhotoHint)
                    : null,
                value: blur,
                onChanged: (v) => setState(() => _blurOverride = v),
              ),
            ],
            if (content.metricHidden)
              Padding(
                padding: const EdgeInsets.only(top: OurneySpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.visibility_off_rounded, size: 20),
                    const SizedBox(width: OurneySpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.share_card_metricHidden,
                        key: const ValueKey('share-card-metric-hidden'),
                        style: text.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            if (showLink) ...[
              const SizedBox(height: OurneySpacing.xl),
              PublicLinkSection(journey: journey),
            ],
          ],
        ),
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

  void _snack(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: OurneySpacing.sm),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
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
    final c = OurneyColors.of(context);
    return SizedBox(
      height: _size + OurneySpacing.sm,
      child: ListView.separated(
        key: const ValueKey('share-card-photos'),
        scrollDirection: Axis.horizontal,
        itemCount: candidates.length,
        separatorBuilder: (_, _) => const SizedBox(width: OurneySpacing.sm),
        itemBuilder: (context, i) {
          final checkIn = candidates[i];
          final selected = checkIn.id == selectedId;
          final d = checkIn.localDate;
          final provider = thumbnails[i];
          return Semantics(
            button: true,
            selected: selected,
            label: l10n.share_card_photoOfDay(
              material.formatMediumDate(DateTime(d.year, d.month, d.day)),
            ),
            excludeSemantics: true,
            child: InkWell(
              key: ValueKey('share-card-photo-${checkIn.id}'),
              borderRadius: BorderRadius.circular(OurneyRadii.chip),
              onTap: () => onSelect(checkIn),
              child: Container(
                width: _size,
                height: _size,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(OurneyRadii.chip),
                  border: Border.all(
                    color: selected ? c.primary : c.border,
                    width: selected ? 3 : 1,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (provider == null)
                      Icon(Icons.photo_rounded, color: c.inkMuted)
                    else
                      Image(
                        image: provider,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (context, error, stack) =>
                            Icon(Icons.photo_rounded, color: c.inkMuted),
                      ),
                    // Selection is not shown by color alone.
                    if (selected)
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          margin: const EdgeInsets.all(OurneySpacing.xs),
                          decoration: BoxDecoration(
                            color: c.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: c.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
