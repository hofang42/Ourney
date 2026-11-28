import 'package:flutter/widgets.dart' show ValueKey;
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart' show JourneyFrame;

import '../../app/app_routes.dart';
import '../../app/navigator_keys.dart';
import '../../ui/ui.dart';
import 'ui/create_journey_screen.dart';
import 'ui/day_viewer_screen.dart';
import 'ui/edit/journey_edit_screen.dart';
import 'ui/journey_detail_screen.dart';
import 'ui/journeys_list_screen.dart';
import 'ui/template_picker_screen.dart';
import 'ui/wrapped/journey_wrapped_screen.dart';

/// Wraps [GoRouterState] with a URI-scoped [pageKey] so parameterized routes
/// (`/journey/:id`, `/journey/:id/day/:date`, `/journeys/new/:template`)
/// always mount a fresh page when their path or query parameters change.
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

/// Journeys feature (B4). Contract (lib/features/README.md): exports
/// `List<RouteBase> journeysRoutes`; top-level paths start with `/journeys`
/// or `/journey`. They live in the Journeys tab of the shell.
///
/// * `/journeys`                   list (tab root)
/// * `/journeys/new`               template picker (full screen)
/// * `/journeys/new/:template`     create form, `:template` = wire name
/// * `/journey/:id`                detail + timeline (`ourney://journey/<id>`)
/// * `/journey/:id/day/:date`      photo viewer, `:date` = YYYY-MM-DD
/// * `/journey/:id/edit`           edit journey (owner)
/// * `/journey/:id/wrapped`        end-of-journey story
///
/// Build links with `AppRoutes` / `JourneysPaths` (journeys_paths.dart).
final List<RouteBase> journeysRoutes = [
  GoRoute(
    path: AppRoutes.journeys,
    builder: (context, state) => JourneysListScreen(
      initialSegment: JourneysListScreen.parseSegment(
        state.uri.queryParameters['segment'],
      ),
    ),
    routes: [
      GoRoute(
        path: 'new',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildUiPage(
          context: context,
          state: _UriKeyedState(state),
          kind: UiPageTransition.sharedZ,
          child: TemplatePickerScreen(
            resume: state.uri.queryParameters['resume'] == '1',
            initialWho: TemplatePickerScreen.parseWho(
              state.uri.queryParameters['who'],
            ),
            inviteHandle: state.uri.queryParameters['invite'],
          ),
        ),
        routes: [
          GoRoute(
            path: ':template',
            parentNavigatorKey: rootNavigatorKey,
            pageBuilder: (context, state) {
              final raw = state.pathParameters['template'];
              return buildUiPage(
                context: context,
                state: _UriKeyedState(state),
                kind: UiPageTransition.sharedX,
                child: CreateJourneyScreen(
                  templateId: CreateJourneyScreen.parseTemplate(raw),
                  isCouplePreset: CreateJourneyScreen.isCoupleWire(raw),
                  // "Do this journey" (SCR-87) hands its frame over.
                  frame: state.extra is JourneyFrame
                      ? state.extra! as JourneyFrame
                      : null,
                  openMoreOptions: state.uri.queryParameters['more'] == '1',
                ),
              );
            },
          ),
        ],
      ),
    ],
  ),
  GoRoute(
    path: '/journey/:id',
    pageBuilder: (context, state) => buildUiPage(
      context: context,
      state: _UriKeyedState(state),
      kind: UiPageTransition.sharedZ,
      child: JourneyDetailScreen(journeyId: state.pathParameters['id']!),
    ),
    routes: [
      GoRoute(
        path: 'wrapped',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildUiPage(
          context: context,
          state: _UriKeyedState(state),
          kind: UiPageTransition.verticalSheet,
          child: JourneyWrappedScreen(journeyId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: 'edit',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildUiPage(
          context: context,
          state: _UriKeyedState(state),
          kind: UiPageTransition.sharedZ,
          child: JourneyEditScreen(journeyId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: 'day/:date',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildUiPage(
          context: context,
          state: _UriKeyedState(state),
          kind: UiPageTransition.sharedZ,
          opaque: false,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: UiMotion.sheetExit,
          child: DayViewerScreen(
            journeyId: state.pathParameters['id']!,
            date: DayViewerScreen.parseDate(state.pathParameters['date']),
            editCaption: state.uri.queryParameters['caption'] == 'edit',
          ),
        ),
      ),
    ],
  ),
];
