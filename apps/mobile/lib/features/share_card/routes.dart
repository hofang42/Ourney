import 'package:go_router/go_router.dart';

import 'ui/share_card_screen.dart';

/// Share card feature (C2). Contract (lib/features/README.md): exports
/// `List<RouteBase> shareCardRoutes`; top-level paths start with `/share`.
/// Full screen. Build links with `AppRoutes.share(journeyId)`.
///
/// * `/share/:journeyId`  card preview, share sheet, solo public link
final List<RouteBase> shareCardRoutes = [
  GoRoute(
    path: '/share/:journeyId',
    builder: (context, state) =>
        ShareCardScreen(journeyId: state.pathParameters['journeyId']!),
  ),
];
