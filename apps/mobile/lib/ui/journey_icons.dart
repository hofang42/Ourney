import 'package:flutter/widgets.dart';
import 'package:ourney_core/ourney_core.dart';

import 'components/ourney_icons.dart';

/// Drawn [OurneyIcon] of a journey template.
Widget uiTemplateGlyph(TemplateId id, {double size = 24, Color? color}) =>
    OurneyIcon(name: _templateNames[id]!, size: size, color: color);

/// Drawn [OurneyIcon] for a journey's emoji; an emoji outside the create
/// form's choices falls back to the glyph of [template].
Widget uiJourneyGlyph(
  String emoji,
  TemplateId template, {
  double size = 24,
  Color? color,
}) => OurneyIcon(
  name: _emojiNames[emoji.replaceAll('️', '')] ?? _templateNames[template]!,
  size: size,
  color: color,
);

const Map<TemplateId, String> _templateNames = {
  TemplateId.weightLoss: 'type-weight',
  TemplateId.englishDaily: 'type-study',
  TemplateId.workout30: 'type-workout',
  TemplateId.travel: 'type-trip',
  TemplateId.custom: 'sparkle',
};

const Map<String, String> _emojiNames = {
  '⚖': 'type-weight',
  '📚': 'type-study',
  '💪': 'type-workout',
  '✈': 'type-trip',
  '✨': 'sparkle',
  '🏃': 'type-workout',
  '🧘': 'lotus',
  '🥗': 'restaurant',
  '🎨': 'palette',
  '🎸': 'music',
  '🌱': 'leaf',
  '💧': 'drop',
  '💞': 'type-couple',
};
