import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import 'ui/import_flow_screen.dart';

/// Retell a past journey: photos, timeline check, details, durable saving.
/// Full screen on the root navigator.
///
/// * `/import`   the flow
/// * `/retell`   legacy alias, redirects to `/import`
final List<RouteBase> importRoutes = [
  GoRoute(
    path: AppRoutes.importJourney,
    builder: (context, state) => const ImportFlowScreen(),
  ),
  GoRoute(
    path: AppRoutes.retell,
    redirect: (context, state) => AppRoutes.importJourney,
  ),
];
