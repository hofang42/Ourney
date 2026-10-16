import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import 'safety_paths.dart';
import 'ui/blocked_users_screen.dart';
import 'ui/contact_screen.dart';
import 'ui/legal_screens.dart';
import 'ui/report_screens.dart';
import 'ui/safety_hub_screen.dart';

/// Safety (C3): hub, EULA, privacy, contact, EULA gate, report, block,
/// blocked list. All under `/safety` (reachable before sign-in); paths are
/// built with [SafetyPaths]. See lib/features/safety/README.md.
///
/// Contract (lib/features/README.md): keep exporting
/// `List<RouteBase> safetyRoutes`.
final List<RouteBase> safetyRoutes = [
  GoRoute(
    path: AppRoutes.safety,
    builder: (context, state) => const SafetyHubScreen(),
    routes: [
      GoRoute(
        path: 'eula',
        builder: (context, state) =>
            const LegalScreen(document: LegalDocument.eula),
        routes: [
          GoRoute(
            path: 'accept',
            builder: (context, state) => EulaAcceptScreen(from: state.uri),
          ),
        ],
      ),
      GoRoute(
        path: 'privacy',
        builder: (context, state) =>
            const LegalScreen(document: LegalDocument.privacy),
      ),
      GoRoute(
        path: 'contact',
        builder: (context, state) => const ContactScreen(),
      ),
      GoRoute(
        path: 'blocked',
        builder: (context, state) => const BlockedUsersScreen(),
      ),
      GoRoute(
        path: 'report/checkin/:checkInId',
        builder: (context, state) => ReportScreen(
          checkInId: state.pathParameters['checkInId'],
          userId: state.uri.queryParameters[SafetyPaths.userIdParam],
          name: state.uri.queryParameters[SafetyPaths.nameParam],
        ),
      ),
      GoRoute(
        path: 'report/user/:userId',
        builder: (context, state) => ReportScreen(
          userId: state.pathParameters['userId'],
          name: state.uri.queryParameters[SafetyPaths.nameParam],
        ),
      ),
      GoRoute(
        path: 'block/:userId',
        builder: (context, state) => BlockUserScreen(
          userId: state.pathParameters['userId']!,
          name: state.uri.queryParameters[SafetyPaths.nameParam],
        ),
      ),
    ],
  ),
];
