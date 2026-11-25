import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/app_routes.dart';
import '../../app/providers.dart';
import '../../app/redirect.dart' show ProfileGateStatus, safeFrom;
import '../../app/theme/motion.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/ui.dart';
import '../onboarding/onboarding_providers.dart';
import '../safety/data/safety_providers.dart' show eulaAcceptedProvider;
import 'avatar_picker.dart';
import 'l10n/generated/profile_localizations.dart';
import 'profile_providers.dart';
import 'widgets/profile_face_avatar.dart';
import 'widgets/sign_out_flow.dart';

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
  final Map<String, bool> _availability = {};
  int _checkSeq = 0;
  _FormError? _error;

  @override
  void initState() {
    super.initState();
    // The profile may already exist (e.g. re-opened): prefill if untouched.
    ref.listenManual(myProfileProvider, (previous, next) {
      final profile = next.asData?.value;
      if (profile != null && !_edited) {
        _username.text = profile.username;
        _displayName.text = profile.displayName;
        _availability[profile.username] = true;
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
    if ((_usernameTaken && value == _takenUsername) ||
        _availability[value] == false) {
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

  void _onUsernameChanged(String value) {
    final seq = ++_checkSeq;
    setState(() {
      _edited = true;
      if (value != _takenUsername) {
        _usernameTaken = false;
        _takenUsername = null;
      }
    });
    if (validateUsername(value) != null) return;
    final initial = ref.read(myProfileProvider).asData?.value;
    if (initial != null && initial.username == value) {
      setState(() {
        _availability[value] = true;
        _usernameTaken = false;
        _takenUsername = null;
      });
      return;
    }
    final cached = _availability[value];
    if (cached != null) {
      setState(() {
        _usernameTaken = !cached;
        _takenUsername = cached ? null : value;
      });
      return;
    }
    final ProfileRepository repo;
    try {
      repo = ref.read(profileRepositoryProvider);
    } on Object {
      return;
    }
    unawaited(() async {
      try {
        final ok = await repo.isUsernameAvailable(value);
        if (!mounted || seq != _checkSeq || _username.text != value) return;
        setState(() {
          _availability[value] = ok;
          _usernameTaken = !ok;
          _takenUsername = ok ? null : value;
        });
      } on Object {
        if (!mounted || seq != _checkSeq || _username.text != value) return;
        setState(() {
          _availability.remove(value);
        });
      }
    }());
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
            leading: const OurneyIcon(name: 'gallery', flat: true),
            title: l10n.profile_avatarFromGallery,
            onPressed: () => Navigator.of(context).pop(AvatarSource.gallery),
          ),
          UiRow(
            key: const ValueKey('profile-avatar-camera'),
            leading: const OurneyIcon(name: 'camera', flat: true),
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
    final initial = ref.read(myProfileProvider).asData?.value;
    final profileChanged =
        initial == null ||
        initial.username != username ||
        initial.displayName != displayName;

    setState(() => _saving = true);
    try {
      if (profileChanged) {
        await repo.upsertMe(username: username, displayName: displayName);
        // The profile row exists now: push the quiz answers a new account
        // could not save before (best effort, never throws).
        unawaited(ref.read(onboardingQuizProvider.notifier).syncToServer());
      }
    } on OurneyException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        switch (e.error) {
          case OurneyErrorCode.invalid:
            _availability[username] = false;
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
    // P1: if the initial watchMe() failed or timed out before subscribing to
    // local Drift updates, refresh myProfileProvider + profileGateStatusProvider
    // and flush any deferred initial clickwrap consent before navigating away.
    var refreshedProfile = ref.read(myProfileProvider).asData?.value;
    if (ref.read(profileGateStatusProvider) != ProfileGateStatus.ready ||
        refreshedProfile == null) {
      ref.invalidate(myProfileProvider);
      try {
        refreshedProfile = await ref
            .read(myProfileProvider.future)
            .timeout(const Duration(seconds: 2));
      } on Object {
        // Best effort if a custom test stream stays silent on re-subscribe.
      }
      if (ref.read(profileGateStatusProvider) != ProfileGateStatus.ready) {
        ref.read(profileGateStatusProvider.notifier).markReady();
      }
    }
    await ref
        .read(eulaAcceptedProvider.notifier)
        .flushDeferredClickwrap(profile: refreshedProfile);
    if (!mounted) return;
    setState(() => _saving = false);
    OurneyHaptics.success();
    final rawFrom = widget.from;
    final target = rawFrom == null
        ? null
        : safeFrom(
            Uri(
              path: AppRoutes.profile,
              queryParameters: {AppRoutes.fromParam: rawFrom},
            ),
          );
    context.go(target ?? AppRoutes.capture);
  }

  static bool _isOffline(Object? error) =>
      error is OurneyException && error.error == OurneyErrorCode.offline;

  void _retry() {
    final profileState = ref.read(myProfileProvider);
    if (profileState.hasError || profileState.isLoading) {
      ref.invalidate(myProfileProvider);
    }
    if (_error != null) {
      if (_error == _FormError.avatar && _picked == null) {
        setState(() => _error = null);
        unawaited(_pickAvatar());
        return;
      }
      unawaited(_save());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ProfileL10n.of(context);
    final ui = context.ui;
    final profileState = ref.watch(myProfileProvider);
    final gateTimedOut =
        profileState.isLoading &&
        ref.watch(profileGateStatusProvider) == ProfileGateStatus.needsSetup;
    final loadError = switch (profileState) {
      AsyncError(:final error) => error,
      _ when gateTimedOut => const OurneyException(OurneyErrorCode.offline),
      _ => null,
    };
    final hasAvatar = _picked != null;
    final usernameError = _usernameError(l10n);
    final usernameFormatOk =
        _username.text.isNotEmpty &&
        validateUsername(_username.text) == null &&
        usernameError == null;
    final usernameAvailable =
        usernameFormatOk && _availability[_username.text] == true;
    final usernameOk =
        usernameFormatOk && _availability[_username.text] != false;
    final errorText = switch (_error) {
      _FormError.save => l10n.profile_saveError,
      _FormError.offline => l10n.profile_offlineError,
      _FormError.avatar => l10n.profile_avatarError,
      null => null,
    };

    return UiScaffold(
      key: const ValueKey('profile-setup-screen'),
      padTop: 64,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.profile_setupTitle,
                style: UiText.heading(
                  font: UiFonts.spaceGrotesk,
                  size: 32,
                  weight: 700,
                  height: 1.25,
                  tracking: -0.045,
                  color: ui.ink,
                ),
              ),
            ),
            if (loadError != null) ...[
              const SizedBox(height: UiSpace.md),
              Column(
                key: const ValueKey('profile-load-error'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isOffline(loadError))
                    UiBanner(
                      key: const ValueKey('profile-offline-banner'),
                      message: l10n.profile_offlineError,
                    )
                  else
                    UiInlineError(message: l10n.profile_loadError),
                  const SizedBox(height: UiSpace.sm),
                  UiButton.secondary(
                    key: const ValueKey('profile-retry'),
                    label: AppLocalizations.of(context).common_retry,
                    glyph: const OurneyIcon(name: 'refresh', flat: true),
                    onPressed: _saving ? null : _retry,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 26),
            // `.profile-avatar-large`; tapping it picks a photo (kept from
            // the data layer: the avatar can be a real picture).
            Center(
              child: UiPressable(
                key: const ValueKey('profile-avatar-pick'),
                onPressed: _saving ? null : _pickAvatar,
                semanticLabel: hasAvatar
                    ? l10n.profile_avatarChange
                    : l10n.profile_avatarAdd,
                excludeChildSemantics: true,
                borderRadius: BorderRadius.circular(UiRadius.card),
                minSize: const Size.square(ProfileFaceAvatar.size),
                // U11: no color swatches here any more (the choice was
                // never saved). A camera badge, as on UiAvatarPicker, says
                // the face is where a photo goes.
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ProfileFaceAvatar(
                      color: profileAvatarColor,
                      image: _picked == null ? null : MemoryImage(_picked!),
                    ),
                    Positioned(
                      right: -6,
                      bottom: -2,
                      child: Container(
                        key: const ValueKey('profile-avatar-camera-badge'),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: ui.ink,
                          shape: BoxShape.circle,
                        ),
                        child: OurneyIcon(
                          name: 'camera',
                          size: 16,
                          flat: true,
                          color: ui.bg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
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
            const SizedBox(height: 12),
            UiTextField(
              fieldKey: const ValueKey('profile-username'),
              label: l10n.profile_usernameLabel,
              controller: _username,
              enabled: !_saving,
              autocorrect: false,
              leading: Text(
                '@',
                style: UiText.body(
                  size: 16,
                  weight: FontWeight.w700,
                  color: ui.ink,
                ),
              ),
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newUsername],
              inputFormatters: [
                _LowerCaseFormatter(),
                LengthLimitingTextInputFormatter(usernameMax),
              ],
              helper: l10n.profile_usernameHelper,
              invalid: usernameError != null,
              onChanged: _onUsernameChanged,
              onSubmitted: (_) => _saving ? null : _save(),
            ),
            // `.username-status`: error or "Dùng được" (only once verified).
            if (usernameError != null)
              UiFlowError(
                key: const ValueKey('profile-username-status'),
                message: usernameError,
              )
            else if (usernameAvailable)
              UiFlowError(
                key: const ValueKey('profile-username-status'),
                message: l10n.profile_usernameAvailable,
                success: true,
              ),
            if (errorText != null) ...[
              UiFlowError(
                key: const ValueKey('profile-form-error'),
                message: errorText,
              ),
              if (loadError == null) ...[
                const SizedBox(height: UiSpace.sm),
                UiButton.secondary(
                  key: const ValueKey('profile-retry'),
                  label: AppLocalizations.of(context).common_retry,
                  glyph: const OurneyIcon(name: 'refresh', flat: true),
                  onPressed: _saving ? null : _retry,
                ),
              ],
            ],
            const SizedBox(height: 14),
            UiFlowButton(
              key: const ValueKey('profile-save'),
              label: _saving ? l10n.profile_saving : l10n.profile_continue,
              onPressed: _saving || !usernameOk ? null : _save,
            ),
            const SizedBox(height: UiSpace.sm),
            UiButton.ghost(
              key: const ValueKey('profile-setup-sign-out'),
              label: l10n.profile_signOut,
              onPressed: _saving ? null : () => confirmSignOut(context, ref),
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
