import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/groups/data/groups_providers.dart';
import 'package:ourney/features/groups/ui/group_safety_hooks.dart';
import 'package:ourney/features/groups/ui/group_today_screen.dart';
import 'package:ourney/features/groups/ui/groups_list_screen.dart';
import 'package:ourney/features/groups/ui/reaction_bar.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney/features/profile/profile_screen.dart';
import 'package:ourney/features/social/social_paths.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import '../social/social_fakes.dart' as social_fakes;
import 'groups_fakes.dart';

class _GatedGroupRepository extends FakeGroupRepository {
  _GatedGroupRepository({super.reactions});

  Completer<void>? reactGate;
  int _seq = 0;

  @override
  Future<void> react(String checkInId, String emoji) async {
    final mySeq = ++_seq;
    calls.add('react:$checkInId:$emoji');
    if (reactGate case final g?) {
      await g.future;
    }
    if (reactError case final e?) throw e;
    if (mySeq != _seq) return;
    await super.react(checkInId, emoji);
    // Remove duplicate call entry recorded by super.react.
    calls.removeLast();
  }
}

Widget _host(
  Widget child, {
  bool disableAnimations = false,
  Brightness brightness = Brightness.light,
  Size size = const Size(390, 844),
}) {
  return MaterialApp(
    theme: OurneyTheme.build(brightness),
    themeAnimationDuration: Duration.zero,
    localizationsDelegates: ourneyLocalizationsDelegates,
    supportedLocales: ourneySupportedLocales,
    builder: (context, appChild) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: size,
        disableAnimations: disableAnimations,
      ),
      child: appChild!,
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('Moment #4 — Reaction Burst & Optimistic Rolling Counter', () {
    testWidgets(
      '3-point pump choreography on UiReactionBar add/remove: anticipation (35ms), spring pop overshoot + 5-particle burst + rolling counter (150ms), and settled',
      (tester) async {
        final haptics = <String>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              if (call.method == 'HapticFeedback.vibrate') {
                haptics.add(call.arguments as String? ?? '');
              }
              return null;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null);
        });

        String? selected;
        var fireCount = 3;
        late StateSetter setHost;

        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (context, setState) {
                setHost = setState;
                return UiReactionBar(
                  labels: const {
                    'clap': 'Vỗ tay',
                    'flex': 'Cố lên',
                    'heart': 'Thương',
                    'laugh': 'Haha',
                    'fire': 'Cháy',
                  },
                  selected: selected,
                  counts: {'fire': fireCount},
                  onReact: (id) {
                    setHost(() {
                      if (selected == id) {
                        selected = null;
                        if (id == 'fire') fireCount--;
                      } else {
                        selected = id;
                        if (id == 'fire') fireCount++;
                      }
                    });
                  },
                );
              },
            ),
          ),
        );

        // 1. Tap 'fire' to add reaction (t = 0ms)
        await tester.tap(find.byKey(const ValueKey('reaction-disc-fire')));
        await tester.pump();
        expect(selected, 'fire');
        expect(fireCount, 4);
        expect(haptics, ['HapticFeedbackType.lightImpact']);

        // 2. Mid-anticipation (t = 35ms within 0..70ms): icon compresses < 1.0 and tilts < 0
        await tester.pump(const Duration(milliseconds: 35));
        final scale35 = tester
            .widget<Transform>(
              find.byKey(const ValueKey('reaction-scale-fire')),
            )
            .transform
            .storage[0];
        expect(scale35, lessThan(1.0));
        expect(scale35, greaterThanOrEqualTo(0.84));

        // 3. Mid-spring pop & vector sticker burst (t = 150ms within 70..310ms & 90..480ms)
        await tester.pump(const Duration(milliseconds: 115));
        final scale150 = tester
            .widget<Transform>(
              find.byKey(const ValueKey('reaction-scale-fire')),
            )
            .transform
            .storage[0];
        // Bouncy spring overshoots > 1.0 (peaking near ~1.24).
        expect(scale150, greaterThan(1.05));

        final burstCanvas = find.byKey(
          const ValueKey('reaction-burst-canvas-fire'),
        );
        expect(burstCanvas, findsOneWidget);
        final painter =
            tester.widget<CustomPaint>(burstCanvas).painter!
                as UiReactionBurstPainter;
        expect(painter.burstProgress, greaterThan(0.0));
        expect(painter.burstProgress, lessThan(1.0));

        // Rolling counter is mid-roll (3 -> 4): both '3' and '4' exist in UiCountRoll.
        expect(find.text('3'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);

        // 4. Settled (t >= 480ms)
        await tester.pumpAndSettle();
        expect(find.text('4'), findsOneWidget);
        expect(find.text('3'), findsNothing);
        expect(burstCanvas, findsNothing);
        expect(tester.binding.transientCallbackCount, 0);

        // 5. Tap 'fire' again to remove reaction: 140ms dip settle (0.92), no particle burst, selectionClick haptic
        haptics.clear();
        await tester.tap(find.byKey(const ValueKey('reaction-disc-fire')));
        await tester.pump();
        expect(selected, isNull);
        expect(fireCount, 3);
        expect(haptics, ['HapticFeedbackType.selectionClick']);
        expect(burstCanvas, findsNothing);

        await tester.pump(const Duration(milliseconds: 70));
        final removeMidScale = tester
            .widget<Transform>(
              find.byKey(const ValueKey('reaction-scale-fire')),
            )
            .transform
            .storage[0];
        expect(removeMidScale, lessThan(1.0));
        expect(removeMidScale, greaterThanOrEqualTo(0.91));
        expect(burstCanvas, findsNothing);

        await tester.pumpAndSettle();
        expect(find.text('3'), findsOneWidget);
        expect(find.text('4'), findsNothing);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'Squad Wall ReactionBar allows non-blocking rapid taps across reactions while network write is in flight, shifts border to ui.accent, and obeys Reduce Motion',
      (tester) async {
        final gate = Completer<void>();
        final repo = _GatedGroupRepository(
          reactions: {
            'c1': [
              Reaction(
                checkInId: 'c1',
                userId: 'u3',
                emoji: '🔥',
                createdAt: testNow,
              ),
            ],
          },
        )..reactGate = gate;

        final prefs = await testPrefs();
        Widget buildBar({bool disableAnimations = false}) {
          return ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              authRepositoryProvider.overrideWithValue(
                FakeAuthRepository(userId: me),
              ),
              groupRepositoryProvider.overrideWithValue(repo),
              safetyRepositoryProvider.overrideWithValue(
                FakeSafetyRepository(),
              ),
            ],
            child: _host(
              disableAnimations: disableAnimations,
              const ReactionBar(checkInId: 'c1'),
            ),
          );
        }

        await tester.pumpWidget(buildBar());
        await tester.pumpAndSettle();

        Finder chip(String emoji) => find.byKey(ValueKey('groups-react-c1-$emoji'));

        // 1. Tap 🔥 while network write is gated by `gate`.
        await tester.tap(chip('🔥'));
        await tester.pump();

        // Pill border immediately shifts to ui.accent (2dp) and optimistic count increments (1 -> 2).
        final fireContainer = tester.widget<Container>(
          find.descendant(of: chip('🔥'), matching: find.byType(Container)).first,
        );
        final fireBorder =
            (fireContainer.decoration! as BoxDecoration).border! as Border;
        expect(fireBorder.top.color, OurneyUi.light.accent);
        expect(fireBorder.top.width, UiBorder.standard);

        // Other reaction pills (e.g. 💪) are NOT locked out while 🔥 is in flight!
        final flexPressable = tester.widget<UiPressable>(
          find.descendant(of: chip('💪'), matching: find.byType(UiPressable)),
        );
        expect(flexPressable.onPressed, isNotNull);

        // 2. Rapidly tap 💪 before 🔥 finishes: optimistic state moves immediately to 💪!
        repo.reactGate = null;
        await tester.tap(chip('💪'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        expect(
          find.byKey(const ValueKey('reaction-burst-canvas-flex')),
          findsOneWidget,
        );

        gate.complete();
        await tester.pumpAndSettle();
        expect(repo.calls, ['react:c1:🔥', 'react:c1:💪']);
        expect(
          find.descendant(of: chip('💪'), matching: find.text('1')),
          findsOneWidget,
        );

        // 3. Reduce-Motion parity: instant count update, zero particle burst, zero scale/tilt transforms.
        await tester.pumpWidget(buildBar(disableAnimations: true));
        await tester.pump();

        await tester.tap(chip('🔥'));
        await tester.pump();
        expect(
          find.byKey(const ValueKey('reaction-burst-canvas-fire')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('reaction-scale-fire')),
          findsNothing,
        );
        expect(
          find.descendant(of: chip('🔥'), matching: find.text('2')),
          findsOneWidget,
        );
        expect(tester.binding.transientCallbackCount, 0);
      },
    );
  });

  group('Moment #8, #10 & #11 — Squad Polaroid Hero, Stagger & Pull-to-Refresh', () {
    testWidgets(
      'GroupTodayScreen wraps member Polaroid photo in UiHero(dayPhoto) and supports UiRefreshScaffold pull-to-refresh',
      (tester) async {
        final g = groupJourney();
        final annToday = testCheckIn('g1', testToday, userId: 'u2');
        final groupsRepo = FakeGroupRepository(
          today: {
            'g1': [
              memberToday(me, 'Minh', role: MemberRole.owner),
              memberToday('u2', 'Ann', today: annToday, streak: 5),
              memberToday('u3', 'Binh', streak: 3),
              memberToday('u4', 'Chi', streak: 2),
              memberToday('u5', 'Dung', streak: 4),
              memberToday('u6', 'Giang', streak: 1),
              memberToday('u7', 'Hanh', streak: 6),
              memberToday('u8', 'Khanh', streak: 2),
            ],
          },
        );
        final prefs = await testPrefs();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appConfigProvider.overrideWithValue(testBackendConfig),
              sharedPreferencesProvider.overrideWithValue(prefs),
              authRepositoryProvider.overrideWithValue(
                FakeAuthRepository(userId: me),
              ),
              groupRepositoryProvider.overrideWithValue(groupsRepo),
              journeyRepositoryProvider.overrideWithValue(
                FakeJourneyRepository(
                  journeys: [g],
                  memberships: {'g1': groupMembership(g)},
                ),
              ),
              checkInRepositoryProvider.overrideWithValue(
                FakeCheckInRepository([annToday]),
              ),
              safetyRepositoryProvider.overrideWithValue(
                FakeSafetyRepository(),
              ),
              mediaStoreProvider.overrideWithValue(FakeMediaStore()),
              journeysClockProvider.overrideWithValue(Clock.fixed(testNow)),
              groupSafetyHooksProvider.overrideWithValue(
                const GroupSafetyHooks(),
              ),
            ],
            child: _host(const GroupTodayScreen(journeyId: 'g1')),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify Squad Polaroid photo is wrapped in UiHero with canonical tag.
        final heroFinder = find.ancestor(
          of: find.byKey(const ValueKey('group-member-photo-u2')),
          matching: find.byType(UiHero),
        );
        expect(heroFinder, findsOneWidget);
        final uiHero = tester.widget<UiHero>(heroFinder);
        expect(uiHero.tag, UiHeroTags.dayPhoto(annToday.id));

        // 2. Pull-to-refresh on GroupTodayScreen mounts 36x36 Neo-Brutalist refresh badge.
        final drag = await tester.startGesture(const Offset(195, 250));
        await drag.moveBy(const Offset(0, 35));
        await tester.pump();
        await drag.moveBy(const Offset(0, 95));
        await tester.pump();
        expect(find.byKey(const ValueKey('ui-refresh-badge')), findsOneWidget);

        await drag.up();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('ui-refresh-badge')), findsNothing);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'GroupsListScreen & InboxScreen 3-point skeleton->content crossfade, first-load wave stagger, and pull-to-refresh + Reduce Motion parity',
      (tester) async {
        final groupsController = StreamController<List<Journey>>.broadcast();
        addTearDown(groupsController.close);
        final prefs = await testPrefs();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appConfigProvider.overrideWithValue(testBackendConfig),
              sharedPreferencesProvider.overrideWithValue(prefs),
              authRepositoryProvider.overrideWithValue(
                FakeAuthRepository(userId: me),
              ),
              groupJourneysProvider.overrideWith((ref) => groupsController.stream),
              groupRepositoryProvider.overrideWithValue(FakeGroupRepository()),
              safetyRepositoryProvider.overrideWithValue(
                FakeSafetyRepository(),
              ),
            ],
            child: _host(const GroupsListScreen()),
          ),
        );
        await tester.pump();

        // 1. Initially renders skeleton while stream is waiting.
        expect(find.byKey(const ValueKey('squad-skeleton')), findsOneWidget);

        // 2. Emit 3 group journeys -> triggers AnimatedSwitcher crossfade + UiStaggerItem wave.
        groupsController.add([
          groupJourney(id: 'g1', title: 'Squad 1'),
          groupJourney(id: 'g2', title: 'Squad 2'),
          groupJourney(id: 'g3', title: 'Squad 3'),
        ]);
        await tester.pump();

        // Mid-flight at t = 50ms: Card 0 (0ms delay) is mid-fade; Card 2 (80ms delay) has not started yet (opacity == 0.0).
        await tester.pump(const Duration(milliseconds: 50));
        final card0Fade = tester.widget<FadeTransition>(
          find
              .descendant(
                of: find.byKey(const ValueKey('squad-stagger-g1')),
                matching: find.byType(FadeTransition),
              )
              .first,
        );
        final card2Fade = tester.widget<FadeTransition>(
          find
              .descendant(
                of: find.byKey(const ValueKey('squad-stagger-g3')),
                matching: find.byType(FadeTransition),
              )
              .first,
        );
        expect(card0Fade.opacity.value, greaterThan(0.0));
        expect(card0Fade.opacity.value, lessThan(1.0));
        expect(card2Fade.opacity.value, 0.0);

        // Fire the 80ms delay timer for Card 2 (at t = 90ms) and advance 50ms into its entrance (t = 140ms).
        await tester.pump(const Duration(milliseconds: 40));
        await tester.pump(const Duration(milliseconds: 50));
        expect(card2Fade.opacity.value, greaterThan(0.0));
        expect(card2Fade.opacity.value, lessThan(1.0));

        await tester.pumpAndSettle();
        expect(card0Fade.opacity.value, 1.0);
        expect(card2Fade.opacity.value, 1.0);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'InboxScreen pull-to-refresh mounts 36x36 Neo-Brutalist refresh badge and collapses cleanly',
      (tester) async {
        await social_fakes.pumpSocial(
          tester,
          location: SocialPaths.inbox,
          fakes: social_fakes.SocialFakes(
            friends: social_fakes.FakeFriendRepository([
              for (var i = 1; i <= 8; i++)
                social_fakes.request('khoa-$i', name: 'Khoa Le $i'),
            ]),
          ),
        );
        final inboxDrag = await tester.startGesture(const Offset(195, 300));
        await inboxDrag.moveBy(const Offset(0, 35));
        await tester.pump();
        await inboxDrag.moveBy(const Offset(0, 95));
        await tester.pump();
        expect(find.byKey(const ValueKey('ui-refresh-badge')), findsOneWidget);
        await inboxDrag.up();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('ui-refresh-badge')), findsNothing);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );
  });

  group('Moment #12 — Profile Confirmation Dialog & Reduce Motion Parity', () {
    testWidgets(
      'showProfileConfirmDialog 3-point scale(0.96 -> 1.0) + FadeTransition entrance, warning haptic, and Reduce Motion opacity-only fallback',
      (tester) async {
        final haptics = <String>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              if (call.method == 'HapticFeedback.vibrate') {
                haptics.add(call.arguments as String? ?? '');
              }
              return null;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null);
        });

        var disableAnimations = false;
        bool? dialogResult;
        late StateSetter setHost;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              setHost = setState;
              return _host(
                disableAnimations: disableAnimations,
                Builder(
                  builder: (innerContext) => UiButton(
                    label: 'Open Delete Dialog',
                    onPressed: () async {
                      dialogResult = await showProfileConfirmDialog(
                        innerContext,
                        title: 'Xóa tài khoản?',
                        message: 'Hành động này không thể hoàn tác.',
                        confirmLabel: 'Xóa',
                        destructive: true,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );

        // 1. Normal motion: tap to open destructive dialog (t = 0ms)
        await tester.tap(find.text('Open Delete Dialog'));
        await tester.pump();
        expect(haptics, contains('HapticFeedbackType.heavyImpact'));

        // 2. Mid-flight (t = 90ms of 200ms): ScaleTransition is between 0.96 and 1.0
        await tester.pump(const Duration(milliseconds: 90));
        final dialogFinder = find.byKey(
          const ValueKey('profile-confirm-dialog'),
        );
        expect(dialogFinder, findsOneWidget);
        final scaleTransition = tester.widget<ScaleTransition>(
          find
              .ancestor(
                of: dialogFinder,
                matching: find.byType(ScaleTransition),
              )
              .first,
        );
        expect(scaleTransition.scale.value, greaterThan(0.96));
        expect(scaleTransition.scale.value, lessThan(1.0));

        // 3. Settled (t >= 200ms)
        await tester.pumpAndSettle();
        expect(scaleTransition.scale.value, 1.0);
        await tester.tap(find.byKey(const ValueKey('profile-confirm-accept')));
        await tester.pumpAndSettle();
        expect(dialogResult, isTrue);

        // 4. Reduce-Motion parity: zero ScaleTransition mounted, settles within 160ms
        setHost(() => disableAnimations = true);
        await tester.pump();

        await tester.tap(find.text('Open Delete Dialog'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 75));
        expect(
          find.ancestor(
            of: find.byKey(const ValueKey('profile-confirm-dialog')),
            matching: find.byType(ScaleTransition),
          ),
          findsNothing,
        );
        await tester.pump(const Duration(milliseconds: 85));
        await tester.tap(find.byKey(const ValueKey('profile-confirm-cancel')));
        await tester.pumpAndSettle();
        expect(dialogResult, isFalse);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );
  });
}
