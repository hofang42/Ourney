import 'package:go_router/go_router.dart';

import '../../shared/placeholder_screen.dart';
import 'l10n/generated/share_card_localizations.dart';

/// PLACEHOLDER (A3): the share_card feature agent (C2 (Mobile UI B)) replaces the screens.
///
/// Contract (lib/features/README.md): keep exporting
/// `List<RouteBase> shareCardRoutes`; top-level paths must start with a prefix listed
/// for 'share_card' in `featureRoutePrefixes` (lib/app/app_routes.dart).
/// Full-screen. Build links with `AppRoutes.share(journeyId)`.
final List<RouteBase> shareCardRoutes = [
  GoRoute(
    path: '/share/:journeyId',
    builder: (context, state) => PlaceholderScreen(
      id: 'share_card',
      title: ShareCardL10n.of(context).share_card_title,
    ),
  ),
];
