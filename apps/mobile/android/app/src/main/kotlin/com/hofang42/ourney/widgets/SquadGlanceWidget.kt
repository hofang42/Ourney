package com.hofang42.ourney.widgets

import android.content.Context
import androidx.annotation.Keep
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalSize
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
 * `OurneySquadWidget` — Responsive `4×2` (`250×110dp`) and `4×4` (`250×250dp`)
 * Squad Today & Couple Rituals widget.
 */
@Keep
class SquadGlanceWidget : GlanceAppWidget() {

    override val sizeMode: SizeMode = SizeMode.Responsive(
        setOf(MEDIUM_BOX, LARGE_BOX),
    )

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val nowMs = System.currentTimeMillis()
        val store = WidgetSnapshotStore.fromContext(context)
        val snapshot = store.readSnapshot(nowMs)
        val isDark = OurneyGlanceTheme.resolveIsDark(context, snapshot?.themeMode)
        val l10n = OurneyGlanceTheme.localizedContext(context, snapshot?.locale)

        val squad = snapshot?.takeIf { !it.isSignedOut }?.selectSquad()
        val palette = if (squad != null) {
            OurneyGlanceTheme.skinPalette(squad.skinId, squad.colorVariant, isDark)
        } else {
            OurneyGlanceTheme.neutralShellPalette(isDark)
        }

        val avatarStripBitmap = squad?.let {
            OurneyWidgetCanvas.renderSquadAvatarStrip(
                context = context,
                store = store,
                members = it.members,
                totalMemberCount = it.memberCount,
                palette = palette,
            )
        }

        val photoMode = snapshot?.privacy?.photoMode
        val showMemberPhotos = photoMode == "blurred" || photoMode == "clear"
        val memberPolaroids = if (squad != null && showMemberPhotos) {
            squad.members
                .filter { it.checkedInToday && !it.todayThumbFile.isNullOrBlank() }
                .take(2)
                .mapNotNull { member ->
                    OurneyWidgetCanvas.renderFramedPhoto(
                        context = context,
                        photoFile = store.resolveThumbFile(member.todayThumbFile),
                        palette = palette,
                        widthDp = 64f,
                        heightDp = 64f,
                    )?.let { bmp -> member.displayName to bmp }
                }
        } else {
            emptyList()
        }

        provideContent {
            val size = LocalSize.current
            if (squad == null) {
                EmptySquadCard(
                    context = context,
                    l10n = l10n,
                    palette = palette,
                    isSignedOut = snapshot?.isSignedOut == true,
                )
            } else {
                SquadCardContent(
                    context = context,
                    l10n = l10n,
                    squad = squad,
                    palette = palette,
                    avatarStripBitmap = avatarStripBitmap,
                    memberPolaroids = memberPolaroids,
                    isLarge = size.height >= 200.dp,
                )
            }
        }
    }

    @Composable
    private fun SquadCardContent(
        context: Context,
        l10n: Context,
        squad: WidgetSquadItem,
        palette: OurneyWidgetPalette,
        avatarStripBitmap: android.graphics.Bitmap?,
        memberPolaroids: List<Pair<String, android.graphics.Bitmap>>,
        isLarge: Boolean,
    ) {
        val progressText = l10n.getString(
            R.string.widget_squad_progress,
            squad.doneCount,
            squad.memberCount,
        )
        val a11yDescription = "${squad.title}, $progressText"

        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(ImageProvider(palette.cardBackgroundRes()))
                .clickable(WidgetActions.groupTodayAction(context, squad.journeyId))
                .semantics { contentDescription = a11yDescription }
                .padding(14.dp),
        ) {
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Image(
                    provider = ImageProvider(
                        OurneyGlanceTheme.stickerIconRes(
                            if (squad.isCouple) "type-couple" else squad.typeIcon,
                        ),
                    ),
                    contentDescription = null,
                    modifier = GlanceModifier.size(20.dp),
                )
                Spacer(modifier = GlanceModifier.width(6.dp))
                Text(
                    text = squad.title,
                    style = TextStyle(
                        color = palette.inkProvider,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                    maxLines = 1,
                    modifier = GlanceModifier.defaultWeight(),
                )
                Spacer(modifier = GlanceModifier.width(6.dp))
                val totalDays = squad.totalDays
                Text(
                    text = if (squad.isCouple) {
                        l10n.getString(R.string.widget_squad_couple_badge, squad.dayNumber)
                    } else if (totalDays != null && totalDays > 0) {
                        l10n.getString(
                            R.string.widget_day_progress,
                            squad.dayNumber,
                            totalDays,
                        )
                    } else {
                        l10n.getString(R.string.widget_day_only, squad.dayNumber)
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
                text = progressText,
                style = TextStyle(
                    color = if (squad.doneCount >= squad.memberCount && squad.memberCount > 0) {
                        palette.successProvider
                    } else {
                        palette.inkMutedProvider
                    },
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                ),
                maxLines = 1,
            )

            if (isLarge) {
                Spacer(modifier = GlanceModifier.height(8.dp))
                SquadMembersDetailSection(
                    l10n = l10n,
                    squad = squad,
                    palette = palette,
                    memberPolaroids = memberPolaroids,
                )
            }

            Spacer(modifier = GlanceModifier.defaultWeight())

            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                if (avatarStripBitmap != null) {
                    Image(
                        provider = ImageProvider(avatarStripBitmap),
                        contentDescription = null,
                        modifier = GlanceModifier.height(40.dp).defaultWeight(),
                        contentScale = ContentScale.Fit,
                    )
                } else {
                    Spacer(modifier = GlanceModifier.defaultWeight())
                }

                Spacer(modifier = GlanceModifier.width(8.dp))

                if (!squad.meCheckedInToday) {
                    Row(
                        modifier = GlanceModifier
                            .height(48.dp)
                            .background(ImageProvider(R.drawable.bg_widget_cta))
                            .clickable(WidgetActions.captureAction(context, squad.journeyId))
                            .padding(horizontal = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Image(
                            provider = ImageProvider(R.drawable.ic_ourney_sticker_camera),
                            contentDescription = null,
                            modifier = GlanceModifier.size(18.dp),
                        )
                        Spacer(modifier = GlanceModifier.width(6.dp))
                        Text(
                            text = l10n.getString(R.string.widget_snap_cta),
                            style = TextStyle(
                                color = OurneyGlanceTheme.neutralShellPalette(isDark = false).buttonLabelProvider,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                            ),
                            maxLines = 1,
                        )
                    }
                } else {
                    Row(
                        modifier = GlanceModifier
                            .height(44.dp)
                            .background(ImageProvider(palette.surfaceBackgroundRes()))
                            .padding(horizontal = 10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Image(
                            provider = ImageProvider(R.drawable.ic_ourney_sticker_check_circle),
                            contentDescription = null,
                            modifier = GlanceModifier.size(16.dp),
                        )
                        Spacer(modifier = GlanceModifier.width(5.dp))
                        Text(
                            text = l10n.getString(R.string.widget_squad_me_done),
                            style = TextStyle(
                                color = palette.successProvider,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                            ),
                            maxLines = 1,
                        )
                    }
                }
            }
        }
    }

    @Composable
    private fun SquadMembersDetailSection(
        l10n: Context,
        squad: WidgetSquadItem,
        palette: OurneyWidgetPalette,
        memberPolaroids: List<Pair<String, android.graphics.Bitmap>>,
    ) {
        if (memberPolaroids.isNotEmpty()) {
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                memberPolaroids.forEachIndexed { idx, (name, bmp) ->
                    if (idx > 0) Spacer(modifier = GlanceModifier.width(10.dp))
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Image(
                            provider = ImageProvider(bmp),
                            contentDescription = name,
                            modifier = GlanceModifier.size(64.dp),
                            contentScale = ContentScale.Fit,
                        )
                        Spacer(modifier = GlanceModifier.height(2.dp))
                        Text(
                            text = name,
                            style = TextStyle(
                                color = palette.inkProvider,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                            ),
                            maxLines = 1,
                        )
                    }
                }
            }
        } else {
            Column(modifier = GlanceModifier.fillMaxWidth()) {
                squad.members.take(3).forEach { member ->
                    Row(
                        modifier = GlanceModifier
                            .fillMaxWidth()
                            .padding(vertical = 2.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Image(
                            provider = ImageProvider(
                                if (member.checkedInToday) {
                                    R.drawable.ic_ourney_sticker_check_circle
                                } else {
                                    R.drawable.ic_ourney_sticker_clock
                                },
                            ),
                            contentDescription = null,
                            modifier = GlanceModifier.size(16.dp),
                        )
                        Spacer(modifier = GlanceModifier.width(6.dp))
                        Text(
                            text = member.displayName,
                            style = TextStyle(
                                color = palette.inkProvider,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                            ),
                            maxLines = 1,
                            modifier = GlanceModifier.defaultWeight(),
                        )
                        if (member.streak > 0) {
                            Text(
                                text = l10n.getString(R.string.widget_streak_days, member.streak),
                                style = TextStyle(
                                    color = palette.inkMutedProvider,
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Medium,
                                ),
                                maxLines = 1,
                            )
                        }
                    }
                }
            }
        }
    }

    @Composable
    private fun EmptySquadCard(
        context: Context,
        l10n: Context,
        palette: OurneyWidgetPalette,
        isSignedOut: Boolean,
    ) {
        val title = if (isSignedOut) {
            l10n.getString(R.string.widget_signed_out_title)
        } else {
            l10n.getString(R.string.widget_squad_empty_title)
        }
        val subtitle = if (isSignedOut) {
            l10n.getString(R.string.widget_signed_out_subtitle)
        } else {
            l10n.getString(R.string.widget_squad_empty_subtitle)
        }
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(ImageProvider(palette.cardBackgroundRes()))
                .clickable(WidgetActions.groupsHubAction(context))
                .semantics { contentDescription = "$title. $subtitle" }
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Image(
                    provider = ImageProvider(R.drawable.ic_ourney_sticker_squad),
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
        }
    }

    companion object {
        val MEDIUM_BOX = DpSize(250.dp, 110.dp)
        val LARGE_BOX = DpSize(250.dp, 250.dp)
    }
}
