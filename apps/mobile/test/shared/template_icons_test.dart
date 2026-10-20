import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/journeys/domain/journey_form.dart';
import 'package:ourney/shared/template_icons.dart';
import 'package:ourney_core/ourney_core.dart';

void main() {
  test('every emoji of the create form has an icon of its own', () {
    // A mapped emoji ignores the fallback template.
    for (final e in journeyEmojiChoices) {
      expect(
        journeyIcon(e, TemplateId.custom),
        journeyIcon(e, TemplateId.weightLoss),
        reason: e,
      );
    }
  });

  test('every template emoji has an icon of its own', () {
    for (final t in allTemplates) {
      expect(
        journeyIcon(t.emoji, TemplateId.custom),
        journeyIcon(t.emoji, TemplateId.weightLoss),
        reason: '${t.id}',
      );
    }
  });

  test('variation selectors do not matter and unknown emoji fall back', () {
    expect(
      journeyIcon('✈️', TemplateId.custom),
      journeyIcon('✈', TemplateId.custom),
    );
    expect(
      journeyIcon('🦄', TemplateId.travel),
      templateIcon(TemplateId.travel),
    );
  });

  test('templates map to distinct icons', () {
    expect({
      for (final t in TemplateId.values) templateIcon(t),
    }, hasLength(TemplateId.values.length));
    expect(templateIcon(TemplateId.travel), Icons.flight_takeoff_rounded);
  });
}
