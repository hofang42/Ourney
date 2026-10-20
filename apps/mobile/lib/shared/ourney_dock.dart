import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart' show buildAppTheme, kBodyFont;
import '../app/theme/motion.dart';
import '../app/theme/persona_theme.dart';
import '../app/theme/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import 'color_utils.dart';
import 'layout.dart';
import 'ourney_pill_button.dart';
import 'ourney_primary_button.dart';

/// The 3-tab bottom dock shared by every primary screen (F4, `CLAUDE.md` §2):
///
/// * left: Journeys (map icon),
/// * center: the snap button, a 76x76 hero shutter while on the camera and a
///   56x40 pill in `primaryAccent` everywhere else,
/// * right: Squad (people icon).
///
/// Colors come from [OurneyPersonaTheme], so the dock takes the active
/// journey's persona and follows light and dark. On the camera it is always
/// dark, like the rest of that screen.
class OurneyDock extends StatelessWidget {
  const OurneyDock({
    required this.currentIndex,
    required this.onSelect,
    super.key,
  });

  static const int journeysIndex = 0;
  static const int captureIndex = 1;
  static const int groupsIndex = 2;

  /// Height of the dock content, above the safe-area inset.
  static const double height = 72;
  static const double heroSize = 76;
  static const Size pillSize = Size(56, 40);

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final onCapture = currentIndex == captureIndex;
    final base = Theme.of(context);
    final skin = OurneyPersonaTheme.of(context).skinId;
    return Theme(
      data: onCapture ? buildAppTheme(Brightness.dark, skin) : base,
      child: Builder(
        builder: (context) {
          final pTheme = OurneyPersonaTheme.of(context);
          final l10n = AppLocalizations.of(context);
          return Material(
            color: onCapture ? OurneyColors.cameraBg : pTheme.surface,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: pTheme.border,
                    width: pTheme.borderWidth,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                // Compact chrome: labels follow the system text size only up
                // to 1.3x (like native tab bars).
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.3,
                  child: SizedBox(
                    height: height,
                    child: Row(
                      children: [
                        Expanded(
                          child: _DockTab(
                            key: const ValueKey('dock-journeys'),
                            icon: Icons.map_rounded,
                            label: l10n.nav_journeys,
                            selected: currentIndex == journeysIndex,
                            onTap: () => onSelect(journeysIndex),
                          ),
                        ),
                        Expanded(
                          child: _DockSnap(
                            label: l10n.nav_capture,
                            hero: onCapture,
                            onTap: () => onSelect(captureIndex),
                          ),
                        ),
                        Expanded(
                          child: _DockTab(
                            key: const ValueKey('dock-groups'),
                            icon: Icons.groups_rounded,
                            label: l10n.nav_groups,
                            selected: currentIndex == groupsIndex,
                            onTap: () => onSelect(groupsIndex),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DockTab extends StatelessWidget {
  const _DockTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    // Selected = ink + bold label + accent bar (never color alone); the
    // accent itself is not text-safe on every persona surface.
    final color = selected ? pTheme.ink : pTheme.inkMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: OurneyLayout.minTouchTarget,
            minWidth: OurneyLayout.minTouchTarget,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: kBodyFont,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  height: 1.3,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: OurneyMotion.duration(context, OurneyDurations.tap),
                width: selected ? 20 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: pTheme.primaryAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Center snap button: the hero shutter on the camera, the pill elsewhere.
class _DockSnap extends StatelessWidget {
  const _DockSnap({
    required this.label,
    required this.hero,
    required this.onTap,
  });

  final String label;
  final bool hero;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The hero shutter is 76dp in a 72dp dock: let it overflow its cell
    // instead of being squeezed.
    return OverflowBox(
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: AnimatedSwitcher(
        duration: OurneyMotion.duration(context, OurneyDurations.personaSwitch),
        child: hero
            ? _HeroShutter(
                key: const ValueKey('dock-hero-shutter'),
                label: label,
                onTap: onTap,
              )
            : OurneyPillButton(
                key: const ValueKey('dock-snap-pill'),
                icon: Icons.photo_camera_rounded,
                semanticLabel: label,
                width: OurneyDock.pillSize.width,
                height: OurneyDock.pillSize.height,
                onPressed: onTap,
              ),
      ),
    );
  }
}

class _HeroShutter extends StatefulWidget {
  const _HeroShutter({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  State<_HeroShutter> createState() => _HeroShutterState();
}

class _HeroShutterState extends State<_HeroShutter> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final fg = readableOn(pTheme.primaryAccent);
    return Semantics(
      button: true,
      selected: true,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: () {
          OurneyHaptics.light();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? ourneyPressScale : 1,
          duration: OurneyMotion.movement(context, ourneyPressDuration),
          curve: Curves.easeOut,
          child: Container(
            width: OurneyDock.heroSize,
            height: OurneyDock.heroSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pTheme.primaryAccent,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: pTheme.primaryAccent.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.photo_camera_rounded, color: fg, size: 34),
          ),
        ),
      ),
    );
  }
}
