package com.hofang42.ourney.widgets

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Native Android handler for `MethodChannel("ourney/widgets")` (§4.4).
 *
 * All disk I/O and thumbnail downsampling/blurring execute on a single background
 * thread so the Flutter UI thread never drops frames during check-in or sync.
 */
class OurneyWidgetBridge(context: Context) : MethodChannel.MethodCallHandler {

    private val appContext: Context = context.applicationContext
    private val store: WidgetSnapshotStore = WidgetSnapshotStore.fromContext(appContext)
    private val ioExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "syncSnapshot" -> handleSyncSnapshot(call, result)
            "syncLiveActivity" -> handleSyncLiveActivity(call, result)
            "clearAll" -> handleClearAll(result)
            "consumeWidgetState" -> handleConsumeWidgetState(result)
            "getCapabilities" -> handleGetCapabilities(result)
            else -> result.notImplemented()
        }
    }

    private fun handleSyncSnapshot(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        val snapshotJson = args?.get("snapshotJson") as? String
        if (snapshotJson.isNullOrBlank()) {
            result.success(false)
            return
        }
        val rawThumbs = args["thumbs"] as? List<*>
        val thumbSpecs = rawThumbs
            ?.mapNotNull { (it as? Map<*, *>)?.let(ThumbSpec::fromMap) }
            .orEmpty()

        ioExecutor.execute {
            val writeResult = store.writeSnapshotAtomically(snapshotJson)
            val snapshot = writeResult.snapshot
            if (writeResult.success && snapshot != null) {
                val thumbsChanged = store.syncThumbs(thumbSpecs, snapshot.referencedThumbPaths())
                val nowMs = System.currentTimeMillis()
                val evaluated = snapshot.evaluateAt(nowMs)
                CheckInWindowReceiver.scheduleNextRollover(appContext, evaluated, nowMs)
                CheckInLiveUpdateManager.syncFromStore(appContext, nowMs)
                if (writeResult.changed || thumbsChanged) {
                    WidgetActions.refreshAllWidgetsAsync(appContext)
                }
            }
            mainHandler.post {
                result.success(writeResult.success)
            }
        }
    }

    private fun handleSyncLiveActivity(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        ioExecutor.execute {
            val ok = try {
                CheckInLiveUpdateManager.syncFromBridge(appContext, args)
            } catch (_: Exception) {
                false
            }
            mainHandler.post {
                result.success(ok)
            }
        }
    }

    private fun handleClearAll(result: MethodChannel.Result) {
        ioExecutor.execute {
            val ok = store.clearAll()
            CheckInLiveUpdateManager.cancel(appContext)
            CheckInWindowReceiver.cancelScheduledRollovers(appContext)
            WidgetActions.refreshAllWidgetsAsync(appContext)
            mainHandler.post {
                result.success(ok)
            }
        }
    }

    private fun handleConsumeWidgetState(result: MethodChannel.Result) {
        ioExecutor.execute {
            val stateMap = store.readState().toMap()
            mainHandler.post {
                result.success(stateMap)
            }
        }
    }

    private fun handleGetCapabilities(result: MethodChannel.Result) {
        val capabilities = mapOf(
            "widgets" to true,
            "liveActivity" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O),
            "promotedLiveUpdates" to CheckInLiveUpdateManager.canPostPromotedLiveUpdates(appContext),
            "appGroup" to true,
        )
        result.success(capabilities)
    }

    companion object {
        const val CHANNEL_NAME = "ourney/widgets"
    }
}
