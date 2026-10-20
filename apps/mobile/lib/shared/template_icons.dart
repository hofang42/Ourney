import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

/// Vector icon of a journey template, for screens that must not use emoji as
/// system icons (`CLAUDE.md` §1.3). The journey's own emoji stays user data.
IconData templateIcon(TemplateId id) => switch (id) {
  TemplateId.weightLoss => Icons.monitor_weight_rounded,
  TemplateId.englishDaily => Icons.menu_book_rounded,
  TemplateId.workout30 => Icons.fitness_center_rounded,
  TemplateId.travel => Icons.flight_takeoff_rounded,
  TemplateId.custom => Icons.auto_awesome_rounded,
};

/// Streak flame.
const IconData streakIcon = Icons.local_fire_department_rounded;

/// Vector icon for a journey's emoji. The emoji stays the stored value (the
/// backend contract, `journeys.emoji`); screens draw this icon instead so
/// system UI never shows keyboard emoji (`CLAUDE.md` §1.3). An emoji outside
/// the create form's choices falls back to the icon of [template].
IconData journeyIcon(String emoji, TemplateId template) =>
    _emojiIcons[emoji.replaceAll('\uFE0F', '')] ?? templateIcon(template);

/// Icons for the emoji offered in the create form, keyed without the
/// variation selector.
const Map<String, IconData> _emojiIcons = {
  '⚖': Icons.monitor_weight_rounded,
  '📚': Icons.menu_book_rounded,
  '💪': Icons.fitness_center_rounded,
  '✈': Icons.flight_takeoff_rounded,
  '✨': Icons.auto_awesome_rounded,
  '🏃': Icons.directions_run_rounded,
  '🧘': Icons.self_improvement_rounded,
  '🥗': Icons.restaurant_rounded,
  '🎨': Icons.palette_rounded,
  '🎸': Icons.music_note_rounded,
  '🌱': Icons.eco_rounded,
  '💧': Icons.water_drop_rounded,
  '💞': Icons.favorite_rounded,
};
