import 'package:ourney_core/ourney_core.dart';

import '../../app/app_routes.dart';
import 'data/journeys_providers.dart';

/// Sub-paths of the journeys feature that have no `AppRoutes` constant.
/// They live under the feature's own prefixes (`/journeys`, `/journey`).
abstract final class JourneysPaths {
  /// Create form seeded from a template: `/journeys/new/<template wire name>`.
  static String newFromTemplate(TemplateId id) =>
      '${AppRoutes.journeyNew}/${id.wireName}';

  /// Create form seeded with the Couple Rituals preset (`TemplateId.custom`
  /// with `💞` emoji): `/journeys/new/couple`.
  static String get newCoupleRitual => '${AppRoutes.journeyNew}/couple';

  /// Full-screen photo of one day: `/journey/<id>/day/<YYYY-MM-DD>`.
  static String day(String journeyId, LocalDate date) =>
      '${AppRoutes.journey(journeyId)}/day/$date';

  /// Camera with [journeyId] preselected (also stored in
  /// `camera.lastJourneyId`, see README.md).
  static String captureFor(String journeyId) => Uri(
    path: AppRoutes.capture,
    queryParameters: {captureJourneyParam: journeyId},
  ).toString();
}
