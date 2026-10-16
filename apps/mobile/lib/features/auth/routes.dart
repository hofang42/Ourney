import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../shared/placeholder_screen.dart';
import 'l10n/generated/auth_localizations.dart';

/// PLACEHOLDER (A3): the auth feature agent (B2 (Mobile UI A)) replaces the screens.
///
/// Contract (lib/features/README.md): keep exporting
/// `List<RouteBase> authRoutes`; top-level paths must start with a prefix listed
/// for 'auth' in `featureRoutePrefixes` (lib/app/app_routes.dart).
/// Full-screen (outside the tab shell).
final List<RouteBase> authRoutes = [
  GoRoute(
    path: AppRoutes.auth,
    builder: (context, state) =>
        PlaceholderScreen(id: 'auth', title: AuthL10n.of(context).auth_title),
  ),
];
