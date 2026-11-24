package com.hofang42.ourney

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Camera permission denied with "Don't ask again": only the app's
        // details page in system Settings can grant it again (U7).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ourney/app_settings")
            .setMethodCallHandler { call, result ->
                if (call.method != "openAppDetails") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    val intent = Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.fromParts("package", packageName, null),
                    ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.success(false)
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ourney/app_icon")
            .setMethodCallHandler { call, result ->
                handleAppIconCall(call, result)
            }
    }

    private fun handleAppIconCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "supportsAlternateIcons" -> result.success(true)
            "getAlternateIcon" -> result.success(currentEnabledAlias())
            "setAlternateIcon" -> {
                val targetAlias = resolveTargetAlias(call)
                if (targetAlias == null || !ICON_ALIASES_BY_ID.containsValue(targetAlias)) {
                    result.success(false)
                    return
                }
                try {
                    switchLauncherAlias(targetAlias)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ICON_SWITCH_FAILED", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun resolveTargetAlias(call: MethodCall): String? {
        val args = call.arguments
        return when (args) {
            null -> DEFAULT_ALIAS
            is String -> ICON_ALIASES_BY_ID[args] ?: args
            is Map<*, *> -> {
                val id = args["id"] as? String
                val alias = args["androidAlias"] as? String
                if (id != null && ICON_ALIASES_BY_ID.containsKey(id)) {
                    ICON_ALIASES_BY_ID[id]
                } else {
                    alias
                }
            }
            else -> null
        }
    }

    private fun currentEnabledAlias(): String {
        val pm = packageManager
        for (alias in ICON_ALIASES_BY_ID.values) {
            val comp = ComponentName(packageName, "$packageName$alias")
            val state = pm.getComponentEnabledSetting(comp)
            if (state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED ||
                (state == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT && alias == DEFAULT_ALIAS)
            ) {
                return alias
            }
        }
        return DEFAULT_ALIAS
    }

    private fun switchLauncherAlias(targetAlias: String) {
        val pm = packageManager
        // Enable the target alias first so at least one LAUNCHER component is
        // always enabled before disabling the previous one.
        val targetComp = ComponentName(packageName, "$packageName$targetAlias")
        val targetState = pm.getComponentEnabledSetting(targetComp)
        val targetAlreadyEnabled =
            targetState == PackageManager.COMPONENT_ENABLED_STATE_ENABLED ||
                (targetState == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT && targetAlias == DEFAULT_ALIAS)
        if (!targetAlreadyEnabled) {
            pm.setComponentEnabledSetting(
                targetComp,
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
        for (alias in ICON_ALIASES_BY_ID.values) {
            if (alias == targetAlias) continue
            val comp = ComponentName(packageName, "$packageName$alias")
            val state = pm.getComponentEnabledSetting(comp)
            val isEnabled =
                state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED ||
                    (state == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT && alias == DEFAULT_ALIAS)
            if (isEnabled) {
                pm.setComponentEnabledSetting(
                    comp,
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP,
                )
            }
        }
    }

    companion object {
        private const val DEFAULT_ALIAS = ".IconDefault"
        private val ICON_ALIASES_BY_ID = linkedMapOf(
            "default" to DEFAULT_ALIAS,
            "yellow" to ".IconYellow",
            "green" to ".IconGreen",
            "coral" to ".IconCoral",
            "violet" to ".IconViolet",
            "sky" to ".IconSky",
            "dark" to ".IconDark",
            "minimal" to ".IconMinimal",
        )
    }
}
