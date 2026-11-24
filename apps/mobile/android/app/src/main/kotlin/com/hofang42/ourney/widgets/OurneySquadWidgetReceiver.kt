package com.hofang42.ourney.widgets

import androidx.annotation.Keep
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver

@Keep
class OurneySquadWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = SquadGlanceWidget()
}
