import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../app/theme/motion.dart';
import '../app/theme/persona_theme.dart';
import '../app/theme/tokens.dart';
import 'persona_contract.dart';
import 'persona_registry.dart';

/// Cross-fade between two persona layouts (`docs/06` §1 Q1).
const Duration personaSwitchDuration = OurneyDurations.personaSwitch;

/// Makes [OurneyPersonaTheme.of] resolve to [skin] for [child], whatever the
/// app-wide theme currently is.
///
/// A journey screen shows the persona of the journey it displays, which can
/// differ from the active one (a detail page opened from the Hub, a share
/// card). Without a scope its persona widgets would be drawn in the wrong
/// colors. Does nothing when the ambient theme already matches.
class PersonaSkinScope extends StatelessWidget {
  const PersonaSkinScope({required this.skin, required this.child, super.key});

  final PersonaSkinId skin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.extension<OurneyPersonaTheme>()?.skinId == skin) return child;
    final persona = OurneyPersonaTheme.forSkin(skin, theme.brightness);
    return Theme(
      data: theme.copyWith(
        extensions: [
          for (final e in theme.extensions.values)
            if (e is! OurneyPersonaTheme) e,
          persona,
        ],
      ),
      child: child,
    );
  }
}

/// Shared mechanics of the four switchers: scope the skin, then cross-fade
/// when the skin changes. The switched child owns no hardware (the camera
/// preview is passed in), so a switch never restarts anything.
class _PersonaSwitcher extends StatelessWidget {
  const _PersonaSwitcher({
    required this.skin,
    required this.name,
    required this.builder,
    this.expand = false,
  });

  final PersonaSkinId skin;
  final String name;
  final WidgetBuilder builder;

  /// Fill the parent (camera HUD) instead of sizing to the child.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: OurneyMotion.duration(context, personaSwitchDuration),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        fit: expand ? StackFit.expand : StackFit.loose,
        children: [...previous, ?current],
      ),
      child: KeyedSubtree(
        key: ValueKey('persona-$name-${skin.name}'),
        child: PersonaSkinScope(
          skin: skin,
          child: Builder(builder: builder),
        ),
      ),
    );
  }
}

/// Timeline of the journey detail screen (F3).
class PersonaTimelineSwitcher extends StatelessWidget {
  const PersonaTimelineSwitcher({
    required this.skin,
    required this.data,
    super.key,
  });

  final PersonaSkinId skin;
  final PersonaTimelineData data;

  @override
  Widget build(BuildContext context) => _PersonaSwitcher(
    skin: skin,
    name: 'timeline',
    builder: (context) => personaStyleFor(skin).timeline(context, data),
  );
}

/// Camera HUD over the live preview (F3). The preview is [PersonaCameraData.viewfinder],
/// built once by the capture screen, so switching persona never touches the
/// `CameraController`.
class PersonaCameraHudSwitcher extends StatelessWidget {
  const PersonaCameraHudSwitcher({
    required this.skin,
    required this.data,
    super.key,
  });

  final PersonaSkinId skin;
  final PersonaCameraData data;

  @override
  Widget build(BuildContext context) => _PersonaSwitcher(
    skin: skin,
    name: 'camera',
    expand: true,
    builder: (context) => personaStyleFor(skin).camera(context, data),
  );
}

/// Share board of the share-card screen (F3).
class PersonaShareSwitcher extends StatelessWidget {
  const PersonaShareSwitcher({
    required this.skin,
    required this.data,
    super.key,
  });

  final PersonaSkinId skin;
  final PersonaShareData data;

  @override
  Widget build(BuildContext context) => _PersonaSwitcher(
    skin: skin,
    name: 'share',
    builder: (context) => personaStyleFor(skin).share(context, data),
  );
}

/// Squad wall of the group "Today" screen (F3).
///
/// Personas without a wall show [fallback], the screen's default header and
/// member list. Personas with a wall show it above [membersFooter]: the
/// member list that carries the report, block and remove actions (FR-F1/F2,
/// store policy), which a wall tile does not offer yet.
class PersonaGroupSwitcher extends StatelessWidget {
  const PersonaGroupSwitcher({
    required this.skin,
    required this.data,
    required this.fallback,
    required this.membersFooter,
    super.key,
  });

  final PersonaSkinId skin;
  final PersonaGroupData data;
  final WidgetBuilder fallback;
  final WidgetBuilder membersFooter;

  @override
  Widget build(BuildContext context) => _PersonaSwitcher(
    skin: skin,
    name: 'group',
    builder: (context) {
      final wall = personaStyleFor(skin).group;
      if (wall == null) return fallback(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [wall(context, data), membersFooter(context)],
      );
    },
  );
}
