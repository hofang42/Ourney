package com.hofang42.ourney.widgets

import android.content.Context
import android.content.res.Configuration
import androidx.annotation.DrawableRes
import androidx.compose.ui.graphics.Color
import androidx.glance.unit.ColorProvider
import com.hofang42.ourney.R
import java.util.Locale

/**
 * Exact Kotlin port of `apps/mobile/lib/ui/tokens.dart` (`OurneyUi.light`,
 * `OurneyUi.dark`), `apps/mobile/lib/ui/skins.dart` (`uiSkins` 6×3 adaptive
 * persona palettes), and `apps/mobile/lib/ui/components/avatar.dart`
 * (`uiAvatarColors`).
 */
data class OurneyWidgetPalette(
    val isDark: Boolean,
    val skinId: String,
    val bg: Int,
    val surface: Int,
    val fill: Int,
    val ink: Int,
    val inkMuted: Int,
    val outline: Int,
    val hardShadow: Int,
    val accent: Int,
    val onAccent: Int,
    val button: Int,
    val buttonLabel: Int,
    val secondary: Int,
    val brand: Int,
    val flame: Int,
    val warn: Int,
    val success: Int,
    val successSoft: Int,
    val borderWidthDp: Float,
) {
    val bgProvider: ColorProvider get() = ColorProvider(Color(bg))
    val surfaceProvider: ColorProvider get() = ColorProvider(Color(surface))
    val fillProvider: ColorProvider get() = ColorProvider(Color(fill))
    val inkProvider: ColorProvider get() = ColorProvider(Color(ink))
    val inkMutedProvider: ColorProvider get() = ColorProvider(Color(inkMuted))
    val outlineProvider: ColorProvider get() = ColorProvider(Color(outline))
    val accentProvider: ColorProvider get() = ColorProvider(Color(accent))
    val onAccentProvider: ColorProvider get() = ColorProvider(Color(onAccent))
    val buttonProvider: ColorProvider get() = ColorProvider(Color(button))
    val buttonLabelProvider: ColorProvider get() = ColorProvider(Color(buttonLabel))
    val flameProvider: ColorProvider get() = ColorProvider(Color(flame))
    val warnProvider: ColorProvider get() = ColorProvider(Color(warn))
    val successProvider: ColorProvider get() = ColorProvider(Color(success))
    val successSoftProvider: ColorProvider get() = ColorProvider(Color(successSoft))

    @DrawableRes
    fun cardBackgroundRes(urgent: Boolean = false): Int = when {
        urgent && isDark -> R.drawable.bg_widget_card_urgent_dark
        urgent && !isDark -> R.drawable.bg_widget_card_urgent_light
        isDark -> R.drawable.bg_widget_card_dark
        else -> R.drawable.bg_widget_card_light
    }

    @DrawableRes
    fun surfaceBackgroundRes(): Int =
        if (isDark) R.drawable.bg_widget_surface_dark else R.drawable.bg_widget_surface_light
}

object OurneyGlanceTheme {

    /** `uiAvatarColors` from `apps/mobile/lib/ui/components/avatar.dart:10`. */
    val avatarColors = intArrayOf(
        0xFFE15B72.toInt(),
        0xFF6D4BF0.toInt(),
        0xFF2AA7E0.toInt(),
        0xFF10B981.toInt(),
        0xFFFF9F1C.toInt(),
    )

    fun avatarDiscColor(index: Int): Int =
        avatarColors[index.mod(avatarColors.size)]

    fun avatarInkColor(discColor: Int): Int {
        val dark = 0xFF1A1A1A.toInt()
        val white = 0xFFFFFFFF.toInt()
        return if (contrastRatio(discColor, white) >= contrastRatio(discColor, dark)) white else dark
    }

    fun resolveIsDark(context: Context, themeMode: String?): Boolean = when (themeMode) {
        "light" -> false
        "dark" -> true
        else -> {
            val nightMask = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
            nightMask == Configuration.UI_MODE_NIGHT_YES
        }
    }

    /**
     * Resolves a localized Android [Context] honoring `snapshot.locale` (`"vi"`
     * default or `"en"`) so switching language inside Ourney Settings updates
     * every widget and Live Update immediately.
     */
    fun localizedContext(context: Context, localeCode: String?): Context {
        val normalized = when (localeCode?.trim()?.lowercase(Locale.ROOT)) {
            "en" -> "en"
            else -> "vi"
        }
        return try {
            val locale = Locale.forLanguageTag(normalized)
            val config = Configuration(context.resources.configuration)
            config.setLocale(locale)
            context.createConfigurationContext(config)
        } catch (_: Exception) {
            context
        }
    }

    /**
     * Maps the 17 Ourney icon names (`ourney_icons.dart`) to two-tone Neo-Brutalist
     * sticker `VectorDrawable` resources. Zero Material icons, zero emojis.
     */
    @DrawableRes
    fun stickerIconRes(iconName: String?): Int = when (iconName) {
        "flame", "react-fire" -> R.drawable.ic_ourney_sticker_flame
        "camera" -> R.drawable.ic_ourney_sticker_camera
        "check" -> R.drawable.ic_ourney_sticker_check
        "check-circle" -> R.drawable.ic_ourney_sticker_check_circle
        "clock", "timer" -> R.drawable.ic_ourney_sticker_clock
        "journeys" -> R.drawable.ic_ourney_sticker_journeys
        "squad" -> R.drawable.ic_ourney_sticker_squad
        "chevron-right" -> R.drawable.ic_ourney_sticker_chevron_right
        "close" -> R.drawable.ic_ourney_sticker_close
        "lock" -> R.drawable.ic_ourney_sticker_lock
        "sparkle" -> R.drawable.ic_ourney_sticker_sparkle
        "type-weight", "scales", "weight" -> R.drawable.ic_ourney_sticker_type_weight
        "type-study", "book", "study" -> R.drawable.ic_ourney_sticker_type_study
        "type-trip", "trip" -> R.drawable.ic_ourney_sticker_type_trip
        "type-couple", "couple", "heart" -> R.drawable.ic_ourney_sticker_type_couple
        "type-workout", "fitness", "workout" -> R.drawable.ic_ourney_sticker_type_workout
        "type-custom", "custom" -> R.drawable.ic_ourney_sticker_type_custom
        else -> R.drawable.ic_ourney_sticker_sparkle
    }

    /**
     * Maps the 17 Ourney icon names to monochrome `24dp` `VectorDrawable` resources
     * for Android notification `smallIcon`, Android 16 `ProgressStyle` tracker icons,
     * and tinted flat glyphs.
     */
    @DrawableRes
    fun monoIconRes(iconName: String?): Int = when (iconName) {
        "flame", "react-fire" -> R.drawable.ic_ourney_mono_flame
        "camera" -> R.drawable.ic_ourney_mono_camera
        "check" -> R.drawable.ic_ourney_mono_check
        "check-circle" -> R.drawable.ic_ourney_mono_check_circle
        "clock", "timer" -> R.drawable.ic_ourney_mono_clock
        "journeys" -> R.drawable.ic_ourney_mono_journeys
        "squad" -> R.drawable.ic_ourney_mono_squad
        "chevron-right" -> R.drawable.ic_ourney_mono_chevron_right
        "close" -> R.drawable.ic_ourney_mono_close
        "lock" -> R.drawable.ic_ourney_mono_lock
        "sparkle" -> R.drawable.ic_ourney_mono_sparkle
        "type-weight", "scales", "weight" -> R.drawable.ic_ourney_mono_type_weight
        "type-study", "book", "study" -> R.drawable.ic_ourney_mono_type_study
        "type-trip", "trip" -> R.drawable.ic_ourney_mono_type_trip
        "type-couple", "couple", "heart" -> R.drawable.ic_ourney_mono_type_couple
        "type-workout", "fitness", "workout" -> R.drawable.ic_ourney_mono_type_workout
        "type-custom", "custom" -> R.drawable.ic_ourney_mono_type_custom
        else -> R.drawable.ic_ourney_mono_sparkle
    }

    /**
     * Neutral V2 shell palette (`OurneyUi.light` / `OurneyUi.dark` in `tokens.dart`).
     */
    fun neutralShellPalette(isDark: Boolean): OurneyWidgetPalette = if (!isDark) {
        OurneyWidgetPalette(
            isDark = false,
            skinId = "shell",
            bg = 0xFFFFF8EE.toInt(),
            surface = 0xFFFFFFFF.toInt(),
            fill = 0xFFF6EEDF.toInt(),
            ink = 0xFF1A1A1A.toInt(),
            inkMuted = 0xFF5A544C.toInt(),
            outline = 0xFF1A1A1A.toInt(),
            hardShadow = 0xFF1A1A1A.toInt(),
            accent = 0xFFFF8A3D.toInt(),
            onAccent = 0xFF1A1A1A.toInt(),
            button = 0xFFFF8A3D.toInt(),
            buttonLabel = 0xFF1A1A1A.toInt(),
            secondary = 0xFF1A1A1A.toInt(),
            brand = 0xFFFF8A3D.toInt(),
            flame = 0xFFD97706.toInt(),
            warn = 0xFFB33A0A.toInt(),
            success = 0xFF287747.toInt(),
            successSoft = 0xFFDCFCE7.toInt(),
            borderWidthDp = 2.0f,
        )
    } else {
        OurneyWidgetPalette(
            isDark = true,
            skinId = "shell",
            bg = 0xFF1B1916.toInt(),
            surface = 0xFF25221E.toInt(),
            fill = 0xFF2A2722.toInt(),
            ink = 0xFFECE5D8.toInt(),
            inkMuted = 0xFFB3AA9C.toInt(),
            outline = 0xFF79756D.toInt(),
            hardShadow = 0xFF0C0B0A.toInt(),
            accent = 0xFFFF8A3D.toInt(),
            onAccent = 0xFF1A1A1A.toInt(),
            button = 0xFFFF8A3D.toInt(),
            buttonLabel = 0xFF1A1A1A.toInt(),
            secondary = 0xFFECE5D8.toInt(),
            brand = 0xFFFF8A3D.toInt(),
            flame = 0xFFF2A93B.toInt(),
            warn = 0xFFF2A070.toInt(),
            success = 0xFF6FCF8E.toInt(),
            successSoft = 0xFF1F3B2A.toInt(),
            borderWidthDp = 2.0f,
        )
    }

    /**
     * Resolves any of the 6×3 V2 `UiSkin` definitions (`quiet`, `squad`, `memory`,
     * `couple`, `flexer`, `minimal`) in Light or Dark mode, matching `UiSkin.apply`
     * in `apps/mobile/lib/ui/skins.dart:127-167`.
     */
    fun skinPalette(
        skinId: String?,
        colorVariant: Int = 0,
        isDark: Boolean = false,
    ): OurneyWidgetPalette {
        val skin = skins[skinId] ?: skins["minimal"]!!
        val base = if (isDark) skin.dark else skin.light
        val clampedIndex = colorVariant.coerceIn(0, skin.variants.lastIndex)
        val rawVariant = skin.variants[clampedIndex]

        // V2 special override: minimal variant 1 in dark mode uses a light button (#E4E4E7).
        val resolvedAccent = if (isDark && rawVariant.accentDark != null) {
            rawVariant.accentDark
        } else {
            rawVariant.accent
        }
        val resolvedButton: Int
        val resolvedButtonLabel: Int
        if (skin.id == "minimal" && clampedIndex == 1 && isDark) {
            resolvedButton = 0xFFE4E4E7.toInt()
            resolvedButtonLabel = 0xFF18181A.toInt()
        } else {
            resolvedButton = rawVariant.button
            resolvedButtonLabel = rawVariant.buttonLabel
        }

        val outline = if (isDark) lerpArgb(base.ink, base.bg, 0.55f) else base.ink
        val hardShadow = if (isDark) lerpArgb(base.bg, 0xFF000000.toInt(), 0.55f) else base.ink
        val fill = alphaBlend(base.ink, base.bg, 0.06f)

        return OurneyWidgetPalette(
            isDark = isDark,
            skinId = skin.id,
            bg = base.bg,
            surface = base.surface,
            fill = fill,
            ink = base.ink,
            inkMuted = base.muted,
            outline = outline,
            hardShadow = hardShadow,
            accent = resolvedAccent,
            onAccent = onAccentFor(resolvedAccent),
            button = resolvedButton,
            buttonLabel = resolvedButtonLabel,
            secondary = rawVariant.secondary,
            brand = 0xFFFF8A3D.toInt(),
            flame = if (isDark) 0xFFF2A93B.toInt() else 0xFFD97706.toInt(),
            warn = if (isDark) 0xFFF2A070.toInt() else 0xFFB33A0A.toInt(),
            success = if (isDark) 0xFF6FCF8E.toInt() else 0xFF287747.toInt(),
            successSoft = if (isDark) 0xFF1F3B2A.toInt() else 0xFFDCFCE7.toInt(),
            borderWidthDp = skin.borderWidthDp,
        )
    }

    private data class SkinNeutral(
        val bg: Int,
        val surface: Int,
        val ink: Int,
        val muted: Int,
    )

    private data class SkinVariantDef(
        val accent: Int,
        val accentDark: Int? = null,
        val button: Int,
        val buttonLabel: Int,
        val secondary: Int,
    )

    private data class SkinDef(
        val id: String,
        val borderWidthDp: Float,
        val light: SkinNeutral,
        val dark: SkinNeutral,
        val variants: List<SkinVariantDef>,
    )

    private val skins: Map<String, SkinDef> = mapOf(
        "quiet" to SkinDef(
            id = "quiet",
            borderWidthDp = 1.5f,
            light = SkinNeutral(
                bg = 0xFFEFF3F0.toInt(),
                surface = 0xFFFFFFFF.toInt(),
                ink = 0xFF0F172A.toInt(),
                muted = 0xFF53605B.toInt(),
            ),
            dark = SkinNeutral(
                bg = 0xFF161B1C.toInt(),
                surface = 0xFF1F2628.toInt(),
                ink = 0xFFE6ECEA.toInt(),
                muted = 0xFFA7B2AF.toInt(),
            ),
            variants = listOf(
                SkinVariantDef(
                    accent = 0xFF10B981.toInt(),
                    button = 0xFFFF4D6D.toInt(),
                    buttonLabel = 0xFF0F172A.toInt(),
                    secondary = 0xFFB7E8D1.toInt(),
                ),
                SkinVariantDef(
                    accent = 0xFF6B9E8A.toInt(),
                    button = 0xFFD9694F.toInt(),
                    buttonLabel = 0xFF0F172A.toInt(),
                    secondary = 0xFFCADBD4.toInt(),
                ),
                SkinVariantDef(
                    accent = 0xFF6E9AC0.toInt(),
                    button = 0xFFE8A25C.toInt(),
                    buttonLabel = 0xFF0F172A.toInt(),
                    secondary = 0xFFD4E4F0.toInt(),
                ),
            ),
        ),
        "squad" to SkinDef(
            id = "squad",
            borderWidthDp = 2.0f,
            light = SkinNeutral(
                bg = 0xFFF7F1E5.toInt(),
                surface = 0xFFFFFDF9.toInt(),
                ink = 0xFF1E1B18.toInt(),
                muted = 0xFF665F57.toInt(),
            ),
            dark = SkinNeutral(
                bg = 0xFF191A22.toInt(),
                surface = 0xFF23252F.toInt(),
                ink = 0xFFEEEFF4.toInt(),
                muted = 0xFFB3B6C4.toInt(),
            ),
            variants = listOf(
                SkinVariantDef(
                    accent = 0xFFFF9F1C.toInt(),
                    button = 0xFFFF9F1C.toInt(),
                    buttonLabel = 0xFF1E1B18.toInt(),
                    secondary = 0xFF7556F8.toInt(),
                ),
                SkinVariantDef(
                    accent = 0xFF7556F8.toInt(),
                    accentDark = 0xFF9B87FA.toInt(),
                    button = 0xFFFF9F1C.toInt(),
                    buttonLabel = 0xFF1E1B18.toInt(),
                    secondary = 0xFF7556F8.toInt(),
                ),
                SkinVariantDef(
                    accent = 0xFF4FA36B.toInt(),
                    button = 0xFFE9B949.toInt(),
                    buttonLabel = 0xFF1E1B18.toInt(),
                    secondary = 0xFF7556F8.toInt(),
                ),
            ),
        ),
        "memory" to SkinDef(
            id = "memory",
            borderWidthDp = 2.0f,
            light = SkinNeutral(
                bg = 0xFFF4EFE6.toInt(),
                surface = 0xFFFFFFFF.toInt(),
                ink = 0xFF231F1E.toInt(),
                muted = 0xFF675E59.toInt(),
            ),
            dark = SkinNeutral(
                bg = 0xFF1C1A17.toInt(),
                surface = 0xFF26231F.toInt(),
                ink = 0xFFEEE8DD.toInt(),
                muted = 0xFFB6AC9F.toInt(),
            ),
            variants = listOf(
                SkinVariantDef(
                    accent = 0xFFCC4A2F.toInt(),
                    accentDark = 0xFFE07A5F.toInt(),
                    button = 0xFFCC4A2F.toInt(),
                    buttonLabel = 0xFFFFFFFF.toInt(),
                    secondary = 0xFF4A6B53.toInt(),
                ),
                SkinVariantDef(
                    accent = 0xFF2F6F8F.toInt(),
                    accentDark = 0xFF6FA8C7.toInt(),
                    button = 0xFF2F6F8F.toInt(),
                    buttonLabel = 0xFFFFFFFF.toInt(),
                    secondary = 0xFFD9A441.toInt(),
                ),
                SkinVariantDef(
                    accent = 0xFF7B5EA7.toInt(),
                    accentDark = 0xFFA98BD6.toInt(),
                    button = 0xFF7B5EA7.toInt(),
                    buttonLabel = 0xFFFFFFFF.toInt(),
                    secondary = 0xFFE0A43A.toInt(),
                ),
            ),
        ),
        "couple" to SkinDef(
            id = "couple",
            borderWidthDp = 2.0f,
            light = SkinNeutral(
                bg = 0xFFF9F0EE.toInt(),
                surface = 0xFFFFFFFF.toInt(),
                ink = 0xFF261F22.toInt(),
                muted = 0xFF6D5E64.toInt(),
            ),
            dark = SkinNeutral(
                bg = 0xFF1E181B.toInt(),
                surface = 0xFF2A2126.toInt(),
                ink = 0xFFF3E4EA.toInt(),
                muted = 0xFFC8B3BD.toInt(),
            ),
            variants = listOf(
                SkinVariantDef(
                    accent = 0xFF9D174D.toInt(),
                    accentDark = 0xFFE7739A.toInt(),
                    button = 0xFFE15B72.toInt(),
                    buttonLabel = 0xFF1A1316.toInt(),
                    secondary = 0xFF9D174D.toInt(),
                ),
                SkinVariantDef(
                    accent = 0xFFE15B72.toInt(),
                    button = 0xFF9D174D.toInt(),
                    buttonLabel = 0xFFFFFFFF.toInt(),
                    secondary = 0xFFE15B72.toInt(),
                ),
                SkinVariantDef(
                    accent = 0xFFB4533A.toInt(),
                    accentDark = 0xFFE08A6E.toInt(),
                    button = 0xFFF08A6B.toInt(),
                    buttonLabel = 0xFF1A1316.toInt(),
                    secondary = 0xFFB4533A.toInt(),
                ),
            ),
        ),
        "flexer" to SkinDef(
            id = "flexer",
            borderWidthDp = 2.0f,
            light = SkinNeutral(
                bg = 0xFFF3F4F6.toInt(),
                surface = 0xFFFFFFFF.toInt(),
                ink = 0xFF090A0F.toInt(),
                muted = 0xFF525660.toInt(),
            ),
            dark = SkinNeutral(
                bg = 0xFF14161C.toInt(),
                surface = 0xFF1E2029.toInt(),
                ink = 0xFFEEF0F5.toInt(),
                muted = 0xFFA9AFBD.toInt(),
            ),
            variants = listOf(
                SkinVariantDef(
                    accent = 0xFF3DE88C.toInt(),
                    button = 0xFFFF4D6D.toInt(),
                    buttonLabel = 0xFF090A0F.toInt(),
                    secondary = 0xFF263D34.toInt(),
                ),
                SkinVariantDef(
                    accent = 0xFFFF4D6D.toInt(),
                    button = 0xFF3DE88C.toInt(),
                    buttonLabel = 0xFF090A0F.toInt(),
                    secondary = 0xFF46252E.toInt(),
                ),
                SkinVariantDef(
                    accent = 0xFF7DD3FC.toInt(),
                    button = 0xFFC4B5FD.toInt(),
                    buttonLabel = 0xFF090A0F.toInt(),
                    secondary = 0xFF293848.toInt(),
                ),
            ),
        ),
        "minimal" to SkinDef(
            id = "minimal",
            borderWidthDp = 2.0f,
            light = SkinNeutral(
                bg = 0xFFF5F3EE.toInt(),
                surface = 0xFFFFFFFF.toInt(),
                ink = 0xFF1C1C1E.toInt(),
                muted = 0xFF626166.toInt(),
            ),
            dark = SkinNeutral(
                bg = 0xFF18181A.toInt(),
                surface = 0xFF222225.toInt(),
                ink = 0xFFECECEE.toInt(),
                muted = 0xFFA1A1AA.toInt(),
            ),
            variants = listOf(
                SkinVariantDef(
                    accent = 0xFFEA580C.toInt(),
                    accentDark = 0xFFF07A3A.toInt(),
                    button = 0xFFEA580C.toInt(),
                    buttonLabel = 0xFF1C1C1E.toInt(),
                    secondary = 0xFF27272A.toInt(),
                ),
                SkinVariantDef(
                    accent = 0xFF27272A.toInt(),
                    accentDark = 0xFFD4D4D8.toInt(),
                    button = 0xFF27272A.toInt(),
                    buttonLabel = 0xFFFFFFFF.toInt(),
                    secondary = 0xFF27272A.toInt(),
                ),
                SkinVariantDef(
                    accent = 0xFF0EA5E9.toInt(),
                    button = 0xFF0EA5E9.toInt(),
                    buttonLabel = 0xFF1C1C1E.toInt(),
                    secondary = 0xFF27272A.toInt(),
                ),
            ),
        ),
    )

    fun onAccentFor(accent: Int, preferred: Int = 0xFF1A1A1A.toInt()): Int {
        if (contrastRatio(preferred, accent) >= 4.5) return preferred
        if (contrastRatio(0xFFFFFFFF.toInt(), accent) >= 4.5) return 0xFFFFFFFF.toInt()
        return 0xFF000000.toInt()
    }

    fun contrastRatio(c1: Int, c2: Int): Double {
        val l1 = relativeLuminance(c1)
        val l2 = relativeLuminance(c2)
        val lighter = maxOf(l1, l2)
        val darker = minOf(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private fun relativeLuminance(argb: Int): Double {
        fun channel(v: Int): Double {
            val s = (v and 0xFF) / 255.0
            return if (s <= 0.03928) s / 12.92 else Math.pow((s + 0.055) / 1.055, 2.4)
        }
        val r = channel(argb shr 16)
        val g = channel(argb shr 8)
        val b = channel(argb)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    private fun lerpArgb(a: Int, b: Int, t: Float): Int {
        val clamped = t.coerceIn(0f, 1f)
        val ar = (a shr 16) and 0xFF
        val ag = (a shr 8) and 0xFF
        val ab = a and 0xFF
        val br = (b shr 16) and 0xFF
        val bg = (b shr 8) and 0xFF
        val bb = b and 0xFF
        val rr = (ar + ((br - ar) * clamped)).toInt().coerceIn(0, 255)
        val rg = (ag + ((bg - ag) * clamped)).toInt().coerceIn(0, 255)
        val rb = (ab + ((bb - ab) * clamped)).toInt().coerceIn(0, 255)
        return (0xFF shl 24) or (rr shl 16) or (rg shl 8) or rb
    }

    private fun alphaBlend(over: Int, on: Int, alpha: Float): Int =
        lerpArgb(on, over, alpha)
}
