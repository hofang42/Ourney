import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/providers.dart';
import '../../app/redirect.dart' show safeFrom;
import 'profile_edit_screen.dart';
import 'profile_screen.dart';
import 'profile_setup_screen.dart';

export 'profile_screen.dart' show profileEditPath, profileSetupPath;

/// Profile (FR-A2, FR-A4, FR-A5).
///
/// * `/profile` — view, settings links, sign out, delete account.
/// * `/profile/edit` — edit username / display name / avatar.
/// * `/profile/setup?from=<path>` — first-sign-in setup, opened by the auth
///   flow; continues to `from` (or `/capture`) when saved.
///
/// Contract (lib/features/README.md): keep exporting
/// `List<RouteBase> profileRoutes`. Full-screen (outside the tab shell).
final List<RouteBase> profileRoutes = [
  GoRoute(
    path: AppRoutes.profile,
    builder: (context, state) => const ProfileScreen(),
    routes: [
      GoRoute(
        path: 'edit',
        builder: (context, state) => const _BackendOnly(ProfileEditScreen()),
      ),
      GoRoute(
        path: 'setup',
        builder: (context, state) =>
            _BackendOnly(ProfileSetupScreen(from: safeFrom(state.uri))),
      ),
    ],
  ),
];

/// Local-only mode has no account: show the guest profile instead.
class _BackendOnly extends ConsumerWidget {
  const _BackendOnly(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(appConfigProvider).localOnly ? const ProfileScreen() : child;
}
