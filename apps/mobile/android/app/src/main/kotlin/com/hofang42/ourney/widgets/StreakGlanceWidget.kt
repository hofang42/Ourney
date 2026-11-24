package com.hofang42.ourney.widgets

import android.content.Context
import androidx.annotation.Keep
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
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
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.hofang42.ourney.R

/**
 * `OurneyStreakWidget` — `2×2` (`110×110dp`) Soft Neo-Brutalist Streak Sticker
 * widget with giant `BricolageGrotesque` counter, two-tone `flame` vector, and
 * 7-day rolling consistency chain.
 */
@Keep
class StreakGlanceWidget : GlanceAppWidget() {

    override val sizeMode: SizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val nowMs = System.currentTimeMillis()
        val store = WidgetSnapshotStore.fromContext(context)
        val snapshot = store.readSnapshot(nowMs)
        val isDark = OurneyGlanceTheme.resolveIsDark(context, snapshot?.themeMode)
        val l10n = OurneyGlanceTheme.localizedContext(context, snapshot?.locale)

        val journey = snapshot?.takeIf { !it.isSignedOut }?.selectStreakJourney()
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

        provideContent {
            if (journey == null) {
                EmptyStreakCard(
                    context = context,
                    l10n = l10n,
                    palette = palette,
                    isSignedOut = snapshot?.isSignedOut == true,
                )
            } else {
                StreakStickerCard(
                    context = context,
                    l10n = l10n,
                    journey = journey,
                    palette = palette,
                    nowMs = nowMs,
                    heroBitmap = heroBitmap,
                    weekBitmap = weekBitmap,
                )
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
        val tapAction = if (journey.checkedInToday) {
            WidgetActions.journeyDetailAction(context, journey.id)
        } else {
            WidgetActions.captureAction(context, journey.id)
        }
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
                modifier = GlanceModifier.fillMaxWidth(),
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
                        color = if (urgent) palette.warnProvider else palette.inkMutedProvider,
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
        context: Context,
        l10n: Context,
        palette: OurneyWidgetPalette,
        isSignedOut: Boolean,
    ) {
        val title = if (isSignedOut) {
            l10n.getString(R.string.widget_signed_out_title)
        } else {
            l10n.getString(R.string.widget_empty_title)
        }
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(ImageProvider(palette.cardBackgroundRes()))
                .clickable(WidgetActions.journeysHubAction(context))
                .semantics { contentDescription = title }
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Image(
                provider = ImageProvider(R.drawable.ic_ourney_sticker_flame),
                contentDescription = null,
                modifier = GlanceModifier.size(28.dp),
            )
            Spacer(modifier = GlanceModifier.height(6.dp))
            Text(
                text = title,
                style = TextStyle(
                    color = palette.inkProvider,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                ),
                maxLines = 2,
            )
        }
    }
}
