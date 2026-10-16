import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/features/safety/data/safety_providers.dart';
import 'package:ourney/features/safety/safety_paths.dart';
import 'package:ourney/features/safety/ui/block_dialogs.dart';
import 'package:ourney/features/safety/ui/report_form.dart';
import 'package:ourney_core/ourney_core.dart';

import 'safety_fakes.dart';

void main() {
  group('report sheet (FR-F1)', () {
    late FakeSafetyRepository repo;
    bool? result;

    Widget opener(BuildContext context) => TextButton(
      onPressed: () async {
        result = await showReportSheet(
          context,
          checkInId: 'c1',
          userId: 'u2',
          name: 'Lan',
        );
      },
      child: const Text('open'),
    );

    setUp(() {
      repo = FakeSafetyRepository();
      result = null;
    });

    testWidgets('pick a reason, add a note, send: hidden at once', (
      tester,
    ) async {
      final c = await pumpSafetyHarness(tester, repo: repo, builder: opener);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Báo cáo check-in'), findsOneWidget);

      // Submit does nothing before a reason is chosen.
      await tester.tap(byKey('safety-report-submit'));
      await tester.pumpAndSettle();
      expect(repo.reports, isEmpty);

      await tester.tap(byKey('safety-reason-harassment'));
      await tester.pumpAndSettle();
      await tester.enterText(byKey('safety-report-note'), '  bị chửi  ');
      await tester.ensureVisible(byKey('safety-report-submit'));
      await tester.tap(byKey('safety-report-submit'));
      await tester.pumpAndSettle();

      expect(repo.reports, hasLength(1));
      final r = repo.reports.single;
      expect(r.checkInId, 'c1');
      expect(r.reason, ReportReason.harassment);
      expect(r.note, 'bị chửi');
      expect(c.read(hiddenCheckInIdsProvider), {'c1'});
      expect(byKey('safety-report-sent'), findsOneWidget);
      expect(byKey('safety-self-harm-support'), findsNothing);

      await tester.tap(byKey('safety-report-done'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('self-harm shows the support message, before and after', (
      tester,
    ) async {
      await pumpSafetyHarness(tester, repo: repo, builder: opener);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('safety-reason-self_harm'));
      await tester.pumpAndSettle();
      expect(byKey('safety-self-harm-support'), findsOneWidget);
      expect(find.text('Bạn không một mình'), findsOneWidget);
      // No phone numbers are invented.
      final body = tester
          .widgetList<Text>(
            find.descendant(
              of: byKey('safety-self-harm-support'),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data ?? '')
          .join(' ');
      expect(RegExp(r'\d{3,}').hasMatch(body), isFalse);

      await tester.ensureVisible(byKey('safety-report-submit'));
      await tester.tap(byKey('safety-report-submit'));
      await tester.pumpAndSettle();
      expect(repo.reports.single.reason, ReportReason.selfHarm);
      expect(repo.reports.single.note, isNull);
      expect(byKey('safety-self-harm-support'), findsOneWidget);
    });

    testWidgets('rate limit error is shown and nothing is hidden', (
      tester,
    ) async {
      repo.reportError = const OurneyException(OurneyErrorCode.rateLimited);
      final c = await pumpSafetyHarness(tester, repo: repo, builder: opener);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('safety-reason-spam'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(byKey('safety-report-submit'));
      await tester.tap(byKey('safety-report-submit'));
      await tester.pumpAndSettle();
      expect(byKey('safety-report-error'), findsOneWidget);
      expect(find.textContaining('24 giờ'), findsOneWidget);
      expect(c.read(hiddenCheckInIdsProvider), isEmpty);
      expect(byKey('safety-report-form'), findsOneWidget);
    });

    testWidgets('cancel returns false', (tester) async {
      await pumpSafetyHarness(tester, repo: repo, builder: opener);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(byKey('safety-report-cancel'));
      await tester.tap(byKey('safety-report-cancel'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(repo.reports, isEmpty);
    });

    testWidgets('after reporting, "also block" blocks the author', (
      tester,
    ) async {
      final c = await pumpSafetyHarness(tester, repo: repo, builder: opener);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('safety-reason-nudity'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(byKey('safety-report-submit'));
      await tester.tap(byKey('safety-report-submit'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('safety-report-also-block'));
      await tester.pumpAndSettle();
      expect(find.text('Chặn Lan?'), findsOneWidget);
      await tester.tap(byKey('safety-block-confirm'));
      await tester.pumpAndSettle();
      expect(repo.blocked, {'u2'});
      expect(c.read(blockedNamesProvider), {'u2': 'Lan'});
      expect(result, isTrue);
    });

    testWidgets('local-only mode explains that a server is needed', (
      tester,
    ) async {
      await pumpSafetyHarness(
        tester,
        repo: repo,
        config: const AppConfig.localOnly(),
        builder: opener,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(byKey('safety-report-needs-server'), findsOneWidget);
    });

    testWidgets('English strings', (tester) async {
      await pumpSafetyHarness(
        tester,
        repo: repo,
        locale: const Locale('en'),
        builder: opener,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Report check-in'), findsOneWidget);
      expect(find.text('Self-harm'), findsOneWidget);
    });
  });

  group('confirmBlock (FR-F2)', () {
    Widget opener(BuildContext context) => TextButton(
      onPressed: () => confirmBlock(context, userId: 'u9', name: 'Minh'),
      child: const Text('block'),
    );

    testWidgets('cancel does nothing', (tester) async {
      final repo = FakeSafetyRepository();
      await pumpSafetyHarness(tester, repo: repo, builder: opener);
      await tester.tap(find.text('block'));
      await tester.pumpAndSettle();
      expect(byKey('safety-block-dialog'), findsOneWidget);
      await tester.tap(byKey('safety-block-cancel'));
      await tester.pumpAndSettle();
      expect(repo.blocked, isEmpty);
    });

    testWidgets('confirm blocks, remembers the name, shows a snack bar', (
      tester,
    ) async {
      final repo = FakeSafetyRepository();
      final c = await pumpSafetyHarness(tester, repo: repo, builder: opener);
      await tester.tap(find.text('block'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('safety-block-confirm'));
      await tester.pumpAndSettle();
      expect(repo.blocked, {'u9'});
      expect(c.read(blockedNamesProvider)['u9'], 'Minh');
      expect(find.text('Đã chặn Minh.'), findsOneWidget);
    });

    testWidgets('server error is reported', (tester) async {
      final repo = FakeSafetyRepository()
        ..blockError = const OurneyException(OurneyErrorCode.invalid);
      await pumpSafetyHarness(tester, repo: repo, builder: opener);
      await tester.tap(find.text('block'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('safety-block-confirm'));
      await tester.pumpAndSettle();
      expect(find.text('Không thể thực hiện với chính bạn.'), findsOneWidget);
    });
  });

  group('routes', () {
    testWidgets('report a user by route', (tester) async {
      final repo = FakeSafetyRepository();
      final c = await pumpSignedInApp(tester, repo: repo);
      await goTo(tester, c, SafetyPaths.reportUser('u2', name: 'Lan'));
      expect(byKey('safety-report-screen'), findsOneWidget);
      expect(find.text('Báo cáo người dùng'), findsOneWidget);
      await tester.tap(byKey('safety-reason-other'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(byKey('safety-report-submit'));
      await tester.tap(byKey('safety-report-submit'));
      await tester.pumpAndSettle();
      expect(repo.reports.single.userId, 'u2');
      expect(repo.reports.single.checkInId, isNull);
    });

    testWidgets('report a check-in by route', (tester) async {
      final repo = FakeSafetyRepository();
      final c = await pumpSignedInApp(tester, repo: repo);
      await goTo(tester, c, SafetyPaths.reportCheckIn('c 1', userId: 'u2'));
      await tester.tap(byKey('safety-reason-spam'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(byKey('safety-report-submit'));
      await tester.tap(byKey('safety-report-submit'));
      await tester.pumpAndSettle();
      expect(repo.reports.single.checkInId, 'c 1');
      expect(c.read(hiddenCheckInIdsProvider), {'c 1'});
      expect(byKey('safety-report-also-block'), findsOneWidget);
    });

    testWidgets('block page blocks and leaves', (tester) async {
      final repo = FakeSafetyRepository();
      final c = await pumpSignedInApp(tester, repo: repo);
      await goTo(tester, c, SafetyPaths.block('u3', name: 'Hà'));
      expect(find.text('Chặn Hà?'), findsOneWidget);
      await tester.tap(byKey('safety-block-page-confirm'));
      await tester.pumpAndSettle();
      expect(repo.blocked, {'u3'});
      expect(byKey('safety-block-screen'), findsNothing);
    });

    testWidgets('blocked list shows names and unblocks', (tester) async {
      final repo = FakeSafetyRepository(blocked: {'u2', 'u7'});
      final c = await pumpSignedInApp(tester, repo: repo);
      await c.read(blockedNamesProvider.notifier).remember('u2', 'Lan');
      await goTo(tester, c, SafetyPaths.blocked);
      expect(find.text('Lan'), findsOneWidget);
      expect(find.text('Người dùng'), findsOneWidget); // name unknown

      await tester.tap(byKey('safety-unblock-u2'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ chặn Lan?'), findsOneWidget);
      await tester.tap(byKey('safety-unblock-confirm'));
      await tester.pumpAndSettle();
      expect(repo.blocked, {'u7'});
      expect(byKey('safety-blocked-u2'), findsNothing);
      expect(c.read(blockedNamesProvider), isEmpty);
    });

    testWidgets('empty blocked list', (tester) async {
      final c = await pumpSignedInApp(tester);
      await goTo(tester, c, SafetyPaths.blocked);
      expect(byKey('safety-blocked-empty'), findsOneWidget);
    });
  });

  test('SafetyPaths encode ids and optional query', () {
    expect(SafetyPaths.reportCheckIn('a/b'), '/safety/report/checkin/a%2Fb');
    expect(
      SafetyPaths.reportCheckIn('c', userId: 'u', name: 'Lan Anh'),
      '/safety/report/checkin/c?userId=u&name=Lan+Anh',
    );
    expect(SafetyPaths.reportUser('u'), '/safety/report/user/u');
    expect(SafetyPaths.block('u', name: ''), '/safety/block/u');
    expect(SafetyPaths.blocked, '/safety/blocked');
    expect(SafetyPaths.eulaAccept, '/safety/eula/accept');
  });

  test('safetyFailureOf maps server codes', () {
    expect(
      safetyFailureOf(const OurneyException(OurneyErrorCode.notFound)),
      SafetyFailure.notFound,
    );
    expect(
      safetyFailureOf(const OurneyException(OurneyErrorCode.offline)),
      SafetyFailure.offline,
    );
    expect(safetyFailureOf(StateError('x')), SafetyFailure.generic);
  });
}
