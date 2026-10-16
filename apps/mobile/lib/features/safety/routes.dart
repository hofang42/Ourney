import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../shared/placeholder_screen.dart';
import 'l10n/generated/safety_localizations.dart';

/// PLACEHOLDER (A3): the safety feature agent (C3) replaces the screens.
///
/// Contract (lib/features/README.md): keep exporting
/// `List<RouteBase> safetyRoutes`; top-level paths must start with a prefix listed
/// for 'safety' in `featureRoutePrefixes` (lib/app/app_routes.dart).
/// Full-screen. Reachable before sign-in (EULA/privacy/contact).
final List<RouteBase> safetyRoutes = [
  GoRoute(
    path: AppRoutes.safety,
    builder: (context, state) => PlaceholderScreen(
      id: 'safety',
      title: SafetyL10n.of(context).safety_title,
    ),
  ),
];
