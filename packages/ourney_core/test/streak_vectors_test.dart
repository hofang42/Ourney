import 'dart:convert';
import 'dart:io';

import 'package:ourney_core/ourney_core.dart';
import 'package:test/test.dart';

void main() {
  // `dart test` runs with the package root as cwd.
  final file = File('../../docs/contracts/streak_vectors.json');
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final vectors = (json['vectors'] as List).cast<Map<String, dynamic>>();

  test('contract file has vectors', () => expect(vectors, isNotEmpty));

  for (final v in vectors) {
    test('vector: ${v['name']}', () {
      final s = computeStreak(
        start: LocalDate.parse(v['start'] as String),
        durationDays: v['duration'] as int?,
        today: LocalDate.parse(v['today'] as String),
        dates: (v['dates'] as List).map((e) => LocalDate.parse(e as String)),
      );
      expect(s.current, v['current'], reason: 'current');
      expect(s.best, v['best'], reason: 'best');
      expect(s.completed, v['completed'], reason: 'completed');
    });
  }
}
