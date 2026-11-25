part 'place_catalog_data.dart';

class Place {
  const Place(
    this.id,
    this.nameVi,
    this.nameEn,
    this.countryCode, [
    this.aliases = const [],
  ]);

  final String id;
  final String nameVi;
  final String nameEn;
  final String countryCode;
  final List<String> aliases;

  String get countryVi => _countriesByCode[countryCode]!.nameVi;
  String get countryEn => _countriesByCode[countryCode]!.nameEn;
  bool get isCountry => id.startsWith('country-');

  String name(String language) => language == 'vi' ? nameVi : nameEn;
  String country(String language) => language == 'vi' ? countryVi : countryEn;
}

const placeCatalog = [
  ..._vietnamProvinces,
  ..._vietnamDestinations,
  ..._internationalCities,
  ..._countries,
];
final _countriesByCode = {
  for (final place in _countries) place.countryCode: place,
};

final _foldedLetters = {
  for (final group in const {
    'a': 'àáảãạăằắẳẵặâầấẩẫậäåāą',
    'ae': 'æ',
    'c': 'çćč',
    'd': 'đďð',
    'e': 'èéẻẽẹêềếểễệëēęě',
    'g': 'ğ',
    'i': 'ìíỉĩịîïīı',
    'l': 'ł',
    'n': 'ñńň',
    'o': 'òóỏõọôồốổỗộơờớởỡợöøōő',
    'oe': 'œ',
    'r': 'ř',
    's': 'śšşș',
    'ss': 'ß',
    't': 'ťț',
    'u': 'ùúủũụưừứửữựûüūůű',
    'y': 'ỳýỷỹỵÿ',
    'z': 'źżž',
  }.entries)
    for (final letter in group.value.split('')) letter: group.key,
};
final _combiningMarks = RegExp(r'[\u0300-\u036f]');
final _placeSeparators = RegExp(r"[\s.,’'\-]+");

String foldPlaceName(String value) => value
    .toLowerCase()
    .replaceAll(_combiningMarks, '')
    .split('')
    .map((letter) => _foldedLetters[letter] ?? letter)
    .join()
    .replaceAll(_placeSeparators, ' ')
    .trim();

final _searchKeys = [
  for (final place in placeCatalog)
    {place.nameVi, place.nameEn, ...place.aliases}.map(foldPlaceName).toSet(),
];
final _placesByName = _indexNames();

Map<String, Place> _indexNames() {
  final names = <String, Place>{};
  // Prefer an actual place name over another entry's alias.
  for (final place in placeCatalog) {
    names.putIfAbsent(foldPlaceName(place.nameVi), () => place);
    names.putIfAbsent(foldPlaceName(place.nameEn), () => place);
  }
  final aliases = <String, Place?>{};
  for (final place in placeCatalog) {
    for (final alias in place.aliases.map(foldPlaceName)) {
      if (aliases.containsKey(alias) && aliases[alias] != place) {
        aliases[alias] = null;
      } else {
        aliases[alias] = place;
      }
    }
  }
  for (final MapEntry(key: alias, value: place) in aliases.entries) {
    if (place != null) names.putIfAbsent(alias, () => place);
  }
  return names;
}

/// Vietnam first, then exact, prefix and substring matches within each group.
Iterable<Place> searchPlaces(String query) {
  final folded = foldPlaceName(query);
  if (folded.isEmpty) return const [];
  final ranked = List.generate(6, (_) => <Place>[]);
  for (var i = 0; i < placeCatalog.length; i++) {
    final place = placeCatalog[i];
    final keys = _searchKeys[i];
    final rank = keys.contains(folded)
        ? 0
        : keys.any((key) => key.startsWith(folded))
        ? 1
        : keys.any((key) => key.contains(folded))
        ? 2
        : null;
    if (rank != null) {
      ranked[rank + (place.countryCode == 'VN' ? 0 : 3)].add(place);
    }
  }
  return ranked.expand((group) => group);
}

typedef PlaceSuggestion = ({String value, String? country, String? id});

/// [recent] is ordered newest first. An optional trip destination goes first.
List<PlaceSuggestion> placeSuggestions({
  required String query,
  required String language,
  String? destination,
  Iterable<String> recent = const [],
  int? maxRunes,
}) {
  final items = <PlaceSuggestion>[];
  final seen = <String>{};
  void add(String value, {Place? place}) {
    final folded = foldPlaceName(value);
    if (value.isEmpty ||
        (maxRunes != null && value.runes.length > maxRunes) ||
        !seen.add(folded.isEmpty ? value : folded)) {
      return;
    }
    items.add((
      value: value,
      country: place == null || place.isCountry
          ? null
          : place.country(language),
      id: place?.id,
    ));
  }

  final browse = query.trim().isEmpty;
  if (browse) {
    for (final saved in [?destination, ...recent]) {
      final name = saved.trim();
      final place = _placesByName[foldPlaceName(name)];
      add(place?.name(language) ?? name, place: place);
      if (items.length == 5) break;
    }
  }
  for (final place in browse ? placeCatalog : searchPlaces(query)) {
    add(place.name(language), place: place);
  }
  return items;
}
