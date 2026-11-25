import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/shared/places/place_catalog.dart';

void main() {
  test('catalog includes all current provinces and a worldwide selection', () {
    expect(
      placeCatalog.where((p) => p.id.startsWith('vn-province-')),
      hasLength(34),
    );
    expect(placeCatalog.where((p) => p.id.startsWith('city-')), hasLength(160));
    expect(placeCatalog.where((p) => p.isCountry), hasLength(257));
    expect(
      placeCatalog.map((p) => p.id).toSet(),
      hasLength(placeCatalog.length),
    );
    for (final place in placeCatalog) {
      expect(place.countryVi, isNotEmpty);
      expect(place.countryEn, isNotEmpty);
    }
  });

  test('folds case, Vietnamese accents, punctuation and combining marks', () {
    expect(foldPlaceName('  ĐA\u0300   LẠT  '), 'da lat');
    expect(foldPlaceName('St. Petersburg'), 'st petersburg');
    expect(searchPlaces('DA LAT').first.id, 'vn-destination-da-lat');
    expect(searchPlaces('Hà Giang').first.id, 'vn-destination-ha-giang');
    expect(searchPlaces('sapa').first.id, 'vn-destination-sa-pa');
    expect(searchPlaces('HCMC').first.id, 'vn-province-ho-chi-minh');
    expect(searchPlaces('Peking').first.id, 'city-cn-beijing');
    expect(searchPlaces('munchen').first.id, 'city-de-munich');
    expect(searchPlaces('does not exist'), isEmpty);
  });

  test('Vietnamese matches rank before international matches', () {
    final countries = searchPlaces('la').map((p) => p.countryCode).toList();
    final firstInternational = countries.indexWhere((code) => code != 'VN');
    expect(firstInternational, greaterThan(0));
    expect(countries.skip(firstInternational), isNot(contains('VN')));
  });

  test('suggestions localize both the name and country', () {
    final vi = placeSuggestions(query: 'Beijing', language: 'vi').first;
    expect((vi.value, vi.country), ('Bắc Kinh', 'Trung Quốc'));
    final en = placeSuggestions(query: 'Bắc Kinh', language: 'en').first;
    expect((en.value, en.country), ('Beijing', 'China'));
    expect(searchPlaces('Nhật Bản').first.name('en'), 'Japan');
  });

  test(
    'empty search keeps saved spelling and deduplicates place identities',
    () {
      final items = placeSuggestions(
        query: ' ',
        language: 'vi',
        destination: ' Hanoi ',
        recent: ['Ha Noi', '  Cabin by the lake ', 'Phu Quoc', 'Phú Quốc', ''],
      );
      expect(items.take(3).map((p) => p.value), [
        'Hanoi',
        'Cabin by the lake',
        'Phu Quoc',
      ]);
      expect(items.where((p) => p.id == 'vn-province-ha-noi'), hasLength(1));
      expect(
        items.where((p) => p.id == 'vn-destination-phu-quoc'),
        hasLength(1),
      );
      expect(
        placeSuggestions(
          query: 'Tokyo',
          language: 'vi',
          destination: 'Hanoi',
        ).map((p) => p.value),
        ['Tokyo'],
      );
    },
  );

  test('related places help search and keep separate saved suggestions', () {
    const related = {
      'Vịnh Hạ Long': 'Hạ Long',
      'Okinawa': 'Naha',
      'Hawaii': 'Honolulu',
      'Angkor': 'Siem Reap',
    };
    final items = placeSuggestions(
      query: '',
      language: 'vi',
      destination: related.keys.first,
      recent: related.keys.skip(1),
    );
    expect(items.take(4).map((p) => p.value), related.keys);
    expect(items.take(4).map((p) => p.id), everyElement(isNull));
    for (final entry in related.entries) {
      expect(searchPlaces(entry.key).first.nameVi, entry.value);
    }
  });

  test('territory names and aliases resolve to one row without a subtitle', () {
    for (final (vi, en, queries) in [
      (
        'Hồng Kông',
        'Hong Kong',
        [
          'Hong Kong',
          'Hong Kong SAR China',
          'Đặc khu Hành chính Hồng Kông, Trung Quốc',
        ],
      ),
      (
        'Ma Cao',
        'Macao',
        [
          'Macao',
          'Macau',
          'Macao SAR China',
          'Đặc khu Hành chính Macao, Trung Quốc',
        ],
      ),
      ('Singapore', 'Singapore', ['Singapore', 'Singapura']),
    ]) {
      for (final query in queries) {
        for (final (language, name) in [('vi', vi), ('en', en)]) {
          final item = placeSuggestions(
            query: query,
            language: language,
          ).single;
          expect((item.value, item.country), (name, null));
        }
      }
    }
  });

  test('Athens displays A-ten in Vietnamese and accepts Athena', () {
    for (final query in ['A-ten', 'Athena', 'Athens']) {
      final place = searchPlaces(query).first;
      expect((place.nameVi, place.nameEn), ('A-ten', 'Athens'));
    }
  });
}
