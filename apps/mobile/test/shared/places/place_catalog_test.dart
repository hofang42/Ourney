import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/shared/places/place_catalog.dart';

void main() {
  test('catalog includes all current provinces and a worldwide selection', () {
    expect(
      placeCatalog.where((p) => p.id.startsWith('vn-province-')),
      hasLength(34),
    );
    expect(placeCatalog.where((p) => p.id.startsWith('city-')), hasLength(163));
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
    'empty search promotes destination and deduplicates localized recents',
    () {
      final items = placeSuggestions(
        query: ' ',
        language: 'vi',
        destination: ' Hanoi ',
        recent: ['Ha Noi', '  Cabin by the lake ', 'Phu Quoc', 'Phú Quốc', ''],
      );
      expect(items.take(3).map((p) => p.value), [
        'Hà Nội',
        'Cabin by the lake',
        'Phú Quốc',
      ]);
      expect(items.where((p) => p.value == 'Hà Nội'), hasLength(1));
      expect(items.where((p) => p.value == 'Phú Quốc'), hasLength(1));
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
}
