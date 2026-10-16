import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/tokens.dart';
import '../../../shared/ourney_card.dart';
import '../data/safety_providers.dart';
import '../l10n/generated/safety_localizations.dart';

String safetyFailureMessage(SafetyL10n l10n, Object error) =>
    switch (safetyFailureOf(error)) {
      SafetyFailure.rateLimited => l10n.safety_errorRateLimited,
      SafetyFailure.notFound => l10n.safety_errorNotFound,
      SafetyFailure.invalid => l10n.safety_errorInvalid,
      SafetyFailure.offline => l10n.safety_errorOffline,
      SafetyFailure.generic => l10n.safety_errorGeneric,
    };

/// Pops when possible, otherwise goes to [fallback] (deep-linked pages).
void closeOr(BuildContext context, String fallback, [Object? result]) {
  if (context.canPop()) {
    context.pop(result);
  } else {
    context.go(fallback);
  }
}

/// Gentle support message shown with the self-harm reason (no phone
/// numbers: they differ per country and must not be guessed).
class SelfHarmSupportCard extends StatelessWidget {
  const SelfHarmSupportCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = SafetyL10n.of(context);
    final text = Theme.of(context).textTheme;
    final c = OurneyColors.of(context);
    return OurneyCard(
      key: const ValueKey('safety-self-harm-support'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.favorite_rounded, color: c.accent),
          const SizedBox(width: OurneySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.safety_selfHarmTitle, style: text.titleMedium),
                const SizedBox(height: OurneySpacing.xs),
                Text(l10n.safety_selfHarmBody, style: text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section heading + paragraph used by the legal pages.
class LegalSection extends StatelessWidget {
  const LegalSection({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: OurneySpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(title, style: text.titleMedium)),
          const SizedBox(height: OurneySpacing.sm),
          Text(body, style: text.bodyMedium),
        ],
      ),
    );
  }
}
