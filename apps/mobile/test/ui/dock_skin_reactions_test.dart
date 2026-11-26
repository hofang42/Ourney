import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/components/dock.dart';
import 'package:ourney/ui/components/dock_tab.dart'
    show dockBaselineDescenderRatio;
import 'package:ourney/ui/components/glass.dart';
import 'package:ourney/ui/components/ourney_icons.dart';
import 'package:ourney/ui/components/pressable.dart';
import 'package:ourney/ui/components/reaction_bar.dart';
import 'package:ourney/ui/components/skin_scope.dart';
import 'package:ourney/ui/skins.dart';
import 'package:ourney/ui/theme.dart';
import 'package:ourney/ui/tokens.dart';

Widget host(
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  Size size = const Size(390, 780),
  bool highContrast = false,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: OurneyTheme.build(brightness),
    home: MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
        highContrast: highContrast,
      ),
      child: Scaffold(
        body: Align(alignment: Alignment.bottomCenter, child: child),
      ),
    ),
  );
}

const reactionLabels = {
  'clap': 'Vỗ tay',
  'flex': 'Cố lên',
  'heart': 'Thương',
  'laugh': 'Haha',
  'fire': 'Cháy',
};

UiDock fiveTab(List<String> taps, {int active = 0, VoidCallback? onLong}) {
  UiDockItem item(String glyph, String label, int i) => UiDockItem(
    glyph: glyph,
    label: label,
    active: active == i,
    itemKey: ValueKey('tab-$i'),
    onPressed: () => taps.add(label),
  );
  return UiDock(
    left: item('journeys', 'Hành trình', 0),
    extraLeft: [item('squad', 'Nhóm', 1)],
    extraRight: [item('activity', 'Hoạt động', 3)],
    right: item('profile', 'Hồ sơ', 4),
    snapLabel: 'Chụp',
    snapKey: const ValueKey('snap'),
    onSnap: () => taps.add('snap'),
    onShutterLongPress: onLong,
  );
}

void main() {
  group('svg path parser', () {
    test('absolute and relative lines, H/V, Z', () {
      expect(
        parseSvgPath('M0 0H10V5Z').getBounds(),
        const Rect.fromLTRB(0, 0, 10, 5),
      );
      expect(
        parseSvgPath('m1 1 l 4 0 0 3 z').getBounds(),
        const Rect.fromLTRB(1, 1, 5, 4),
      );
    });

    test('implicit lineto after M and compact numbers', () {
      final b = parseSvgPath('M2 2 6 2-.5 8').getBounds();
      expect(b.left, -0.5);
      expect(b.right, 6);
      expect(b.bottom, 8);
    });

    test('curves and arcs stay inside the viewBox', () {
      expect(
        parseSvgPath('M0 0C0 4 4 4 4 0S8-4 8 0Q10 3 12 0').getBounds().right,
        12,
      );
      final arc = parseSvgPath('M2 12a4 4 0 0 1 8 0').getBounds();
      expect(arc.left, closeTo(2, 0.01));
      expect(arc.right, closeTo(10, 0.01));
      expect(arc.top, closeTo(8, 0.1));
    });

    test('rejects data without a leading command', () {
      expect(() => parseSvgPath('10 10'), throwsFormatException);
    });

    test('every drawn icon parses to a non-empty path in the viewBox', () {
      expect(
        ourneyIconNames,
        containsAll([
          'journeys',
          'squad',
          'camera',
          'activity',
          'profile',
          'react-clap',
          'react-flex',
          'react-heart',
          'react-laugh',
          'react-fire',
          'react-wave',
        ]),
      );
      for (final name in ourneyIconNames) {
        final b = ourneyIconPath(name)!.getBounds();
        expect(b.isEmpty, isFalse, reason: name);
        expect(b.left, greaterThanOrEqualTo(0), reason: name);
        expect(b.top, greaterThanOrEqualTo(0), reason: name);
        expect(b.right, lessThanOrEqualTo(24), reason: name);
        expect(b.bottom, lessThanOrEqualTo(24), reason: name);
      }
      expect(
        ourneyIconNames,
        containsAll([
          'chevron-right',
          'chevron-left',
          'chevron-down',
          'chevron-up',
          'arrow-right',
          'more',
          'search',
          'send',
          'download',
          'copy',
          'edit',
          'trash',
          'info',
          'error',
          'check-circle',
          'logout',
          'login',
          'bell',
          'bell-off',
          'mail',
          'link',
          'link-off',
          'flag',
          'block',
          'eye',
          'eye-off',
          'refresh',
          'undo',
          'shield',
          'user-plus',
          'user-minus',
          'mic',
          'camera-off',
          'gallery',
          'image-off',
          'image-plus',
          'grid',
          'flash-off',
          'flash-auto',
          'translate',
          'radio-off',
          'radio-on',
          'gavel',
          'chat',
          'chat-off',
          'sparkle',
          'inbox',
          'home',
          'qr',
          'phone',
          'restaurant',
          'palette',
          'music',
          'leaf',
          'drop',
          'lotus',
        ]),
      );
      expect(ourneyIconPath('nope'), isNull);
    });
  });

  group('UiDock', () {
    for (final activeTab in [0, 3]) {
      testWidgets(
        '360dp Vietnamese label stays inside the capsule ($activeTab)',
        (tester) async {
          await tester.pumpWidget(
            host(
              UiDock(
                left: UiDockItem(
                  glyph: 'journeys',
                  label: 'Hành trình',
                  active: activeTab == 0,
                  onPressed: () {},
                ),
                extraLeft: [
                  UiDockItem(
                    glyph: 'squad',
                    label: 'Nhóm',
                    active: activeTab == 1,
                    onPressed: () {},
                  ),
                ],
                extraRight: [
                  UiDockItem(
                    glyph: 'activity',
                    label: 'Hoạt động',
                    active: activeTab == 3,
                    onPressed: () {},
                  ),
                ],
                right: UiDockItem(
                  glyph: 'profile',
                  label: 'Hồ sơ',
                  active: activeTab == 4,
                  onPressed: () {},
                ),
                snapLabel: 'Chụp',
                onSnap: () {},
              ),
              size: const Size(360, 780),
            ),
          );
          await tester.pump();
          final pill = tester.getRect(
            find.byKey(const ValueKey('dock-selection-pill')),
          );
          final label = tester.getRect(
            find.text(activeTab == 0 ? 'Hành trình' : 'Hoạt động'),
          );
          final r = (pill.width < pill.height ? pill.width : pill.height) / 2;
          bool inside(Offset p) {
            final cx = p.dx.clamp(pill.left + r, pill.right - r);
            final cy = p.dy.clamp(pill.top + r, pill.bottom - r);
            return (p - Offset(cx, cy)).distance <= r - UiBorder.thin + 0.5;
          }

          final baselineY =
              label.bottom - dockBaselineDescenderRatio * label.height;
          for (final p in [
            Offset(label.left, baselineY),
            Offset(label.right, baselineY),
            label.topLeft,
            label.topRight,
          ]) {
            expect(inside(p), isTrue, reason: 'label point $p vs $pill');
          }
          expect(label.top, greaterThanOrEqualTo(pill.top));
          expect(label.bottom, lessThanOrEqualTo(pill.bottom));
        },
      );
    }

    testWidgets('5 tabs: taps, selection pill slides, labels', (tester) async {
      final taps = <String>[];
      var active = 0;
      late StateSetter set;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return UiDock(
                left: UiDockItem(
                  glyph: 'journeys',
                  label: 'Hành trình',
                  active: active == 0,
                  onPressed: () => taps.add('j'),
                ),
                extraLeft: [
                  UiDockItem(
                    glyph: 'squad',
                    label: 'Nhóm',
                    active: active == 1,
                    onPressed: () => taps.add('h'),
                  ),
                ],
                extraRight: [
                  UiDockItem(
                    glyph: 'activity',
                    label: 'Hoạt động',
                    active: active == 3,
                    onPressed: () => taps.add('a'),
                  ),
                ],
                right: UiDockItem(
                  glyph: 'profile',
                  label: 'Hồ sơ',
                  active: active == 4,
                  onPressed: () => taps.add('p'),
                ),
                snapLabel: 'Chụp',
                onSnap: () => taps.add('snap'),
              );
            },
          ),
        ),
      );
      expect(find.text('Squad'), findsNothing);
      for (final l in ['Hành trình', 'Nhóm', 'Hoạt động', 'Hồ sơ']) {
        await tester.tap(find.text(l));
      }
      await tester.tap(find.bySemanticsLabel('Chụp'));
      expect(taps, ['j', 'h', 'a', 'p', 'snap']);

      final pill = find.byKey(const ValueKey('dock-selection-pill'));
      expect(tester.getSize(pill).height, 52);
      expect(tester.getSize(pill).width, inInclusiveRange(60, 74));
      final deco =
          tester.widget<DecoratedBox>(pill).decoration as BoxDecoration;
      expect(deco.borderRadius, BorderRadius.circular(26));
      // Even the outermost tab keeps clear padding inside the dock border.
      expect(
        tester.getTopLeft(pill).dx - tester.getTopLeft(find.byType(UiDock)).dx,
        greaterThanOrEqualTo(8),
      );
      final x0 = tester.getCenter(pill).dx;
      set(() => active = 4);
      await tester.pump();
      // Bounded: the 280ms slide must be finished by the 320ms mark.
      await tester.pump(const Duration(milliseconds: 160));
      await tester.pump(const Duration(milliseconds: 160));
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.getCenter(pill).dx, greaterThan(x0 + 100));
      expect(
        tester.getCenter(pill).dx,
        closeTo(tester.getCenter(find.text('Hồ sơ')).dx, 2),
      );
    });

    for (final b in Brightness.values) {
      testWidgets(
        'edge pill keeps air inside the border, ${b.name} (bug #11)',
        (tester) async {
          for (final active in [0, 4]) {
            await tester.pumpWidget(
              host(fiveTab([], active: active), brightness: b),
            );
            await tester.pumpAndSettle();
            final islands = find.byType(UiGlass);
            final glass = tester.getRect(
              active == 0 ? islands.first : islands.last,
            );
            final pill = tester.getRect(
              find.byKey(const ValueKey('dock-selection-pill')),
            );
            const shadow = UiShadow.tiny;
            expect(pill.top - glass.top, greaterThanOrEqualTo(5));
            expect(
              glass.bottom - (pill.bottom + shadow),
              greaterThanOrEqualTo(4),
            );
            expect(pill.left - glass.left, greaterThanOrEqualTo(4));
            expect(
              glass.right - (pill.right + shadow),
              greaterThanOrEqualTo(3),
            );
          }
        },
      );

      testWidgets('active and pressed tabs keep coloured stickers, ${b.name}', (
        tester,
      ) async {
        await tester.pumpWidget(host(fiveTab([]), brightness: b));
        await tester.pumpAndSettle();
        final tab = find.byKey(const ValueKey('tab-0'));
        final gesture = await tester.startGesture(tester.getCenter(tab));
        await tester.pump(const Duration(milliseconds: 60));
        final icons = tester.widgetList<OurneyIcon>(
          find.descendant(
            of: find.byType(UiDock),
            matching: find.byType(OurneyIcon),
          ),
        );
        for (final icon in icons.where((i) => i.name != 'camera')) {
          // No solid single-colour fill: the V2 palette shows through.
          expect(icon.color, isNull, reason: icon.name);
          expect(icon.inkColor, isNull, reason: icon.name);
        }
        final active = tester.widget<OurneyIcon>(
          find.descendant(of: tab, matching: find.byType(OurneyIcon)),
        );
        expect(active.active, isTrue);
        await gesture.up();
      });
    }

    testWidgets('dock is BackdropFilter glass with a translucent tint', (
      tester,
    ) async {
      await tester.pumpWidget(host(fiveTab([])));
      final glasses = tester.widgetList<UiGlass>(find.byType(UiGlass)).toList();
      expect(glasses, hasLength(2));
      for (final glass in glasses) {
        expect(glass.blur, 20);
        expect(glass.borderWidth, UiBorder.standard);
        expect(glass.hardShadow, greaterThan(0));
        expect(glass.tint!.a, lessThan(0.9));
      }
      expect(find.byType(BackdropFilter), findsNWidgets(2));
    });

    testWidgets('selection pill jumps at once under reduce-motion', (
      tester,
    ) async {
      var active = 0;
      late StateSetter set;
      await tester.pumpWidget(
        MaterialApp(
          theme: OurneyTheme.build(Brightness.light),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 780),
              disableAnimations: true,
            ),
            child: Scaffold(
              bottomNavigationBar: StatefulBuilder(
                builder: (c, s) {
                  set = s;
                  return UiDock(
                    left: UiDockItem(
                      glyph: 'journeys',
                      label: 'A',
                      active: active == 0,
                      onPressed: () {},
                    ),
                    right: UiDockItem(
                      glyph: 'profile',
                      label: 'B',
                      active: active == 1,
                      onPressed: () {},
                    ),
                    snapLabel: 'Chụp',
                    onSnap: () {},
                  );
                },
              ),
            ),
          ),
        ),
      );
      final pill = find.byKey(const ValueKey('dock-selection-pill'));
      final x0 = tester.getCenter(pill).dx;
      set(() => active = 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.getCenter(pill).dx, greaterThan(x0 + 100));
    });

    testWidgets('3-slot compatibility with Material icons', (tester) async {
      final taps = <String>[];
      await tester.pumpWidget(
        host(
          UiDock(
            left: UiDockItem(
              icon: Icons.map_outlined,
              label: 'Hành trình',
              active: true,
              onPressed: () => taps.add('l'),
            ),
            right: UiDockItem(
              icon: Icons.group_outlined,
              label: 'Nhóm',
              onPressed: () => taps.add('r'),
            ),
            snapLabel: 'Chụp',
            onSnap: () => taps.add('s'),
          ),
        ),
      );
      await tester.tap(find.text('Hành trình'));
      await tester.tap(find.text('Nhóm'));
      await tester.tap(find.bySemanticsLabel('Chụp'));
      expect(taps, ['l', 'r', 's']);
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    });

    testWidgets('long press on the shutter fires after 400ms, tap does not', (
      tester,
    ) async {
      final taps = <String>[];
      var long = 0;
      await tester.pumpWidget(host(fiveTab(taps, onLong: () => long++)));
      await tester.tap(find.byKey(const ValueKey('snap')));
      await tester.pump(const Duration(seconds: 1));
      expect(long, 0);
      expect(taps, ['snap']);
      await tester.longPress(find.byKey(const ValueKey('snap')));
      await tester.pump();
      expect(long, 1);
    });

    testWidgets('glass blur by default, solid when transparency is reduced', (
      tester,
    ) async {
      await tester.pumpWidget(host(fiveTab([])));
      expect(find.byType(UiGlass), findsNWidgets(2));
      expect(find.byType(BackdropFilter), findsNWidgets(2));

      await tester.pumpWidget(
        host(
          UiDock(
            left: UiDockItem(glyph: 'journeys', label: 'A', onPressed: () {}),
            right: UiDockItem(glyph: 'profile', label: 'B', onPressed: () {}),
            snapLabel: 'Chụp',
            onSnap: () {},
            reduceTransparency: true,
          ),
        ),
      );
      expect(find.byType(BackdropFilter), findsNothing);

      await tester.pumpWidget(host(fiveTab([]), highContrast: true));
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('quiet skin thins the outline, others use 2dp', (tester) async {
      Future<double> outline(String skin) async {
        await tester.pumpWidget(
          host(UiSkinScope(skinId: skin, child: fiveTab([]))),
        );
        await tester.pumpAndSettle();
        return tester.widget<UiGlass>(find.byType(UiGlass).first).borderWidth;
      }

      expect(await outline('quiet'), UiBorder.thin);
      expect(await outline('squad'), UiBorder.standard);
    });

    testWidgets('camera dock hosts the 76dp shutter', (tester) async {
      var long = 0;
      await tester.pumpWidget(
        host(
          UiDock(
            camera: true,
            left: UiDockItem(glyph: 'journeys', label: 'A', onPressed: () {}),
            right: UiDockItem(glyph: 'profile', label: 'B', onPressed: () {}),
            snapLabel: 'Chụp',
            onSnap: () {},
            center: UiShutter(
              label: 'Chụp',
              onPressed: () {},
              onLongPress: () => long++,
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(UiShutter)).height, UiSize.shutter);
      await tester.longPress(find.byType(UiShutter));
      expect(long, 1);
    });

    for (final b in Brightness.values) {
      testWidgets('5-tab dock: no overflow at 320dp / 1.35x, ${b.name}', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          host(
            fiveTab([]),
            brightness: b,
            textScale: 1.35,
            size: const Size(320, 640),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final i in [0, 1, 3, 4]) {
          final s = tester.getSize(find.byKey(ValueKey('tab-$i')));
          expect(s.width, greaterThanOrEqualTo(48), reason: 'tab $i');
          expect(s.height, greaterThanOrEqualTo(48), reason: 'tab $i');
        }
      });
    }
  });

  group('UiSkinScope', () {
    for (final skin in uiSkins) {
      for (final b in Brightness.values) {
        testWidgets('${skin.id} ${b.name} recolors context.ui', (tester) async {
          late OurneyUi seen;
          late UiSkinScopeData data;
          await tester.pumpWidget(
            MaterialApp(
              theme: OurneyTheme.build(b),
              home: UiSkinScope(
                skinId: skin.id,
                variant: 1,
                child: Builder(
                  builder: (context) {
                    seen = context.ui;
                    data = UiSkinScope.of(context);
                    return const SizedBox();
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final p = skin.palette(b);
          final v = skin.resolvedVariant(1, b);
          expect(seen.bg, p.bg);
          expect(seen.surface, p.surface);
          expect(seen.ink, p.ink);
          expect(seen.brand, v.button);
          expect(seen.onBrand, v.buttonLabel);
          expect(data.skin.id, skin.id);
          expect(data.variantIndex, 1);
          expect(data.variant.button, v.button);
          expect(data.headingFont, isNotEmpty);
        });
      }
    }

    testWidgets('minimal variant 1 in dark uses the light button', (
      tester,
    ) async {
      late OurneyUi seen;
      await tester.pumpWidget(
        MaterialApp(
          theme: OurneyTheme.build(Brightness.dark),
          home: UiSkinScope(
            skinId: 'minimal',
            variant: 1,
            child: Builder(
              builder: (context) {
                seen = context.ui;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(seen.brand, const Color(0xFFE4E4E7));
    });

    testWidgets('animates 320ms when the skin changes', (tester) async {
      Widget app(String id) => MaterialApp(
        theme: OurneyTheme.build(Brightness.light),
        home: UiSkinScope(
          skinId: id,
          child: Builder(
            builder: (c) => ColoredBox(
              key: const ValueKey('bg'),
              color: c.ui.bg,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.pumpWidget(app('quiet'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(app('couple'));
      await tester.pump(const Duration(milliseconds: 160));
      final mid = tester.widget<ColoredBox>(find.byKey(const ValueKey('bg')));
      expect(mid.color, isNot(uiSkinById('couple').light.bg));
      expect(mid.color, isNot(uiSkinById('quiet').light.bg));
      // Bounded: 160ms + 160ms reaches the 320ms mark, no open-ended settle.
      await tester.pump(const Duration(milliseconds: 160));
      expect(
        tester.widget<ColoredBox>(find.byKey(const ValueKey('bg'))).color,
        uiSkinById('couple').light.bg,
      );
    });

    testWidgets('maybeOf is null without a scope', (tester) async {
      UiSkinScopeData? data = UiSkinScopeData(
        skin: uiSkins.first,
        variantIndex: 0,
        variant: uiSkins.first.variant(0),
        headingFont: 'x',
      );
      await tester.pumpWidget(
        Builder(
          builder: (c) {
            data = UiSkinScope.maybeOf(c);
            return const SizedBox();
          },
        ),
      );
      expect(data, isNull);
    });
  });

  group('UiReactionBar', () {
    testWidgets('five Vietnamese-labelled 48dp targets with 38dp visuals', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final got = <String>[];
      await tester.pumpWidget(
        host(
          UiReactionBar(
            labels: reactionLabels,
            onReact: got.add,
            selected: 'heart',
            counts: const {'fire': 3},
          ),
        ),
      );
      const labels = ['Vỗ tay', 'Cố lên', 'Thương', 'Haha', 'Cháy, 3'];
      for (final l in labels) {
        expect(find.bySemanticsLabel(l), findsOneWidget, reason: l);
      }
      for (final id in uiReactionIds) {
        expect(
          tester.getSize(find.byKey(ValueKey('reaction-disc-$id'))),
          const Size(38, 38),
        );
      }
      final targets = find.byType(UiPressable);
      expect(targets, findsNWidgets(5));
      for (final e in targets.evaluate()) {
        final s = tester.getSize(find.byWidget(e.widget));
        expect(s.width, greaterThanOrEqualTo(48));
        expect(s.height, greaterThanOrEqualTo(48));
      }
      expect(
        tester.getSemantics(find.bySemanticsLabel('Thương')),
        matchesSemantics(
          label: 'Thương',
          isButton: true,
          isSelected: true,
          isEnabled: true,
          hasEnabledState: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.bySemanticsLabel('Cháy, 3'));
      expect(got, ['fire']);
      expect(uiReactionIds, ['clap', 'flex', 'heart', 'laugh', 'fire']);
      handle.dispose();
    });

    for (final b in Brightness.values) {
      testWidgets('no overflow at 320dp / 1.35x, ${b.name}', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          host(
            UiReactionBar(
              labels: reactionLabels,
              onReact: (_) {},
              selected: 'clap',
              counts: const {'clap': 128, 'fire': 7},
            ),
            brightness: b,
            textScale: 1.35,
            size: const Size(320, 640),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(UiReactionBar)).width,
          lessThanOrEqualTo(320),
        );
      });
    }
  });

  group('UiDock height regression', () {
    for (final camera in [false, true]) {
      testWidgets('keeps its own height inside a Scaffold (camera=$camera)', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OurneyTheme.build(Brightness.light),
            home: Scaffold(
              body: const SizedBox.expand(),
              bottomNavigationBar: UiDock(
                camera: camera,
                snapLabel: 'Chụp',
                onSnap: () {},
                left: UiDockItem(
                  icon: Icons.map,
                  label: 'A',
                  onPressed: () {},
                  active: true,
                ),
                right: UiDockItem(
                  icon: Icons.group,
                  label: 'B',
                  onPressed: () {},
                ),
              ),
            ),
          ),
        );
        // A Center without a height once made the glass fill the screen and
        // swallow every tap above it.
        final height = tester.getSize(find.byType(UiDock)).height;
        expect(height, camera ? 90 : 84);
        expect(tester.getSize(find.byType(UiGlass).first).height, 64);
      });
    }
  });
}
