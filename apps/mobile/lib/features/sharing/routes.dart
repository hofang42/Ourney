import 'package:go_router/go_router.dart';

import 'ui/follow_journey_screen.dart';
import 'ui/insights_screen.dart';
import 'ui/retell_screen.dart';
import 'ui/share_journey_sheet.dart';
import 'ui/shared_journey_screen.dart';
import 'ui/story_editor_screen.dart';

/// Journey sharing (docs/09 S1–S40). Full screen on the root navigator.
///
/// * `/sharing/:journeyId`           share this journey (SCR-82)
/// * `/sharing/:journeyId/story`     prepare the story (SCR-83)
/// * `/sharing/:journeyId/insights`  insights (SCR-88)
/// * `/shared/:journeyId`            shared journey, friend / member (SCR-84)
/// * `/p/:token`                     public journey in the app (SCR-84)
/// * `/follow/:journeyId`            do this journey (SCR-87)
/// * `/retell`                       retell a past journey (SCR-28)
final List<RouteBase> sharingRoutes = [
  GoRoute(
    path: '/sharing/:journeyId',
    builder: (context, state) =>
        ShareJourneyScreen(journeyId: state.pathParameters['journeyId']!),
    routes: [
      GoRoute(
        path: 'story',
        builder: (context, state) =>
            StoryEditorScreen(journeyId: state.pathParameters['journeyId']!),
      ),
      GoRoute(
        path: 'insights',
        builder: (context, state) =>
            InsightsScreen(journeyId: state.pathParameters['journeyId']!),
      ),
    ],
  ),
  GoRoute(
    path: '/shared/:journeyId',
    builder: (context, state) =>
        SharedJourneyScreen.byId(journeyId: state.pathParameters['journeyId']!),
  ),
  GoRoute(
    path: '/p/:token',
    builder: (context, state) =>
        SharedJourneyScreen.byToken(token: state.pathParameters['token']!),
  ),
  GoRoute(
    path: '/follow/:journeyId',
    builder: (context, state) =>
        FollowJourneyScreen(journeyId: state.pathParameters['journeyId']!),
  ),
  GoRoute(path: '/retell', builder: (context, state) => const RetellScreen()),
];
