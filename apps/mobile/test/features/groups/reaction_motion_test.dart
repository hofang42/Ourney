import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/navigator_keys.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/groups/data/groups_providers.dart';
import 'package:ourney/features/groups/routes.dart';
import 'package:ourney/features/groups/ui/group_safety_hooks.dart';
import 'package:ourney/features/groups/ui/groups_list_screen.dart';
import 'package:ourney/features/groups/ui/reaction_bar.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney/features/journeys/journeys_paths.dart';
import 'package:ourney/features/profile/profile_providers.dart';
import 'package:ourney/features/profile/profile_screen.dart';
import 'package:ourney/features/social/data/social_providers.dart';
import 'package:ourney/features/social/routes.dart';
import 'package:ourney/features/social/ui/chat_screen.dart';
import 'package:ourney/features/social/ui/inbox_screen.dart';
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
    calls.removeLast();
  }
}

class _GatedChatRepository extends social_fakes.FakeChatRepository {
  _GatedChatRepository({super.conversations});

  Completer<void>? sendGate;

  @override
  Future<ChatMessage> sendText(
    String conversationId,
    String body, {
    String? replyToCheckInId,
    String? draftId,
  }) async {
    if (sendGate case final g?) {
      await g.future;
    }
    return super.sendText(
      conversationId,
      body,
      replyToCheckInId: replyToCheckInId,
      draftId: draftId,
    );
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

Widget _routerHost(
  Widget child, {
  bool disableAnimations = false,
  Brightness brightness = Brightness.light,
  Size size = const Size(390, 844),
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(body: Center(child: child)),
      ),
    ],
  );
  return MaterialApp.router(
    theme: OurneyTheme.build(brightness),
    themeAnimationDuration: Duration.zero,
    localizationsDelegates: ourneyLocalizationsDelegates,
    supportedLocales: ourneySupportedLocales,
    routerConfig: router,
    builder: (context, appChild) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: size,
        disableAnimations: disableAnimations,
      ),
      child: appChild!,
    ),
  );
}

List<String> _recordHaptics(WidgetTester tester) {
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
  return haptics;
}

void main() {
  group('Moment #4 — Reaction Burst & Optimistic Rolling Counter', () {
    testWidgets(
      '3-point pump choreography on UiReactionBar add/switch/remove, single haptic on switch, ui.outline border, ExcludeSemantics burst, and quiet skin calm spring',
      (tester) async {
        final haptics = _recordHaptics(tester);

        String? selected;
        var fireCount = 3;
        var flexCount = 1;
        var skinId = 'squad';
        late StateSetter setHost;

        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (context, setState) {
                setHost = setState;
                return UiSkinScope(
                  skinId: skinId,
                  child: UiReactionBar(
                    labels: const {
                      'clap': 'Vỗ tay',
                      'flex': 'Cố lên',
                      'heart': 'Thương',
                      'laugh': 'Haha',
                      'fire': 'Cháy',
                    },
                    selected: selected,
                    counts: {'fire': fireCount, 'flex': flexCount},
                    onReact: (id) {
                      setHost(() {
                        if (selected == id) {
                          selected = null;
                          if (id == 'fire') fireCount--;
                          if (id == 'flex') flexCount--;
                        } else {
                          if (selected == 'fire') fireCount--;
                          if (selected == 'flex') flexCount--;
                          selected = id;
                          if (id == 'fire') fireCount++;
                          if (id == 'flex') flexCount++;
                        }
                      });
                    },
                  ),
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

        // Selected disc border uses ui.outline (1.5dp) so it remains visible when ui.brand == ui.accent.
        final fireDiscFinder = find.byKey(const ValueKey('reaction-disc-fire'));
        final fireDisc = tester.widget<Container>(fireDiscFinder);
        final discBorder =
            (fireDisc.decoration! as BoxDecoration).border! as Border;
        final scopedUi = tester.element(fireDiscFinder).ui;
        expect(discBorder.top.color, scopedUi.outline);
        expect(discBorder.top.width, UiBorder.thin);

        // 2. Mid-anticipation (t = 35ms within 0..70ms): icon compresses < 1.0
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
        expect(scale150, greaterThan(1.05));

        final burstCanvas = find.byKey(
          const ValueKey('reaction-burst-canvas-fire'),
        );
        expect(burstCanvas, findsOneWidget);
        expect(
          find.ancestor(
            of: burstCanvas,
            matching: find.byType(ExcludeSemantics),
          ),
          findsWidgets,
        );
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

        // 5. Switch directly from 'fire' (A) to 'flex' (B): emits strictly ONE lightImpact haptic (no phantom selectionClick from 'fire').
        haptics.clear();
        await tester.tap(find.byKey(const ValueKey('reaction-disc-flex')));
        await tester.pump();
        expect(selected, 'flex');
        expect(haptics, ['HapticFeedbackType.lightImpact']);
        expect(
          find.byKey(const ValueKey('reaction-scale-fire')),
          findsNothing,
        );
        await tester.pumpAndSettle();

        // 6. Tap 'flex' again to remove reaction: 140ms dip settle (0.92), no particle burst, 1 selectionClick haptic.
        haptics.clear();
        await tester.tap(find.byKey(const ValueKey('reaction-disc-flex')));
        await tester.pump();
        expect(selected, isNull);
        expect(haptics, ['HapticFeedbackType.selectionClick']);
        expect(
          find.byKey(const ValueKey('reaction-burst-canvas-flex')),
          findsNothing,
        );

        await tester.pump(const Duration(milliseconds: 70));
        final removeMidScale = tester
            .widget<Transform>(
              find.byKey(const ValueKey('reaction-scale-flex')),
            )
            .transform
            .storage[0];
        expect(removeMidScale, lessThan(1.0));
        expect(removeMidScale, greaterThanOrEqualTo(0.91));
        await tester.pumpAndSettle();

        // 7. Quiet skin temperament: critically damped settle (scale <= 1.0, zero overshoot) and no particle burst.
        setHost(() => skinId = 'quiet');
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('reaction-disc-fire')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        expect(
          find.byKey(const ValueKey('reaction-burst-canvas-fire')),
          findsNothing,
        );
        final quietScale150 = tester
            .widget<Transform>(
              find.byKey(const ValueKey('reaction-scale-fire')),
            )
            .transform
            .storage[0];
        expect(quietScale150, lessThanOrEqualTo(1.001));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Squad Wall ReactionBar emits 0 phantom haptics/bursts on stream hydration or error rollback, 1 haptic on reaction switch, and obeys Android + iOS Reduce Motion',
      (tester) async {
        final haptics = _recordHaptics(tester);
        final gate = Completer<void>();
        final repo = _GatedGroupRepository(
          reactions: {
            'c1': [
              Reaction(
                checkInId: 'c1',
                userId: me,
                emoji: '🔥',
                createdAt: testNow,
              ),
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
        Future<void> pumpBar({bool disableAnimations = false}) {
          return tester.pumpWidget(
            ProviderScope(
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
            ),
          );
        }

        // 1. Initial mount + stream hydration when caller already reacted with 🔥 (count = 2):
        // must emit ZERO haptics, ZERO particle bursts, and ZERO 0 -> 2 digit roll.
        await pumpBar();
        await tester.pump();
        expect(haptics, isEmpty);
        expect(
          find.byKey(const ValueKey('reaction-burst-canvas-fire')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('reaction-scale-fire')),
          findsNothing,
        );
        Finder chip(String emoji) =>
            find.byKey(ValueKey('groups-react-c1-$emoji'));
        expect(
          find.descendant(of: chip('🔥'), matching: find.text('2')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: chip('🔥'), matching: find.text('0')),
          findsNothing,
        );

        // 2. Switch from 🔥 to 💪 while network write is gated: emits strictly 1 lightImpact haptic.
        await tester.tap(chip('💪'));
        await tester.pump();
        expect(haptics, ['HapticFeedbackType.lightImpact']);

        final flexContainer = tester.widget<Container>(
          find
              .descendant(of: chip('💪'), matching: find.byType(Container))
              .first,
        );
        final flexBorder =
            (flexContainer.decoration! as BoxDecoration).border! as Border;
        expect(flexBorder.top.color, OurneyUi.light.accent);
        expect(flexBorder.top.width, UiBorder.standard);

        // Other reaction pills (e.g. 👏) are NOT locked out while 💪 is in flight.
        final clapPressable = tester.widget<UiPressable>(
          find.descendant(of: chip('👏'), matching: find.byType(UiPressable)),
        );
        expect(clapPressable.onPressed, isNotNull);

        // 3. Rapidly tap 👏 before 💪 finishes: optimistic state moves immediately to 👏 with 1 haptic.
        haptics.clear();
        repo.reactGate = null;
        await tester.tap(chip('👏'));
        await tester.pump();
        expect(haptics, ['HapticFeedbackType.lightImpact']);
        await tester.pump(const Duration(milliseconds: 120));
        expect(
          find.byKey(const ValueKey('reaction-burst-canvas-clap')),
          findsOneWidget,
        );

        gate.complete();
        await tester.pumpAndSettle();
        expect(repo.calls, ['react:c1:💪', 'react:c1:👏']);

        // 4. Error rollback emits ZERO spurious haptics and ZERO particle bursts.
        haptics.clear();
        final errGate = Completer<void>();
        repo
          ..reactGate = errGate
          ..reactError = Exception('network error');
        await tester.tap(chip('❤️'));
        await tester.pump();
        expect(haptics, ['HapticFeedbackType.lightImpact']);
        await tester.pumpAndSettle();
        haptics.clear();

        errGate.complete();
        await tester.pumpAndSettle();
        expect(haptics, isEmpty);
        expect(
          find.byKey(const ValueKey('reaction-burst-canvas-clap')),
          findsNothing,
        );
        repo
          ..reactGate = null
          ..reactError = null;

        // 5. Android Reduce-Motion parity (MediaQueryData.disableAnimations: true).
        await pumpBar(disableAnimations: true);
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

        // 6. iOS Reduce-Motion parity (FakeAccessibilityFeatures(reduceMotion: true)).
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(reduceMotion: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await pumpBar();
        await tester.pump();
        await tester.tap(chip('💪'));
        await tester.pump();
        expect(
          find.byKey(const ValueKey('reaction-burst-canvas-flex')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('reaction-scale-flex')),
          findsNothing,
        );
        expect(tester.binding.transientCallbackCount, 0);
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      },
    );
  });

  group('Moment #8, #10 & #11 — Squad Polaroid Hero, Stagger & Pull-to-Refresh', () {
    testWidgets(
      'GroupTodayScreen gates Polaroid UiHero + labeled UiPressable tap strictly on entry.isMe, leaves squadmates non-tappable, and supports pull-to-refresh',
      (tester) async {
        final g = groupJourney();
        final myToday = testCheckIn('g1', testToday, userId: me);
        final annToday = testCheckIn(
          'g1',
          testToday,
          userId: 'u2',
          hour: 3,
        );
        final groupsRepo = FakeGroupRepository(
          today: {
            'g1': [
              memberToday(me, 'Minh', today: myToday, role: MemberRole.owner),
              memberToday('u2', 'Ann', today: annToday, streak: 5),
              memberToday('u3', 'Binh', streak: 3),
              memberToday('u4', 'Chi', streak: 2),
              memberToday('u5', 'Dung', streak: 4),
              memberToday('u6', 'Giang', streak: 1),
            ],
          },
        );
        final prefs = await testPrefs();
        String? pushedDayRoute;

        final router = GoRouter(
          navigatorKey: rootNavigatorKey,
          initialLocation: '/groups/g1',
          routes: [
            ...groupsRoutes,
            GoRoute(
              path: '/journey/:id/day/:date',
              builder: (context, state) {
                pushedDayRoute = state.uri.toString();
                return Scaffold(
                  body: Center(
                    child: UiButton(
                      label: 'Close Day',
                      onPressed: () => context.pop(),
                    ),
                  ),
                );
              },
            ),
          ],
        );
        addTearDown(router.dispose);

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
                FakeCheckInRepository([myToday, annToday]),
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
            child: MaterialApp.router(
              theme: OurneyTheme.build(Brightness.light),
              localizationsDelegates: ourneyLocalizationsDelegates,
              supportedLocales: ourneySupportedLocales,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Caller's own Polaroid (entry.isMe) wraps photo in UiHero and labeled UiPressable.
        final myHeroFinder = find.ancestor(
          of: find.byKey(const ValueKey('group-member-photo-$me')),
          matching: find.byType(UiHero),
        );
        expect(myHeroFinder, findsOneWidget);
        expect(
          tester.widget<UiHero>(myHeroFinder).tag,
          UiHeroTags.dayPhoto(myToday.id),
        );
        final myTapFinder = find.byKey(
          const ValueKey('group-member-photo-tap-$me'),
        );
        expect(myTapFinder, findsOneWidget);
        final myPressable = tester.widget<UiPressable>(myTapFinder);
        expect(myPressable.semanticLabel, isNotNull);
        expect(myPressable.semanticLabel, contains('Minh'));

        // 2. Squadmate's Polaroid (!entry.isMe) has NO tap handler and NO DayViewer Hero tag.
        expect(
          find.byKey(const ValueKey('group-member-photo-tap-u2')),
          findsNothing,
        );
        expect(
          find.ancestor(
            of: find.byKey(const ValueKey('group-member-photo-u2')),
            matching: find.byType(UiHero),
          ),
          findsNothing,
        );
        await tester.tap(find.byKey(const ValueKey('group-member-photo-u2')));
        await tester.pumpAndSettle();
        expect(pushedDayRoute, isNull);

        // 3. Tapping caller's Polaroid navigates via JourneysPaths.day('g1', testToday).
        await tester.tap(myTapFinder);
        await tester.pumpAndSettle();
        expect(pushedDayRoute, JourneysPaths.day('g1', testToday));
        await tester.tap(find.text('Close Day'));
        await tester.pumpAndSettle();

        // 4. Pull-to-refresh on GroupTodayScreen mounts 36x36 Neo-Brutalist refresh badge.
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
      'GroupsListScreen 3-point skeleton->content crossfade, first-load wave stagger (latched against replay), pull-to-refresh, and Android + iOS Reduce Motion parity',
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
              groupJourneysProvider.overrideWith(
                (ref) => groupsController.stream,
              ),
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
        final initialGroups = [
          groupJourney(id: 'g1', title: 'Squad 1'),
          groupJourney(id: 'g2', title: 'Squad 2'),
          groupJourney(id: 'g3', title: 'Squad 3'),
        ];
        groupsController.add(initialGroups);
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

        // 3. Subsequent stream emission adding g4..g8 does NOT replay stagger on g4 (_hasPlayedInitialEntrance is latched).
        final manyGroups = [
          ...initialGroups,
          for (var i = 4; i <= 8; i++)
            groupJourney(id: 'g$i', title: 'Squad $i'),
        ];
        groupsController.add(manyGroups);
        await tester.pump();
        await tester.pump();
        final g4Stagger = tester.widget<UiStaggerItem>(
          find.byKey(const ValueKey('squad-stagger-g4')),
        );
        expect(g4Stagger.enabled, isFalse);

        // 4. Pull-to-refresh on GroupsListScreen mounts 36x36 Neo-Brutalist refresh badge.
        final drag = await tester.startGesture(const Offset(195, 250));
        await drag.moveBy(const Offset(0, 35));
        await tester.pump();
        await drag.moveBy(const Offset(0, 95));
        await tester.pump();
        expect(find.byKey(const ValueKey('ui-refresh-badge')), findsOneWidget);
        await drag.up();
        await tester.pump();
        // Re-emit data for the invalidated stream provider.
        groupsController.add(manyGroups);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('ui-refresh-badge')), findsNothing);

        // 5. Android + iOS Reduce-Motion parity: zero stagger FadeTransitions mounted.
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              appConfigProvider.overrideWithValue(testBackendConfig),
              sharedPreferencesProvider.overrideWithValue(prefs),
              authRepositoryProvider.overrideWithValue(
                FakeAuthRepository(userId: me),
              ),
              groupJourneysProvider.overrideWith(
                (ref) => Stream.value(initialGroups),
              ),
              groupRepositoryProvider.overrideWithValue(FakeGroupRepository()),
              safetyRepositoryProvider.overrideWithValue(
                FakeSafetyRepository(),
              ),
            ],
            child: _host(
              disableAnimations: true,
              const GroupsListScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('squad-stagger-g1')),
            matching: find.byType(FadeTransition),
          ),
          findsNothing,
        );

        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(reduceMotion: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              appConfigProvider.overrideWithValue(testBackendConfig),
              sharedPreferencesProvider.overrideWithValue(prefs),
              authRepositoryProvider.overrideWithValue(
                FakeAuthRepository(userId: me),
              ),
              groupJourneysProvider.overrideWith(
                (ref) => Stream.value(initialGroups),
              ),
              groupRepositoryProvider.overrideWithValue(FakeGroupRepository()),
              safetyRepositoryProvider.overrideWithValue(
                FakeSafetyRepository(),
              ),
            ],
            child: _host(const GroupsListScreen()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 160));
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('squad-stagger-g1')),
            matching: find.byType(FadeTransition),
          ),
          findsNothing,
        );
        expect(tester.binding.transientCallbackCount, 0);
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      },
    );

    testWidgets(
      'InboxScreen 3-point skeleton->content crossfade, first-load wave stagger, non-replay after triage, public-group accordion AnimatedRotation, pull-to-refresh, and Android + iOS Reduce Motion',
      (tester) async {
        final haptics = _recordHaptics(tester);
        final friendsStream = StreamController<List<Friendship>>.broadcast();
        final convStream = StreamController<List<Conversation>>.broadcast();
        addTearDown(friendsStream.close);
        addTearDown(convStream.close);

        final prefs = await testPrefs();
        final fakes = social_fakes.SocialFakes(
          friends: social_fakes.FakeFriendRepository([
            for (var i = 1; i <= 3; i++)
              social_fakes.request('khoa-$i', name: 'Khoa Le $i'),
            social_fakes.request(
              'pub-1',
              name: 'Linh Public',
              source: FriendSource.publicJourney,
              journeyId: 'j-pub',
              journeyTitle: '30 Days Running',
            ),
          ]),
        );

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              appConfigProvider.overrideWithValue(testBackendConfig),
              sharedPreferencesProvider.overrideWithValue(prefs),
              supabaseClientProvider.overrideWithValue(null),
              authRepositoryProvider.overrideWithValue(
                FakeAuthRepository(userId: me),
              ),
              ...fakes.overrides,
              friendshipsProvider.overrideWith((ref) => friendsStream.stream),
              conversationsProvider.overrideWith((ref) => convStream.stream),
            ],
            child: _routerHost(const InboxScreen()),
          ),
        );
        await tester.pump();

        // 1. Skeleton mounted while streams are loading.
        expect(
          find.byKey(const ValueKey('inbox-state-skeleton')),
          findsOneWidget,
        );

        // 2. Emit friendships & conversations -> 3-point wave stagger survives _autoRead post-frame setState.
        friendsStream.add(fakes.friends.friendships);
        convStream.add(const []);
        await tester.pump();

        await tester.pump(const Duration(milliseconds: 50));
        final row0Fade = tester.widget<FadeTransition>(
          find
              .descendant(
                of: find.byKey(const ValueKey('inbox-stagger-f:khoa-1')),
                matching: find.byType(FadeTransition),
              )
              .first,
        );
        final row2Fade = tester.widget<FadeTransition>(
          find
              .descendant(
                of: find.byKey(const ValueKey('inbox-stagger-f:khoa-3')),
                matching: find.byType(FadeTransition),
              )
              .first,
        );
        expect(row0Fade.opacity.value, greaterThan(0.0));
        expect(row0Fade.opacity.value, lessThan(1.0));
        expect(row2Fade.opacity.value, 0.0);

        await tester.pump(const Duration(milliseconds: 40));
        await tester.pump(const Duration(milliseconds: 50));
        expect(row2Fade.opacity.value, greaterThan(0.0));
        expect(row2Fade.opacity.value, lessThan(1.0));

        await tester.pumpAndSettle();
        expect(row0Fade.opacity.value, 1.0);
        expect(row2Fade.opacity.value, 1.0);

        // 3. Inline triage (decline khoa-1) + new stream item khoa-4 at index 2 mounts with enabled: false (no stagger replay).
        await tester.tap(find.byKey(const ValueKey('inbox-decline-khoa-1')));
        await tester.pump();
        final updatedFriendships = [
          ...fakes.friends.friendships,
          for (var i = 4; i <= 7; i++)
            social_fakes.request('khoa-$i', name: 'Khoa Le $i'),
        ];
        friendsStream.add(updatedFriendships);
        await tester.pump();
        await tester.pump();
        final khoa4Stagger = tester.widget<UiStaggerItem>(
          find.byKey(const ValueKey('inbox-stagger-f:khoa-4')),
        );
        expect(khoa4Stagger.enabled, isFalse);
        await tester.pumpAndSettle();

        // 4. Public-journey accordion rotates chevron 0.0 -> 0.5 turns with selection haptic and AnimatedSize.
        haptics.clear();
        final publicCard = find.byKey(const ValueKey('inbox-public-j-pub'));
        final feedScrollable = find.byType(Scrollable).last;
        await tester.scrollUntilVisible(
          publicCard,
          120,
          scrollable: feedScrollable,
        );
        await tester.pumpAndSettle();
        final rotBefore = tester.widget<AnimatedRotation>(
          find.descendant(
            of: publicCard,
            matching: find.byType(AnimatedRotation),
          ),
        );
        expect(rotBefore.turns, 0.0);

        await tester.tap(publicCard);
        await tester.pump();
        expect(haptics, contains('HapticFeedbackType.selectionClick'));
        final rotAfter = tester.widget<AnimatedRotation>(
          find.descendant(
            of: publicCard,
            matching: find.byType(AnimatedRotation),
          ),
        );
        expect(rotAfter.turns, 0.5);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('inbox-public-request-pub-1')),
          findsOneWidget,
        );

        // Scroll back to top of feed before testing pull-to-refresh.
        await tester.drag(feedScrollable, const Offset(0, 800));
        await tester.pumpAndSettle();

        // 5. Pull-to-refresh mounts 36x36 Neo-Brutalist refresh badge.
        final inboxDrag = await tester.startGesture(const Offset(195, 220));
        await inboxDrag.moveBy(const Offset(0, 35));
        await tester.pump();
        await inboxDrag.moveBy(const Offset(0, 95));
        await tester.pump();
        expect(find.byKey(const ValueKey('ui-refresh-badge')), findsOneWidget);
        await inboxDrag.up();
        await tester.pump();
        friendsStream.add(updatedFriendships);
        convStream.add(const []);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('ui-refresh-badge')), findsNothing);

        // 6. Android & iOS Reduce-Motion parity on InboxScreen.
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(reduceMotion: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              appConfigProvider.overrideWithValue(testBackendConfig),
              sharedPreferencesProvider.overrideWithValue(prefs),
              supabaseClientProvider.overrideWithValue(null),
              authRepositoryProvider.overrideWithValue(
                FakeAuthRepository(userId: me),
              ),
              ...fakes.overrides,
            ],
            child: _routerHost(
              disableAnimations: true,
              const InboxScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 160));
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('inbox-stagger-f:khoa-2')),
            matching: find.byType(FadeTransition),
          ),
          findsNothing,
        );
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      },
    );

    testWidgets(
      'ChatScreen loading->thread crossfade, send/spinner morph, reply-banner AnimatedSize, and socialRoutes buildUiPage transition + Reduce Motion parity',
      (tester) async {
        final sendGate = Completer<void>();
        final msgController = StreamController<List<ChatMessage>>.broadcast();
        addTearDown(msgController.close);

        final chatRepo = _GatedChatRepository(
          conversations: [social_fakes.conversation('c1')],
        )..sendGate = sendGate;
        final fakes = social_fakes.SocialFakes(chat: chatRepo);
        final prefs = await testPrefs();

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              appConfigProvider.overrideWithValue(testBackendConfig),
              sharedPreferencesProvider.overrideWithValue(prefs),
              supabaseClientProvider.overrideWithValue(null),
              authRepositoryProvider.overrideWithValue(
                FakeAuthRepository(userId: me),
              ),
              ...fakes.overrides,
              chatMessagesProvider('c1').overrideWith(
                (ref) => msgController.stream,
              ),
            ],
            child: _routerHost(
              const ChatScreen(
                conversationId: 'c1',
                replyToCheckInId: 'chk-1',
              ),
            ),
          ),
        );
        await tester.pump();

        // 1. Starts in loading state.
        expect(
          find.byKey(const ValueKey('chat-state-loading')),
          findsOneWidget,
        );

        // 2. Emit message -> AnimatedSwitcher crossfades loading -> thread.
        msgController.add([
          ChatMessage(
            id: 'm1',
            conversationId: 'c1',
            senderId: 'nam',
            kind: MessageKind.text,
            body: 'Chào bạn!',
            createdAt: testNow,
          ),
        ]);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(find.byKey(const ValueKey('chat-state-thread')), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 250));

        // 3. Reply banner collapses via AnimatedSize when cancelled.
        expect(find.byKey(const ValueKey('chat-reply-pending')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('chat-reply-cancel')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byKey(const ValueKey('chat-reply-pending')), findsNothing);

        // 4. Send button morphs to spinner while sendText is in flight, then back.
        await tester.enterText(
          find.byKey(const ValueKey('chat-input')),
          'Cố lên nhé!',
        );
        await tester.tap(find.byKey(const ValueKey('chat-send')));
        await tester.pump();
        expect(
          find.byKey(const ValueKey('chat-sending-spinner')),
          findsOneWidget,
        );

        sendGate.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byKey(const ValueKey('chat-send')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('chat-sending-spinner')),
          findsNothing,
        );

        // 5. socialRoutes buildUiPage transition mid-flight & iOS Reduce-Motion 160ms settle.
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(reduceMotion: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final router = GoRouter(
          navigatorKey: rootNavigatorKey,
          initialLocation: '/inbox',
          routes: [
            ...socialRoutes,
            ...activityRoutes,
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              appConfigProvider.overrideWithValue(testBackendConfig),
              sharedPreferencesProvider.overrideWithValue(prefs),
              supabaseClientProvider.overrideWithValue(null),
              authRepositoryProvider.overrideWithValue(
                FakeAuthRepository(userId: me),
              ),
              ...fakes.overrides,
            ],
            child: MaterialApp.router(
              theme: OurneyTheme.build(Brightness.light),
              localizationsDelegates: ourneyLocalizationsDelegates,
              supportedLocales: ourneySupportedLocales,
              routerConfig: router,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        unawaited(router.push('/friends'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 160));
        expect(tester.binding.transientCallbackCount, 0);
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      },
    );
  });

  group('Moment #10 & #12 — Profile Async Stagger & Confirmation Dialog', () {
    testWidgets(
      'ProfileScreen plays 3-section wave stagger on async cold load (AsyncLoading -> AsyncData) and obeys Android + iOS Reduce Motion',
      (tester) async {
        final profileController = StreamController<Profile?>.broadcast();
        addTearDown(profileController.close);
        final prefs = await testPrefs();
        final fakes = social_fakes.SocialFakes();

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              appConfigProvider.overrideWithValue(testBackendConfig),
              sharedPreferencesProvider.overrideWithValue(prefs),
              supabaseClientProvider.overrideWithValue(null),
              authRepositoryProvider.overrideWithValue(
                FakeAuthRepository(userId: me),
              ),
              ...fakes.overrides,
              myProfileProvider.overrideWith((ref) => profileController.stream),
              profileStatsProvider.overrideWith(
                (ref) async => const ProfileStats(
                  totalSnaps: 21,
                  longestStreak: 7,
                  currentStreak: 5,
                  journeysCompleted: 1,
                  journeysTotal: 2,
                ),
              ),
            ],
            child: _routerHost(const ProfileScreen()),
          ),
        );
        await tester.pump();

        // 1. Even while myProfileProvider is in AsyncLoading, the 3 sections start their stagger wave.
        await tester.pump(const Duration(milliseconds: 30));
        final headerFade = tester.widget<FadeTransition>(
          find
              .descendant(
                of: find.byKey(const ValueKey('profile-stagger-header')),
                matching: find.byType(FadeTransition),
              )
              .first,
        );
        final statsFade = tester.widget<FadeTransition>(
          find
              .descendant(
                of: find.byKey(const ValueKey('profile-stagger-stats')),
                matching: find.byType(FadeTransition),
              )
              .first,
        );
        expect(headerFade.opacity.value, greaterThan(0.0));
        expect(headerFade.opacity.value, lessThan(1.0));
        // Stats section (index 2 -> 80ms delay) has not started at t = 30ms.
        expect(statsFade.opacity.value, 0.0);

        // 2. Emit async profile data at t = 30ms: stagger continues smoothly without aborting!
        profileController.add(
          const Profile(
            id: me,
            username: 'minh',
            displayName: 'Minh Nguyen',
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 55));
        await tester.pump(const Duration(milliseconds: 50));
        expect(statsFade.opacity.value, greaterThan(0.0));
        expect(statsFade.opacity.value, lessThan(1.0));

        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        expect(headerFade.opacity.value, 1.0);
        expect(statsFade.opacity.value, 1.0);
        expect(find.byKey(const ValueKey('profile-card')), findsOneWidget);
      },
    );

    testWidgets(
      'showProfileConfirmDialog 3-point 200ms scale(0.96 -> 1.0) entrance, asymmetric 150ms exit, warning haptic, and Android + iOS Reduce Motion fallback',
      (tester) async {
        final haptics = _recordHaptics(tester);

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

        // 2. Mid-flight entrance (t = 90ms of 200ms): ScaleTransition is between 0.96 and 1.0
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

        // 3. Settled entrance (t >= 200ms), then verify 150ms asymmetric exit
        await tester.pumpAndSettle();
        expect(scaleTransition.scale.value, 1.0);
        await tester.tap(find.byKey(const ValueKey('profile-confirm-accept')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 75));
        expect(dialogFinder, findsOneWidget);
        await tester.pump(const Duration(milliseconds: 80));
        await tester.pump();
        expect(dialogFinder, findsNothing);
        expect(dialogResult, isTrue);

        // 4. Android Reduce-Motion parity (disableAnimations: true): zero ScaleTransition mounted, settles within 160ms
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

        // 5. iOS Reduce-Motion parity (FakeAccessibilityFeatures(reduceMotion: true)): zero ScaleTransition mounted
        setHost(() => disableAnimations = false);
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(reduceMotion: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
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
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      },
    );
  });
}
