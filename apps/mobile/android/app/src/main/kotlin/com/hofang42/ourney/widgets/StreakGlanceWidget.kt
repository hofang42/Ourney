package com.hofang42.ourney.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import androidx.annotation.Keep
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.datastore.preferences.core.Preferences
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.Action
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.semantics.contentDescription
import androidx.glance.semantics.semantics
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.state.PreferencesGlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.hofang42.ourney.R

private class StreakRenderBundle(
    val nowMs: Long,
    val l10n: Context,
    val palette: OurneyWidgetPalette,
    val cardState: JourneyWidgetCardState,
    val heroBitmap: android.graphics.Bitmap?,
    val weekBitmap: android.graphics.Bitmap?,
)

/**
 * `OurneyStreakWidget` — `2×2` (`110×110dp`) Soft Neo-Brutalist Streak Sticker
 * widget with giant `BricolageGrotesque` counter, two-tone `flame` vector, and
 * 7-day rolling consistency chain.
 */
@Keep
class StreakGlanceWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*> = PreferencesGlanceStateDefinition

    override val sizeMode: SizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val store = WidgetSnapshotStore.fromContext(context)
        val appWidgetId = try {
            GlanceAppWidgetManager(context).getAppWidgetId(id)
        } catch (_: Exception) {
            AppWidgetManager.INVALID_APPWIDGET_ID
        }

        provideContent {
            val prefs = currentState<Preferences>()
            val snapshotSeq = prefs[WidgetPrefsKeys.SNAPSHOT_SEQ] ?: 0L
            val prefSelectedId = prefs[WidgetPrefsKeys.SELECTED_ID]

            val bundle = remember(snapshotSeq, prefSelectedId) {
                val nowMs = System.currentTimeMillis()
                val snapshot = store.readSnapshot(nowMs)
                val selectedId = prefSelectedId
                    ?.takeIf { it.isNotBlank() }
                    ?: store.getWidgetSelection(appWidgetId)
                val cardState = WidgetSnapshot.resolveStreakCardState(
                    snapshot = snapshot,
                    selectedId = selectedId,
                )
                val isDark = OurneyGlanceTheme.resolveIsDark(context, snapshot?.themeMode)
                val l10n = OurneyGlanceTheme.localizedContext(context, snapshot?.locale)

                val journey = (cardState as? JourneyWidgetCardState.Ready)?.journey
                val palette = if (journey != null) {
                    OurneyGlanceTheme.skinPalette(journey.skinId, journey.colorVariant, isDark)
                } else {
                    OurneyGlanceTheme.neutralShellPalette(isDark)
                }

                val heroBitmap = journey?.let {
                    OurneyWidgetCanvas.renderStreakHeroBadge(
                        context = context,
                        streakCount = it.currentStreak,
                        palette = palette,
                        atRisk = it.isStreakAlertActive(nowMs),
                        checkedInToday = it.checkedInToday,
                        compact = false,
                    )
                }

                val weekBitmap = journey?.let {
                    OurneyWidgetCanvas.renderWeekStrip(
                        context = context,
                        weekStrip = it.weekStrip,
                        palette = palette,
                        widthDp = 156f,
                        heightDp = 36f,
                    )
                }

                StreakRenderBundle(
                    nowMs = nowMs,
                    l10n = l10n,
                    palette = palette,
                    cardState = cardState,
                    heroBitmap = heroBitmap,
                    weekBitmap = weekBitmap,
                )
            }

            val l10n = bundle.l10n
            val palette = bundle.palette
            when (val state = bundle.cardState) {
                is JourneyWidgetCardState.Unsynced -> {
                    EmptyStreakCard(
                        palette = palette,
                        iconRes = R.drawable.ic_ourney_sticker_sparkle,
                        title = l10n.getString(R.string.widget_unsynced_title),
                        subtitle = l10n.getString(R.string.widget_unsynced_subtitle),
                        clickAction = WidgetActions.syncWidgetsAction(context),
                    )
                }
                is JourneyWidgetCardState.SignedOut -> {
                    EmptyStreakCard(
                        palette = palette,
                        iconRes = R.drawable.ic_ourney_sticker_lock,
                        title = l10n.getString(R.string.widget_signed_out_title),
                        subtitle = l10n.getString(R.string.widget_signed_out_subtitle),
                        clickAction = WidgetActions.syncWidgetsAction(context),
                    )
                }
                is JourneyWidgetCardState.NoJourneys -> {
                    EmptyStreakCard(
                        palette = palette,
                        iconRes = R.drawable.ic_ourney_sticker_flame,
                        title = l10n.getString(R.string.widget_empty_title),
                        subtitle = l10n.getString(R.string.widget_empty_subtitle),
                        clickAction = WidgetActions.createJourneyAction(context),
                    )
                }
                is JourneyWidgetCardState.Ready -> {
                    Box(
                        modifier = GlanceModifier.fillMaxSize(),
                        contentAlignment = Alignment.TopEnd,
                    ) {
                        StreakStickerCard(
                            context = context,
                            l10n = l10n,
                            journey = state.journey,
                            palette = palette,
                            nowMs = bundle.nowMs,
                            heroBitmap = bundle.heroBitmap,
                            weekBitmap = bundle.weekBitmap,
                        )
                        if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                            ConfigureWidgetOverlayButton(
                                context = context,
                                l10n = l10n,
                                palette = palette,
                                appWidgetId = appWidgetId,
                                showLabel = false,
                            )
                        }
                    }
                }
            }
        }
    }

    @Composable
    private fun StreakStickerCard(
        context: Context,
        l10n: Context,
        journey: WidgetJourneyItem,
        palette: OurneyWidgetPalette,
        nowMs: Long,
        heroBitmap: android.graphics.Bitmap?,
        weekBitmap: android.graphics.Bitmap?,
    ) {
        val urgent = journey.isStreakAlertActive(nowMs)
        val tapAction = WidgetActions.captureAction(context, journey.id)
        val statusLabel = when {
            journey.checkedInToday -> l10n.getString(R.string.widget_checked_in_short)
            urgent -> l10n.getString(R.string.widget_streak_at_risk, journey.currentStreak)
            else -> l10n.getString(R.string.widget_snap_cta)
        }
        val a11yDescription =
            "${journey.title}, ${l10n.getString(R.string.widget_streak_days, journey.currentStreak)}, $statusLabel"

        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(ImageProvider(palette.cardBackgroundRes(urgent = urgent)))
                .clickable(tapAction)
                .semantics { contentDescription = a11yDescription }
                .padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Row(
                modifier = GlanceModifier.fillMaxWidth().padding(end = 30.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Image(
                    provider = ImageProvider(OurneyGlanceTheme.stickerIconRes(journey.typeIcon)),
                    contentDescription = null,
                    modifier = GlanceModifier.size(18.dp),
                )
                Spacer(modifier = GlanceModifier.width(5.dp))
                Text(
                    text = journey.title,
                    style = TextStyle(
                        color = palette.inkProvider,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                    maxLines = 1,
                    modifier = GlanceModifier.defaultWeight(),
                )
            }

            Spacer(modifier = GlanceModifier.defaultWeight())

            if (heroBitmap != null) {
                Image(
                    provider = ImageProvider(heroBitmap),
                    contentDescription = null,
                    modifier = GlanceModifier.height(44.dp).width(100.dp),
                    contentScale = ContentScale.Fit,
                )
            }

            Spacer(modifier = GlanceModifier.defaultWeight())

            if (weekBitmap != null) {
                Image(
                    provider = ImageProvider(weekBitmap),
                    contentDescription = null,
                    modifier = GlanceModifier.fillMaxWidth().height(34.dp),
                    contentScale = ContentScale.Fit,
                )
            } else {
                Text(
                    text = statusLabel,
                    style = TextStyle(
                        color = if (urgent) palette.timeCueProvider else palette.inkMutedProvider,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                    maxLines = 1,
                )
            }
        }
    }

    @Composable
    private fun EmptyStreakCard(
        palette: OurneyWidgetPalette,
        iconRes: Int,
        title: String,
        subtitle: String,
        clickAction: Action,
    ) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(ImageProvider(palette.cardBackgroundRes()))
                .clickable(clickAction)
                .semantics { contentDescription = "$title. $subtitle" }
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Image(
                provider = ImageProvider(iconRes),
                contentDescription = null,
                modifier = GlanceModifier.size(26.dp),
            )
            Spacer(modifier = GlanceModifier.height(4.dp))
            Text(
                text = title,
                style = TextStyle(
                    color = palette.inkProvider,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                ),
                maxLines = 2,
            )
            Spacer(modifier = GlanceModifier.height(2.dp))
            Text(
                text = subtitle,
                style = TextStyle(
                    color = palette.inkMutedProvider,
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Medium,
                ),
                maxLines = 2,
            )
        }
    }
}
