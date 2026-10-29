import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/locale_override.dart';
import '../../app/providers.dart';
import '../../app/theme/motion.dart';
import '../../ui/ui.dart';
import 'l10n/generated/onboarding_localizations.dart';
import 'onboarding_art.dart';

/// First-run onboarding (App.tsx `Onboarding`): three pages with an
/// illustration, headline, body, page dots and one "Continue" button.
/// Page 1 carries the language chip; every page has "Skip".
///
/// No permission prompts here: camera and notification access are requested
/// in context by the camera and reminders features. Finishing (or skipping)
/// calls `onboardingCompleteProvider.notifier.complete()`; the router
/// redirect then moves on by itself.
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
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _switchLanguage() {
    final current = Localizations.localeOf(context).languageCode;
    unawaited(
      ref
          .read(localeOverrideProvider.notifier)
          .set(Locale(current == 'vi' ? 'en' : 'vi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = OnboardingL10n.of(context);
    final ui = context.ui;
    final width = MediaQuery.sizeOf(context).width;
    final gutter = UiSpace.gutter(width);

    final titles = [
      l10n.onboarding_page1Title,
      l10n.onboarding_page2Title,
      l10n.onboarding_page3Title,
    ];
    final bodies = [
      l10n.onboarding_page1Body,
      l10n.onboarding_page2Body,
      l10n.onboarding_page3Body,
    ];
    final arts = <Widget>[
      const OnboardingArtMemories(),
      const OnboardingArtStyles(),
      OnboardingArtRecap(
        title: l10n.onboarding_recapTitle,
        subtitle: l10n.onboarding_recapSubtitle,
        shareLabel: l10n.onboarding_recapShare,
      ),
    ];

    return Scaffold(
      key: const ValueKey('onboarding-screen'),
      backgroundColor: ui.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: UiSpace.maxContent(width)),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_page == 0)
                        Flexible(
                          child: UiChip(
                            key: const ValueKey('onboarding-language'),
                            icon: Icons.translate_rounded,
                            label: l10n.onboarding_languageSwitch,
                            semanticHint: l10n.onboarding_languageSwitchHint,
                            onPressed: _switchLanguage,
                          ),
                        )
                      else
                        const SizedBox(height: UiSize.tap),
                      UiTextAction(
                        key: const ValueKey('onboarding-skip'),
                        label: l10n.onboarding_skip,
                        onPressed: _complete,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: OnboardingScreen.pageCount,
                    onPageChanged: (p) {
                      OurneyHaptics.selection();
                      setState(() => _page = p);
                    },
                    itemBuilder: (context, i) => _OnboardingPage(
                      key: ValueKey('onboarding-page-$i'),
                      art: arts[i],
                      title: titles[i],
                      body: bodies[i],
                      gutter: gutter,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 28),
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
                      const SizedBox(height: 10),
                      UiButton(
                        key: const ValueKey('onboarding-next'),
                        label: l10n.onboarding_next,
                        onPressed: _next,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.art,
    required this.title,
    required this.body,
    required this.gutter,
    super.key,
  });

  final Widget art;
  final String title;
  final String body;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return LayoutBuilder(
      builder: (context, box) {
        final artHeight = (box.maxHeight * 0.5).clamp(170.0, 420.0);
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: artHeight,
                  width: double.infinity,
                  child: ClipRect(
                    // Illustrations are pictures, not text: keep them fixed
                    // when the system text size grows.
                    child: MediaQuery.withNoTextScaling(
                      child: Center(child: art),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: gutter,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: UiText.h1(size: 28, color: ui.ink),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        body,
                        textAlign: TextAlign.center,
                        style: UiText.muted(color: ui.inkMuted, size: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// `.page-dots.onboarding-dots`: 5dp dots, the active one stretches to 16dp.
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
    final ui = context.ui;
    final duration = UiMotion.of(context, const Duration(milliseconds: 200));
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        height: 12,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: duration,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: i == current ? 16 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: i == current ? ui.ink : ui.ink.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
