import 'package:flutter/material.dart';

/// One of the ten journey styles from App.tsx (`styles` + `onAccentColors`):
/// accent, tinted paper, ink and the label color that sits on the accent.
@immutable
class UiJourneyStyle {
  const UiJourneyStyle({
    required this.name,
    required this.accent,
    required this.paper,
    required this.ink,
    required this.onAccent,
  });

  final String name;
  final Color accent;
  final Color paper;
  final Color ink;
  final Color onAccent;
}

const Color _darkOn = Color(0xFF111114);
const Color _white = Color(0xFFFFFFFF);

const List<UiJourneyStyle> uiJourneyStyles = [
  UiJourneyStyle(
    name: 'Quiet Transformer',
    accent: Color(0xFF10B981),
    paper: Color(0xFFEFF3F0),
    ink: Color(0xFF0F172A),
    onAccent: _darkOn,
  ),
  UiJourneyStyle(
    name: 'Accountability Squad',
    accent: Color(0xFFFF9F1C),
    paper: Color(0xFFF7F1E5),
    ink: Color(0xFF1E1B18),
    onAccent: _darkOn,
  ),
  UiJourneyStyle(
    name: 'Memory Collectors',
    accent: Color(0xFFC2452B),
    paper: Color(0xFFF4EFE6),
    ink: Color(0xFF231F1E),
    onAccent: _white,
  ),
  UiJourneyStyle(
    name: 'Couple Rituals',
    accent: Color(0xFFE15B72),
    paper: Color(0xFFF9F0EE),
    ink: Color(0xFF261F22),
    onAccent: _darkOn,
  ),
  UiJourneyStyle(
    name: 'Aesthetic Flexer',
    accent: Color(0xFFFF4D6D),
    paper: Color(0xFFF3F4F6),
    ink: Color(0xFF090A0F),
    onAccent: _darkOn,
  ),
  UiJourneyStyle(
    name: 'Minimalist Habit',
    accent: Color(0xFFEA580C),
    paper: Color(0xFFF5F3EE),
    ink: Color(0xFF1C1C1E),
    onAccent: _darkOn,
  ),
  UiJourneyStyle(
    name: 'Glow Ritual',
    accent: Color(0xFFA13CC9),
    paper: Color(0xFFFBF5FC),
    ink: Color(0xFF25112C),
    onAccent: _white,
  ),
  UiJourneyStyle(
    name: 'Little Milestones',
    accent: Color(0xFF2AA7E0),
    paper: Color(0xFFF1F8FC),
    ink: Color(0xFF0B2233),
    onAccent: _darkOn,
  ),
  UiJourneyStyle(
    name: 'Paw Growth',
    accent: Color(0xFF6CB021),
    paper: Color(0xFFF5F9EC),
    ink: Color(0xFF172206),
    onAccent: _darkOn,
  ),
  UiJourneyStyle(
    name: 'Blueprint Makeover',
    accent: Color(0xFF1D4ED8),
    paper: Color(0xFFEEF3F8),
    ink: Color(0xFF10203A),
    onAccent: _white,
  ),
];
