package com.hofang42.ourney.widgets

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import java.io.File

/**
 * Renders Ourney's Soft Neo-Brutalist custom-typography & geometric sticker
 * components into compact bitmaps (`< 35 KB` each) so total `RemoteViews`
 * Binder IPC parcels remain well below `< 250 KB`.
 *
 * Uses Flutter's already-bundled fonts (`flutter_assets/assets/fonts/...`) for
 * `0 KB` extra APK footprint.
 */
object OurneyWidgetCanvas {

    private const val DISPLAY_FONT_ASSET =
        "flutter_assets/assets/fonts/BricolageGrotesque-Variable.ttf"
    private const val BODY_BOLD_FONT_ASSET =
        "flutter_assets/assets/fonts/BeVietnamPro-Bold.ttf"
    private const val BODY_SEMIBOLD_FONT_ASSET =
        "flutter_assets/assets/fonts/BeVietnamPro-SemiBold.ttf"

    @Volatile
    private var displayTypeface: Typeface? = null

    @Volatile
    private var bodyBoldTypeface: Typeface? = null

    @Volatile
    private var bodySemiBoldTypeface: Typeface? = null

    fun getDisplayTypeface(context: Context): Typeface {
        displayTypeface?.let { return it }
        return synchronized(this) {
            displayTypeface ?: loadAssetTypeface(context, DISPLAY_FONT_ASSET)
                .also { displayTypeface = it }
        }
    }

    fun getBodyBoldTypeface(context: Context): Typeface {
        bodyBoldTypeface?.let { return it }
        return synchronized(this) {
            bodyBoldTypeface ?: loadAssetTypeface(context, BODY_BOLD_FONT_ASSET)
                .also { bodyBoldTypeface = it }
        }
    }

    fun getBodySemiBoldTypeface(context: Context): Typeface {
        bodySemiBoldTypeface?.let { return it }
        return synchronized(this) {
            bodySemiBoldTypeface ?: loadAssetTypeface(context, BODY_SEMIBOLD_FONT_ASSET)
                .also { bodySemiBoldTypeface = it }
        }
    }

    private fun loadAssetTypeface(context: Context, assetPath: String): Typeface {
        return try {
            Typeface.createFromAsset(context.assets, assetPath)
        } catch (_: Exception) {
            Typeface.DEFAULT_BOLD
        }
    }

    /**
     * Renders the hero `BricolageGrotesque` streak numeral + `flame` vector sticker
     * inside a Soft Neo-Brutalist badge (`2dp` ink stroke + `2dp` hard offset shadow).
     */
    fun renderStreakHeroBadge(
        context: Context,
        streakCount: Int,
        palette: OurneyWidgetPalette,
        atRisk: Boolean = false,
        checkedInToday: Boolean = false,
        compact: Boolean = false,
    ): Bitmap {
        val density = context.resources.displayMetrics.density.coerceIn(1f, 2.25f)
        val widthDp = if (compact) 84f else 104f
        val heightDp = if (compact) 38f else 46f
        val w = (widthDp * density).toInt().coerceAtLeast(1)
        val h = (heightDp * density).toInt().coerceAtLeast(1)

        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val shadowPx = 2.5f * density
        val borderPx = palette.borderWidthDp * density
        val radiusPx = 12f * density

        val pillFill = when {
            atRisk && !checkedInToday -> if (palette.isDark) 0xFF2E2417.toInt() else 0xFFFEF3C7.toInt()
            checkedInToday -> palette.successSoft
            else -> palette.surface
        }
        val pillBorder = when {
            atRisk && !checkedInToday -> if (palette.isDark) 0xFFF2A93B.toInt() else 0xFFB8650A.toInt()
            else -> palette.outline
        }

        val shadowRect = RectF(shadowPx, shadowPx, w - 1f, h - 1f)
        val cardRect = RectF(
            borderPx / 2f,
            borderPx / 2f,
            w - shadowPx - borderPx / 2f,
            h - shadowPx - borderPx / 2f,
        )

        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        // Hard offset shadow
        paint.style = Paint.Style.FILL
        paint.color = palette.hardShadow
        canvas.drawRoundRect(shadowRect, radiusPx, radiusPx, paint)

        // Sticker pill surface
        paint.color = pillFill
        canvas.drawRoundRect(cardRect, radiusPx, radiusPx, paint)

        // Sticker ink border
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = borderPx
        paint.color = pillBorder
        canvas.drawRoundRect(cardRect, radiusPx, radiusPx, paint)

        // Draw two-tone Ourney flame icon on the left
        val flameBoxSize = (if (compact) 20f else 24f) * density
        val flameLeft = cardRect.left + 8f * density
        val flameTop = cardRect.centerY() - flameBoxSize / 2f
        drawFlameIcon(canvas, flameLeft, flameTop, flameBoxSize, palette.ink)

        // Draw BricolageGrotesque streak numeral
        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = getDisplayTypeface(context)
            isFakeBoldText = true
            textSize = (if (compact) 20f else 24f) * density
            color = if (atRisk && !checkedInToday) palette.timeCue else palette.ink
            textAlign = Paint.Align.LEFT
        }
        val numStr = streakCount.toString()
        val fm = textPaint.fontMetrics
        val textY = cardRect.centerY() - (fm.ascent + fm.descent) / 2f
        val textX = flameLeft + flameBoxSize + 5f * density
        canvas.drawText(numStr, textX, textY, textPaint)

        return bitmap
    }

    /**
     * Renders the 7-day rolling consistency chain (`WeekStrip`: 7 crisp Neo-Brutalist
     * squares with `2dp` ink borders, `2dp` hard offset shadows, checkmark vector on
     * completed days, and Vietnamese/English day labels).
     */
    fun renderWeekStrip(
        context: Context,
        weekStrip: List<WidgetWeekDay>,
        palette: OurneyWidgetPalette,
        widthDp: Float = 216f,
        heightDp: Float = 44f,
    ): Bitmap {
        val density = context.resources.displayMetrics.density.coerceIn(1f, 2.25f)
        val w = (widthDp * density).toInt().coerceAtLeast(1)
        val h = (heightDp * density).toInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val days = if (weekStrip.size >= 7) {
            weekStrip.takeLast(7)
        } else {
            val padded = weekStrip.toMutableList()
            while (padded.size < 7) {
                padded.add(
                    0,
                    WidgetWeekDay(date = "", day = 0, label = "·", state = "future"),
                )
            }
            padded
        }

        val count = 7
        val gapPx = 5f * density
        val cellW = ((w - gapPx * (count - 1)) / count.toFloat()).coerceAtLeast(10f)
        val boxSize = minOf(cellW - 2f * density, 22f * density)
        val shadowPx = 1.8f * density
        val borderPx = (palette.borderWidthDp * 0.85f) * density
        val cornerPx = 6f * density

        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val labelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = getBodyBoldTypeface(context)
            textSize = 9.5f * density
            textAlign = Paint.Align.CENTER
        }

        for (i in 0 until count) {
            val day = days[i]
            val cellLeft = i * (cellW + gapPx)
            val cellCenterX = cellLeft + cellW / 2f
            val boxLeft = cellCenterX - boxSize / 2f
            val boxTop = 2f * density

            val isDone = day.state == "done"
            val isToday = day.state == "today"

            val boxRect = RectF(boxLeft, boxTop, boxLeft + boxSize, boxTop + boxSize)
            if (isDone || isToday) {
                val shadowRect = RectF(
                    boxRect.left + shadowPx,
                    boxRect.top + shadowPx,
                    boxRect.right + shadowPx,
                    boxRect.bottom + shadowPx,
                )
                paint.style = Paint.Style.FILL
                paint.color = palette.hardShadow
                canvas.drawRoundRect(shadowRect, cornerPx, cornerPx, paint)
            }

            // Fill
            paint.style = Paint.Style.FILL
            paint.color = when {
                isDone -> palette.accent
                isToday -> palette.brand
                else -> palette.fill
            }
            canvas.drawRoundRect(boxRect, cornerPx, cornerPx, paint)

            // Border
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = borderPx
            paint.color = if (isToday || isDone) palette.outline else palette.inkMuted
            canvas.drawRoundRect(boxRect, cornerPx, cornerPx, paint)

            // Inner check or dot
            if (isDone) {
                val checkPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    style = Paint.Style.STROKE
                    strokeWidth = 2f * density
                    strokeCap = Paint.Cap.ROUND
                    strokeJoin = Paint.Join.ROUND
                    color = palette.onAccent
                }
                val path = Path().apply {
                    moveTo(boxRect.left + boxSize * 0.25f, boxRect.top + boxSize * 0.52f)
                    lineTo(boxRect.left + boxSize * 0.44f, boxRect.top + boxSize * 0.70f)
                    lineTo(boxRect.left + boxSize * 0.76f, boxRect.top + boxSize * 0.32f)
                }
                canvas.drawPath(path, checkPaint)
            } else if (isToday) {
                paint.style = Paint.Style.FILL
                paint.color = 0xFF1A1A1A.toInt()
                canvas.drawCircle(
                    boxRect.centerX(),
                    boxRect.centerY(),
                    2.6f * density,
                    paint,
                )
            }

            // Day label below square
            labelPaint.color = if (isToday || isDone) palette.ink else palette.inkMuted
            val labelText = day.label.take(3).ifBlank { (i + 1).toString() }
            val labelY = boxRect.bottom + 12.5f * density
            canvas.drawText(labelText, cellCenterX, labelY, labelPaint)
        }

        return bitmap
    }

    /**
     * Renders Squad member avatar discs (up to 5 discs + `+N` overflow badge, each
     * with a Neo-Brutalist paper/ink border and a green check dot if `checkedInToday`).
     */
    fun renderSquadAvatarStrip(
        context: Context,
        store: WidgetSnapshotStore,
        members: List<WidgetSquadMember>,
        totalMemberCount: Int,
        palette: OurneyWidgetPalette,
    ): Bitmap {
        val density = context.resources.displayMetrics.density.coerceIn(1f, 2.25f)
        val visible = members.take(5)
        val overflow = (totalMemberCount - visible.size).coerceAtLeast(0)
        val slotCount = (visible.size + if (overflow > 0) 1 else 0).coerceAtLeast(1)

        val discDp = 34f
        val stepDp = 28f
        val widthDp = discDp + (slotCount - 1) * stepDp + 8f
        val heightDp = 40f

        val w = (widthDp * density).toInt().coerceAtLeast(1)
        val h = (heightDp * density).toInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val radius = (discDp * density) / 2f
        val cy = h / 2f
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = getBodyBoldTypeface(context)
            textSize = 13.5f * density
            textAlign = Paint.Align.CENTER
        }

        visible.forEachIndexed { idx, member ->
            val cx = radius + 2f * density + idx * (stepDp * density)

            // Hard offset shadow
            paint.style = Paint.Style.FILL
            paint.color = palette.hardShadow
            canvas.drawCircle(cx + 1.5f * density, cy + 1.5f * density, radius - 1f * density, paint)

            val avatarFile = store.resolveThumbFile(member.avatarFile)
            val avatarBmp = avatarFile?.let { decodeSmallBitmap(it, (discDp * density).toInt()) }

            if (avatarBmp != null) {
                drawCircularBitmap(canvas, avatarBmp, cx, cy, radius - 1.5f * density)
                avatarBmp.recycle()
            } else {
                val discColor = OurneyGlanceTheme.avatarDiscColor(member.avatarColorIndex)
                paint.style = Paint.Style.FILL
                paint.color = discColor
                canvas.drawCircle(cx, cy, radius - 1.5f * density, paint)

                textPaint.color = OurneyGlanceTheme.avatarInkColor(discColor)
                val fm = textPaint.fontMetrics
                val ty = cy - (fm.ascent + fm.descent) / 2f
                canvas.drawText(member.initial.take(1).uppercase(), cx, ty, textPaint)
            }

            // Sticker outline ring
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = 2f * density
            paint.color = if (member.checkedInToday) palette.accent else palette.outline
            canvas.drawCircle(cx, cy, radius - 1.5f * density, paint)

            // Status indicator dot at bottom-right
            val badgeR = 5.5f * density
            val badgeX = cx + radius * 0.62f
            val badgeY = cy + radius * 0.62f
            paint.style = Paint.Style.FILL
            paint.color = if (member.checkedInToday) 0xFF10B981.toInt() else palette.fill
            canvas.drawCircle(badgeX, badgeY, badgeR, paint)
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = 1.5f * density
            paint.color = palette.outline
            canvas.drawCircle(badgeX, badgeY, badgeR, paint)
        }

        if (overflow > 0) {
            val cx = radius + 2f * density + visible.size * (stepDp * density)
            paint.style = Paint.Style.FILL
            paint.color = palette.fill
            canvas.drawCircle(cx, cy, radius - 1.5f * density, paint)
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = 2f * density
            paint.color = palette.outline
            canvas.drawCircle(cx, cy, radius - 1.5f * density, paint)

            textPaint.color = palette.ink
            textPaint.textSize = 11.5f * density
            val fm = textPaint.fontMetrics
            val ty = cy - (fm.ascent + fm.descent) / 2f
            canvas.drawText("+$overflow", cx, ty, textPaint)
        }

        return bitmap
    }

    /**
     * Renders a Soft Neo-Brutalist framed Polaroid thumbnail from [photoFile]
     * (`12dp` rounded corners, `2dp` ink border, `2.5dp` hard shadow), capped
     * at `< 35 KB` in memory.
     */
    fun renderFramedPhoto(
        context: Context,
        photoFile: File?,
        palette: OurneyWidgetPalette,
        widthDp: Float = 76f,
        heightDp: Float = 76f,
    ): Bitmap? {
        if (photoFile == null || !photoFile.isFile) return null
        val density = context.resources.displayMetrics.density.coerceIn(1f, 2f)
        val w = (widthDp * density).toInt().coerceAtLeast(16)
        val h = (heightDp * density).toInt().coerceAtLeast(16)
        val src = decodeSmallBitmap(photoFile, maxOf(w, h)) ?: return null

        val out = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(out)
        val shadowPx = 2.5f * density
        val borderPx = palette.borderWidthDp * density
        val cornerPx = 12f * density

        val shadowRect = RectF(shadowPx, shadowPx, w - 1f, h - 1f)
        val photoRect = RectF(
            borderPx / 2f,
            borderPx / 2f,
            w - shadowPx - borderPx / 2f,
            h - shadowPx - borderPx / 2f,
        )

        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.style = Paint.Style.FILL
        paint.color = palette.hardShadow
        canvas.drawRoundRect(shadowRect, cornerPx, cornerPx, paint)

        val scaled = centerCropBitmap(src, photoRect.width().toInt(), photoRect.height().toInt())
        if (scaled !== src) src.recycle()

        val saveCount = canvas.save()
        canvas.translate(photoRect.left, photoRect.top)
        val shaderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = BitmapShader(scaled, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
        }
        canvas.drawRoundRect(
            RectF(0f, 0f, photoRect.width(), photoRect.height()),
            cornerPx,
            cornerPx,
            shaderPaint,
        )
        canvas.restoreToCount(saveCount)
        scaled.recycle()

        paint.style = Paint.Style.STROKE
        paint.strokeWidth = borderPx
        paint.color = palette.outline
        canvas.drawRoundRect(photoRect, cornerPx, cornerPx, paint)

        return out
    }

    private fun drawFlameIcon(
        canvas: Canvas,
        left: Float,
        top: Float,
        sizePx: Float,
        inkColor: Int,
    ) {
        val scale = sizePx / 24f
        val save = canvas.save()
        canvas.translate(left, top)
        canvas.scale(scale, scale)

        // Outer flame silhouette from ourney_icons.dart:139
        val outer = Path().apply {
            moveTo(12f, 21f)
            cubicTo(7.6f, 21f, 5f, 18.4f, 5f, 14.5f)
            cubicTo(5f, 11.5f, 7f, 9.3f, 9.3f, 6.8f)
            cubicTo(9.4f, 8.8f, 10.4f, 9.8f, 11.3f, 10.3f)
            cubicTo(11.7f, 6.8f, 13.4f, 4.5f, 15.6f, 3.0f)
            cubicTo(15.7f, 6.6f, 19.0f, 8.7f, 19.0f, 13.0f)
            cubicTo(19.0f, 17.8f, 16.0f, 21.0f, 12.0f, 21.0f)
            close()
        }
        // Inner core from ourney_icons.dart:27
        val core = Path().apply {
            moveTo(12f, 18.6f)
            cubicTo(10f, 18.6f, 8.7f, 17.4f, 8.7f, 15.6f)
            cubicTo(8.7f, 14.2f, 9.5f, 13.1f, 10.7f, 12.0f)
            cubicTo(10.8f, 13.0f, 11.3f, 13.6f, 11.9f, 13.9f)
            cubicTo(12.1f, 12.2f, 12.9f, 11.1f, 13.9f, 10.3f)
            cubicTo(14.0f, 12.0f, 15.7f, 13.1f, 15.7f, 15.4f)
            cubicTo(15.7f, 17.4f, 14.2f, 18.6f, 12.0f, 18.6f)
            close()
        }

        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
        }
        // Halo outline
        paint.color = inkColor
        paint.style = Paint.Style.FILL_AND_STROKE
        paint.strokeWidth = 3.8f
        canvas.drawPath(outer, paint)

        // Sticker fill (#C2452B)
        paint.color = 0xFFC2452B.toInt()
        paint.strokeWidth = 1.6f
        canvas.drawPath(outer, paint)

        // Core fill (#FF9F1C)
        paint.style = Paint.Style.FILL
        paint.color = 0xFFFF9F1C.toInt()
        canvas.drawPath(core, paint)

        canvas.restoreToCount(save)
    }

    private fun decodeSmallBitmap(file: File, targetMaxPx: Int): Bitmap? {
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(file.absolutePath, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
            var sample = 1
            val longest = maxOf(bounds.outWidth, bounds.outHeight)
            while (longest / (sample * 2) >= targetMaxPx.coerceAtLeast(16)) {
                sample *= 2
            }
            val opts = BitmapFactory.Options().apply {
                inSampleSize = sample
                inPreferredConfig = Bitmap.Config.ARGB_8888
            }
            BitmapFactory.decodeFile(file.absolutePath, opts)
        } catch (_: Exception) {
            null
        }
    }

    private fun centerCropBitmap(src: Bitmap, targetW: Int, targetH: Int): Bitmap {
        val tw = targetW.coerceAtLeast(1)
        val th = targetH.coerceAtLeast(1)
        val scale = maxOf(tw.toFloat() / src.width.toFloat(), th.toFloat() / src.height.toFloat())
        val scaledW = (src.width * scale).toInt().coerceAtLeast(tw)
        val scaledH = (src.height * scale).toInt().coerceAtLeast(th)
        val scaled = Bitmap.createScaledBitmap(src, scaledW, scaledH, true)
        val dx = ((scaledW - tw) / 2).coerceAtLeast(0)
        val dy = ((scaledH - th) / 2).coerceAtLeast(0)
        val cropped = Bitmap.createBitmap(scaled, dx, dy, tw, th)
        if (cropped !== scaled && scaled !== src) {
            scaled.recycle()
        }
        return cropped
    }

    private fun drawCircularBitmap(
        canvas: Canvas,
        bmp: Bitmap,
        cx: Float,
        cy: Float,
        radius: Float,
    ) {
        val diameter = (radius * 2f).toInt().coerceAtLeast(2)
        val cropped = centerCropBitmap(bmp, diameter, diameter)
        val save = canvas.save()
        canvas.translate(cx - radius, cy - radius)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = BitmapShader(cropped, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
        }
        canvas.drawCircle(radius, radius, radius, paint)
        canvas.restoreToCount(save)
        if (cropped !== bmp) cropped.recycle()
    }
}
