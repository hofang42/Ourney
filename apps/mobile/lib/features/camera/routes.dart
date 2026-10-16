import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../shared/placeholder_screen.dart';
import 'l10n/generated/camera_localizations.dart';

/// PLACEHOLDER (A3): the camera feature agent (B3 (Mobile UI B)) replaces the screens.
///
/// Contract (lib/features/README.md): keep exporting
/// `List<RouteBase> cameraRoutes`; top-level paths must start with a prefix listed
/// for 'camera' in `featureRoutePrefixes` (lib/app/app_routes.dart).
/// Capture tab (center); `/capture` is the app's initial location (FR-C1).
final List<RouteBase> cameraRoutes = [
  GoRoute(
    path: AppRoutes.capture,
    builder: (context, state) => PlaceholderScreen(
      id: 'camera',
      title: CameraL10n.of(context).camera_title,
    ),
  ),
];
