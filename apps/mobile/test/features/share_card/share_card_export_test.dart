import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/share_card/data/share_card_exporter.dart';
import 'package:ourney/features/share_card/domain/share_card_content.dart';
import 'package:ourney/features/share_card/ui/share_card.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import 'share_card_fakes.dart';

final _boundaryKey = GlobalKey();

Future<RenderRepaintBoundary> _pumpCard(
  WidgetTester tester,
  ShareCardFormat format,
) async {
  final j = testJourney();
  final content = ShareCardContent.from(
    journey: j,
    membership: testMembership(j),
    streak: computeStreak(
      start: j.startDate,
      durationDays: j.durationDays,
      today: const LocalDate(2026, 10, 16),
      dates: [for (var d = 10; d <= 15; d++) LocalDate(2026, 10, d)],
    ),
    dayNumber: 7,
    checkIns: const [],
  );
  tester.view.physicalSize = const Size(400, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    testApp(
      FittedBox(
        child: RepaintBoundary(
          key: _boundaryKey,
          child: ShareCard(content: content, format: format, blur: false),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _boundaryKey.currentContext!.findRenderObject()!
      as RenderRepaintBoundary;
}

void main() {
  for (final format in ShareCardFormat.values) {
    testWidgets('${format.name}: renders at exactly '
        '${format.pixelWidth}x${format.pixelHeight} and writes a file', (
      tester,
    ) async {
      final boundary = await _pumpCard(tester, format);
      expect(boundary.size, format.logicalSize);
      expect(tester.takeException(), isNull);

      final dir = await tester.runAsync(
        () => Directory.systemTemp.createTemp('share_card_test'),
      );
      addTearDown(() => dir!.deleteSync(recursive: true));
      final exporter = ShareCardExporter(tempDirectory: () async => dir!);
      final file = await tester.runAsync(
        () => exporter.export(boundary, format, baseName: 'card'),
      );
      expect(file!.image.width, format.pixelWidth);
      expect(file.image.height, format.pixelHeight);
      // A flat gradient card compresses well: PNG under 1 MB.
      expect(file.image.format, ShareCardImageFormat.png);
      expect(file.mimeType, 'image/png');
      expect(file.path, endsWith('card.png'));
      final bytes = await tester.runAsync(() => File(file.path).readAsBytes());
      expect(bytes!.length, lessThan(1000000));
      // Decode the PNG header back: exact pixel size.
      final codec = await tester.runAsync(() => ui.instantiateImageCodec(bytes));
      final frame = await tester.runAsync(() => codec!.getNextFrame());
      expect(frame!.image.width, format.pixelWidth);
      expect(frame.image.height, format.pixelHeight);
      frame.image.dispose();
    });
  }

  testWidgets('falls back to JPEG when the PNG is over the size budget', (
    tester,
  ) async {
    final boundary = await _pumpCard(tester, ShareCardFormat.feed);
    final qualities = <int>[];
    final exporter = ShareCardExporter(
      maxBytes: 10,
      jpegEncoder: (png, {required width, required height, required quality}) async {
        expect((width, height), (1080, 1350));
        qualities.add(quality);
        // Pretend the second quality fits.
        return Uint8List(quality == 85 ? 8 : 20);
      },
    );
    final image = await tester.runAsync(
      () => exporter.capture(boundary, ShareCardFormat.feed),
    );
    final encoded = await tester.runAsync(() => exporter.encode(image!));
    image!.dispose();
    expect(qualities, [92, 85]);
    expect(encoded!.format, ShareCardImageFormat.jpeg);
    expect(encoded.bytes.length, 8);
  });

  testWidgets('keeps the PNG when JPEG encoding is unavailable', (
    tester,
  ) async {
    final boundary = await _pumpCard(tester, ShareCardFormat.feed);
    final exporter = ShareCardExporter(
      maxBytes: 10,
      jpegEncoder: (png, {required width, required height, required quality}) =>
          throw UnsupportedError('no plugin'),
    );
    final image = await tester.runAsync(
      () => exporter.capture(boundary, ShareCardFormat.feed),
    );
    final encoded = await tester.runAsync(() => exporter.encode(image!));
    image!.dispose();
    expect(encoded!.format, ShareCardImageFormat.png);
  });

  testWidgets('capture rejects a boundary that is not the card size', (
    tester,
  ) async {
    final boundary = await _pumpCard(tester, ShareCardFormat.feed);
    // Feed boundary captured as a story: 1080x1350 != 1080x1920.
    final error = await tester.runAsync(() async {
      try {
        await ShareCardExporter().capture(boundary, ShareCardFormat.story);
        return null;
      } on StateError catch (e) {
        return e;
      }
    });
    expect(error, isA<StateError>());
  });
}
