import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/navigator_keys.dart';
import '../../ui/motion.dart';
import 'groups_paths.dart';
import 'ui/group_today_screen.dart';
import 'ui/groups_list_screen.dart';
import 'ui/invite_screen.dart';
import 'ui/join_screen.dart';

/// Groups feature (C1). Contract (lib/features/README.md): exports
/// `List<RouteBase> groupsRoutes`; top-level paths start with `/groups` or
/// `/join`. They live in the Groups tab of the shell.
///
/// * `/groups`                      list of group journeys (tab root)
/// * `/groups/:journeyId`           group "Today" screen (FR-D3)
/// * `/groups/:journeyId/invite`    code, link, QR (full screen)
/// * `/join`                        manual code entry (FR-D1)
/// * `/join/:code`                  `ourney://join/<code>` preview + join
///
/// Every screen shows `NeedsServerView` in local-only mode (FR-A5). Build
/// links with `AppRoutes` / `GroupsPaths` (groups_paths.dart).
final List<RouteBase> groupsRoutes = [
  GoRoute(
    path: AppRoutes.groups,
    builder: (context, state) => const GroupsListScreen(),
    routes: [
      GoRoute(
        path: ':journeyId',
        pageBuilder: (context, state) => buildUiPage<void>(
          context: context,
          state: state,
          kind: UiPageTransition.sharedZ,
          child: GroupTodayScreen(
            journeyId: state.pathParameters['journeyId']!,
          ),
        ),
        routes: [
          GoRoute(
            path: 'invite',
            parentNavigatorKey: rootNavigatorKey,
            pageBuilder: (context, state) => buildUiPage<void>(
              context: context,
              state: state,
              kind: UiPageTransition.verticalSheet,
              child: InviteScreen(
                journeyId: state.pathParameters['journeyId']!,
              ),
            ),
          ),
        ],
      ),
    ],
  ),
  GoRoute(
    path: GroupsPaths.joinEntry,
    pageBuilder: (context, state) => buildUiPage<void>(
      context: context,
      state: state,
      kind: UiPageTransition.verticalSheet,
      child: const JoinScreen(),
    ),
    routes: [
      GoRoute(
        path: ':code',
        pageBuilder: (context, state) {
          final code = state.pathParameters['code']!;
          return buildUiPage<void>(
            context: context,
            state: state,
            pageKey: ValueKey('${state.pageKey.value}:$code'),
            kind: UiPageTransition.verticalSheet,
            child: JoinScreen(initialCode: code),
          );
        },
      ),
    ],
  ),
];
