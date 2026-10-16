import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import 'captured_photo.dart';
import 'checkin_screen.dart';

/// Check-in feature (B3). Full screen on the root navigator (covers the
/// bottom bar). Open with
/// `context.push(AppRoutes.checkin, extra: CapturedPhoto(...))`.
final List<RouteBase> checkinRoutes = [
  GoRoute(
    path: AppRoutes.checkin,
    builder: (context, state) {
      final extra = state.extra;
      return CheckinScreen(photo: extra is CapturedPhoto ? extra : null);
    },
  ),
];
