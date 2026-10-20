import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/features/auth/l10n/generated/auth_localizations.dart';
import 'package:ourney/features/camera/l10n/generated/camera_localizations.dart';
import 'package:ourney/features/checkin/l10n/generated/checkin_localizations.dart';
import 'package:ourney/features/groups/l10n/generated/groups_localizations.dart';
import 'package:ourney/features/journeys/l10n/generated/journeys_localizations.dart';
import 'package:ourney/features/onboarding/l10n/generated/onboarding_localizations.dart';
import 'package:ourney/features/profile/l10n/generated/profile_localizations.dart';
import 'package:ourney/features/reminders/l10n/generated/reminders_localizations.dart';
import 'package:ourney/features/safety/l10n/generated/safety_localizations.dart';
import 'package:ourney/features/share_card/l10n/generated/share_card_localizations.dart';
import 'package:ourney/l10n/generated/app_localizations.dart';
import 'package:ourney/personas/accountability_squad/l10n/generated/accountability_squad_localizations.dart';
import 'package:ourney/personas/aesthetic_flexer/l10n/generated/aesthetic_flexer_localizations.dart';
import 'package:ourney/personas/couple_rituals/l10n/generated/couple_rituals_localizations.dart';
import 'package:ourney/personas/memory_collectors/l10n/generated/memory_collectors_localizations.dart';
import 'package:ourney/personas/minimalist_habit/l10n/generated/minimalist_habit_localizations.dart';
import 'package:ourney/personas/quiet_transformer/l10n/generated/quiet_transformer_localizations.dart';

import 'test_helpers.dart';

Map<String, Object?> readArb(String path) =>
    (jsonDecode(File(path).readAsStringSync()) as Map).cast<String, Object?>();

Set<String> messageKeys(Map<String, Object?> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

/// (name, arb dir, file prefix, key prefix).
List<(String, String, String, String)> arbSets() {
  final sets = [('app', 'lib/l10n', 'app', '')];
  for (final parent in ['lib/features', 'lib/personas']) {
    for (final dir in Directory(parent).listSync().whereType<Directory>()) {
      if (!Directory('${dir.path}/l10n').existsSync()) continue;
      final f = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
      sets.add((f, '${dir.path}/l10n', f, '${f}_'));
    }
  }
  return sets;
}

void main() {
  test('every feature has its own vi + en ARB pair', () {
    for (final dir in Directory(
      'lib/features',
    ).listSync().whereType<Directory>()) {
      final f = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
      for (final locale in ['vi', 'en']) {
        expect(
          File('${dir.path}/l10n/${f}_$locale.arb').existsSync(),
          isTrue,
          reason: 'missing lib/features/$f/l10n/${f}_$locale.arb',
        );
      }
    }
  });

  test('every persona has its own vi + en ARB pair', () {
    for (final dir in Directory(
      'lib/personas',
    ).listSync().whereType<Directory>()) {
      final p = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
      for (final locale in ['vi', 'en']) {
        expect(
          File('${dir.path}/l10n/${p}_$locale.arb').existsSync(),
          isTrue,
          reason: 'missing lib/personas/$p/l10n/${p}_$locale.arb',
        );
      }
    }
  });

  for (final (name, dir, file, keyPrefix) in arbSets()) {
    test('$name: vi and en define the same keys, prefixed "$keyPrefix"', () {
      final vi = readArb('$dir/${file}_vi.arb');
      final en = readArb('$dir/${file}_en.arb');
      expect(vi['@@locale'], 'vi');
      expect(en['@@locale'], 'en');
      expect(messageKeys(en), messageKeys(vi), reason: '$name vi/en drift');
      for (final key in messageKeys(vi)) {
        expect(
          key.startsWith(keyPrefix),
          isTrue,
          reason: '$name key "$key" must start with "$keyPrefix"',
        );
      }
    });

    test('$name: generated code is present', () {
      expect(
        File('$dir/generated/${file}_localizations.dart').existsSync(),
        isTrue,
        reason: 'run: dart run tool/gen_l10n.dart $name',
      );
    });
  }

  for (final locale in ourneySupportedLocales) {
    testWidgets('all delegates load for $locale', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
          locale: locale,
        ),
      );
      expect(AppLocalizations.of(ctx).app_name, 'Ourney');
      final titles = [
        AuthL10n.of(ctx).auth_title,
        OnboardingL10n.of(ctx).onboarding_title,
        ProfileL10n.of(ctx).profile_title,
        CameraL10n.of(ctx).camera_title,
        CheckinL10n.of(ctx).checkin_title,
        JourneysL10n.of(ctx).journeys_title,
        GroupsL10n.of(ctx).groups_title,
        ShareCardL10n.of(ctx).share_card_title,
        SafetyL10n.of(ctx).safety_title,
        RemindersL10n.of(ctx).reminders_title,
      ];
      expect(titles.every((t) => t.isNotEmpty), isTrue);
      // One class per persona (F1): all six load with the app delegates.
      final personaNames = [
        QuietTransformerL10n.of(ctx).quiet_transformer_name,
        AccountabilitySquadL10n.of(ctx).accountability_squad_nudge('A'),
        MemoryCollectorsL10n.of(ctx).memory_collectors_contactSheetSubtitle(1),
        CoupleRitualsL10n.of(ctx).couple_rituals_name,
        AestheticFlexerL10n.of(ctx).aesthetic_flexer_name,
        MinimalistHabitL10n.of(ctx).minimalist_habit_name,
      ];
      expect(personaNames.every((t) => t.isNotEmpty), isTrue);
      expect(AppLocalizations.of(ctx).localeName, locale.languageCode);
    });
  }

  test('Vietnamese is the fallback locale', () {
    expect(ourneySupportedLocales.first, const Locale('vi'));
  });
}
