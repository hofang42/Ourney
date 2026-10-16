import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/profile/avatar_picker.dart';
import 'package:ourney/features/profile/routes.dart';
import 'package:ourney/features/safety/data/safety_providers.dart';
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
  group('profile setup (FR-A2)', () {
    testWidgets('validates username locally (ourney_core rules)', (
      tester,
    ) async {
      final profiles = FakeProfileRepository();
      await signedIn(tester, profiles: profiles, path: profileSetupPath);
      expect(byKey('profile-setup-screen'), findsOneWidget);

      await tester.tap(byKey('profile-save'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập tên hiển thị.'), findsOneWidget);
      expect(find.text('Tối thiểu 3 ký tự.'), findsOneWidget);
      expect(profiles.calls, isEmpty);

      // Upper case is lowered as you type; "!" is rejected.
      await tester.enterText(byKey('profile-username'), 'Bob!');
      await tester.enterText(byKey('profile-display-name'), 'Bob');
      await tester.tap(byKey('profile-save'));
      await tester.pumpAndSettle();
      expect(find.text('bob!'), findsOneWidget);
      expect(
        find.text('Chỉ dùng chữ thường a–z, số, dấu _ và dấu chấm.'),
        findsOneWidget,
      );
      expect(profiles.calls, isEmpty);

      await tester.enterText(byKey('profile-username'), 'bo');
      await tester.pumpAndSettle();
      expect(find.text('Tối thiểu 3 ký tự.'), findsOneWidget);
      expect(profiles.calls, isEmpty);
    });

    testWidgets('taken username, then success with avatar -> from target', (
      tester,
    ) async {
      final profiles = FakeProfileRepository()..takenUsernames.add('bob');
      final picker = FakeAvatarPicker(_png);
      final c = await signedIn(
        tester,
        profiles: profiles,
        picker: picker,
        path: '$profileSetupPath?from=%2Fjourneys',
      );

      await tester.enterText(byKey('profile-username'), 'bob');
      await tester.enterText(byKey('profile-display-name'), '  Bob Tran ');
      await tapVisible(tester, 'profile-save');
      expect(profiles.calls, ['upsertMe:bob:Bob Tran']);
      expect(
        find.text('Tên này đã có người dùng. Chọn tên khác nhé.'),
        findsOneWidget,
      );
      expect(location(c), startsWith(profileSetupPath));

      await tapVisible(tester, 'profile-avatar-pick');
      await tester.tap(byKey('profile-avatar-gallery'));
      await tester.pumpAndSettle();
      expect(picker.lastSource, AvatarSource.gallery);

      await tester.enterText(byKey('profile-username'), 'bob.tran');
      await tapVisible(tester, 'profile-save');
      expect(profiles.calls, [
        'upsertMe:bob:Bob Tran',
        'upsertMe:bob.tran:Bob Tran',
        'setAvatar:${_png.length}',
      ]);
      expect(profiles.avatarBytes, _png);
      expect(location(c), AppRoutes.journeys);
    });

    testWidgets('offline save keeps the form with an error', (tester) async {
      final profiles = FakeProfileRepository()
        ..upsertError = const OurneyException(OurneyErrorCode.offline);
      await signedIn(tester, profiles: profiles, path: profileSetupPath);
      await tester.enterText(byKey('profile-username'), 'bob');
      await tester.enterText(byKey('profile-display-name'), 'Bob');
      await tapVisible(tester, 'profile-save');
      expect(byKey('profile-form-error'), findsOneWidget);
      expect(byKey('profile-setup-screen'), findsOneWidget);
    });
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

    testWidgets('links to reminders and safety', (tester) async {
      final c = await signedIn(tester);
      await tapVisible(tester, 'profile-reminders');
      expect(location(c), AppRoutes.reminders);
      await goTo(tester, c, AppRoutes.profile);
      await tapVisible(tester, 'profile-safety');
      expect(location(c), AppRoutes.safety);
    });

    testWidgets('missing profile offers setup', (tester) async {
      final c = await signedIn(tester, profiles: FakeProfileRepository());
      expect(byKey('profile-incomplete'), findsOneWidget);
      await tapVisible(tester, 'profile-complete');
      expect(location(c), profileSetupPath);
    });

    testWidgets('load error offers retry', (tester) async {
      await signedIn(tester, profiles: _FailingProfileRepository());
      expect(byKey('profile-load-error'), findsOneWidget);
      expect(byKey('profile-retry'), findsOneWidget);
    });

    testWidgets('sign out asks, then the router goes to /auth', (tester) async {
      final auth = RecordingAuthRepository(userId: 'u1');
      final c = await signedIn(tester, auth: auth);
      await tapVisible(tester, 'profile-signout');
      expect(byKey('profile-signout-dialog'), findsOneWidget);
      await tester.tap(byKey('profile-signout-confirm'));
      await tester.pumpAndSettle();
      expect(auth.calls, ['signOut']);
      expect(location(c), startsWith(AppRoutes.auth));
    });

    testWidgets('local-only: guest state, no account actions (FR-A5)', (
      tester,
    ) async {
      final c = await pumpOurneyApp(tester);
      await goTo(tester, c, AppRoutes.profile);
      expect(byKey('profile-guest'), findsOneWidget);
      expect(byKey('profile-signout'), findsNothing);
      expect(byKey('profile-delete'), findsNothing);
      expect(byKey('profile-reminders'), findsOneWidget);

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

  group('delete account (FR-A4)', () {
    testWidgets('needs the username typed; retryable error; then resets', (
      tester,
    ) async {
      final auth = RecordingAuthRepository(userId: 'u1')
        ..deleteError = const OurneyException(
          OurneyErrorCode.storageCleanupIncomplete,
        );
      final c = await signedIn(tester, auth: auth);
      await tapVisible(tester, 'profile-delete');
      expect(byKey('profile-delete-dialog'), findsOneWidget);
      expect(find.text('Gõ alice để xác nhận'), findsOneWidget);

      FilledButton confirm() =>
          tester.widget<FilledButton>(byKey('profile-delete-confirm'));
      expect(confirm().onPressed, isNull);
      await tester.enterText(byKey('profile-delete-confirm-field'), 'Alice');
      await tester.pump();
      expect(confirm().onPressed, isNull);
      await tester.enterText(byKey('profile-delete-confirm-field'), 'alice');
      await tester.pump();
      expect(confirm().onPressed, isNotNull);

      await tester.tap(byKey('profile-delete-confirm'));
      await tester.pumpAndSettle();
      expect(auth.calls, ['deleteAccount']);
      expect(
        find.text('Chưa xoá xong. Thử lại để xoá nốt phần còn lại nhé.'),
        findsOneWidget,
      );
      expect(c.read(onboardingCompleteProvider), isTrue);

      auth.deleteError = null;
      await tester.tap(byKey('profile-delete-confirm'));
      await tester.pumpAndSettle();
      expect(auth.calls, ['deleteAccount', 'deleteAccount']);
      expect(c.read(onboardingCompleteProvider), isFalse);
      expect(c.read(eulaAcceptedProvider), isFalse);
      expect(byKey('profile-delete-dialog'), findsNothing);
      expect(location(c), startsWith(AppRoutes.onboarding));
    });

    testWidgets('cancel does nothing', (tester) async {
      final auth = RecordingAuthRepository(userId: 'u1');
      await signedIn(tester, auth: auth);
      await tapVisible(tester, 'profile-delete');
      await tester.tap(byKey('profile-delete-cancel'));
      await tester.pumpAndSettle();
      expect(byKey('profile-delete-dialog'), findsNothing);
      expect(auth.calls, isEmpty);
    });

    testWidgets('expired session asks to sign in again', (tester) async {
      final auth = RecordingAuthRepository(userId: 'u1')
        ..deleteError = const OurneyException(OurneyErrorCode.unauthenticated);
      await signedIn(tester, auth: auth);
      await tapVisible(tester, 'profile-delete');
      await tester.enterText(byKey('profile-delete-confirm-field'), 'alice');
      await tester.pump();
      await tester.tap(byKey('profile-delete-confirm'));
      await tester.pumpAndSettle();
      expect(
        find.text('Phiên đăng nhập đã hết hạn. Đăng nhập lại rồi xoá nhé.'),
        findsOneWidget,
      );
    });
  });
}
