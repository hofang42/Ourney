import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import 'empty_state.dart';

/// Temporary screen used by the placeholder `lib/features/*/routes.dart`
/// files until the real feature screens land. Delete usages, not this file
/// (other placeholders may still use it).
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.id, this.title, super.key});

  /// Stable id used for the widget key `placeholder-<id>` (tests).
  final String id;

  /// Localized title; falls back to [id].
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: ValueKey('placeholder-$id'),
      body: SafeArea(
        child: EmptyState(
          title: title ?? id,
          message: l10n.placeholder_comingSoon,
        ),
      ),
    );
  }
}
