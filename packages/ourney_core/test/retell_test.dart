import 'package:ourney_core/ourney_core.dart';
import 'package:test/test.dart';

Journey journey([JourneyOrigin origin = JourneyOrigin.imported]) => Journey(
  id: 'retold',
  ownerId: 'me',
  kind: JourneyKind.solo,
  templateId: TemplateId.custom,
  title: 'A few days',
  emoji: '',
  startDate: const LocalDate(2026, 11, 20),
  timezone: 'Asia/Ho_Chi_Minh',
  visibility: JourneyVisibility.private,
  status: JourneyStatus.active,
  origin: origin,
);
CheckIn photo(int day, {bool library = true, String suffix = ''}) => CheckIn(
  id: '$day-$library-$suffix',
  journeyId: 'retold',
  userId: 'me',
  localDate: LocalDate(2026, 11, day),
  capturedAt: DateTime.utc(2026, 11, day),
  photoPath: '',
  thumbPath: '',
  fromLibrary: library,
);

void main() {
  test('live journeys count library and camera photos', () {
    expect(countsTowardStreak(journey(JourneyOrigin.live), photo(20)), isTrue);
    expect(
      countsTowardStreak(
        journey(JourneyOrigin.live),
        photo(20, library: false),
      ),
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
      expect(lastRetoldDate(journey(JourneyOrigin.live), [photo(27)]), isNull);
    },
  );
}
