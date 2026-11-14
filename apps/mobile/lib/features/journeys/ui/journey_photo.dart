import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../ui/ui.dart';

/// Photo of a check-in: thumbnail in grid cells, full photo in the viewer.
/// Shows [fallback] while loading or when the file cannot be read.
class JourneyPhoto extends ConsumerWidget {
  const JourneyPhoto({
    required this.checkIn,
    this.thumbnail = true,
    this.partner = false,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.fallback,
    super.key,
  });

  final CheckIn checkIn;
  final bool thumbnail;

  /// Shows the partner's photo of a couple check-in instead of the author's.
  final bool partner;
  final BoxFit fit;
  final int? cacheWidth;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeholder = fallback ?? const _PhotoFallback();
    final partnerPath = checkIn.partnerPhotoPath;
    if (partner && partnerPath == null) return placeholder;
    final local = partner
        ? checkIn.localPartnerPhotoFile
        : checkIn.localPhotoFile;
    final String? path;
    if (local != null && (partner || !thumbnail || !checkIn.uploaded)) {
      path = local;
    } else {
      // The partner photo has no thumbnail: the full image serves both.
      final storagePath = partner
          ? partnerPath!
          : thumbnail
          ? checkIn.thumbPath
          : checkIn.photoPath;
      final resolved = ref.watch(mediaFileProvider(storagePath));
      path = resolved.value ?? (resolved.hasError ? local : null);
    }
    if (path == null) return placeholder;
    return Image.file(
      File(path),
      fit: fit,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stack) => placeholder,
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return ColoredBox(
      color: ui.success.withValues(alpha: 0.18),
      child: Center(
        child: OurneyIcon(name: 'check', color: ui.ink, size: 20, flat: true),
      ),
    );
  }
}
