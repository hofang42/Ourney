import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../shared/placeholder_screen.dart';
import 'l10n/generated/journeys_localizations.dart';

/// PLACEHOLDER (A3): the journeys feature agent (B4, Mobile UI A) replaces
/// the screens.
///
/// Contract (lib/features/README.md): keep exporting
/// `List<RouteBase> journeysRoutes`; top-level paths must start with
/// `/journeys` or `/journey`. These routes live in the Journeys tab of the
/// shell. `/journey/:id` is the target of the `ourney://journey/<id>` deep
/// link; create flow goes under `/journeys/new` (`AppRoutes.journeyNew`).
final List<RouteBase> journeysRoutes = [
  GoRoute(
    path: AppRoutes.journeys,
    builder: (context, state) => PlaceholderScreen(
      id: 'journeys',
      title: JourneysL10n.of(context).journeys_title,
    ),
  ),
  GoRoute(
    path: '/journey/:id',
    builder: (context, state) => PlaceholderScreen(
      id: 'journey',
      title:
          '${JourneysL10n.of(context).journeys_title} · '
          '${state.pathParameters['id']}',
    ),
  ),
];
