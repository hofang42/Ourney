// Regenerates every localization class of the app:
//
//   dart run tool/gen_l10n.dart            # all ARB sets
//   dart run tool/gen_l10n.dart journeys   # only lib/features/journeys/l10n
//   dart run tool/gen_l10n.dart app        # only lib/l10n (shared strings)
//
// `flutter gen-l10n` supports exactly one template ARB per output class and
// ignores CLI flags when an l10n.yaml exists, so the project has no l10n.yaml
// and this script calls gen-l10n once per ARB set with explicit flags:
//
//   lib/l10n/app_{vi,en}.arb                       -> AppLocalizations
//   lib/features/<f>/l10n/<f>_{vi,en}.arb          -> <F>L10n
//   lib/personas/<p>/l10n/<p>_{vi,en}.arb          -> <P>L10n
//
// Output goes to `<arb dir>/generated/` and is committed. Vietnamese is the
// template. Generated `supportedLocales` lists are alphabetical (Flutter
// 3.47 ignores `--preferred-supported-locales` on the CLI), so the app's
// fallback order vi -> en is set in lib/app/localization.dart instead.
import 'dart:io';

Future<void> main(List<String> args) async {
  final root = File.fromUri(Platform.script).parent.parent;
  final sets = <_ArbSet>[
    const _ArbSet(
      name: 'app',
      dir: 'lib/l10n',
      prefix: 'app',
      outputClass: 'AppLocalizations',
    ),
    ..._folderSets(root, 'lib/features'),
    ..._folderSets(root, 'lib/personas'),
  ]..sort((a, b) => a.name.compareTo(b.name));

  final selected = args.isEmpty
      ? sets
      : sets.where((s) => args.contains(s.name)).toList();
  if (selected.isEmpty) {
    stderr.writeln(
      'No ARB set named ${args.join(', ')}. '
      'Known: ${sets.map((s) => s.name).join(', ')}',
    );
    exitCode = 64;
    return;
  }

  for (final set in selected) {
    stdout.writeln(
      'gen-l10n ${set.name} -> ${set.dir}/generated '
      '(${set.outputClass})',
    );
    final result = await Process.run(
      'flutter',
      [
        'gen-l10n',
        '--arb-dir=${set.dir}',
        '--template-arb-file=${set.prefix}_vi.arb',
        '--output-dir=${set.dir}/generated',
        '--output-localization-file=${set.prefix}_localizations.dart',
        '--output-class=${set.outputClass}',
        '--no-nullable-getter',
        '--format',
      ],
      workingDirectory: root.path,
      runInShell: true,
    );
    final out = '${result.stdout}${result.stderr}'
        .split('\n')
        .where((l) => !_noise(l))
        .join('\n')
        .trim();
    if (out.isNotEmpty) stdout.writeln(out);
    if (result.exitCode != 0) {
      stderr.writeln('gen-l10n failed for ${set.name}');
      exitCode = result.exitCode;
      return;
    }
  }
}

/// One set per sub-folder of [parent] that has an `l10n` folder.
Iterable<_ArbSet> _folderSets(Directory root, String parent) =>
    Directory('${root.path}/$parent')
        .listSync()
        .whereType<Directory>()
        .where((d) => Directory('${d.path}/l10n').existsSync())
        .map((d) {
          final name = d.uri.pathSegments.where((s) => s.isNotEmpty).last;
          return _ArbSet(
            name: name,
            dir: '$parent/$name/l10n',
            prefix: name,
            outputClass: '${_pascal(name)}L10n',
          );
        });

bool _noise(String line) =>
    line.contains('Woah! You appear to be trying to run flutter as root') ||
    line.contains('We strongly recommend running the flutter tool') ||
    line.trim() == '/' ||
    line.trim() == '📎';

String _pascal(String snake) => snake
    .split('_')
    .where((p) => p.isNotEmpty)
    .map((p) => p[0].toUpperCase() + p.substring(1))
    .join();

class _ArbSet {
  const _ArbSet({
    required this.name,
    required this.dir,
    required this.prefix,
    required this.outputClass,
  });

  final String name;
  final String dir;
  final String prefix;
  final String outputClass;
}
