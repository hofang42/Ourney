import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/theme/persona_theme.dart';
import 'package:ourney/shared/color_utils.dart';
import 'package:ourney/shared/dashed_placeholder.dart';
import 'package:ourney/shared/ourney_pill_button.dart';
import 'package:ourney/shared/ourney_primary_button.dart';
import 'package:ourney/shared/persona_pill.dart';
import 'package:ourney/shared/polaroid_frame.dart';

import '../personas/pump_persona.dart';

Widget _all({VoidCallback? onTap}) => ListView(
  padding: const EdgeInsets.all(16),
  children: [
    OurneyPrimaryButton(
      label: 'Chụp ảnh check-in hôm nay',
      icon: Icons.photo_camera_rounded,
      onPressed: onTap ?? () {},
    ),
    const SizedBox(height: 8),
    OurneyPrimaryButton(
      label: 'Đóng',
      compact: true,
      onPressed: onTap ?? () {},
    ),
    const SizedBox(height: 8),
    const OurneyPrimaryButton(label: 'Đang tắt', onPressed: null),
    const SizedBox(height: 8),
    OurneyPillButton(
      icon: Icons.photo_camera_rounded,
      semanticLabel: 'Chụp',
      onPressed: onTap ?? () {},
    ),
    const SizedBox(height: 8),
    const PersonaPill(
      label: '🏃 30 NGÀY · TẬP MỖI NGÀY ĐỂ KHỎE HƠN',
      icon: Icons.bolt,
    ),
    const SizedBox(height: 8),
    const PersonaPill(label: 'NGÀY 21', emphasized: true),
    const SizedBox(height: 8),
    const SizedBox(
      width: 160,
      child: PolaroidFrame(
        caption: 'Ngày 21 · Đà Lạt lạnh quá nên chụp vội',
        angle: -0.04,
        showTape: true,
        child: ColoredBox(color: Colors.grey),
      ),
    ),
    const SizedBox(height: 16),
    const SizedBox(
      width: 160,
      child: DashedPlaceholder(
        icon: Icons.hourglass_empty_rounded,
        label: 'Chưa chụp hôm nay',
      ),
    ),
  ],
);

void main() {
  for (final skin in allSkins) {
    for (final brightness in bothBrightness) {
      testWidgets('${skin.name} ${brightness.name}: shared widgets draw at '
          '320dp and 1.35x text without overflow', (tester) async {
        await pumpPersona(
          tester,
          _all(),
          skin: skin,
          brightness: brightness,
          width: 320,
          textScale: 1.35,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(OurneyPrimaryButton), findsNWidgets(3));
        expect(find.byType(PersonaPill), findsNWidgets(2));
        expect(find.byKey(const ValueKey('polaroid-tape')), findsOneWidget);
      });
    }
  }

  group('OurneyPrimaryButton', () {
    testWidgets('is 52dp, or 44dp compact, with a 48dp touch area', (
      tester,
    ) async {
      await pumpPersona(tester, _all());
      final buttons = find.byType(OurneyPrimaryButton);
      Size face(int i) => tester.getSize(
        find
            .descendant(of: buttons.at(i), matching: find.byType(Container))
            .first,
      );
      expect(face(0).height, 52);
      expect(face(1).height, 44);
      for (var i = 0; i < 3; i++) {
        expect(tester.getSize(buttons.at(i)).height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('uses the persona accent and a readable label', (tester) async {
      for (final skin in allSkins) {
        for (final brightness in bothBrightness) {
          await pumpPersona(
            tester,
            OurneyPrimaryButton(label: 'Chụp', onPressed: () {}),
            skin: skin,
            brightness: brightness,
          );
          final pTheme = OurneyPersonaTheme.forSkin(skin, brightness);
          final face = tester.widget<Container>(
            find
                .descendant(
                  of: find.byType(OurneyPrimaryButton),
                  matching: find.byType(Container),
                )
                .first,
          );
          final fill = (face.decoration! as BoxDecoration).color!;
          expect(fill, pTheme.primaryAccent);
          final text = tester.widget<Text>(find.text('Chụp'));
          expect(
            contrastRatio(text.style!.color!, fill),
            greaterThanOrEqualTo(4.5),
            reason: '${skin.name} ${brightness.name}',
          );
        }
      }
    });

    testWidgets('presses to 0.96 in 110ms and calls back on tap', (
      tester,
    ) async {
      var taps = 0;
      await pumpPersona(
        tester,
        OurneyPrimaryButton(label: 'Chụp', onPressed: () => taps++),
      );
      final scale = find.descendant(
        of: find.byType(OurneyPrimaryButton),
        matching: find.byType(AnimatedScale),
      );
      expect(tester.widget<AnimatedScale>(scale).scale, 1);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(OurneyPrimaryButton)),
      );
      await tester.pump();
      final pressed = tester.widget<AnimatedScale>(scale);
      expect(pressed.scale, 0.96);
      expect(pressed.duration, const Duration(milliseconds: 110));
      await gesture.up();
      await tester.pump();
      expect(tester.widget<AnimatedScale>(scale).scale, 1);
      expect(taps, 1);
    });

    testWidgets('draws the bottom lip only when the persona has one', (
      tester,
    ) async {
      for (final skin in allSkins) {
        await pumpPersona(
          tester,
          OurneyPrimaryButton(label: 'Chụp', onPressed: () {}),
          skin: skin,
        );
        final lip = OurneyPersonaTheme.forSkin(
          skin,
          Brightness.light,
        ).bottomLipHeight;
        final face = tester.getSize(
          find
              .descendant(
                of: find.byType(OurneyPrimaryButton),
                matching: find.byType(Container),
              )
              .first,
        );
        final whole = tester.getSize(
          find
              .descendant(
                of: find.byType(OurneyPrimaryButton),
                matching: find.byType(AnimatedScale),
              )
              .first,
        );
        expect(whole.height - face.height, lip, reason: skin.name);
      }
    });

    testWidgets('does nothing and reads as disabled without a callback', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpPersona(
        tester,
        const OurneyPrimaryButton(label: 'Chụp', onPressed: null),
      );
      expect(
        tester.getSemantics(find.byType(OurneyPrimaryButton)),
        matchesSemantics(
          label: 'Chụp',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });
  });

  group('OurneyPillButton', () {
    testWidgets('is 56x40 with a 48dp-high touch area', (tester) async {
      await pumpPersona(
        tester,
        OurneyPillButton(
          icon: Icons.photo_camera_rounded,
          semanticLabel: 'Chụp',
          onPressed: () {},
        ),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('ourney-pill-button-face'))),
        const Size(56, 40),
      );
      expect(tester.getSize(find.byType(OurneyPillButton)).height, 48);
    });
  });

  group('PolaroidFrame and DashedPlaceholder', () {
    testWidgets('keep the photo area square at any width', (tester) async {
      for (final width in [320.0, 430.0]) {
        await pumpPersona(
          tester,
          const Center(
            child: SizedBox(
              width: 150,
              child: PolaroidFrame(child: ColoredBox(color: Colors.grey)),
            ),
          ),
          width: width,
        );
        final photo = tester.getSize(find.byType(ColoredBox).last);
        expect(photo.width, photo.height);
      }
    });

    testWidgets('dashed placeholder is not only a color: it has a label', (
      tester,
    ) async {
      await pumpPersona(
        tester,
        const SizedBox(
          width: 120,
          child: DashedPlaceholder(label: 'Chưa chụp'),
        ),
      );
      expect(find.text('Chưa chụp'), findsOneWidget);
    });
  });

  test('readableOn picks the higher-contrast of white and dark ink', () {
    expect(readableOn(const Color(0xFF000000)), const Color(0xFFFFFFFF));
    expect(readableOn(const Color(0xFFFFFFFF)), isNot(const Color(0xFFFFFFFF)));
    expect(
      contrastRatio(
        readableOn(const Color(0xFFFF9F1C)),
        const Color(0xFFFF9F1C),
      ),
      greaterThanOrEqualTo(4.5),
    );
  });
}
