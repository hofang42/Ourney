import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../ui/ui.dart';
import 'capture_screen.dart';

/// Camera feature (B3). Capture tab (center); `/capture` is the app's
/// initial location (FR-C1). The captured photo goes to `/checkin`
/// (`checkinRoutes`) as a `CapturedPhoto` in `state.extra`.
/// `/capture?journeyId=<id>` preselects that journey (e.g. from a journey
/// screen or a reminder notification).
final List<RouteBase> cameraRoutes = [
  GoRoute(
    path: AppRoutes.capture,
    pageBuilder: (context, state) => buildUiPage<void>(
      context: context,
      state: state,
      kind: UiPageTransition.fadeThrough,
      // The camera page and its session survive query-only navigation.
      child: Builder(
        builder: (context) => CaptureScreen(
          initialJourneyId: GoRouterState.of(context)
              .uri
              .queryParameters[CaptureScreen.journeyIdParam],
        ),
      ),
    ),
  ),
];
