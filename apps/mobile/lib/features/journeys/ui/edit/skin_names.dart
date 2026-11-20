import '../../l10n/generated/journeys_localizations.dart';

/// Localized short name of a V2 skin (replaces a hard-coded Vietnamese
/// label, bug U20).
String skinShortName(JourneysL10n l10n, String skinId) => switch (skinId) {
  'quiet' => l10n.journeys_edit_skinShort_quiet,
  'squad' => l10n.journeys_edit_skinShort_squad,
  'memory' => l10n.journeys_edit_skinShort_memory,
  'couple' => l10n.journeys_edit_skinShort_couple,
  'flexer' => l10n.journeys_edit_skinShort_flexer,
  _ => l10n.journeys_edit_skinShort_minimal,
};

/// Localized name of colour variant [index] (0..2) of skin [skinId].
String skinColorName(JourneysL10n l10n, String skinId, int index) {
  final i = index.clamp(0, 2);
  return switch ((skinId, i)) {
    ('quiet', 0) => l10n.journeys_edit_skinColor_quiet_0,
    ('quiet', 1) => l10n.journeys_edit_skinColor_quiet_1,
    ('quiet', _) => l10n.journeys_edit_skinColor_quiet_2,
    ('squad', 0) => l10n.journeys_edit_skinColor_squad_0,
    ('squad', 1) => l10n.journeys_edit_skinColor_squad_1,
    ('squad', _) => l10n.journeys_edit_skinColor_squad_2,
    ('memory', 0) => l10n.journeys_edit_skinColor_memory_0,
    ('memory', 1) => l10n.journeys_edit_skinColor_memory_1,
    ('memory', _) => l10n.journeys_edit_skinColor_memory_2,
    ('couple', 0) => l10n.journeys_edit_skinColor_couple_0,
    ('couple', 1) => l10n.journeys_edit_skinColor_couple_1,
    ('couple', _) => l10n.journeys_edit_skinColor_couple_2,
    ('flexer', 0) => l10n.journeys_edit_skinColor_flexer_0,
    ('flexer', 1) => l10n.journeys_edit_skinColor_flexer_1,
    ('flexer', _) => l10n.journeys_edit_skinColor_flexer_2,
    (_, 0) => l10n.journeys_edit_skinColor_minimal_0,
    (_, 1) => l10n.journeys_edit_skinColor_minimal_1,
    _ => l10n.journeys_edit_skinColor_minimal_2,
  };
}
