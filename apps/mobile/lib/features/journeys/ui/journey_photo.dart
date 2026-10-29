import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';

/// Photo of a check-in: thumbnail in grid cells, full photo in the viewer.
/// Shows [fallback] while loading or when the file cannot be read.
class JourneyPhoto extends ConsumerWidget {
  const JourneyPhoto({
    required this.checkIn,
    this.thumbnail = true,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.fallback,
    super.key,
  });

  final CheckIn checkIn;
  final bool thumbnail;
  final BoxFit fit;
  final int? cacheWidth;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeholder = fallback ?? const _PhotoFallback();
    final local = checkIn.localPhotoFile;
    final String? path;
    if (local != null && (!thumbnail || !checkIn.uploaded)) {
      path = local;
    } else {
      final storagePath = thumbnail ? checkIn.thumbPath : checkIn.photoPath;
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
    final c = OurneyColors.of(context);
    return ColoredBox(
      color: c.success.withValues(alpha: 0.18),
      child: Center(child: Icon(Icons.check_rounded, color: c.ink, size: 20)),
    );
  }
}
