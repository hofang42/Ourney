package com.hofang42.ourney.widgets

import androidx.annotation.Keep
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver

@Keep
class OurneyTodayWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = TodayGlanceWidget()
}
