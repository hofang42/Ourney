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
  'chevron-right': [_Prim.path('m9 5 7 7-7 7')],
  'chevron-left': [_Prim.path('m15 5-7 7 7 7')],
  'chevron-down': [_Prim.path('m5 9 7 7 7-7')],
  'chevron-up': [_Prim.path('m5 15 7-7 7 7')],
  'arrow-right': [_Prim.path('m14 5 7 7-7 7M20 12H3')],
  'more': [
    _Prim.circle(5, 12, 1.6),
    _Prim.circle(12, 12, 1.6),
    _Prim.circle(19, 12, 1.6),
  ],
  'search': [_Prim.circle(10.5, 10.5, 6.5), _Prim.path('m15.5 15.5 5 5')],
  'send': [_Prim.path('M3 11 21 3l-7 18-3-7Z'), _Prim.path('m11 14 10-11')],
  'download': [_Prim.path('M12 4v11M7 11l5 5 5-5M5 20h14')],
  'copy': [_Prim.path('M9 9h11v11H9Z'), _Prim.path('M15 9V4H4v11h5')],
  'edit': [_Prim.path('m4 20 1-5L16 4l4 4L9 19Z'), _Prim.path('m14 6 4 4')],
  'trash': [_Prim.path('M5 7h14l-1 13H6Z'), _Prim.path('M3 7h18M9 7V4h6v3')],
  'info': [_Prim.circle(12, 12, 9), _Prim.path('M12 11v6M12 7.5h.01')],
  'error': [_Prim.circle(12, 12, 9), _Prim.path('M12 7v6M12 16.5h.01')],
  'check-circle': [_Prim.circle(12, 12, 9), _Prim.path('m8 12.5 3 3 5-6')],
  'logout': [_Prim.path('M10 4H4v16h6'), _Prim.path('M9 12h12M17 8l4 4-4 4')],
  'login': [_Prim.path('M14 4h6v16h-6'), _Prim.path('M3 12h12M11 8l4 4-4 4')],
  'bell': [
    _Prim.path(
      'M6.5 17.5h11l-1.5-2V11c0-2.7-1.5-4.6-4-4.8C9.5 6.4 8 8.3 8 11v4.5Z',
    ),
    _Prim.path('M10 19.5c.8 1 3.2 1 4 0M10 4.5h4'),
  ],
  'bell-off': [
    _Prim.path(
      'M6.5 17.5h11l-1.5-2V11c0-2.7-1.5-4.6-4-4.8C9.5 6.4 8 8.3 8 11v4.5Z',
    ),
    _Prim.path('M10 19.5c.8 1 3.2 1 4 0M10 4.5h4M3 3l18 18'),
  ],
  'mail': [_Prim.path('M3 5h18v14H3Z'), _Prim.path('m3 6 9 7 9-7')],
  'link': [
    _Prim.path(
      'M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1M14 10a4 4 0 0 0-5.7 0l-3 3A4 4 0 0 0 11 18.7l1-1',
    ),
  ],
  'link-off': [
    _Prim.path(
      'M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1M14 10a4 4 0 0 0-5.7 0l-3 3A4 4 0 0 0 11 18.7l1-1M3 3l18 18',
    ),
  ],
  'flag': [_Prim.path('M5 21V4M5 4h12l-2 4 2 4H5')],
  'block': [_Prim.circle(12, 12, 9), _Prim.path('m5.6 5.6 12.8 12.8')],
  'eye': [
    _Prim.path('M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12Z'),
    _Prim.circle(12, 12, 3),
  ],
  'eye-off': [
    _Prim.path('M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12Z'),
    _Prim.circle(12, 12, 3),
    _Prim.path('M3 3l18 18'),
  ],
  'refresh': [_Prim.path('M19 12a7 7 0 1 1-2.05-4.95M19 4v5h-5')],
  'undo': [_Prim.path('M9 14 4 9l5-5M4 9h10a6 6 0 0 1 0 12h-3')],
  'shield': [_Prim.path('m12 3 8 3v6c0 4.5-3.2 7.8-8 9-4.8-1.2-8-4.5-8-9V6Z')],
  'user-plus': [
    _Prim.circle(9, 8, 3.5),
    _Prim.path('M3 20c.5-4.6 2.6-7 6-7s5.5 2.4 6 7M18 8v6M15 11h6'),
  ],
  'user-minus': [
    _Prim.circle(9, 8, 3.5),
    _Prim.path('M3 20c.5-4.6 2.6-7 6-7s5.5 2.4 6 7M15 11h6'),
  ],
  'mic': [
    _Prim.path('M9 3h6v10a3 3 0 0 1-6 0Z'),
    _Prim.path('M5 11a7 7 0 0 0 14 0M12 18v3'),
  ],
  'camera-off': [
    _Prim.path('M4 7.5h3l1.5-2h7l1.5 2h3v11H4Z'),
    _Prim.circle(12, 13, 3.5),
    _Prim.path('M3 3l18 18'),
  ],
  'gallery': [
    _Prim.path('M7 3h14v14H7Z'),
    _Prim.path('M3 7v14h14'),
    _Prim.path('m8 14 3-3 3 3 2-2 3 3'),
  ],
  'image-off': [
    _Prim.path('M3 5h18v14H3Z'),
    _Prim.circle(8, 9, 1.5),
    _Prim.path('m4 17 5-5 3 3 2-2 6 5M3 3l18 18'),
  ],
  'image-plus': [
    _Prim.path('M3 5h18v14H3Z'),
    _Prim.circle(8, 9, 1.5),
    _Prim.path('m4 17 5-5 3 3 2-2 6 5M19 1v6M16 4h6'),
  ],
  'grid': [
    _Prim.path('M3 3h18v18H3Z'),
    _Prim.path('M9 3v18M15 3v18M3 9h18M3 15h18'),
  ],
  'flash-off': [
    _Prim.path('m13 2-8 12h6l-1 8 9-13h-6Z'),
    _Prim.path('M3 3l18 18'),
  ],
  'flash-auto': [
    _Prim.path('m11 4-7 11h5l-1 7 8-11h-5Z'),
    _Prim.path('M18 2v5M15.5 4.5h5'),
  ],
  'translate': [
    _Prim.path(
      'M4 5h10M9 3v2M6 5c.5 4 3 7 6 8M12 5c-.5 4-3 7-7 9M13 20l4-10 4 10M14.5 17h5',
    ),
  ],
  'radio-off': [_Prim.circle(12, 12, 8)],
  'radio-on': [_Prim.circle(12, 12, 8), _Prim.circle(12, 12, 3.5)],
  'gavel': [
    _Prim.path('m13 3 7 7-3 3-7-7Z'),
    _Prim.path('m11 11-7 7 2 2 7-7M3 21h9'),
  ],
  'chat': [_Prim.path('M4 5h16v11H10l-5 4v-4H4Z')],
  'chat-off': [
    _Prim.path('M4 5h16v11H10l-5 4v-4H4Z'),
    _Prim.path('M3 3l18 18'),
  ],
  'sparkle': [
    _Prim.path('m12 3 1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8Z'),
    _Prim.path('m19 15 .8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8Z'),
  ],
  'inbox': [
    _Prim.path('m3 13 3-8h12l3 8v6H3Z'),
    _Prim.path('M3 13h5l1 3h6l1-3h5'),
  ],
  'home': [_Prim.path('m3 11 9-7 9 7M5 10v10h14V10M10 20v-5h4v5')],
  'qr': [
    _Prim.path('M3 3h7v7H3ZM14 3h7v7h-7ZM3 14h7v7H3Z'),
    _Prim.path('M14 14h3v3h-3M20 14v1M14 20h1M18 18h3v3'),
  ],
  'phone': [_Prim.path('M7 2h10v20H7Z'), _Prim.path('M11 19h2')],
  'restaurant': [
    _Prim.path('M7 3v8M5 3v5a2 2 0 0 0 4 0V3M7 11v10M17 3c-2 2-3 5-3 8h3v10'),
  ],
  'palette': [
    _Prim.path(
      'M12 3a9 9 0 0 0 0 18c1.5 0 2-1 1.5-2s0-2 1.5-2h2a4 4 0 0 0 4-4c0-5-4-10-9-10Z',
    ),
    _Prim.circle(7.5, 11, 1),
    _Prim.circle(10, 7, 1),
    _Prim.circle(15, 7, 1),
  ],
  'music': [
    _Prim.path('M9 18V5l11-2v13'),
    _Prim.path(
      'M9 18a3 3 0 1 1-6 0 3 3 0 0 1 6 0ZM20 16a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z',
    ),
  ],
  'leaf': [
    _Prim.path('M5 19C5 10 10 5 20 4c0 10-5 15-14 15Z'),
    _Prim.path('m5 19 8-8'),
  ],
  'drop': [_Prim.path('M12 3s6 6.5 6 11a6 6 0 0 1-12 0c0-4.5 6-11 6-11Z')],
  'lotus': [
    _Prim.path('M12 4c2 2.5 2 6 0 9-2-3-2-6.5 0-9Z'),
    _Prim.path('M4 9c4 0 7 2 8 6M20 9c-4 0-7 2-8 6M5 19h14'),
  ],
  // Journey goal icons of the onboarding quiz (V2 icons.tsx: scales, book,
  // fitness, trip, edit). `pencil` is V2's `edit`; `edit` above keeps its
  // older drawing.
  'scales': [_Prim.path('M12 4v16M7 20h10M5 7h14M5 7l-3 6h6ZM19 7l-3 6h6Z')],
  'book': [
    _Prim.path(
      'M4 4h6c2 0 2 2 2 2v14c0-2-2-2-2-2H4ZM20 4h-6c-2 0-2 2-2 2v14c0-2 2-2 2-2h6Z',
    ),
  ],
  'fitness': [_Prim.path('M7 8v8M4 10v4M17 8v8M20 10v4M7 12h10')],
  'trip': [
    _Prim.path('M6 7h12v14H6Z'),
    _Prim.path('M9 7V4h6v3M9 11h6M10 21v1M14 21v1'),
  ],
  'pencil': [_Prim.path('m5 17-1 4 4-1L20 8l-3-3Z'), _Prim.path('m14 8 3 3')],
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
  'chevron-right': Color(0xFF2AA7E0),
  'chevron-left': Color(0xFF2AA7E0),
  'chevron-down': Color(0xFF2AA7E0),
  'chevron-up': Color(0xFF2AA7E0),
  'arrow-right': Color(0xFF2AA7E0),
  'more': Color(0xFF2AA7E0),
  'search': Color(0xFF2AA7E0),
  'send': Color(0xFF2AA7E0),
  'download': Color(0xFF10B981),
  'copy': Color(0xFF2AA7E0),
  'edit': Color(0xFFFF9F1C),
  'trash': Color(0xFFC2452B),
  'info': Color(0xFF2AA7E0),
  'error': Color(0xFFC2452B),
  'check-circle': Color(0xFF10B981),
  'logout': Color(0xFFC2452B),
  'login': Color(0xFF10B981),
  'bell': Color(0xFFFF4D6D),
  'bell-off': Color(0xFFC2452B),
  'mail': Color(0xFF2AA7E0),
  'link': Color(0xFF2AA7E0),
  'link-off': Color(0xFFC2452B),
  'flag': Color(0xFFFF9F1C),
  'block': Color(0xFFC2452B),
  'eye': Color(0xFF2AA7E0),
  'eye-off': Color(0xFF2AA7E0),
  'refresh': Color(0xFF2AA7E0),
  'undo': Color(0xFF2AA7E0),
  'shield': Color(0xFF2AA7E0),
  'user-plus': Color(0xFF10B981),
  'user-minus': Color(0xFFC2452B),
  'mic': Color(0xFFFF4D6D),
  'camera-off': Color(0xFFC2452B),
  'gallery': Color(0xFF10B981),
  'image-off': Color(0xFFC2452B),
  'image-plus': Color(0xFF10B981),
  'grid': Color(0xFF2AA7E0),
  'flash-off': Color(0xFFC2452B),
  'flash-auto': Color(0xFFFF9F1C),
  'translate': Color(0xFF2AA7E0),
  'radio-off': Color(0xFF2AA7E0),
  'radio-on': Color(0xFF10B981),
  'gavel': Color(0xFFC2452B),
  'chat': Color(0xFF2AA7E0),
  'chat-off': Color(0xFFC2452B),
  'sparkle': Color(0xFFFF9F1C),
  'inbox': Color(0xFF2AA7E0),
  'home': Color(0xFFFF9F1C),
  'qr': Color(0xFF2AA7E0),
  'phone': Color(0xFF2AA7E0),
  'restaurant': Color(0xFF10B981),
  'palette': Color(0xFFA13CC9),
  'music': Color(0xFFFF4D6D),
  'leaf': Color(0xFF10B981),
  'drop': Color(0xFF2AA7E0),
  'lotus': Color(0xFFA13CC9),
  'scales': Color(0xFF10B981),
  'book': Color(0xFFFF9F1C),
  'fitness': Color(0xFFA13CC9),
  'trip': Color(0xFFC2452B),
  'pencil': Color(0xFFA13CC9),
};

/// Icons that are open strokes: their path is never filled.
const Set<String> _openIcons = {
  'chevron-right',
  'chevron-left',
  'chevron-down',
  'chevron-up',
  'arrow-right',
  'download',
  'refresh',
  'undo',
  'translate',
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
    this.flat = false,
  });

  /// Single [color] line, no fill / ink halo / shadow (chevrons on plain rows,
  /// monochrome glyphs on the camera chrome).
  final bool flat;

  final String name;

  /// Fill color of the glyph.
  final Color color;

  /// Outline color.
  final Color ink;

  /// Adds the die-cut edge and hard shadow (full tier, 24dp up, only).
  final bool active;

  /// Hard shadow of the full tier; null skips it.
  final Color? shadow;
  final Color dieCut;

  /// True when a two-tone sticker would collapse into one solid blob: the
  /// fill and the outline are (nearly) the same color, e.g. `color: ui.ink`
  /// on the default ink outline, or a white camera glyph in dark mode.
  static bool collapses(Color color, Color ink) {
    if (color == ink) return true;
    final a = color.computeLuminance() + 0.05;
    final b = ink.computeLuminance() + 0.05;
    return (a > b ? a / b : b / a) < 1.15;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = ourneyIconPath(name);
    if (path == null) return;
    // A two-tone icon whose fill and ink coincide is drawn as a single
    // [color] line glyph instead of a filled blob (details stay visible).
    final flat = this.flat || collapses(color, ink);
    final scale = size.width / 24;
    final tiny = size.width < 16;
    final full = size.width >= 24;
    canvas.save();
    canvas.scale(scale);

    final open = _openIcons.contains(name);
    void layer(Path p, Color c, double strokePx) {
      final paint = Paint()
        ..color = c
        ..style = PaintingStyle.fill;
      if (!open && (!flat || name == 'more')) canvas.drawPath(p, paint);
      canvas.drawPath(
        p,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokePx / scale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    if (flat) {
      layer(path, color, size.width < 16 ? 1.6 : 2);
      canvas.restore();
      return;
    }
    if (active && full) {
      if (shadow != null) {
        layer(path.shift(Offset(2 / scale, 2 / scale)), shadow!, 12);
      }
      layer(path, dieCut, 12);
    }
    // The ink halo scales with the icon so it does not clump at 16-22px.
    if (!tiny) layer(path, ink, (size.width * 0.22).clamp(3.5, 6.0));
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
      old.flat != flat ||
      old.shadow != shadow ||
      old.dieCut != dieCut;
}

/// A drawn Ourney sticker icon (`OIcon` in V2). Never a Material icon.
///
/// Usage: `OurneyIcon(name: 'chevron-right', size: 20, flat: true, color:
/// ui.chevron)` for a quiet line glyph, or `OurneyIcon(name: 'flag')` for the
/// sticker. Pass it as the `glyph:` of kit widgets (`UiButton`, `UiChip`,
/// `UiMenuItem`, `UiEmptyState`...). Names: see [ourneyIconNames].
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
    this.flat = false,
    this.semanticLabel,
    super.key,
  });

  /// Draws a single [color] line (default `context.ui.ink`) without the
  /// sticker fill, outline and shadow.
  final bool flat;

  final String name;
  final double size;
  final bool active;
  final Color? color;
  final Color? inkColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    // A custom [color] without an [inkColor] is a neutral / state tint (ink,
    // muted, divider...): as a sticker fill it would swallow the outline, so
    // it is drawn as a line glyph. Palette colors keep the sticker look.
    final lineGlyph =
        flat ||
        (color != null && inkColor == null && color != ourneyIconColor(name));
    final Widget icon = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: OurneyIconPainter(
          name: name,
          color: color ?? (lineGlyph ? ui.ink : ourneyIconColor(name)),
          ink: inkColor ?? ui.ink,
          active: active,
          flat: lineGlyph,
          shadow: ui.isDark ? const Color(0xFF000000) : ui.ink,
        ),
      ),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: icon)
        : Semantics(label: semanticLabel, image: true, child: icon);
  }
}
