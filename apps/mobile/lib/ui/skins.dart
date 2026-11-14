import 'package:flutter/material.dart';

import 'tokens.dart';

/// One accent variant of a [UiSkin] (`skin.variants[n]` in the V2 StyleGuide).
@immutable
class UiSkinVariant {
  const UiSkinVariant({
    required this.name,
    required this.accent,
    required this.button,
    required this.buttonLabel,
    required this.secondary,
  });

  final String name;
  final Color accent;

  /// Fill of the primary button and shutter.
  final Color button;

  /// Label color on [button].
  final Color buttonLabel;
  final Color secondary;
}

/// The four neutral colors of a skin in one brightness.
@immutable
class UiSkinPalette {
  const UiSkinPalette({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.muted,
  });

  final Color bg;
  final Color surface;
  final Color ink;
  final Color muted;
}

/// A V2 journey skin: palettes for both brightnesses, three accent variants
/// and the heading font. Native skin per journey type:
/// quiet=Giảm cân, squad=Tiếng Anh, memory=Chuyến đi, couple=Cặp đôi,
/// flexer=Tập luyện, minimal=Tự đặt.
@immutable
class UiSkin {
  const UiSkin({
    required this.id,
    required this.short,
    required this.journey,
    required this.headingFont,
    required this.mood,
    required this.light,
    required this.dark,
    required this.variants,
    this.borderWidth = UiBorder.standard,
  });

  final String id;
  final String short;
  final String journey;
  final String headingFont;
  final String mood;
  final UiSkinPalette light;
  final UiSkinPalette dark;
  final List<UiSkinVariant> variants;

  /// Outline width: 1.5 for the quiet skin, 2 elsewhere.
  final double borderWidth;

  UiSkinPalette palette(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  UiSkinVariant variant(int index) =>
      variants[index.clamp(0, variants.length - 1)];

  /// The variant after V2's one override: minimal variant 1 in dark mode
  /// uses a light button.
  UiSkinVariant resolvedVariant(int index, Brightness brightness) {
    final v = variant(index);
    if (id == 'minimal' && index == 1 && brightness == Brightness.dark) {
      return UiSkinVariant(
        name: v.name,
        accent: v.accent,
        button: const Color(0xFFF4F4F5),
        buttonLabel: const Color(0xFF0E0E10),
        secondary: v.secondary,
      );
    }
    return v;
  }

  /// The shell palette recolored for this skin and variant.
  OurneyUi apply(OurneyUi base, {int variantIndex = 0}) {
    final p = palette(base.brightness);
    final v = resolvedVariant(variantIndex, base.brightness);
    return base.copyWith(
      bg: p.bg,
      surface: p.surface,
      ink: p.ink,
      inkMuted: p.muted,
      brand: v.button,
      onBrand: v.buttonLabel,
      accent: v.accent,
    );
  }
}

/// Journey-type pastel stickers (`typePastel` in V2 routes.tsx), used by type
/// badges, the camera journey chip and the wheel discs.
abstract final class UiTypePastel {
  static const weightLoss = Color(0xFF7EE8A2);
  static const english = Color(0xFFFFD84D);
  static const trip = Color(0xFFFFB347);
  static const couple = Color(0xFFFF7E7E);
  static const workout = Color(0xFFCF9FFF);
  static const custom = Color(0xFF7EC8E3);
}

/// The six V2 skins, indexed like the StyleGuide.
const List<UiSkin> uiSkins = [
  UiSkin(
    id: 'quiet',
    short: 'Lặng',
    journey: 'Giảm cân',
    headingFont: 'Fraunces',
    mood: 'Lâm sàng dịu nhẹ · nét mảnh',
    borderWidth: UiBorder.thin,
    light: UiSkinPalette(
      bg: Color(0xFFEFF3F0),
      surface: Color(0xFFFFFFFF),
      ink: Color(0xFF0F172A),
      muted: Color(0xFF53605B),
    ),
    dark: UiSkinPalette(
      bg: Color(0xFF0B0F12),
      surface: Color(0xFF151C21),
      ink: Color(0xFFF1F5F9),
      muted: Color(0xFFA8B2B9),
    ),
    variants: [
      UiSkinVariant(
        name: 'Lục ngọc',
        accent: Color(0xFF10B981),
        button: Color(0xFFFF4D6D),
        buttonLabel: Color(0xFF0F172A),
        secondary: Color(0xFFB7E8D1),
      ),
      UiSkinVariant(
        name: 'Xanh sage',
        accent: Color(0xFF6B9E8A),
        button: Color(0xFFD9694F),
        buttonLabel: Color(0xFF0F172A),
        secondary: Color(0xFFCADBD4),
      ),
      UiSkinVariant(
        name: 'Sương mù',
        accent: Color(0xFF6E9AC0),
        button: Color(0xFFE8A25C),
        buttonLabel: Color(0xFF0F172A),
        secondary: Color(0xFFD4E4F0),
      ),
    ],
  ),
  UiSkin(
    id: 'squad',
    short: 'Đội',
    journey: 'Tiếng Anh',
    headingFont: 'Space Grotesk',
    mood: 'Sổ kem · đồng đội rực lửa',
    light: UiSkinPalette(
      bg: Color(0xFFF7F1E5),
      surface: Color(0xFFFFFDF9),
      ink: Color(0xFF1E1B18),
      muted: Color(0xFF665F57),
    ),
    dark: UiSkinPalette(
      bg: Color(0xFF12131A),
      surface: Color(0xFF1D1F2B),
      ink: Color(0xFFF8FAFC),
      muted: Color(0xFFB6BAC8),
    ),
    variants: [
      UiSkinVariant(
        name: 'Lửa',
        accent: Color(0xFFFF9F1C),
        button: Color(0xFFFF9F1C),
        buttonLabel: Color(0xFF1E1B18),
        secondary: Color(0xFF7556F8),
      ),
      UiSkinVariant(
        name: 'Tím',
        accent: Color(0xFF7556F8),
        button: Color(0xFFFF9F1C),
        buttonLabel: Color(0xFF1E1B18),
        secondary: Color(0xFF7556F8),
      ),
      UiSkinVariant(
        name: 'Phấn',
        accent: Color(0xFF4FA36B),
        button: Color(0xFFE9B949),
        buttonLabel: Color(0xFF1E1B18),
        secondary: Color(0xFF7556F8),
      ),
    ],
  ),
  UiSkin(
    id: 'memory',
    short: 'Ký ức',
    journey: 'Chuyến đi',
    headingFont: 'Fraunces',
    mood: 'Giấy hạt · băng dính · phim',
    light: UiSkinPalette(
      bg: Color(0xFFF4EFE6),
      surface: Color(0xFFFFFFFF),
      ink: Color(0xFF231F1E),
      muted: Color(0xFF675E59),
    ),
    dark: UiSkinPalette(
      bg: Color(0xFF141312),
      surface: Color(0xFF1F1D1B),
      ink: Color(0xFFF5F2EB),
      muted: Color(0xFFB8B0A6),
    ),
    variants: [
      UiSkinVariant(
        name: 'Sương thông',
        accent: Color(0xFFCC4A2F),
        button: Color(0xFFCC4A2F),
        buttonLabel: Color(0xFFFFFFFF),
        secondary: Color(0xFF4A6B53),
      ),
      UiSkinVariant(
        name: 'Biển muối',
        accent: Color(0xFF2F6F8F),
        button: Color(0xFF2F6F8F),
        buttonLabel: Color(0xFFFFFFFF),
        secondary: Color(0xFFD9A441),
      ),
      UiSkinVariant(
        name: 'Phố đêm',
        accent: Color(0xFF7B5EA7),
        button: Color(0xFF7B5EA7),
        buttonLabel: Color(0xFFFFFFFF),
        secondary: Color(0xFFE0A43A),
      ),
    ],
  ),
  UiSkin(
    id: 'couple',
    short: 'Đôi',
    journey: 'Cặp đôi',
    headingFont: 'Playfair Display',
    mood: 'Khung đôi · lãng mạn thanh lịch',
    light: UiSkinPalette(
      bg: Color(0xFFF9F0EE),
      surface: Color(0xFFFFFFFF),
      ink: Color(0xFF261F22),
      muted: Color(0xFF6D5E64),
    ),
    dark: UiSkinPalette(
      bg: Color(0xFF171215),
      surface: Color(0xFF241C21),
      ink: Color(0xFFFCE7F3),
      muted: Color(0xFFCDB5C2),
    ),
    variants: [
      UiSkinVariant(
        name: 'Hồng',
        accent: Color(0xFF9D174D),
        button: Color(0xFFE15B72),
        buttonLabel: Color(0xFF1A1316),
        secondary: Color(0xFF9D174D),
      ),
      UiSkinVariant(
        name: 'Mâm xôi',
        accent: Color(0xFFE15B72),
        button: Color(0xFF9D174D),
        buttonLabel: Color(0xFFFFFFFF),
        secondary: Color(0xFFE15B72),
      ),
      UiSkinVariant(
        name: 'Đào',
        accent: Color(0xFFB4533A),
        button: Color(0xFFF08A6B),
        buttonLabel: Color(0xFF1A1316),
        secondary: Color(0xFFB4533A),
      ),
    ],
  ),
  UiSkin(
    id: 'flexer',
    short: 'Năng lượng',
    journey: 'Tập luyện',
    headingFont: 'Barlow Condensed',
    mood: 'Kính mờ · viền phát sáng',
    light: UiSkinPalette(
      bg: Color(0xFFF3F4F6),
      surface: Color(0xFFFFFFFF),
      ink: Color(0xFF090A0F),
      muted: Color(0xFF525660),
    ),
    dark: UiSkinPalette(
      bg: Color(0xFF090A0F),
      surface: Color(0xFF14161F),
      ink: Color(0xFFF8FAFC),
      muted: Color(0xFFA9AFBD),
    ),
    variants: [
      UiSkinVariant(
        name: 'Lime neon',
        accent: Color(0xFF3DE88C),
        button: Color(0xFFFF4D6D),
        buttonLabel: Color(0xFF090A0F),
        secondary: Color(0xFF263D34),
      ),
      UiSkinVariant(
        name: 'San hô điện',
        accent: Color(0xFFFF4D6D),
        button: Color(0xFF3DE88C),
        buttonLabel: Color(0xFF090A0F),
        secondary: Color(0xFF46252E),
      ),
      UiSkinVariant(
        name: 'Băng',
        accent: Color(0xFF7DD3FC),
        button: Color(0xFFC4B5FD),
        buttonLabel: Color(0xFF090A0F),
        secondary: Color(0xFF293848),
      ),
    ],
  ),
  UiSkin(
    id: 'minimal',
    short: 'Tối giản',
    journey: 'Tự đặt',
    headingFont: 'Space Grotesk',
    mood: 'Lưới 1 điểm · không trang trí',
    light: UiSkinPalette(
      bg: Color(0xFFF5F3EE),
      surface: Color(0xFFFFFFFF),
      ink: Color(0xFF1C1C1E),
      muted: Color(0xFF626166),
    ),
    dark: UiSkinPalette(
      bg: Color(0xFF0E0E10),
      surface: Color(0xFF18181B),
      ink: Color(0xFFF4F4F5),
      muted: Color(0xFFA1A1AA),
    ),
    variants: [
      UiSkinVariant(
        name: 'Cam',
        accent: Color(0xFFEA580C),
        button: Color(0xFFEA580C),
        buttonLabel: Color(0xFF1C1C1E),
        secondary: Color(0xFF27272A),
      ),
      UiSkinVariant(
        name: 'Than',
        accent: Color(0xFF27272A),
        button: Color(0xFF27272A),
        buttonLabel: Color(0xFFFFFFFF),
        secondary: Color(0xFF27272A),
      ),
      UiSkinVariant(
        name: 'Trời',
        accent: Color(0xFF0EA5E9),
        button: Color(0xFF0EA5E9),
        buttonLabel: Color(0xFF1C1C1E),
        secondary: Color(0xFF27272A),
      ),
    ],
  ),
];

/// Lookup by V2 skin id (`quiet`, `squad`, `memory`, `couple`, `flexer`,
/// `minimal`); falls back to `minimal`.
UiSkin uiSkinById(String id) =>
    uiSkins.firstWhere((s) => s.id == id, orElse: () => uiSkins.last);
