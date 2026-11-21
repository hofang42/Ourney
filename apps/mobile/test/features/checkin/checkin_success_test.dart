import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/checkin/checkin_progress.dart';
import 'package:ourney/features/checkin/checkin_success.dart';
import 'package:ourney/ui/ui.dart' show UiPolaroid, UiStamp;
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import 'fakes.dart';

void main() {
  // One template per skin.
  final byTemplate = <PersonaSkinId, TemplateId>{};
  for (final t in TemplateId.values) {
    byTemplate.putIfAbsent(personaSkinForTemplate(t), () => t);
  }

  for (final entry in byTemplate.entries) {
    for (final brightness in Brightness.values) {
      for (final milestone in <Milestone?>[null, Milestone.sevenDays]) {
        testWidgets('${entry.key.name} ${brightness.name} '
            '${milestone?.name ?? 'plain'}: done fits 320dp at 1.35x', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 640);
          addTearDown(tester.view.reset);
          tester.platformDispatcher.textScaleFactorTestValue = 1.35;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final journey = testJourney(templateId: entry.value);
          final day = journey.startDate.addDays(6);
          await tester.pumpWidget(
            ProviderScope(
              child: testApp(
                CheckinSuccessView(
                  outcome: CheckInOutcome(
                    checkIn: testCheckIn(day),
                    streakBefore: 6,
                    streakAfter: 7,
                    milestone: milestone,
                  ),
                  journey: journey,
                  haptics: false,
                  onDone: () {},
                  onShare: () {},
                ),
                brightness: brightness,
              ),
            ),
          );
          await tester.pump();
          expect(
            find.byKey(const ValueKey('checkin-success-screen')),
            findsOneWidget,
          );
          expect(find.byKey(const ValueKey('checkin-streak')), findsOneWidget);
          expect(find.byKey(const ValueKey('checkin-done')), findsOneWidget);
          expect(
            find.byKey(const ValueKey('checkin-milestone')),
            milestone == null ? findsNothing : findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('checkin-share')),
            milestone == null ? findsNothing : findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.pump(CheckinSuccessView.autoCloseDelay);
        });
      }
    }
  }

  for (final locale in const [Locale('en'), Locale('vi')]) {
    for (final scale in const [1.0, 1.35]) {
      testWidgets('memory done with a real 300x400 photo: rotated polaroid, '
          'title, stamp never overlap (320dp ${locale.languageCode} x$scale)', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 640);
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final dir = Directory.systemTemp.createTempSync('ourney_ci');
        addTearDown(() {
          try {
            dir.deleteSync(recursive: true);
          } on FileSystemException {
            // Windows may still hold the decoded file; the OS temp cleans up.
          }
        });
        final file = File('${dir.path}/photo.png');
        await tester.runAsync(() async {
          final rec = ui.PictureRecorder();
          ui.Canvas(rec).drawRect(
            const Rect.fromLTWH(0, 0, 300, 400),
            ui.Paint()..color = const Color(0xFF336699),
          );
          final img = await rec.endRecording().toImage(300, 400);
          final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
          file.writeAsBytesSync(bytes!.buffer.asUint8List());
        });
        final journey = testJourney(templateId: TemplateId.travel);
        final day = journey.startDate.addDays(11);
        final base = testCheckIn(day);
        final checkIn = CheckIn(
          id: base.id,
          journeyId: base.journeyId,
          userId: base.userId,
          localDate: base.localDate,
          capturedAt: base.capturedAt,
          photoPath: base.photoPath,
          thumbPath: base.thumbPath,
          localPhotoFile: file.path,
          uploaded: false,
        );
        await tester.pumpWidget(
          ProviderScope(
            child: testApp(
              CheckinSuccessView(
                outcome: CheckInOutcome(
                  checkIn: checkIn,
                  streakBefore: 1,
                  streakAfter: 2,
                  photoOfDay: 2,
                ),
                journey: journey,
                haptics: false,
                onDone: () {},
                onShare: () {},
              ),
              locale: locale,
            ),
          ),
        );
        // The photo decodes on a real isolate: let it finish, then pump.
        for (var n = 0; n < 40; n++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump();
          if (tester.widget<RawImage>(find.byType(RawImage).first).image !=
              null) {
            break;
          }
        }
        final raw = tester.widget<RawImage>(find.byType(RawImage).first);
        expect(raw.image, isNotNull);

        Rect rotated(Finder f) {
          final box = tester.renderObject<RenderBox>(f);
          return MatrixUtils.transformRect(
            box.getTransformTo(null),
            Offset.zero & box.size,
          );
        }

        final polaroid = rotated(find.byType(UiPolaroid));
        final stamp = rotated(
          find
              .descendant(
                of: find.byType(UiStamp),
                matching: find.byType(Container),
              )
              .first,
        );
        final title = rotated(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data == 'Chain kept.' || w.data == 'Giữ được chuỗi.'),
          ),
        );
        final streak = rotated(find.byKey(const ValueKey('checkin-streak')));
        expect(polaroid.bottom, lessThanOrEqualTo(stamp.top));
        expect(stamp.bottom, lessThanOrEqualTo(title.top));
        expect(title.bottom, lessThanOrEqualTo(streak.top));
        expect(stamp.left, greaterThanOrEqualTo(0));
        expect(stamp.right, lessThanOrEqualTo(320));
        expect(tester.takeException(), isNull);
        await tester.pump(CheckinSuccessView.autoCloseDelay);
      });
    }
  }
}
