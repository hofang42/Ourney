package com.hofang42.ourney.widgets

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.runBlocking
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
            "getPlacedWidgets" -> handleGetPlacedWidgets(result)
            "setWidgetSelection" -> handleSetWidgetSelection(call, result)
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
            WidgetActions.refreshAllWidgetsAsync(appContext, clearSelections = true)
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

    private fun handleGetPlacedWidgets(result: MethodChannel.Result) {
        ioExecutor.execute {
            val placed = queryPlacedWidgets()
            mainHandler.post {
                result.success(placed)
            }
        }
    }

    private fun handleSetWidgetSelection(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        val appWidgetId = (args?.get("appWidgetId") as? Number)?.toInt()
            ?: AppWidgetManager.INVALID_APPWIDGET_ID
        val selectedId = args?.get("selectedId") as? String
        if (appWidgetId <= 0) {
            result.success(false)
            return
        }
        ioExecutor.execute {
            val ok = try {
                runBlocking {
                    WidgetActions.applyWidgetSelection(
                        context = appContext,
                        appWidgetId = appWidgetId,
                        selectedId = selectedId,
                        store = store,
                    )
                }
            } catch (_: Throwable) {
                false
            }
            mainHandler.post {
                result.success(ok)
            }
        }
    }

    private fun queryPlacedWidgets(): List<Map<String, Any>> {
        val manager = try {
            AppWidgetManager.getInstance(appContext)
        } catch (_: Throwable) {
            return emptyList()
        }
        val receivers = listOf(
            OurneyTodayWidgetReceiver::class.java to "today",
            OurneyStreakWidgetReceiver::class.java to "streak",
            OurneySquadWidgetReceiver::class.java to "squad",
        )
        val state = store.readState()
        val entries = mutableListOf<Pair<Int, Map<String, Any>>>()
        for ((receiverClass, kind) in receivers) {
            val ids = try {
                manager.getAppWidgetIds(ComponentName(appContext, receiverClass))
            } catch (_: Throwable) {
                IntArray(0)
            }
            for (id in ids) {
                if (id <= 0) continue
                val info = try {
                    manager.getAppWidgetInfo(id)
                } catch (_: Throwable) {
                    null
                }
                if (info == null) continue
                entries.add(
                    id to mapOf(
                        "appWidgetId" to id,
                        "kind" to kind,
                        "selectedId" to state.selectionFor(id),
                    ),
                )
            }
        }
        return entries.sortedBy { it.first }.map { it.second }
    }

    companion object {
        const val CHANNEL_NAME = "ourney/widgets"
    }
}
