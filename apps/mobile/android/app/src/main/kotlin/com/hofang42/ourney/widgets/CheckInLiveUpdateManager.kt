package com.hofang42.ourney.widgets

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.hofang42.ourney.R

/**
 * Manages the Check-In Window Live Update notification (`id = 42000`, silent
 * channel `checkin_window_live` — disjoint from `ReminderScheduler`'s
 * `41000..41063` on `checkin_reminders`).
 *
 * - **Android 16 (`API 36`+)**: Posts a `Notification.ProgressStyle` notification
 *   with per-journey segments, `setOngoing(true)`, `setRequestPromotedOngoing(true)`,
 *   and `setShortCriticalText(...)` (`<= 7` chars) for status-bar chip & lock-screen
 *   Live Update promotion.
 * - **Android 8.0–15 (`API 26–35`)**: Posts a silent ongoing countdown chronometer
 *   notification (`setUsesChronometer(true)`, `setChronometerCountDown(true)`).
 * - **Privacy (`§7.1`)**: Uses `VISIBILITY_PRIVATE` + redacted `publicVersion` when
 *   `redactLockScreenTitles` is enabled. Never displays photos or weight/metrics.
 */
object CheckInLiveUpdateManager {

    const val NOTIFICATION_ID = 42000
    const val CHANNEL_ID = "checkin_window_live"
    const val EXTRA_REQUEST_PROMOTED_ONGOING = "android.requestPromotedOngoing"
    const val EXTRA_SHORT_CRITICAL_TEXT = "android.shortCriticalText"

    fun canPostPromotedLiveUpdates(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < 36) return false
        return Api36Impl.canPostPromoted(context)
    }

    fun syncFromBridge(context: Context, args: Map<*, *>?): Boolean {
        if (args == null) {
            cancel(context)
            return true
        }
        val store = WidgetSnapshotStore.fromContext(context)
        val nowMs = System.currentTimeMillis()
        val snapshot = store.readSnapshot(nowMs)
        val state = store.readState()

        if (snapshot != null && (snapshot.isSignedOut || !snapshot.privacy.liveActivityEnabled)) {
            cancel(context)
            return true
        }

        val window = WidgetLiveWindow.fromMap(args)
        if (window.celebrateAndDismiss || window.pendingCount <= 0) {
            // Spec §6.2.3: when pendingTodayCount drops to 0, cancel notification 42000 on Android.
            cancel(context)
            return true
        }

        if (!window.isActiveAt(nowMs, state)) {
            cancel(context)
            return true
        }

        val defaultLocale = if (
            java.util.Locale.getDefault().language.lowercase(java.util.Locale.ROOT).startsWith("vi")
        ) {
            "vi"
        } else {
            "en"
        }
        val locale = (args["locale"] as? String) ?: snapshot?.locale ?: defaultLocale
        val redactLockScreen = resolveRedactLockScreenTitles(args, snapshot, window)

        postOrUpdate(
            context = context,
            window = window,
            locale = locale,
            redactLockScreenTitles = redactLockScreen,
            nowEpochMs = nowMs,
        )
        return true
    }

    /**
     * Resolves the Lock Screen title redaction flag from [args], [window], or
     * [snapshot]:
     * - Sensitive journeys (`isSensitive`, `quiet`, `weightLoss`, `type-weight`)
     *   are always redacted on the Lock Screen regardless of toggle state.
     * - Reads `redactLockScreenTitles` (spec §4.3/§4.4 name) first.
     * - Also accepts `redactTitleOnLockScreen` for backward compatibility (`[P2-1]`).
     * - Falls back to `snapshot.privacy.redactLockScreenTitles` (or `false`).
     */
    internal fun resolveRedactLockScreenTitles(
        args: Map<*, *>?,
        snapshot: WidgetSnapshot?,
        window: WidgetLiveWindow? = null,
    ): Boolean {
        if (isSensitiveLiveWindow(args, snapshot, window)) return true
        if (args != null) {
            (args["redactLockScreenTitles"] as? Boolean)?.let { return it }
            (args["redactTitleOnLockScreen"] as? Boolean)?.let { return it }
            val privacyMap = args["privacy"] as? Map<*, *>
            (privacyMap?.get("redactLockScreenTitles") as? Boolean)?.let { return it }
            (privacyMap?.get("redactTitleOnLockScreen") as? Boolean)?.let { return it }
            val nestedWindow = args["liveWindow"] as? Map<*, *>
            (nestedWindow?.get("redactLockScreenTitles") as? Boolean)?.let { return it }
            (nestedWindow?.get("redactTitleOnLockScreen") as? Boolean)?.let { return it }
        }
        window?.redactLockScreenTitles?.let { return it }
        return snapshot?.privacy?.redactLockScreenTitles ?: false
    }

    private fun isSensitiveLiveWindow(
        args: Map<*, *>?,
        snapshot: WidgetSnapshot?,
        window: WidgetLiveWindow?,
    ): Boolean {
        if (window?.isSensitive == true) return true
        val nestedWindow = args?.get("liveWindow") as? Map<*, *>
        if ((nestedWindow?.get("isSensitive") as? Boolean) == true) return true
        if ((args?.get("isSensitive") as? Boolean) == true) return true
        val skinId = window?.skinId
            ?: (nestedWindow?.get("skinId") as? String)
            ?: (args?.get("skinId") as? String)
        val typeIcon = window?.typeIcon
            ?: (nestedWindow?.get("typeIcon") as? String)
            ?: (args?.get("typeIcon") as? String)
        if (skinId == "quiet" || skinId == "quietTransformer" || skinId == "weightLoss" || typeIcon == "type-weight") {
            return true
        }
        val journeyId = window?.journeyId
            ?: (nestedWindow?.get("journeyId") as? String)
            ?: (args?.get("journeyId") as? String)
        val matched = journeyId?.let { id -> snapshot?.journeys?.firstOrNull { it.id == id } }
        if (matched != null && (matched.isSensitive || matched.skinId == "quiet" || matched.typeIcon == "type-weight")) {
            return true
        }
        return false
    }

    fun syncFromStore(context: Context, nowEpochMs: Long = System.currentTimeMillis()) {
        val store = WidgetSnapshotStore.fromContext(context)
        val snapshot = store.readSnapshot(nowEpochMs)
        val state = store.readState()

        if (snapshot == null || snapshot.isSignedOut || !snapshot.privacy.liveActivityEnabled) {
            cancel(context)
            return
        }

        val window = snapshot.liveWindow
        if (window == null || window.pendingCount <= 0 || !window.isActiveAt(nowEpochMs, state)) {
            cancel(context)
            return
        }

        postOrUpdate(
            context = context,
            window = window,
            locale = snapshot.locale,
            redactLockScreenTitles = resolveRedactLockScreenTitles(null, snapshot, window),
            nowEpochMs = nowEpochMs,
        )
    }

    fun cancel(context: Context) {
        try {
            val nm = context.getSystemService(NotificationManager::class.java)
            nm?.cancel(NOTIFICATION_ID)
        } catch (_: Exception) {
        }
    }

    private fun postOrUpdate(
        context: Context,
        window: WidgetLiveWindow,
        locale: String,
        redactLockScreenTitles: Boolean,
        nowEpochMs: Long,
    ) {
        if (!hasPostNotificationPermission(context)) return
        val nm = context.getSystemService(NotificationManager::class.java) ?: return
        val l10n = OurneyGlanceTheme.localizedContext(context, locale)
        ensureSilentChannel(nm, l10n)

        val deadlineMs = WidgetSnapshot.parseIsoEpochMs(window.deadlineUtc) ?: return
        val timeoutAfterMs = (deadlineMs - nowEpochMs).coerceAtLeast(1_000L)
        val remainingMinutes = ((deadlineMs - nowEpochMs).coerceAtLeast(60_000L) / 60_000L).coerceAtLeast(1L)
        val rawChipText = if (remainingMinutes >= 60L) {
            l10n.getString(R.string.widget_live_chip_hours)
        } else {
            l10n.getString(R.string.widget_live_chip_mins)
        }
        val shortChipText = rawChipText.take(7)

        val title = if (window.atRisk && window.currentStreak > 0) {
            l10n.getString(R.string.widget_live_title_at_risk, window.currentStreak, window.journeyTitle)
        } else {
            l10n.getString(R.string.widget_live_title_window, window.journeyTitle)
        }
        val total = window.totalActiveCount.coerceAtLeast(1)
        val done = window.completedCount.coerceIn(0, total)
        val body = l10n.getString(R.string.widget_live_body_progress, done, total)
        val snapLabel = l10n.getString(R.string.widget_snap_cta)
        val dismissLabel = l10n.getString(R.string.widget_live_dismiss)

        val notification = if (Build.VERSION.SDK_INT >= 36) {
            Api36Impl.buildPromotedProgressNotification(
                context = context,
                l10n = l10n,
                window = window,
                title = title,
                body = body,
                shortChipText = shortChipText,
                snapLabel = snapLabel,
                dismissLabel = dismissLabel,
                deadlineMs = deadlineMs,
                remainingMs = timeoutAfterMs,
                redactLockScreenTitles = redactLockScreenTitles,
            )
        } else {
            buildCompatChronometerNotification(
                context = context,
                l10n = l10n,
                window = window,
                title = title,
                body = body,
                snapLabel = snapLabel,
                dismissLabel = dismissLabel,
                deadlineMs = deadlineMs,
                remainingMs = timeoutAfterMs,
                redactLockScreenTitles = redactLockScreenTitles,
            )
        }

        try {
            nm.notify(NOTIFICATION_ID, notification)
        } catch (_: SecurityException) {
        }
    }

    private fun buildCompatChronometerNotification(
        context: Context,
        l10n: Context,
        window: WidgetLiveWindow,
        title: String,
        body: String,
        snapLabel: String,
        dismissLabel: String,
        deadlineMs: Long,
        remainingMs: Long,
        redactLockScreenTitles: Boolean,
    ): Notification {
        val total = window.totalActiveCount.coerceAtLeast(1)
        val done = window.completedCount.coerceIn(0, total)
        val capturePi = WidgetActions.capturePendingIntent(context, window.journeyId)
        val dismissPi = CheckInWindowReceiver.dismissPendingIntent(context, window.windowKey)

        val publicNotification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_ourney_mono_flame)
            .setContentTitle(l10n.getString(R.string.widget_live_public_title))
            .setContentText(l10n.getString(R.string.widget_live_public_body))
            .setOngoing(true)
            .setSilent(true)
            .setOnlyAlertOnce(true)
            .setUsesChronometer(true)
            .setChronometerCountDown(true)
            .setWhen(deadlineMs)
            .setShowWhen(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()

        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_ourney_mono_flame)
            .setContentTitle(title)
            .setContentText(body)
            .setOngoing(true)
            .setSilent(true)
            .setOnlyAlertOnce(true)
            .setUsesChronometer(true)
            .setChronometerCountDown(true)
            .setWhen(deadlineMs)
            .setShowWhen(true)
            .setTimeoutAfter(remainingMs)
            .setProgress(total, done, false)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setVisibility(
                if (redactLockScreenTitles) {
                    NotificationCompat.VISIBILITY_PRIVATE
                } else {
                    NotificationCompat.VISIBILITY_PUBLIC
                },
            )
            .setPublicVersion(publicNotification)
            .setContentIntent(capturePi)
            .addAction(
                NotificationCompat.Action.Builder(
                    R.drawable.ic_ourney_mono_camera,
                    snapLabel,
                    capturePi,
                ).build(),
            )
            .addAction(
                NotificationCompat.Action.Builder(
                    R.drawable.ic_ourney_mono_close,
                    dismissLabel,
                    dismissPi,
                ).build(),
            )
            .build()
    }

    private fun ensureSilentChannel(nm: NotificationManager, l10n: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val existing = nm.getNotificationChannel(CHANNEL_ID)
        val name = l10n.getString(R.string.widget_live_channel_name)
        val desc = l10n.getString(R.string.widget_live_channel_desc)
        if (existing != null) {
            if (existing.name != name || existing.description != desc) {
                existing.name = name
                existing.description = desc
                nm.createNotificationChannel(existing)
            }
            return
        }
        val channel = NotificationChannel(
            CHANNEL_ID,
            name,
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = desc
            setSound(null, null)
            enableVibration(false)
            enableLights(false)
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PRIVATE
        }
        nm.createNotificationChannel(channel)
    }

    private fun hasPostNotificationPermission(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED
    }

    @RequiresApi(36)
    private object Api36Impl {
        fun canPostPromoted(context: Context): Boolean {
            return try {
                val nm = context.getSystemService(NotificationManager::class.java)
                nm?.canPostPromotedNotifications() == true
            } catch (_: Throwable) {
                false
            }
        }

        fun buildPromotedProgressNotification(
            context: Context,
            l10n: Context,
            window: WidgetLiveWindow,
            title: String,
            body: String,
            shortChipText: String,
            snapLabel: String,
            dismissLabel: String,
            deadlineMs: Long,
            remainingMs: Long,
            redactLockScreenTitles: Boolean,
        ): Notification {
            val total = window.totalActiveCount.coerceAtLeast(1)
            val done = window.completedCount.coerceIn(0, total)
            val pending = (total - done).coerceAtLeast(0)
            val totalSegmentLength = total * 1000
            val progressValue = (done * 1000).coerceIn(120, totalSegmentLength)

            val segments = buildList {
                repeat(done) {
                    add(
                        Notification.ProgressStyle.Segment(1000)
                            .setColor(0xFFFF8A3D.toInt()),
                    )
                }
                repeat(pending.coerceAtLeast(if (done == 0) 1 else 0)) {
                    add(
                        Notification.ProgressStyle.Segment(1000)
                            .setColor(0xFF79756D.toInt()),
                    )
                }
            }

            val progressStyle = Notification.ProgressStyle()
                .setProgress(progressValue)
                .setProgressTrackerIcon(
                    Icon.createWithResource(context, R.drawable.ic_ourney_mono_flame),
                )
                .setProgressSegments(segments)

            val capturePi = WidgetActions.capturePendingIntent(context, window.journeyId)
            val dismissPi = CheckInWindowReceiver.dismissPendingIntent(context, window.windowKey)

            val publicVersion = Notification.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_ourney_mono_flame)
                .setContentTitle(l10n.getString(R.string.widget_live_public_title))
                .setContentText(l10n.getString(R.string.widget_live_public_body))
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setUsesChronometer(true)
                .setChronometerCountDown(true)
                .setWhen(deadlineMs)
                .setShowWhen(true)
                .setVisibility(Notification.VISIBILITY_PUBLIC)
                .build()

            val snapAction = Notification.Action.Builder(
                Icon.createWithResource(context, R.drawable.ic_ourney_mono_camera),
                snapLabel,
                capturePi,
            ).build()

            val dismissAction = Notification.Action.Builder(
                Icon.createWithResource(context, R.drawable.ic_ourney_mono_close),
                dismissLabel,
                dismissPi,
            ).build()

            val promotedExtras = Bundle().apply {
                putBoolean(EXTRA_REQUEST_PROMOTED_ONGOING, true)
                putString(EXTRA_SHORT_CRITICAL_TEXT, shortChipText)
            }

            // Qualification rules on Android 16:
            // - ongoing = true, EXTRA_REQUEST_PROMOTED_ONGOING = true, ProgressStyle, contentTitle set
            // - shortCriticalText <= 7 chars
            // - NO RemoteViews, NO setColorized(true), NO group summary
            return Notification.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_ourney_mono_flame)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(progressStyle)
                .setOngoing(true)
                .addExtras(promotedExtras)
                .setShortCriticalText(shortChipText)
                .setOnlyAlertOnce(true)
                .setUsesChronometer(true)
                .setChronometerCountDown(true)
                .setWhen(deadlineMs)
                .setShowWhen(true)
                .setTimeoutAfter(remainingMs)
                .setCategory(Notification.CATEGORY_PROGRESS)
                .setVisibility(
                    if (redactLockScreenTitles) {
                        Notification.VISIBILITY_PRIVATE
                    } else {
                        Notification.VISIBILITY_PUBLIC
                    },
                )
                .setPublicVersion(publicVersion)
                .setContentIntent(capturePi)
                .addAction(snapAction)
                .addAction(dismissAction)
                .build()
        }
    }
}
