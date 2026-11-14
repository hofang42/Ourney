import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/navigator_keys.dart';
import 'ui/add_friends_screen.dart';
import 'ui/chat_screen.dart';
import 'ui/friends_screen.dart';
import 'ui/inbox_screen.dart';
import 'ui/invite_accept_screen.dart';

/// Social feature (friends, inbox, chat). Contract (lib/features/README.md):
/// exports `List<RouteBase> socialRoutes`. Every screen is full screen on
/// the root navigator and shows `NeedsServerView` in local-only mode.
///
/// * `/friends`       SCR-80 friends and requests
/// * `/friends/add`   SCR-81 invite link, QR, find by @username
/// * `/inbox`         SCR-85
/// * `/chat/:id`      SCR-86
/// * `/f/:token`      invite link (`ourney://friend/<token>`)
final List<RouteBase> socialRoutes = [
  GoRoute(
    path: AppRoutes.friends,
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) => const FriendsScreen(),
    routes: [
      GoRoute(
        path: 'add',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddFriendsScreen(),
      ),
    ],
  ),
  GoRoute(
    path: '/chat/:id',
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) =>
        ChatScreen(conversationId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/f/:token',
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) =>
        InviteAcceptScreen(token: state.pathParameters['token']!),
  ),
];

/// Activity tab (V2 `ActivityScreen`): `/inbox` inside the bottom-bar shell.
final List<RouteBase> activityRoutes = [
  GoRoute(
    path: AppRoutes.inbox,
    builder: (context, state) => const InboxScreen(),
  ),
];
