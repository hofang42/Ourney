import 'contracts/social.dart' show JourneyOrigin;
import 'models.dart';
import 'streak.dart';
import 'templates.dart';

/// What the user wants to stick to (onboarding quiz, question 1).
enum QuizGoal {
  weightLoss('weight_loss', TemplateId.weightLoss),
  english('english', TemplateId.englishDaily),
  workout('workout', TemplateId.workout30),
  trip('trip', TemplateId.travel),
  couple('couple', TemplateId.custom),
  habit('habit', TemplateId.custom);

  const QuizGoal(this.wireName, this.template);
  final String wireName;

  /// Template suggested for this goal.
  final TemplateId template;

  static QuizGoal? fromWire(Object? wire) {
    for (final g in values) {
      if (g.wireName == wire) return g;
    }
    return null;
  }
}

/// Alone or with others (onboarding quiz, question 2).
enum QuizCompany {
  solo('solo'),
  group('group'),
  couple('couple');

  const QuizCompany(this.wireName);
  final String wireName;

  static QuizCompany? fromWire(Object? wire) {
    for (final c in values) {
      if (c.wireName == wire) return c;
    }
    return null;
  }
}

/// Suggested defaults for the create-journey form.
class JourneySuggestion {
  const JourneySuggestion({
    required this.templateId,
    required this.skin,
    required this.kind,
    this.reminder,
    this.coupleRitual = false,
  });

  final TemplateId templateId;
  final PersonaSkinId skin;
  final JourneyKind kind;

  /// "HH:MM" local reminder time, when the user chose one.
  final String? reminder;

  /// Two-person ritual ([PersonaSkinId.coupleRituals], max 2 members).
  final bool coupleRitual;
}

final RegExp _hhmm = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

/// The 3 onboarding answers (FR-A3 v2). Stored locally and, when signed in,
/// in `profiles.onboarding_quiz`. Any answer may be missing (skipped).
class OnboardingQuiz {
  const OnboardingQuiz({this.goal, this.company, this.reminder});

  final QuizGoal? goal;
  final QuizCompany? company;

  /// "HH:MM".
  final String? reminder;

  bool get isEmpty => goal == null && company == null && reminder == null;

  /// Default template/skin for the first journey. Null when nothing was
  /// answered. A couple answer (either question) selects the couple ritual.
  JourneySuggestion? get suggestion {
    if (isEmpty) return null;
    final couple = company == QuizCompany.couple || goal == QuizGoal.couple;
    final template = goal?.template ?? TemplateId.custom;
    final skin = couple
        ? PersonaSkinId.coupleRituals
        : templateFor(template).personaSkinId;
    final kind = company == QuizCompany.solo || company == null
        ? JourneyKind.solo
        : JourneyKind.group;
    return JourneySuggestion(
      templateId: couple ? TemplateId.custom : template,
      skin: skin,
      kind: couple ? JourneyKind.group : kind,
      reminder: reminder != null && _hhmm.hasMatch(reminder!) ? reminder : null,
      coupleRitual: couple,
    );
  }

  Map<String, Object> toJson() => {
        if (goal != null) 'goal': goal!.wireName,
        if (company != null) 'who': company!.wireName,
        if (reminder != null) 'reminder': reminder!,
      };

  /// Tolerant: unknown keys / values are ignored, never thrown.
  static OnboardingQuiz? fromJson(Object? json) {
    if (json is! Map) return null;
    final reminder = json['reminder'];
    return OnboardingQuiz(
      goal: QuizGoal.fromWire(json['goal']),
      company: QuizCompany.fromWire(json['who']),
      reminder:
          reminder is String && _hhmm.hasMatch(reminder) ? reminder : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OnboardingQuiz &&
      other.goal == goal &&
      other.company == company &&
      other.reminder == reminder;

  @override
  int get hashCode => Object.hash(goal, company, reminder);
}

/// Numbers on the profile screen (server RPC `profile_stats` or computed
/// from local data).
class ProfileStats {
  const ProfileStats({
    this.totalSnaps = 0,
    this.longestStreak = 0,
    this.currentStreak = 0,
    this.journeysCompleted = 0,
    this.journeysTotal = 0,
  });

  final int totalSnaps;
  final int longestStreak;
  final int currentStreak;
  final int journeysCompleted;
  final int journeysTotal;

  static ProfileStats fromJson(Object? json) {
    // The RPC returns a one-row table: a list with one object, or the object.
    final row = json is List ? (json.isEmpty ? null : json.first) : json;
    if (row is! Map) return const ProfileStats();
    int n(String k) => (row[k] as num?)?.toInt() ?? 0;
    return ProfileStats(
      totalSnaps: n('total_snaps'),
      longestStreak: n('longest_streak'),
      currentStreak: n('current_streak'),
      journeysCompleted: n('journeys_completed'),
      journeysTotal: n('journeys_total'),
    );
  }
}

/// Local-only fallback for [ProfileStats]: derived from the journeys and
/// check-ins on this device. [today] resolves a journey's timezone to its
/// current local date.
ProfileStats computeLocalProfileStats({
  required Iterable<Journey> journeys,
  required Map<String, List<CheckIn>> checkInsByJourney,
  required LocalDate Function(String timezone) today,
}) {
  var snaps = 0;
  var longest = 0;
  var current = 0;
  var completed = 0;
  var total = 0;
  for (final j in journeys) {
    final mine = checkInsByJourney[j.id] ?? const <CheckIn>[];
    final localToday = today(j.timezone);
    final isFinished =
        j.status == JourneyStatus.ended ||
        j.status == JourneyStatus.archived ||
        j.isPastEndOn(localToday);
    total++;
    snaps += mine.length;
    if (isFinished) completed++;
    // S12: imported journeys do not count toward live streaks.
    if (j.origin != JourneyOrigin.imported) {
      final s = computeStreak(
        start: j.startDate,
        durationDays: j.durationDays,
        today: localToday,
        dates: [for (final c in mine) c.localDate],
      );
      if (s.best > longest) longest = s.best;
      if (!isFinished && s.current > current) current = s.current;
    }
  }
  return ProfileStats(
    totalSnaps: snaps,
    longestStreak: longest,
    currentStreak: current,
    journeysCompleted: completed,
    journeysTotal: total,
  );
}

/// Steady-habit badges on the shelf (Figma ProfileScreen).
enum BadgeId {
  streak7(7),
  streak30(30),
  firstFinish(1),
  days100(100);

  const BadgeId(this.threshold);

  /// Streak days / snaps / finished journeys needed.
  final int threshold;
}

class ProfileBadge {
  const ProfileBadge(this.id, {required this.unlocked});
  final BadgeId id;
  final bool unlocked;
}

/// Badges derived from [s]; always all of [BadgeId.values], in order.
List<ProfileBadge> badgesFor(ProfileStats s) => [
      ProfileBadge(BadgeId.streak7,
          unlocked: s.longestStreak >= BadgeId.streak7.threshold),
      ProfileBadge(BadgeId.streak30,
          unlocked: s.longestStreak >= BadgeId.streak30.threshold),
      ProfileBadge(BadgeId.firstFinish,
          unlocked: s.journeysCompleted >= BadgeId.firstFinish.threshold),
      ProfileBadge(BadgeId.days100,
          unlocked: s.totalSnaps >= BadgeId.days100.threshold),
    ];

/// Server-backed extras of the signed-in account: onboarding quiz and profile
/// stats. Implementations throw `OurneyException` (mapped codes).
abstract interface class AccountInsightsRepository {
  /// `profile_stats()` RPC (RLS-scoped to the caller).
  Future<ProfileStats> fetchStats();

  /// `profiles.onboarding_quiz` of the caller (null when never saved).
  Future<OnboardingQuiz?> fetchQuiz();

  /// Saves the quiz on the caller's profile row. A no-op (not an error) when
  /// the profile row does not exist yet.
  Future<void> saveQuiz(OnboardingQuiz quiz);
}
