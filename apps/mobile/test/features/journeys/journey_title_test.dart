import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/journeys/domain/journey_title.dart';

void main() {
  for (final title in [
    'Đà Lạt 7 ngày',
    'ĐÀ LẠT 7 NGÀY',
    'Da Lat 7 ngay',
    'Nhật 10 ngày 9 đêm',
    'Phú Quốc 4N3Đ',
    '3d2n Sapa',
    'Japan 10 days',
    '1 day in Hue',
    '30-day run',
    '30 ngày cơ thể',
    '2 tuần ở Huế',
  ]) {
    test(
      'recognizes length: $title',
      () => expect(titleStatesLength(title), isTrue),
    );
  }
  for (final title in [
    'IELTS 7.5',
    'Đọc 10 trang',
    'Chạy 5km',
    'Hà Nội 2026',
    'Top 10',
    'Đà Lạt',
    'tụi mình.',
    '',
  ]) {
    test(
      'does not invent length: $title',
      () => expect(titleStatesLength(title), isFalse),
    );
  }
  test('keeps numbers with the following word', () {
    expect(keepNumberWithUnit('Đà Lạt 7 ngày'), 'Đà Lạt 7\u00A0ngày');
    expect(keepNumberWithUnit('IELTS 7.5'), 'IELTS 7.5');
  });
}
