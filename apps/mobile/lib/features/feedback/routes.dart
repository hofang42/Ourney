import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/navigator_keys.dart';
import 'ui/feature_request_detail_screen.dart';
import 'ui/feature_requests_screen.dart';

/// Feature Requests & Roadmap Board (`/feedback` and `/feedback/:id`).
/// Full-screen on the root navigator (outside the bottom dock).
final List<RouteBase> feedbackRoutes = [
  GoRoute(
    path: AppRoutes.feedback,
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) => const FeatureRequestsScreen(),
    routes: [
      GoRoute(
        path: ':id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            FeatureRequestDetailScreen(requestId: state.pathParameters['id']!),
      ),
    ],
  ),
];
