import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/feature_routes.dart';

/// Top-level GoRoutes of [routes], looking through shell routes.
Iterable<GoRoute> topLevel(List<RouteBase> routes) sync* {
  for (final route in routes) {
    if (route is GoRoute) {
      yield route;
    } else if (route is ShellRouteBase) {
      yield* topLevel(route.routes);
    }
  }
}

/// Every full path declared under [routes] (children joined to parents).
Iterable<String> fullPaths(List<RouteBase> routes, [String parent = '']) sync* {
  for (final route in routes) {
    if (route is GoRoute) {
      final path = route.path.startsWith('/')
          ? route.path
          : '${parent == '/' ? '' : parent}/${route.path}';
      yield path;
      yield* fullPaths(route.routes, path);
    } else if (route is ShellRouteBase) {
      yield* fullPaths(route.routes, parent);
    }
  }
}

void main() {
  const features = [
    'auth',
    'onboarding',
    'profile',
    'camera',
    'checkin',
    'journeys',
    'groups',
    'share_card',
    'safety',
    'reminders',
    'social',
  ];

  test('every feature folder is registered with route prefixes', () {
    expect(FeatureRoutes.byFeature.keys.toSet(), features.toSet());
    expect(featureRoutePrefixes.keys.toSet(), features.toSet());
    final dirs = Directory('lib/features')
        .listSync()
        .whereType<Directory>()
        .map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last)
        .toSet();
    expect(dirs, features.toSet());
    for (final f in features) {
      expect(
        File('lib/features/$f/routes.dart').existsSync(),
        isTrue,
        reason: '$f must have routes.dart',
      );
    }
  });

  for (final entry in FeatureRoutes.byFeature.entries) {
    test('${entry.key}: top-level paths stay inside its prefixes', () {
      final prefixes = featureRoutePrefixes[entry.key]!;
      final routes = topLevel(entry.value).toList();
      expect(routes, isNotEmpty, reason: '${entry.key} exports no routes');
      for (final route in routes) {
        expect(
          prefixes.any((p) => pathHasPrefix(route.path, p)),
          isTrue,
          reason:
              '${entry.key} declares ${route.path}, '
              'outside its prefixes $prefixes',
        );
      }
    });
  }

  test('no two features declare the same path', () {
    final seen = <String, String>{};
    for (final entry in FeatureRoutes.byFeature.entries) {
      for (final path in fullPaths(entry.value)) {
        expect(
          seen.containsKey(path),
          isFalse,
          reason: '$path declared by ${seen[path]} and ${entry.key}',
        );
        seen[path] = entry.key;
      }
    }
  });

  test('well-known locations exist in the registry', () {
    final all = FeatureRoutes.byFeature.values.expand(fullPaths).toSet();
    expect(
      all,
      containsAll(<String>[
        AppRoutes.capture,
        AppRoutes.checkin,
        AppRoutes.journeys,
        '/journey/:id',
        AppRoutes.groups,
        '/join/:code',
        AppRoutes.onboarding,
        AppRoutes.auth,
        AppRoutes.profile,
        '/share/:journeyId',
        AppRoutes.safety,
        AppRoutes.reminders,
      ]),
    );
  });
}
