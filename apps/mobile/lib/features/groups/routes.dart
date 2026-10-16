import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/providers.dart';
import '../../shared/needs_server_view.dart';
import '../../shared/placeholder_screen.dart';
import 'l10n/generated/groups_localizations.dart';

/// PLACEHOLDER (A3): the groups feature agent (C1, Social) replaces the
/// screens.
///
/// Contract (lib/features/README.md): keep exporting
/// `List<RouteBase> groupsRoutes`; top-level paths must start with `/groups`
/// or `/join`. These routes live in the Groups tab of the shell.
/// `/join/:code` is the target of the `ourney://join/<code>` deep link.
///
/// Local-only mode (FR-A5): every group screen must show [NeedsServerView]
/// when `ref.watch(appConfigProvider).localOnly` is true.
final List<RouteBase> groupsRoutes = [
  GoRoute(
    path: AppRoutes.groups,
    builder: (context, state) => const _GroupsPlaceholder(id: 'groups'),
  ),
  GoRoute(
    path: '/join/:code',
    builder: (context, state) =>
        _GroupsPlaceholder(id: 'join', detail: state.pathParameters['code']),
  ),
];

class _GroupsPlaceholder extends ConsumerWidget {
  const _GroupsPlaceholder({required this.id, this.detail});

  final String id;
  final String? detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(appConfigProvider).localOnly) {
      return const Scaffold(body: SafeArea(child: NeedsServerView()));
    }
    final title = GroupsL10n.of(context).groups_title;
    return PlaceholderScreen(
      id: id,
      title: detail == null ? title : '$title · $detail',
    );
  }
}
