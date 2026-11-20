import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A dock tab root (`/profile`, `/groups`, ...) opened with `push` /
/// `pushReplacement` / `replace` stacks a second copy of the screen above the
/// shell while the dock keeps showing the previous tab. Tab roots must be
/// reached with `go` / `goBranch`.
void main() {
  const tabNames = ['profile', 'groups', 'journeys', 'inbox', 'capture'];

  test('no feature pushes a dock tab root route (aliases included)', () {
    final sources = <String, String>{};
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      sources[f.path] = f
          .readAsLinesSync()
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');
    }

    // Tab-root paths, then every `static const x = <tab root>;` alias of one.
    final tabPaths = {
      for (final n in tabNames) "'/$n'",
      for (final n in tabNames) '"/$n"',
    };
    final names = <String>{for (final n in tabNames) 'AppRoutes.$n'};
    final alias = RegExp(
      r'''static\s+const\s+(?:String\s+)?(\w+)\s*=\s*([\w.]+|'[^']*'|"[^"]*")\s*;''',
    );
    var grew = true;
    while (grew) {
      grew = false;
      for (final entry in sources.entries) {
        for (final m in alias.allMatches(entry.value)) {
          final owner = RegExp(
            r'(?:class|extension)\s+(\w+)[^{]*\{(?:(?!\bclass\b)[\s\S])*?' +
                RegExp.escape(m.group(0)!),
          ).allMatches(entry.value).lastOrNull?.group(1);
          if (owner == null) continue;
          final target = m.group(2)!;
          if ((tabPaths.contains(target) || names.contains(target)) &&
              names.add('$owner.${m.group(1)}')) {
            grew = true;
          }
        }
      }
    }

    final nameAlt = names.map(RegExp.escape).join('|');
    final pathAlt = tabNames.map((n) => '/$n').join('|');
    final call = RegExp(
      '\.(?:push|pushReplacement|replace|pushReplacementNamed)'
              r'(?:<[^>(]*>)?\(\s*(?:(?:' +
          nameAlt +
          r')\b(?!\w*\()|' +
          '''['"](?:$pathAlt)['"])''',
    );
    final offenders = [
      for (final e in sources.entries)
        if (call.hasMatch(e.value)) e.key,
    ];
    expect(offenders, isEmpty, reason: 'aliases: $names');
    expect(names, contains('SocialPaths.inbox'));
  });
}
