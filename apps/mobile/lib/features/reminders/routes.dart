import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../shared/placeholder_screen.dart';
import 'l10n/generated/reminders_localizations.dart';

/// PLACEHOLDER (A3): the reminders feature agent (C3) replaces the screens.
///
/// Contract (lib/features/README.md): keep exporting
/// `List<RouteBase> remindersRoutes`; top-level paths must start with a prefix listed
/// for 'reminders' in `featureRoutePrefixes` (lib/app/app_routes.dart).
/// Full-screen (reminder settings).
final List<RouteBase> remindersRoutes = [
  GoRoute(
    path: AppRoutes.reminders,
    builder: (context, state) => PlaceholderScreen(
      id: 'reminders',
      title: RemindersL10n.of(context).reminders_title,
    ),
  ),
];
