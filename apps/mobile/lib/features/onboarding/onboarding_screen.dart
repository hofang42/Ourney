import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart' show OnboardingQuiz;

import '../../app/providers.dart';
import '../../app/theme/motion.dart';
import '../../ui/ui.dart';
import 'onboarding_providers.dart';
import 'onboarding_quiz.dart';

/// First-run onboarding (V2 `OnboardingFlow`): the 3-question quiz, reached
/// from the splash. Every question has "Skip"; finishing or skipping calls
/// `onboardingCompleteProvider.notifier.complete()` and the router redirect
/// then moves on by itself.
///
/// No permission prompts here: camera and notification access are requested
/// in context by the camera and reminders features.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const pageCount = OnboardingQuizStage.questionCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = context.ui;
    final width = MediaQuery.sizeOf(context).width;
    // V2 side padding is 24dp; compact phones keep the 16dp gutter.
    final gutter = width < 360 ? UiSpace.gutter(width) : 24.0;

    Future<void> finish(OnboardingQuiz? quiz) async {
      OurneyHaptics.success();
      if (quiz != null) {
        // Local save is immediate; the server copy is best effort.
        unawaited(ref.read(onboardingQuizProvider.notifier).save(quiz));
      }
      await ref.read(onboardingCompleteProvider.notifier).complete();
    }

    return Scaffold(
      key: const ValueKey('onboarding-screen'),
      backgroundColor: ui.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: UiSpace.maxContent(width)),
            child: OnboardingQuizStage(onDone: finish, gutter: gutter),
          ),
        ),
      ),
    );
  }
}
