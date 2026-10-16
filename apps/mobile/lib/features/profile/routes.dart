import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../shared/placeholder_screen.dart';
import 'l10n/generated/profile_localizations.dart';

/// PLACEHOLDER (A3): the profile feature agent (B2 (Mobile UI A)) replaces the screens.
///
/// Contract (lib/features/README.md): keep exporting
/// `List<RouteBase> profileRoutes`; top-level paths must start with a prefix listed
/// for 'profile' in `featureRoutePrefixes` (lib/app/app_routes.dart).
/// Full-screen (outside the tab shell).
final List<RouteBase> profileRoutes = [
  GoRoute(
    path: AppRoutes.profile,
    builder: (context, state) => PlaceholderScreen(
      id: 'profile',
      title: ProfileL10n.of(context).profile_title,
    ),
  ),
];
