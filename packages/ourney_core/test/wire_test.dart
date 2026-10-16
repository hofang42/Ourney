import 'package:ourney_core/ourney_core.dart';
import 'package:test/test.dart';

// Value lists copied verbatim from supabase/migrations/0001_core.sql.
const sqlJourneyKind = ['solo', 'group'];
const sqlJourneyVisibility = ['private', 'group', 'link'];
const sqlJourneyStatus = ['active', 'ended', 'archived'];
const sqlMemberRole = ['owner', 'member'];
const sqlMemberStatus = ['active', 'left'];
const sqlTemplateId = ['weight_loss', 'english_daily', 'workout_30', 'travel', 'custom'];
const sqlReportReason = ['spam', 'nudity', 'harassment', 'self_harm', 'other'];
const sqlReportStatus = ['open', 'actioned', 'dismissed'];
const sqlReactionEmojis = ['🔥', '💪', '👏', '❤️', '😂'];

void roundTrip<T extends Enum>(
  String name,
  List<String> sql,
  List<T> values,
  String Function(T) wireOf,
  T Function(String) fromWire,
) {
  group(name, () {
    test('wire names equal the SQL enum, in order', () {
      expect(values.map(wireOf).toList(), sql);
    });
    test('every SQL value round-trips', () {
      for (final w in sql) {
        expect(wireOf(fromWire(w)), w);
      }
    });
    test('unknown value throws FormatException', () {
      expect(() => fromWire('nope'), throwsFormatException);
    });
  });
}

void main() {
  roundTrip('JourneyKind', sqlJourneyKind, JourneyKind.values, (v) => v.wireName, JourneyKind.fromWire);
  roundTrip('JourneyVisibility', sqlJourneyVisibility, JourneyVisibility.values, (v) => v.wireName,
      JourneyVisibility.fromWire);
  roundTrip('JourneyStatus', sqlJourneyStatus, JourneyStatus.values, (v) => v.wireName, JourneyStatus.fromWire);
  roundTrip('MemberRole', sqlMemberRole, MemberRole.values, (v) => v.wireName, MemberRole.fromWire);
  roundTrip('MemberStatus', sqlMemberStatus, MemberStatus.values, (v) => v.wireName, MemberStatus.fromWire);
  roundTrip('TemplateId', sqlTemplateId, TemplateId.values, (v) => v.wireName, TemplateId.fromWire);
  roundTrip('ReportReason', sqlReportReason, ReportReason.values, (v) => v.wireName, ReportReason.fromWire);
  roundTrip('ReportStatus', sqlReportStatus, ReportStatus.values, (v) => v.wireName, ReportStatus.fromWire);

  test('snake_case wire names differ from Dart names', () {
    expect(TemplateId.weightLoss.wireName, 'weight_loss');
    expect(TemplateId.workout30.wireName, 'workout_30');
    expect(ReportReason.selfHarm.wireName, 'self_harm');
  });

  test('reaction emojis match the SQL CHECK', () => expect(reactionEmojis, sqlReactionEmojis));

  group('JourneyDraft visibility default', () {
    JourneyDraft draft(JourneyKind kind, [JourneyVisibility? v]) => JourneyDraft(
          kind: kind,
          templateId: TemplateId.custom,
          title: 't',
          emoji: '✨',
          startDate: const LocalDate(2026, 10, 1),
          timezone: 'Asia/Ho_Chi_Minh',
          visibility: v,
        );
    test('group defaults to group', () => expect(draft(JourneyKind.group).visibility, JourneyVisibility.group));
    test('solo defaults to private', () => expect(draft(JourneyKind.solo).visibility, JourneyVisibility.private));
    test('explicit value kept', () {
      expect(draft(JourneyKind.solo, JourneyVisibility.link).visibility, JourneyVisibility.link);
    });
    test('defaultVisibilityFor agrees', () {
      for (final k in JourneyKind.values) {
        expect(draft(k).visibility, defaultVisibilityFor(k));
      }
    });
  });
}
