package com.hofang42.ourney.widgets

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.io.File
import java.io.FileOutputStream
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.security.MessageDigest

/**
 * Atomic file store for `<filesDir>/ourney_widgets/`:
 * - `snapshot_v1.json` (versioned widget & Live Update state)
 * - `state.json` (interactive cycle index & dismissed window key)
 * - `thumbs/<sha256_16>.jpg` (content-addressed downsampled/blurred JPEGs)
 */
class WidgetSnapshotStore(val rootDir: File) {

    val snapshotFile: File
        get() = File(rootDir, SNAPSHOT_FILE_NAME)

    val stateFile: File
        get() = File(rootDir, STATE_FILE_NAME)

    val thumbsDir: File
        get() = File(rootDir, THUMBS_DIR_NAME)

    /**
     * Reads and parses `snapshot_v1.json`, evaluating time-shifted rollover
     * rules at [nowEpochMs]. Returns `null` if missing or corrupt.
     */
    @Synchronized
    fun readSnapshot(nowEpochMs: Long = System.currentTimeMillis()): WidgetSnapshot? {
        val file = snapshotFile
        if (!file.isFile) return null
        return try {
            val raw = file.readText(StandardCharsets.UTF_8)
            if (raw.isBlank()) return null
            WidgetSnapshot.fromJson(raw).evaluateAt(nowEpochMs)
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Writes [snapshotJson] atomically via `snapshot_v1.json.tmp` -> `snapshot_v1.json`.
     *
     * @return [WriteResult] indicating whether the write succeeded and whether the
     * canonical SHA-256 content hash changed compared to the previous file on disk.
     */
    @Synchronized
    fun writeSnapshotAtomically(snapshotJson: String): WriteResult {
        return try {
            val parsed = WidgetSnapshot.fromJson(snapshotJson)
            if (!rootDir.exists()) {
                rootDir.mkdirs()
            }
            val newHash = sha256Hex(snapshotJson)
            val previousHash = if (snapshotFile.isFile) {
                try {
                    sha256Hex(snapshotFile.readText(StandardCharsets.UTF_8))
                } catch (_: Exception) {
                    null
                }
            } else {
                null
            }

            atomicWriteText(snapshotFile, snapshotJson)
            WriteResult(
                success = true,
                changed = newHash != previousHash,
                snapshot = parsed,
            )
        } catch (_: Exception) {
            WriteResult(success = false, changed = false, snapshot = null)
        }
    }

    /**
     * Content-addressed thumbnail synchronizer:
     * - Copies/downsamples/blurs only missing `<id>.jpg` files (`0 CPU` on cache hit).
     * - Sweeps orphan files in `thumbs/` not referenced by [referencedRelPaths] or [specs].
     */
    @Synchronized
    fun syncThumbs(specs: List<ThumbSpec>, referencedRelPaths: Set<String>) {
        if (!thumbsDir.exists()) {
            thumbsDir.mkdirs()
        }
        val keepFileNames = mutableSetOf<String>()
        for (rel in referencedRelPaths) {
            sanitizeFileName(rel.substringAfterLast('/'))?.let(keepFileNames::add)
        }
        for (spec in specs) {
            val safeName = sanitizeFileName(spec.id.substringAfterLast('/')) ?: continue
            keepFileNames.add(safeName)
            val destFile = File(thumbsDir, safeName)
            if (destFile.isFile && destFile.length() > 0L) {
                // Content-addressed cache hit: skip re-encoding.
                continue
            }
            val srcFile = File(spec.sourcePath)
            if (!srcFile.isFile) continue
            prepareThumbFile(srcFile, destFile, spec.maxSide, spec.blur)
        }

        thumbsDir.listFiles()?.forEach { existing ->
            if (existing.isFile && existing.name !in keepFileNames) {
                existing.delete()
            }
        }
    }

    /**
     * Resolves a relative thumbnail path (e.g. `"thumbs/a91f4c82b011e3d4.jpg"`)
     * safely inside [thumbsDir], preventing path traversal.
     */
    fun resolveThumbFile(relativePath: String?): File? {
        if (relativePath.isNullOrBlank()) return null
        val safeName = sanitizeFileName(relativePath.substringAfterLast('/')) ?: return null
        val file = File(thumbsDir, safeName)
        return file.takeIf { it.isFile && it.length() > 0L }
    }

    @Synchronized
    fun readState(): WidgetMutableState {
        val file = stateFile
        if (!file.isFile) return WidgetMutableState()
        return try {
            val raw = file.readText(StandardCharsets.UTF_8)
            if (raw.isBlank()) WidgetMutableState() else WidgetMutableState.fromJson(raw)
        } catch (_: Exception) {
            WidgetMutableState()
        }
    }

    @Synchronized
    fun writeState(state: WidgetMutableState): Boolean {
        return try {
            if (!rootDir.exists()) {
                rootDir.mkdirs()
            }
            atomicWriteText(stateFile, state.toJsonString())
            true
        } catch (_: Exception) {
            false
        }
    }

    @Synchronized
    fun cycleTodayJourney(): WidgetMutableState {
        val current = readState()
        val next = current.copy(selectedTodayIndex = current.selectedTodayIndex + 1)
        writeState(next)
        return next
    }

    @Synchronized
    fun markWindowDismissed(windowKey: String, nowEpochMs: Long = System.currentTimeMillis()): WidgetMutableState {
        val current = readState()
        val next = current.copy(
            dismissedWindowKey = windowKey,
            dismissedWindowDate = WidgetMutableState.todayUtcDateString(nowEpochMs),
        )
        writeState(next)
        return next
    }

    /**
     * Wipes `snapshot_v1.json`, `state.json`, and all cached `thumbs/<id>.jpg` files on
     * sign-out, account switch, or account deletion.
     */
    @Synchronized
    fun clearAll(): Boolean {
        return try {
            if (snapshotFile.exists()) snapshotFile.delete()
            if (stateFile.exists()) stateFile.delete()
            if (thumbsDir.exists()) {
                thumbsDir.listFiles()?.forEach { it.delete() }
                thumbsDir.delete()
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun prepareThumbFile(
        sourceFile: File,
        destFile: File,
        maxSide: Int,
        blur: Boolean,
    ) {
        try {
            val boundsOpts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(sourceFile.absolutePath, boundsOpts)
            val srcW = boundsOpts.outWidth
            val srcH = boundsOpts.outHeight
            if (srcW <= 0 || srcH <= 0) {
                if (!blur) {
                    copyRawFileAtomically(sourceFile, destFile)
                }
                return
            }

            var sampleSize = 1
            val longest = maxOf(srcW, srcH)
            while (longest / (sampleSize * 2) >= maxSide) {
                sampleSize *= 2
            }

            val decodeOpts = BitmapFactory.Options().apply {
                inSampleSize = sampleSize
                inPreferredConfig = Bitmap.Config.ARGB_8888
            }
            val decoded = BitmapFactory.decodeFile(sourceFile.absolutePath, decodeOpts)
            if (decoded == null) {
                if (!blur) {
                    copyRawFileAtomically(sourceFile, destFile)
                }
                return
            }

            val scaled = scaleDownBitmap(decoded, maxSide)
            if (scaled !== decoded) {
                decoded.recycle()
            }

            val processed = if (blur) {
                val blurred = fastStackBlur(scaled, radius = 14)
                if (blurred !== scaled) scaled.recycle()
                blurred
            } else {
                scaled
            }

            val tmpFile = File(destFile.parentFile, "${destFile.name}.tmp")
            FileOutputStream(tmpFile).use { out ->
                processed.compress(Bitmap.CompressFormat.JPEG, 82, out)
                out.fd.sync()
            }
            processed.recycle()
            atomicMove(tmpFile, destFile)
        } catch (_: Throwable) {
            // Fail closed when blur == true so an unblurred sensitive photo is never written.
            // When blur == false (or in pure-JVM unit tests where BitmapFactory is stubbed),
            // fall back to atomic file copy.
            if (!blur) {
                try {
                    copyRawFileAtomically(sourceFile, destFile)
                } catch (_: Exception) {
                }
            }
        }
    }

    private fun scaleDownBitmap(bitmap: Bitmap, maxSide: Int): Bitmap {
        val w = bitmap.width
        val h = bitmap.height
        val longest = maxOf(w, h)
        if (longest <= maxSide) return bitmap
        val ratio = maxSide.toFloat() / longest.toFloat()
        val targetW = (w * ratio).toInt().coerceAtLeast(1)
        val targetH = (h * ratio).toInt().coerceAtLeast(1)
        return Bitmap.createScaledBitmap(bitmap, targetW, targetH, true)
    }

    /**
     * Lightweight 2-pass box blur approximation on a pre-downsampled bitmap so
     * sensitive photos (`TemplateId.weightLoss` / `blurPhotosOnShare`) are blurred
     * on disk before Glance ever renders them.
     */
    private fun fastStackBlur(src: Bitmap, radius: Int): Bitmap {
        val scale = 4
        val smallW = (src.width / scale).coerceAtLeast(8)
        val smallH = (src.height / scale).coerceAtLeast(8)
        val small = Bitmap.createScaledBitmap(src, smallW, smallH, true)
        val work = small.copy(Bitmap.Config.ARGB_8888, true) ?: return src
        if (small !== src) small.recycle()

        val w = work.width
        val h = work.height
        val pixels = IntArray(w * h)
        val temp = IntArray(w * h)
        work.getPixels(pixels, 0, w, 0, 0, w, h)
        val r = (radius / scale).coerceIn(2, 8)
        val window = 2 * r + 1

        // Horizontal pass
        for (y in 0 until h) {
            val rowOffset = y * w
            for (x in 0 until w) {
                var sumR = 0
                var sumG = 0
                var sumB = 0
                for (dx in -r..r) {
                    val sampleX = (x + dx).coerceIn(0, w - 1)
                    val c = pixels[rowOffset + sampleX]
                    sumR += (c shr 16) and 0xFF
                    sumG += (c shr 8) and 0xFF
                    sumB += c and 0xFF
                }
                temp[rowOffset + x] =
                    (0xFF shl 24) or ((sumR / window) shl 16) or ((sumG / window) shl 8) or (sumB / window)
            }
        }
        // Vertical pass
        for (x in 0 until w) {
            for (y in 0 until h) {
                var sumR = 0
                var sumG = 0
                var sumB = 0
                for (dy in -r..r) {
                    val sampleY = (y + dy).coerceIn(0, h - 1)
                    val c = temp[sampleY * w + x]
                    sumR += (c shr 16) and 0xFF
                    sumG += (c shr 8) and 0xFF
                    sumB += c and 0xFF
                }
                pixels[y * w + x] =
                    (0xFF shl 24) or ((sumR / window) shl 16) or ((sumG / window) shl 8) or (sumB / window)
            }
        }
        work.setPixels(pixels, 0, w, 0, 0, w, h)
        val upscaled = Bitmap.createScaledBitmap(work, src.width, src.height, true)
        if (upscaled !== work) work.recycle()
        return upscaled
    }

    private fun copyRawFileAtomically(sourceFile: File, destFile: File) {
        val tmpFile = File(destFile.parentFile, "${destFile.name}.tmp")
        Files.copy(sourceFile.toPath(), tmpFile.toPath(), StandardCopyOption.REPLACE_EXISTING)
        atomicMove(tmpFile, destFile)
    }

    private fun atomicWriteText(targetFile: File, content: String) {
        val parent = targetFile.parentFile
        if (parent != null && !parent.exists()) {
            parent.mkdirs()
        }
        val tmpFile = File(parent, "${targetFile.name}.tmp")
        FileOutputStream(tmpFile).use { out ->
            out.write(content.toByteArray(StandardCharsets.UTF_8))
            out.fd.sync()
        }
        atomicMove(tmpFile, targetFile)
    }

    private fun atomicMove(tmpFile: File, targetFile: File) {
        try {
            Files.move(
                tmpFile.toPath(),
                targetFile.toPath(),
                StandardCopyOption.REPLACE_EXISTING,
                StandardCopyOption.ATOMIC_MOVE,
            )
        } catch (_: Exception) {
            Files.move(
                tmpFile.toPath(),
                targetFile.toPath(),
                StandardCopyOption.REPLACE_EXISTING,
            )
        }
    }

    data class WriteResult(
        val success: Boolean,
        val changed: Boolean,
        val snapshot: WidgetSnapshot?,
    )

    companion object {
        const val ROOT_DIR_NAME = "ourney_widgets"
        const val SNAPSHOT_FILE_NAME = "snapshot_v1.json"
        const val STATE_FILE_NAME = "state.json"
        const val THUMBS_DIR_NAME = "thumbs"

        private val SAFE_FILENAME_REGEX = Regex("^[A-Za-z0-9._-]+$")

        fun fromContext(context: Context): WidgetSnapshotStore =
            WidgetSnapshotStore(File(context.filesDir, ROOT_DIR_NAME))

        fun sanitizeFileName(raw: String?): String? {
            if (raw.isNullOrBlank()) return null
            val trimmed = raw.trim()
            if (trimmed == "." || trimmed == ".." || !SAFE_FILENAME_REGEX.matches(trimmed)) {
                return null
            }
            return trimmed
        }

        fun sha256Hex(text: String): String {
            val digest = MessageDigest.getInstance("SHA-256")
                .digest(text.toByteArray(StandardCharsets.UTF_8))
            val sb = StringBuilder(digest.size * 2)
            for (b in digest) {
                sb.append(String.format(java.util.Locale.ROOT, "%02x", b))
            }
            return sb.toString()
        }
    }
}
