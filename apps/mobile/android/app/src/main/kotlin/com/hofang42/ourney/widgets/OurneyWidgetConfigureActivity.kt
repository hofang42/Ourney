package com.hofang42.ourney.widgets

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.text.TextUtils
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.WindowInsets
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.annotation.DrawableRes
import androidx.annotation.Keep
import com.hofang42.ourney.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Lightweight native widget configuration sheet (`android:configure` +
 * `android:widgetFeatures="reconfigurable|configuration_optional"`).
 *
 * Allows users to long-press any placed Ourney widget (`Today`, `Streak`, `Squad`)
 * and pin a specific journey or squad, or select `"Automatic"` (`"Tự động"`).
 *
 * Designed in Ourney's Soft Neo-Brutalist style (`OurneyGlanceTheme` Light/Dark
 * tokens, `2dp` ink borders, `>= 48dp` hit targets, `BricolageGrotesque` &
 * `BeVietnamPro` fonts, and `ic_ourney_sticker_*` vector drawables — zero
 * Material stock icons, zero emojis).
 */
@Keep
class OurneyWidgetConfigureActivity : Activity() {

    private enum class WidgetConfigKind {
        TODAY,
        STREAK,
        SQUAD,
    }

    private data class PickerOption(
        val id: String,
        val title: String,
        val subtitle: String,
        @DrawableRes val iconRes: Int,
        val badgeBgColor: Int,
        val badgeOutlineColor: Int,
    )

    private var appWidgetId: Int = AppWidgetManager.INVALID_APPWIDGET_ID
    private var widgetKind: WidgetConfigKind = WidgetConfigKind.TODAY
    private lateinit var store: WidgetSnapshotStore
    private var saving: Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        // Mandatory Android widget configuration contract: default to RESULT_CANCELED
        // immediately so pressing Back or tapping outside cancels cleanly.
        val cancelResult = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        setResult(RESULT_CANCELED, cancelResult)

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val providerInfo = try {
            AppWidgetManager.getInstance(this).getAppWidgetInfo(appWidgetId)
        } catch (_: Throwable) {
            null
        }
        if (providerInfo?.provider?.packageName != packageName) {
            finish()
            return
        }

        val receiverClassName = providerInfo.provider.className
        widgetKind = when {
            receiverClassName.endsWith("OurneySquadWidgetReceiver") -> WidgetConfigKind.SQUAD
            receiverClassName.endsWith("OurneyStreakWidgetReceiver") -> WidgetConfigKind.STREAK
            else -> WidgetConfigKind.TODAY
        }

        store = WidgetSnapshotStore.fromContext(applicationContext)
        val snapshot = store.readSnapshot()
        val isDark = OurneyGlanceTheme.resolveIsDark(this, snapshot?.themeMode)
        val l10n = OurneyGlanceTheme.localizedContext(this, snapshot?.locale)
        val palette = OurneyGlanceTheme.neutralShellPalette(isDark)
        @Suppress("DEPRECATION")
        window?.navigationBarColor = palette.bg

        val options = buildOptions(snapshot, l10n, palette, isDark)
        val rawSelectedId = store.getWidgetSelection(appWidgetId)
        val activeSelectedId = if (options.any { it.id == rawSelectedId }) {
            rawSelectedId
        } else {
            WidgetSnapshot.AUTO_SELECTION_ID
        }

        setContentView(
            buildSheetView(
                l10n = l10n,
                palette = palette,
                snapshot = snapshot,
                options = options,
                selectedId = activeSelectedId,
            ),
        )
    }

    private fun buildOptions(
        snapshot: WidgetSnapshot?,
        l10n: Context,
        shellPalette: OurneyWidgetPalette,
        isDark: Boolean,
    ): List<PickerOption> {
        val autoSubtitleRes = when (widgetKind) {
            WidgetConfigKind.TODAY -> R.string.widget_config_auto_today_sub
            WidgetConfigKind.STREAK -> R.string.widget_config_auto_streak_sub
            WidgetConfigKind.SQUAD -> R.string.widget_config_auto_squad_sub
        }
        val list = mutableListOf(
            PickerOption(
                id = WidgetSnapshot.AUTO_SELECTION_ID,
                title = l10n.getString(R.string.widget_config_auto_title),
                subtitle = l10n.getString(autoSubtitleRes),
                iconRes = R.drawable.ic_ourney_sticker_sparkle,
                badgeBgColor = shellPalette.fill,
                badgeOutlineColor = shellPalette.outline,
            ),
        )

        if (snapshot == null || snapshot.isSignedOut) {
            return list
        }

        if (widgetKind == WidgetConfigKind.SQUAD) {
            for (squad in snapshot.squads) {
                val skinPalette = OurneyGlanceTheme.skinPalette(
                    squad.skinId,
                    squad.colorVariant,
                    isDark,
                )
                val progress = l10n.getString(
                    R.string.widget_squad_progress,
                    squad.doneCount,
                    squad.memberCount,
                )
                val totalDays = squad.totalDays
                val dayPart = if (totalDays != null && totalDays > 0) {
                    l10n.getString(R.string.widget_day_progress, squad.dayNumber, totalDays)
                } else {
                    l10n.getString(R.string.widget_day_only, squad.dayNumber)
                }
                list.add(
                    PickerOption(
                        id = squad.journeyId,
                        title = squad.title,
                        subtitle = "$progress · $dayPart",
                        iconRes = OurneyGlanceTheme.stickerIconRes(
                            if (squad.isCouple) "type-couple" else squad.typeIcon,
                        ),
                        badgeBgColor = skinPalette.fill,
                        badgeOutlineColor = skinPalette.outline,
                    ),
                )
            }
        } else {
            for (journey in snapshot.journeys) {
                val skinPalette = OurneyGlanceTheme.skinPalette(
                    journey.skinId,
                    journey.colorVariant,
                    isDark,
                )
                val totalDays = journey.totalDays
                val dayPart = if (totalDays != null && totalDays > 0) {
                    l10n.getString(R.string.widget_day_progress, journey.dayNumber, totalDays)
                } else {
                    l10n.getString(R.string.widget_day_only, journey.dayNumber)
                }
                val streakPart = l10n.getString(R.string.widget_streak_days, journey.currentStreak)
                val statusPart = if (journey.checkedInToday) {
                    l10n.getString(R.string.widget_checked_in)
                } else {
                    l10n.getString(R.string.widget_pending_today)
                }
                list.add(
                    PickerOption(
                        id = journey.id,
                        title = journey.title,
                        subtitle = "$dayPart · $streakPart · $statusPart",
                        iconRes = OurneyGlanceTheme.stickerIconRes(journey.typeIcon),
                        badgeBgColor = skinPalette.fill,
                        badgeOutlineColor = skinPalette.outline,
                    ),
                )
            }
        }

        return list
    }

    private fun buildSheetView(
        l10n: Context,
        palette: OurneyWidgetPalette,
        snapshot: WidgetSnapshot?,
        options: List<PickerOption>,
        selectedId: String,
    ): View {
        val root = FrameLayout(this).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            )
            setPadding(0, dp(32f), 0, 0)
            setOnClickListener {
                if (!saving) finish()
            }
        }

        val screenWidthDp = resources.configuration.screenWidthDp
        val maxSheetWidthPx = if (screenWidthDp >= 600) dp(520f) else ViewGroup.LayoutParams.MATCH_PARENT
        val horizontalPadPx = if (screenWidthDp < 360) dp(16f) else dp(20f)
        val topSheetPadPx = dp(14f)
        val baseBottomSheetPadPx = dp(24f)

        val sheet = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            isClickable = true
            isFocusable = true
            setPadding(horizontalPadPx, topSheetPadPx, horizontalPadPx, baseBottomSheetPadPx)
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                setColor(palette.bg)
                val topR = dp(24f).toFloat()
                cornerRadii = floatArrayOf(topR, topR, topR, topR, 0f, 0f, 0f, 0f)
                setStroke(dp(2f), palette.outline)
            }
        }

        root.setOnApplyWindowInsetsListener { v, insets ->
            val (topInset, bottomInset) = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val sysInsets = insets.getInsets(
                    WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout(),
                )
                sysInsets.top to sysInsets.bottom
            } else {
                @Suppress("DEPRECATION")
                insets.systemWindowInsetTop to insets.systemWindowInsetBottom
            }
            v.setPadding(0, topInset + dp(32f), 0, 0)
            sheet.setPadding(
                horizontalPadPx,
                topSheetPadPx,
                horizontalPadPx,
                baseBottomSheetPadPx + bottomInset,
            )
            insets
        }
        root.addOnAttachStateChangeListener(
            object : View.OnAttachStateChangeListener {
                override fun onViewAttachedToWindow(v: View) {
                    v.requestApplyInsets()
                }

                override fun onViewDetachedFromWindow(v: View) = Unit
            },
        )

        // Top drag handle bar
        val handle = View(this).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(99f).toFloat()
                setColor(palette.inkMuted)
                alpha = 90
            }
        }
        sheet.addView(
            handle,
            LinearLayout.LayoutParams(dp(38f), dp(4f)).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = dp(12f)
            },
        )

        // Header row: Display title + 48x48dp close button
        val headerRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        val titleRes = when (widgetKind) {
            WidgetConfigKind.TODAY -> R.string.widget_config_today_title
            WidgetConfigKind.STREAK -> R.string.widget_config_streak_title
            WidgetConfigKind.SQUAD -> R.string.widget_config_squad_title
        }
        val titleView = TextView(this).apply {
            text = l10n.getString(titleRes)
            typeface = OurneyWidgetCanvas.getDisplayTypeface(this@OurneyWidgetConfigureActivity)
            setTextColor(palette.ink)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            includeFontPadding = true
            setLineSpacing(0f, 1.3f)
            maxLines = 1
            ellipsize = TextUtils.TruncateAt.END
        }
        headerRow.addView(
            titleView,
            LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f),
        )

        val closeBtn = FrameLayout(this).apply {
            contentDescription = l10n.getString(R.string.widget_config_close)
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(12f).toFloat()
                setColor(palette.fill)
                setStroke(dp(1.5f), palette.outline)
            }
            setOnClickListener {
                if (!saving) finish()
            }
            val closeIcon = ImageView(this@OurneyWidgetConfigureActivity).apply {
                setImageResource(R.drawable.ic_ourney_sticker_close)
                importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
            }
            addView(
                closeIcon,
                FrameLayout.LayoutParams(dp(20f), dp(20f), Gravity.CENTER),
            )
        }
        headerRow.addView(
            closeBtn,
            LinearLayout.LayoutParams(dp(48f), dp(48f)).apply {
                marginStart = dp(8f)
            },
        )
        sheet.addView(
            headerRow,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ),
        )

        val subtitleView = TextView(this).apply {
            text = l10n.getString(R.string.widget_config_subtitle)
            typeface = OurneyWidgetCanvas.getBodySemiBoldTypeface(this@OurneyWidgetConfigureActivity)
            setTextColor(palette.inkMuted)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            includeFontPadding = true
            setLineSpacing(0f, 1.35f)
        }
        sheet.addView(
            subtitleView,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply {
                topMargin = dp(4f)
                bottomMargin = dp(14f)
            },
        )

        // Scrollable options container
        val scrollView = ScrollView(this).apply {
            isVerticalScrollBarEnabled = false
        }
        val listContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }

        options.forEachIndexed { index, option ->
            val isSelected = option.id == selectedId
            val row = buildOptionCard(option, isSelected, palette)
            listContainer.addView(
                row,
                LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                ).apply {
                    if (index > 0) topMargin = dp(10f)
                },
            )
        }

        // Contextual helper banner if snapshot is missing, signed out, or has no matching items
        buildHelperBannerIfNeeded(snapshot, l10n, palette)?.let { banner ->
            listContainer.addView(
                banner,
                LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                ).apply {
                    topMargin = dp(14f)
                },
            )
        }

        scrollView.addView(
            listContainer,
            ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ),
        )
        sheet.addView(
            scrollView,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ),
        )

        root.addView(
            sheet,
            FrameLayout.LayoutParams(
                maxSheetWidthPx,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL,
            ),
        )
        return root
    }

    private fun buildOptionCard(
        option: PickerOption,
        isSelected: Boolean,
        palette: OurneyWidgetPalette,
    ): View {
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            minimumHeight = dp(64f)
            setPadding(dp(14f), dp(12f), dp(14f), dp(12f))
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(16f).toFloat()
                setColor(if (isSelected) palette.surface else palette.fill)
                setStroke(
                    dp(if (isSelected) 2.5f else 1.5f),
                    if (isSelected) palette.accent else palette.outline,
                )
            }
            contentDescription = "${option.title}. ${option.subtitle}"
            setOnClickListener { commitSelection(option.id) }
        }

        val iconBadge = FrameLayout(this).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(10f).toFloat()
                setColor(option.badgeBgColor)
                setStroke(dp(1.5f), option.badgeOutlineColor)
            }
            val iconView = ImageView(this@OurneyWidgetConfigureActivity).apply {
                setImageResource(option.iconRes)
                importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
            }
            addView(
                iconView,
                FrameLayout.LayoutParams(dp(22f), dp(22f), Gravity.CENTER),
            )
        }
        card.addView(
            iconBadge,
            LinearLayout.LayoutParams(dp(40f), dp(40f)).apply {
                marginEnd = dp(12f)
            },
        )

        val textCol = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }
        val titleText = TextView(this).apply {
            text = option.title
            typeface = OurneyWidgetCanvas.getBodyBoldTypeface(this@OurneyWidgetConfigureActivity)
            setTextColor(palette.ink)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            includeFontPadding = true
            setLineSpacing(0f, 1.35f)
            maxLines = 1
            ellipsize = TextUtils.TruncateAt.END
        }
        val subText = TextView(this).apply {
            text = option.subtitle
            typeface = OurneyWidgetCanvas.getBodySemiBoldTypeface(this@OurneyWidgetConfigureActivity)
            setTextColor(palette.inkMuted)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            includeFontPadding = true
            setLineSpacing(0f, 1.35f)
            maxLines = 2
            ellipsize = TextUtils.TruncateAt.END
        }
        textCol.addView(titleText)
        textCol.addView(subText)
        card.addView(
            textCol,
            LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                marginEnd = dp(10f)
            },
        )

        val radioView = ImageView(this).apply {
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
            if (isSelected) {
                setImageResource(R.drawable.ic_ourney_sticker_check_circle)
            } else {
                background = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(palette.surface)
                    setStroke(dp(2f), palette.inkMuted)
                }
            }
        }
        card.addView(
            radioView,
            LinearLayout.LayoutParams(dp(24f), dp(24f)),
        )

        return card
    }

    private fun buildHelperBannerIfNeeded(
        snapshot: WidgetSnapshot?,
        l10n: Context,
        palette: OurneyWidgetPalette,
    ): View? {
        val bannerSpec: Triple<String, String, Intent>? = when {
            snapshot == null -> Triple(
                l10n.getString(R.string.widget_unsynced_title),
                l10n.getString(R.string.widget_unsynced_subtitle),
                WidgetActions.syncWidgetsIntent(this),
            )
            snapshot.isSignedOut -> Triple(
                l10n.getString(R.string.widget_signed_out_title),
                l10n.getString(R.string.widget_signed_out_subtitle),
                WidgetActions.syncWidgetsIntent(this),
            )
            widgetKind == WidgetConfigKind.SQUAD && snapshot.squads.isEmpty() && snapshot.journeys.isNotEmpty() -> Triple(
                l10n.getString(R.string.widget_squad_empty_title),
                l10n.resources.getQuantityString(
                    R.plurals.widget_squad_solo_only_subtitle,
                    snapshot.journeys.size,
                    snapshot.journeys.size,
                ),
                WidgetActions.groupsHubIntent(this),
            )
            snapshot.journeys.isEmpty() -> Triple(
                l10n.getString(R.string.widget_empty_title),
                l10n.getString(R.string.widget_empty_subtitle),
                WidgetActions.createJourneyIntent(this),
            )
            else -> null
        }

        val (bannerTitle, bannerSub, actionIntent) = bannerSpec ?: return null
        val ctaLabel = when {
            snapshot == null -> l10n.getString(R.string.widget_config_open_app_sync)
            snapshot.isSignedOut -> l10n.getString(R.string.widget_signed_out_cta)
            widgetKind == WidgetConfigKind.SQUAD -> l10n.getString(R.string.widget_squad_empty_cta)
            else -> l10n.getString(R.string.widget_empty_cta_create)
        }

        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(14f), dp(12f), dp(14f), dp(12f))
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(16f).toFloat()
                setColor(palette.surface)
                setStroke(dp(1.5f), palette.outline)
            }

            addView(
                TextView(this@OurneyWidgetConfigureActivity).apply {
                    text = bannerTitle
                    typeface = OurneyWidgetCanvas.getBodyBoldTypeface(this@OurneyWidgetConfigureActivity)
                    setTextColor(palette.ink)
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                    includeFontPadding = true
                    setLineSpacing(0f, 1.35f)
                },
            )

            addView(
                TextView(this@OurneyWidgetConfigureActivity).apply {
                    text = bannerSub
                    typeface = OurneyWidgetCanvas.getBodySemiBoldTypeface(this@OurneyWidgetConfigureActivity)
                    setTextColor(palette.inkMuted)
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                    includeFontPadding = true
                    setLineSpacing(0f, 1.35f)
                },
                LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                ).apply {
                    topMargin = dp(2f)
                    bottomMargin = dp(10f)
                },
            )

            val ctaButton = TextView(this@OurneyWidgetConfigureActivity).apply {
                text = ctaLabel
                gravity = Gravity.CENTER
                minimumHeight = dp(48f)
                typeface = OurneyWidgetCanvas.getBodyBoldTypeface(this@OurneyWidgetConfigureActivity)
                setTextColor(0xFF1A1A1A.toInt())
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                setPadding(dp(16f), dp(10f), dp(16f), dp(10f))
                background = GradientDrawable().apply {
                    shape = GradientDrawable.RECTANGLE
                    cornerRadius = dp(99f).toFloat()
                    setColor(palette.brand)
                    setStroke(dp(2f), 0xFF1A1A1A.toInt())
                }
                setOnClickListener {
                    commitSelection(WidgetSnapshot.AUTO_SELECTION_ID, launchAfterCommit = actionIntent)
                }
            }
            addView(
                ctaButton,
                LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    dp(48f),
                ),
            )
        }
    }

    private fun commitSelection(
        chosenId: String,
        launchAfterCommit: Intent? = null,
    ) {
        if (saving) return
        saving = true
        val appCtx = applicationContext
        val id = appWidgetId
        val kindName = when (widgetKind) {
            WidgetConfigKind.TODAY -> "today"
            WidgetConfigKind.STREAK -> "streak"
            WidgetConfigKind.SQUAD -> "squad"
        }

        CoroutineScope(Dispatchers.Default).launch {
            WidgetActions.applyWidgetSelection(
                context = appCtx,
                appWidgetId = id,
                selectedId = chosenId,
                store = store,
                widgetKind = kindName,
            )
            runOnUiThread {
                val resultValue = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
                setResult(RESULT_OK, resultValue)
                if (launchAfterCommit != null) {
                    try {
                        startActivity(launchAfterCommit)
                    } catch (_: Throwable) {
                    }
                }
                finish()
            }
        }
    }

    private fun dp(value: Float): Int =
        TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value,
            resources.displayMetrics,
        ).toInt()
}
