import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/features/auth/l10n/generated/auth_localizations.dart';
import 'package:ourney/features/camera/l10n/generated/camera_localizations.dart';
import 'package:ourney/features/checkin/l10n/generated/checkin_localizations.dart';
import 'package:ourney/features/feedback/l10n/generated/feedback_localizations.dart';
import 'package:ourney/features/groups/l10n/generated/groups_localizations.dart';
import 'package:ourney/features/journeys/l10n/generated/journeys_localizations.dart';
import 'package:ourney/features/onboarding/l10n/generated/onboarding_localizations.dart';
import 'package:ourney/features/profile/l10n/generated/profile_localizations.dart';
import 'package:ourney/features/reminders/l10n/generated/reminders_localizations.dart';
import 'package:ourney/features/safety/l10n/generated/safety_localizations.dart';
import 'package:ourney/features/share_card/l10n/generated/share_card_localizations.dart';
import 'package:ourney/features/update/l10n/generated/update_localizations.dart';
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
  test('every user-facing feature has its own vi + en ARB pair', () {
    for (final dir in Directory(
      'lib/features',
    ).listSync().whereType<Directory>()) {
      final f = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
      // The app update controller ships before its hosted prompt widgets.
      if (f == 'update' && !Directory('${dir.path}/ui').existsSync()) {
        continue;
      }
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
        FeedbackL10n.of(ctx).feedback_title,
        UpdateL10n.of(ctx).update_ctaUpdate,
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

  test('English ARBs consistently use "squad" instead of "group"', () {
    final groupWord = RegExp(r'\bgroups?\b', caseSensitive: false);
    for (final (name, dir, file, _) in arbSets()) {
      final en = readArb('$dir/${file}_en.arb');
      for (final key in messageKeys(en)) {
        final raw = en[key];
        if (raw is! String) continue;
        // Strip ICU `{placeholder}` tokens before checking user-facing copy.
        final prose = raw.replaceAll(RegExp(r'\{[^}]+\}'), '');
        expect(
          groupWord.hasMatch(prose),
          isFalse,
          reason: '$name.$key still uses "group(s)": "$raw"',
        );
      }
    }
    expect(
      readArb('lib/features/groups/l10n/groups_en.arb').containsKey(
        'groups_eyebrow',
      ),
      isFalse,
    );
  });

  test(
    'gentle copy guard: reminder, streak, and widget l10n contain zero pressuring phrases or raw emojis',
    () {
      final bannedAllArbs = RegExp(
        r'sắp mất|sắp đứt|sắp hết hạn|cảnh báo streak|TẬP ĐI|Ra khỏi giường|cả nhóm đang chờ|'
        r'about to break|streak at risk|streak alert|streak-saver|whole squad is waiting|GO TRAIN|Get out of bed|'
        r'\u{1F525}',
        caseSensitive: false,
        unicode: true,
      );
      final bannedReminderWidget = RegExp(
        r'sắp mất|sắp đứt|sắp hết hạn|sẽ mất|cảnh báo streak|TẬP ĐI|đang chờ|'
        r'about to break|streak at risk|streak alert|GO TRAIN|whole squad is waiting|'
        r'midnight|nửa đêm|ends at|keeps it going',
        caseSensitive: false,
      );
      final bannedStreakDeadline = RegExp(
        r'\buntil\b|\bends\b|mất|còn mở đến|còn đến|mở đến',
        caseSensitive: false,
      );

      for (final (name, dir, file, _) in arbSets()) {
        for (final locale in ['vi', 'en']) {
          final arb = readArb('$dir/${file}_$locale.arb');
          for (final key in messageKeys(arb)) {
            final raw = arb[key];
            if (raw is! String) continue;
            expect(
              bannedAllArbs.hasMatch(raw),
              isFalse,
              reason: '$name.$key ($locale) contains pressuring copy: "$raw"',
            );
            final isReminderOrWidgetKey =
                name == 'reminders' ||
                name == 'widgets' ||
                key.startsWith('reminderBanner_') ||
                key.startsWith('streak_') ||
                key == 'groups_wallWaiting';
            if (isReminderOrWidgetKey) {
              expect(
                bannedReminderWidget.hasMatch(raw),
                isFalse,
                reason:
                    '$name.$key ($locale) contains banned reminder/widget phrase: "$raw"',
              );
            }
            final isStreakAlertOrBannerKey =
                (name == 'reminders' &&
                    (key.startsWith('reminders_alert') ||
                        key == 'reminders_permissionMessage' ||
                        key == 'reminders_channelDescription')) ||
                key.startsWith('reminderBanner_streak_') ||
                key == 'widgets_previewAtRiskBadge';
            if (isStreakAlertOrBannerKey) {
              expect(
                bannedStreakDeadline.hasMatch(raw),
                isFalse,
                reason:
                    '$name.$key ($locale) contains loss/deadline wording: "$raw"',
              );
            }
          }
        }
      }

      final nativeFiles = [
        'ios/OurneyWidgets/Theme/WidgetL10n.swift',
        'ios/OurneyWidgets/Localizable.xcstrings',
        'android/app/src/main/res/values/widget_strings.xml',
        'android/app/src/main/res/values-en/widget_strings.xml',
        'android/app/src/main/res/values-vi/widget_strings.xml',
      ];
      final bannedNativeCountdown = RegExp(
        r'Còn %1\$d|Còn \\\(pending\)|left today|\\\(pending\) left|số hành trình còn lại|remaining check-ins',
        caseSensitive: false,
      );
      for (final relPath in nativeFiles) {
        final content = File(relPath).readAsStringSync();
        expect(
          bannedReminderWidget.hasMatch(content),
          isFalse,
          reason: '$relPath contains banned pressuring reminder/widget phrase',
        );
        expect(
          bannedNativeCountdown.hasMatch(content),
          isFalse,
          reason: '$relPath contains countdown/"left" widget copy',
        );
      }

      // F-17 & F-06: native iOS Live Activity & Android Live Update views must
      // never render ticking countdown timers (countsDown / setUsesChronometer /
      // setChronometerCountDown) and Dynamic Island Expanded must use shared
      // title redaction (liveActivityDisplayTitle) rather than relying solely
      // on .privacySensitive().
      final iosLiveActivity = File(
        'ios/OurneyWidgets/Views/CheckInLiveActivity.swift',
      ).readAsStringSync();
      expect(
        iosLiveActivity.contains('countsDown'),
        isFalse,
        reason: 'CheckInLiveActivity.swift must not use ticking countsDown timer',
      );
      expect(
        iosLiveActivity.contains('timerInterval:'),
        isFalse,
        reason: 'CheckInLiveActivity.swift must not use timerInterval countdown',
      );
      expect(
        iosLiveActivity.contains('.privacySensitive('),
        isFalse,
        reason:
            'CheckInLiveActivity.swift must redact displayTitle directly to "Ourney" '
            'instead of relying on .privacySensitive() which unredacts on Face ID',
      );
      expect(
        RegExp(r'WidgetL10n\.liveActivityDisplayTitle\(')
            .allMatches(iosLiveActivity)
            .length,
        greaterThanOrEqualTo(2),
        reason:
            'Both Dynamic Island Expanded and Lock Screen Banner must redact via '
            'WidgetL10n.liveActivityDisplayTitle',
      );

      final androidLiveUpdate = File(
        'android/app/src/main/kotlin/com/hofang42/ourney/widgets/CheckInLiveUpdateManager.kt',
      ).readAsStringSync();
      expect(
        androidLiveUpdate.contains('setChronometerCountDown(true)'),
        isFalse,
        reason:
            'CheckInLiveUpdateManager.kt must not enable countdown chronometer',
      );
      expect(
        androidLiveUpdate.contains('setUsesChronometer(true)'),
        isFalse,
        reason: 'CheckInLiveUpdateManager.kt must not enable ticking chronometer',
      );

      // F-17: journeys ARBs must not contain "Xh left today" / "Còn X giờ" copy.
      for (final locale in ['vi', 'en']) {
        final journeysArb = readArb(
          'lib/features/journeys/l10n/journeys_$locale.arb',
        );
        expect(journeysArb.containsKey('journeys_endsInHours'), isFalse);
        expect(journeysArb.containsKey('journeys_endsSoon'), isFalse);
        expect(journeysArb.containsKey('journeys_openToday'), isTrue);
        for (final key in messageKeys(journeysArb)) {
          final val = journeysArb[key];
          if (val is! String) continue;
          expect(
            RegExp(
              r'left today|Còn \{hours\} giờ|Còn chưa tới 1 giờ',
              caseSensitive: false,
            ).hasMatch(val),
            isFalse,
            reason: 'journeys_$locale.arb.$key contains countdown copy: "$val"',
          );
        }
      }
    },
  );

  test(
    'B4 copy guard: VI ARBs use "check-in" (zero "điểm danh"), zero "giữ chuỗi"/"đúc"/"gãy chuỗi"/"mất chuỗi", streak banners have no digit, and unused minimalist_habit_quickSnapHint is removed',
    () {
      final bannedViArb = RegExp(
        r'điểm danh|giữ chuỗi|gãy chuỗi|mất chuỗi|\bđúc\b',
        caseSensitive: false,
        unicode: true,
      );
      for (final (name, dir, file, _) in arbSets()) {
        final vi = readArb('$dir/${file}_vi.arb');
        for (final key in messageKeys(vi)) {
          final raw = vi[key];
          if (raw is! String) continue;
          expect(
            bannedViArb.hasMatch(raw),
            isFalse,
            reason: '$name.$key (vi) contains banned B4 phrase: "$raw"',
          );
        }
      }

      for (final locale in ['vi', 'en']) {
        final appArb = readArb('lib/l10n/app_$locale.arb');
        for (final skin in [
          'quiet',
          'squad',
          'memory',
          'couple',
          'flexer',
          'minimal',
        ]) {
          final key = 'reminderBanner_streak_$skin';
          final val = appArb[key] as String;
          expect(
            RegExp(r'\d|\{streak\}').hasMatch(val),
            isFalse,
            reason: 'app_$locale.arb.$key must not contain any count: "$val"',
          );
        }
      }

      final minVi = readArb(
        'lib/personas/minimalist_habit/l10n/minimalist_habit_vi.arb',
      );
      final minEn = readArb(
        'lib/personas/minimalist_habit/l10n/minimalist_habit_en.arb',
      );
      expect(minVi.containsKey('minimalist_habit_quickSnapHint'), isFalse);
      expect(minEn.containsKey('minimalist_habit_quickSnapHint'), isFalse);
    },
  );
}
