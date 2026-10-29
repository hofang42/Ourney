import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart' show displayStyle;
import '../../app/theme/motion.dart';
import '../../app/theme/persona_theme.dart';
import '../../app/theme/tokens.dart';
import '../../shared/ourney_primary_button.dart';
import '../../shared/persona_pill.dart';
import '../../shared/template_icons.dart';
import 'l10n/generated/onboarding_localizations.dart';

/// FR-A3 onboarding: three pages (value prop, how check-in works, ready).
///
/// Built on the neutral Ourney Editorial Base (`OurneyPersonaTheme`) in both
/// Light and Dark mode, with architectural cards and vector icons (zero AI-slop
/// rainbow gradients or floating decorative blobs).
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
    final brightness = Theme.of(context).brightness;
    final pTheme = OurneyPersonaTheme.editorialNeutralBase(brightness);
    final text = Theme.of(context).textTheme;

    final pages = [
      _OnboardingPage(
        key: const ValueKey('onboarding-page-0'),
        eyebrow: l10n.onboarding_title,
        title: l10n.onboarding_valueTitle,
        hero: _PersonaShowcaseDeck(brightness: brightness, pTheme: pTheme),
        body: Text(
          l10n.onboarding_valueBody,
          textAlign: TextAlign.center,
          style: text.bodyLarge?.copyWith(color: pTheme.inkMuted, height: 1.45),
        ),
      ),
      _OnboardingPage(
        key: const ValueKey('onboarding-page-1'),
        title: l10n.onboarding_howTitle,
        hero: _RitualFlowHero(pTheme: pTheme),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Step(
              index: 1,
              icon: Icons.photo_camera_outlined,
              text: l10n.onboarding_howStep1,
              pTheme: pTheme,
            ),
            _Step(
              index: 2,
              icon: Icons.tune_rounded,
              text: l10n.onboarding_howStep2,
              pTheme: pTheme,
            ),
            _Step(
              index: 3,
              icon: Icons.local_fire_department_rounded,
              text: l10n.onboarding_howStep3,
              pTheme: pTheme,
            ),
          ],
        ),
      ),
      _OnboardingPage(
        key: const ValueKey('onboarding-page-2'),
        title: l10n.onboarding_readyTitle,
        hero: _ReadyViewfinderHero(pTheme: pTheme),
        body: Text(
          l10n.onboarding_readyBody,
          textAlign: TextAlign.center,
          style: text.bodyLarge?.copyWith(color: pTheme.inkMuted, height: 1.45),
        ),
      ),
    ];

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: pTheme.background,
        extensions: [
          for (final e in Theme.of(context).extensions.values)
            if (e is! OurneyPersonaTheme) e,
          pTheme,
        ],
      ),
      child: Scaffold(
        key: const ValueKey('onboarding-screen'),
        backgroundColor: pTheme.background,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: OurneySizes.minTap + OurneySpacing.sm,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedOpacity(
                    opacity: _isLast ? 0 : 1,
                    duration: OurneyMotion.duration(
                      context,
                      OurneyDurations.tap,
                    ),
                    child: _isLast
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(
                              right: OurneySpacing.sm,
                            ),
                            child: TextButton(
                              key: const ValueKey('onboarding-skip'),
                              style: TextButton.styleFrom(
                                foregroundColor: pTheme.inkMuted,
                                minimumSize: const Size(
                                  OurneySizes.minTap,
                                  OurneySizes.minTap,
                                ),
                              ),
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
                      pTheme: pTheme,
                      label: l10n.onboarding_pageSemantics(
                        _page + 1,
                        OnboardingScreen.pageCount,
                      ),
                    ),
                    const SizedBox(height: OurneySpacing.xl),
                    OurneyPrimaryButton(
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
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.hero,
    required this.title,
    required this.body,
    this.eyebrow,
    super.key,
  });

  final Widget hero;
  final String title;
  final Widget body;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: OurneySpacing.screenMargin,
      ),
      // V1.0 first-run copy is centered under the art.
      child: Column(
        children: [
          ExcludeSemantics(child: hero),
          const SizedBox(height: OurneySpacing.xl),
          if (eyebrow != null) ...[
            PersonaPill(
              icon: Icons.auto_awesome_rounded,
              emphasized: true,
              label: eyebrow!,
            ),
            const SizedBox(height: OurneySpacing.sm),
          ],
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: displayStyle(
                size: 28,
                weight: 700,
                color: pTheme.ink,
                height: 1.25,
                tracking: -0.04,
              ),
            ),
          ),
          const SizedBox(height: OurneySpacing.md),
          body,
          const SizedBox(height: OurneySpacing.lg),
        ],
      ),
    );
  }
}

/// Page 1 hero: clean architectural showcase of Ourney's 6 persona skins.
class _PersonaShowcaseDeck extends StatelessWidget {
  const _PersonaShowcaseDeck({required this.brightness, required this.pTheme});

  final Brightness brightness;
  final OurneyPersonaTheme pTheme;

  static const List<(PersonaSkinId, IconData, String)> _tiles = [
    (PersonaSkinId.quietTransformer, Icons.monitor_weight_rounded, 'DAY 21'),
    (PersonaSkinId.accountabilitySquad, Icons.menu_book_rounded, 'SQUAD'),
    (PersonaSkinId.memoryCollectors, Icons.flight_takeoff_rounded, '35MM'),
    (PersonaSkinId.coupleRituals, Icons.favorite_rounded, 'DUO'),
    (PersonaSkinId.aestheticFlexer, Icons.fitness_center_rounded, 'PACE'),
    (PersonaSkinId.minimalistHabit, Icons.auto_awesome_rounded, 'STREAK'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pTheme.surface,
        borderRadius: BorderRadius.circular(pTheme.cardRadius),
        border: Border.all(color: pTheme.border, width: pTheme.borderWidth),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < 2; r++) ...[
            if (r > 0) const SizedBox(height: 10),
            Row(
              children: [
                for (var c = 0; c < 3; c++) ...[
                  if (c > 0) const SizedBox(width: 10),
                  Expanded(child: _buildPersonaTile(_tiles[r * 3 + c])),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonaTile((PersonaSkinId, IconData, String) item) {
    final (skinId, icon, tag) = item;
    final skinTheme = OurneyPersonaTheme.forSkin(skinId, brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: skinTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: skinTheme.primaryAccent.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: skinTheme.primaryAccent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: skinTheme.primaryAccent),
          ),
          const SizedBox(height: 8),
          Text(
            tag,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              color: skinTheme.ink,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Page 2 hero: tactile 3-stage check-in progression card (`SNAP -> LOG -> STREAK`).
class _RitualFlowHero extends StatelessWidget {
  const _RitualFlowHero({required this.pTheme});

  final OurneyPersonaTheme pTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: pTheme.surface,
        borderRadius: BorderRadius.circular(pTheme.cardRadius),
        border: Border.all(color: pTheme.border, width: pTheme.borderWidth),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _FlowNode(
            icon: Icons.photo_camera_rounded,
            badge: '01',
            pTheme: pTheme,
            active: true,
          ),
          Icon(
            Icons.trending_flat_rounded,
            color: pTheme.primaryAccent,
            size: 22,
          ),
          _FlowNode(
            icon: Icons.tune_rounded,
            badge: '02',
            pTheme: pTheme,
            active: false,
          ),
          Icon(
            Icons.trending_flat_rounded,
            color: pTheme.primaryAccent,
            size: 22,
          ),
          _FlowNode(
            icon: streakIcon,
            badge: '03',
            pTheme: pTheme,
            active: true,
          ),
        ],
      ),
    );
  }
}

class _FlowNode extends StatelessWidget {
  const _FlowNode({
    required this.icon,
    required this.badge,
    required this.pTheme,
    required this.active,
  });

  final IconData icon;
  final String badge;
  final OurneyPersonaTheme pTheme;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: active
                ? pTheme.primaryAccent.withValues(alpha: 0.16)
                : pTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? pTheme.primaryAccent : pTheme.border,
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            size: 26,
            color: active ? pTheme.primaryAccent : pTheme.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          badge,
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            color: pTheme.inkMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Page 3 hero: dark camera viewfinder frame with tactile shutter ring preview.
class _ReadyViewfinderHero extends StatelessWidget {
  const _ReadyViewfinderHero({required this.pTheme});

  final OurneyPersonaTheme pTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: OurneyColors.cameraBg,
        borderRadius: BorderRadius.circular(pTheme.cardRadius),
        border: Border.all(color: pTheme.border, width: pTheme.borderWidth),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: OurneyColors.mediaWhite.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: pTheme.primaryAccent,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'DAY 01',
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        color: OurneyColors.mediaWhite,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.flash_auto_rounded,
                size: 18,
                color: OurneyColors.mediaWhite.withValues(alpha: 0.7),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: OurneyColors.mediaWhite, width: 3),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pTheme.primaryAccent,
              ),
              child: const Icon(
                Icons.photo_camera_rounded,
                color: OurneyColors.mediaWhite,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.icon,
    required this.text,
    required this.pTheme,
  });

  final int index;
  final IconData icon;
  final String text;
  final OurneyPersonaTheme pTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: OurneySpacing.md),
      child: Container(
        padding: const EdgeInsets.all(OurneySpacing.md),
        decoration: BoxDecoration(
          color: pTheme.surface,
          borderRadius: BorderRadius.circular(pTheme.cardRadius),
          border: Border.all(color: pTheme.border, width: pTheme.borderWidth),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Container(
                width: OurneySizes.minTap,
                height: OurneySizes.minTap,
                decoration: BoxDecoration(
                  color: pTheme.primaryAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(OurneyRadii.chip),
                ),
                child: Icon(icon, color: pTheme.primaryAccent),
              ),
            ),
            const SizedBox(width: OurneySpacing.md),
            Expanded(
              child: Text(
                '$index. $text',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: pTheme.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page indicator; the active page is longer (not color-only).
class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.current,
    required this.pTheme,
    required this.label,
  });

  final int count;
  final int current;
  final OurneyPersonaTheme pTheme;
  final String label;

  @override
  Widget build(BuildContext context) {
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
                      ? pTheme.primaryAccent
                      : pTheme.inkMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(OurneyRadii.capsule),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
