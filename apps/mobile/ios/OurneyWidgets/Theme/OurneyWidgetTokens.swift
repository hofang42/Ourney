import ImageIO
import SwiftUI
import UIKit
import WidgetKit

// MARK: - Hex Color & Luminance Helpers

public struct OurneyRGB: Equatable {
  public let r: Double
  public let g: Double
  public let b: Double
  public let a: Double

  public init(hex: UInt32, alpha: Double = 1.0) {
    self.r = Double((hex >> 16) & 0xFF) / 255.0
    self.g = Double((hex >> 8) & 0xFF) / 255.0
    self.b = Double(hex & 0xFF) / 255.0
    self.a = alpha
  }

  public init(r: Double, g: Double, b: Double, a: Double = 1.0) {
    self.r = r
    self.g = g
    self.b = b
    self.a = a
  }

  public var color: Color {
    Color(.sRGB, red: r, green: g, blue: b, opacity: a)
  }

  public func lerp(to other: OurneyRGB, t: Double) -> OurneyRGB {
    let clamped = min(max(t, 0.0), 1.0)
    return OurneyRGB(
      r: r + (other.r - r) * clamped,
      g: g + (other.g - g) * clamped,
      b: b + (other.b - b) * clamped,
      a: a + (other.a - a) * clamped
    )
  }

  public func blend(over background: OurneyRGB, alpha: Double) -> OurneyRGB {
    let a = min(max(alpha, 0.0), 1.0)
    return OurneyRGB(
      r: r * a + background.r * (1.0 - a),
      g: g * a + background.g * (1.0 - a),
      b: b * a + background.b * (1.0 - a),
      a: 1.0
    )
  }

  /// WCAG 2.1 relative luminance.
  public var relativeLuminance: Double {
    func channel(_ c: Double) -> Double {
      c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
  }

  public func contrastRatio(with other: OurneyRGB) -> Double {
    let l1 = max(relativeLuminance, other.relativeLuminance)
    let l2 = min(relativeLuminance, other.relativeLuminance)
    return (l1 + 0.05) / (l2 + 0.05)
  }

  public static func onAccent(for accent: OurneyRGB, preferred: OurneyRGB = OurneyRGB(hex: 0x1A1A1A)) -> OurneyRGB {
    let white = OurneyRGB(hex: 0xFFFFFF)
    if preferred.contrastRatio(with: accent) >= 4.5 {
      return preferred
    }
    if white.contrastRatio(with: accent) >= 4.5 {
      return white
    }
    return OurneyRGB(hex: 0x000000)
  }
}

// MARK: - Skin & Token Definitions (Exact parity with apps/mobile/lib/ui/tokens.dart & skins.dart)

public struct OurneySkinVariantSpec {
  public let accent: OurneyRGB
  public let accentDark: OurneyRGB?
  public let button: OurneyRGB
  public let buttonLabel: OurneyRGB
  public let secondary: OurneyRGB
}

public struct OurneySkinPaletteSpec {
  public let bg: OurneyRGB
  public let surface: OurneyRGB
  public let ink: OurneyRGB
  public let muted: OurneyRGB

  public func outline(isDark: Bool) -> OurneyRGB {
    isDark ? ink.lerp(to: bg, t: 0.55) : ink
  }
}

public struct OurneySkinSpec {
  public let id: String
  public let borderWidth: CGFloat
  public let light: OurneySkinPaletteSpec
  public let dark: OurneySkinPaletteSpec
  public let variants: [OurneySkinVariantSpec]

  public func resolvedVariant(index: Int, isDark: Bool) -> OurneySkinVariantSpec {
    let safeIdx = min(max(index, 0), max(variants.count - 1, 0))
    let v = variants[safeIdx]
    // V2 override: minimal variant 1 in dark mode uses a light button (#E4E4E7).
    if id == "minimal" && safeIdx == 1 && isDark {
      return OurneySkinVariantSpec(
        accent: v.accentDark ?? v.accent,
        accentDark: v.accentDark,
        button: OurneyRGB(hex: 0xE4E4E7),
        buttonLabel: OurneyRGB(hex: 0x18181A),
        secondary: v.secondary
      )
    }
    if isDark, let darkAccent = v.accentDark {
      return OurneySkinVariantSpec(
        accent: darkAccent,
        accentDark: darkAccent,
        button: v.button,
        buttonLabel: v.buttonLabel,
        secondary: v.secondary
      )
    }
    return v
  }
}

public struct OurneyWidgetTheme {
  public let isDark: Bool
  public let skinId: String
  public let borderWidth: CGFloat
  public let bgRGB: OurneyRGB
  public let surfaceRGB: OurneyRGB
  public let fillRGB: OurneyRGB
  public let inkRGB: OurneyRGB
  public let inkMutedRGB: OurneyRGB
  public let borderRGB: OurneyRGB
  public let outlineRGB: OurneyRGB
  public let hardShadowRGB: OurneyRGB
  public let brandRGB: OurneyRGB
  public let onBrandRGB: OurneyRGB
  public let accentRGB: OurneyRGB
  public let onAccentRGB: OurneyRGB
  public let successRGB: OurneyRGB
  public let successSoftRGB: OurneyRGB
  public let warnRGB: OurneyRGB
  public let dangerRGB: OurneyRGB
  public let flameRGB: OurneyRGB

  public var bg: Color { bgRGB.color }
  public var surface: Color { surfaceRGB.color }
  public var fill: Color { fillRGB.color }
  public var ink: Color { inkRGB.color }
  public var inkMuted: Color { inkMutedRGB.color }
  public var border: Color { borderRGB.color }
  public var outline: Color { outlineRGB.color }
  public var hardShadow: Color { hardShadowRGB.color }
  public var brand: Color { brandRGB.color }
  public var onBrand: Color { onBrandRGB.color }
  public var accent: Color { accentRGB.color }
  public var onAccent: Color { onAccentRGB.color }
  public var success: Color { successRGB.color }
  public var successSoft: Color { successSoftRGB.color }
  public var warn: Color { warnRGB.color }
  public var danger: Color { dangerRGB.color }
  public var flame: Color { flameRGB.color }

  /// Neutral V2 shell Light palette (`OurneyUi.light`).
  public static let neutralLight = OurneyWidgetTheme(
    isDark: false,
    skinId: "shell",
    borderWidth: 2.0,
    bgRGB: OurneyRGB(hex: 0xFFF8EE),
    surfaceRGB: OurneyRGB(hex: 0xFFFFFF),
    fillRGB: OurneyRGB(hex: 0xF6EEDF),
    inkRGB: OurneyRGB(hex: 0x1A1A1A),
    inkMutedRGB: OurneyRGB(hex: 0x5A544C),
    borderRGB: OurneyRGB(hex: 0xDCD2C2),
    outlineRGB: OurneyRGB(hex: 0x1A1A1A),
    hardShadowRGB: OurneyRGB(hex: 0x1A1A1A),
    brandRGB: OurneyRGB(hex: 0xFF8A3D),
    onBrandRGB: OurneyRGB(hex: 0x1A1A1A),
    accentRGB: OurneyRGB(hex: 0xFF8A3D),
    onAccentRGB: OurneyRGB(hex: 0x1A1A1A),
    successRGB: OurneyRGB(hex: 0x287747),
    successSoftRGB: OurneyRGB(hex: 0xDCFCE7),
    warnRGB: OurneyRGB(hex: 0xB33A0A),
    dangerRGB: OurneyRGB(hex: 0xB3261E),
    flameRGB: OurneyRGB(hex: 0xD97706)
  )

  /// Neutral V2 shell Dark palette (`OurneyUi.dark`).
  public static let neutralDark = OurneyWidgetTheme(
    isDark: true,
    skinId: "shell",
    borderWidth: 2.0,
    bgRGB: OurneyRGB(hex: 0x1B1916),
    surfaceRGB: OurneyRGB(hex: 0x25221E),
    fillRGB: OurneyRGB(hex: 0x2A2722),
    inkRGB: OurneyRGB(hex: 0xECE5D8),
    inkMutedRGB: OurneyRGB(hex: 0xB3AA9C),
    borderRGB: OurneyRGB(hex: 0x3C3A35),
    outlineRGB: OurneyRGB(hex: 0x79756D),
    hardShadowRGB: OurneyRGB(hex: 0x0C0B0A),
    brandRGB: OurneyRGB(hex: 0xFF8A3D),
    onBrandRGB: OurneyRGB(hex: 0x1A1A1A),
    accentRGB: OurneyRGB(hex: 0xFF8A3D),
    onAccentRGB: OurneyRGB(hex: 0x1A1A1A),
    successRGB: OurneyRGB(hex: 0x6FCF8E),
    successSoftRGB: OurneyRGB(hex: 0x1F3B2A),
    warnRGB: OurneyRGB(hex: 0xF2A070),
    dangerRGB: OurneyRGB(hex: 0xF2A097),
    flameRGB: OurneyRGB(hex: 0xF2A93B)
  )

  /// Always-dark `UiCamera` palette used by the Lock Screen Live Activity banner (§6.1).
  public static let cameraDark = OurneyWidgetTheme(
    isDark: true,
    skinId: "camera",
    borderWidth: 1.5,
    bgRGB: OurneyRGB(hex: 0x07070A),
    surfaceRGB: OurneyRGB(hex: 0x111114),
    fillRGB: OurneyRGB(hex: 0x1C1C22),
    inkRGB: OurneyRGB(hex: 0xF5F0E6),
    inkMutedRGB: OurneyRGB(hex: 0xB3AA9C),
    borderRGB: OurneyRGB(hex: 0x3C3A35),
    outlineRGB: OurneyRGB(hex: 0x79756D),
    hardShadowRGB: OurneyRGB(hex: 0x000000),
    brandRGB: OurneyRGB(hex: 0xFF8A3D),
    onBrandRGB: OurneyRGB(hex: 0x1A1A1A),
    accentRGB: OurneyRGB(hex: 0xFF8A3D),
    onAccentRGB: OurneyRGB(hex: 0x1A1A1A),
    successRGB: OurneyRGB(hex: 0x6FCF8E),
    successSoftRGB: OurneyRGB(hex: 0x1F3B2A),
    warnRGB: OurneyRGB(hex: 0xF2A070),
    dangerRGB: OurneyRGB(hex: 0xFF4D6D),
    flameRGB: OurneyRGB(hex: 0xF2A93B)
  )

  /// Authoritative 6 V2 skins × 3 variants (`apps/mobile/lib/ui/skins.dart`).
  public static let skins: [String: OurneySkinSpec] = [
    "quiet": OurneySkinSpec(
      id: "quiet",
      borderWidth: 1.5,
      light: OurneySkinPaletteSpec(
        bg: OurneyRGB(hex: 0xEFF3F0),
        surface: OurneyRGB(hex: 0xFFFFFF),
        ink: OurneyRGB(hex: 0x0F172A),
        muted: OurneyRGB(hex: 0x53605B)
      ),
      dark: OurneySkinPaletteSpec(
        bg: OurneyRGB(hex: 0x161B1C),
        surface: OurneyRGB(hex: 0x1F2628),
        ink: OurneyRGB(hex: 0xE6ECEA),
        muted: OurneyRGB(hex: 0xA7B2AF)
      ),
      variants: [
        OurneySkinVariantSpec(accent: OurneyRGB(hex: 0x10B981), accentDark: nil, button: OurneyRGB(hex: 0xFF4D6D), buttonLabel: OurneyRGB(hex: 0x0F172A), secondary: OurneyRGB(hex: 0xB7E8D1)),
        OurneySkinVariantSpec(accent: OurneyRGB(hex: 0x6B9E8A), accentDark: nil, button: OurneyRGB(hex: 0xD9694F), buttonLabel: OurneyRGB(hex: 0x0F172A), secondary: OurneyRGB(hex: 0xCADBD4)),
        OurneySkinVariantSpec(accent: OurneyRGB(hex: 0x6E9AC0), accentDark: nil, button: OurneyRGB(hex: 0xE8A25C), buttonLabel: OurneyRGB(hex: 0x0F172A), secondary: OurneyRGB(hex: 0xD4E4F0)),
      ]
    ),
    "squad": OurneySkinSpec(
      id: "squad",
      borderWidth: 2.0,
      light: OurneySkinPaletteSpec(
        bg: OurneyRGB(hex: 0xF7F1E5),
        surface: OurneyRGB(hex: 0xFFFDF9),
        ink: OurneyRGB(hex: 0x1E1B18),
        muted: OurneyRGB(hex: 0x665F57)
      ),
      dark: OurneySkinPaletteSpec(
        bg: OurneyRGB(hex: 0x191A22),
        surface: OurneyRGB(hex: 0x23252F),
        ink: OurneyRGB(hex: 0xEEEFF4),
        muted: OurneyRGB(hex: 0xB3B6C4)
      ),
      variants: [
        OurneySkinVariantSpec(accent: OurneyRGB(hex: 0xFF9F1C), accentDark: nil, button: OurneyRGB(hex: 0xFF9F1C), buttonLabel: OurneyRGB(hex: 0x1E1B18), secondary: OurneyRGB(hex: 0x7556F8)),
        OurneySkinVariantSpec(accent: OurneyRGB(hex: 0x7556F8), accentDark: OurneyRGB(hex: 0x9B87FA), button: OurneyRGB(hex: 0xFF9F1C), buttonLabel: OurneyRGB(hex: 0x1E1B18), secondary: OurneyRGB(hex: 0x7556F8)),
        OurneySkinVariantSpec(accent: OurneyRGB(hex: 0x4FA36B), accentDark: nil, button: OurneyRGB(hex: 0xE9B949), buttonLabel: OurneyRGB(hex: 0x1E1B18), secondary: OurneyRGB(hex: 0x7556F8)),
      ]
    ),
    "memory": OurneySkinSpec(
      id: "memory",
      borderWidth: 2.0,
      light: OurneySkinPaletteSpec(
        bg: OurneyRGB(hex: 0xF4EFE6),
        surface: OurneyRGB(hex: 0xFFFFFF),
        ink: OurneyRGB(hex: 0x231F1E),
        muted: OurneyRGB(hex: 0x675E59)
      ),
      dark: OurneySkinPaletteSpec(
        bg: OurneyRGB(hex: 0x1C1A17),
        surface: OurneyRGB(hex: 0x26231F),
        ink: OurneyRGB(hex: 0xEEE8DD),
        muted: OurneyRGB(hex: 0xB6AC9F)
      ),
      variants: [
        OurneySkinVariantSpec(accent: OurneyRGB(hex: 0xCC4A2F), accentDark: OurneyRGB(hex: 0xE07A5F), button: OurneyRGB(hex: 0xCC4A2F), buttonLabel: OurneyRGB(hex: 0xFFFFFF), secondary: OurneyRGB(hex: 0x4A6B53)),
        OurneySkinVariantSpec(accent: OurneyRGB(hex: 0x2F6F8F), accentDark: OurneyRGB(hex: 0x6FA8C7), button: OurneyRGB(hex: 0x2F6F8F), buttonLabel: OurneyRGB(hex: 0xFFFFFF), secondary: OurneyRGB(hex: 0xD9A441)),
        OurneySkinVariantSpec(accent: OurneyRGB(hex: 0x7B5EA7), accentDark: OurneyRGB(hex: 0xA98BD6), button: OurneyRGB(hex: 0x7B5EA7), buttonLabel: OurneyRGB(hex: 0xFFFFFF), secondary: OurneyRGB(hex: 0xE0A43A)),
      ]
    ),
    "couple": OurneySkinSpec(
      id: "couple",
      borderWidth: 2.0,
      light: OurneySkinPaletteSpec(
        bg: OurneyRGB(hex: 0xF9F0EE),
        surface: OurneyRGB(hex: 0xFFFFFF),
        ink: OurneyRGB(hex: 0x261F22),
        muted: OurneyRGB(hex: 0x6D5E64)
      ),
      dark: OurneySkinPaletteSpec(
        bg: OurneyRGB(hex: 0x1E181B),
        surface: OurneyRGB(hex: 0x2A2126),
        ink: OurneyRGB(hex: 0xF3E4EA),
        muted: OurneyRGB(hex: 0xC8B3BD)
      ),
      variants: [
        OurneySkinVariantSpec(accent: OurneyRGB(hex: 0x9D174D), accentDark: OurneyRGB(hex: 0xE7739A), button: OurneyRGB(hex: 0xE15B72), buttonLabel: OurneyRGB(hex: 0x1A1316), secondary: OurneyRGB(hex: 0x9D174D)),
        OurneySkinVariantSpec(accent: OurneyRGB(hex: 0xE15B72), accentDark: nil, button: OurneyRGB(hex: 0x9D174D), buttonLabel: OurneyRGB(hex: 0xFFFFFF), secondary: OurneyRGB(hex: 0xE15B72)),
        OurneySkinVariantSpec(accent: OurneyRGB(hex: 0xB4533A), accentDark: OurneyRGB(hex: 0xE08A6E), button: OurneyRGB(hex: 0xF08A6B), buttonLabel: OurneyRGB(hex: 0x1A1316), secondary: OurneyRGB(hex: 0xB4533A)),
      ]
    ),
    "flexer": OurneySkinSpec(
      id: "flexer",
      borderWidth: 2.0,
      light: OurneySkinPaletteSpec(
        bg: OurneyRGB(hex: 0xF3F4F6),
        surface: OurneyRGB(hex: 0xFFFFFF),
        ink: OurneyRGB(hex: 0x090A0F),
        muted: OurneyRGB(hex: 0x525660)
      ),
      dark: OurneySkinPaletteSpec(
        bg: OurneyRGB(hex: 0x14161C),
        surface: OurneyRGB(hex: 0x1E2029),
        ink: OurneyRGB(hex: 0xEEF0F5),
        muted: OurneyRGB(hex: 0xA9AFBD)
      ),
      variants: [
        OurneySkinVariantSpec(accent: OurneyRGB(hex: 0x3DE88C), accentDark: nil, button: OurneyRGB(hex: 0xFF4D6D), buttonLabel: OurneyRGB(hex: 0x090A0F), secondary: OurneyRGB(hex: 0x263D34)),
        OurneySkinVariantSpec(accent: OurneyRGB(hex: 0xFF4D6D), accentDark: nil, button: OurneyRGB(hex: 0x3DE88C), buttonLabel: OurneyRGB(hex: 0x090A0F), secondary: OurneyRGB(hex: 0x46252E)),
        OurneySkinVariantSpec(accent: OurneyRGB(hex: 0x7DD3FC), accentDark: nil, button: OurneyRGB(hex: 0xC4B5FD), buttonLabel: OurneyRGB(hex: 0x090A0F), secondary: OurneyRGB(hex: 0x293848)),
      ]
    ),
    "minimal": OurneySkinSpec(
      id: "minimal",
      borderWidth: 2.0,
      light: OurneySkinPaletteSpec(
        bg: OurneyRGB(hex: 0xF5F3EE),
        surface: OurneyRGB(hex: 0xFFFFFF),
        ink: OurneyRGB(hex: 0x1C1C1E),
        muted: OurneyRGB(hex: 0x626166)
      ),
      dark: OurneySkinPaletteSpec(
        bg: OurneyRGB(hex: 0x18181A),
        surface: OurneyRGB(hex: 0x222225),
        ink: OurneyRGB(hex: 0xECECEE),
        muted: OurneyRGB(hex: 0xA1A1AA)
      ),
      variants: [
        OurneySkinVariantSpec(accent: OurneyRGB(hex: 0xEA580C), accentDark: OurneyRGB(hex: 0xF07A3A), button: OurneyRGB(hex: 0xEA580C), buttonLabel: OurneyRGB(hex: 0x1C1C1E), secondary: OurneyRGB(hex: 0x27272A)),
        OurneySkinVariantSpec(accent: OurneyRGB(hex: 0x27272A), accentDark: OurneyRGB(hex: 0xD4D4D8), button: OurneyRGB(hex: 0x27272A), buttonLabel: OurneyRGB(hex: 0xFFFFFF), secondary: OurneyRGB(hex: 0x27272A)),
        OurneySkinVariantSpec(accent: OurneyRGB(hex: 0x0EA5E9), accentDark: nil, button: OurneyRGB(hex: 0x0EA5E9), buttonLabel: OurneyRGB(hex: 0x1C1C1E), secondary: OurneyRGB(hex: 0x27272A)),
      ]
    ),
  ]

  /// Avatar disc colors (`uiAvatarColors` in `apps/mobile/lib/ui/components/avatar.dart`).
  public static let avatarDiscRGBs: [OurneyRGB] = [
    OurneyRGB(hex: 0xE15B72),
    OurneyRGB(hex: 0x6D4BF0),
    OurneyRGB(hex: 0x2AA7E0),
    OurneyRGB(hex: 0x10B981),
    OurneyRGB(hex: 0xFF9F1C),
  ]

  public static func avatarDisc(for index: Int) -> (fill: Color, ink: Color) {
    let safe = ((index % avatarDiscRGBs.count) + avatarDiscRGBs.count) % avatarDiscRGBs.count
    let disc = avatarDiscRGBs[safe]
    let dark = OurneyRGB(hex: 0x1A1A1A)
    let white = OurneyRGB(hex: 0xFFFFFF)
    let inkRGB = disc.contrastRatio(with: white) >= disc.contrastRatio(with: dark) ? white : dark
    return (disc.color, inkRGB.color)
  }

  /// Resolves the active widget theme for `skinId`, `colorVariant`, `themeMode`, and iOS `ColorScheme`.
  public static func resolve(
    skinId: String?,
    colorVariant: Int = 0,
    themeMode: String = "system",
    systemScheme: ColorScheme
  ) -> OurneyWidgetTheme {
    let isDark: Bool
    switch themeMode.lowercased() {
    case "light":
      isDark = false
    case "dark":
      isDark = true
    default:
      isDark = (systemScheme == .dark)
    }

    let base = isDark ? neutralDark : neutralLight
    guard let id = skinId, let spec = skins[id] ?? skins[normalizeSkinId(id)] else {
      return base
    }

    let p = isDark ? spec.dark : spec.light
    let v = spec.resolvedVariant(index: colorVariant, isDark: isDark)
    let outline = p.outline(isDark: isDark)
    let hardShadow = isDark ? p.bg.lerp(to: OurneyRGB(hex: 0x000000), t: 0.55) : p.ink
    let fill = p.ink.blend(over: p.bg, alpha: 0.06)
    let border = p.ink.blend(over: p.bg, alpha: 0.16)
    let onAccent = OurneyRGB.onAccent(for: v.accent)

    return OurneyWidgetTheme(
      isDark: isDark,
      skinId: spec.id,
      borderWidth: spec.borderWidth,
      bgRGB: p.bg,
      surfaceRGB: p.surface,
      fillRGB: fill,
      inkRGB: p.ink,
      inkMutedRGB: p.muted,
      borderRGB: border,
      outlineRGB: outline,
      hardShadowRGB: hardShadow,
      brandRGB: v.button,
      onBrandRGB: v.buttonLabel,
      accentRGB: v.accent,
      onAccentRGB: onAccent,
      successRGB: base.successRGB,
      successSoftRGB: base.successSoftRGB,
      warnRGB: base.warnRGB,
      dangerRGB: base.dangerRGB,
      flameRGB: base.flameRGB
    )
  }

  private static func normalizeSkinId(_ raw: String) -> String {
    switch raw {
    case "quietTransformer", "weightLoss":
      return "quiet"
    case "accountabilitySquad", "englishDaily":
      return "squad"
    case "memoryCollectors", "travel":
      return "memory"
    case "coupleRituals":
      return "couple"
    case "aestheticFlexer", "workout30":
      return "flexer"
    case "minimalistHabit", "custom":
      return "minimal"
    default:
      return raw
    }
  }
}

// MARK: - Typography Helpers

public enum OurneyWidgetFont {
  /// Hero streak and display numerals (`BricolageGrotesque` variable font bundled via `Info.plist`).
  public static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
    Font.custom("BricolageGrotesque", size: size).weight(weight)
  }

  /// Vietnamese-complete UI body & title font (`BeVietnamPro-Bold` / `BeVietnamPro-SemiBold`).
  public static func title(_ size: CGFloat) -> Font {
    Font.custom("BeVietnamPro-Bold", size: size)
  }

  public static func body(_ size: CGFloat, bold: Bool = false) -> Font {
    Font.custom(bold ? "BeVietnamPro-Bold" : "BeVietnamPro-SemiBold", size: size)
  }
}

// MARK: - Compatibility & Soft Neo-Brutalist View Components

@available(iOSApplicationExtension 16.0, iOS 16.0, *)
private struct _ModernRenderingModeReader<Content: View>: View {
  @Environment(\.widgetRenderingMode) private var mode
  let content: (Bool) -> Content

  var body: some View {
    content(mode == .fullColor)
  }
}

/// Reports `true` when rendering in `.fullColor` mode, and `false` in Lock Screen `.vibrant`
/// or iOS 18+ Home Screen `.accented` (Tinted) / StandBy Night mode.
public struct OurneyRenderingModeReader<Content: View>: View {
  private let content: (Bool) -> Content

  public init(@ViewBuilder content: @escaping (Bool) -> Content) {
    self.content = content
  }

  public var body: some View {
    if #available(iOSApplicationExtension 16.0, iOS 16.0, *) {
      _ModernRenderingModeReader(content: content)
    } else {
      content(true)
    }
  }
}

public extension View {
  /// Applies `.containerBackground(for: .widget)` on iOS 17+ and `.background(...)` on iOS 15–16.
  @ViewBuilder
  func ourneyWidgetContainerBackground<Background: View>(
    @ViewBuilder _ background: () -> Background
  ) -> some View {
    if #available(iOSApplicationExtension 17.0, iOS 17.0, *) {
      self.containerBackground(for: .widget, content: background)
    } else {
      self.background(background())
    }
  }

  /// Adds content padding on iOS 15–16 where system widget content margins are not automatically applied.
  @ViewBuilder
  func ourneyWidgetPadding(_ insets: EdgeInsets = EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)) -> some View {
    if #available(iOSApplicationExtension 17.0, iOS 17.0, *) {
      self
    } else {
      self.padding(insets)
    }
  }

  /// Marks key accents/numerals as `.widgetAccentable()` on iOS 16+ (for iOS 18/26 Tinted mode & StandBy).
  @ViewBuilder
  func ourneyWidgetAccentable(_ accentable: Bool = true) -> some View {
    if #available(iOSApplicationExtension 16.0, iOS 16.0, *) {
      self.widgetAccentable(accentable)
    } else {
      self
    }
  }

  /// Wraps content in a Soft Neo-Brutalist sticker surface (`1.5–2pt` ink border + zero-blur hard offset shadow).
  func ourneyStickerCard(
    fill: Color,
    outline: Color,
    shadow: Color,
    cornerRadius: CGFloat = 14,
    borderWidth: CGFloat = 2.0,
    shadowOffset: CGFloat = 3.0
  ) -> some View {
    self
      .background(
        ZStack {
          if shadowOffset > 0 {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
              .fill(shadow)
              .offset(x: shadowOffset, y: shadowOffset)
          }
          RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(fill)
        }
      )
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .strokeBorder(outline, lineWidth: borderWidth)
      )
  }
}

public extension Image {
  /// Prevents raster thumbnails from turning into solid opaque tint blocks in iOS 18+ Tinted mode (§1.2).
  @ViewBuilder
  func ourneyWidgetAccentedPhoto() -> some View {
    #if compiler(>=6.0)
    if #available(iOSApplicationExtension 18.0, iOS 18.0, *) {
      self.widgetAccentedRenderingMode(.desaturated)
    } else {
      self
    }
    #else
    self
    #endif
  }
}

/// Memory-safe thumbnail loader using `CGImageSourceCreateThumbnailAtIndex` to stay strictly
/// below WidgetKit's 30 MB Jetsam ceiling (§1.2).
public enum OurneyThumbLoader {
  public static func loadDownsampledImage(relativePath: String?, maxPixelSize: Int = 320) -> UIImage? {
    guard let url = WidgetSnapshotStore.thumbURL(for: relativePath) else {
      return nil
    }
    let sourceOptions: [CFString: Any] = [
      kCGImageSourceShouldCache: false
    ]
    guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions as CFDictionary) else {
      return nil
    }
    let thumbOptions: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceShouldCacheImmediately: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
    ]
    guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions as CFDictionary) else {
      return nil
    }
    return UIImage(cgImage: cgImage)
  }
}

/// Soft Neo-Brutalist avatar disc matching `UiAvatar` (`apps/mobile/lib/ui/components/avatar.dart`).
public struct OurneyAvatarDisc: View {
  public let initial: String
  public let colorIndex: Int
  public let avatarFile: String?
  public let size: CGFloat
  public let checkedInToday: Bool
  public let theme: OurneyWidgetTheme

  public init(
    initial: String,
    colorIndex: Int,
    avatarFile: String? = nil,
    size: CGFloat = 30,
    checkedInToday: Bool = false,
    theme: OurneyWidgetTheme
  ) {
    self.initial = initial
    self.colorIndex = colorIndex
    self.avatarFile = avatarFile
    self.size = size
    self.checkedInToday = checkedInToday
    self.theme = theme
  }

  public var body: some View {
    let pair = OurneyWidgetTheme.avatarDisc(for: colorIndex)
    ZStack(alignment: .bottomTrailing) {
      Group {
        if let uiImage = OurneyThumbLoader.loadDownsampledImage(relativePath: avatarFile, maxPixelSize: 120) {
          Image(uiImage: uiImage)
            .resizable()
            .ourneyWidgetAccentedPhoto()
            .scaledToFill()
        } else {
          ZStack {
            Circle().fill(pair.fill)
            Text(String(initial.prefix(1)).uppercased())
              .font(OurneyWidgetFont.title(size * 0.42))
              .foregroundColor(pair.ink)
              .minimumScaleFactor(0.7)
          }
        }
      }
      .frame(width: size, height: size)
      .clipShape(Circle())
      .overlay(
        Circle()
          .strokeBorder(checkedInToday ? theme.outline : theme.surface, lineWidth: 1.75)
      )

      if checkedInToday {
        ZStack {
          Circle()
            .fill(Color(.sRGB, red: 0.063, green: 0.725, blue: 0.506, opacity: 1.0)) // #10B981
          OurneyIconView(name: "check", size: size * 0.34, flat: true, overrideColor: Color.black)
        }
        .frame(width: max(12, size * 0.42), height: max(12, size * 0.42))
        .overlay(
          Circle().strokeBorder(theme.outline, lineWidth: 1.2)
        )
        .offset(x: 2, y: 2)
      }
    }
  }
}

/// 7-day rolling cadence strip (`WeekStrip` in `today_card.dart:231`, §1.1).
public struct OurneyWeekStripView: View {
  public let days: [WidgetWeekDay]
  public let theme: OurneyWidgetTheme
  public let compact: Bool

  public init(days: [WidgetWeekDay], theme: OurneyWidgetTheme, compact: Bool = false) {
    self.days = days
    self.theme = theme
    self.compact = compact
  }

  public var body: some View {
    let displayDays = days.isEmpty ? Self.fallbackDays : Array(days.suffix(7))
    HStack(spacing: compact ? 3 : 4) {
      ForEach(Array(displayDays.enumerated()), id: \.offset) { _, item in
        dayCell(item)
      }
    }
  }

  @ViewBuilder
  private func dayCell(_ item: WidgetWeekDay) -> some View {
    let isDone = item.isDone
    let isToday = item.isToday
    let cellFill: Color = {
      if isDone { return theme.accent }
      if isToday { return theme.surface }
      return theme.fill
    }()
    let labelColor: Color = {
      if isDone { return theme.onAccent }
      if isToday { return theme.ink }
      return theme.inkMuted
    }()

    VStack(spacing: compact ? 1 : 2) {
      Text(item.label)
        .font(OurneyWidgetFont.body(compact ? 8 : 9, bold: isToday || isDone))
        .foregroundColor(isDone ? theme.ink : theme.inkMuted)
        .lineLimit(1)
        .minimumScaleFactor(0.7)

      ZStack {
        RoundedRectangle(cornerRadius: compact ? 5 : 6, style: .continuous)
          .fill(cellFill)
          .frame(height: compact ? 16 : 20)
          .overlay(
            RoundedRectangle(cornerRadius: compact ? 5 : 6, style: .continuous)
              .strokeBorder(
                isDone || isToday ? theme.outline : theme.border,
                lineWidth: isToday ? 1.8 : 1.2
              )
          )

        if isDone {
          OurneyIconView(
            name: "check",
            size: compact ? 10 : 12,
            flat: true,
            overrideColor: labelColor
          )
          .ourneyWidgetAccentable()
        } else {
          Text("\(item.day)")
            .font(OurneyWidgetFont.body(compact ? 8 : 9, bold: isToday))
            .foregroundColor(labelColor)
            .minimumScaleFactor(0.7)
        }
      }
    }
    .frame(maxWidth: .infinity)
  }

  private static let fallbackDays: [WidgetWeekDay] = [
    WidgetWeekDay(date: "1", day: 18, label: "T4", state: "done"),
    WidgetWeekDay(date: "2", day: 19, label: "T5", state: "done"),
    WidgetWeekDay(date: "3", day: 20, label: "T6", state: "done"),
    WidgetWeekDay(date: "4", day: 21, label: "T7", state: "done"),
    WidgetWeekDay(date: "5", day: 22, label: "CN", state: "done"),
    WidgetWeekDay(date: "6", day: 23, label: "T2", state: "done"),
    WidgetWeekDay(date: "7", day: 24, label: "HN", state: "today"),
  ]
}
