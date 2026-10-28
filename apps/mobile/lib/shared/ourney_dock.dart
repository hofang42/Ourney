import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart' show buildAppTheme, kBodyFont;
import '../app/theme/motion.dart';
import '../app/theme/persona_theme.dart';
import '../app/theme/tokens.dart';
import '../l10n/generated/app_localizations.dart';
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
            // V1.0: translucent paper bar over the content, hairline top.
            color: onCapture
                ? OurneyColors.cameraBg
                : pTheme.surface.withValues(alpha: 0.92),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: onCapture
                        ? Colors.white.withValues(alpha: 0.12)
                        : OurneyColors.of(context).divider,
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
                        const SizedBox(width: 26),
                        Expanded(
                          child: _DockTab(
                            key: const ValueKey('dock-journeys'),
                            icon: Icons.map_outlined,
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
                            icon: Icons.people_outline_rounded,
                            label: l10n.nav_groups,
                            selected: currentIndex == groupsIndex,
                            onTap: () => onSelect(groupsIndex),
                          ),
                        ),
                        const SizedBox(width: 26),
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
    // Selected = ink + bold label (V1.0 dock has no indicator bar); the
    // selected state is also announced through semantics.
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
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: kBodyFont,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  height: 1.3,
                  color: color,
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
                icon: Icons.photo_camera_outlined,
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
          // V1.0 shutter: a 3dp white ring around a 64dp accent disc.
          child: Container(
            width: OurneyDock.heroSize,
            height: OurneyDock.heroSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pTheme.primaryAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
