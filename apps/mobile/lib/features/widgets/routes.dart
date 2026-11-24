import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import 'ui/widgets_screen.dart';

/// Home-Screen Widgets, Lock-Screen Widgets & Live Activities gallery and
/// privacy configuration screen at `/widgets` (§3.1 #6, §7.2, §9).
///
/// Contract (`lib/features/README.md`): exports `List<RouteBase> widgetsRoutes`
/// whose top-level paths start with a prefix listed for `'widgets'` in
/// `featureRoutePrefixes`.
final List<RouteBase> widgetsRoutes = [
  GoRoute(
    path: AppRoutes.widgets,
    builder: (context, state) => const WidgetsScreen(),
  ),
];
