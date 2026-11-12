import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

/// Vector icon of a journey template (App.tsx `journeys[].icon`). System UI
/// never shows keyboard emoji (CLAUDE.md 1.3); the journey's own emoji stays
/// the stored value.
IconData uiTemplateIcon(TemplateId id) => switch (id) {
  TemplateId.weightLoss => Icons.monitor_weight_rounded,
  TemplateId.englishDaily => Icons.menu_book_rounded,
  TemplateId.workout30 => Icons.fitness_center_rounded,
  TemplateId.travel => Icons.flight_takeoff_rounded,
  TemplateId.custom => Icons.auto_awesome_rounded,
};

/// Vector icon for a journey's emoji; an emoji outside the create form's
/// choices falls back to the icon of [template].
IconData uiJourneyIcon(String emoji, TemplateId template) =>
    _emojiIcons[emoji.replaceAll('️', '')] ?? uiTemplateIcon(template);

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
