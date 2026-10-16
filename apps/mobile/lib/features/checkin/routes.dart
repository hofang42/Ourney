import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../shared/placeholder_screen.dart';
import 'l10n/generated/checkin_localizations.dart';

/// PLACEHOLDER (A3): the checkin feature agent (B3 (Mobile UI B)) replaces the screens.
///
/// Contract (lib/features/README.md): keep exporting
/// `List<RouteBase> checkinRoutes`; top-level paths must start with a prefix listed
/// for 'checkin' in `featureRoutePrefixes` (lib/app/app_routes.dart).
/// Full-screen on the root navigator (covers the bottom bar). Pass the captured photo via `state.extra`.
final List<RouteBase> checkinRoutes = [
  GoRoute(
    path: AppRoutes.checkin,
    builder: (context, state) => PlaceholderScreen(
      id: 'checkin',
      title: CheckinL10n.of(context).checkin_title,
    ),
  ),
];
