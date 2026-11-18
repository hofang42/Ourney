import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/journey_clock.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/camera/camera_providers.dart';
import 'package:ourney_core/ourney_core.dart';

import '../checkin/fakes.dart';

// 7 days from 2026-10-01: the last day is 2026-10-07 in the journey's zone.
Journey _week(String id, String timezone) => Journey(
  id: id,
  ownerId: 'me',
  kind: JourneyKind.solo,
  templateId: TemplateId.custom,
  title: id,
  emoji: 'x',
  startDate: const LocalDate(2026, 10, 1),
  durationDays: 7,
  timezone: timezone,
  visibility: JourneyVisibility.private,
  status: JourneyStatus.active,
  hideMetricDefault: false,
);

ProviderContainer _container(List<Journey> js, DateTime now) {
  final c = ProviderContainer.test(
    overrides: [
      journeyRepositoryProvider.overrideWithValue(
        FakeJourneyRepository(journeys: js),
      ),
      journeysClockProvider.overrideWithValue(Clock.fixed(now)),
    ],
  );
  return c;
}

Future<List<Journey>> _keep(
  ProviderContainer c,
  StreamProvider<List<Journey>> p,
) {
  c.listen(p, (_, _) {});
  return c.read(p.future);
}

void main() {
  test('an expired fixed-term journey is hidden from the camera', () async {
    // 2026-10-08 in Ho Chi Minh: the window is over.
    final c = _container([
      _week('hcm', 'Asia/Ho_Chi_Minh'),
    ], DateTime.utc(2026, 10, 8, 1));
    expect(await _keep(c, captureJourneysProvider), isEmpty);
    final picker = await _keep(c, capturePickerJourneysProvider);
    expect(picker.single.status, JourneyStatus.ended);
  });

  test('a journey in another zone on its last day is still shown', () async {
    // 2026-10-07 22:00 UTC: already 10-08 in Ho Chi Minh, still 10-07 in
    // Los Angeles. The device date must not decide.
    final c = _container([
      _week('hcm', 'Asia/Ho_Chi_Minh'),
      _week('la', 'America/Los_Angeles'),
    ], DateTime.utc(2026, 10, 7, 22));
    final shown = await _keep(c, captureJourneysProvider);
    expect([for (final j in shown) j.id], ['la']);
  });
}
