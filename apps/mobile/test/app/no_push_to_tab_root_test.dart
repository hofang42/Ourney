import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A dock tab root (`/profile`, `/groups`, ...) opened with `push` stacks a
/// second copy of the screen above the shell while the dock keeps showing
/// the previous tab. Tab roots must be reached with `go` / `goBranch`.
void main() {
  test('no feature pushes a dock tab root route', () {
    final tabRoot = RegExp(
      r'''\.push(?:<\w+>)?\(\s*(?:AppRoutes\.(?:profile|groups|journeys|inbox|capture)\b(?!\w*\()|['"]/(?:profile|groups|journeys|inbox|capture)['"])''',
    );
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (tabRoot.hasMatch(f.readAsStringSync())) offenders.add(f.path);
    }
    expect(offenders, isEmpty);
  });
}
