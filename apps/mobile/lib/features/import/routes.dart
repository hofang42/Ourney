import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import 'ui/import_flow_screen.dart';

/// Import a past journey (Figma `ImportJourneyFlow`, 3 stages in one route).
/// Full screen on the root navigator.
///
/// * `/import`   setup, library, review
final List<RouteBase> importRoutes = [
  GoRoute(
    path: AppRoutes.importJourney,
    builder: (context, state) => const ImportFlowScreen(),
  ),
];
