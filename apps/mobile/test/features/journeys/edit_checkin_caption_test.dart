import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import 'day_viewer_test.dart' show pumpDayViewer, viewerPhoto, viewerTimeout;
import 'journeys_fakes.dart';

class CaptionRepository extends FakeCheckInRepository {
  CaptionRepository(super.photos);
  OurneyErrorCode? failure;
  Completer<void>? gate;
  final List<String?> captions = [];

  @override
  Future<CheckIn> updateCaption(String id, String? caption) async {
    captions.add(caption);
    await gate?.future;
    if (failure case final code?) throw OurneyException(code);
    return super.updateCaption(id, caption);
  }
}

Finder key(String value) => find.byKey(ValueKey(value));

Future<void> tap(WidgetTester tester, String value) async {
  await tester.ensureVisible(key(value));
  await tester.tap(key(value));
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  for (final failure in [null, OurneyErrorCode.offline]) {
    testWidgets('save completing during dismissal keeps viewer: $failure', (
      tester,
    ) async {
      final photo = viewerPhoto(caption: 'Before');
      final repo = CaptionRepository([photo])
        ..gate = Completer<void>()
        ..failure = failure;
      await pumpDayViewer(
        tester,
        photos: [photo],
        repository: repo,
        reduced: false,
      );
      await tap(tester, 'journey-day-edit-caption');
      await tester.enterText(key('edit-checkin-caption-field'), 'After');
      await tap(tester, 'edit-checkin-caption-save');
      // BottomSheet's drag onClosing calls pop directly. Complete the request
      // while that outgoing route is still mounted during its exit animation.
      Navigator.of(tester.element(key('edit-checkin-caption-sheet'))).pop();
      repo.gate!.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(key('journey-day-viewer'), findsOneWidget);
      expect(key('edit-checkin-caption-sheet'), findsNothing);
      expect(tester.takeException(), isNull);
    }, timeout: viewerTimeout);
  }

  testWidgets('add and edit save the text; clear saves null', (tester) async {
    final photo = viewerPhoto(caption: 'Before');
    final repo = CaptionRepository([photo]);
    await pumpDayViewer(
      tester,
      photos: [photo],
      repository: repo,
      photoStream: () => repo.watchForJourney('j1'),
    );
    await tap(tester, 'journey-day-edit-caption');
    await tester.enterText(key('edit-checkin-caption-field'), 'After');
    await tap(tester, 'edit-checkin-caption-save');
    expect(repo.captions, ['After']);
    expect(find.text('After'), findsOneWidget);
    await tap(tester, 'journey-day-edit-caption');
    await tap(tester, 'edit-checkin-caption-clear');
    expect(repo.captions, ['After', null]);
    expect(key('journey-day-add-caption'), findsOneWidget);
    expect(
      tester.getSize(key('journey-day-add-caption')).height,
      greaterThanOrEqualTo(48),
    );
    await tap(tester, 'journey-day-add-caption');
    await tester.enterText(key('edit-checkin-caption-field'), 'New caption');
    await tap(tester, 'edit-checkin-caption-save');
    expect(find.text('New caption'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, timeout: viewerTimeout);

  for (final code in [OurneyErrorCode.contentPolicy, OurneyErrorCode.offline]) {
    testWidgets('$code keeps text and allows a corrected save', (tester) async {
      final photo = viewerPhoto();
      final repo = CaptionRepository([photo])..failure = code;
      await pumpDayViewer(tester, photos: [photo], repository: repo);
      await tap(tester, 'journey-day-add-caption');
      await tester.enterText(key('edit-checkin-caption-field'), 'Keep this');
      await tap(tester, 'edit-checkin-caption-save');
      expect(key('edit-checkin-caption-error'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(key('edit-checkin-caption-field'))
            .controller!
            .text,
        'Keep this',
      );
      repo.failure = null;
      await tester.enterText(key('edit-checkin-caption-field'), 'Revised');
      await tap(tester, 'edit-checkin-caption-save');
      expect(repo.captions, ['Keep this', 'Revised']);
      expect(key('edit-checkin-caption-sheet'), findsNothing);
    }, timeout: viewerTimeout);
  }

  testWidgets('a caption with many lines is shown in full', (tester) async {
    final lines = [for (var i = 1; i <= 10; i++) 'Dòng $i'].join('\n');
    final photo = viewerPhoto(caption: lines);
    await pumpDayViewer(tester, photos: [photo], size: const Size(360, 780));
    final text = tester.widget<Text>(key('journey-day-caption'));
    expect(text.data, lines);
    expect(text.maxLines, isNull);
    expect(text.overflow, isNull);
    expect(tester.takeException(), isNull);
  }, timeout: viewerTimeout);

  testWidgets('no-op saves close without writing', (tester) async {
    final captioned = viewerPhoto(caption: 'Before');
    final repo = CaptionRepository([captioned]);
    await pumpDayViewer(tester, photos: [captioned], repository: repo);
    await tap(tester, 'journey-day-edit-caption');
    await tester.enterText(key('edit-checkin-caption-field'), '  Before  ');
    await tap(tester, 'edit-checkin-caption-save');
    expect(key('edit-checkin-caption-sheet'), findsNothing);
    expect(repo.captions, isEmpty);
    expect(tester.takeException(), isNull);
  }, timeout: viewerTimeout);

  testWidgets('keep photo only on a photo that never had a caption is a no-op', (
    tester,
  ) async {
    final photo = viewerPhoto();
    final repo = CaptionRepository([photo]);
    await pumpDayViewer(tester, photos: [photo], repository: repo);
    await tap(tester, 'journey-day-add-caption');
    await tester.enterText(key('edit-checkin-caption-field'), 'Draft');
    await tester.pump();
    await tap(tester, 'edit-checkin-caption-clear');
    expect(key('edit-checkin-caption-sheet'), findsNothing);
    await tap(tester, 'journey-day-add-caption');
    await tap(tester, 'edit-checkin-caption-save');
    expect(key('edit-checkin-caption-sheet'), findsNothing);
    expect(repo.captions, isEmpty);
    expect(tester.takeException(), isNull);
  }, timeout: viewerTimeout);

  for (final code in [
    OurneyErrorCode.ended,
    OurneyErrorCode.forbidden,
    OurneyErrorCode.notFound,
    OurneyErrorCode.invalidCapturedAt,
  ]) {
    testWidgets('$code closes a stale editor and keeps the viewer', (
      tester,
    ) async {
      final photo = viewerPhoto();
      final repo = CaptionRepository([photo])..failure = code;
      await pumpDayViewer(tester, photos: [photo], repository: repo);
      await tap(tester, 'journey-day-add-caption');
      await tester.enterText(key('edit-checkin-caption-field'), 'Caption');
      await tap(tester, 'edit-checkin-caption-save');
      expect(key('edit-checkin-caption-sheet'), findsNothing);
      expect(key('journey-day-viewer'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 5));
    }, timeout: viewerTimeout);
  }

  for (final reason in ['ended', 'moderated', 'left']) {
    testWidgets('caption action hidden for $reason', (tester) async {
      await pumpDayViewer(
        tester,
        journey: testJourney(
          status: reason == 'ended'
              ? JourneyStatus.ended
              : JourneyStatus.active,
        ),
        photos: [viewerPhoto(moderated: reason == 'moderated')],
        activeMember: reason != 'left',
      );
      expect(key('journey-day-add-caption'), findsNothing);
      expect(key('journey-day-edit-caption'), findsNothing);
    }, timeout: viewerTimeout);
  }

  testWidgets(
    'policy failure can keep just the photo without losing typed text',
    (tester) async {
      final photo = viewerPhoto(caption: 'Before');
      final repo = CaptionRepository([photo])
        ..failure = OurneyErrorCode.contentPolicy;
      await pumpDayViewer(tester, photos: [photo], repository: repo);
      await tap(tester, 'journey-day-edit-caption');
      await tester.enterText(key('edit-checkin-caption-field'), 'Typed text');
      await tap(tester, 'edit-checkin-caption-save');
      repo.failure = OurneyErrorCode.offline;
      await tap(tester, 'edit-checkin-caption-clear');
      expect(
        tester
            .widget<TextField>(key('edit-checkin-caption-field'))
            .controller!
            .text,
        'Typed text',
      );
      repo.failure = null;
      await tap(tester, 'edit-checkin-caption-clear');
      expect(repo.captions, ['Typed text', null, null]);
      expect(key('edit-checkin-caption-sheet'), findsNothing);
    },
    timeout: viewerTimeout,
  );

  testWidgets('public hint and today prompt are shown', (tester) async {
    final photo = viewerPhoto();
    await pumpDayViewer(
      tester,
      journey: testJourney(visibility: JourneyVisibility.link),
      photos: [photo],
      repository: CaptionRepository([photo]),
      editCaption: true,
    );
    expect(find.text('Hôm nay bạn tập gì?'), findsOneWidget);
    expect(find.text('Chú thích sẽ hiện trên trang chia sẻ.'), findsOneWidget);
    expect(key('edit-checkin-caption-clear'), findsNothing);
  }, timeout: viewerTimeout);

  for (final brightness in Brightness.values) {
    testWidgets('caption sheet 360dp 1.35 $brightness and keyboard', (
      tester,
    ) async {
      final photo = viewerPhoto(
        date: testToday.addDays(-1),
        caption: 'A memory',
      );
      await pumpDayViewer(
        tester,
        photos: [photo],
        date: photo.localDate,
        repository: CaptionRepository([photo]),
        size: const Size(360, 780),
        scale: 1.35,
        brightness: brightness,
        editCaption: true,
      );
      expect(key('edit-checkin-caption-sheet'), findsOneWidget);
      expect(find.text('Buổi tập hôm đó thế nào?'), findsOneWidget);
      expect(
        tester.widget<UiButton>(key('edit-checkin-caption-save')).onPressed,
        isNotNull,
      );
      await tester.tap(key('edit-checkin-caption-field'));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.ensureVisible(key('edit-checkin-caption-save'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }, timeout: viewerTimeout);
  }
}
