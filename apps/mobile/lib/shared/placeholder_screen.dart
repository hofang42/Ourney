import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import 'empty_state.dart';

/// Temporary screen used by feature placeholder route files until the real
/// feature screens land.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: ValueKey('placeholder-$name'),
      body: SafeArea(
        child: EmptyState(title: name, message: l10n.placeholder_comingSoon),
      ),
    );
  }
}
