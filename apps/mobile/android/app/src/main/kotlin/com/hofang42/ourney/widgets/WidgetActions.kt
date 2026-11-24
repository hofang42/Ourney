package com.hofang42.ourney.widgets

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.annotation.Keep
import androidx.glance.GlanceId
import androidx.glance.action.Action
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.updateAll
import com.hofang42.ourney.MainActivity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Deep-link builders and interactive Glance `ActionCallback`s.
 *
 * Security rule (§5.1): every widget/notification deep-link `Intent` and
 * `PendingIntent` targets [MainActivity] explicitly so no third-party app can
 * intercept `ourney://` taps.
 */
object WidgetActions {

    fun captureIntent(context: Context, journeyId: String? = null): Intent {
        val uri = if (!journeyId.isNullOrBlank()) {
            Uri.parse("ourney://capture?journeyId=${Uri.encode(journeyId)}")
        } else {
            Uri.parse("ourney://capture")
        }
        return explicitMainActivityIntent(context, uri)
    }

    fun journeyDetailIntent(context: Context, journeyId: String): Intent {
        val uri = Uri.parse("ourney://journey/${Uri.encode(journeyId)}")
        return explicitMainActivityIntent(context, uri)
    }

    fun journeysHubIntent(context: Context): Intent =
        explicitMainActivityIntent(context, Uri.parse("ourney://journeys"))

    fun groupTodayIntent(context: Context, groupId: String): Intent {
        val uri = Uri.parse("ourney://groups/${Uri.encode(groupId)}")
        return explicitMainActivityIntent(context, uri)
    }

    fun groupsHubIntent(context: Context): Intent =
        explicitMainActivityIntent(context, Uri.parse("ourney://groups"))

    fun captureAction(context: Context, journeyId: String? = null): Action =
        actionStartActivity(captureIntent(context, journeyId))

    fun journeyDetailAction(context: Context, journeyId: String): Action =
        actionStartActivity(journeyDetailIntent(context, journeyId))

    fun journeysHubAction(context: Context): Action =
        actionStartActivity(journeysHubIntent(context))

    fun groupTodayAction(context: Context, groupId: String): Action =
        actionStartActivity(groupTodayIntent(context, groupId))

    fun groupsHubAction(context: Context): Action =
        actionStartActivity(groupsHubIntent(context))

    fun cycleTodayJourneyAction(): Action =
        actionRunCallback<CycleTodayJourneyAction>()

    fun capturePendingIntent(
        context: Context,
        journeyId: String?,
        requestCode: Int = 42010,
    ): PendingIntent = PendingIntent.getActivity(
        context,
        requestCode,
        captureIntent(context, journeyId),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun explicitMainActivityIntent(context: Context, uri: Uri): Intent =
        Intent(Intent.ACTION_VIEW, uri, context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

    suspend fun refreshAllWidgets(context: Context) {
        try {
            TodayGlanceWidget().updateAll(context)
        } catch (_: Exception) {
        }
        try {
            StreakGlanceWidget().updateAll(context)
        } catch (_: Exception) {
        }
        try {
            SquadGlanceWidget().updateAll(context)
        } catch (_: Exception) {
        }
    }

    fun refreshAllWidgetsAsync(context: Context) {
        CoroutineScope(Dispatchers.Default).launch {
            refreshAllWidgets(context)
        }
    }
}

/**
 * Interactive in-place widget callback that cycles through multiple pending
 * journeys on `OurneyTodayWidget` without launching the app.
 */
@Keep
class CycleTodayJourneyAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        WidgetSnapshotStore.fromContext(context).cycleTodayJourney()
        TodayGlanceWidget().update(context, glanceId)
        TodayGlanceWidget().updateAll(context)
    }
}
