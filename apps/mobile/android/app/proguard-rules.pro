# flutter_local_notifications 19.0.0+ (22.3.2) upgrades to Gson 2.12.0, which ships built-in
# consumer R8 rules (META-INF/proguard/gson.pro), and annotates its plugin/model classes with
# @androidx.annotation.Keep (see flutter_local_notifications README §"ProGuard rules" and
# CHANGELOG 19.0.0). Avoid global `-keepattributes *Annotation*`, unconditional `TypeToken`
# keeps, or `{ *; }` wildcards which inflate R8's live object graph and heap.
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver
-keep class com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver

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
