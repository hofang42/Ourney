import 'package:flutter/widgets.dart' show ValueKey;
import 'package:go_router/go_router.dart';

import '../../ui/ui.dart';
import 'domain/share_card_content.dart';
import 'ui/share_card_screen.dart';

/// In-app handoff from Wrapped's privacy toggle to a specific card editor.
final class WeightNumbersOptIn {
  const WeightNumbersOptIn(this.journeyId);

  final String journeyId;
}

class _UriKeyedState implements GoRouterState {
  _UriKeyedState(this._base);

  final GoRouterState _base;

  @override
  ValueKey<String> get pageKey =>
      ValueKey<String>('${_base.pageKey.value}:${_base.uri}');

  @override
  Uri get uri => _base.uri;

  @override
  String get matchedLocation => _base.matchedLocation;

  @override
  String? get name => _base.name;

  @override
  String? get path => _base.path;

  @override
  String? get fullPath => _base.fullPath;

  @override
  Map<String, String> get pathParameters => _base.pathParameters;

  @override
  Object? get extra => _base.extra;

  @override
  GoException? get error => _base.error;

  @override
  GoRoute? get topRoute => _base.topRoute;

  @override
  Map<String, dynamic> get metadata => _base.metadata;

  @override
  String namedLocation(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    String? fragment,
  }) => _base.namedLocation(
    name,
    pathParameters: pathParameters,
    queryParameters: queryParameters,
    fragment: fragment,
  );
}

/// Share card feature (C2). Contract (lib/features/README.md): exports
/// `List<RouteBase> shareCardRoutes`; top-level paths start with `/share`.
/// Full screen. Build links with `AppRoutes.share(journeyId)`.
///
/// * `/share/:journeyId`  card preview, share sheet, solo public link
final List<RouteBase> shareCardRoutes = [
  GoRoute(
    path: '/share/:journeyId',
    pageBuilder: (context, state) {
      final q = state.uri.queryParameters;
      final journeyId = state.pathParameters['journeyId']!;
      final extra = state.extra;
      return buildUiPage(
        context: context,
        state: _UriKeyedState(state),
        kind: UiPageTransition.sharedZ,
        child: ShareCardScreen(
          journeyId: journeyId,
          initialFormat: q['format'] == 'feed'
              ? ShareCardFormat.feed
              : q['format'] == 'story'
              ? ShareCardFormat.story
              : null,
          initialBlur: bool.tryParse(q['blur'] ?? ''),
          initialHideBrand: bool.tryParse(q['hideBrand'] ?? ''),
          initialHideMetric: bool.tryParse(q['hideMetric'] ?? ''),
          weightNumbersOptIn:
              extra is WeightNumbersOptIn && extra.journeyId == journeyId,
        ),
      );
    },
  ),
];
