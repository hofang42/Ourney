import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/data_context.dart' show checkinDraftDirName;
import 'package:ourney/data/db/app_database.dart';
import 'package:ourney_core/ourney_core.dart';

import 'data_test_helpers.dart';

void main() {
  late AppDatabase db;
  late Directory media;
  late Directory camera;
  late TestClock clock;

  setUp(() {
    db = memoryDb();
    media = tempDir();
    camera = tempDir();
    // 2026-10-16 09:00 in Vietnam.
    clock = TestClock(DateTime.utc(2026, 10, 16, 2));
  });

  test('create journey -> check-in -> retake replaces -> streak', () async {
    final layer = localLayer(db: db, media: media, clock: clock);
    const guest = 'aaaaaaaa-0000-4000-8000-000000000001';

    // Created on the 14th (joined_at = now, like the server's default).
    clock.value = DateTime.utc(2026, 10, 14, 2);
    final journey = await layer.journeys.create(
      soloDraft(start: const LocalDate(2026, 10, 14)),
    );
    clock.value = DateTime.utc(2026, 10, 16, 2);
    expect(journey.ownerId, guest);
    expect(journey.visibility, JourneyVisibility.private);
    expect(journey.templateId, TemplateId.weightLoss);
    expect(await layer.journeys.watchActive().first, hasLength(1));

    final membership = await layer.journeys.watchMyMembership(journey.id).first;
    expect(membership!.role, MemberRole.owner);
    expect(
      membership.hideMetric,
      isTrue,
      reason: 'copied from template default',
    );

    // Yesterday and the day before, then today.
    for (final day in [14, 15]) {
      final shot = fakeCapture(camera, 'd$day');
      await layer.checkIns.submit(
        CheckInDraft(
          journeyId: journey.id,
          capturedAt: DateTime.utc(2026, 10, day, 3),
          photoFile: shot.photo,
          thumbFile: shot.thumb,
        ),
      );
    }
    final first = fakeCapture(camera, 'today1');
    final take1 = await layer.checkIns.submit(
      CheckInDraft(
        journeyId: journey.id,
        capturedAt: clock.value,
        photoFile: first.photo,
        thumbFile: first.thumb,
        metricValue: 70.5,
      ),
    );
    expect(take1.localDate, const LocalDate(2026, 10, 16));
    expect(take1.photoPath, checkInPhotoPath(journey.id, guest, take1.id));
    expect(take1.thumbPath, checkInThumbPath(journey.id, guest, take1.id));
    expect(File(take1.localPhotoFile!).existsSync(), isTrue);
    expect(take1.uploaded, isFalse);

    // Retake: same local day, replaces the first take and its files.
    final second = fakeCapture(camera, 'today2');
    final take2 = await layer.checkIns.submit(
      CheckInDraft(
        journeyId: journey.id,
        capturedAt: clock.value.add(const Duration(minutes: 5)),
        photoFile: second.photo,
        thumbFile: second.thumb,
        caption: 'Lần 2',
      ),
    );
    expect(take2.id, isNot(take1.id));
    final all = await layer.checkIns.watchForJourney(journey.id).first;
    expect(all, hasLength(3));
    expect(all.first.id, take2.id, reason: 'newest first');
    expect(all.first.caption, 'Lần 2');
    expect(File(take1.localPhotoFile!).existsSync(), isFalse);
    expect(
      File(await layer.media.localFileFor(take2.thumbPath)).existsSync(),
      isTrue,
    );

    final streak = computeMemberStreak(
      journeyStart: journey.startDate,
      durationDays: journey.durationDays,
      joinedLocalDate: localDateOf(membership.joinedAt, vnOffset),
      today: const LocalDate(2026, 10, 16),
      dates: all.map((c) => c.localDate),
    );
    expect(streak.current, 3);
    expect(streak.checkedInToday, isTrue);
    expect(await layer.checkIns.watchPendingUploads().first, 0);
  });

  test('local-only auth: no signed-in user, sign-in needs a server', () async {
    final layer = localLayer(db: db, media: media, clock: clock);
    expect(layer.auth.isLocalOnly, isTrue);
    expect(layer.auth.currentUserId, isNull);
    expect(await layer.auth.watchUserId().first, isNull);
    await expectLater(
      layer.auth.sendOtp('a@b.c'),
      throwsA(
        isA<OurneyException>().having(
          (e) => e.error,
          'error',
          OurneyErrorCode.offline,
        ),
      ),
    );
  });

  test('group, link and safety operations need the server', () async {
    final layer = localLayer(db: db, media: media, clock: clock);
    Matcher offline<T extends OurneyException>() => throwsA(
      isA<T>().having((e) => e.error, 'error', OurneyErrorCode.offline),
    );

    await expectLater(
      layer.journeys.create(
        JourneyDraft(
          kind: JourneyKind.group,
          templateId: TemplateId.custom,
          title: 'Nhóm',
          emoji: '💪',
          startDate: const LocalDate(2026, 10, 16),
          timezone: vnZone,
        ),
      ),
      offline<OurneyException>(),
    );
    await expectLater(
      layer.journeys.create(
        JourneyDraft(
          kind: JourneyKind.solo,
          templateId: TemplateId.custom,
          title: 'Link',
          emoji: '💪',
          startDate: const LocalDate(2026, 10, 16),
          timezone: vnZone,
          visibility: JourneyVisibility.link,
        ),
      ),
      offline<OurneyException>(),
    );
    await expectLater(
      layer.groups.joinByCode('ABCD1234'),
      offline<GroupException>(),
    );
    await expectLater(layer.groups.react('x', '🔥'), offline<GroupException>());
    await expectLater(
      layer.groups.watchToday('j').first,
      offline<GroupException>(),
    );
    await expectLater(layer.safety.block('u'), offline<OurneyException>());
    expect(await layer.safety.watchBlockedIds().first, isEmpty);
    final j = await layer.journeys.create(soloDraft());
    await expectLater(
      layer.journeys.setPublicLink(j.id, enabled: true),
      offline<OurneyException>(),
    );
  });

  test('limit of 3 active journeys, end and archive', () async {
    final layer = localLayer(db: db, media: media, clock: clock);
    final a = await layer.journeys.create(soloDraft(title: 'A'));
    await layer.journeys.create(soloDraft(title: 'B'));
    await layer.journeys.create(soloDraft(title: 'C'));
    await expectLater(
      layer.journeys.create(soloDraft(title: 'D')),
      throwsA(isA<JourneyLimitException>()),
    );

    await layer.journeys.end(a.id);
    expect(
      (await layer.journeys.watch(a.id).first)!.status,
      JourneyStatus.ended,
    );
    await expectLater(
      layer.journeys.end(a.id),
      throwsA(
        isA<OurneyException>().having(
          (e) => e.error,
          'error',
          OurneyErrorCode.ended,
        ),
      ),
    );
    final shot = fakeCapture(camera, 'x');
    await expectLater(
      layer.checkIns.submit(
        CheckInDraft(
          journeyId: a.id,
          capturedAt: clock.value,
          photoFile: shot.photo,
          thumbFile: shot.thumb,
        ),
      ),
      throwsA(
        isA<OurneyException>().having(
          (e) => e.error,
          'error',
          OurneyErrorCode.ended,
        ),
      ),
    );
    // Ended journeys no longer count toward the limit.
    await layer.journeys.create(soloDraft(title: 'D'));

    await layer.journeys.archive(a.id);
    final active = await layer.journeys.watchActive().first;
    expect(active.map((j) => j.title), isNot(contains('A')));
    expect(active, hasLength(3));
  });

  test('check-in validation mirrors the server', () async {
    final layer = localLayer(db: db, media: media, clock: clock);
    final j = await layer.journeys.create(soloDraft(durationDays: 7));
    final shot = fakeCapture(camera, 'v');
    CheckInDraft at(DateTime t, {String? caption}) => CheckInDraft(
      journeyId: j.id,
      capturedAt: t,
      photoFile: shot.photo,
      thumbFile: shot.thumb,
      caption: caption,
    );
    Matcher code(OurneyErrorCode c) =>
        throwsA(isA<OurneyException>().having((e) => e.error, 'error', c));

    await expectLater(
      layer.checkIns.submit(at(clock.value.add(const Duration(minutes: 11)))),
      code(OurneyErrorCode.invalidCapturedAt),
    );
    // Window is 10..16 Oct; the 17th (VN) is past the last day.
    clock.advance(const Duration(days: 1));
    await expectLater(
      layer.checkIns.submit(at(clock.value)),
      code(OurneyErrorCode.ended),
    );
    await expectLater(
      layer.checkIns.submit(
        at(DateTime.utc(2026, 10, 16, 2), caption: 'x' * 141),
      ),
      code(OurneyErrorCode.invalid),
    );
    await expectLater(
      layer.checkIns.submit(
        CheckInDraft(
          journeyId: 'missing',
          capturedAt: clock.value,
          photoFile: shot.photo,
          thumbFile: shot.thumb,
        ),
      ),
      code(OurneyErrorCode.notFound),
    );
  });

  test('journey-local date follows the journey timezone', () async {
    final layer = localLayer(db: db, media: media, clock: clock);
    final j = await layer.journeys.create(soloDraft());
    final shot = fakeCapture(camera, 'tz');
    // 2026-10-15 18:30 UTC is already the 16th in Vietnam (UTC+7).
    final c = await layer.checkIns.submit(
      CheckInDraft(
        journeyId: j.id,
        capturedAt: DateTime.utc(2026, 10, 15, 18, 30),
        photoFile: shot.photo,
        thumbFile: shot.thumb,
      ),
    );
    expect(c.localDate, const LocalDate(2026, 10, 16));
  });

  test(
    'delete removes rows and media; delete account wipes everything',
    () async {
      final layer = localLayer(db: db, media: media, clock: clock);
      final j = await layer.journeys.create(soloDraft());
      final shot = fakeCapture(camera, 'del');
      final c = await layer.checkIns.submit(
        CheckInDraft(
          journeyId: j.id,
          capturedAt: clock.value,
          photoFile: shot.photo,
          thumbFile: shot.thumb,
        ),
      );
      await layer.journeys.delete(j.id);
      expect(await layer.journeys.watch(j.id).first, isNull);
      expect(await layer.checkIns.watchForJourney(j.id).first, isEmpty);
      expect(File(c.localPhotoFile!).existsSync(), isFalse);
      await expectLater(
        layer.media.localFileFor(c.photoPath),
        throwsA(
          isA<OurneyException>().having(
            (e) => e.error,
            'error',
            OurneyErrorCode.notFound,
          ),
        ),
      );

      await layer.journeys.create(soloDraft());
      await layer.auth.deleteAccount();
      expect(await layer.journeys.watchActive().first, isEmpty);
    },
  );

  test(
    'delete account also removes check-in drafts next to the media root',
    () async {
      final support = tempDir(); // stands in for Application Support
      final mediaRoot = Directory('${support.path}/media');
      final drafts = Directory('${support.path}/$checkinDraftDirName')
        ..createSync();
      final leftover = File('${drafts.path}/draft.jpg')..writeAsBytesSync([1]);
      final other = File('${support.path}/keep.txt')..writeAsStringSync('x');
      final layer = localLayer(db: db, media: mediaRoot, clock: clock);
      await layer.journeys.create(soloDraft());
      await layer.auth.deleteAccount();
      expect(leftover.existsSync(), isFalse);
      expect(drafts.existsSync(), isFalse);
      expect(other.existsSync(), isTrue, reason: 'only our folders are wiped');
    },
  );

  test('create with a client id is idempotent', () async {
    final layer = localLayer(db: db, media: media, clock: clock);
    const draftId = 'cccccccc-0000-4000-8000-000000000002';
    final base = soloDraft();
    final draft = JourneyDraft(
      kind: base.kind,
      templateId: base.templateId,
      title: base.title,
      emoji: base.emoji,
      startDate: base.startDate,
      timezone: base.timezone,
      id: draftId,
    );
    final a = await layer.journeys.create(draft);
    final b = await layer.journeys.create(draft);
    expect(a.id, draftId);
    expect(b.id, draftId);
    expect(await layer.journeys.watchActive().first, hasLength(1));
  });

  test('profile is kept locally', () async {
    final layer = localLayer(db: db, media: media, clock: clock);
    expect(await layer.profiles.watchMe().first, isNull);
    await layer.profiles.upsertMe(username: 'linh.ng', displayName: ' Linh ');
    await layer.profiles.setAvatar([9, 9, 9]);
    final me = await layer.profiles.watchMe().first;
    expect(me!.displayName, 'Linh');
    expect(
      me.avatarPath,
      startsWith('avatars/aaaaaaaa-0000-4000-8000-000000000001/'),
    );
    expect(
      File(await layer.media.localFileFor(me.avatarPath!)).readAsBytesSync(),
      [9, 9, 9],
    );
    await expectLater(
      layer.profiles.upsertMe(username: 'NO', displayName: 'x'),
      throwsA(
        isA<OurneyException>().having(
          (e) => e.error,
          'error',
          OurneyErrorCode.invalid,
        ),
      ),
    );
  });

  test('data survives a restart (file database)', () async {
    final dir = tempDir();
    final file = File('${dir.path}/ourney.sqlite');
    final db1 = AppDatabase(NativeDatabase(file));
    final layer1 = localLayer(db: db1, media: media, clock: clock);
    final j = await layer1.journeys.create(soloDraft());
    await layer1.dispose();
    await db1.close();

    final db2 = AppDatabase(NativeDatabase(file));
    addTearDown(db2.close);
    final layer2 = localLayer(db: db2, media: media, clock: clock);
    final active = await layer2.journeys.watchActive().first;
    expect(active.single.id, j.id);
  });
}
