package com.hofang42.ourney.widgets

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.annotation.Keep

/**
 * Handles inexact window/midnight rollover alarms (`setAndAllowWhileIdle` —
 * zero `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` permission), device boot /
 * timezone / locale reconciliation, and the `"Dismiss"` action on the Check-In
 * Window Live Update notification.
 */
@Keep
class CheckInWindowReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        val store = WidgetSnapshotStore.fromContext(context)
        val nowMs = System.currentTimeMillis()

        if (action == ACTION_DISMISS_WINDOW) {
            val windowKey = intent.getStringExtra(EXTRA_WINDOW_KEY)
                ?: store.readSnapshot(nowMs)?.liveWindow?.windowKey
            if (!windowKey.isNullOrBlank()) {
                store.markWindowDismissed(windowKey, nowMs)
            }
            CheckInLiveUpdateManager.cancel(context)
            WidgetActions.refreshAllWidgetsAsync(context)
            return
        }

        if (action in RECONCILE_ACTIONS) {
            val snapshot = store.readSnapshot(nowMs)
            CheckInLiveUpdateManager.syncFromStore(context, nowMs)
            scheduleNextRollover(context, snapshot, nowMs)
            WidgetActions.refreshAllWidgetsAsync(context)
        }
    }

    companion object {
        const val ACTION_WINDOW_ROLLOVER =
            "com.hofang42.ourney.widgets.ACTION_WINDOW_ROLLOVER"
        const val ACTION_DISMISS_WINDOW =
            "com.hofang42.ourney.widgets.ACTION_DISMISS_WINDOW"
        const val EXTRA_WINDOW_KEY = "window_key"

        private const val REQUEST_CODE_ROLLOVER = 42020
        private const val REQUEST_CODE_DISMISS = 42021

        private val RECONCILE_ACTIONS = setOf(
            ACTION_WINDOW_ROLLOVER,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_LOCALE_CHANGED,
        )

        fun dismissPendingIntent(context: Context, windowKey: String): PendingIntent {
            val intent = Intent(context, CheckInWindowReceiver::class.java).apply {
                action = ACTION_DISMISS_WINDOW
                putExtra(EXTRA_WINDOW_KEY, windowKey)
            }
            return PendingIntent.getBroadcast(
                context,
                REQUEST_CODE_DISMISS,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        /**
         * Schedules the next inexact transition alarm (evening cue, 21:00 streak
         * alert, live window start, or midnight rollover) using
         * [AlarmManager.setAndAllowWhileIdle].
         */
        fun scheduleNextRollover(
            context: Context,
            snapshot: WidgetSnapshot?,
            nowEpochMs: Long = System.currentTimeMillis(),
        ) {
            val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
            val pendingIntent = rolloverPendingIntent(context)
            if (snapshot == null || snapshot.isSignedOut) {
                alarmManager.cancel(pendingIntent)
                return
            }
            val nextEpochMs = snapshot.nextRolloverEpochMs(nowEpochMs)
            if (nextEpochMs == null || nextEpochMs <= nowEpochMs) {
                alarmManager.cancel(pendingIntent)
                return
            }
            // Add a 2-second grace offset so the receiver wakes strictly after the boundary.
            val triggerAtMs = nextEpochMs + 2_000L
            try {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMs,
                    pendingIntent,
                )
            } catch (_: Exception) {
            }
        }

        fun cancelScheduledRollovers(context: Context) {
            try {
                val alarmManager = context.getSystemService(AlarmManager::class.java)
                alarmManager?.cancel(rolloverPendingIntent(context))
            } catch (_: Exception) {
            }
        }

        private fun rolloverPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, CheckInWindowReceiver::class.java).apply {
                action = ACTION_WINDOW_ROLLOVER
            }
            return PendingIntent.getBroadcast(
                context,
                REQUEST_CODE_ROLLOVER,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
