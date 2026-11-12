import 'package:ourney_core/ourney_core.dart';

/// The persona skin that styles [journey] (`CLAUDE.md` §4).
PersonaSkinId personaSkinOf(Journey journey) => personaSkinForTemplate(
  journey.templateId,
  kind: journey.kind,
  maxMembers: journey.maxMembers,
  emoji: journey.emoji,
);
