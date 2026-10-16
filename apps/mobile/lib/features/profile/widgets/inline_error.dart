import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';

/// Inline error with an icon (state is not conveyed by color alone),
/// announced to screen readers. Used by the auth and profile screens.
class InlineError extends StatelessWidget {
  const InlineError({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(OurneySpacing.md),
        decoration: BoxDecoration(
          color: c.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(OurneyRadii.chip),
          border: Border.all(color: c.danger.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: c.danger),
            const SizedBox(width: OurneySpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: c.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
