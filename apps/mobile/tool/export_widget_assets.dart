// Pure-Dart asset exporter for Ourney V1 Home-Screen Widgets, Lock-Screen
// Widgets & Live Activities (§5.3.2).
//
// Extracts the authoritative 24x24 vector icon primitives, sticker colors,
// two-tone flame core, interior ink strokes, and Light/Dark + 6x3 UiSkin
// palettes from `lib/ui/components/ourney_icons.dart`, `lib/ui/tokens.dart`,
// and `lib/ui/skins.dart`.
//
// Usage:
//   dart run tool/export_widget_assets.dart
//     -> writes apps/mobile/tool/widget_icon_specs.json
//   dart run tool/export_widget_assets.dart --stdout
//     -> prints JSON spec to stdout without touching disk
import 'dart:convert';
import 'dart:io';

/// The 17 Ourney vector icons used across iOS WidgetKit/ActivityKit and Android
/// Jetpack Glance/Live Updates (§5.3.2). Zero SF Symbols, zero Material icons,
/// zero emojis.
const List<String> kExportedWidgetIconNames = [
  'flame',
  'camera',
  'check',
  'check-circle',
  'clock',
  'journeys',
  'squad',
  'chevron-right',
  'close',
  'lock',
  'sparkle',
  'type-weight',
  'type-study',
  'type-trip',
  'type-couple',
  'type-workout',
  'type-custom',
];

class _IconPrimitiveSpec {
  const _IconPrimitiveSpec.path(this.d, {this.fill = true});

  factory _IconPrimitiveSpec.circle(double cx, double cy, double r) {
    final left = _fmt(cx - r);
    final y = _fmt(cy);
    final rad = _fmt(r);
    final diam = _fmt(r * 2);
    final negDiam = _fmt(-r * 2);
    return _IconPrimitiveSpec.path(
      'M$left $y a$rad $rad 0 1 0 $diam 0 a$rad $rad 0 1 0 $negDiam 0Z',
    );
  }

  final String d;
  final bool fill;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Map<String, Object?> toJson() => {'d': d, 'fill': fill};
}

class _WidgetIconSpec {
  const _WidgetIconSpec({
    required this.name,
    required this.stickerHex,
    required this.primitives,
    this.openStrokeOnly = false,
    this.corePath,
    this.coreHex,
    this.interiorInkPath,
  });

  final String name;
  final String stickerHex;
  final List<_IconPrimitiveSpec> primitives;
  final bool openStrokeOnly;
  final String? corePath;
  final String? coreHex;
  final String? interiorInkPath;

  Map<String, Object?> toJson() => {
    'name': name,
    'viewBox': '0 0 24 24',
    'stickerHex': stickerHex,
    'openStrokeOnly': openStrokeOnly,
    'primitives': [for (final p in primitives) p.toJson()],
    if (corePath != null) 'corePath': corePath,
    if (coreHex != null) 'coreHex': coreHex,
    if (interiorInkPath != null) 'interiorInkPath': interiorInkPath,
  };
}

/// Authoritative 24x24 vector primitives mirrored from
/// `lib/ui/components/ourney_icons.dart`.
final List<_WidgetIconSpec> _iconSpecs = [
  const _WidgetIconSpec(
    name: 'flame',
    stickerHex: '#C2452B',
    primitives: [
      _IconPrimitiveSpec.path(
        'M12 21c-4.4 0-7-2.6-7-6.5 0-3 2-5.2 4.3-7.7.1 2 1.1 3 2 3.5.4-3.5 2.1-5.8 4.3-7.3.1 3.6 3.4 5.7 3.4 10 0 4.8-3 8-7 8Z',
      ),
    ],
    corePath:
        'M12 18.6c-2 0-3.3-1.2-3.3-3 0-1.4.8-2.5 2-3.6.1 1 .6 1.6 1.2 1.9.2-1.7 1-2.8 2-3.6.1 1.7 1.8 2.8 1.8 5.1 0 2-1.5 3.2-3.7 3.2Z',
    coreHex: '#FF9F1C',
  ),
  _WidgetIconSpec(
    name: 'camera',
    stickerHex: '#10B981',
    primitives: [
      const _IconPrimitiveSpec.path('M4 7.5h3l1.5-2h7l1.5 2h3v11H4Z'),
      _IconPrimitiveSpec.circle(12, 13, 3.5),
    ],
    interiorInkPath: _IconPrimitiveSpec.circle(12, 13, 3.2).d,
  ),
  const _WidgetIconSpec(
    name: 'check',
    stickerHex: '#10B981',
    primitives: [
      _IconPrimitiveSpec.path('m6 12.5 4 4 8-9', fill: false),
    ],
    openStrokeOnly: true,
  ),
  _WidgetIconSpec(
    name: 'check-circle',
    stickerHex: '#10B981',
    primitives: [
      _IconPrimitiveSpec.circle(12, 12, 9),
      const _IconPrimitiveSpec.path('m8 12.5 3 3 5-6'),
    ],
  ),
  _WidgetIconSpec(
    name: 'clock',
    stickerHex: '#2AA7E0',
    primitives: [
      _IconPrimitiveSpec.circle(12, 12, 8),
      const _IconPrimitiveSpec.path('M12 7v5l3.5 2M9 2h6', fill: false),
    ],
    interiorInkPath: 'M12 7v5l3.5 2',
  ),
  const _WidgetIconSpec(
    name: 'journeys',
    stickerHex: '#C2452B',
    primitives: [
      _IconPrimitiveSpec.path(
        'M3.5 5.5 9 3l6 2.5L20.5 3v15.5L15 21l-6-2.5L3.5 21Z',
      ),
      _IconPrimitiveSpec.path('M9 3v15.5M15 5.5V21'),
      _IconPrimitiveSpec.path('m6 14 2-2 3 2 4-5 2 2'),
    ],
  ),
  _WidgetIconSpec(
    name: 'squad',
    stickerHex: '#FF9F1C',
    primitives: [
      _IconPrimitiveSpec.circle(9, 8, 3),
      _IconPrimitiveSpec.circle(17, 9, 2.5),
      const _IconPrimitiveSpec.path(
        'M3.5 19c.4-4 2.2-6 5.5-6s5.1 2 5.5 6M14 14c3.7-.5 5.8 1.2 6.3 4.5',
      ),
    ],
  ),
  const _WidgetIconSpec(
    name: 'chevron-right',
    stickerHex: '#2AA7E0',
    primitives: [
      _IconPrimitiveSpec.path('m9 5 7 7-7 7', fill: false),
    ],
    openStrokeOnly: true,
  ),
  const _WidgetIconSpec(
    name: 'close',
    stickerHex: '#C2452B',
    primitives: [
      _IconPrimitiveSpec.path('m5 5 14 14M19 5 5 19', fill: false),
    ],
    openStrokeOnly: true,
  ),
  const _WidgetIconSpec(
    name: 'lock',
    stickerHex: '#2AA7E0',
    primitives: [
      _IconPrimitiveSpec.path('M6 10h12v10H6Z'),
      _IconPrimitiveSpec.path('M8.5 10V7.5a3.5 3.5 0 0 1 7 0V10', fill: false),
      _IconPrimitiveSpec.path('M12 14v2.5', fill: false),
    ],
    interiorInkPath: 'M12 14v2.5',
  ),
  const _WidgetIconSpec(
    name: 'sparkle',
    stickerHex: '#FF9F1C',
    primitives: [
      _IconPrimitiveSpec.path(
        'm12 3 1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8Z',
      ),
      _IconPrimitiveSpec.path(
        'm19 15 .8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8Z',
      ),
    ],
  ),
  const _WidgetIconSpec(
    name: 'type-weight',
    stickerHex: '#10B981',
    primitives: [
      _IconPrimitiveSpec.path('M12 4v16M7 20h10M5 7h14', fill: false),
      _IconPrimitiveSpec.path('M5 7l-3 6h6ZM19 7l-3 6h6Z'),
    ],
  ),
  const _WidgetIconSpec(
    name: 'type-study',
    stickerHex: '#FF9F1C',
    primitives: [
      _IconPrimitiveSpec.path(
        'M4 4h6c2 0 2 2 2 2v14c0-2-2-2-2-2H4ZM20 4h-6c-2 0-2 2-2 2v14c0-2 2-2 2-2h6Z',
      ),
    ],
    interiorInkPath: 'M12 6v14',
  ),
  const _WidgetIconSpec(
    name: 'type-trip',
    stickerHex: '#C2452B',
    primitives: [
      _IconPrimitiveSpec.path('M6 7h12v14H6Z'),
      _IconPrimitiveSpec.path(
        'M9 7V4h6v3M9 11h6M10 21v1M14 21v1',
        fill: false,
      ),
    ],
    interiorInkPath: 'M9 11h6',
  ),
  const _WidgetIconSpec(
    name: 'type-couple',
    stickerHex: '#FF4D6D',
    primitives: [
      _IconPrimitiveSpec.path(
        'M12 20S4 15.5 4 9.5C4 5 9.5 4 12 8c2.5-4 8-3 8 1.5 0 6-8 10.5-8 10.5Z',
      ),
    ],
  ),
  const _WidgetIconSpec(
    name: 'type-workout',
    stickerHex: '#2AA7E0',
    primitives: [
      _IconPrimitiveSpec.path(
        'M7 8v8M4 10v4M17 8v8M20 10v4M7 12h10',
        fill: false,
      ),
    ],
    openStrokeOnly: true,
  ),
  const _WidgetIconSpec(
    name: 'type-custom',
    stickerHex: '#A13CC9',
    primitives: [
      _IconPrimitiveSpec.path(
        'm12 3 1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8Z',
      ),
      _IconPrimitiveSpec.path(
        'm19 15 .8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8Z',
      ),
    ],
  ),
];

Map<String, Object?> buildWidgetAssetSpecDocument() => {
  'schemaVersion': 1,
  'icons': [for (final icon in _iconSpecs) icon.toJson()],
};

Future<void> main(List<String> args) async {
  final doc = buildWidgetAssetSpecDocument();
  final formatted = const JsonEncoder.withIndent('  ').convert(doc);
  if (args.contains('--stdout')) {
    stdout.writeln(formatted);
    return;
  }
  final scriptDir = File.fromUri(Platform.script).parent;
  final outPath = '${scriptDir.path}/widget_icon_specs.json';
  await File(outPath).writeAsString('$formatted\n');
  stdout.writeln(
    'Exported ${_iconSpecs.length} widget icon specs -> $outPath',
  );
}
