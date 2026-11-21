import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/components/flow_kit.dart';
import 'package:ourney/ui/tokens.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // U14: small labels (privacy tag, Insights delta) use these tokens.
  for (final (name, ui) in [
    ('light', OurneyUi.light),
    ('dark', OurneyUi.dark),
  ]) {
    test('$name: muted ink and success read >= 4.5:1 on bg and surface', () {
      for (final bg in [ui.bg, ui.surface]) {
        expect(_ratio(ui.inkMuted, bg), greaterThanOrEqualTo(4.5));
        expect(_ratio(ui.success, bg), greaterThanOrEqualTo(4.5));
      }
    });
  }

  test('app-icon tile marks (settings) read >= 4.5:1 on the light tiles', () {
    for (final tile in const [
      Color(0xFFFF4D6D),
      Color(0xFFDFF7EC),
      Color(0xFFFFF0C7),
      Color(0xFFF3E3C3),
      Color(0xFFFFE0E9),
      Color(0xFFF4F4F5),
    ]) {
      expect(_ratio(UiFlowColors.onPastel, tile), greaterThanOrEqualTo(4.5));
    }
  });
}
