import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/checkin/checkin_controller.dart';
import 'package:ourney_core/ourney_core.dart';

import 'fakes.dart';

CheckIn _ci(String id, String user, int day, {bool uploaded = true}) => CheckIn(
  id: id,
  journeyId: 'j1',
  userId: user,
  localDate: LocalDate(2026, 10, day),
  capturedAt: DateTime.utc(2026, 10, day, 3),
  photoPath: 'p/$id.jpg',
  thumbPath: 'p/${id}_t.jpg',
  uploaded: uploaded,
);

class _Me extends CurrentUserId {
  @override
  String? build() => 'me';
}

void main() {
  test('pending weight survives without listeners and clears', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(pendingWeightProvider('j1')), isNull);
    c.read(pendingWeightProvider('j1').notifier).setPendingWeight(72.5);
    expect(c.read(pendingWeightProvider('j1')), 72.5);
    expect(c.read(pendingWeightProvider('j2')), isNull);
    c.read(pendingWeightProvider('j1').notifier).clear();
    expect(c.read(pendingWeightProvider('j1')), isNull);
  });

  test('partner photos: others only, newest first', () async {
    final repo = FakeCheckInRepository(
      existing: [
        _ci('a', 'me', 16),
        _ci('b', 'her', 14),
        _ci('c', 'her', 15),
        _ci('d', 'her', 16, uploaded: false),
      ],
    );
    final c = ProviderContainer(
      overrides: [
        checkInRepositoryProvider.overrideWithValue(repo),
        currentUserIdProvider.overrideWith(_Me.new),
      ],
    );
    addTearDown(c.dispose);
    c.listen(partnerCheckInPhotosProvider('j1'), (_, _) {});
    final list = await c.read(partnerCheckInPhotosProvider('j1').future);
    expect([for (final x in list) x.id], ['c', 'b']);
  });

  test('partner photos: none without a user (local-only)', () async {
    final c = ProviderContainer(
      overrides: [
        checkInRepositoryProvider.overrideWithValue(
          FakeCheckInRepository(existing: [_ci('b', 'her', 14)]),
        ),
        currentUserIdProvider.overrideWith(_NoUser.new),
      ],
    );
    addTearDown(c.dispose);
    c.listen(partnerCheckInPhotosProvider('j1'), (_, _) {});
    expect(await c.read(partnerCheckInPhotosProvider('j1').future), isEmpty);
  });
}

class _NoUser extends CurrentUserId {
  @override
  String? build() => null;
}
