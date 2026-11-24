# Keep Jetpack Glance AppWidgetReceivers, GlanceAppWidgets, ActionCallbacks,
# and CheckInWindowReceiver so R8 never strips their no-arg constructors.
-keep class com.hofang42.ourney.widgets.OurneyTodayWidgetReceiver {
    public <init>();
}
-keep class com.hofang42.ourney.widgets.OurneyStreakWidgetReceiver {
    public <init>();
}
-keep class com.hofang42.ourney.widgets.OurneySquadWidgetReceiver {
    public <init>();
}
-keep class com.hofang42.ourney.widgets.TodayGlanceWidget {
    public <init>();
}
-keep class com.hofang42.ourney.widgets.StreakGlanceWidget {
    public <init>();
}
-keep class com.hofang42.ourney.widgets.SquadGlanceWidget {
    public <init>();
}
-keep class com.hofang42.ourney.widgets.CycleTodayJourneyAction {
    public <init>();
}
-keep class com.hofang42.ourney.widgets.CheckInWindowReceiver {
    public <init>();
}
-keep class * extends androidx.glance.appwidget.GlanceAppWidgetReceiver {
    public <init>();
}
-keep class * implements androidx.glance.appwidget.action.ActionCallback {
    public <init>();
}
