import 'package:ourney_core/ourney_core.dart';

/// The persona skin that styles [journey] (`CLAUDE.md` section 4): the owner's
/// layout override (`journeys.layout`, edit screen "Giao dien") when set,
/// otherwise the one derived from the template.
PersonaSkinId personaSkinOf(Journey journey) =>
    journey.layout ?? defaultSkinOf(journey);

/// The skin [journey] would have without a layout override.
PersonaSkinId defaultSkinOf(Journey journey) =>
    journey.coupleSelfName != null
    ? PersonaSkinId.coupleRituals
    : personaSkinForTemplate(
        journey.templateId,
        kind: journey.kind,
        maxMembers: journey.maxMembers,
      );
