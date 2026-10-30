import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/ui.dart';
import '../l10n/generated/profile_localizations.dart';
import '../profile_providers.dart';

/// [UiAvatar] for a profile: freshly picked [bytes] win over the stored
/// [storagePath] (resolved through MediaStore); initials otherwise.
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({
    required this.name,
    this.storagePath,
    this.bytes,
    this.size = UiSize.avatarXL,
    super.key,
  });

  final String name;
  final String? storagePath;
  final Uint8List? bytes;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ImageProvider? image;
    if (bytes != null) {
      image = MemoryImage(bytes!);
    } else if (storagePath != null) {
      final file = ref.watch(avatarFileProvider(storagePath!)).value;
      if (file != null) image = FileImage(File(file));
    }
    return Semantics(
      label: ProfileL10n.of(context).profile_avatarSemantics(name),
      image: true,
      excludeSemantics: true,
      child: UiAvatar(
        name: name,
        colorIndex: UiAvatar.indexFor(name),
        image: image,
        size: size,
      ),
    );
  }
}
