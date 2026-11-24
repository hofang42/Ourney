import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../ui/ui.dart';
import '../app_routes.dart';

/// 404 / unknown deep-link screen (`errorBuilder` of the app router, DE-14):
/// explains that the link or page was not found and provides a way back to the
/// camera instead of silently dropping the user onto `/capture`.
class NotFoundRedirect extends StatelessWidget {
  const NotFoundRedirect({super.key});

  void _back(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
    } else {
      context.go(AppRoutes.capture);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final material = Localizations.of<MaterialLocalizations>(
      context,
      MaterialLocalizations,
    );
    return UiScaffold(
      key: const ValueKey('not-found-screen'),
      padTop: 0,
      child: Column(
        children: [
          UiBackHeader(
            onBack: () => _back(context),
            backLabel: material?.backButtonTooltip ?? 'Back',
          ),
          UiEmptyState(
            key: const ValueKey('not-found-empty'),
            glyph: const OurneyIcon(name: 'search', size: 40),
            title: l10n?.notFound_title ?? 'Không tìm thấy trang này',
            body:
                l10n?.notFound_body ??
                'Liên kết này không tồn tại hoặc đã thay đổi.',
            actionLabel: l10n?.notFound_action ?? 'Về màn hình chụp',
            actionKey: const ValueKey('not-found-home'),
            onAction: () => context.go(AppRoutes.capture),
          ),
        ],
      ),
    );
  }
}
