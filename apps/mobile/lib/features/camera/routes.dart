import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import 'capture_screen.dart';

/// Camera feature (B3). Capture tab (center); `/capture` is the app's
/// initial location (FR-C1). The captured photo goes to `/checkin`
/// (`checkinRoutes`) as a `CapturedPhoto` in `state.extra`.
final List<RouteBase> cameraRoutes = [
  GoRoute(
    path: AppRoutes.capture,
    builder: (context, state) => const CaptureScreen(),
  ),
];
