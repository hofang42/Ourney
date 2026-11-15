import 'package:ourney_core/ourney_core.dart';
import 'package:test/test.dart';

void main() {
  group('CheckInExtras', () {
    test('json round trip keeps only set keys', () {
      const e = CheckInExtras(mood: 'Nhẹ nhõm', minutes: 45, pace: '5:04');
      expect(e.toJson(), {'mood': 'Nhẹ nhõm', 'minutes': 45, 'pace': '5:04'});
      expect(CheckInExtras.fromJson(e.toJsonString()), e);
      expect(CheckInExtras.empty.toJson(), isEmpty);
      expect(CheckInExtras.empty.isEmpty, isTrue);
    });

    test('fromJson is lenient about garbage', () {
      expect(CheckInExtras.fromJson('not json'), CheckInExtras.empty);
      expect(CheckInExtras.fromJson(null), CheckInExtras.empty);
      expect(
        CheckInExtras.fromJson({'minutes': 'x', 'evil': 1, 'dish': 'Phở'}),
        const CheckInExtras(dish: 'Phở'),
      );
    });

    test('validate mirrors the SQL whitelist', () {
      expect(const CheckInExtras(hearts: 5, minutes: 1440).validate(), isNull);
      expect(const CheckInExtras(minutes: 0).validate(), 'minutes');
      expect(const CheckInExtras(minutes: 1441).validate(), 'minutes');
      expect(const CheckInExtras(hearts: 6).validate(), 'hearts');
      expect(const CheckInExtras(pace: '5:75').validate(), 'pace');
      expect(const CheckInExtras(pace: '12:30').validate(), isNull);
      expect(CheckInExtras(place: 'x' * 61).validate(), 'place');
      expect(const CheckInExtras(mood: '').validate(), 'mood');
    });

    test('km: 0.1..500 with one decimal', () {
      expect(const CheckInExtras(km: 5.3).validate(), isNull);
      expect(const CheckInExtras(km: 0.1).validate(), isNull);
      expect(const CheckInExtras(km: 500).validate(), isNull);
      expect(const CheckInExtras(km: 0).validate(), 'km');
      expect(const CheckInExtras(km: 500.1).validate(), 'km');
      expect(const CheckInExtras(km: 5.25).validate(), 'km');
      expect(const CheckInExtras(km: 5.25).normalized().km, 5.3);
      const e = CheckInExtras(km: 10.5);
      expect(CheckInExtras.fromJson(e.toJsonString()), e);
      expect(e.isEmpty, isFalse);
    });

    test('normalized drops blanks', () {
      const e = CheckInExtras(dish: '  ', place: ' Đà Lạt ');
      expect(e.normalized(), const CheckInExtras(place: 'Đà Lạt'));
    });
  });

  group('validateCoupleNames', () {
    test('pair rules', () {
      expect(validateCoupleNames(null, null), isNull);
      expect(validateCoupleNames('An', 'Bình'), isNull);
      expect(validateCoupleNames('An', ' '), CoupleNamesError.missing);
      expect(
        validateCoupleNames('a' * 25, 'Bình'),
        CoupleNamesError.tooLong,
      );
    });
  });

  test('partner photo path', () {
    expect(checkInPartnerPhotoPath('j', 'u', 'c'), 'checkins/j/u/c_p.jpg');
  });
}
