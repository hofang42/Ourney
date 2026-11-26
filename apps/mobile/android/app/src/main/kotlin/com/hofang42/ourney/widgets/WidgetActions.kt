package com.hofang42.ourney.widgets

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.annotation.Keep
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.glance.GlanceId
import androidx.glance.action.Action
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.appwidget.updateAll
import com.hofang42.ourney.MainActivity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Per-widget `PreferencesGlanceStateDefinition` DataStore keys.
 *
 * Mutating [SNAPSHOT_SEQ] via [updateAppWidgetState] before calling
 * `GlanceAppWidget.update(context, glanceId)` forces Jetpack Glance 1.2.0 to
 * recompose `provideContent { ... }` immediately even when an interactive
 * 45-second `AppWidgetSession` is already running in `SessionWorker`.
 */
object WidgetPrefsKeys {
    val SELECTED_ID = stringPreferencesKey("selected_id")
    val SNAPSHOT_SEQ = longPreferencesKey("snapshot_seq")
    val CYCLE_INDEX = intPreferencesKey("cycle_index")
}

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

    fun journeysHubIntent(context: Context): Intent =
        explicitMainActivityIntent(context, Uri.parse("ourney://journeys"))

    fun syncWidgetsIntent(context: Context): Intent =
        explicitMainActivityIntent(context, Uri.parse("ourney://journeys?syncWidgets=1"))

    fun createJourneyIntent(context: Context): Intent =
        explicitMainActivityIntent(context, Uri.parse("ourney://journeys/new"))

    fun groupsHubIntent(context: Context): Intent =
        explicitMainActivityIntent(context, Uri.parse("ourney://groups"))

    fun captureAction(context: Context, journeyId: String? = null): Action =
        actionStartActivity(captureIntent(context, journeyId))

    fun journeysHubAction(context: Context): Action =
        actionStartActivity(journeysHubIntent(context))

    fun syncWidgetsAction(context: Context): Action =
        actionStartActivity(syncWidgetsIntent(context))

    fun createJourneyAction(context: Context): Action =
        actionStartActivity(createJourneyIntent(context))

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

    fun syncWidgetsPendingIntent(
        context: Context,
        requestCode: Int = 42011,
    ): PendingIntent = PendingIntent.getActivity(
        context,
        requestCode,
        syncWidgetsIntent(context),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun explicitMainActivityIntent(context: Context, uri: Uri): Intent =
        Intent(Intent.ACTION_VIEW, uri, context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

    suspend fun refreshAllWidgets(
        context: Context,
        clearSelections: Boolean = false,
    ) {
        val manager = GlanceAppWidgetManager(context)
        val seq = System.currentTimeMillis()
        refreshWidgetClass(context, manager, TodayGlanceWidget(), seq, clearSelections)
        refreshWidgetClass(context, manager, StreakGlanceWidget(), seq, clearSelections)
        refreshWidgetClass(context, manager, SquadGlanceWidget(), seq, clearSelections)
    }

    private suspend fun <T : GlanceAppWidget> refreshWidgetClass(
        context: Context,
        manager: GlanceAppWidgetManager,
        widget: T,
        seq: Long,
        clearSelections: Boolean,
    ) {
        try {
            val glanceIds = manager.getGlanceIds(widget.javaClass)
            for (glanceId in glanceIds) {
                try {
                    updateAppWidgetState(context, glanceId) { prefs ->
                        if (clearSelections) {
                            prefs.remove(WidgetPrefsKeys.SELECTED_ID)
                            prefs.remove(WidgetPrefsKeys.CYCLE_INDEX)
                        }
                        val prevSeq = prefs[WidgetPrefsKeys.SNAPSHOT_SEQ] ?: 0L
                        prefs[WidgetPrefsKeys.SNAPSHOT_SEQ] = maxOf(seq, prevSeq + 1L)
                    }
                    widget.update(context, glanceId)
                } catch (_: Exception) {
                }
            }
        } catch (_: Exception) {
            try {
                widget.updateAll(context)
            } catch (_: Exception) {
            }
        }
    }

    fun refreshAllWidgetsAsync(
        context: Context,
        clearSelections: Boolean = false,
    ) {
        CoroutineScope(Dispatchers.Default).launch {
            refreshAllWidgets(context, clearSelections = clearSelections)
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
        try {
            updateAppWidgetState(context, glanceId) { prefs ->
                val current = prefs[WidgetPrefsKeys.CYCLE_INDEX] ?: 0
                prefs[WidgetPrefsKeys.CYCLE_INDEX] = current + 1
                val prevSeq = prefs[WidgetPrefsKeys.SNAPSHOT_SEQ] ?: 0L
                prefs[WidgetPrefsKeys.SNAPSHOT_SEQ] =
                    maxOf(System.currentTimeMillis(), prevSeq + 1L)
            }
        } catch (_: Exception) {
        }
        TodayGlanceWidget().update(context, glanceId)
    }
}
