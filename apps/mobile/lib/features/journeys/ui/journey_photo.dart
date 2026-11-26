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
    this.attachment = false,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.fallback,
    super.key,
  });

  final CheckIn checkIn;
  final bool thumbnail;

  /// Shows the historical attachment submitted by this check-in's author.
  final bool attachment;
  final BoxFit fit;
  final int? cacheWidth;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeholder = fallback ?? const _PhotoFallback();
    final attachmentPath = checkIn.partnerPhotoPath;
    if (attachment && attachmentPath == null) return placeholder;
    final local = attachment
        ? checkIn.localPartnerPhotoFile
        : checkIn.localPhotoFile;
    final String? path;
    if (local != null && (attachment || !thumbnail || !checkIn.uploaded)) {
      path = local;
    } else {
      // Historical attachments only have a full-size image.
      final storagePath = attachment
          ? attachmentPath!
          : thumbnail
          ? checkIn.thumbPath
          : checkIn.photoPath;
      final resolved = ref.watch(mediaFileProvider(storagePath));
      path = resolved.value ?? (resolved.hasError ? local : null);
    }
    if (path == null) return placeholder;
    return Image.file(
      File(path),
      key: ValueKey(path),
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
