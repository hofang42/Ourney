import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/ui.dart';

Widget host(
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  Size size = const Size(390, 844),
}) {
  return MediaQuery(
    data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
    child: MaterialApp(
      theme: OurneyTheme.build(brightness),
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    ),
  );
}

OurneyUi paletteOf(Brightness b) =>
    b == Brightness.dark ? OurneyUi.dark : OurneyUi.light;

BoxDecoration decorOf(WidgetTester t, Finder f) =>
    (t.widget<Container>(f).decoration! as BoxDecoration);

void main() {
  for (final b in Brightness.values) {
    final ui = paletteOf(b);
    group('V2 sticker kit ($b)', () {
      testWidgets('chip: selected is brand + ink label, 44 visual in 48 hit', (
        t,
      ) async {
        await t.pumpWidget(
          host(
            Column(
              children: [
                UiChip(label: 'Off', onPressed: () {}),
                UiChip(label: 'On', selected: true, onPressed: () {}),
              ],
            ),
            brightness: b,
          ),
        );
        final containers = outlined(find.byType(UiChip));
        final off = decorOf(t, containers.at(0));
        final on = decorOf(t, containers.at(1));
        expect(off.color, ui.surface);
        expect(on.color, ui.brand);
        expect(
          (on.border! as Border).top,
          BorderSide(color: ui.outline, width: UiBorder.thin),
        );
        expect(
          t
              .widget<Text>(
                find.descendant(
                  of: find.byType(UiChip).at(1),
                  matching: find.text('On'),
                ),
              )
              .style!
              .color,
          ui.onBrand,
        );
        expect(t.getSize(containers.at(0)).height, 44);
        expect(t.getSize(find.byType(UiPressable).first).height, 48);
        // 3dp hard shadow on a selectable chip.
        final shadow =
            t
                    .widgetList<AnimatedContainer>(
                      find.byType(AnimatedContainer),
                    )
                    .first
                    .decoration!
                as BoxDecoration;
        expect(shadow.boxShadow!.single.offset, const Offset(3, 3));
      });

      testWidgets('tag has the 1.5dp outline', (t) async {
        await t.pumpWidget(host(const UiTag(label: 'Tag'), brightness: b));
        final d = decorOf(
          t,
          find.descendant(
            of: find.byType(UiTag),
            matching: find.byType(Container),
          ),
        );
        expect((d.border! as Border).top.width, UiBorder.thin);
        expect(d.boxShadow, isNull);
      });

      testWidgets('card: outline, radius, shadow, sticker press', (t) async {
        var taps = 0;
        await t.pumpWidget(
          host(
            UiCard(onPressed: () => taps++, child: const Text('Card')),
            brightness: b,
          ),
        );
        final box = outlined(find.byType(UiCard));
        final d = decorOf(t, box.first);
        expect(d.borderRadius, BorderRadius.circular(16));
        expect((d.border! as Border).top.width, 2);
        final animated = find.descendant(
          of: find.byType(UiPressable),
          matching: find.byType(AnimatedContainer),
        );
        AnimatedContainer ac() => t.widget<AnimatedContainer>(animated.first);
        expect(
          (ac().decoration! as BoxDecoration).boxShadow!.single.offset,
          const Offset(4, 4),
        );
        final before = t.getTopLeft(box.first);
        final g = await t.startGesture(t.getCenter(box.first));
        await t.pump();
        await t.pump(const Duration(milliseconds: 200));
        expect(t.getTopLeft(box.first) - before, const Offset(4, 4));
        expect((ac().decoration! as BoxDecoration).boxShadow, isEmpty);
        await g.up();
        await t.pumpAndSettle();
        expect(taps, 1);
        expect(t.getTopLeft(box.first), before);
      });

      testWidgets('static card carries the hard shadow, menu is 16dp', (
        t,
      ) async {
        await t.pumpWidget(
          host(
            Column(
              children: [
                const UiCard(child: Text('x')),
                UiMenuSurface(
                  children: [UiMenuItem(label: 'Item', onPressed: () {})],
                ),
              ],
            ),
            brightness: b,
          ),
        );
        final card = decorOf(
          t,
          find.descendant(
            of: find.byType(UiCard),
            matching: find.byType(Container),
          ),
        );
        expect(card.boxShadow!.single.color, ui.outline);
        final menu = decorOf(
          t,
          find
              .descendant(
                of: find.byType(UiMenuSurface),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(menu.borderRadius, BorderRadius.circular(16));
        expect(menu.boxShadow!.single.offset, const Offset(4, 4));
        expect(
          t.getSize(find.byType(UiMenuItem)).height,
          greaterThanOrEqualTo(48),
        );
      });

      testWidgets('text field: label, radius, outline, error under field', (
        t,
      ) async {
        final c = TextEditingController();
        await t.pumpWidget(
          host(
            UiTextField(label: 'Email', controller: c, error: 'Sai email'),
            brightness: b,
          ),
        );
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Sai email'), findsOneWidget);
        final deco = t.widget<TextField>(find.byType(TextField)).decoration!;
        final border = deco.enabledBorder! as OutlineInputBorder;
        expect(border.borderRadius, BorderRadius.circular(12));
        expect(border.borderSide.width, 2);
        expect(border.borderSide.color, ui.danger);
        expect(
          t.getTopLeft(find.text('Sai email')).dy,
          greaterThan(t.getBottomLeft(find.byType(TextField)).dy - 1),
        );
      });

      testWidgets('text field: focus draws a 3dp brand ring', (t) async {
        final c = TextEditingController();
        final f = FocusNode();
        await t.pumpWidget(
          host(
            UiTextField(label: 'Ten', controller: c, focusNode: f),
            brightness: b,
          ),
        );
        BoxDecoration ring() =>
            t
                    .widget<DecoratedBox>(
                      find.byKey(const ValueKey('ui-field-ring')),
                    )
                    .decoration
                as BoxDecoration;
        expect(ring().boxShadow, isEmpty);
        expect(
          (t
                      .widget<TextField>(find.byType(TextField))
                      .decoration!
                      .enabledBorder!
                  as OutlineInputBorder)
              .borderSide
              .color,
          ui.outline,
        );
        f.requestFocus();
        await t.pump();
        final s = ring().boxShadow!.single;
        expect(s.color, ui.brand);
        expect(s.spreadRadius, 3);
        expect(s.blurRadius, 0);
      });

      testWidgets('otp: 48x58 boxes, 8 gap, active shadow, error outline', (
        t,
      ) async {
        final c = TextEditingController();
        final f = FocusNode();
        var error = false;
        late StateSetter set;
        await t.pumpWidget(
          host(
            StatefulBuilder(
              builder: (_, s) {
                set = s;
                return UiOtpField(
                  controller: c,
                  focusNode: f,
                  digitLabel: 'code',
                  hasError: error,
                );
              },
            ),
            brightness: b,
          ),
        );
        Finder box(int i) => find.byKey(ValueKey('ui-otp-box-$i'));
        expect(t.getSize(box(0)), const Size(48, 58));
        expect(t.getTopLeft(box(1)).dx - t.getTopRight(box(0)).dx, 8);
        f.requestFocus();
        await t.pump();
        await t.enterText(find.byType(TextField), '12');
        await t.pump();
        expect(find.text('1'), findsOneWidget);
        BoxDecoration d(int i) => decorOf(t, box(i));
        expect(d(2).boxShadow!.single.color, ui.brand);
        expect(d(2).boxShadow!.single.offset, const Offset(4, 4));
        expect(d(0).boxShadow, isNull);
        expect((d(0).border! as Border).top.color, ui.outline);
        expect(d(0).borderRadius, BorderRadius.circular(12));
        set(() => error = true);
        await t.pump();
        expect((d(0).border! as Border).top.color, ui.danger);
        expect(
          t.widget<Text>(find.text('1')).style!.fontFamily,
          UiFonts.spaceGrotesk,
        );
        expect(t.widget<Text>(find.text('1')).style!.fontSize, 28);
      });

      testWidgets('switch row: 46x27 track, 18 thumb, brand when on', (
        t,
      ) async {
        var v = false;
        late StateSetter set;
        await t.pumpWidget(
          host(
            StatefulBuilder(
              builder: (_, s) {
                set = s;
                return UiSwitchRow(
                  label: 'Nhac nho',
                  value: v,
                  onChanged: (x) => set(() => v = x),
                );
              },
            ),
            brightness: b,
          ),
        );
        const track = ValueKey('ui-switch-track');
        expect(t.getSize(find.byKey(track)), const Size(46, 27));
        expect(
          t.getSize(find.byKey(const ValueKey('ui-switch-thumb'))).width,
          18,
        );
        expect(
          t.getSize(find.byType(UiPressable)).height,
          greaterThanOrEqualTo(48),
        );
        await t.tap(find.byType(UiSwitchRow));
        await t.pumpAndSettle();
        expect(v, isTrue);
        final d =
            t.widget<AnimatedContainer>(find.byKey(track)).decoration!
                as BoxDecoration;
        expect(d.color, ui.brand);
        expect((d.border! as Border).top.width, 1.5);
      });

      testWidgets('back header: 44 outlined button in a 48 hit area', (
        t,
      ) async {
        var back = 0;
        await t.pumpWidget(
          host(
            UiBackHeader(
              onBack: () => back++,
              backLabel: 'Quay lai',
              title: 'Hanh trinh',
            ),
            brightness: b,
          ),
        );
        final btn = find.byKey(const ValueKey('ui-bar-icon-button'));
        expect(t.getSize(btn), const Size(44, 44));
        final d = decorOf(t, btn);
        expect(d.shape, BoxShape.circle);
        expect((d.border! as Border).top.width, 1.5);
        expect(t.getSize(find.byType(UiPressable)), const Size(48, 48));
        final bar = decorOf(
          t,
          find
              .descendant(
                of: find.byType(UiBackHeader),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(
          (bar.border! as Border).bottom,
          BorderSide(color: ui.ink.withValues(alpha: 0.12)),
        );
        expect(t.widget<Text>(find.text('Hanh trinh')).style!.fontSize, 27);
        await t.tap(btn);
        expect(back, 1);
      });

      testWidgets('top bar glass flag defaults off', (t) async {
        await t.pumpWidget(
          host(const UiTopBar(title: 'Hom nay'), brightness: b),
        );
        expect(find.byType(BackdropFilter), findsNothing);
        await t.pumpWidget(
          host(const UiTopBar(title: 'Hom nay', glass: true), brightness: b),
        );
        expect(find.byType(BackdropFilter), findsOneWidget);
      });

      testWidgets('keyboard focus ring on a chip', (t) async {
        await t.pumpWidget(
          host(
            UiChip(label: 'Focus', onPressed: () {}),
            brightness: b,
          ),
        );
        await t.sendKeyEvent(LogicalKeyboardKey.tab);
        await t.pump();
        final ring = t
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .where((d) {
              final dec = d.decoration;
              return dec is BoxDecoration &&
                  dec.border is Border &&
                  (dec.border! as Border).top.color == ui.focus &&
                  (dec.border! as Border).top.width == 3;
            });
        expect(ring, isNotEmpty);
      });

      testWidgets('no overflow at 1.35x text on 320dp', (t) async {
        final c = TextEditingController();
        final f = FocusNode();
        await t.pumpWidget(
          host(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const UiBackHeader(
                  onBack: _noop,
                  backLabel: 'Quay lai',
                  title: 'Mot tieu de rat dai de kiem tra cat chu Viet',
                  subtitle: 'Phu de cung kha dai de kiem tra',
                ),
                UiTopBar(
                  title: 'Mot tieu de rat dai de kiem tra cat chu',
                  actions: [
                    UiBarIconButton(
                      icon: Icons.add_rounded,
                      label: 'Them',
                      onPressed: () {},
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    UiChip(
                      label: 'Mot nhan chip kha dai de kiem tra cat chu',
                      selected: true,
                      onPressed: () {},
                    ),
                    const UiTag(label: 'Tag rat dai de kiem tra cat chu viet'),
                  ],
                ),
                UiCard(onPressed: () {}, child: const Text('Noi dung the')),
                UiRow(
                  title: 'Mot dong rat dai de kiem tra cat chu tieng Viet',
                  onPressed: () {},
                  sticker: true,
                ),
                UiTextField(
                  label: 'Ten dang nhap',
                  controller: c,
                  error: 'Loi kha dai de kiem tra xuong dong tren man hinh nho',
                ),
                UiOtpField(controller: c, focusNode: f, digitLabel: 'code'),
                UiSwitchRow(
                  label: 'Mot cai dat co nhan rat dai de kiem tra xuong dong',
                  subtitle: 'Mo ta',
                  value: true,
                  onChanged: (_) {},
                ),
              ],
            ),
            brightness: b,
            textScale: 1.35,
            size: const Size(320, 640),
          ),
        );
        await t.pump();
        expect(t.takeException(), isNull);
      });
    });
  }
}

void _noop() {}

/// Containers inside [of] that draw an outline (skips AnimatedContainer's
/// internal shadow/translate container).
Finder outlined(Finder of) => find.descendant(
  of: of,
  matching: find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration! as BoxDecoration).border != null,
  ),
);
