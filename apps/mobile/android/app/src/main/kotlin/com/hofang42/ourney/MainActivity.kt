package com.hofang42.ourney

import android.Manifest
import android.content.ComponentName
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.hofang42.ourney.widgets.OurneyWidgetBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException

class MainActivity : FlutterActivity() {
    private var pendingStoragePermissionCallback: ((Boolean) -> Unit)? = null
    private val mediaSaverExecutor = Executors.newSingleThreadExecutor()

    override fun onDestroy() {
        pendingStoragePermissionCallback?.invoke(false)
        pendingStoragePermissionCallback = null
        mediaSaverExecutor.shutdown()
        super.onDestroy()
    }

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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ourney/media_saver")
            .setMethodCallHandler { call, result ->
                handleMediaSaverCall(call, result)
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OurneyWidgetBridge.CHANNEL_NAME)
            .setMethodCallHandler(OurneyWidgetBridge(applicationContext))
    }

    private fun handleMediaSaverCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "saveImage") {
            result.notImplemented()
            return
        }
        val path = call.argument<String>("path")
        val mimeType = call.argument<String>("mimeType") ?: "image/png"
        val ext = if (mimeType == "image/jpeg") "jpg" else "png"
        val fileName =
            call.argument<String>("fileName")
                ?: "ourney-card-${System.currentTimeMillis()}.$ext"
        if (path.isNullOrBlank()) {
            result.error("INVALID_FILE", "Image path is required", null)
            return
        }
        val sourceFile = File(path)
        if (!sourceFile.isFile) {
            result.error("INVALID_FILE", "Source image file does not exist", null)
            return
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            val granted = ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.WRITE_EXTERNAL_STORAGE,
            ) == PackageManager.PERMISSION_GRANTED
            if (!granted) {
                if (pendingStoragePermissionCallback != null) {
                    result.error("SAVE_FAILED", "A storage permission request is already open", null)
                    return
                }
                pendingStoragePermissionCallback = { allowed ->
                    if (allowed) {
                        saveFileToMediaStore(sourceFile, fileName, mimeType, result)
                    } else {
                        result.error(
                            "PERMISSION_DENIED",
                            "WRITE_EXTERNAL_STORAGE permission denied",
                            null,
                        )
                    }
                }
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                    REQUEST_WRITE_EXTERNAL_STORAGE,
                )
                return
            }
        }
        saveFileToMediaStore(sourceFile, fileName, mimeType, result)
    }

    @Suppress("DEPRECATION")
    private fun saveFileToMediaStore(
        sourceFile: File,
        fileName: String,
        mimeType: String,
        result: MethodChannel.Result,
    ) {
        val resolver = applicationContext.contentResolver
        try {
            mediaSaverExecutor.execute {
                var insertedUri: Uri? = null
                try {
                    val nowSeconds = System.currentTimeMillis() / 1000
                    val values = ContentValues().apply {
                        put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                        put(MediaStore.Images.Media.MIME_TYPE, mimeType)
                        put(MediaStore.Images.Media.DATE_ADDED, nowSeconds)
                        put(MediaStore.Images.Media.DATE_MODIFIED, nowSeconds)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            put(
                                MediaStore.Images.Media.RELATIVE_PATH,
                                "${Environment.DIRECTORY_PICTURES}/Ourney",
                            )
                            put(MediaStore.Images.Media.IS_PENDING, 1)
                        } else {
                            val picturesDir = File(
                                Environment.getExternalStoragePublicDirectory(
                                    Environment.DIRECTORY_PICTURES,
                                ),
                                "Ourney",
                            )
                            if (!picturesDir.exists() && !picturesDir.mkdirs()) {
                                runOnUiThread {
                                    result.error(
                                        "SAVE_FAILED",
                                        "Could not create Pictures/Ourney directory",
                                        null,
                                    )
                                }
                                return@execute
                            }
                            val targetFile = File(picturesDir, fileName)
                            put(MediaStore.Images.Media.DATA, targetFile.absolutePath)
                        }
                    }
                    val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                    if (uri == null) {
                        runOnUiThread {
                            result.error("SAVE_FAILED", "MediaStore insert returned null", null)
                        }
                        return@execute
                    }
                    insertedUri = uri
                    val copied = resolver.openOutputStream(uri)?.use { out ->
                        sourceFile.inputStream().use { input ->
                            input.copyTo(out)
                        }
                        true
                    } ?: false
                    if (!copied) {
                        runCatching { resolver.delete(uri, null, null) }
                        runOnUiThread {
                            result.error(
                                "SAVE_FAILED",
                                "Could not open MediaStore output stream",
                                null,
                            )
                        }
                        return@execute
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val publishValues = ContentValues().apply {
                            put(MediaStore.Images.Media.IS_PENDING, 0)
                        }
                        check(resolver.update(uri, publishValues, null, null) == 1) {
                            "Could not publish the MediaStore image"
                        }
                    }
                    val savedUri = uri.toString()
                    runOnUiThread {
                        result.success(savedUri)
                    }
                } catch (se: SecurityException) {
                    insertedUri?.let { runCatching { resolver.delete(it, null, null) } }
                    runOnUiThread {
                        result.error("PERMISSION_DENIED", se.message, null)
                    }
                } catch (e: Exception) {
                    insertedUri?.let { runCatching { resolver.delete(it, null, null) } }
                    runOnUiThread {
                        result.error("SAVE_FAILED", e.message, null)
                    }
                }
            }
        } catch (e: RejectedExecutionException) {
            result.error("SAVE_FAILED", e.message, null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_WRITE_EXTERNAL_STORAGE) {
            val callback = pendingStoragePermissionCallback
            pendingStoragePermissionCallback = null
            val granted =
                grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
            callback?.invoke(granted)
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
        private const val REQUEST_WRITE_EXTERNAL_STORAGE = 4201
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
