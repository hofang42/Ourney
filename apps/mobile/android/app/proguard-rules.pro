# flutter_local_notifications 19.0.0+ (22.3.2) upgrades to Gson 2.12.0, which ships built-in
# consumer R8 rules (META-INF/proguard/gson.pro), and annotates its plugin/model classes with
# @androidx.annotation.Keep (see flutter_local_notifications README §"ProGuard rules" and
# CHANGELOG 19.0.0). Avoid global `-keepattributes *Annotation*`, unconditional `TypeToken`
# keeps, or `{ *; }` wildcards which inflate R8's live object graph and heap.
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver
-keep class com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver
