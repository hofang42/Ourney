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
    super.key,
  });

  final CheckIn checkIn;
  final bool thumbnail;

  /// Older photo (member not checked in today): drawn faded.
  final bool dimmed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      child: Center(child: Icon(Icons.photo_outlined, color: ui.inkMuted)),
    );
  }
}

/// Avatar image from a storage path (null while loading / missing).
ImageProvider? groupAvatarImage(WidgetRef ref, String? avatarPath) {
  if (avatarPath == null) return null;
  final file = ref.watch(mediaFileProvider(avatarPath)).value;
  return file == null ? null : FileImage(File(file));
}
