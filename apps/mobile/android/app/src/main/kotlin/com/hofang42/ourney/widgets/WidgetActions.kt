package com.hofang42.ourney.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.annotation.Keep
import androidx.datastore.preferences.core.MutablePreferences
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

    /**
     * Unique per-[appWidgetId] URI string so `Intent.filterEquals` never
     * collides across multiple placed widgets (`§5 Guardrail 1`).
     */
    fun configureWidgetUriString(appWidgetId: Int): String =
        "ourney://widget-config/$appWidgetId"

    /**
     * Explicit configuration `Intent` targeting [OurneyWidgetConfigureActivity]
     * with a unique [Intent.setData] URI per [appWidgetId] (`§5 Guardrail 1`).
     */
    fun configureWidgetIntent(context: Context, appWidgetId: Int): Intent =
        Intent(
            AppWidgetManager.ACTION_APPWIDGET_CONFIGURE,
            Uri.parse(configureWidgetUriString(appWidgetId)),
            context,
            OurneyWidgetConfigureActivity::class.java,
        ).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

    /**
     * Direct `actionStartActivity` action (never `actionRunCallback` trampoline)
     * so Android 14–16 BAL and OEM launchers (HyperOS/MIUI, ColorOS, OriginOS)
     * launch [OurneyWidgetConfigureActivity] with the launcher host's foreground
     * token (`§5 Guardrail 2`).
     */
    fun configureWidgetAction(context: Context, appWidgetId: Int): Action =
        actionStartActivity(configureWidgetIntent(context, appWidgetId))

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

    /**
     * Mutates a Glance [MutablePreferences] instance with [selectedId], a
     * monotonic [WidgetPrefsKeys.SNAPSHOT_SEQ], and resets [WidgetPrefsKeys.CYCLE_INDEX]
     * to `0` (`§5 Guardrail 5`).
     */
    fun applySelectionToGlancePrefs(
        prefs: MutablePreferences,
        selectedId: String?,
        nowEpochMs: Long = System.currentTimeMillis(),
    ) {
        val normalized = selectedId?.trim()?.takeIf { it.isNotEmpty() }
            ?: WidgetSnapshot.AUTO_SELECTION_ID
        if (normalized == WidgetSnapshot.AUTO_SELECTION_ID) {
            prefs.remove(WidgetPrefsKeys.SELECTED_ID)
        } else {
            prefs[WidgetPrefsKeys.SELECTED_ID] = normalized
        }
        val prevSeq = prefs[WidgetPrefsKeys.SNAPSHOT_SEQ] ?: 0L
        prefs[WidgetPrefsKeys.SNAPSHOT_SEQ] = maxOf(nowEpochMs, prevSeq + 1L)
        prefs[WidgetPrefsKeys.CYCLE_INDEX] = 0
    }

    /**
     * Synchronizes both `state.json` ([WidgetSnapshotStore.setWidgetSelection])
     * and an in-memory Glance [MutablePreferences] store in lockstep (`§5 Guardrail 5`).
     */
    fun applyWidgetSelectionToStores(
        store: WidgetSnapshotStore,
        appWidgetId: Int,
        selectedId: String?,
        glancePrefs: MutablePreferences,
        nowEpochMs: Long = System.currentTimeMillis(),
    ): Boolean {
        if (appWidgetId <= 0) return false
        val normalized = selectedId?.trim()?.takeIf { it.isNotEmpty() }
            ?: WidgetSnapshot.AUTO_SELECTION_ID
        store.setWidgetSelection(appWidgetId, normalized)
        applySelectionToGlancePrefs(glancePrefs, normalized, nowEpochMs)
        return true
    }

    /**
     * Updates the selection from [OurneyWidgetConfigureActivity] in both
     * `state.json` and Glance preferences (`§5 Guardrail 5`).
     */
    suspend fun applyWidgetSelection(
        context: Context,
        appWidgetId: Int,
        selectedId: String?,
        store: WidgetSnapshotStore = WidgetSnapshotStore.fromContext(context.applicationContext),
        widgetKind: String? = null,
    ): Boolean {
        if (appWidgetId <= 0) return false
        val appCtx = context.applicationContext
        val normalized = selectedId?.trim()?.takeIf { it.isNotEmpty() }
            ?: WidgetSnapshot.AUTO_SELECTION_ID
        store.setWidgetSelection(appWidgetId, normalized)

        try {
            val manager = GlanceAppWidgetManager(appCtx)
            val glanceId = manager.getGlanceIdBy(appWidgetId)
            updateAppWidgetState(appCtx, glanceId) { prefs ->
                applySelectionToGlancePrefs(prefs, normalized)
            }
            val providerClass = try {
                AppWidgetManager.getInstance(appCtx)
                    .getAppWidgetInfo(appWidgetId)
                    ?.provider
                    ?.className
                    .orEmpty()
            } catch (_: Throwable) {
                ""
            }
            val resolvedKind = when {
                providerClass.endsWith("OurneySquadWidgetReceiver") -> "squad"
                providerClass.endsWith("OurneyStreakWidgetReceiver") -> "streak"
                providerClass.endsWith("OurneyTodayWidgetReceiver") -> "today"
                else -> widgetKind?.lowercase().orEmpty()
            }
            when (resolvedKind) {
                "squad" -> SquadGlanceWidget().update(appCtx, glanceId)
                "streak" -> StreakGlanceWidget().update(appCtx, glanceId)
                "today" -> TodayGlanceWidget().update(appCtx, glanceId)
                else -> refreshAllWidgets(appCtx)
            }
        } catch (_: Throwable) {
            refreshAllWidgets(appCtx)
        }
        return true
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
