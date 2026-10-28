import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/navigator_keys.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/theme/app_theme.dart';
import 'package:ourney/features/social/data/social_providers.dart';
import 'package:ourney/features/social/routes.dart';
import 'package:ourney/features/social/social.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';

const me = 'me';

PersonSummary person(String id, {String? name}) => PersonSummary(
  userId: id,
  username: id,
  displayName: name ?? 'User ${id.toUpperCase()}',
);

Friendship friend(String id, {String? name}) => Friendship(
  person: person(id, name: name),
  status: FriendStatus.accepted,
  direction: FriendDirection.outgoing,
  source: FriendSource.direct,
  createdAt: DateTime(2026, 10, 1),
  acceptedAt: DateTime(2026, 10, 2),
);

Friendship request(
  String id, {
  FriendDirection direction = FriendDirection.incoming,
  FriendSource source = FriendSource.direct,
  String? journeyId,
  String? journeyTitle,
  String? name,
}) => Friendship(
  person: person(id, name: name),
  status: FriendStatus.pending,
  direction: direction,
  source: source,
  sourceJourneyId: journeyId,
  sourceJourneyTitle: journeyTitle,
  createdAt: DateTime(2026, 10, 20, 17, 30),
);

/// A value stream: replays the latest value to each new listener.
class _Live<T> {
  _Live(this.value);

  T value;
  final _changes = StreamController<T>.broadcast();

  Stream<T> watch() async* {
    yield value;
    yield* _changes.stream;
  }

  void set(T v) {
    value = v;
    _changes.add(v);
  }
}

class FakeFriendRepository implements FriendRepository {
  FakeFriendRepository([List<Friendship> initial = const []])
    : _list = _Live(List.of(initial));

  final _Live<List<Friendship>> _list;
  final Map<String, PersonSummary> directory = {};
  final List<String> calls = [];
  int invitesCreated = 0;
  Object? findError;
  Object? acceptInviteError;
  PersonSummary acceptInviteResult = person('inviter', name: 'Nam Tran');

  List<Friendship> get friendships => _list.value;

  void _replace(String userId, Friendship? next) => _list.set([
    for (final f in _list.value)
      if (f.person.userId != userId) f,
    ?next,
  ]);

  @override
  Stream<List<Friendship>> watchFriendships() => _list.watch();

  @override
  Future<PersonSummary?> findByUsername(String username) async {
    calls.add('find:$username');
    if (findError != null) throw findError!;
    return directory[username.toLowerCase()];
  }

  @override
  Future<void> sendRequest(String userId, {String? fromJourneyId}) async {
    calls.add('send:$userId');
    _replace(userId, request(userId, direction: FriendDirection.outgoing));
  }

  @override
  Future<void> respond(String userId, {required bool accept}) async {
    calls.add('${accept ? 'accept' : 'decline'}:$userId');
    final old = _list.value.firstWhere((f) => f.person.userId == userId);
    _replace(
      userId,
      accept ? friend(userId, name: old.person.displayName) : null,
    );
  }

  @override
  Future<void> remove(String userId) async {
    calls.add('remove:$userId');
    _replace(userId, null);
  }

  @override
  Future<String> createInvite() async {
    invitesCreated++;
    return 'tok$invitesCreated';
  }

  @override
  Future<PersonSummary> acceptInvite(String token) async {
    calls.add('acceptInvite:$token');
    if (acceptInviteError != null) throw acceptInviteError!;
    return acceptInviteResult;
  }
}

class FakeChatRepository implements ChatRepository {
  FakeChatRepository({
    List<Conversation> conversations = const [],
    Map<String, List<ChatMessage>> messages = const {},
  }) : _conversations = _Live(List.of(conversations)),
       _messages = {
         for (final e in messages.entries) e.key: _Live(List.of(e.value)),
       };

  final _Live<List<Conversation>> _conversations;
  final Map<String, _Live<List<ChatMessage>>> _messages;
  final List<String> calls = [];
  final List<List<int>> photos = [];
  var _seq = 0;

  _Live<List<ChatMessage>> _thread(String id) =>
      _messages.putIfAbsent(id, () => _Live(<ChatMessage>[]));

  @override
  Stream<List<Conversation>> watchConversations() => _conversations.watch();

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) =>
      _thread(conversationId).watch();

  @override
  Future<String> openForReply(String journeyId, {String? checkInId}) async =>
      'c-new';

  ChatMessage _add(String id, MessageKind kind, {String? body, String? path}) {
    final m = ChatMessage(
      id: 'sent${_seq++}',
      conversationId: id,
      senderId: me,
      kind: kind,
      createdAt: DateTime.now(),
      body: body,
      mediaPath: path,
    );
    final t = _thread(id);
    t.set([...t.value, m]);
    return m;
  }

  @override
  Future<ChatMessage> sendText(
    String conversationId,
    String body, {
    String? replyToCheckInId,
  }) async {
    calls.add('text:$body');
    return _add(conversationId, MessageKind.text, body: body);
  }

  @override
  Future<ChatMessage> sendPhoto(
    String conversationId,
    List<int> jpegBytes, {
    String? body,
    String? replyToCheckInId,
  }) async {
    calls.add('photo:${jpegBytes.length}');
    photos.add(jpegBytes);
    return _add(conversationId, MessageKind.photo, path: 'messages/x.jpg');
  }

  @override
  Future<void> markRead(String conversationId) async =>
      calls.add('read:$conversationId');

  @override
  Future<void> clear(String conversationId) async {
    calls.add('clear:$conversationId');
    _conversations.set([
      for (final c in _conversations.value)
        if (c.id != conversationId) c,
    ]);
  }

  @override
  Future<void> hideMessage(String messageId) async {
    calls.add('hide:$messageId');
    for (final t in _messages.values) {
      t.set([
        for (final m in t.value)
          if (m.id != messageId) m,
      ]);
    }
  }
}

class FakeShareConsentRepository implements ShareConsentRepository {
  FakeShareConsentRepository([List<ShareConsent> pending = const []])
    : _pending = _Live(List.of(pending));

  final _Live<List<ShareConsent>> _pending;
  final List<String> calls = [];

  @override
  Stream<List<ShareConsent>> watchForJourney(String journeyId) =>
      const Stream.empty();

  @override
  Stream<List<ShareConsent>> watchMyPending() => _pending.watch();

  @override
  Future<void> request(String journeyId) async {}

  @override
  Future<void> respond(String journeyId, {required bool accept}) async {
    calls.add('${accept ? 'agree' : 'decline'}:$journeyId');
    _pending.set([
      for (final s in _pending.value)
        if (s.journeyId != journeyId) s,
    ]);
  }

  @override
  Future<void> withdraw(String journeyId) async {}
}

class FakeInsightsRepository implements InsightsRepository {
  FakeInsightsRepository([this.counts = emptyCounts]);

  static const emptyCounts = InboxCounts(
    friendRequests: 0,
    publicRequests: 0,
    newShares: 0,
    unreadMessages: 0,
    consentRequests: 0,
  );

  InboxCounts counts;

  @override
  Stream<InboxCounts> watchInboxCounts() => Stream.value(counts);

  @override
  Future<JourneyInsights> journeyInsights(String journeyId) =>
      throw UnimplementedError();

  @override
  Future<int> myReach() async => 0;
}

class FakeMediaStore implements MediaStore {
  @override
  Future<String> localFileFor(String storagePath) async =>
      '/nonexistent/$storagePath';
}

class FakeChatPhotoPicker implements ChatPhotoPicker {
  FakeChatPhotoPicker([this.bytes = const [1, 2, 3, 4]]);

  final List<int>? bytes;
  final List<bool> picks = [];

  @override
  Future<List<int>?> pick({required bool camera}) async {
    picks.add(camera);
    return bytes;
  }
}

ShareConsent consent(String journeyId, String title, String byId) =>
    ShareConsent(
      journeyId: journeyId,
      journeyTitle: title,
      member: person(me),
      status: ShareConsentStatus.pending,
      requestedBy: person(byId),
    );

Conversation conversation(
  String id, {
  String other = 'nam',
  String journey = 'Daily Reading',
  int unread = 0,
  bool readOnly = false,
  String? preview = 'hello',
}) => Conversation(
  id: id,
  journeyId: 'j-$id',
  journeyTitle: journey,
  other: person(other, name: 'Nam Tran'),
  unreadCount: unread,
  readOnly: readOnly,
  lastMessageAt: DateTime.now(),
  lastMessagePreview: preview,
  lastMessageKind: MessageKind.text,
);

/// Everything the social screens read, in one bag.
class SocialFakes {
  SocialFakes({
    FakeFriendRepository? friends,
    FakeChatRepository? chat,
    FakeShareConsentRepository? consents,
    FakeInsightsRepository? insights,
    FakeChatPhotoPicker? picker,
  }) : friends = friends ?? FakeFriendRepository(),
       chat = chat ?? FakeChatRepository(),
       consents = consents ?? FakeShareConsentRepository(),
       insights = insights ?? FakeInsightsRepository(),
       picker = picker ?? FakeChatPhotoPicker();

  final FakeFriendRepository friends;
  final FakeChatRepository chat;
  final FakeShareConsentRepository consents;
  final FakeInsightsRepository insights;
  final FakeChatPhotoPicker picker;
  final List<String> shared = [];
  final List<String> copied = [];

  List<Override> get overrides => [
    friendRepositoryProvider.overrideWithValue(friends),
    chatRepositoryProvider.overrideWithValue(chat),
    shareConsentRepositoryProvider.overrideWithValue(consents),
    insightsRepositoryProvider.overrideWithValue(insights),
    mediaStoreProvider.overrideWithValue(FakeMediaStore()),
    chatPhotoPickerProvider.overrideWithValue(picker),
    socialShareLauncherProvider.overrideWithValue((text) async {
      shared.add(text);
    }),
    socialClipboardProvider.overrideWithValue((text) async {
      copied.add(text);
    }),
  ];
}

/// Pumps the social routes at [location] (plus `/journeys` and a `/hub`
/// page holding the exported widgets) with the given fakes.
Future<GoRouter> pumpSocial(
  WidgetTester tester, {
  required String location,
  SocialFakes? fakes,
  bool localOnly = false,
  Brightness brightness = Brightness.light,
  double width = 390,
  double textScale = 1,
  Locale locale = const Locale('en'),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 760);
  addTearDown(tester.view.reset);
  final prefs = await testPrefs();
  final f = fakes ?? SocialFakes();
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: location,
    routes: [
      ...socialRoutes,
      GoRoute(
        path: '/journeys',
        builder: (_, _) => const Scaffold(body: Text('hub-journeys')),
      ),
      GoRoute(
        path: '/hub',
        builder: (_, _) => const Scaffold(
          body: SafeArea(
            child: Column(children: [InboxButton(), FriendsProfileTile()]),
          ),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(
          localOnly ? const AppConfig.localOnly() : testBackendConfig,
        ),
        sharedPreferencesProvider.overrideWithValue(prefs),
        supabaseClientProvider.overrideWithValue(null),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(userId: me),
        ),
        ...f.overrides,
      ],
      child: MaterialApp.router(
        theme: buildAppTheme(brightness),
        locale: locale,
        localizationsDelegates: ourneyLocalizationsDelegates,
        supportedLocales: ourneySupportedLocales,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
