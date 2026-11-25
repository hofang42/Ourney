package com.hofang42.ourney.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import androidx.annotation.Keep
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import com.hofang42.ourney.R

@Keep
class OurneyTodayWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = TodayGlanceWidget()

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        attachInitialTapFallback(context, appWidgetManager, appWidgetIds)
        super.onUpdate(context, appWidgetManager, appWidgetIds)
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        WidgetSnapshotStore.fromContext(context).removeWidgetSelections(appWidgetIds)
    }

    companion object {
        internal fun attachInitialTapFallback(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray,
        ) {
            try {
                val rv = RemoteViews(context.packageName, R.layout.widget_initial_loading).apply {
                    setOnClickPendingIntent(
                        R.id.widget_initial_root,
                        WidgetActions.syncWidgetsPendingIntent(context),
                    )
                }
                appWidgetManager.partiallyUpdateAppWidget(appWidgetIds, rv)
            } catch (_: Throwable) {
            }
        }
    }
}
