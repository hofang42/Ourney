import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import 'ui/reminders_screen.dart';

/// Reminders (C3). Full-screen settings page at `/reminders` (FR-G1, FR-G2).
///
/// Contract (lib/features/README.md): keep exporting
/// `List<RouteBase> remindersRoutes`; top-level paths start with a prefix
/// listed for 'reminders' in `featureRoutePrefixes`.
///
/// Integration hooks for other features: see `data/reminder_scheduler.dart`
/// (`rescheduleReminders(ref)`, `ReminderLifecycleHook`).
final List<RouteBase> remindersRoutes = [
  GoRoute(
    path: AppRoutes.reminders,
    builder: (context, state) => const RemindersScreen(),
  ),
];
