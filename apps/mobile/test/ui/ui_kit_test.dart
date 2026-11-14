import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart' show PersonaSkinId;

Widget host(
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  Size? size,
}) {
  final app = MaterialApp(
    theme: OurneyTheme.build(brightness),
    home: Scaffold(
      body: SafeArea(child: SingleChildScrollView(child: child)),
    ),
  );
  return MediaQuery(
    data: MediaQueryData(
      size: size ?? const Size(390, 844),
      textScaler: TextScaler.linear(textScale),
    ),
    child: app,
  );
}

void main() {
  group('tokens (index.css)', () {
    test('light and dark values match the V2 shell', () {
      expect(OurneyUi.light.bg, const Color(0xFFFFF8EE));
      expect(OurneyUi.light.ink, const Color(0xFF1A1A1A));
      expect(OurneyUi.light.inkMuted, const Color(0xFF5A544C));
      expect(OurneyUi.light.brand, const Color(0xFFFF8A3D));
      expect(OurneyUi.light.danger, const Color(0xFFB3261E));
      expect(OurneyUi.dark.bg, const Color(0xFF121212));
      expect(OurneyUi.dark.ink, const Color(0xFFF5F0E6));
      expect(OurneyUi.dark.surface, const Color(0xFF1C1B19));
      expect(OurneyUi.dark.inkMuted, const Color(0xFFB8B0A4));
      expect(OurneyUi.dark.brand, const Color(0xFFFF8A3D));
    });

    test('skins recolor the shell per skin, variant and brightness', () {
      expect(uiSkins.map((s) => s.id), [
        'quiet',
        'squad',
        'memory',
        'couple',
        'flexer',
        'minimal',
      ]);
      expect(uiSkins.every((s) => s.variants.length == 3), isTrue);
      final quiet = uiSkinById('quiet').apply(OurneyUi.light);
      expect(quiet.bg, const Color(0xFFEFF3F0));
      expect(quiet.brand, const Color(0xFFFF4D6D));
      // The variant accent is its own token; brand stays the button fill.
      expect(quiet.accent, const Color(0xFF10B981));
      expect(OurneyUi.light.accent, const Color(0xFFFF8A3D));
      expect(OurneyUi.light.onDanger, const Color(0xFFFFFFFF));
      expect(uiSkinIdFor(PersonaSkinId.coupleRituals), 'couple');
      expect(
        PersonaSkinId.values.map(uiSkinIdFor).toSet(),
        uiSkins.map((s) => s.id).toSet(),
      );
      final dark = uiSkinById('squad').apply(OurneyUi.dark, variantIndex: 1);
      expect(dark.bg, const Color(0xFF12131A));
      expect(dark.ink, const Color(0xFFF8FAFC));
      // V2 override: minimal variant 1 in dark mode uses a light button.
      final minimal = uiSkinById('minimal')
          .apply(OurneyUi.dark, variantIndex: 1);
      expect(minimal.brand, const Color(0xFFF4F4F5));
      expect(minimal.onBrand, const Color(0xFF0E0E10));
      // Derived neutrals follow the skin, not the warm shell.
      expect(quiet.surfaceInput, quiet.surface);
      expect(quiet.inputBorder, quiet.ink);
      expect(quiet.fill, isNot(OurneyUi.light.fill));
      expect(quiet.divider, isNot(OurneyUi.light.divider));
      expect(uiSkinById('quiet').borderWidth, UiBorder.thin);
      expect(uiSkinById('nope').id, 'minimal');
    });

    test('responsive gutters follow CLAUDE.md', () {
      expect(UiSpace.gutter(320), 16);
      expect(UiSpace.gutter(375), 20);
      expect(UiSpace.gutter(430), 24);
      expect(UiSpace.maxContent(430), 480);
      expect(UiSpace.maxContent(800), 520);
    });

    testWidgets('theme exposes the kit in both modes', (tester) async {
      for (final b in Brightness.values) {
        late OurneyUi seen;
        await tester.pumpWidget(
          MaterialApp(
            theme: OurneyTheme.build(b),
            home: Builder(
              builder: (context) {
                seen = context.ui;
                return Scaffold(
                  body: Text('x', style: Theme.of(context).textTheme.bodyLarge),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(seen.brightness, b);
        expect(
          Theme.of(tester.element(find.text('x'))).scaffoldBackgroundColor,
          seen.bg,
        );
      }
    });
  });

  group('components', () {
    testWidgets('UiButton taps, disables and keeps a 48dp target', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          Column(
            children: [
              UiButton(
                key: const ValueKey('p'),
                label: 'Tiếp tục',
                onPressed: () => taps++,
              ),
              UiButton.secondary(
                key: const ValueKey('s'),
                label: 'Để sau',
                compact: true,
                onPressed: () => taps += 10,
              ),
              const UiButton(key: ValueKey('d'), label: 'Tắt', onPressed: null),
            ],
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const ValueKey('p'))).height, 52);
      // Compact is 44dp visually but keeps a 48dp hit area.
      expect(tester.getSize(find.byKey(const ValueKey('s'))).height, 48);
      expect(
        tester
            .getSize(
              find
                  .descendant(
                    of: find.byKey(const ValueKey('s')),
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .height,
        44,
      );
      await tester.tap(find.byKey(const ValueKey('p')));
      await tester.tap(find.byKey(const ValueKey('s')));
      await tester.tap(find.byKey(const ValueKey('d')));
      expect(taps, 11);
    });

    testWidgets('plain controls press-scale to 0.96', (tester) async {
      await tester.pumpWidget(
        host(UiButton.ghost(label: 'Go', onPressed: () {})),
      );
      final g = await tester.startGesture(tester.getCenter(find.text('Go')));
      await tester.pump(const Duration(milliseconds: 200));
      final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scale.scale, UiMotion.pressScale);
      await g.up();
    });

    testWidgets('primary button uses the sticker press', (tester) async {
      await tester.pumpWidget(host(UiButton(label: 'Go', onPressed: () {})));
      AnimatedContainer sticker() => tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      expect(sticker().decoration, isA<BoxDecoration>());
      expect((sticker().decoration! as BoxDecoration).boxShadow, hasLength(1));
      final g = await tester.startGesture(tester.getCenter(find.text('Go')));
      await tester.pump(const Duration(milliseconds: 200));
      // Pressed: no scale, shadow gone, translated by the 4dp offset.
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      expect((sticker().decoration! as BoxDecoration).boxShadow, isEmpty);
      expect(sticker().transform!.getTranslation().x, UiShadow.large);
      await g.up();
    });

    testWidgets(
      'UiGlass keeps the 2dp outline and an outside-only hard shadow',
      (tester) async {
        await tester.pumpWidget(host(const UiGlass(child: Text('glass'))));
        BoxDecoration deco() => tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(UiGlass),
                matching: find.byType(DecoratedBox),
              ),
            )
            .map((d) => d.decoration)
            .whereType<BoxDecoration>()
            .firstWhere((d) => d.border != null);
        expect((deco().border! as Border).top.width, UiBorder.standard);
        expect(find.byType(ClipPath), findsOneWidget);

        // The painted shadow: 4dp offset in the palette outline (ink).
        ({double dx, double dy, Color color}) shadow() {
          final clip = find.descendant(
            of: find.byType(UiGlass),
            matching: find.byType(ClipPath),
          );
          final t = tester.widget<Transform>(
            find.descendant(of: clip, matching: find.byType(Transform)),
          );
          final box = tester.widget<DecoratedBox>(
            find.descendant(of: clip, matching: find.byType(DecoratedBox)),
          );
          final v = t.transform.getTranslation();
          return (
            dx: v.x,
            dy: v.y,
            color: (box.decoration as BoxDecoration).color!,
          );
        }

        final hard = shadow();
        expect(hard.dx, UiShadow.large);
        expect(hard.dy, UiShadow.large);
        expect(hard.color, OurneyUi.light.outline);

        await tester.pumpWidget(
          host(const UiGlass(hardShadow: 0, child: Text('glass'))),
        );
        expect(find.byType(ClipPath), findsNothing);

        // Camera chip: 2px cream outline, 2px black hard shadow.
        await tester.pumpWidget(
          host(const UiGlass.camera(child: Text('chip'))),
        );
        expect((deco().border! as Border).top.color, UiCamera.outline);
        expect(find.byType(ClipPath), findsOneWidget);
        final cam = shadow();
        expect(cam.dx, UiShadow.tiny);
        expect(cam.dy, UiShadow.tiny);
        expect(cam.color, UiCamera.shadow);
      },
    );

    testWidgets('UiGlass blurs, then goes opaque and stays clipped', (
      tester,
    ) async {
      await tester.pumpWidget(host(const UiGlass(child: Text('glass'))));
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.byType(ClipRRect), findsWidgets);

      // App-level Reduce Transparency setting.
      await tester.pumpWidget(
        host(const UiGlass(reduceTransparency: true, child: Text('glass'))),
      );
      expect(find.byType(BackdropFilter), findsNothing);
      expect(
        find.descendant(
          of: find.byType(UiGlass),
          matching: find.byType(ClipRRect),
        ),
        findsOneWidget,
        reason: 'the opaque fallback still clips to the rounded corners',
      );

      // Platform high-contrast flag (set inside host(), which owns the
      // outer MediaQuery).
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(highContrast: true),
              child: const UiGlass(child: Text('glass')),
            ),
          ),
        ),
      );
      expect(find.byType(BackdropFilter), findsNothing);
      expect(UiGlass.saturationMatrix(1)[0], closeTo(1, 1e-9));
    });

    testWidgets('UiSegmented switches value', (tester) async {
      var v = 'a';
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => host(
            UiSegmented<String>(
              segments: const [
                UiSegment(value: 'a', label: 'Của tôi'),
                UiSegment(value: 'b', label: 'Được chia sẻ', showDot: true),
              ],
              value: v,
              onChanged: (n) => setState(() => v = n),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Được chia sẻ'));
      await tester.pump();
      expect(v, 'b');
    });

    testWidgets('UiOtpField shows typed digits and caps at 6', (tester) async {
      final c = TextEditingController();
      final f = FocusNode();
      addTearDown(c.dispose);
      addTearDown(f.dispose);
      await tester.pumpWidget(
        host(UiOtpField(controller: c, focusNode: f, digitLabel: 'Mã 6 số')),
      );
      await tester.enterText(find.byType(TextField), '123456789');
      await tester.pump();
      expect(c.text, '123456');
      for (final d in '123456'.split('')) {
        expect(find.text(d), findsOneWidget);
      }
    });

    testWidgets('UiTextField shows error over helper', (tester) async {
      final c = TextEditingController();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        host(
          UiTextField(
            label: 'Email',
            controller: c,
            helper: 'help',
            error: 'bad',
          ),
        ),
      );
      expect(find.text('bad'), findsOneWidget);
      expect(find.text('help'), findsNothing);
    });

    testWidgets('showUiSheet / permission sheet pops true and false', (
      tester,
    ) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: OurneyTheme.build(Brightness.dark),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => result = await showUiPermissionSheet(
                  context: context,
                  icon: Icons.notifications_none_rounded,
                  title: 'Bật thông báo?',
                  body: 'Nội dung',
                  primaryLabel: 'Bật',
                  secondaryLabel: 'Để sau',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Bật thông báo?'), findsOneWidget);
      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bật'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('UiDock routes taps to its three slots', (tester) async {
      final taps = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: OurneyTheme.build(Brightness.light),
          home: Scaffold(
            bottomNavigationBar: UiDock(
              left: UiDockItem(
                icon: Icons.map_outlined,
                label: 'Hành trình',
                active: true,
                onPressed: () => taps.add('left'),
              ),
              right: UiDockItem(
                icon: Icons.group_outlined,
                label: 'Squad',
                onPressed: () => taps.add('right'),
              ),
              snapLabel: 'Chụp',
              onSnap: () => taps.add('snap'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Hành trình'));
      await tester.tap(find.text('Squad'));
      await tester.tap(find.bySemanticsLabel('Chụp'));
      expect(taps, ['left', 'right', 'snap']);
      // 56x40 pill inside a 48dp hit area.
      expect(
        tester.getSize(
          find
              .descendant(
                of: find.byType(UiSnapPill),
                matching: find.byType(Container),
              )
              .first,
        ),
        const Size(UiSize.snapPillW, UiSize.snapPillH),
      );
      expect(tester.getSize(find.byType(UiSnapPill)).height, 48);
    });

    for (final dark in [false, true]) {
      testWidgets('kit gallery has no overflow at 1.35x / 320dp, '
          '${dark ? 'dark' : 'light'}', (tester) async {
        tester.view.physicalSize = const Size(320 * 2, 640 * 2);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          host(
            brightness: dark ? Brightness.dark : Brightness.light,
            textScale: 1.35,
            size: const Size(320, 640),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const UiTopBar(
                    title: 'Hành trình của tôi và những người bạn đồng hành',
                    eyebrow: 'Đang diễn ra',
                  ),
                  UiBackHeader(
                    onBack: () {},
                    backLabel: 'Quay lại',
                    title: 'Một tiêu đề dài ngoằng không vừa một dòng đâu nhé',
                    subtitle: 'phụ đề',
                  ),
                  UiButton(
                    label:
                        'Một nhãn nút khá dài để thử tràn dòng ở tỉ lệ chữ lớn',
                    onPressed: () {},
                  ),
                  UiRow(
                    title: 'Đọc sách mỗi ngày không bỏ sót ngày nào cả',
                    subtitle: const UiStyleLabel(
                      label: 'Minimalist Habit',
                      dot: Color(0xFFEA580C),
                    ),
                    meta: const UiPrivacyTag(
                      type: UiPrivacy.squad,
                      label: 'Nhóm',
                    ),
                    leading: const UiAvatar(name: 'Linh'),
                    onPressed: () {},
                  ),
                  UiSwitchRow(
                    label: 'Nhắc tôi mỗi ngày vào lúc tối muộn',
                    subtitle: 'Chỉ khi chuỗi ngày sắp mất',
                    value: true,
                    onChanged: (_) {},
                  ),
                  const UiProgressBar(value: 0.8),
                  const UiListHeading(
                    title: 'Hành trình đang diễn ra',
                    actionLabel: 'Xem tất cả',
                  ),
                ],
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
