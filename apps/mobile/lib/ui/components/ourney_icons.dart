import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// One drawn primitive of an Ourney sticker icon (24x24 viewBox).
@immutable
class _Prim {
  const _Prim.path(this.d) : cx = 0, cy = 0, r = 0;
  const _Prim.circle(this.cx, this.cy, this.r) : d = null;

  final String? d;
  final double cx, cy, r;

  Path build() => d != null
      ? parseSvgPath(d!)
      : (Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)));
}

/// Inner "core" fills drawn over the main shape (V2 `.o-flame-inner`).
final Map<String, (Path, Color)> _cores = {
  'flame': (
    parseSvgPath(
      'M12 18.6c-2 0-3.3-1.2-3.3-3 0-1.4.8-2.5 2-3.6.1 1 .6 1.6 1.2 1.9.2-1.7 1-2.8 2-3.6.1 1.7 1.8 2.8 1.8 5.1 0 2-1.5 3.2-3.7 3.2Z',
    ),
    const Color(0xFFFF9F1C),
  ),
};

/// Path data of the icons used by the dock and reaction bar, copied from
/// V2 `design/ourney-v2-app/src/app/icons.tsx` (`drawing()`).
const Map<String, List<_Prim>> _drawings = {
  'journeys': [
    _Prim.path('M3.5 5.5 9 3l6 2.5L20.5 3v15.5L15 21l-6-2.5L3.5 21Z'),
    _Prim.path('M9 3v15.5M15 5.5V21'),
    _Prim.path('m6 14 2-2 3 2 4-5 2 2'),
  ],
  'squad': [
    _Prim.circle(9, 8, 3),
    _Prim.circle(17, 9, 2.5),
    _Prim.path(
      'M3.5 19c.4-4 2.2-6 5.5-6s5.1 2 5.5 6M14 14c3.7-.5 5.8 1.2 6.3 4.5',
    ),
  ],
  'camera': [
    _Prim.path('M4 7.5h3l1.5-2h7l1.5 2h3v11H4Z'),
    _Prim.circle(12, 13, 3.5),
  ],
  'activity': [
    _Prim.path(
      'M6.5 17.5h11l-1.5-2V11c0-2.7-1.5-4.6-4-4.8C9.5 6.4 8 8.3 8 11v4.5Z',
    ),
    _Prim.path('M10 19.5c.8 1 3.2 1 4 0M10 4.5h4'),
  ],
  'profile': [
    _Prim.circle(12, 8, 3.5),
    _Prim.path('M5 20c.5-4.6 2.8-7 7-7s6.5 2.4 7 7'),
  ],
  'react-clap': [
    _Prim.path('m5 13 5-6 2 2 2-4 2 2 2-2 2 2-5 11c-2 4-8 3-10 0l-2-3Z'),
    _Prim.path('m4 10-2-2M7 6 6 3M11 5l1-3'),
  ],
  'react-flex': [
    _Prim.path('M5 17c2-1 2-4 3-6l3 1 1-5 3-1 2 3c4 1 5 4 3 7-2 4-6 5-10 4Z'),
    _Prim.path('M8 11 5 9l-2 3 2 5'),
  ],
  'react-heart': [
    _Prim.path(
      'M12 20S4 15.5 4 9.5C4 5 9.5 4 12 8c2.5-4 8-3 8 1.5 0 6-8 10.5-8 10.5Z',
    ),
  ],
  'react-laugh': [
    _Prim.circle(12, 12, 9),
    _Prim.path('M7 9c1-1 2-1 3 0M14 9c1-1 2-1 3 0M7 14h10c-1 5-9 5-10 0Z'),
  ],
  'react-fire': [
    _Prim.path(
      'M12 21c-4 0-7-2.8-7-6.5 0-3 2-5.4 4.5-7.8 0 2 1 3.2 2.2 3.8.3-3.8 2.2-6.2 4.5-7.7.1 3.8 3.8 6 3.8 10.2 0 4.5-3.2 7.5-7 7.5Z',
    ),
  ],
  'react-wave': [
    _Prim.path(
      'M6 13V7a2 2 0 0 1 4 0v4-6a2 2 0 0 1 4 0v6-5a2 2 0 0 1 4 0v6-3a2 2 0 0 1 4 0v6c0 4-3 7-7 7h-2c-4 0-6-2-8-5l-2-3c-1-2 2-3 3-1l2 2',
    ),
  ],
  'settings': [
    _Prim.circle(12, 12, 3),
    _Prim.path(
      'm12 3 1 2.2 2.5.8 2.1-1 1.5 1.5-1 2.2.8 2.5L21 12l-2.2 1 .2 2.6 1 2-1.7 1.5-2-1-2.5.8L12 21l-1-2.2-2.6-.8-2.1 1-1.5-1.6 1-2.1L3 12l2.2-1L5 8.5l-1-2 1.7-1.6 2 1 2.5-.8Z',
    ),
  ],
  'back': [_Prim.path('m10 5-7 7 7 7'), _Prim.path('M4 12h17')],
  'close': [_Prim.path('m5 5 14 14M19 5 5 19')],
  'plus': [_Prim.path('M12 4v16M4 12h16')],
  'share': [
    _Prim.circle(18, 5, 2.5),
    _Prim.circle(6, 12, 2.5),
    _Prim.circle(18, 19, 2.5),
    _Prim.path('m8.2 10.8 7.5-4.5M8.2 13.2l7.5 4.5'),
  ],
  'lock': [
    _Prim.path('M6 10h12v10H6Z'),
    _Prim.path('M8.5 10V7.5a3.5 3.5 0 0 1 7 0V10'),
    _Prim.path('M12 14v2.5'),
  ],
  'heart': [
    _Prim.path(
      'M12 20S4 15.5 4 9.5C4 5 9.5 4 12 8c2.5-4 8-3 8 1.5 0 6-8 10.5-8 10.5Z',
    ),
  ],
  'star': [
    _Prim.path(
      'm12 3 2.6 5.4 5.9.8-4.3 4.2 1 5.9-5.2-2.8-5.2 2.8 1-5.9-4.3-4.2 5.9-.8Z',
    ),
  ],
  'flame': [
    _Prim.path(
      'M12 21c-4.4 0-7-2.6-7-6.5 0-3 2-5.2 4.3-7.7.1 2 1.1 3 2 3.5.4-3.5 2.1-5.8 4.3-7.3.1 3.6 3.4 5.7 3.4 10 0 4.8-3 8-7 8Z',
    ),
  ],
  'trophy': [
    _Prim.path('M7 4h10v5c0 3.5-2 5.5-5 5.5S7 12.5 7 9Z'),
    _Prim.path(
      'M7 6H4v2c0 2 1.2 3 3.5 3M17 6h3v2c0 2-1.2 3-3.5 3M12 14.5V19M8 20h8',
    ),
  ],
  'clock': [_Prim.circle(12, 12, 8), _Prim.path('M12 7v5l3.5 2M9 2h6')],
  'timer': [_Prim.circle(12, 12, 8), _Prim.path('M12 7v5l3.5 2M9 2h6')],
  'image': [
    _Prim.path('M3 5h18v14H3Z'),
    _Prim.circle(8, 9, 1.5),
    _Prim.path('m4 17 5-5 3 3 2-2 6 5'),
  ],
  'check': [_Prim.path('m6 12.5 4 4 8-9')],
  'warning': [_Prim.path('m12 3 9 17H3Z'), _Prim.path('M12 8v5M12 17h.01')],
  'wifi-off': [
    _Prim.path(
      'M3 8c4.8-3.8 10.3-4.2 15.5-1.2M6 12c2.8-2.2 5.7-2.7 8.8-1.4M9.5 16c1.5-1 3.2-.9 4.5.2M3 3l18 18',
    ),
  ],
  'cloud-off': [
    _Prim.path(
      'M5.5 17H5a3 3 0 0 1-.8-5.9A6.5 6.5 0 0 1 15 6.5a4.5 4.5 0 0 1 4.2 6.1M3 3l18 18',
    ),
  ],
  'calendar': [
    _Prim.path('M4 6h16v15H4Z'),
    _Prim.path('M8 3v6M16 3v6M4 10h16'),
  ],
  'switch-camera': [
    _Prim.path('M5 8h3l1.5-2h5L16 8h3v10H5Z'),
    _Prim.path('m9 12 2-2M9 12l2 2M15 14l-2 2M15 14l-2-2'),
  ],
  'lightning': [_Prim.path('m13 2-8 12h6l-1 8 9-13h-6Z')],
  'type-weight': [
    _Prim.path(
      'M12 3.2c5.5 0 9 3.5 9 8.8s-3.5 8.8-9 8.8S3 17.3 3 12s3.5-8.8 9-8.8Zm0 5C9.6 8.2 8.1 9.7 8.1 12s1.5 3.8 3.9 3.8 3.9-1.5 3.9-3.8-1.5-3.8-3.9-3.8Z',
    ),
  ],
  'type-study': [
    _Prim.path(
      'M3.5 3.5h5.7v10.2c0 1.7.9 2.6 2.8 2.6s2.8-.9 2.8-2.6V3.5h5.7v10.8c0 4.4-3.2 7-8.5 7s-8.5-2.6-8.5-7Z',
    ),
  ],
  'type-trip': [
    _Prim.path('M2.5 3h19v18h-19Z'),
    _Prim.path(
      'M4 4h5.2v2.4C10.5 4.6 12.4 3.6 15 3.6c.8 0 1.6.1 2.2.3l-.6 5.2c-.8-.3-1.6-.5-2.5-.5-3 0-4.5 1.6-4.5 4.9V21H4Z',
    ),
  ],
  'type-couple': [
    _Prim.path('M2.2 4.3h19.6v15.4H2.2Z'),
    _Prim.path(
      'M18.3 14.9c-1.7 1.2-3.8 1.8-6.2 1.8-4.5 0-7.4-2.4-7.4-6.3 0-4 3-6.5 7.3-6.5 4.5 0 7.1 2.6 7.1 7.2v1.3H10c.4 1 1.4 1.5 3 1.5 1.5 0 2.8-.4 4.1-1.2ZM10 9.4h3.8c-.1-1.1-.8-1.7-1.9-1.7-1 0-1.7.6-1.9 1.7Z',
    ),
  ],
  'type-workout': [
    _Prim.path('M3.5 20.5v-17h5.2l6.6 9.1V3.5h5.2v17h-5.2l-6.6-9v9Z'),
    _Prim.circle(6.2, 6.2, 1.15),
    _Prim.circle(17.8, 17.8, 1.15),
    _Prim.circle(17.8, 6.2, 0.85),
  ],
  'type-custom': [
    _Prim.path('M2.8 3.5h6l3.3 7.1 3.2-7.1h5.9L14.8 16v5H9.2v-5Z'),
  ],
};

/// Sticker fill of each icon (V2 icons.tsx `palette`).
const Map<String, Color> _palette = {
  'journeys': Color(0xFFC2452B),
  'squad': Color(0xFFFF9F1C),
  'camera': Color(0xFF10B981),
  'activity': Color(0xFFFF4D6D),
  'profile': Color(0xFFA13CC9),
  'react-clap': Color(0xFFFF9F1C),
  'react-flex': Color(0xFFA13CC9),
  'react-heart': Color(0xFFFF4D6D),
  'react-laugh': Color(0xFFFF9F1C),
  'react-fire': Color(0xFFC2452B),
  'react-wave': Color(0xFF2AA7E0),
  'settings': Color(0xFF2AA7E0),
  'back': Color(0xFF2AA7E0),
  'close': Color(0xFFC2452B),
  'plus': Color(0xFF10B981),
  'share': Color(0xFF2AA7E0),
  'lock': Color(0xFF2AA7E0),
  'heart': Color(0xFFFF4D6D),
  'star': Color(0xFFFF9F1C),
  'flame': Color(0xFFC2452B),
  'trophy': Color(0xFFFF9F1C),
  'clock': Color(0xFF2AA7E0),
  'timer': Color(0xFFFF9F1C),
  'image': Color(0xFF10B981),
  'check': Color(0xFF10B981),
  'warning': Color(0xFFFF9F1C),
  'wifi-off': Color(0xFFC2452B),
  'cloud-off': Color(0xFF2AA7E0),
  'calendar': Color(0xFFFF4D6D),
  'switch-camera': Color(0xFF10B981),
  'lightning': Color(0xFFFF9F1C),
  'type-weight': Color(0xFF10B981),
  'type-study': Color(0xFFFF9F1C),
  'type-trip': Color(0xFFC2452B),
  'type-couple': Color(0xFFFF4D6D),
  'type-workout': Color(0xFF2AA7E0),
  'type-custom': Color(0xFFA13CC9),
};

/// Names [OurneyIcon] can draw.
List<String> get ourneyIconNames => List.unmodifiable(_drawings.keys);

/// The sticker color of icon [name] (V2 `palette`).
Color ourneyIconColor(String name) => _palette[name] ?? const Color(0xFF2AA7E0);

/// All primitives of icon [name] merged into one [Path] in the 24x24 viewBox,
/// or null for an unknown name.
Path? ourneyIconPath(String name) {
  final prims = _drawings[name];
  if (prims == null) return null;
  final p = Path();
  for (final prim in prims) {
    p.addPath(prim.build(), Offset.zero);
  }
  return p;
}

final RegExp _token = RegExp(
  r'[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?',
);

final RegExp _isCommand = RegExp(r'^[A-Za-z]$');

/// Minimal SVG path-data parser: M L H V C S Q T A Z, absolute and relative,
/// with implicit command repetition. Arc flags must be separated from the
/// following numbers (as in the V2 icon set).
Path parseSvgPath(String d) {
  final tokens = _token.allMatches(d).map((m) => m.group(0)!).toList();
  final path = Path();
  var i = 0;
  var cmd = '';
  var x = 0.0, y = 0.0; // current point
  var sx = 0.0, sy = 0.0; // subpath start
  double? lcx, lcy; // last cubic control point (for S)
  double? lqx, lqy; // last quad control point (for T)

  double num() => double.parse(tokens[i++]);

  while (i < tokens.length) {
    if (_isCommand.hasMatch(tokens[i])) {
      cmd = tokens[i++];
      if (cmd == 'Z' || cmd == 'z') {
        path.close();
        x = sx;
        y = sy;
        lcx = lcy = lqx = lqy = null;
        continue;
      }
    } else if (cmd.isEmpty) {
      throw FormatException('Path data must start with a command', d);
    } else if (cmd == 'M') {
      cmd = 'L';
    } else if (cmd == 'm') {
      cmd = 'l';
    }
    final rel = cmd == cmd.toLowerCase();
    final ox = rel ? x : 0.0, oy = rel ? y : 0.0;
    switch (cmd.toUpperCase()) {
      case 'M':
        x = num() + ox;
        y = num() + oy;
        sx = x;
        sy = y;
        path.moveTo(x, y);
        lcx = lcy = lqx = lqy = null;
      case 'L':
        x = num() + ox;
        y = num() + oy;
        path.lineTo(x, y);
        lcx = lcy = lqx = lqy = null;
      case 'H':
        x = num() + ox;
        path.lineTo(x, y);
        lcx = lcy = lqx = lqy = null;
      case 'V':
        y = num() + oy;
        path.lineTo(x, y);
        lcx = lcy = lqx = lqy = null;
      case 'C':
        final x1 = num() + ox, y1 = num() + oy;
        final x2 = num() + ox, y2 = num() + oy;
        x = num() + ox;
        y = num() + oy;
        path.cubicTo(x1, y1, x2, y2, x, y);
        lcx = x2;
        lcy = y2;
        lqx = lqy = null;
      case 'S':
        final x1 = lcx == null ? x : 2 * x - lcx;
        final y1 = lcy == null ? y : 2 * y - lcy;
        final x2 = num() + ox, y2 = num() + oy;
        x = num() + ox;
        y = num() + oy;
        path.cubicTo(x1, y1, x2, y2, x, y);
        lcx = x2;
        lcy = y2;
        lqx = lqy = null;
      case 'Q':
        final x1 = num() + ox, y1 = num() + oy;
        x = num() + ox;
        y = num() + oy;
        path.quadraticBezierTo(x1, y1, x, y);
        lqx = x1;
        lqy = y1;
        lcx = lcy = null;
      case 'T':
        final x1 = lqx == null ? x : 2 * x - lqx;
        final y1 = lqy == null ? y : 2 * y - lqy;
        x = num() + ox;
        y = num() + oy;
        path.quadraticBezierTo(x1, y1, x, y);
        lqx = x1;
        lqy = y1;
        lcx = lcy = null;
      case 'A':
        final rx = num().abs(), ry = num().abs();
        final rot = num();
        final large = num() != 0;
        final sweep = num() != 0;
        x = num() + ox;
        y = num() + oy;
        if (rx == 0 || ry == 0) {
          path.lineTo(x, y);
        } else {
          path.arcToPoint(
            Offset(x, y),
            radius: Radius.elliptical(rx, ry),
            rotation: rot * math.pi / 180,
            largeArc: large,
            clockwise: sweep,
          );
        }
        lcx = lcy = lqx = lqy = null;
      default:
        throw FormatException('Unsupported path command $cmd', d);
    }
  }
  return path;
}

/// Paints one Ourney sticker icon. Layers, bottom to top: hard shadow (full
/// tier), white die-cut edge (active), ink outline, colored fill (V2
/// `.o-icon-*`). Stroke widths are logical pixels, not viewBox units.
class OurneyIconPainter extends CustomPainter {
  OurneyIconPainter({
    required this.name,
    required this.color,
    required this.ink,
    this.active = false,
    this.shadow,
    this.dieCut = const Color(0xFFFFFFFF),
  });

  final String name;

  /// Fill color of the glyph.
  final Color color;

  /// Outline color.
  final Color ink;

  /// Adds the die-cut edge (and the hard shadow from 24dp up).
  final bool active;

  /// Hard shadow of the full tier; null skips it.
  final Color? shadow;
  final Color dieCut;

  @override
  void paint(Canvas canvas, Size size) {
    final path = ourneyIconPath(name);
    if (path == null) return;
    final scale = size.width / 24;
    final tiny = size.width < 16;
    final full = size.width >= 24;
    canvas.save();
    canvas.scale(scale);

    void layer(Path p, Color c, double strokePx) {
      final paint = Paint()
        ..color = c
        ..style = PaintingStyle.fill;
      canvas.drawPath(p, paint);
      canvas.drawPath(
        p,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokePx / scale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    if (active && !tiny) {
      if (shadow != null && full) {
        layer(path.shift(Offset(2 / scale, 2 / scale)), shadow!, 12);
      }
      layer(path, dieCut, full ? 12 : 9);
    }
    if (!tiny) layer(path, ink, full ? 6 : 5);
    layer(path, color, tiny ? 3.5 : 2);
    final core = _cores[name];
    if (core != null && !tiny && color == ourneyIconColor(name)) {
      canvas.drawPath(
        core.$1,
        Paint()
          ..color = core.$2
          ..style = PaintingStyle.fill,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(OurneyIconPainter old) =>
      old.name != name ||
      old.color != color ||
      old.ink != ink ||
      old.active != active ||
      old.shadow != shadow ||
      old.dieCut != dieCut;
}

/// A drawn Ourney sticker icon (`OIcon` in V2). Never a Material icon.
///
/// [color] overrides the sticker fill (e.g. a solid ink glyph) and [inkColor]
/// the outline; they default to the V2 palette and `context.ui.ink`.
/// Decorative unless [semanticLabel] is given.
class OurneyIcon extends StatelessWidget {
  const OurneyIcon({
    required this.name,
    this.size = 24,
    this.active = false,
    this.color,
    this.inkColor,
    this.semanticLabel,
    super.key,
  });

  final String name;
  final double size;
  final bool active;
  final Color? color;
  final Color? inkColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final Widget icon = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: OurneyIconPainter(
          name: name,
          color: color ?? ourneyIconColor(name),
          ink: inkColor ?? ui.ink,
          active: active,
          shadow: ui.isDark ? const Color(0xFF000000) : ui.ink,
        ),
      ),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: icon)
        : Semantics(label: semanticLabel, image: true, child: icon);
  }
}
