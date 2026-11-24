import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../ui/ui.dart';
import 'captured_photo.dart';
import 'checkin_screen.dart';

/// Check-in feature (B3). Full screen on the root navigator (covers the
/// bottom bar). Open with
/// `context.push(AppRoutes.checkin, extra: CapturedPhoto(...))`.
final List<RouteBase> checkinRoutes = [
  GoRoute(
    path: AppRoutes.checkin,
    pageBuilder: (context, state) {
      final extra = state.extra;
      return buildUiPage<void>(
        context: context,
        state: state,
        kind: UiPageTransition.sharedZ,
        child: CheckinScreen(photo: extra is CapturedPhoto ? extra : null),
      );
    },
  ),
];
