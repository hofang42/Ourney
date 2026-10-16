import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';
import '../../shared/chunky_button.dart';
import 'l10n/generated/onboarding_localizations.dart';

/// FR-A3 onboarding: three pages (value prop, how check-in works, ready).
///
/// No permission prompts here: camera and notification access are requested
/// in context by the camera and reminders features. Finishing (or skipping)
/// calls `onboardingCompleteProvider.notifier.complete()`; the router redirect
/// then moves on by itself.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const pageCount = 3;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == OnboardingScreen.pageCount - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _complete() =>
      ref.read(onboardingCompleteProvider.notifier).complete();

  void _next() {
    if (_isLast) {
      OurneyHaptics.success();
      unawaited(_complete());
      return;
    }
    final target = _page + 1;
    if (OurneyMotion.reduced(context)) {
      _controller.jumpToPage(target);
    } else {
      _controller.animateToPage(
        target,
        duration: OurneyDurations.navigation,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = OnboardingL10n.of(context);
    final c = OurneyColors.of(context);
    final pages = [
      _OnboardingPage(
        key: const ValueKey('onboarding-page-0'),
        eyebrow: l10n.onboarding_title,
        icon: Icons.photo_camera_rounded,
        gradient: OurneyColors.heroGradient,
        title: l10n.onboarding_valueTitle,
        body: Text(
          l10n.onboarding_valueBody,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: c.inkMuted),
        ),
      ),
      _OnboardingPage(
        key: const ValueKey('onboarding-page-1'),
        icon: Icons.bolt_rounded,
        gradient: OurneyColors.warmGradient,
        title: l10n.onboarding_howTitle,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Step(
              index: 1,
              icon: Icons.photo_camera_outlined,
              text: l10n.onboarding_howStep1,
            ),
            _Step(
              index: 2,
              icon: Icons.edit_note_rounded,
              text: l10n.onboarding_howStep2,
            ),
            _Step(
              index: 3,
              icon: Icons.local_fire_department_rounded,
              text: l10n.onboarding_howStep3,
            ),
          ],
        ),
      ),
      _OnboardingPage(
        key: const ValueKey('onboarding-page-2'),
        icon: Icons.rocket_launch_rounded,
        gradient: OurneyColors.heroGradient,
        title: l10n.onboarding_readyTitle,
        body: Text(
          l10n.onboarding_readyBody,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: c.inkMuted),
        ),
      ),
    ];

    return Scaffold(
      key: const ValueKey('onboarding-screen'),
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: OurneySizes.minTap + OurneySpacing.sm,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: _isLast ? 0 : 1,
                  duration: OurneyMotion.duration(context, OurneyDurations.tap),
                  child: _isLast
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(
                            right: OurneySpacing.sm,
                          ),
                          child: TextButton(
                            key: const ValueKey('onboarding-skip'),
                            onPressed: _complete,
                            child: Text(l10n.onboarding_skip),
                          ),
                        ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (p) {
                  OurneyHaptics.selection();
                  setState(() => _page = p);
                },
                children: pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                OurneySpacing.screenMargin,
                OurneySpacing.md,
                OurneySpacing.screenMargin,
                OurneySpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Dots(
                    count: OnboardingScreen.pageCount,
                    current: _page,
                    label: l10n.onboarding_pageSemantics(
                      _page + 1,
                      OnboardingScreen.pageCount,
                    ),
                  ),
                  const SizedBox(height: OurneySpacing.xl),
                  ChunkyButton(
                    key: const ValueKey('onboarding-next'),
                    label: _isLast
                        ? l10n.onboarding_start
                        : l10n.onboarding_next,
                    icon: _isLast
                        ? Icons.photo_camera_rounded
                        : Icons.arrow_forward_rounded,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.body,
    this.eyebrow,
    super.key,
  });

  final IconData icon;
  final Gradient gradient;
  final String title;
  final Widget body;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = OurneyColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: OurneySpacing.screenMargin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: AspectRatio(
              aspectRatio: 1.25,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(OurneyRadii.media),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -24,
                      top: -24,
                      child: _Blob(size: 120, color: c.sun),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: _Blob(
                        size: 140,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Icon(icon, size: 56, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: OurneySpacing.xl),
          if (eyebrow != null) ...[
            Text(
              eyebrow!,
              style: text.labelLarge?.copyWith(color: c.primaryDeep),
            ),
            const SizedBox(height: OurneySpacing.xs),
          ],
          Semantics(
            header: true,
            child: Text(title, style: text.displayMedium),
          ),
          const SizedBox(height: OurneySpacing.md),
          body,
          const SizedBox(height: OurneySpacing.lg),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _Step extends StatelessWidget {
  const _Step({required this.index, required this.icon, required this.text});

  final int index;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: OurneySpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Container(
              width: OurneySizes.minTap,
              height: OurneySizes.minTap,
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(OurneyRadii.chip),
              ),
              child: Icon(icon, color: c.primaryDeep),
            ),
          ),
          const SizedBox(width: OurneySpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: OurneySpacing.sm),
              child: Text(
                '$index. $text',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Page indicator; the active page is longer (not color-only).
class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.current,
    required this.label,
  });

  final int count;
  final int current;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    return Semantics(
      label: label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: OurneyMotion.movement(context, OurneyDurations.tap),
                margin: const EdgeInsets.symmetric(
                  horizontal: OurneySpacing.xs,
                ),
                width: i == current ? 28 : 10,
                height: 10,
                decoration: BoxDecoration(
                  color: i == current
                      ? c.primary
                      : c.inkMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(OurneyRadii.capsule),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
