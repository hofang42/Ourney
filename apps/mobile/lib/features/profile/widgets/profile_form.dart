import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../app/theme/motion.dart';
import '../../../ui/ui.dart';
import '../avatar_picker.dart';
import '../l10n/generated/profile_localizations.dart';
import '../profile_providers.dart';

/// Username + display name + optional avatar (FR-A2) for "edit profile".
/// (First-sign-in setup has its own screen, `ProfileSetupScreen`.)
///
/// Saving calls `ProfileRepository.upsertMe` and then, if a new photo was
/// picked, `ProfileRepository.setAvatar` (JPEG bytes). The username format is
/// checked locally with ourney_core's `validateUsername`; uniqueness is the
/// server's job (`profiles.username` UNIQUE): `upsertMe` failing with
/// [OurneyErrorCode.invalid] after local validation passed means "taken".
class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({
    required this.submitLabel,
    required this.onSaved,
    this.initial,
    super.key,
  });

  final Profile? initial;
  final String submitLabel;
  final VoidCallback onSaved;

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

enum _FormError { save, offline, avatar }

class _ProfileFormState extends ConsumerState<ProfileForm> {
  late final TextEditingController _username;
  late final TextEditingController _displayName;
  Uint8List? _picked;
  bool _saving = false;
  bool _submitted = false;
  bool _edited = false;
  bool _usernameTaken = false;
  String? _takenUsername;
  _FormError? _error;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: widget.initial?.username ?? '');
    _displayName = TextEditingController(
      text: widget.initial?.displayName ?? '',
    );
  }

  @override
  void didUpdateWidget(ProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The profile may arrive after the form is shown: prefill if untouched.
    final next = widget.initial;
    if (oldWidget.initial == null && next != null && !_edited) {
      _username.text = next.username;
      _displayName.text = next.displayName;
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    super.dispose();
  }

  String? _usernameError(ProfileL10n l10n) {
    final value = _username.text;
    if (_usernameTaken && value == _takenUsername) {
      return l10n.profile_usernameTaken;
    }
    if (!_submitted && value.isEmpty) return null;
    return switch (validateUsername(value)) {
      UsernameError.tooShort => l10n.profile_usernameTooShort(usernameMin),
      UsernameError.tooLong => l10n.profile_usernameTooLong(usernameMax),
      UsernameError.invalidChars => l10n.profile_usernameInvalidChars,
      null => null,
    };
  }

  String? _displayNameError(ProfileL10n l10n) {
    if (!_submitted && _displayName.text.isEmpty) return null;
    return switch (validateDisplayName(_displayName.text)) {
      DisplayNameError.empty => l10n.profile_displayNameEmpty,
      DisplayNameError.tooLong => l10n.profile_displayNameTooLong(
        displayNameMax,
      ),
      null => null,
    };
  }

  Future<void> _pickAvatar() async {
    final l10n = ProfileL10n.of(context);
    final source = await showUiSheet<AvatarSource>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          UiRow(
            key: const ValueKey('profile-avatar-gallery'),
            leading: const Icon(Icons.photo_library_outlined),
            title: l10n.profile_avatarFromGallery,
            showChevron: false,
            onPressed: () => Navigator.of(context).pop(AvatarSource.gallery),
          ),
          UiRow(
            key: const ValueKey('profile-avatar-camera'),
            leading: const Icon(Icons.photo_camera_outlined),
            title: l10n.profile_avatarFromCamera,
            showChevron: false,
            divider: false,
            onPressed: () => Navigator.of(context).pop(AvatarSource.camera),
          ),
        ],
      ),
    );
    if (source == null || !mounted) return;
    final picker = ref.read(avatarPickerProvider);
    final Uint8List? bytes;
    try {
      bytes = await picker.pick(source);
    } on Object {
      if (mounted) setState(() => _error = _FormError.avatar);
      return;
    }
    if (bytes == null || !mounted) return;
    setState(() {
      _picked = bytes;
      _edited = true;
      if (_error == _FormError.avatar) _error = null;
    });
  }

  Future<void> _save() async {
    final l10n = ProfileL10n.of(context);
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (_usernameError(l10n) != null || _displayNameError(l10n) != null) {
      return;
    }
    final username = _username.text;
    final displayName = _displayName.text.trim();
    final repo = ref.read(profileRepositoryProvider);
    final initial = widget.initial;
    final profileChanged =
        initial == null ||
        initial.username != username ||
        initial.displayName != displayName;

    setState(() => _saving = true);
    try {
      if (profileChanged) {
        await repo.upsertMe(username: username, displayName: displayName);
      }
    } on OurneyException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        switch (e.error) {
          case OurneyErrorCode.invalid:
            _usernameTaken = true;
            _takenUsername = username;
          case OurneyErrorCode.offline:
            _error = _FormError.offline;
          default:
            _error = _FormError.save;
        }
      });
      return;
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = _FormError.save;
        });
      }
      return;
    }

    final picked = _picked;
    if (picked != null) {
      try {
        await repo.setAvatar(picked);
      } on Object catch (e) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _error = e is OurneyException && e.error == OurneyErrorCode.offline
              ? _FormError.offline
              : _FormError.avatar;
        });
        return;
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
    OurneyHaptics.success();
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ProfileL10n.of(context);
    final ui = context.ui;
    final name = _displayName.text.trim().isEmpty
        ? (_username.text.isEmpty ? '?' : _username.text)
        : _displayName.text.trim();
    final hasAvatar = _picked != null || widget.initial?.avatarPath != null;
    final storagePath = widget.initial?.avatarPath;
    final storedFile = _picked == null && storagePath != null
        ? ref.watch(avatarFileProvider(storagePath)).value
        : null;
    final ImageProvider? image = _picked != null
        ? MemoryImage(_picked!)
        : storedFile != null
        ? FileImage(File(storedFile))
        : null;
    final errorText = switch (_error) {
      _FormError.save => l10n.profile_saveError,
      _FormError.offline => l10n.profile_offlineError,
      _FormError.avatar => l10n.profile_avatarError,
      null => null,
    };

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: UiAvatarPicker(
              key: const ValueKey('profile-avatar-pick'),
              name: name,
              label: hasAvatar
                  ? l10n.profile_avatarChange
                  : l10n.profile_avatarAdd,
              image: image,
              colorIndex: UiAvatar.indexFor(name),
              onPressed: _saving ? null : _pickAvatar,
            ),
          ),
          if (!hasAvatar)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.profile_avatarOptional,
                textAlign: TextAlign.center,
                style: UiText.body(size: 12, color: ui.inkMuted),
              ),
            ),
          const SizedBox(height: UiSpace.xxl),
          UiTextField(
            fieldKey: const ValueKey('profile-display-name'),
            label: l10n.profile_displayNameLabel,
            controller: _displayName,
            enabled: !_saving,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            error: _displayNameError(l10n),
            onChanged: (_) => setState(() => _edited = true),
          ),
          const SizedBox(height: 18),
          UiTextField(
            fieldKey: const ValueKey('profile-username'),
            label: l10n.profile_usernameLabel,
            controller: _username,
            enabled: !_saving,
            autocorrect: false,
            prefixText: '@',
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newUsername],
            inputFormatters: [
              _LowerCaseFormatter(),
              LengthLimitingTextInputFormatter(usernameMax + 5),
            ],
            helper: l10n.profile_usernameHelper,
            error: _usernameError(l10n),
            onChanged: (_) => setState(() => _edited = true),
            onSubmitted: (_) => _saving ? null : _save(),
          ),
          if (errorText != null) ...[
            const SizedBox(height: UiSpace.lg),
            UiInlineError(
              key: const ValueKey('profile-form-error'),
              message: errorText,
            ),
          ],
          const SizedBox(height: UiSpace.xxl),
          UiButton(
            key: const ValueKey('profile-save'),
            label: _saving ? l10n.profile_saving : widget.submitLabel,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _LowerCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toLowerCase());
}
