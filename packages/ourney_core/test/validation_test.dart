import 'package:ourney_core/ourney_core.dart';
import 'package:test/test.dart';

void main() {
  group('username', () {
    test('valid', () {
      for (final u in ['abc', 'a_b.c9', 'a' * 20, 'user.name_1']) {
        expect(validateUsername(u), isNull, reason: u);
      }
    });
    test('too short', () => expect(validateUsername('ab'), UsernameError.tooShort));
    test('too long', () => expect(validateUsername('a' * 21), UsernameError.tooLong));
    test('uppercase rejected', () => expect(validateUsername('Abc'), UsernameError.invalidChars));
    test('space and dash rejected', () {
      expect(validateUsername('a b'), UsernameError.invalidChars);
      expect(validateUsername('a-b'), UsernameError.invalidChars);
    });
    test('empty is too short', () => expect(validateUsername(''), UsernameError.tooShort));
  });

  group('displayName', () {
    test('valid', () => expect(validateDisplayName('Hoàng'), isNull));
    test('empty and whitespace', () {
      expect(validateDisplayName(''), DisplayNameError.empty);
      expect(validateDisplayName('   '), DisplayNameError.empty);
    });
    test('40 ok, 41 too long', () {
      expect(validateDisplayName('a' * 40), isNull);
      expect(validateDisplayName('a' * 41), DisplayNameError.tooLong);
    });
    test('counts emoji as one character', () {
      expect(validateDisplayName('😀' * 40), isNull);
    });
  });

  group('journey title', () {
    test('empty', () => expect(validateJourneyTitle(' '), JourneyTitleError.empty));
    test('60 ok, 61 too long', () {
      expect(validateJourneyTitle('a' * 60), isNull);
      expect(validateJourneyTitle('a' * 61), JourneyTitleError.tooLong);
    });
  });

  group('caption', () {
    test('null and empty ok', () {
      expect(validateCaption(null), isNull);
      expect(validateCaption(''), isNull);
    });
    test('140 ok, 141 too long', () {
      expect(validateCaption('a' * 140), isNull);
      expect(validateCaption('a' * 141), CaptionError.tooLong);
    });
  });

  group('invite code', () {
    test('valid', () => expect(validateInviteCode('AB12CD34'), isNull));
    test('wrong length', () {
      expect(validateInviteCode('AB12CD3'), InviteCodeError.wrongLength);
      expect(validateInviteCode('AB12CD345'), InviteCodeError.wrongLength);
    });
    test('lowercase rejected', () => expect(validateInviteCode('ab12cd34'), InviteCodeError.invalidChars));
    test('normalize trims and uppercases', () {
      expect(normalizeInviteCode('  ab12cd34\n'), 'AB12CD34');
      expect(validateInviteCode(normalizeInviteCode(' ab12cd34 ')), isNull);
    });
  });

  group('metric value', () {
    test('sane values', () {
      expect(validateMetricValue(72.5), isNull);
      expect(validateMetricValue(0), isNull);
    });
    test('negative', () => expect(validateMetricValue(-1), MetricValueError.outOfRange));
    test('huge', () => expect(validateMetricValue(1e9), MetricValueError.outOfRange));
    test('nan and infinity', () {
      expect(validateMetricValue(double.nan), MetricValueError.notFinite);
      expect(validateMetricValue(double.infinity), MetricValueError.notFinite);
    });
    test('null ok', () => expect(validateMetricValue(null), isNull));
  });

  group('duration', () {
    test('null (open) ok', () => expect(validateDurationDays(null), isNull));
    test('7..365 ok', () {
      expect(validateDurationDays(7), isNull);
      expect(validateDurationDays(365), isNull);
    });
    test('out of range', () {
      expect(validateDurationDays(6), DurationError.outOfRange);
      expect(validateDurationDays(366), DurationError.outOfRange);
    });
  });
}
