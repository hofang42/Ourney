import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../ui/ui.dart';
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

/// Full-page frame of the safety screens: back header + scrolling body,
/// optional pinned [bottom] (kit `UiScaffold` + `UiBackHeader`).
class SafetyPage extends StatelessWidget {
  const SafetyPage({
    required this.pageKey,
    required this.onBack,
    required this.child,
    this.title,
    this.bottom,
    this.scroll = true,
    super.key,
  });

  final Key pageKey;
  final String? title;
  final VoidCallback? onBack;
  final Widget child;
  final Widget? bottom;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final header = onBack == null
        ? (title == null
              ? const SizedBox(height: UiSpace.md)
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: UiSpace.md),
                  child: Text(
                    title!,
                    textAlign: TextAlign.center,
                    style: UiText.h2(color: context.ui.ink),
                  ),
                ))
        : UiBackHeader(
            onBack: onBack!,
            backLabel: MaterialLocalizations.of(context).backButtonTooltip,
            title: title,
          );
    return KeyedSubtree(
      key: pageKey,
      child: UiScaffold(
        scroll: false,
        padTop: 0,
        padBottom: bottom == null ? 20 : 0,
        bottom: bottom == null
            ? null
            : Padding(
                padding: EdgeInsets.fromLTRB(
                  UiSpace.gutter(MediaQuery.sizeOf(context).width),
                  UiSpace.md,
                  UiSpace.gutter(MediaQuery.sizeOf(context).width),
                  UiSpace.lg,
                ),
                child: bottom,
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Expanded(
              child: scroll
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.only(top: UiSpace.sm),
                      child: child,
                    )
                  : child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Gentle support message shown with the self-harm reason (no phone
/// numbers: they differ per country and must not be guessed).
class SelfHarmSupportCard extends StatelessWidget {
  const SelfHarmSupportCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = SafetyL10n.of(context);
    final ui = context.ui;
    return UiCard(
      key: const ValueKey('safety-self-harm-support'),
      radius: UiRadius.card,
      color: ui.fill,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.favorite_rounded, color: ui.danger),
          const SizedBox(width: UiSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.safety_selfHarmTitle,
                  style: UiText.body(color: ui.ink, weight: FontWeight.w700),
                ),
                const SizedBox(height: UiSpace.xs),
                Text(
                  l10n.safety_selfHarmBody,
                  style: UiText.muted(color: ui.inkMuted),
                ),
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
    final ui = context.ui;
    return Padding(
      padding: const EdgeInsets.only(bottom: UiSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: UiText.body(color: ui.ink, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: UiSpace.sm),
          Text(body, style: UiText.muted(color: ui.inkMuted)),
        ],
      ),
    );
  }
}
