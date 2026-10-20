import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

/// Layout variants for the 3 core screens of each Journey Persona Skin.
enum TimelineLayoutVariant {
  connectedWeightCurve,
  steppingStoneQuest,
  scrapbookThread,
  duoSplitTimeline,
  athleticTelemetry,
  chainCalendarGrid,
}

enum CameraHudVariant {
  ghostAlignVault,
  studyTimerSnap,
  disposableFilmStamp,
  halfFrameDuo,
  stravaStickerStudio,
  zeroText3Sec,
}

enum ShareCardVariant {
  sideBySideArchive,
  squadPolaroidWall,
  filmContactSheet,
  coupleMosaicPoster,
  transparentStorySticker,
  zenSummaryCard,
}

/// Dynamic ThemeExtension that morphs smoothly (via [lerp]) when switching
/// between Journeys of different [PersonaSkinId] without resetting the app.
@immutable
class OurneyPersonaTheme extends ThemeExtension<OurneyPersonaTheme> {
  const OurneyPersonaTheme({
    required this.skinId,
    required this.timelineVariant,
    required this.cameraVariant,
    required this.shareVariant,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.ink,
    required this.inkMuted,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.border,
    required this.cardRadius,
    required this.borderWidth,
    required this.bottomLipHeight,
  });

  final PersonaSkinId? skinId;
  final TimelineLayoutVariant timelineVariant;
  final CameraHudVariant cameraVariant;
  final ShareCardVariant shareVariant;

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color ink;
  final Color inkMuted;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color border;
  final double cardRadius;
  final double borderWidth;
  final double bottomLipHeight;

  static OurneyPersonaTheme of(BuildContext context) {
    return Theme.of(context).extension<OurneyPersonaTheme>() ??
        editorialNeutralBase(Theme.of(context).brightness);
  }

  /// Default "Ourney Editorial Base" used for the Global Hub when no journey
  /// is selected or before the user picks a template on Create Journey.
  static OurneyPersonaTheme editorialNeutralBase(
    Brightness brightness, {
    Color? ambientAccentOverride,
  }) {
    final isDark = brightness == Brightness.dark;
    final accent = ambientAccentOverride ??
        (isDark ? const Color(0xFFFF6B88) : const Color(0xFFFF4D6D));
    return OurneyPersonaTheme(
      skinId: null,
      timelineVariant: TimelineLayoutVariant.scrapbookThread,
      cameraVariant: CameraHudVariant.zeroText3Sec,
      shareVariant: ShareCardVariant.filmContactSheet,
      background: isDark ? const Color(0xFF0F0F14) : const Color(0xFFF6F2EA),
      surface: isDark ? const Color(0xFF181820) : const Color(0xFFFFFFFF),
      surfaceElevated:
          isDark ? const Color(0xFF22222E) : const Color(0xFFEDE6D8),
      ink: isDark ? const Color(0xFFF5F5FA) : const Color(0xFF1A1A22),
      inkMuted: isDark ? const Color(0xFFA0A0B2) : const Color(0xFF5C5C6B),
      primaryAccent: accent,
      secondaryAccent:
          isDark ? const Color(0xFF9D85FF) : const Color(0xFF7C5CFF),
      border: isDark ? const Color(0x1FF5F5FA) : const Color(0x1A1A1A22),
      cardRadius: 22,
      borderWidth: 1,
      bottomLipHeight: 0,
    );
  }

  /// Resolves the complete Light or Dark theme tokens for any of the 6 Personas.
  static OurneyPersonaTheme forSkin(
    PersonaSkinId skin,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;
    switch (skin) {
      case PersonaSkinId.quietTransformer:
        return OurneyPersonaTheme(
          skinId: skin,
          timelineVariant: TimelineLayoutVariant.connectedWeightCurve,
          cameraVariant: CameraHudVariant.ghostAlignVault,
          shareVariant: ShareCardVariant.sideBySideArchive,
          background:
              isDark ? const Color(0xFF0B0F12) : const Color(0xFFEFF3F0),
          surface: isDark ? const Color(0xFF151C21) : const Color(0xFFFFFFFF),
          surfaceElevated:
              isDark ? const Color(0xFF1E282F) : const Color(0xFFE2EAE5),
          ink: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
          inkMuted: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          primaryAccent: const Color(0xFF10B981),
          secondaryAccent: const Color(0xFFFF4D6D),
          border: isDark ? const Color(0x22F1F5F9) : const Color(0x1A0F172A),
          cardRadius: 22,
          borderWidth: 1,
          bottomLipHeight: 0,
        );

      case PersonaSkinId.accountabilitySquad:
        return OurneyPersonaTheme(
          skinId: skin,
          timelineVariant: TimelineLayoutVariant.steppingStoneQuest,
          cameraVariant: CameraHudVariant.studyTimerSnap,
          shareVariant: ShareCardVariant.squadPolaroidWall,
          background:
              isDark ? const Color(0xFF12131A) : const Color(0xFFF7F1E5),
          surface: isDark ? const Color(0xFF1D1F2B) : const Color(0xFFFFFDF9),
          surfaceElevated:
              isDark ? const Color(0xFF282B3A) : const Color(0xFFEDE3D2),
          ink: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E1B18),
          inkMuted: isDark ? const Color(0xFFA8A8B8) : const Color(0xFF5C554E),
          primaryAccent: const Color(0xFFFF9F1C),
          secondaryAccent: const Color(0xFF7556F8),
          border: isDark ? const Color(0xFF383B4E) : const Color(0xFF2A2521),
          cardRadius: 20,
          borderWidth: 2,
          bottomLipHeight: 3,
        );

      case PersonaSkinId.memoryCollectors:
        return OurneyPersonaTheme(
          skinId: skin,
          timelineVariant: TimelineLayoutVariant.scrapbookThread,
          cameraVariant: CameraHudVariant.disposableFilmStamp,
          shareVariant: ShareCardVariant.filmContactSheet,
          background:
              isDark ? const Color(0xFF141312) : const Color(0xFFF4EFE6),
          surface: isDark ? const Color(0xFF1F1D1B) : const Color(0xFFFFFFFF),
          surfaceElevated:
              isDark ? const Color(0xFF2B2825) : const Color(0xFFE8E0D2),
          ink: isDark ? const Color(0xFFF5F2EB) : const Color(0xFF231F1E),
          inkMuted: isDark ? const Color(0xFFA8A096) : const Color(0xFF6A625A),
          primaryAccent: const Color(0xFFCC4A2F),
          secondaryAccent: const Color(0xFF4A6B53),
          border: isDark ? const Color(0x22F5F2EB) : const Color(0x1F231F1E),
          cardRadius: 14,
          borderWidth: 1,
          bottomLipHeight: 0,
        );

      case PersonaSkinId.coupleRituals:
        return OurneyPersonaTheme(
          skinId: skin,
          timelineVariant: TimelineLayoutVariant.duoSplitTimeline,
          cameraVariant: CameraHudVariant.halfFrameDuo,
          shareVariant: ShareCardVariant.coupleMosaicPoster,
          background:
              isDark ? const Color(0xFF171215) : const Color(0xFFF9F0EE),
          surface: isDark ? const Color(0xFF241C21) : const Color(0xFFFFFFFF),
          surfaceElevated:
              isDark ? const Color(0xFF31262D) : const Color(0xFFF1E2DF),
          ink: isDark ? const Color(0xFFFCE7F3) : const Color(0xFF261F22),
          inkMuted: isDark ? const Color(0xFFC4A8B5) : const Color(0xFF705E66),
          primaryAccent: const Color(0xFFE15B72),
          secondaryAccent: const Color(0xFF9D174D),
          border: isDark ? const Color(0x24FCE7F3) : const Color(0x1A261F22),
          cardRadius: 24,
          borderWidth: 1,
          bottomLipHeight: 0,
        );

      case PersonaSkinId.aestheticFlexer:
        return OurneyPersonaTheme(
          skinId: skin,
          timelineVariant: TimelineLayoutVariant.athleticTelemetry,
          cameraVariant: CameraHudVariant.stravaStickerStudio,
          shareVariant: ShareCardVariant.transparentStorySticker,
          background:
              isDark ? const Color(0xFF090A0F) : const Color(0xFFF3F4F6),
          surface: isDark ? const Color(0xFF14161F) : const Color(0xFFFFFFFF),
          surfaceElevated:
              isDark ? const Color(0xFF1E2230) : const Color(0xFFE5E7EB),
          ink: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF090A0F),
          inkMuted: isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B5563),
          primaryAccent: const Color(0xFFFF4D6D),
          secondaryAccent: const Color(0xFF3DE88C),
          border: isDark ? const Color(0x28F8FAFC) : const Color(0x1A090A0F),
          cardRadius: 20,
          borderWidth: 1,
          bottomLipHeight: 0,
        );

      case PersonaSkinId.minimalistHabit:
        return OurneyPersonaTheme(
          skinId: skin,
          timelineVariant: TimelineLayoutVariant.chainCalendarGrid,
          cameraVariant: CameraHudVariant.zeroText3Sec,
          shareVariant: ShareCardVariant.zenSummaryCard,
          background:
              isDark ? const Color(0xFF0E0E10) : const Color(0xFFF5F3EE),
          surface: isDark ? const Color(0xFF18181B) : const Color(0xFFFFFFFF),
          surfaceElevated:
              isDark ? const Color(0xFF232329) : const Color(0xFFEBE8E0),
          ink: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF1C1C1E),
          inkMuted: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF636366),
          primaryAccent: const Color(0xFFEA580C),
          secondaryAccent: const Color(0xFF27272A),
          border: isDark ? const Color(0x22F4F4F5) : const Color(0x1C1C1C1E),
          cardRadius: 16,
          borderWidth: 1,
          bottomLipHeight: 0,
        );
    }
  }

  /// Builds a complete Flutter [ThemeData] wrapping this [OurneyPersonaTheme].
  ThemeData toThemeData(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryAccent,
        onPrimary: Colors.white,
        secondary: secondaryAccent,
        onSecondary: Colors.white,
        error: const Color(0xFFEF4444),
        onError: Colors.white,
        surface: surface,
        onSurface: ink,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: border, width: borderWidth),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: ink),
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: isDark ? -0.2 : -0.3,
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[this],
    );
  }

  @override
  OurneyPersonaTheme copyWith({
    PersonaSkinId? skinId,
    TimelineLayoutVariant? timelineVariant,
    CameraHudVariant? cameraVariant,
    ShareCardVariant? shareVariant,
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? ink,
    Color? inkMuted,
    Color? primaryAccent,
    Color? secondaryAccent,
    Color? border,
    double? cardRadius,
    double? borderWidth,
    double? bottomLipHeight,
  }) {
    return OurneyPersonaTheme(
      skinId: skinId ?? this.skinId,
      timelineVariant: timelineVariant ?? this.timelineVariant,
      cameraVariant: cameraVariant ?? this.cameraVariant,
      shareVariant: shareVariant ?? this.shareVariant,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      primaryAccent: primaryAccent ?? this.primaryAccent,
      secondaryAccent: secondaryAccent ?? this.secondaryAccent,
      border: border ?? this.border,
      cardRadius: cardRadius ?? this.cardRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      bottomLipHeight: bottomLipHeight ?? this.bottomLipHeight,
    );
  }

  @override
  OurneyPersonaTheme lerp(
    covariant ThemeExtension<OurneyPersonaTheme>? other,
    double t,
  ) {
    if (other is! OurneyPersonaTheme) return this;
    return OurneyPersonaTheme(
      skinId: t < 0.5 ? skinId : other.skinId,
      timelineVariant: t < 0.5 ? timelineVariant : other.timelineVariant,
      cameraVariant: t < 0.5 ? cameraVariant : other.cameraVariant,
      shareVariant: t < 0.5 ? shareVariant : other.shareVariant,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t)!,
      secondaryAccent: Color.lerp(secondaryAccent, other.secondaryAccent, t)!,
      border: Color.lerp(border, other.border, t)!,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t)!,
      bottomLipHeight: lerpDouble(bottomLipHeight, other.bottomLipHeight, t)!,
    );
  }
}
