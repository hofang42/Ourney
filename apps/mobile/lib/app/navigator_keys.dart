import 'package:flutter/widgets.dart';

/// Shared navigator keys (separate file so features can import them without
/// a cycle through router.dart / feature_routes.dart).
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
