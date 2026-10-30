// Social contract v1.3 (docs/09-journey-sharing.md S1–S40,
// docs/contracts/sharing.md). Friends, journey sharing, shared-with-me,
// story, follow-along ("Do this journey"), retold (imported) journeys,
// chat, group share consents and insights.
//
// Wire values cross the boundary through `wireName` / `fromWire` only.

import '../models.dart';

T _fromWire<T extends Enum>(
        List<T> values, String wire, String Function(T) name) =>
    values.firstWhere((v) => name(v) == wire,
        orElse: () => throw FormatException('unknown wire value', wire));

// --- enums ------------------------------------------------------------------

/// `journeys.origin`: lived in the app, or retold from old photos (S12).
enum JourneyOrigin {
  live('live'),
  imported('imported');

  const JourneyOrigin(this.wireName);
  final String wireName;
  static JourneyOrigin fromWire(String wire) =>
      _fromWire(values, wire, (v) => v.wireName);
}

/// `friendships.status`.
enum FriendStatus {
  pending('pending'),
  accepted('accepted');

  const FriendStatus(this.wireName);
  final String wireName;
  static FriendStatus fromWire(String wire) =>
      _fromWire(values, wire, (v) => v.wireName);
}

/// Who sent a pending request, seen from the caller.
enum FriendDirection {
  incoming('incoming'),
  outgoing('outgoing');

  const FriendDirection(this.wireName);
  final String wireName;
  static FriendDirection fromWire(String wire) =>
      _fromWire(values, wire, (v) => v.wireName);
}

/// `friendships.source` (S27): a direct request, or one sent from a public
/// journey page (shown under "From your public journeys", no red dot).
enum FriendSource {
  direct('direct'),
  publicJourney('public_journey');

  const FriendSource(this.wireName);
  final String wireName;
  static FriendSource fromWire(String wire) =>
      _fromWire(values, wire, (v) => v.wireName);
}

/// `journey_share_consents.status` (S29–S31).
enum ShareConsentStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  withdrawn('withdrawn');

  const ShareConsentStatus(this.wireName);
  final String wireName;
  static ShareConsentStatus fromWire(String wire) =>
      _fromWire(values, wire, (v) => v.wireName);
}

/// `messages.kind`. `clip` is v0.2 and not sent by v1 clients.
enum MessageKind {
  text('text'),
  photo('photo');

  const MessageKind(this.wireName);
  final String wireName;
  static MessageKind fromWire(String wire) =>
      _fromWire(values, wire, (v) => v.wireName);
}

/// How the caller sees a shared journey (docs/09 §4).
enum ViewerRole {
  /// Owner or active member: everything.
  member('member'),

  /// A friend the journey was shared with (S13): react, reply by photo.
  friend('friend'),

  /// Signed-in stranger who opened the public link (S24): react when
  /// allowed, Do this journey, Add friend when allowed. No replies.
  stranger('stranger');

  const ViewerRole(this.wireName);
  final String wireName;
  static ViewerRole fromWire(String wire) =>
      _fromWire(values, wire, (v) => v.wireName);
}

// --- friends ----------------------------------------------------------------

/// Another user as the caller may see them (friend, request, search hit).
class PersonSummary {
  const PersonSummary(
      {required this.userId,
      required this.username,
      required this.displayName,
      this.avatarPath});

  final String userId;
  final String username;
  final String displayName;
  final String? avatarPath;
}

/// One row of `my_friends()`: an accepted friend or a pending request.
class Friendship {
  const Friendship({
    required this.person,
    required this.status,
    required this.direction,
    required this.source,
    required this.createdAt,
    this.sourceJourneyId,
    this.sourceJourneyTitle,
    this.acceptedAt,
  });

  final PersonSummary person;
  final FriendStatus status;

  /// Who sent the request (meaningful while [status] is pending).
  final FriendDirection direction;
  final FriendSource source;

  /// Public journey the request came from (S27).
  final String? sourceJourneyId;
  final String? sourceJourneyTitle;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  bool get isFriend => status == FriendStatus.accepted;
  bool get isIncomingRequest =>
      status == FriendStatus.pending && direction == FriendDirection.incoming;
}

/// Friends, requests and invite links (S2–S4, S27, S39).
abstract interface class FriendRepository {
  /// Accepted friends and pending requests in both directions, newest first.
  Stream<List<Friendship>> watchFriendships();

  /// Exact, case-insensitive @username match; null when none (S3).
  /// Rate limited like `join_by_code` (`rate_limited`).
  Future<PersonSummary?> findByUsername(String username);

  /// Sends a request. When [fromJourneyId] is set the request comes from a
  /// public journey page (S27, max 20 per sender per day → `rate_limited`,
  /// `forbidden` when the journey does not allow viewer requests).
  /// Accepts at once when the other user already asked the caller.
  Future<void> sendRequest(String userId, {String? fromJourneyId});

  /// Accept or decline an incoming request.
  Future<void> respond(String userId, {required bool accept});

  /// Unfriend, or cancel an outgoing request. Revokes every journey share
  /// between the two people (docs/09 §4).
  Future<void> remove(String userId);

  /// A new invite token for the caller's link / QR (`ourney://friend/<t>`,
  /// `https://<host>/f/<t>`). Rotating kills the previous token.
  Future<String> createInvite();

  /// Opens someone's invite: both become friends at once (the inviter
  /// consented by sharing the link). Returns the inviter.
  /// `not_found` for an unknown or rotated token, `invalid` for your own.
  Future<PersonSummary> acceptInvite(String token);
}

// --- sharing ----------------------------------------------------------------

/// Story written before sharing (S11).
class JourneyStory {
  const JourneyStory(
      {this.title, this.intro, this.lessons, this.coverCheckInId});

  final String? title;
  final String? intro;
  final String? lessons;
  final String? coverCheckInId;

  bool get isEmpty =>
      title == null &&
      intro == null &&
      lessons == null &&
      coverCheckInId == null;
}

/// Public-side switches of a journey (S22, S25, S27). Defaults follow S28.
class PublicSettings {
  const PublicSettings({
    required this.showCounts,
    required this.allowPublicReactions,
    required this.allowViewerRequests,
  });

  final bool showCounts;
  final bool allowPublicReactions;
  final bool allowViewerRequests;
}

/// The owner's (or a member's own) view of who a journey is shared with.
class JourneyShareState {
  const JourneyShareState({
    required this.journeyId,
    required this.viewers,
    required this.story,
    required this.publicSettings,
    required this.hiddenCheckInIds,
    this.publicToken,
  });

  final String journeyId;

  /// Friends the caller granted access to (their own grants, S32).
  final List<PersonSummary> viewers;
  final JourneyStory story;
  final PublicSettings publicSettings;

  /// Check-ins hidden from every share (S11).
  final Set<String> hiddenCheckInIds;
  final String? publicToken;

  bool get linkOn => publicToken != null;
}

/// One entry of the Hub's "Shared with me" segment (S8, S26).
class SharedJourneySummary {
  const SharedJourneySummary({
    required this.journeyId,
    required this.title,
    required this.emoji,
    required this.templateId,
    required this.kind,
    required this.origin,
    required this.status,
    required this.owner,
    required this.sharedBy,
    required this.sharedAt,
    required this.photoCount,
    required this.saved,
    required this.unseen,
    this.firstDate,
    this.lastDate,
    this.coverThumbPath,
  });

  final String journeyId;
  final String title;
  final String emoji;
  final TemplateId templateId;
  final JourneyKind kind;
  final JourneyOrigin origin;
  final JourneyStatus status;
  final PersonSummary owner;

  /// The member whose grant gives the caller access (earliest active, S33).
  /// For a saved public journey (S26) this is the owner.
  final PersonSummary sharedBy;
  final DateTime sharedAt;
  final int photoCount;

  /// From a stranger's like on a public link (S26), not a friend grant.
  final bool saved;

  /// Shared and not opened yet (inbox dot).
  final bool unseen;
  final LocalDate? firstDate;
  final LocalDate? lastDate;
  final String? coverThumbPath;
}

/// One photo as a viewer sees it (hidden-in-share and non-consenting
/// authors are never returned to non-members, S11/S30).
class SharedPhoto {
  const SharedPhoto({
    required this.checkInId,
    required this.author,
    required this.localDate,
    required this.photoPath,
    required this.thumbPath,
    required this.likeCount,
    required this.likedByMe,
    this.caption,
    this.metricValue,
    this.blurred = false,
  });

  final String checkInId;
  final PersonSummary author;
  final LocalDate localDate;
  final String photoPath;
  final String thumbPath;
  final String? caption;

  /// Null when hidden (owner's `hide_metric`, S11).
  final double? metricValue;

  /// Only the viewer's own count when `show_counts` is off and they are not
  /// a member; members always get the real count.
  final int likeCount;
  final bool likedByMe;

  /// Author asked to blur photos on outside shares (`blur_media`).
  final bool blurred;
}

/// What can be copied by "Do this journey" (S15): never photos or values.
class JourneyFrame {
  const JourneyFrame({
    required this.sourceJourneyId,
    required this.templateId,
    required this.kind,
    required this.title,
    required this.emoji,
    required this.ownerName,
    this.durationDays,
    this.metricName,
    this.metricUnit,
  });

  final String sourceJourneyId;
  final TemplateId templateId;
  final JourneyKind kind;
  final String title;
  final String emoji;

  /// Shown as "Based on {name}'s journey" (S36).
  final String ownerName;
  final int? durationDays;
  final String? metricName;
  final String? metricUnit;
}

/// A journey as one viewer sees it (SCR-84). Built by `shared_journey(id)`
/// for friends / members, or `public_journey_by_token(token)` for a
/// signed-in stranger with the link. Both record a view (S19).
class SharedJourneyView {
  const SharedJourneyView({
    required this.journeyId,
    required this.role,
    required this.title,
    required this.emoji,
    required this.templateId,
    required this.kind,
    required this.origin,
    required this.status,
    required this.owner,
    required this.members,
    required this.story,
    required this.photos,
    required this.canReact,
    required this.canReply,
    required this.canFollow,
    required this.canAddOwner,
    required this.saved,
    this.durationDays,
    this.startDate,
    this.currentStreak,
    this.likeCount,
    this.followCount,
    this.metricName,
    this.metricUnit,
    this.sharedBy,
  });

  final String journeyId;
  final ViewerRole role;
  final String title;
  final String emoji;
  final TemplateId templateId;
  final JourneyKind kind;
  final JourneyOrigin origin;
  final JourneyStatus status;
  final PersonSummary owner;

  /// Group: members who consented (S34). Solo: just the owner.
  final List<PersonSummary> members;
  final JourneyStory story;

  /// Oldest first.
  final List<SharedPhoto> photos;
  final int? durationDays;
  final LocalDate? startDate;

  /// Never for imported journeys (S12) or strangers on groups (S34).
  final int? currentStreak;

  /// Only when `show_counts` (S22) or the caller is a member.
  final int? likeCount;
  final int? followCount;
  final String? metricName;
  final String? metricUnit;

  /// Grant that gives a friend access (reply target, S33).
  final PersonSummary? sharedBy;
  final bool canReact;
  final bool canReply;

  /// Ended / shelf journeys only (S9).
  final bool canFollow;

  /// Stranger + `allow_viewer_requests` + not already friends (S24, S27).
  final bool canAddOwner;

  /// In the caller's Shared with me → Saved (S26).
  final bool saved;
}

/// Sharing, story, follow-along and retold journeys.
abstract interface class SharingRepository {
  /// Share state of a journey for its owner / a member (SCR-82).
  Stream<JourneyShareState> watchShareState(String journeyId);

  /// Grants the given friends access (the caller's own grants, S32).
  /// `forbidden` for a non-friend; `consent_required` when a group member
  /// has not asked the group yet (S29).
  Future<void> shareWithFriends(String journeyId, List<String> friendIds);

  /// Revokes the caller's grant for [friendId], or every grant of the caller
  /// when null. Group owner with [all]: revoke everyone's grants and turn
  /// the link off ("Stop sharing", S18).
  Future<void> unshare(String journeyId, {String? friendId, bool all = false});

  /// Story and public switches (owner / group owner, S11, S22–S28).
  Future<void> updateStory(String journeyId, JourneyStory story);
  Future<void> updatePublicSettings(String journeyId, PublicSettings settings);

  /// Hide / show one of the caller's check-ins in every share (S11).
  Future<void> setHiddenInShare(String checkInId, {required bool hidden});

  /// Turns the public link on / off or rotates it ("Reset link"). Only for
  /// ended journeys or imported ones on the shelf (S9) → else `invalid`;
  /// `forbidden` under 18 (R2-07) or for non-owners. Returns the token.
  Future<String?> setPublicLink(String journeyId,
      {required bool enabled, bool reset = false});

  /// Hub → Shared with me, newest first (friend grants + saved, S8, S26).
  Stream<List<SharedJourneySummary>> watchSharedWithMe();

  /// SCR-84 for a friend / member (records a view, marks the share seen).
  /// `forbidden` → "This journey is private now".
  Future<SharedJourneyView> openShared(String journeyId);

  /// SCR-84 in the app for a signed-in stranger with the link.
  Future<SharedJourneyView> openPublic(String token);

  /// Like / unlike a photo as a viewer (S13, S23–S26). A stranger's like
  /// saves the journey; removing the last one unsaves it.
  Future<void> like(String checkInId);
  Future<void> unlike(String checkInId);

  /// Removes a saved public journey from Shared with me (S26).
  Future<void> unsave(String journeyId);

  /// Frame for "Do this journey" (S15). Ended / shelf journeys only.
  Future<JourneyFrame> followFrame(String journeyId);

  /// Records that [newJourneyId] (the caller's) was started from
  /// [sourceJourneyId] (counts as "started", S19).
  Future<void> markFollowed(String newJourneyId, String sourceJourneyId);

  /// Creates a retold journey on the shelf (S1, S12): `origin = imported`,
  /// `status = ended`, dates from the photos. Check-ins are then added with
  /// `CheckInRepository.submit` (the 3-day rule does not apply to it).
  Future<Journey> createImported(ImportedJourneyDraft draft);
}

/// Retell a past journey (SCR-28).
class ImportedJourneyDraft {
  const ImportedJourneyDraft({
    required this.id,
    required this.title,
    required this.emoji,
    required this.templateId,
    required this.firstDate,
    required this.lastDate,
    required this.timezone,
    this.metricName,
    this.metricUnit,
  });

  final String id;
  final String title;
  final String emoji;
  final TemplateId templateId;
  final LocalDate firstDate;
  final LocalDate lastDate;
  final String timezone;
  final String? metricName;
  final String? metricUnit;
}

// --- group consents (S29–S31) ------------------------------------------------

class ShareConsent {
  const ShareConsent({
    required this.journeyId,
    required this.journeyTitle,
    required this.member,
    required this.status,
    required this.requestedBy,
    this.decidedAt,
  });

  final String journeyId;
  final String journeyTitle;
  final PersonSummary member;
  final ShareConsentStatus status;
  final PersonSummary requestedBy;
  final DateTime? decidedAt;
}

abstract interface class ShareConsentRepository {
  /// Consents of every member of a group journey.
  Stream<List<ShareConsent>> watchForJourney(String journeyId);

  /// The caller's pending consent requests across journeys (inbox).
  Stream<List<ShareConsent>> watchMyPending();

  /// Any member asks the others (S29); the caller is accepted at once.
  Future<void> request(String journeyId);
  Future<void> respond(String journeyId, {required bool accept});

  /// "Remove my photos from sharing" (S31).
  Future<void> withdraw(String journeyId);
}

// --- chat (S16–S17, S37) -----------------------------------------------------

class Conversation {
  const Conversation({
    required this.id,
    required this.journeyId,
    required this.journeyTitle,
    required this.other,
    required this.unreadCount,
    required this.readOnly,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.lastMessageKind,
  });

  final String id;
  final String journeyId;
  final String journeyTitle;
  final PersonSummary other;
  final int unreadCount;

  /// No longer friends / blocked (docs/09 §4): history only.
  final bool readOnly;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final MessageKind? lastMessageKind;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.kind,
    required this.createdAt,
    this.body,
    this.mediaPath,
    this.replyToCheckInId,
    this.replyToThumbPath,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final MessageKind kind;
  final DateTime createdAt;
  final String? body;

  /// `messages/{conversation_id}/{sender_id}/{id}.jpg`.
  final String? mediaPath;
  final String? replyToCheckInId;
  final String? replyToThumbPath;
}

abstract interface class ChatRepository {
  /// Caller's conversations (not cleared), newest first.
  Stream<List<Conversation>> watchConversations();

  /// Messages after the caller's cleared mark, minus hidden ones, oldest
  /// first. Realtime while subscribed.
  Stream<List<ChatMessage>> watchMessages(String conversationId);

  /// Opens (or reuses) the conversation for replying to a photo of a shared
  /// journey; the recipient follows S33. Friends only → `forbidden`.
  Future<String> openForReply(String journeyId, {String? checkInId});

  Future<ChatMessage> sendText(String conversationId, String body,
      {String? replyToCheckInId});

  /// Uploads [jpegBytes] then sends a photo message.
  Future<ChatMessage> sendPhoto(String conversationId, List<int> jpegBytes,
      {String? body, String? replyToCheckInId});

  Future<void> markRead(String conversationId);

  /// "Delete conversation" for the caller only (S37).
  Future<void> clear(String conversationId);

  /// "Delete for me" on one message.
  Future<void> hideMessage(String messageId);
}

// --- inbox & insights --------------------------------------------------------

/// Counts behind the Hub inbox dot (S16, S27: public-journey requests do
/// not light the dot).
class InboxCounts {
  const InboxCounts({
    required this.friendRequests,
    required this.publicRequests,
    required this.newShares,
    required this.unreadMessages,
    required this.consentRequests,
  });

  final int friendRequests;
  final int publicRequests;
  final int newShares;
  final int unreadMessages;
  final int consentRequests;

  bool get hasDot =>
      friendRequests + newShares + unreadMessages + consentRequests > 0;
}

class DailyCount {
  const DailyCount(this.day, this.count);
  final LocalDate day;
  final int count;
}

/// SCR-88 (S19–S21). Never lists who viewed.
class JourneyInsights {
  const JourneyInsights({
    required this.journeyId,
    required this.views,
    required this.viewsByDay,
    required this.likesFromFriends,
    required this.likesFromStrangers,
    required this.started,
    required this.viewsThisWeek,
    required this.likesThisWeek,
    required this.startedThisWeek,
    required this.likers,
  });

  final String journeyId;

  /// Distinct viewers over the whole period.
  final int views;
  final List<DailyCount> viewsByDay;
  final int likesFromFriends;
  final int likesFromStrangers;
  final int started;
  final int viewsThisWeek;
  final int likesThisWeek;
  final int startedThisWeek;

  /// People who liked the caller's own photos (S20).
  final List<PersonSummary> likers;
}

abstract interface class InsightsRepository {
  Stream<InboxCounts> watchInboxCounts();
  Future<JourneyInsights> journeyInsights(String journeyId);

  /// "Your stories reached N people" (S21).
  Future<int> myReach();
}
