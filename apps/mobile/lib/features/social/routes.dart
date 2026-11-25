import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/navigator_keys.dart';
import '../../ui/motion.dart';
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
    pageBuilder: (context, state) => buildUiPage<void>(
      context: context,
      state: state,
      kind: UiPageTransition.sharedZ,
      child: const FriendsScreen(),
    ),
    routes: [
      GoRoute(
        path: 'add',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildUiPage<void>(
          context: context,
          state: state,
          kind: UiPageTransition.verticalSheet,
          child: const AddFriendsScreen(),
        ),
      ),
    ],
  ),
  GoRoute(
    path: '/chat/:id',
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) => buildUiPage<void>(
      context: context,
      state: state,
      kind: UiPageTransition.sharedX,
      child: ChatScreen(
        conversationId: state.pathParameters['id']!,
        replyToCheckInId: state.uri.queryParameters['replyTo'],
      ),
    ),
  ),
  GoRoute(
    path: '/f/:token',
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) {
      final token = state.pathParameters['token']!;
      return buildUiPage<void>(
        context: context,
        state: state,
        pageKey: ValueKey('${state.pageKey.value}:$token'),
        kind: UiPageTransition.verticalSheet,
        child: InviteAcceptScreen(token: token),
      );
    },
  ),
];

/// Activity tab (V2 `ActivityScreen`): `/inbox` inside the bottom-bar shell.
final List<RouteBase> activityRoutes = [
  GoRoute(
    path: AppRoutes.inbox,
    builder: (context, state) => const InboxScreen(),
  ),
];
