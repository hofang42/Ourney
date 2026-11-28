import 'package:ourney_core/ourney_core.dart';
import 'package:test/test.dart';

Journey journey({
  JourneyOrigin origin = JourneyOrigin.imported,
  JourneyStatus status = JourneyStatus.active,
  int? durationDays,
  String ownerId = 'me',
}) =>
    Journey(
      id: 'retold',
      ownerId: ownerId,
      kind: JourneyKind.solo,
      templateId: TemplateId.custom,
      title: 'A few days',
      emoji: '',
      startDate: const LocalDate(2026, 11, 20),
      timezone: 'Asia/Ho_Chi_Minh',
      visibility: JourneyVisibility.private,
      status: status,
      durationDays: durationDays,
      origin: origin,
    );
CheckIn photo(
  int day, {
  bool library = true,
  String journeyId = 'retold',
  String userId = 'me',
  bool moderated = false,
}) =>
    CheckIn(
      id: '$day-$library',
      journeyId: journeyId,
      userId: userId,
      localDate: LocalDate(2026, 11, day),
      capturedAt: DateTime.utc(2026, 11, day),
      photoPath: '',
      thumbPath: '',
      fromLibrary: library,
      moderated: moderated,
    );

void main() {
  test('live journeys count library and camera photos', () {
    final live = journey(origin: JourneyOrigin.live);
    expect(countsTowardStreak(live, photo(20)), isTrue);
    expect(
      countsTowardStreak(live, photo(20, library: false)),
      isTrue,
    );
  });
  test('retold journeys count only camera photos', () {
    expect(countsTowardStreak(journey(), photo(20)), isFalse);
    expect(countsTowardStreak(journey(), photo(28, library: false)), isTrue);
  });
  test(
    'retold boundary is latest library date, ignoring order and camera photos',
    () {
      expect(lastRetoldDate(journey(), []), isNull);
      expect(lastRetoldDate(journey(), [photo(28, library: false)]), isNull);
      expect(
        lastRetoldDate(journey(), [
          photo(27),
          photo(20),
          photo(28, library: false),
        ]),
        const LocalDate(2026, 11, 27),
      );
      expect(lastRetoldDate(journey(origin: JourneyOrigin.live), [photo(27)]),
          isNull);
    },
  );

  group('caption eligibility', () {
    Membership member({
      MemberStatus status = MemberStatus.active,
      String journeyId = 'retold',
      String userId = 'me',
    }) =>
        Membership(
          journeyId: journeyId,
          userId: userId,
          role: MemberRole.member,
          status: status,
          joinedAt: DateTime.utc(2026, 11, 20),
        );

    bool canEdit(
      Journey? j,
      CheckIn c,
      Membership? membership,
    ) =>
        canEditCheckInCaption(
          c: c,
          j: j,
          me: 'me',
          today: const LocalDate(2026, 11, 30),
          membership: membership,
        );

    test('requires an active membership and an unmoderated photo by me', () {
      final active = journey();
      expect(canEdit(active, photo(20), member()), isTrue);
      expect(canEdit(null, photo(20), member()), isFalse);
      expect(canEdit(active, photo(20, journeyId: 'other'), member()), isFalse);
      expect(canEdit(active, photo(20, userId: 'other'), member()), isFalse);
      expect(canEdit(active, photo(20, moderated: true), member()), isFalse);
      expect(canEdit(active, photo(20), null), isFalse);
      expect(
        canEdit(active, photo(20), member(status: MemberStatus.left)),
        isFalse,
      );
      expect(canEdit(active, photo(20), member(journeyId: 'other')), isFalse);
      expect(canEdit(active, photo(20), member(userId: 'other')), isFalse);
    });

    test('uses the photo date for fixed-duration active journeys', () {
      final active = journey(origin: JourneyOrigin.live, durationDays: 3);
      expect(canEdit(active, photo(22), member()), isTrue);
      expect(canEdit(active, photo(23), member()), isFalse);
    });

    for (final status in [JourneyStatus.ended, JourneyStatus.archived]) {
      test('${status.name}: allows only an imported fixed journey owner', () {
        expect(
          canEdit(
              journey(status: status, durationDays: 3), photo(20), member()),
          isTrue,
        );
        expect(
          canEdit(journey(status: status), photo(20), member()),
          isFalse,
        );
        expect(
          canEdit(
            journey(
                status: status, durationDays: 3, origin: JourneyOrigin.live),
            photo(20),
            member(),
          ),
          isFalse,
        );
        expect(
          canEdit(
            journey(status: status, durationDays: 3, ownerId: 'other'),
            photo(20),
            member(),
          ),
          isFalse,
        );
      });
    }
  });
}
