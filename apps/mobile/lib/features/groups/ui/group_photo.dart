import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../ui/ui.dart';

/// A member's check-in photo, resolved through `MediaStore.localFileFor`
/// (thumbnail by default). Uses the on-device file while the caller's own
/// photo is still uploading. Shows a neutral placeholder otherwise.
class GroupPhoto extends ConsumerWidget {
  const GroupPhoto({
    required this.checkIn,
    this.thumbnail = true,
    this.dimmed = false,
    this.decodeWidth = 480,
    super.key,
  });

  final CheckIn checkIn;
  final bool thumbnail;

  /// Older photo (member not checked in today): drawn faded.
  final bool dimmed;

  /// Logical width the photo is shown at (decode size = this x DPR).
  final double decodeWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final local = checkIn.localPhotoFile;
    String? path;
    if (local != null && !checkIn.uploaded) {
      path = local;
    } else {
      final storagePath = thumbnail ? checkIn.thumbPath : checkIn.photoPath;
      final resolved = ref.watch(mediaFileProvider(storagePath));
      path = resolved.value ?? (resolved.hasError ? local : null);
    }
    final Widget image = path == null
        ? const _PhotoFallback()
        : Image.file(
            File(path),
            fit: BoxFit.cover,
            // Decode near the displayed size, not the full 12MP original.
            cacheWidth: (decodeWidth * dpr).ceil(),
            gaplessPlayback: true,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stack) => const _PhotoFallback(),
          );
    return Opacity(opacity: dimmed ? 0.55 : 1, child: image);
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return ColoredBox(
      color: ui.fill,
      child: Center(
        child: OurneyIcon(
          name: 'image',
          size: 24,
          flat: true,
          color: ui.inkMuted,
        ),
      ),
    );
  }
}

/// Avatar image from a storage path (null while loading / missing).
ImageProvider? groupAvatarImage(WidgetRef ref, String? avatarPath) {
  if (avatarPath == null) return null;
  final file = ref.watch(mediaFileProvider(avatarPath)).value;
  return file == null ? null : FileImage(File(file));
}
