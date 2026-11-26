package com.hofang42.ourney.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import androidx.annotation.Keep
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.datastore.preferences.core.Preferences
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalSize
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
import androidx.glance.layout.fillMaxHeight
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

private class TodayRenderBundle(
    val nowMs: Long,
    val l10n: Context,
    val palette: OurneyWidgetPalette,
    val cardState: JourneyWidgetCardState,
    val streakHeroBitmap: android.graphics.Bitmap?,
    val weekStripBitmap: android.graphics.Bitmap?,
    val framedHeroPhoto: android.graphics.Bitmap?,
)

/**
 * `OurneyTodayWidget` — Responsive `2×2` (`110×110dp`), `4×2` (`250×110dp`),
 * and `4×4` (`250×250dp`) Home-Screen widget built with Jetpack Glance 1.2.0.
 */
@Keep
class TodayGlanceWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*> = PreferencesGlanceStateDefinition

    override val sizeMode: SizeMode = SizeMode.Responsive(
        setOf(SMALL_BOX, MEDIUM_BOX, LARGE_BOX),
    )

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
            val prefCycleIndex = prefs[WidgetPrefsKeys.CYCLE_INDEX]
            val size = LocalSize.current

            val bundle = remember(snapshotSeq, prefSelectedId, prefCycleIndex) {
                val nowMs = System.currentTimeMillis()
                val snapshot = store.readSnapshot(nowMs)
                val diskState = store.readState()
                val selectedId = prefSelectedId
                    ?.takeIf { it.isNotBlank() }
                    ?: diskState.selectionFor(appWidgetId)
                val cycleIndex = prefCycleIndex ?: 0
                val cardState = WidgetSnapshot.resolveTodayCardState(
                    snapshot = snapshot,
                    selectedId = selectedId,
                    cycleIndex = cycleIndex,
                )
                val isDark = OurneyGlanceTheme.resolveIsDark(context, snapshot?.themeMode)
                val l10n = OurneyGlanceTheme.localizedContext(context, snapshot?.locale)

                val journey = (cardState as? JourneyWidgetCardState.Ready)?.journey
                val palette = if (journey != null) {
                    OurneyGlanceTheme.skinPalette(journey.skinId, journey.colorVariant, isDark)
                } else {
                    OurneyGlanceTheme.neutralShellPalette(isDark)
                }

                val streakHeroBitmap = journey?.let {
                    OurneyWidgetCanvas.renderStreakHeroBadge(
                        context = context,
                        streakCount = it.currentStreak,
                        palette = palette,
                        atRisk = it.isStreakAlertActive(nowMs),
                        checkedInToday = it.checkedInToday,
                        compact = true,
                    )
                }

                val weekStripBitmap = journey?.let {
                    OurneyWidgetCanvas.renderWeekStrip(
                        context = context,
                        weekStrip = it.weekStrip,
                        palette = palette,
                        widthDp = 220f,
                        heightDp = 42f,
                    )
                }

                val framedHeroPhoto = if (
                    journey != null &&
                    journey.checkedInToday &&
                    snapshot != null &&
                    snapshot.privacy.photoMode != "off" &&
                    !journey.heroThumbFile.isNullOrBlank()
                ) {
                    OurneyWidgetCanvas.renderFramedPhoto(
                        context = context,
                        photoFile = store.resolveThumbFile(journey.heroThumbFile),
                        palette = palette,
                        widthDp = 76f,
                        heightDp = 76f,
                    )
                } else {
                    null
                }

                TodayRenderBundle(
                    nowMs = nowMs,
                    l10n = l10n,
                    palette = palette,
                    cardState = cardState,
                    streakHeroBitmap = streakHeroBitmap,
                    weekStripBitmap = weekStripBitmap,
                    framedHeroPhoto = framedHeroPhoto,
                )
            }

            val l10n = bundle.l10n
            val palette = bundle.palette
            when (val state = bundle.cardState) {
                is JourneyWidgetCardState.Unsynced -> {
                    EmptyOrSignedOutCard(
                        palette = palette,
                        title = l10n.getString(R.string.widget_unsynced_title),
                        subtitle = l10n.getString(R.string.widget_unsynced_subtitle),
                        ctaText = l10n.getString(R.string.widget_unsynced_cta),
                        iconRes = R.drawable.ic_ourney_sticker_sparkle,
                        clickAction = WidgetActions.syncWidgetsAction(context),
                    )
                }
                is JourneyWidgetCardState.SignedOut -> {
                    EmptyOrSignedOutCard(
                        palette = palette,
                        title = l10n.getString(R.string.widget_signed_out_title),
                        subtitle = l10n.getString(R.string.widget_signed_out_subtitle),
                        ctaText = l10n.getString(R.string.widget_signed_out_cta),
                        iconRes = R.drawable.ic_ourney_sticker_lock,
                        clickAction = WidgetActions.syncWidgetsAction(context),
                    )
                }
                is JourneyWidgetCardState.NoJourneys -> {
                    EmptyOrSignedOutCard(
                        palette = palette,
                        title = l10n.getString(R.string.widget_empty_title),
                        subtitle = l10n.getString(R.string.widget_empty_subtitle),
                        ctaText = l10n.getString(R.string.widget_empty_cta_create),
                        iconRes = R.drawable.ic_ourney_sticker_journeys,
                        clickAction = WidgetActions.createJourneyAction(context),
                    )
                }
                is JourneyWidgetCardState.Ready -> {
                    when {
                        size.width < 200.dp -> {
                            SmallTodayCard(
                                context = context,
                                l10n = l10n,
                                journey = state.journey,
                                palette = palette,
                                nowMs = bundle.nowMs,
                                pendingIndex = state.pendingIndex,
                                pendingCount = state.pendingCount,
                                streakBitmap = bundle.streakHeroBitmap,
                            )
                        }
                        size.height < 200.dp -> {
                            MediumTodayCard(
                                context = context,
                                l10n = l10n,
                                journey = state.journey,
                                palette = palette,
                                nowMs = bundle.nowMs,
                                pendingIndex = state.pendingIndex,
                                pendingCount = state.pendingCount,
                                streakBitmap = bundle.streakHeroBitmap,
                                framedPhoto = bundle.framedHeroPhoto,
                            )
                        }
                        else -> {
                            LargeTodayCard(
                                context = context,
                                l10n = l10n,
                                journey = state.journey,
                                palette = palette,
                                nowMs = bundle.nowMs,
                                pendingIndex = state.pendingIndex,
                                pendingCount = state.pendingCount,
                                streakBitmap = bundle.streakHeroBitmap,
                                weekStripBitmap = bundle.weekStripBitmap,
                                framedPhoto = bundle.framedHeroPhoto,
                            )
                        }
                    }
                }
            }
        }
    }

    @Composable
    private fun SmallTodayCard(
        context: Context,
        l10n: Context,
        journey: WidgetJourneyItem,
        palette: OurneyWidgetPalette,
        nowMs: Long,
        pendingIndex: Int,
        pendingCount: Int,
        streakBitmap: android.graphics.Bitmap?,
    ) {
        val urgent = journey.isStreakAlertActive(nowMs)
        val primaryAction = WidgetActions.captureAction(context, journey.id)
        val statusDesc = resolveStatusCopy(l10n, journey, nowMs)
        val a11yDescription =
            "${journey.title}, ${l10n.getString(R.string.widget_streak_days, journey.currentStreak)}, $statusDesc"

        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(ImageProvider(palette.cardBackgroundRes(urgent = urgent)))
                .clickable(primaryAction)
                .semantics { contentDescription = a11yDescription }
                .padding(12.dp),
        ) {
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Image(
                    provider = ImageProvider(OurneyGlanceTheme.stickerIconRes(journey.typeIcon)),
                    contentDescription = null,
                    modifier = GlanceModifier.size(20.dp),
                )
                Spacer(modifier = GlanceModifier.width(6.dp))
                val totalDays = journey.totalDays
                Text(
                    text = if (totalDays != null && totalDays > 0) {
                        l10n.getString(R.string.widget_day_progress, journey.dayNumber, totalDays)
                    } else {
                        l10n.getString(R.string.widget_day_only, journey.dayNumber)
                    },
                    style = TextStyle(
                        color = palette.inkMutedProvider,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                    maxLines = 1,
                    modifier = GlanceModifier.defaultWeight(),
                )
                if (pendingCount >= 2) {
                    Box(
                        modifier = GlanceModifier
                            .size(48.dp)
                            .clickable(WidgetActions.cycleTodayJourneyAction()),
                        contentAlignment = Alignment.CenterEnd,
                    ) {
                        Image(
                            provider = ImageProvider(R.drawable.ic_ourney_sticker_chevron_right),
                            contentDescription = l10n.getString(
                                R.string.widget_cycle_next,
                                pendingIndex,
                                pendingCount,
                            ),
                            modifier = GlanceModifier.size(18.dp),
                        )
                    }
                }
            }

            Text(
                text = journey.title,
                style = TextStyle(
                    color = palette.inkProvider,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                ),
                maxLines = 1,
            )

            Spacer(modifier = GlanceModifier.defaultWeight())

            if (streakBitmap != null) {
                Image(
                    provider = ImageProvider(streakBitmap),
                    contentDescription = null,
                    modifier = GlanceModifier.height(34.dp).width(78.dp),
                    contentScale = ContentScale.Fit,
                )
            }

            Spacer(modifier = GlanceModifier.height(6.dp))

            if (!journey.checkedInToday) {
                SnapCtaPill(
                    context = context,
                    journeyId = journey.id,
                    label = l10n.getString(R.string.widget_snap_short),
                    fullWidth = true,
                )
            } else {
                DoneStatusRow(
                    l10n = l10n,
                    palette = palette,
                    shortLabel = true,
                )
            }
        }
    }

    @Composable
    private fun MediumTodayCard(
        context: Context,
        l10n: Context,
        journey: WidgetJourneyItem,
        palette: OurneyWidgetPalette,
        nowMs: Long,
        pendingIndex: Int,
        pendingCount: Int,
        streakBitmap: android.graphics.Bitmap?,
        framedPhoto: android.graphics.Bitmap?,
    ) {
        val urgent = journey.isStreakAlertActive(nowMs)
        val primaryAction = WidgetActions.captureAction(context, journey.id)
        val statusText = resolveStatusCopy(l10n, journey, nowMs)
        val a11yDescription =
            "${journey.title}, ${l10n.getString(R.string.widget_streak_days, journey.currentStreak)}, $statusText"

        Row(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(ImageProvider(palette.cardBackgroundRes(urgent = urgent)))
                .clickable(primaryAction)
                .semantics { contentDescription = a11yDescription }
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(
                modifier = GlanceModifier.defaultWeight().fillMaxHeight(),
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Image(
                        provider = ImageProvider(OurneyGlanceTheme.stickerIconRes(journey.typeIcon)),
                        contentDescription = null,
                        modifier = GlanceModifier.size(20.dp),
                    )
                    Spacer(modifier = GlanceModifier.width(6.dp))
                    val totalDays = journey.totalDays
                    Text(
                        text = if (totalDays != null && totalDays > 0) {
                            l10n.getString(R.string.widget_day_progress, journey.dayNumber, totalDays)
                        } else {
                            l10n.getString(R.string.widget_day_only, journey.dayNumber)
                        },
                        style = TextStyle(
                            color = palette.inkMutedProvider,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                        ),
                        maxLines = 1,
                    )
                }

                Spacer(modifier = GlanceModifier.height(4.dp))

                Text(
                    text = journey.title,
                    style = TextStyle(
                        color = palette.inkProvider,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                    maxLines = 1,
                )

                Text(
                    text = statusText,
                    style = TextStyle(
                        color = when {
                            urgent -> palette.timeCueProvider
                            journey.checkedInToday -> palette.successProvider
                            else -> palette.inkMutedProvider
                        },
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium,
                    ),
                    maxLines = 1,
                )

                Spacer(modifier = GlanceModifier.defaultWeight())

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    if (streakBitmap != null) {
                        Image(
                            provider = ImageProvider(streakBitmap),
                            contentDescription = null,
                            modifier = GlanceModifier.height(36.dp).width(82.dp),
                            contentScale = ContentScale.Fit,
                        )
                    }
                    if (pendingCount >= 2) {
                        Spacer(modifier = GlanceModifier.width(6.dp))
                        CycleJourneyButton(
                            l10n = l10n,
                            palette = palette,
                            pendingIndex = pendingIndex,
                            pendingCount = pendingCount,
                        )
                    }
                }
            }

            Spacer(modifier = GlanceModifier.width(10.dp))

            if (!journey.checkedInToday) {
                SnapCtaPill(
                    context = context,
                    journeyId = journey.id,
                    label = l10n.getString(R.string.widget_snap_cta),
                    fullWidth = false,
                )
            } else if (framedPhoto != null) {
                Image(
                    provider = ImageProvider(framedPhoto),
                    contentDescription = l10n.getString(R.string.widget_checked_in),
                    modifier = GlanceModifier.size(76.dp),
                    contentScale = ContentScale.Fit,
                )
            } else {
                DoneStatusRow(
                    l10n = l10n,
                    palette = palette,
                    shortLabel = false,
                )
            }
        }
    }

    @Composable
    private fun LargeTodayCard(
        context: Context,
        l10n: Context,
        journey: WidgetJourneyItem,
        palette: OurneyWidgetPalette,
        nowMs: Long,
        pendingIndex: Int,
        pendingCount: Int,
        streakBitmap: android.graphics.Bitmap?,
        weekStripBitmap: android.graphics.Bitmap?,
        framedPhoto: android.graphics.Bitmap?,
    ) {
        val urgent = journey.isStreakAlertActive(nowMs)
        val primaryAction = WidgetActions.captureAction(context, journey.id)
        val statusText = resolveStatusCopy(l10n, journey, nowMs)
        val a11yDescription =
            "${journey.title}, ${l10n.getString(R.string.widget_streak_days, journey.currentStreak)}, $statusText"

        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(ImageProvider(palette.cardBackgroundRes(urgent = urgent)))
                .clickable(primaryAction)
                .semantics { contentDescription = a11yDescription }
                .padding(16.dp),
        ) {
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Image(
                    provider = ImageProvider(OurneyGlanceTheme.stickerIconRes(journey.typeIcon)),
                    contentDescription = null,
                    modifier = GlanceModifier.size(22.dp),
                )
                Spacer(modifier = GlanceModifier.width(8.dp))
                Column(modifier = GlanceModifier.defaultWeight()) {
                    val totalDays = journey.totalDays
                    Text(
                        text = if (totalDays != null && totalDays > 0) {
                            l10n.getString(R.string.widget_day_progress, journey.dayNumber, totalDays)
                        } else {
                            l10n.getString(R.string.widget_day_only, journey.dayNumber)
                        },
                        style = TextStyle(
                            color = palette.inkMutedProvider,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                        ),
                        maxLines = 1,
                    )
                    Text(
                        text = journey.title,
                        style = TextStyle(
                            color = palette.inkProvider,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold,
                        ),
                        maxLines = 1,
                    )
                }
                if (streakBitmap != null) {
                    Image(
                        provider = ImageProvider(streakBitmap),
                        contentDescription = null,
                        modifier = GlanceModifier.height(38.dp).width(84.dp),
                        contentScale = ContentScale.Fit,
                    )
                }
            }

            Spacer(modifier = GlanceModifier.height(8.dp))

            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(modifier = GlanceModifier.defaultWeight()) {
                    Text(
                        text = statusText,
                        style = TextStyle(
                            color = when {
                                urgent -> palette.timeCueProvider
                                journey.checkedInToday -> palette.successProvider
                                else -> palette.inkMutedProvider
                            },
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Bold,
                        ),
                        maxLines = 2,
                    )
                    if (journey.bestStreak > 0) {
                        Spacer(modifier = GlanceModifier.height(2.dp))
                        Text(
                            text = l10n.getString(R.string.widget_best_streak, journey.bestStreak),
                            style = TextStyle(
                                color = palette.inkMutedProvider,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Medium,
                            ),
                            maxLines = 1,
                        )
                    }
                }
                if (framedPhoto != null) {
                    Spacer(modifier = GlanceModifier.width(8.dp))
                    Image(
                        provider = ImageProvider(framedPhoto),
                        contentDescription = l10n.getString(R.string.widget_checked_in),
                        modifier = GlanceModifier.size(72.dp),
                        contentScale = ContentScale.Fit,
                    )
                }
            }

            Spacer(modifier = GlanceModifier.defaultWeight())

            if (weekStripBitmap != null) {
                Image(
                    provider = ImageProvider(weekStripBitmap),
                    contentDescription = null,
                    modifier = GlanceModifier.fillMaxWidth().height(42.dp),
                    contentScale = ContentScale.Fit,
                )
                Spacer(modifier = GlanceModifier.height(10.dp))
            }

            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                if (pendingCount >= 2) {
                    CycleJourneyButton(
                        l10n = l10n,
                        palette = palette,
                        pendingIndex = pendingIndex,
                        pendingCount = pendingCount,
                    )
                    Spacer(modifier = GlanceModifier.width(8.dp))
                }
                Box(modifier = GlanceModifier.defaultWeight()) {
                    if (!journey.checkedInToday) {
                        SnapCtaPill(
                            context = context,
                            journeyId = journey.id,
                            label = l10n.getString(R.string.widget_snap_cta),
                            fullWidth = true,
                        )
                    } else {
                        DoneStatusRow(
                            l10n = l10n,
                            palette = palette,
                            shortLabel = false,
                        )
                    }
                }
            }
        }
    }

    @Composable
    private fun SnapCtaPill(
        context: Context,
        journeyId: String,
        label: String,
        fullWidth: Boolean,
    ) {
        val baseModifier = if (fullWidth) {
            GlanceModifier.fillMaxWidth().height(48.dp)
        } else {
            GlanceModifier.height(48.dp).padding(horizontal = 14.dp)
        }
        val ctaLabelColor = OurneyGlanceTheme.neutralShellPalette(isDark = false).buttonLabelProvider
        Row(
            modifier = baseModifier
                .background(ImageProvider(R.drawable.bg_widget_cta))
                .clickable(WidgetActions.captureAction(context, journeyId))
                .padding(horizontal = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Image(
                provider = ImageProvider(R.drawable.ic_ourney_sticker_camera),
                contentDescription = null,
                modifier = GlanceModifier.size(18.dp),
            )
            Spacer(modifier = GlanceModifier.width(6.dp))
            Text(
                text = label,
                style = TextStyle(
                    color = ctaLabelColor,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                ),
                maxLines = 1,
            )
        }
    }

    @Composable
    private fun CycleJourneyButton(
        l10n: Context,
        palette: OurneyWidgetPalette,
        pendingIndex: Int,
        pendingCount: Int,
    ) {
        val cycleLabel = l10n.getString(R.string.widget_cycle_next, pendingIndex, pendingCount)
        Row(
            modifier = GlanceModifier
                .height(48.dp)
                .background(ImageProvider(palette.surfaceBackgroundRes()))
                .clickable(WidgetActions.cycleTodayJourneyAction())
                .semantics { contentDescription = cycleLabel }
                .padding(horizontal = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = "$pendingIndex/$pendingCount",
                style = TextStyle(
                    color = palette.inkProvider,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                ),
                maxLines = 1,
            )
            Spacer(modifier = GlanceModifier.width(4.dp))
            Image(
                provider = ImageProvider(R.drawable.ic_ourney_sticker_chevron_right),
                contentDescription = null,
                modifier = GlanceModifier.size(16.dp),
            )
        }
    }

    @Composable
    private fun DoneStatusRow(
        l10n: Context,
        palette: OurneyWidgetPalette,
        shortLabel: Boolean,
    ) {
        Row(
            modifier = GlanceModifier
                .height(44.dp)
                .background(ImageProvider(palette.surfaceBackgroundRes()))
                .padding(horizontal = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Image(
                provider = ImageProvider(R.drawable.ic_ourney_sticker_check_circle),
                contentDescription = null,
                modifier = GlanceModifier.size(18.dp),
            )
            Spacer(modifier = GlanceModifier.width(6.dp))
            Text(
                text = if (shortLabel) {
                    l10n.getString(R.string.widget_checked_in_short)
                } else {
                    l10n.getString(R.string.widget_checked_in)
                },
                style = TextStyle(
                    color = palette.successProvider,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                ),
                maxLines = 1,
            )
        }
    }

    @Composable
    private fun EmptyOrSignedOutCard(
        palette: OurneyWidgetPalette,
        title: String,
        subtitle: String,
        ctaText: String,
        iconRes: Int,
        clickAction: Action,
    ) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(ImageProvider(palette.cardBackgroundRes()))
                .clickable(clickAction)
                .semantics { contentDescription = "$title. $subtitle" }
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Image(
                    provider = ImageProvider(iconRes),
                    contentDescription = null,
                    modifier = GlanceModifier.size(22.dp),
                )
                Spacer(modifier = GlanceModifier.width(8.dp))
                Text(
                    text = title,
                    style = TextStyle(
                        color = palette.inkProvider,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                    maxLines = 1,
                )
            }
            Spacer(modifier = GlanceModifier.height(4.dp))
            Text(
                text = subtitle,
                style = TextStyle(
                    color = palette.inkMutedProvider,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium,
                ),
                maxLines = 2,
            )
            Spacer(modifier = GlanceModifier.height(8.dp))
            Row(
                modifier = GlanceModifier
                    .height(48.dp)
                    .background(ImageProvider(R.drawable.bg_widget_cta))
                    .clickable(clickAction)
                    .padding(horizontal = 14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = ctaText,
                    style = TextStyle(
                        color = OurneyGlanceTheme.neutralShellPalette(isDark = false).inkProvider,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                    maxLines = 1,
                )
            }
        }
    }

    private fun resolveStatusCopy(
        l10n: Context,
        journey: WidgetJourneyItem,
        nowMs: Long,
    ): String = when {
        journey.checkedInToday -> l10n.getString(R.string.widget_checked_in)
        journey.isStreakAlertActive(nowMs) ->
            l10n.getString(R.string.widget_streak_at_risk, journey.currentStreak)
        journey.isEveningCueActive(nowMs) ->
            l10n.getString(R.string.widget_evening_nudge)
        else -> l10n.getString(R.string.widget_pending_today)
    }

    companion object {
        val SMALL_BOX = DpSize(110.dp, 110.dp)
        val MEDIUM_BOX = DpSize(250.dp, 110.dp)
        val LARGE_BOX = DpSize(250.dp, 250.dp)
    }
}
