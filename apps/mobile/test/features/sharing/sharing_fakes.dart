import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/checkin/photo_compressor.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney/features/sharing/data/sharing_providers.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import '../journeys/journeys_fakes.dart';

export '../journeys/journeys_fakes.dart';

PersonSummary person(String id, [String? name]) =>
    PersonSummary(userId: id, username: id, displayName: name ?? 'Friend $id');

class _Live<T> {
  _Live(this.value);
  T value;
  final _changes = StreamController<T>.broadcast();
  void set(T v) {
    value = v;
    _changes.add(v);
  }

  Stream<T> watch() async* {
    yield value;
    yield* _changes.stream;
  }
}

class FakeSharingRepository implements SharingRepository {
  FakeSharingRepository({
    List<PersonSummary> viewers = const [],
    String? token,
    List<SharedJourneySummary> sharedWithMe = const [],
    this.view,
    this.frame,
  }) : _state = _Live(
         JourneyShareState(
           journeyId: 'j1',
           viewers: viewers,
           story: const JourneyStory(),
           publicSettings: const PublicSettings(
             showCounts: false,
             allowPublicReactions: true,
             allowViewerRequests: true,
           ),
           hiddenCheckInIds: const {},
           publicToken: token,
         ),
       ),
       _shared = _Live(List.of(sharedWithMe));

  final _Live<JourneyShareState> _state;
  final _Live<List<SharedJourneySummary>> _shared;
  SharedJourneyView? view;
  JourneyFrame? frame;
  final List<String> calls = [];
  Object? shareError;
  Object? linkError;
  Object? viewError;
  JourneyStory? savedStory;
  ImportedJourneyDraft? importedDraft;

  JourneyShareState get state => _state.value;

  void _setState({
    List<PersonSummary>? viewers,
    String? token,
    bool clearToken = false,
    Set<String>? hidden,
  }) {
    final s = _state.value;
    _state.set(
      JourneyShareState(
        journeyId: s.journeyId,
        viewers: viewers ?? s.viewers,
        story: savedStory ?? s.story,
        publicSettings: s.publicSettings,
        hiddenCheckInIds: hidden ?? s.hiddenCheckInIds,
        publicToken: clearToken ? null : (token ?? s.publicToken),
      ),
    );
  }

  @override
  Stream<JourneyShareState> watchShareState(String journeyId) => _state.watch();

  @override
  Future<void> shareWithFriends(
    String journeyId,
    List<String> friendIds,
  ) async {
    calls.add('share:${(List.of(friendIds)..sort()).join(',')}');
    if (shareError case final e?) throw e;
    _setState(
      viewers: [...state.viewers, for (final id in friendIds) person(id)],
    );
  }

  @override
  Future<void> unshare(
    String journeyId, {
    String? friendId,
    bool all = false,
  }) async {
    calls.add('unshare:${friendId ?? ''}:$all');
    _setState(
      viewers: [
        for (final v in state.viewers)
          if (friendId != null && v.userId != friendId) v,
      ],
    );
  }

  @override
  Future<void> updateStory(String journeyId, JourneyStory story) async {
    calls.add('story');
    savedStory = story;
  }

  @override
  Future<void> updatePublicSettings(
    String journeyId,
    PublicSettings settings,
  ) async {
    calls.add('public:${settings.showCounts}');
  }

  @override
  Future<void> setHiddenInShare(
    String checkInId, {
    required bool hidden,
  }) async {
    calls.add('hide:$checkInId:$hidden');
  }

  @override
  Future<String?> setPublicLink(
    String journeyId, {
    required bool enabled,
    bool reset = false,
  }) async {
    calls.add('link:$enabled:$reset');
    if (linkError case final e?) throw e;
    _setState(token: enabled ? 'tok' : null, clearToken: !enabled);
    return enabled ? 'tok' : null;
  }

  @override
  Stream<List<SharedJourneySummary>> watchSharedWithMe() => _shared.watch();

  @override
  Future<SharedJourneyView> openShared(String journeyId) async {
    calls.add('open:$journeyId');
    if (viewError case final e?) throw e;
    return view!;
  }

  @override
  Future<SharedJourneyView> openPublic(String token) async {
    calls.add('public-open:$token');
    if (viewError case final e?) throw e;
    return view!;
  }

  @override
  Future<void> like(String checkInId) async => calls.add('like:$checkInId');

  @override
  Future<void> unlike(String checkInId) async => calls.add('unlike:$checkInId');

  @override
  Future<void> unsave(String journeyId) async {
    calls.add('unsave:$journeyId');
    _shared.set([
      for (final s in _shared.value)
        if (s.journeyId != journeyId) s,
    ]);
  }

  @override
  Future<JourneyFrame> followFrame(String journeyId) async => frame!;

  @override
  Future<void> markFollowed(
    String newJourneyId,
    String sourceJourneyId,
  ) async => calls.add('followed:$newJourneyId:$sourceJourneyId');

  @override
  Future<Journey> createImported(ImportedJourneyDraft draft) async {
    calls.add('imported');
    importedDraft = draft;
    return Journey(
      id: 'imp1',
      ownerId: 'u1',
      kind: JourneyKind.solo,
      templateId: draft.templateId,
      title: draft.title,
      emoji: draft.emoji,
      startDate: draft.firstDate,
      durationDays: draft.firstDate.daysUntil(draft.lastDate) + 1,
      timezone: draft.timezone,
      visibility: JourneyVisibility.private,
      status: JourneyStatus.ended,
    );
  }
}

class FakeFriendRepository implements FriendRepository {
  FakeFriendRepository(List<PersonSummary> friends)
    : _friends = [
        for (final f in friends)
          Friendship(
            person: f,
            status: FriendStatus.accepted,
            direction: FriendDirection.outgoing,
            source: FriendSource.direct,
            createdAt: DateTime.utc(2026),
          ),
      ];

  final List<Friendship> _friends;
  final List<String> requests = [];

  @override
  Stream<List<Friendship>> watchFriendships() => Stream.value(_friends);

  @override
  Future<void> sendRequest(String userId, {String? fromJourneyId}) async =>
      requests.add('$userId:$fromJourneyId');

  @override
  Future<PersonSummary?> findByUsername(String username) async => null;
  @override
  Future<void> respond(String userId, {required bool accept}) async {}
  @override
  Future<void> remove(String userId) async {}
  @override
  Future<String> createInvite() async => 'x';
  @override
  Future<PersonSummary> acceptInvite(String token) async => person('x');
}

class FakeShareConsentRepository implements ShareConsentRepository {
  FakeShareConsentRepository([this.consents = const []]);

  List<ShareConsent> consents;
  final List<String> calls = [];

  @override
  Stream<List<ShareConsent>> watchForJourney(String journeyId) =>
      Stream.value(consents);
  @override
  Stream<List<ShareConsent>> watchMyPending() => Stream.value(const []);
  @override
  Future<void> request(String journeyId) async =>
      calls.add('request:$journeyId');
  @override
  Future<void> respond(String journeyId, {required bool accept}) async {}
  @override
  Future<void> withdraw(String journeyId) async => calls.add('withdraw');
}

class FakeInsightsRepository implements InsightsRepository {
  FakeInsightsRepository([this.insights]);

  JourneyInsights? insights;

  @override
  Future<JourneyInsights> journeyInsights(String journeyId) async => insights!;
  @override
  Stream<InboxCounts> watchInboxCounts() => const Stream.empty();
  @override
  Future<int> myReach() async => 0;
}

class FakeChatRepository implements ChatRepository {
  final List<String> opened = [];

  @override
  Future<String> openForReply(String journeyId, {String? checkInId}) async {
    opened.add('$journeyId:$checkInId');
    return 'conv1';
  }

  @override
  Stream<List<Conversation>> watchConversations() => const Stream.empty();
  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) =>
      const Stream.empty();
  @override
  Future<ChatMessage> sendText(
    String conversationId,
    String body, {
    String? replyToCheckInId,
  }) => throw UnimplementedError();
  @override
  Future<ChatMessage> sendPhoto(
    String conversationId,
    List<int> jpegBytes, {
    String? body,
    String? replyToCheckInId,
  }) => throw UnimplementedError();
  @override
  Future<void> markRead(String conversationId) async {}
  @override
  Future<void> clear(String conversationId) async {}
  @override
  Future<void> hideMessage(String messageId) async {}
}

/// Check-ins whose `submit` works (retell).
class SubmittingCheckInRepository extends FakeCheckInRepository {
  final List<CheckInDraft> submitted = [];

  @override
  Future<CheckIn> submit(CheckInDraft draft) async {
    submitted.add(draft);
    return CheckIn(
      id: 'c${submitted.length}',
      journeyId: draft.journeyId,
      userId: 'u1',
      localDate: const LocalDate(2026, 1, 1),
      capturedAt: draft.capturedAt,
      photoPath: 'p',
      thumbPath: 't',
    );
  }
}

class FakeCompressor implements PhotoCompressor {
  @override
  Future<CompressedPhoto> compress(String sourcePath) async =>
      CompressedPhoto(photoFile: '$sourcePath.c', thumbFile: '$sourcePath.t');
}

class NoopDrafts implements DraftFiles {
  @override
  Future<void> discard(Iterable<String> paths) async {}
}

class FakeRetellPicker implements RetellPhotoPicker {
  FakeRetellPicker(this.photos);
  final List<RetellPhoto> photos;
  @override
  Future<List<RetellPhoto>> pickPhotos() async => photos;
}

class SharingHarness {
  SharingHarness(this.container);
  final ProviderContainer container;
  String get location => container.read(routerProvider).state.uri.toString();
  Future<void> go(WidgetTester tester, String path) async {
    container.read(routerProvider).go(path);
    await tester.pumpAndSettle();
  }
}

/// Real app, backend configured, signed in as `u1`, fake repositories.
Future<SharingHarness> pumpSharing(
  WidgetTester tester, {
  required String location,
  FakeSharingRepository? sharing,
  FakeJourneyRepository? journeys,
  FakeCheckInRepository? checkIns,
  List<PersonSummary> friends = const [],
  FakeShareConsentRepository? consents,
  FakeInsightsRepository? insights,
  FakeChatRepository? chat,
  FakeFriendRepository? friendRepo,
  RetellPhotoPicker? picker,
  AppConfig config = testBackendConfig,
  Locale locale = const Locale('en'),
  Size size = const Size(420, 1800),
  double textScale = 1,
  Brightness? brightness,
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  if (brightness != null) {
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  }
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final container = await pumpOurneyApp(
    tester,
    config: config,
    locale: locale,
    auth: config.localOnly ? null : FakeAuthRepository(userId: 'u1'),
    overrides: [
      sharingRepositoryProvider.overrideWithValue(
        sharing ?? FakeSharingRepository(),
      ),
      journeyRepositoryProvider.overrideWithValue(
        journeys ?? FakeJourneyRepository(),
      ),
      checkInRepositoryProvider.overrideWithValue(
        checkIns ?? FakeCheckInRepository(),
      ),
      friendRepositoryProvider.overrideWithValue(
        friendRepo ?? FakeFriendRepository(friends),
      ),
      shareConsentRepositoryProvider.overrideWithValue(
        consents ?? FakeShareConsentRepository(),
      ),
      insightsRepositoryProvider.overrideWithValue(
        insights ?? FakeInsightsRepository(),
      ),
      chatRepositoryProvider.overrideWithValue(chat ?? FakeChatRepository()),
      mediaStoreProvider.overrideWithValue(FakeMediaStore()),
      journeysClockProvider.overrideWithValue(Clock.fixed(testNow)),
      deviceTimezoneProvider.overrideWith((ref) => testTz),
      photoCompressorProvider.overrideWithValue(FakeCompressor()),
      draftFilesProvider.overrideWithValue(NoopDrafts()),
      retellPhotoPickerProvider.overrideWithValue(
        picker ?? FakeRetellPicker(const []),
      ),
    ],
  );
  final h = SharingHarness(container);
  await h.go(tester, location);
  return h;
}

JourneyInsights testInsights() => JourneyInsights(
  journeyId: 'j1',
  views: 1200,
  viewsByDay: const [
    DailyCount(LocalDate(2026, 10, 14), 12),
    DailyCount(LocalDate(2026, 10, 15), 40),
  ],
  likesFromFriends: 42,
  likesFromStrangers: 298,
  started: 28,
  viewsThisWeek: 56,
  likesThisWeek: 21,
  startedThisWeek: 3,
  likers: [person('l1', 'Ha Vu')],
);

SharedJourneyView testView({
  ViewerRole role = ViewerRole.friend,
  JourneyOrigin origin = JourneyOrigin.live,
  bool canReply = true,
  bool canAddOwner = false,
  bool canFollow = true,
  int? likeCount,
  int? followCount,
  bool blurred = false,
}) => SharedJourneyView(
  journeyId: 'j1',
  role: role,
  title: 'Da Lat',
  emoji: '✈️',
  templateId: TemplateId.travel,
  kind: JourneyKind.solo,
  origin: origin,
  status: JourneyStatus.ended,
  owner: person('o1', 'Ha Vu'),
  members: [person('o1', 'Ha Vu')],
  story: const JourneyStory(
    title: 'Da Lat in 5 photos',
    intro: 'Five cool moments.',
    lessons: 'Slow down.',
  ),
  photos: [
    SharedPhoto(
      checkInId: 'p1',
      author: person('o1', 'Ha Vu'),
      localDate: const LocalDate(2026, 10, 1),
      photoPath: 'a',
      thumbPath: 'a_t',
      likeCount: 2,
      likedByMe: false,
      blurred: blurred,
    ),
  ],
  durationDays: 5,
  startDate: const LocalDate(2026, 10, 1),
  currentStreak: origin == JourneyOrigin.imported ? null : 5,
  likeCount: likeCount,
  followCount: followCount,
  canReact: true,
  canReply: canReply,
  canFollow: canFollow,
  canAddOwner: canAddOwner,
  saved: false,
);
