import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/navigator_keys.dart';
import 'ui/create_journey_screen.dart';
import 'ui/day_viewer_screen.dart';
import 'ui/journey_detail_screen.dart';
import 'ui/journeys_list_screen.dart';
import 'ui/template_picker_screen.dart';

/// Journeys feature (B4). Contract (lib/features/README.md): exports
/// `List<RouteBase> journeysRoutes`; top-level paths start with `/journeys`
/// or `/journey`. They live in the Journeys tab of the shell.
///
/// * `/journeys`                   list (tab root)
/// * `/journeys/new`               template picker (full screen)
/// * `/journeys/new/:template`     create form, `:template` = wire name
/// * `/journey/:id`                detail + timeline (`ourney://journey/<id>`)
/// * `/journey/:id/day/:date`      photo viewer, `:date` = YYYY-MM-DD
///
/// Build links with `AppRoutes` / `JourneysPaths` (journeys_paths.dart).
final List<RouteBase> journeysRoutes = [
  GoRoute(
    path: AppRoutes.journeys,
    builder: (context, state) => const JourneysListScreen(),
    routes: [
      GoRoute(
        path: 'new',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const TemplatePickerScreen(),
        routes: [
          GoRoute(
            path: ':template',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final raw = state.pathParameters['template'];
              return CreateJourneyScreen(
                templateId: CreateJourneyScreen.parseTemplate(raw),
                isCouplePreset: CreateJourneyScreen.isCoupleWire(raw),
              );
            },
          ),
        ],
      ),
    ],
  ),
  GoRoute(
    path: '/journey/:id',
    builder: (context, state) =>
        JourneyDetailScreen(journeyId: state.pathParameters['id']!),
    routes: [
      GoRoute(
        path: 'day/:date',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => DayViewerScreen(
          journeyId: state.pathParameters['id']!,
          date: DayViewerScreen.parseDate(state.pathParameters['date']),
        ),
      ),
    ],
  ),
];
