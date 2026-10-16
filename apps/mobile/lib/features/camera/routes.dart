import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import 'capture_screen.dart';

/// Camera feature (B3). Capture tab (center); `/capture` is the app's
/// initial location (FR-C1). The captured photo goes to `/checkin`
/// (`checkinRoutes`) as a `CapturedPhoto` in `state.extra`.
/// `/capture?journeyId=<id>` preselects that journey (e.g. from a journey
/// screen or a reminder notification).
final List<RouteBase> cameraRoutes = [
  GoRoute(
    path: AppRoutes.capture,
    builder: (context, state) => CaptureScreen(
      initialJourneyId: state.uri.queryParameters[CaptureScreen.journeyIdParam],
    ),
  ),
];
