import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/theme/app_theme.dart';
import 'package:ourney/features/sharing/sharing.dart';
import 'package:ourney/features/sharing/ui/insights_screen.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import '../safety/safety_fakes.dart' show FakeSafetyRepository;
import 'sharing_fakes.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

String _submitLabel(WidgetTester tester) =>
    tester.widget<UiButton>(_key('share-submit')).label;

bool _submitEnabled(WidgetTester tester) =>
    tester.widget<UiButton>(_key('share-submit')).onPressed != null;

FakeJourneyRepository _journeys({
  TemplateId template = TemplateId.travel,
  JourneyStatus status = JourneyStatus.ended,
  JourneyKind kind = JourneyKind.solo,
}) => FakeJourneyRepository(
  journeys: [testJourney(templateId: template, status: status, kind: kind)],
);

final _friends = [
  person('f1', 'Nam Tran'),
  person('f2', 'Lan Do'),
  person('f3', 'Bao Le'),
];

void main() {
  group('Share this journey (SCR-82)', () {
    testWidgets('S7: new friends ticked by default, shared ones removable', (
      tester,
    ) async {
      final sharing = FakeSharingRepository(viewers: [_friends.first]);
      await pumpSharing(
        tester,
        location: '/sharing/j1',
        sharing: sharing,
        journeys: _journeys(),
        friends: _friends,
      );
      expect(_submitLabel(tester), 'Share with 2 friends');
      expect(_key('share-remove-f1'), findsOneWidget);
      expect(find.text('Can see'), findsOneWidget);

      await _tap(tester, _key('share-submit'));
      expect(sharing.calls, contains('share:f2,f3'));
      expect(_submitLabel(tester), 'Pick friends to share');

      await _tap(tester, _key('share-remove-f1'));
      expect(sharing.calls, contains('unshare:f1:false'));
    });

    testWidgets('S7: weight loss ticks nobody; button disabled until a pick', (
      tester,
    ) async {
      await pumpSharing(
        tester,
        location: '/sharing/j1',
        journeys: _journeys(template: TemplateId.weightLoss),
        friends: _friends,
      );
      expect(_submitLabel(tester), 'Pick friends to share');
      expect(_submitEnabled(tester), isFalse);
      expect(
        find.text('Sensitive journey: pick people one by one'),
        findsOneWidget,
      );

      await _tap(tester, _key('share-friend-f2'));
      expect(_submitLabel(tester), 'Share with 1 friend');
      expect(_submitEnabled(tester), isTrue);
      await _tap(tester, _key('share-clear'));
      expect(_submitEnabled(tester), isFalse);
      await _tap(tester, _key('share-select-all'));
      expect(_submitLabel(tester), 'Share with 3 friends');
    });

    testWidgets('S9: running journey has a locked link', (tester) async {
      await pumpSharing(
        tester,
        location: '/sharing/j1',
        journeys: _journeys(status: JourneyStatus.active),
        friends: _friends,
      );
      expect(_key('share-link-locked'), findsOneWidget);
      expect(_key('share-link-switch'), findsNothing);
      expect(find.text("They'll see new photos as you post"), findsOneWidget);
    });

    testWidgets('S9: ended journey turns the link on; stats line shows', (
      tester,
    ) async {
      final sharing = FakeSharingRepository();
      await pumpSharing(
        tester,
        location: '/sharing/j1',
        sharing: sharing,
        journeys: _journeys(),
        insights: FakeInsightsRepository(testInsights()),
      );
      await _tap(tester, _key('share-link-switch'));
      expect(sharing.calls, contains('link:true:false'));
      expect(_key('share-copy-link'), findsOneWidget);
      expect(_key('share-show-counts'), findsOneWidget);
      expect(find.textContaining('1.2K views'), findsOneWidget);
    });

    testWidgets('under 18: forbidden explains the age rule', (tester) async {
      final sharing = FakeSharingRepository()
        ..linkError = const OurneyException(OurneyErrorCode.forbidden);
      await pumpSharing(
        tester,
        location: '/sharing/j1',
        sharing: sharing,
        journeys: _journeys(),
      );
      await _tap(tester, _key('share-link-switch'));
      expect(_key('share-under18'), findsOneWidget);
      expect(
        tester.widget<UiSwitchRow>(_key('share-link-switch')).onChanged,
        isNull,
      );
    });

    testWidgets('sensitive link shows the warm warning first', (tester) async {
      final sharing = FakeSharingRepository();
      await pumpSharing(
        tester,
        location: '/sharing/j1',
        sharing: sharing,
        journeys: _journeys(template: TemplateId.weightLoss),
      );
      await _tap(tester, _key('share-link-switch'));
      expect(_key('share-sensitive-warning'), findsOneWidget);
      expect(sharing.calls.where((c) => c.startsWith('link')), isEmpty);
      await _tap(tester, _key('share-warning-confirm'));
      expect(sharing.calls, contains('link:true:false'));
    });

    testWidgets('group: consent_required asks the group first', (tester) async {
      final sharing = FakeSharingRepository()
        ..shareError = const OurneyException(OurneyErrorCode.consentRequired);
      final consents = FakeShareConsentRepository([
        ShareConsent(
          journeyId: 'j1',
          journeyTitle: 't',
          member: person('u1', 'Me'),
          status: ShareConsentStatus.accepted,
          requestedBy: person('u1', 'Me'),
        ),
        ShareConsent(
          journeyId: 'j1',
          journeyTitle: 't',
          member: person('m2', 'Minh'),
          status: ShareConsentStatus.pending,
          requestedBy: person('u1', 'Me'),
        ),
      ]);
      await pumpSharing(
        tester,
        location: '/sharing/j1',
        sharing: sharing,
        consents: consents,
        journeys: _journeys(kind: JourneyKind.group),
        friends: _friends,
      );
      expect(find.text('Waiting'), findsOneWidget);
      expect(find.text('Agreed'), findsOneWidget);
      expect(_key('share-ask-group'), findsNothing);

      await _tap(tester, _key('share-submit'));
      expect(_key('share-ask-group'), findsOneWidget);
      await _tap(tester, _key('share-ask-group'));
      expect(consents.calls, ['request:j1']);
    });

    testWidgets('member: no Stop sharing for the owner link (C-B14)', (
      tester,
    ) async {
      await pumpSharing(
        tester,
        location: '/sharing/j1',
        sharing: FakeSharingRepository(token: 'tok${'0' * 37}'),
        journeys: FakeJourneyRepository(
          journeys: [
            testJourney(
              ownerId: 'owner',
              kind: JourneyKind.group,
              status: JourneyStatus.ended,
            ),
          ],
        ),
      );
      expect(_key('share-link-block'), findsOneWidget);
      expect(_key('share-stop'), findsNothing);
    });

    testWidgets('owner: link on shows one ellipsized URL line (U22)', (
      tester,
    ) async {
      await pumpSharing(
        tester,
        location: '/sharing/j1',
        sharing: FakeSharingRepository(token: 'tok${'0' * 37}'),
        journeys: _journeys(),
        friends: _friends,
      );
      final url = tester.widget<Text>(_key('share-link-url'));
      expect(url.data, contains('token=tok'));
      expect(url.maxLines, 1);
      expect(url.overflow, TextOverflow.ellipsis);
      expect(
        tester.widget<UiSwitchRow>(_key('share-link-switch')).subtitle,
        isNull,
      );
      expect(_key('share-stop'), findsOneWidget);
      // Select all / Clear sit side by side on one line.
      final all = tester.getRect(_key('share-select-all'));
      final clear = tester.getRect(_key('share-clear'));
      expect(clear.top, all.top);
      expect(clear.left, greaterThanOrEqualTo(all.right));
    });

    testWidgets('showShareJourneySheet opens the panel', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(testBackendConfig),
            sharingRepositoryProvider.overrideWithValue(
              FakeSharingRepository(),
            ),
            friendRepositoryProvider.overrideWithValue(
              FakeFriendRepository(_friends),
            ),
            checkInRepositoryProvider.overrideWithValue(
              FakeCheckInRepository(),
            ),
            mediaStoreProvider.overrideWithValue(FakeMediaStore()),
          ],
          child: MaterialApp(
            theme: buildAppTheme(Brightness.light),
            locale: const Locale('en'),
            localizationsDelegates: ourneyLocalizationsDelegates,
            supportedLocales: ourneySupportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () =>
                      showShareJourneySheet(context, testJourney()),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(_key('share-journey-sheet'), findsOneWidget);
      expect(_submitLabel(tester), 'Share with 3 friends');
    });
  });

  group('Prepare the story (SCR-83)', () {
    testWidgets('saves the story and hides a photo', (tester) async {
      final sharing = FakeSharingRepository();
      final checkIns = FakeCheckInRepository([
        testCheckIn('j1', const LocalDate(2026, 10, 10)),
        testCheckIn('j1', const LocalDate(2026, 10, 11)),
      ]);
      final h = await pumpSharing(
        tester,
        location: '/sharing/j1',
        sharing: sharing,
        checkIns: checkIns,
        journeys: _journeys(),
      );
      await h.go(tester, '/sharing/j1/story');
      expect(
        tester.widget<TextField>(_key('story-title')).controller!.text,
        'Tập mỗi ngày',
      );
      await tester.enterText(_key('story-title'), 'Hoi An 2024');
      await tester.enterText(_key('story-intro'), 'Why I started');
      await _tap(tester, _key('story-hide-c-j1-2026-10-11'));
      expect(sharing.calls, contains('hide:c-j1-2026-10-11:true'));
      await _tap(tester, _key('story-cover'));
      await _tap(tester, _key('story-cover-option-c-j1-2026-10-10'));
      await _tap(tester, _key('story-save'));
      expect(sharing.savedStory?.title, 'Hoi An 2024');
      expect(sharing.savedStory?.intro, 'Why I started');
      expect(sharing.savedStory?.lessons, isNull);
      expect(sharing.savedStory?.coverCheckInId, 'c-j1-2026-10-10');
    });

    testWidgets('hiding the cover photo clears the cover (C-B14)', (
      tester,
    ) async {
      final sharing = FakeSharingRepository();
      final h = await pumpSharing(
        tester,
        location: '/sharing/j1',
        sharing: sharing,
        checkIns: FakeCheckInRepository([
          testCheckIn('j1', const LocalDate(2026, 10, 10)),
          testCheckIn('j1', const LocalDate(2026, 10, 11)),
        ]),
        journeys: _journeys(),
      );
      await h.go(tester, '/sharing/j1/story');
      await _tap(tester, _key('story-cover'));
      await _tap(tester, _key('story-cover-option-c-j1-2026-10-10'));
      await _tap(tester, _key('story-hide-c-j1-2026-10-10'));
      await tester.enterText(_key('story-intro'), 'Why I started');
      await tester.pumpAndSettle();
      await _tap(tester, _key('story-save'));
      expect(sharing.savedStory?.intro, 'Why I started');
      expect(sharing.savedStory?.coverCheckInId, isNull);
    });

    testWidgets('hiding the cover clears it on the server too (C-B14)', (
      tester,
    ) async {
      final sharing = FakeSharingRepository();
      final h = await pumpSharing(
        tester,
        location: '/sharing/j1',
        sharing: sharing,
        checkIns: FakeCheckInRepository([
          testCheckIn('j1', const LocalDate(2026, 10, 10)),
        ]),
        journeys: _journeys(),
      );
      await h.go(tester, '/sharing/j1/story');
      await _tap(tester, _key('story-cover'));
      await _tap(tester, _key('story-cover-option-c-j1-2026-10-10'));
      await _tap(tester, _key('story-save'));
      expect(sharing.savedStory?.coverCheckInId, 'c-j1-2026-10-10');
    });

    testWidgets('slow hide toggles (two) never overwrite a later save', (
      tester,
    ) async {
      final gate = Completer<void>();
      final sharing = FakeSharingRepository(
        story: const JourneyStory(
          title: 'Old',
          coverCheckInId: 'c-j1-2026-10-10',
        ),
        hideGate: gate,
      );
      final h = await pumpSharing(
        tester,
        location: '/sharing/j1',
        sharing: sharing,
        checkIns: FakeCheckInRepository([
          testCheckIn('j1', const LocalDate(2026, 10, 10)),
          testCheckIn('j1', const LocalDate(2026, 10, 11)),
        ]),
        journeys: _journeys(),
      );
      await h.go(tester, '/sharing/j1/story');
      await _tap(tester, _key('story-hide-c-j1-2026-10-10'));
      await _tap(tester, _key('story-hide-c-j1-2026-10-11'));
      await tester.enterText(_key('story-title'), 'New title');
      await tester.pump();
      await _tap(tester, _key('story-save'));
      gate.complete();
      await tester.pumpAndSettle();
      expect(sharing.savedStory?.title, 'New title');
    });

    testWidgets('queued hide toggles still reach the server after closing', (
      tester,
    ) async {
      final gate = Completer<void>();
      final sharing = FakeSharingRepository(hideGate: gate);
      final h = await pumpSharing(
        tester,
        location: '/sharing/j1',
        sharing: sharing,
        checkIns: FakeCheckInRepository([
          testCheckIn('j1', const LocalDate(2026, 10, 10)),
          testCheckIn('j1', const LocalDate(2026, 10, 11)),
        ]),
        journeys: _journeys(),
      );
      await h.go(tester, '/sharing/j1/story');
      await _tap(tester, _key('story-hide-c-j1-2026-10-10'));
      await _tap(tester, _key('story-hide-c-j1-2026-10-11'));
      await h.go(tester, '/sharing/j1');
      gate.complete();
      await tester.pumpAndSettle();
      expect(sharing.calls.where((c) => c.startsWith('hide:')).toSet(), {
        'hide:c-j1-2026-10-10:true',
        'hide:c-j1-2026-10-11:true',
      });
    });

    testWidgets('group member: story is read-only, photos can be hidden '
        '(C-B14)', (tester) async {
      final sharing = FakeSharingRepository();
      final h = await pumpSharing(
        tester,
        location: '/sharing/j1',
        sharing: sharing,
        checkIns: FakeCheckInRepository([
          testCheckIn('j1', const LocalDate(2026, 10, 10)),
        ]),
        journeys: FakeJourneyRepository(
          journeys: [
            testJourney(
              ownerId: 'owner',
              kind: JourneyKind.group,
              status: JourneyStatus.ended,
            ),
          ],
        ),
      );
      await h.go(tester, '/sharing/j1/story');
      expect(_key('story-owner-only'), findsOneWidget);
      expect(_key('story-title'), findsNothing);
      expect(_key('story-cover'), findsNothing);
      expect(_key('story-save'), findsNothing);
      await _tap(tester, _key('story-hide-c-j1-2026-10-10'));
      expect(sharing.calls, contains('hide:c-j1-2026-10-10:true'));
    });

    testWidgets('unsaved edits: back asks first, Save only when changed '
        '(U19)', (tester) async {
      final sharing = FakeSharingRepository();
      final h = await pumpSharing(
        tester,
        location: '/sharing/j1',
        sharing: sharing,
        journeys: _journeys(),
      );
      await h.go(tester, '/sharing/j1');
      await _tap(tester, _key('share-edit-story'));
      expect(_key('story-editor'), findsOneWidget);
      UiTextAction save() => tester.widget<UiTextAction>(_key('story-save'));
      expect(save().onPressed, isNull);

      await tester.enterText(_key('story-title'), '');
      await tester.pumpAndSettle();
      expect(_key('story-title-fallback'), findsOneWidget);
      await tester.enterText(_key('story-intro'), 'Why I started');
      await tester.pumpAndSettle();
      expect(save().onPressed, isNotNull);

      // System back (gesture / Android button) goes through PopScope.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
      await _tap(tester, find.text('Cancel'));
      expect(_key('story-editor'), findsOneWidget);

      final back = find.descendant(
        of: _key('story-editor'),
        matching: find.byType(UiBarIconButton),
      );
      await _tap(tester, back.first);
      expect(find.text('Discard changes?'), findsOneWidget);
      await _tap(tester, _key('sharing-confirm'));
      expect(_key('story-editor'), findsNothing);
      expect(sharing.savedStory, isNull);
    });
  });

  group('Shared with me', () {
    SharedJourneySummary summary(
      String id, {
      bool saved = false,
      bool imported = false,
    }) => SharedJourneySummary(
      journeyId: id,
      title: 'Journey $id',
      emoji: '✈️',
      templateId: TemplateId.travel,
      kind: JourneyKind.solo,
      origin: imported ? JourneyOrigin.imported : JourneyOrigin.live,
      status: JourneyStatus.ended,
      owner: person('o1', 'Ha Vu'),
      sharedBy: person('o1', 'Ha Vu'),
      sharedAt: DateTime.utc(2026),
      photoCount: 3,
      saved: saved,
      unseen: !saved,
      firstDate: const LocalDate(2024, 2, 3),
      lastDate: const LocalDate(2024, 2, 6),
    );

    Future<void> pumpList(
      WidgetTester tester,
      FakeSharingRepository repo, {
      FakeSafetyRepository? safety,
    }) => tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(testBackendConfig),
          sharingRepositoryProvider.overrideWithValue(repo),
          safetyRepositoryProvider.overrideWithValue(
            safety ?? FakeSafetyRepository(),
          ),
          mediaStoreProvider.overrideWithValue(FakeMediaStore()),
        ],
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          locale: const Locale('en'),
          localizationsDelegates: ourneyLocalizationsDelegates,
          supportedLocales: ourneySupportedLocales,
          home: const Scaffold(body: SharedWithMeList()),
        ),
      ),
    );

    testWidgets('rows, Imported badge, Saved section and unsave', (
      tester,
    ) async {
      final repo = FakeSharingRepository(
        sharedWithMe: [summary('a', imported: true), summary('b', saved: true)],
      );
      await pumpList(tester, repo);
      await tester.pumpAndSettle();
      expect(find.text('From friends'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('by Ha Vu'), findsOneWidget);
      expect(_key('shared-imported-a'), findsOneWidget);
      expect(find.text('Imported'), findsOneWidget);
      expect(_key('shared-new-a'), findsOneWidget);
      await _tap(tester, _key('shared-unsave-b'));
      expect(repo.calls, contains('unsave:b'));
      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('journeys from someone just blocked disappear (C-B3)', (
      tester,
    ) async {
      final safety = FakeSafetyRepository();
      await pumpList(
        tester,
        FakeSharingRepository(sharedWithMe: [summary('a')]),
        safety: safety,
      );
      await tester.pumpAndSettle();
      expect(find.text('Journey a'), findsOneWidget);
      await safety.block('o1');
      await tester.pumpAndSettle();
      expect(find.text('Journey a'), findsNothing);
      expect(_key('shared-with-me-empty'), findsOneWidget);
    });

    testWidgets('empty state', (tester) async {
      await pumpList(tester, FakeSharingRepository());
      await tester.pumpAndSettle();
      expect(_key('shared-with-me-empty'), findsOneWidget);
    });

    testWidgets('Vietnamese badge', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(testBackendConfig),
            sharingRepositoryProvider.overrideWithValue(
              FakeSharingRepository(
                sharedWithMe: [summary('a', imported: true)],
              ),
            ),
            mediaStoreProvider.overrideWithValue(FakeMediaStore()),
          ],
          child: MaterialApp(
            theme: buildAppTheme(Brightness.light),
            locale: const Locale('vi'),
            localizationsDelegates: ourneyLocalizationsDelegates,
            supportedLocales: ourneySupportedLocales,
            home: const Scaffold(body: SharedWithMeList()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kể lại'), findsOneWidget);
    });
  });

  group('Shared journey viewer (SCR-84)', () {
    testWidgets('friend: like, reply opens chat, do this journey', (
      tester,
    ) async {
      final sharing = FakeSharingRepository(view: testView());
      final chat = FakeChatRepository();
      final h = await pumpSharing(
        tester,
        location: '/shared/j1',
        sharing: sharing,
        chat: chat,
      );
      expect(find.text('Da Lat in 5 photos'), findsWidgets);
      expect(_key('shared-streak'), findsOneWidget);
      expect(_key('shared-add-friend'), findsNothing);
      await _tap(tester, _key('shared-like-p1'));
      expect(sharing.calls, contains('like:p1'));
      await _tap(tester, _key('shared-like-p1'));
      expect(sharing.calls, contains('unlike:p1'));
      expect(find.text('Only Ha Vu sees your reply'), findsOneWidget);
      // The real chat screen keeps a live stream open: no pumpAndSettle.
      await tester.ensureVisible(_key('shared-reply-p1'));
      await tester.tap(_key('shared-reply-p1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(chat.opened, ['j1:p1']);
      // The photo travels with the route to the first message (C-B15).
      expect(h.location, '/chat/conv1?replyTo=p1');
      expect(_key('chat-reply-pending'), findsOneWidget);
    });

    testWidgets('stranger by token: add friend, no reply, counts', (
      tester,
    ) async {
      final sharing = FakeSharingRepository(
        view: testView(
          role: ViewerRole.stranger,
          canReply: false,
          canAddOwner: true,
          likeCount: 340,
          followCount: 28,
          origin: JourneyOrigin.imported,
          blurred: true,
        ),
      );
      final friends = FakeFriendRepository(const []);
      await pumpSharing(
        tester,
        location: '/p/tok123',
        sharing: sharing,
        friendRepo: friends,
      );
      expect(sharing.calls, contains('public-open:tok123'));
      expect(_key('shared-reply-p1'), findsNothing);
      expect(_key('shared-streak'), findsNothing);
      expect(find.text('❤️ 340 · 28 people did this journey'), findsOneWidget);
      expect(find.textContaining('IMPORTED'), findsOneWidget);
      await _tap(tester, _key('shared-add-friend'));
      expect(friends.requests, ['o1:j1']);
      expect(find.text('Requested'), findsOneWidget);
    });

    testWidgets('revoked: private now', (tester) async {
      final sharing = FakeSharingRepository()
        ..viewError = const OurneyException(OurneyErrorCode.forbidden);
      await pumpSharing(tester, location: '/shared/j1', sharing: sharing);
      expect(_key('shared-private-now'), findsOneWidget);
      expect(find.text('This journey is private now'), findsOneWidget);
    });
  });

  group('Do this journey (SCR-87)', () {
    testWidgets('prefills quick setup and marks followed', (tester) async {
      final sharing = FakeSharingRepository(
        view: testView(),
        frame: const JourneyFrame(
          sourceJourneyId: 'src',
          templateId: TemplateId.travel,
          kind: JourneyKind.solo,
          title: 'Da Lat in 5 photos',
          emoji: '✈️',
          ownerName: 'Ha Vu',
          durationDays: 5,
        ),
      );
      // A 5-day source is clamped to the 7-day minimum.
      final journeys = FakeJourneyRepository();
      await pumpSharing(
        tester,
        location: '/follow/src',
        sharing: sharing,
        journeys: journeys,
      );
      expect(
        find.text('Start your own Memory Collectors journey'),
        findsOneWidget,
      );
      await _tap(tester, _key('follow-start'));
      expect(_key('journey-based-on'), findsOneWidget);
      expect(find.text("Based on Ha Vu's journey"), findsOneWidget);
      expect(
        tester.widget<TextField>(_key('journey-title')).controller!.text,
        'Da Lat in 5 photos',
      );
      await _tap(tester, _key('journey-create'));
      expect(journeys.created.single.durationDays, 7);
      expect(sharing.calls, contains('followed:new-1:src'));
    });

    testWidgets('removing the chip drops the link', (tester) async {
      final sharing = FakeSharingRepository(
        frame: const JourneyFrame(
          sourceJourneyId: 'src',
          templateId: TemplateId.custom,
          kind: JourneyKind.solo,
          title: 'Read',
          emoji: '📚',
          ownerName: 'Ha Vu',
        ),
      );
      await pumpSharing(tester, location: '/follow/src', sharing: sharing);
      await _tap(tester, _key('follow-change'));
      expect(_key('journey-blur'), findsOneWidget);
      await _tap(tester, _key('journey-based-on-remove'));
      expect(_key('journey-based-on'), findsNothing);
      await _tap(tester, _key('journey-create'));
      expect(sharing.calls.where((c) => c.startsWith('followed')), isEmpty);
    });

    testWidgets(
      'back from setup returns to FollowJourneyScreen, and FollowJourneyScreen back falls back to /shared/:id (DE-21)',
      (tester) async {
        final sharing = FakeSharingRepository(
          frame: const JourneyFrame(
            sourceJourneyId: 'src',
            templateId: TemplateId.travel,
            kind: JourneyKind.solo,
            title: 'Da Lat',
            emoji: '✈️',
            ownerName: 'Ha Vu',
          ),
          view: testView(),
        );
        final h = await pumpSharing(
          tester,
          location: '/follow/src',
          sharing: sharing,
        );
        await _tap(tester, _key('follow-start'));
        expect(_key('journeys-create'), findsOneWidget);

        await tester.tap(find.bySemanticsLabel('Back').first);
        await tester.pumpAndSettle();
        expect(h.location, '/follow/src');
        expect(_key('follow-journey'), findsOneWidget);

        await tester.tap(find.bySemanticsLabel('Back').first);
        await tester.pumpAndSettle();
        expect(h.location, '/shared/src');
      },
    );

    testWidgets(
      'ShareJourneyScreen, StoryEditorScreen, and InsightsScreen navigate back to /journey/:id (DE-24)',
      (tester) async {
        final h = await pumpSharing(
          tester,
          location: '/sharing/j1',
          journeys: _journeys(),
          insights: FakeInsightsRepository(testInsights()),
        );
        await tester.tap(find.bySemanticsLabel('Back').first);
        await tester.pumpAndSettle();
        expect(h.location, '/journey/j1');

        await h.go(tester, '/sharing/j1/story');
        await tester.tap(find.bySemanticsLabel('Back').first);
        await tester.pumpAndSettle();
        expect(h.location, '/sharing/j1');
        await tester.tap(find.bySemanticsLabel('Back').first);
        await tester.pumpAndSettle();
        expect(h.location, '/journey/j1');

        await h.go(tester, '/sharing/j1/insights');
        await tester.tap(find.bySemanticsLabel('Back').first);
        await tester.pumpAndSettle();
        expect(h.location, '/sharing/j1');
        await tester.tap(find.bySemanticsLabel('Back').first);
        await tester.pumpAndSettle();
        expect(h.location, '/journey/j1');
      },
    );
  });

  group('Insights (SCR-88)', () {
    testWidgets('numbers, split, likers, privacy note', (tester) async {
      await pumpSharing(
        tester,
        location: '/sharing/j1/insights',
        journeys: _journeys(),
        sharing: FakeSharingRepository(token: 'tok'),
        insights: FakeInsightsRepository(testInsights()),
      );
      expect(find.text('1.2K'), findsOneWidget);
      expect(find.text('340'), findsOneWidget);
      expect(find.text('+56 new viewers this week'), findsOneWidget);
      expect(find.text('Friends 42'), findsOneWidget);
      expect(find.text('Others 298'), findsOneWidget);
      expect(_key('insights-liker-l1'), findsOneWidget);
      expect(_key('insights-chart'), findsOneWidget);
      expect(_key('insights-privacy'), findsOneWidget);
    });

    test('fillDays pads 30 days ending on the latest day', () {
      final days = fillDays(const [
        DailyCount(LocalDate(2026, 10, 15), 4),
      ], today: const LocalDate(2026, 10, 15));
      expect(days, hasLength(30));
      expect(days.last.count, 4);
      expect(days.first.day, const LocalDate(2026, 9, 16));
    });
  });

  group('Local-only and layout', () {
    for (final path in ['/sharing/j1', '/shared/j1', '/retell', '/follow/j1']) {
      testWidgets('$path needs the server', (tester) async {
        await pumpSharing(
          tester,
          location: path,
          config: const AppConfig.localOnly(),
        );
        expect(find.byKey(const ValueKey('needs-server')), findsOneWidget);
      });
    }

    for (final brightness in Brightness.values) {
      for (final path in [
        '/sharing/j1',
        '/shared/j1',
        '/sharing/j1/insights',
        '/sharing/j1/story',
        '/follow/j1',
      ]) {
        testWidgets('$path at 320dp, 1.35x, $brightness, vi', (tester) async {
          await pumpSharing(
            tester,
            location: path,
            locale: const Locale('vi'),
            size: const Size(320, 640),
            textScale: 1.35,
            brightness: brightness,
            journeys: _journeys(kind: JourneyKind.group),
            friends: _friends,
            sharing: FakeSharingRepository(
              token: 'tok',
              view: testView(
                role: ViewerRole.stranger,
                canAddOwner: true,
                likeCount: 340,
                followCount: 28,
              ),
              frame: const JourneyFrame(
                sourceJourneyId: 'j1',
                templateId: TemplateId.weightLoss,
                kind: JourneyKind.group,
                title: 'Giảm cân cùng nhau thật dài',
                emoji: '⚖️',
                ownerName: 'Hà Vũ',
                durationDays: 30,
                metricName: 'Cân nặng',
                metricUnit: 'kg',
              ),
            ),
            insights: FakeInsightsRepository(testInsights()),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
