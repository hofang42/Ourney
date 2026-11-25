import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/auth/auth_providers.dart';
import 'package:ourney/features/profile/avatar_picker.dart';
import 'package:ourney/features/profile/profile_providers.dart';
import 'package:ourney/features/profile/routes.dart';
import 'package:ourney/features/profile/settings_screen.dart'
    show profileSettingsPath;
import 'package:ourney/features/safety/data/safety_providers.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import 'fakes.dart';

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

class _FailingProfileRepository extends FakeProfileRepository {
  @override
  Stream<Profile?> watchMe() =>
      Stream.error(const OurneyException(OurneyErrorCode.internal));
}

class _ControlledUsernameRepository extends FakeProfileRepository {
  _ControlledUsernameRepository(super.profile);

  final lookups = <String>[];
  final pending = <String, Completer<bool>>{};

  @override
  Future<bool> isUsernameAvailable(String username) {
    lookups.add(username);
    final result = pending[username] = Completer<bool>();
    return result.future;
  }
}

class _ReadyProfileGate extends ProfileGateNotifier {
  @override
  ProfileGateStatus build() => ProfileGateStatus.ready;
}

Future<void> tapVisible(WidgetTester tester, String key) async {
  final lists = find.descendant(
    of: find.byType(ListView),
    matching: find.byType(Scrollable),
  );
  if (byKey(key).evaluate().isEmpty && lists.evaluate().isNotEmpty) {
    await tester.scrollUntilVisible(byKey(key), 200, scrollable: lists.first);
  }
  await tester.ensureVisible(byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(byKey(key));
  await tester.pumpAndSettle();
}

Future<ProviderContainer> signedIn(
  WidgetTester tester, {
  FakeProfileRepository? profiles,
  RecordingAuthRepository? auth,
  FakeAvatarPicker? picker,
  String path = AppRoutes.profile,
}) async {
  final c = await pumpBackendApp(
    tester,
    auth: auth ?? RecordingAuthRepository(userId: 'u1'),
    profiles: profiles ?? FakeProfileRepository(aliceProfile),
    picker: picker,
  );
  await goTo(tester, c, path);
  return c;
}

void main() {
  for (final editing in [false, true]) {
    group(
      editing ? 'edit username availability' : 'setup username availability',
      () {
        final path = editing ? profileEditPath : profileSetupPath;
        final initial = editing ? aliceProfile : null;
        const debounce = Duration(milliseconds: 400);

        VoidCallback? saveAction(WidgetTester tester) => editing
            ? tester.widget<UiButton>(byKey('profile-save')).onPressed
            : tester.widget<UiFlowButton>(byKey('profile-save')).onPressed;

        testWidgets(
          'debounces, ignores stale results and rechecks on re-entry',
          (tester) async {
            final profiles = _ControlledUsernameRepository(initial);
            await signedIn(tester, profiles: profiles, path: path);
            final field = byKey('profile-username');
            if (editing) {
              expect(find.text('Dùng được'), findsOneWidget);
              expect(profiles.lookups, isEmpty);
            }

            await tester.enterText(field, 'first');
            await tester.pump(const Duration(milliseconds: 250));
            await tester.enterText(field, 'first.handle');
            await tester.pump(const Duration(milliseconds: 399));
            expect(profiles.lookups, isEmpty);
            await tester.pump(const Duration(milliseconds: 1));
            expect(profiles.lookups, ['first.handle']);
            expect(find.text('Dùng được'), findsNothing);

            const next = 'abcdefghijklmnopqrst';
            await tester.enterText(field, '${next}uvwxy');
            await tester.pump(debounce);
            expect(find.text(next), findsOneWidget);
            expect(profiles.lookups, ['first.handle', next]);
            profiles.pending[next]!.complete(false);
            await tester.pumpAndSettle();
            expect(find.text('Tên này không dùng được'), findsOneWidget);
            expect(saveAction(tester), isNull);

            profiles.pending['first.handle']!.complete(true);
            await tester.pumpAndSettle();
            expect(find.text('Tên này không dùng được'), findsOneWidget);
            expect(find.text('Dùng được'), findsNothing);

            // A handle can be released after the previous lookup.
            await tester.enterText(field, 'other');
            await tester.enterText(field, next);
            await tester.pump(debounce);
            expect(profiles.lookups, ['first.handle', next, next]);
            expect(find.text('Tên này không dùng được'), findsNothing);
            profiles.pending[next]!.complete(true);
            await tester.pumpAndSettle();
            expect(find.text('Dùng được'), findsOneWidget);
            expect(saveAction(tester), isNotNull);

            await tester.enterText(field, 'other');
            await tester.pump(debounce);
            profiles.pending['other']!.completeError(
              const OurneyException(OurneyErrorCode.offline),
            );
            await tester.pumpAndSettle();
            expect(find.text('Dùng được'), findsNothing);
            expect(find.text('Tên này không dùng được'), findsNothing);
            expect(saveAction(tester), isNotNull);
          },
        );

        testWidgets('in-flight availability cannot erase a write collision', (
          tester,
        ) async {
          final profiles = _ControlledUsernameRepository(initial)
            ..takenUsernames.add('race.handle');
          final c = await signedIn(tester, profiles: profiles, path: path);
          if (!editing) {
            await tester.enterText(byKey('profile-display-name'), 'New name');
          }
          await tester.enterText(byKey('profile-username'), 'race.handle');
          await tester.pump(debounce);
          expect(profiles.lookups, ['race.handle']);
          expect(saveAction(tester), isNotNull);

          await tapVisible(tester, 'profile-save');
          expect(profiles.calls, hasLength(1));
          expect(find.text('Tên này đã có người dùng'), findsOneWidget);
          expect(saveAction(tester), isNull);

          profiles.pending['race.handle']!.complete(true);
          await tester.pumpAndSettle();
          expect(find.text('Tên này đã có người dùng'), findsOneWidget);
          expect(find.text('Dùng được'), findsNothing);
          expect(saveAction(tester), isNull);
          expect(location(c), path);
        });

        testWidgets(
          'save distinguishes content policy from username collisions',
          (tester) async {
            final profiles = _ControlledUsernameRepository(initial)
              ..upsertError = const OurneyException(
                OurneyErrorCode.contentPolicy,
              );
            await signedIn(tester, profiles: profiles, path: path);
            if (!editing) {
              await tester.enterText(byKey('profile-display-name'), 'New name');
            }
            await tester.enterText(byKey('profile-username'), 'rejected');
            await tapVisible(tester, 'profile-save');
            expect(find.text('Tên này đã có người dùng'), findsNothing);
            if (editing) {
              expect(find.text('Tên này không dùng được'), findsOneWidget);
              expect(saveAction(tester), isNull);
            } else {
              expect(
                find.text('Hãy thử tên người dùng hoặc tên hiển thị khác.'),
                findsOneWidget,
              );
              expect(saveAction(tester), isNotNull);
            }
          },
        );
      },
    );
  }

  group('profile setup (FR-A2)', () {
    testWidgets('validates username locally (ourney_core rules)', (
      tester,
    ) async {
      final profiles = FakeProfileRepository();
      await signedIn(tester, profiles: profiles, path: profileSetupPath);
      expect(byKey('profile-setup-screen'), findsOneWidget);

      // Figma: "Xong" stays disabled until the username is usable.
      expect(
        tester.widget<UiFlowButton>(byKey('profile-save')).onPressed,
        isNull,
      );

      // Upper case is lowered as you type; "!" is rejected.
      await tester.enterText(byKey('profile-username'), 'Bob!');
      await tester.pumpAndSettle();
      expect(find.text('bob!'), findsOneWidget);
      expect(find.text('Chỉ dùng a–z, 0–9, _ .'), findsOneWidget);
      expect(
        tester.widget<UiFlowButton>(byKey('profile-save')).onPressed,
        isNull,
      );

      await tester.enterText(byKey('profile-username'), 'bo');
      await tester.pumpAndSettle();
      expect(find.text('Tối thiểu 3 ký tự.'), findsOneWidget);
      expect(profiles.calls, isEmpty);

      // A usable username enables the button; a blank name is still caught.
      await tester.enterText(byKey('profile-username'), 'bob');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Dùng được'), findsOneWidget);
      await tapVisible(tester, 'profile-save');
      await tester.pumpAndSettle();
      expect(find.text('Nhập tên hiển thị.'), findsOneWidget);
      expect(profiles.calls, isEmpty);

      // UX-09: input maxLength clamps typing at usernameMax (20 chars).
      await tester.enterText(
        byKey('profile-username'),
        'abcdefghijklmnopqrstuvwxy',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('abcdefghijklmnopqrst'), findsOneWidget);
      expect(find.text('abcdefghijklmnopqrstuvwxy'), findsNothing);
    });

    testWidgets(
      'UX-09: preflight rejection uses neutral copy and save reports a collision',
      (tester) async {
        final profiles = FakeProfileRepository()..takenUsernames.add('bob');
        final picker = FakeAvatarPicker(_png);
        final c = await signedIn(
          tester,
          profiles: profiles,
          picker: picker,
          path: '$profileSetupPath?from=%2Fjourneys',
        );

        // The availability check reports a rejection without giving a reason.
        await tester.enterText(byKey('profile-username'), 'bob');
        await tester.enterText(byKey('profile-display-name'), '  Bob Tran ');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        expect(find.text('Tên này không dùng được'), findsOneWidget);
        expect(find.text('Dùng được'), findsNothing);
        expect(
          tester.widget<UiFlowButton>(byKey('profile-save')).onPressed,
          isNull,
        );
        expect(profiles.calls, isEmpty);

        // The server write can still reject a username claimed after preflight.
        await tester.enterText(byKey('profile-username'), 'bob.race');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        expect(find.text('Dùng được'), findsOneWidget);
        profiles.takenUsernames.add('bob.race');
        await tapVisible(tester, 'profile-save');
        expect(profiles.calls, ['upsertMe:bob.race:Bob Tran']);
        expect(find.text('Tên này đã có người dùng'), findsOneWidget);
        expect(find.text('Dùng được'), findsNothing);
        expect(location(c), startsWith(profileSetupPath));

        await tapVisible(tester, 'profile-avatar-pick');
        await tester.tap(byKey('profile-avatar-gallery'));
        await tester.pumpAndSettle();
        expect(picker.lastSource, AvatarSource.gallery);

        await tester.enterText(byKey('profile-username'), 'bob.tran');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        expect(find.text('Dùng được'), findsOneWidget);
        await tapVisible(tester, 'profile-save');
        expect(profiles.calls, [
          'upsertMe:bob.race:Bob Tran',
          'upsertMe:bob.tran:Bob Tran',
          'setAvatar:${_png.length}',
        ]);
        expect(profiles.avatarBytes, _png);
        expect(location(c), AppRoutes.journeys);
      },
    );

    testWidgets(
      'DE-07: offline save keeps the form with an error and retry recovers',
      (tester) async {
        final profiles = FakeProfileRepository()
          ..upsertError = const OurneyException(OurneyErrorCode.offline);
        final c = await signedIn(
          tester,
          profiles: profiles,
          path: '$profileSetupPath?from=%2Fjourneys',
        );
        await tester.enterText(byKey('profile-username'), 'bob');
        await tester.enterText(byKey('profile-display-name'), 'Bob');
        await tapVisible(tester, 'profile-save');
        expect(byKey('profile-form-error'), findsOneWidget);
        expect(byKey('profile-retry'), findsOneWidget);
        expect(byKey('profile-setup-screen'), findsOneWidget);

        // Reconnect and tap retry.
        profiles.upsertError = null;
        await tapVisible(tester, 'profile-retry');
        expect(profiles.calls, [
          'upsertMe:bob:Bob',
          'upsertMe:bob:Bob',
        ]);
        expect(location(c), AppRoutes.journeys);
      },
    );

    testWidgets(
      'DE-07: profile setup offers sign out to escape when offline or on wrong '
      'account',
      (tester) async {
        final auth = RecordingAuthRepository(userId: 'u1');
        final profiles = FakeProfileRepository()
          ..upsertError = const OurneyException(OurneyErrorCode.offline);
        final c = await signedIn(
          tester,
          auth: auth,
          profiles: profiles,
          path: '$profileSetupPath?from=%2Fjourneys',
        );
        expect(byKey('profile-setup-screen'), findsOneWidget);
        await tapVisible(tester, 'profile-setup-sign-out');
        expect(byKey('profile-signout-dialog'), findsOneWidget);

        await tester.tap(byKey('profile-signout-confirm'));
        await tester.pumpAndSettle();
        expect(auth.calls, ['signOut']);
        expect(location(c), '${AppRoutes.auth}?from=%2Fjourneys');
      },
    );
    testWidgets(
      'DE-07: profile setup shows load/offline error with retry and sign out',
      (tester) async {
        await signedIn(
          tester,
          profiles: _FailingProfileRepository(),
          path: profileSetupPath,
        );
        expect(byKey('profile-setup-screen'), findsOneWidget);
        expect(byKey('profile-load-error'), findsOneWidget);
        expect(byKey('profile-retry'), findsOneWidget);
        expect(byKey('profile-setup-sign-out'), findsOneWidget);
      },
    );

    testWidgets(
      'DE-04 / H1: cold restart while signed in without a profile redirects '
      'to /profile/setup',
      (tester) async {
        final c = await pumpBackendApp(
          tester,
          auth: RecordingAuthRepository(userId: 'u1'),
          profiles: FakeProfileRepository(),
        );
        expect(location(c), profileSetupPath);
        expect(byKey('profile-setup-screen'), findsOneWidget);
      },
    );
  });

  group('profile screen', () {
    testWidgets('shows the profile and edits it', (tester) async {
      final profiles = FakeProfileRepository(aliceProfile);
      final c = await signedIn(tester, profiles: profiles);
      expect(byKey('profile-card'), findsOneWidget);
      expect(find.text('Alice Nguyen'), findsOneWidget);
      expect(find.text('@alice'), findsOneWidget);

      await tapVisible(tester, 'profile-edit');
      expect(location(c), profileEditPath);
      expect(find.text('alice'), findsOneWidget);

      // Nothing changed: no server call.
      await tapVisible(tester, 'profile-save');
      expect(profiles.calls, isEmpty);
      expect(location(c), AppRoutes.profile);

      await tapVisible(tester, 'profile-edit');
      await tester.enterText(byKey('profile-display-name'), 'Alice N.');
      await tapVisible(tester, 'profile-save');
      expect(profiles.calls, ['upsertMe:alice:Alice N.']);
      expect(location(c), AppRoutes.profile);
      expect(find.text('Alice N.'), findsOneWidget);
    });

    testWidgets('the gear opens settings', (tester) async {
      final c = await signedIn(tester);
      await tapVisible(tester, 'profile-settings');
      expect(location(c), profileSettingsPath);
    });

    testWidgets('missing profile offers setup', (tester) async {
      final c = await pumpOurneyApp(
        tester,
        config: testBackendConfig,
        auth: RecordingAuthRepository(userId: 'u1'),
        overrides: <Override>[
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          profileGateStatusProvider.overrideWith(_ReadyProfileGate.new),
          mediaStoreProvider.overrideWithValue(FakeMediaStore()),
          avatarPickerProvider.overrideWithValue(FakeAvatarPicker()),
        ],
      );
      await goTo(tester, c, AppRoutes.profile);
      expect(byKey('profile-incomplete'), findsOneWidget);
      await tapVisible(tester, 'profile-complete');
      expect(location(c), profileSetupPath);
    });

    testWidgets('load error offers retry', (tester) async {
      final c = await pumpOurneyApp(
        tester,
        config: testBackendConfig,
        auth: RecordingAuthRepository(userId: 'u1'),
        overrides: <Override>[
          profileRepositoryProvider.overrideWithValue(
            _FailingProfileRepository(),
          ),
          profileGateStatusProvider.overrideWith(_ReadyProfileGate.new),
          mediaStoreProvider.overrideWithValue(FakeMediaStore()),
          avatarPickerProvider.overrideWithValue(FakeAvatarPicker()),
        ],
      );
      await goTo(tester, c, AppRoutes.profile);
      expect(byKey('profile-load-error'), findsOneWidget);
      expect(byKey('profile-retry'), findsOneWidget);
    });

    testWidgets('dock root shows a title bar, not a back button (U9)', (
      tester,
    ) async {
      await signedIn(tester);
      expect(byKey('profile-top-bar'), findsOneWidget);
      expect(find.byType(UiBackHeader), findsNothing);
    });

    testWidgets('U18: Profile does not repeat Settings rows (sign out, '
        'reminders); Settings owns them', (tester) async {
      await signedIn(tester);
      expect(byKey('profile-settings'), findsOneWidget);
      for (final key in [
        'profile-signout',
        'profile-reminders',
        'profile-haptics',
        'profile-language',
        'profile-safety',
        'profile-delete',
      ]) {
        expect(byKey(key), findsNothing, reason: key);
      }
    });

    testWidgets('local-only: guest state, no account actions (FR-A5)', (
      tester,
    ) async {
      final c = await pumpOurneyApp(tester);
      await goTo(tester, c, AppRoutes.profile);
      expect(byKey('profile-guest'), findsOneWidget);
      expect(byKey('profile-signout'), findsNothing);
      expect(byKey('profile-delete'), findsNothing);
      expect(byKey('profile-settings'), findsOneWidget);

      await goTo(tester, c, profileEditPath);
      expect(byKey('profile-guest'), findsOneWidget);
      expect(byKey('profile-edit-screen'), findsNothing);
    });

    testWidgets('no overflow at 2x text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = await signedIn(tester);
      expect(tester.takeException(), isNull);
      await goTo(tester, c, profileEditPath);
      expect(tester.takeException(), isNull);
      await goTo(tester, c, profileSetupPath);
      expect(tester.takeException(), isNull);
    });
  });

  group('delete account (FR-A4, 3 steps: confirm, code, final)', () {
    Future<void> toCodeStep(WidgetTester tester) async {
      await tapVisible(tester, 'profile-settings');
      await tapVisible(tester, 'settings-delete');
      expect(byKey('profile-delete-dialog'), findsOneWidget);
      UiButton next() =>
          tester.widget<UiButton>(byKey('profile-delete-continue'));
      expect(next().onPressed, isNull);
      await tapVisible(tester, 'profile-delete-understand');
      await tester.pump();
      expect(next().onPressed, isNotNull);
      await tapVisible(tester, 'profile-delete-continue');
      await tester.pumpAndSettle();
      expect(byKey('profile-delete-otp'), findsOneWidget);
    }

    testWidgets('needs the code; wrong code retries; then resets', (
      tester,
    ) async {
      final auth = RecordingAuthRepository(userId: 'u1')
        ..deleteError = const OurneyException(OurneyErrorCode.invalid);
      final c = await signedIn(tester, auth: auth);
      await c
          .read(sharedPreferencesProvider)
          .setString(
            AuthMethodPrefs.lastMethodKey,
            RememberedAuthMethod.password.wireName,
          );
      await toCodeStep(tester);
      expect(auth.calls, ['requestDeleteCode']);

      UiButton confirm() =>
          tester.widget<UiButton>(byKey('profile-delete-confirm'));
      expect(confirm().onPressed, isNull);
      await tester.enterText(byKey('profile-delete-otp'), '123456');
      await tester.pump();
      expect(confirm().onPressed, isNotNull);
      await tapVisible(tester, 'profile-delete-confirm');
      await tester.pumpAndSettle();
      expect(auth.calls.last, 'deleteAccount:123456');
      // Wrong code: back on the code step with an error, nothing reset.
      expect(find.text('Mã chưa đúng. Kiểm tra lại nhé.'), findsOneWidget);
      expect(c.read(onboardingCompleteProvider), isTrue);
      expect(
        c
            .read(sharedPreferencesProvider)
            .getString(AuthMethodPrefs.lastMethodKey),
        RememberedAuthMethod.password.wireName,
      );

      auth.deleteError = null;
      await tester.enterText(byKey('profile-delete-otp'), '654321');
      await tester.pump();
      await tapVisible(tester, 'profile-delete-confirm');
      await tester.pumpAndSettle();
      expect(auth.calls.last, 'deleteAccount:654321');
      expect(c.read(onboardingCompleteProvider), isFalse);
      expect(c.read(eulaAcceptedProvider), isFalse);
      expect(
        c
            .read(sharedPreferencesProvider)
            .getString(AuthMethodPrefs.lastMethodKey),
        isNull,
      );
    });

    testWidgets('retryable server error shows the final step error', (
      tester,
    ) async {
      final auth = RecordingAuthRepository(userId: 'u1')
        ..deleteError = const OurneyException(
          OurneyErrorCode.storageCleanupIncomplete,
        );
      final c = await signedIn(tester, auth: auth);
      await toCodeStep(tester);
      await tester.enterText(byKey('profile-delete-otp'), '123456');
      await tester.pump();
      await tapVisible(tester, 'profile-delete-confirm');
      await tester.pumpAndSettle();
      expect(
        find.text('Chưa xóa xong. Thử lại để xóa nốt phần còn lại nhé.'),
        findsOneWidget,
      );
      expect(byKey('profile-delete-retry'), findsOneWidget);
      expect(c.read(onboardingCompleteProvider), isTrue);
    });

    testWidgets('cancel does nothing', (tester) async {
      final auth = RecordingAuthRepository(userId: 'u1');
      await signedIn(tester, auth: auth);
      await tapVisible(tester, 'profile-settings');
      await tapVisible(tester, 'settings-delete');
      await tapVisible(tester, 'profile-delete-cancel');
      await tester.pumpAndSettle();
      expect(byKey('profile-delete-dialog'), findsNothing);
      expect(auth.calls, isEmpty);
    });

    testWidgets('code request failure stays on step 1', (tester) async {
      final auth = RecordingAuthRepository(userId: 'u1')
        ..requestDeleteCodeError = const OurneyException(
          OurneyErrorCode.unauthenticated,
        );
      await signedIn(tester, auth: auth);
      await tapVisible(tester, 'profile-settings');
      await tapVisible(tester, 'settings-delete');
      await tapVisible(tester, 'profile-delete-understand');
      await tester.pump();
      await tapVisible(tester, 'profile-delete-continue');
      await tester.pumpAndSettle();
      expect(
        find.text('Phiên đăng nhập đã hết hạn. Đăng nhập lại rồi xóa nhé.'),
        findsOneWidget,
      );
      expect(byKey('profile-delete-otp'), findsNothing);
    });
  });

  group('profile stats and badges', () {
    testWidgets('shows the stat cards and a badge rule on tap (UX-43)', (
      tester,
    ) async {
      await signedIn(tester);
      expect(byKey('profile-stats'), findsOneWidget);
      expect(byKey('profile-stat-snaps'), findsOneWidget);
      expect(find.text('tổng lần check-in'), findsOneWidget);
      expect(find.text('tổng ngày check-in'), findsNothing);
      await tapVisible(tester, 'profile-badge-streak7');
      expect(find.text('Có mặt đủ 7 ngày liên tiếp.'), findsOneWidget);
    });
  });
}
