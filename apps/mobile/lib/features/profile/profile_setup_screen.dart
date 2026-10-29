import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/app_routes.dart';
import '../../app/providers.dart';
import '../../app/theme/motion.dart';
import '../../ui/ui.dart';
import 'avatar_picker.dart';
import 'l10n/generated/profile_localizations.dart';
import 'profile_providers.dart';

/// Profile setup after the first sign-in (FR-A2, App.tsx `ProfileSetup`), at
/// `/profile/setup`.
///
/// The auth flow opens it when `ProfileRepository.watchMe()` yields null
/// right after `verifyOtp`. (It cannot live under `/auth`: the router leaves
/// `/auth/*` as soon as a user id exists.) On save it continues to [from]
/// (a sanitized in-app path) or `/capture`.
///
/// Saving calls `ProfileRepository.upsertMe` and, if a photo was picked,
/// `ProfileRepository.setAvatar` (JPEG bytes). The username format is checked
/// locally with ourney_core's `validateUsername`; uniqueness is the server's
/// job: `upsertMe` failing with [OurneyErrorCode.invalid] after local
/// validation passed means "taken".
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({this.from, super.key});

  final String? from;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

enum _FormError { save, offline, avatar }

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _username = TextEditingController();
  final _displayName = TextEditingController();
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
    // The profile may already exist (e.g. re-opened): prefill if untouched.
    ref.listenManual(myProfileProvider, (previous, next) {
      final profile = next.value;
      if (profile != null && !_edited) {
        _username.text = profile.username;
        _displayName.text = profile.displayName;
      }
    }, fireImmediately: true);
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
            onPressed: () => Navigator.of(context).pop(AvatarSource.gallery),
          ),
          UiRow(
            key: const ValueKey('profile-avatar-camera'),
            leading: const Icon(Icons.photo_camera_outlined),
            title: l10n.profile_avatarFromCamera,
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
    final initial = ref.read(myProfileProvider).value;
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
    context.go(widget.from ?? AppRoutes.capture);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ProfileL10n.of(context);
    final ui = context.ui;
    final name = _displayName.text.trim().isEmpty
        ? (_username.text.isEmpty ? '?' : _username.text)
        : _displayName.text.trim();
    final hasAvatar = _picked != null;
    final usernameError = _usernameError(l10n);
    final usernameOk =
        _username.text.isNotEmpty &&
        validateUsername(_username.text) == null &&
        !_usernameTaken;
    final errorText = switch (_error) {
      _FormError.save => l10n.profile_saveError,
      _FormError.offline => l10n.profile_offlineError,
      _FormError.avatar => l10n.profile_avatarError,
      null => null,
    };

    return UiScaffold(
      key: const ValueKey('profile-setup-screen'),
      padTop: 24,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.profile_setupTitle,
                style: UiText.h1(color: ui.ink),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.profile_setupSubtitle,
              style: UiText.muted(color: ui.inkMuted, size: 14),
            ),
            const SizedBox(height: 24),
            Center(
              child: UiAvatarPicker(
                key: const ValueKey('profile-avatar-pick'),
                name: name,
                label: hasAvatar
                    ? l10n.profile_avatarChange
                    : l10n.profile_avatarAdd,
                image: _picked == null ? null : MemoryImage(_picked!),
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
            const SizedBox(height: 24),
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
              error: usernameError,
              trailing: usernameOk
                  ? Icon(Icons.check_rounded, size: 19, color: ui.success)
                  : null,
              onChanged: (_) => setState(() => _edited = true),
              onSubmitted: (_) => _saving ? null : _save(),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 16),
              UiInlineError(
                key: const ValueKey('profile-form-error'),
                message: errorText,
              ),
            ],
            const SizedBox(height: 24),
            UiButton(
              key: const ValueKey('profile-save'),
              label: _saving ? l10n.profile_saving : l10n.profile_continue,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
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
