import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens.dart';
import '../typography.dart';
import 'inputs.dart' show uiFieldBorder;

/// `.field-label` + multi-line (or length-limited) input with a character
/// counter. Same look as `UiTextField` (16dp radius, 1.5dp `ui.border`, 2dp
/// accent on focus), which has no `maxLength` / `maxLines`.
class UiTextArea extends StatelessWidget {
  const UiTextArea({
    required this.label,
    required this.controller,
    this.fieldKey,
    this.hint,
    this.optionalLabel,
    this.maxLength,
    this.minLines = 1,
    this.maxLines,
    this.textCapitalization = TextCapitalization.sentences,
    this.onChanged,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final Key? fieldKey;
  final String? hint;

  /// Muted suffix after the label, e.g. "optional".
  final String? optionalLabel;
  final int? maxLength;
  final int minLines;
  final int? maxLines;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: [
              if (optionalLabel != null)
                TextSpan(
                  text: '  $optionalLabel',
                  style: UiText.body(size: 12, color: ui.inkMuted),
                ),
            ],
          ),
          style: UiText.fieldLabel(color: ui.inkMuted),
        ),
        const SizedBox(height: 7),
        TextField(
          key: fieldKey,
          controller: controller,
          maxLength: maxLength,
          minLines: minLines,
          maxLines: maxLines ?? (minLines == 1 ? 1 : 6),
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          cursorColor: ui.ink,
          style: UiText.body(
            size: 15,
            weight: FontWeight.w500,
            height: 1.4,
            color: ui.ink,
          ),
          buildCounter:
              (
                context, {
                required currentLength,
                required isFocused,
                required maxLength,
              }) => maxLength == null
              ? null
              : Text(
                  '$currentLength/$maxLength',
                  style: UiText.body(size: 11, color: ui.inkMuted),
                ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: ui.fill,
            hintText: hint,
            hintStyle: UiText.body(size: 15, color: ui.inkMuted),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            constraints: const BoxConstraints(minHeight: UiSize.input),
            border: uiFieldBorder(ui.border),
            enabledBorder: uiFieldBorder(ui.border),
            focusedBorder: uiFieldBorder(ui.accent, UiBorder.standard),
          ),
        ),
      ],
    );
  }
}

/// Label-less, rounded, growing caption input (Post screen). Same outline as
/// the other kit fields; the placeholder is the label ([semanticLabel] names
/// it for screen readers). 1 to [maxLines] lines, Return closes the keyboard.
///
/// [counter] is the small right-aligned count under the field; the caller
/// passes it only when it should show (e.g. from 120 of 140 characters).
/// [counterSemantics] stays on the field's node either way.
class UiCaptionField extends StatelessWidget {
  const UiCaptionField({
    required this.controller,
    required this.semanticLabel,
    this.fieldKey,
    this.hint,
    this.inputFormatters,
    this.maxLines = 5,
    this.counter,
    this.counterKey,
    this.counterDanger = false,
    this.counterSemantics,
    this.onChanged,
    this.focusNode,
    super.key,
  });

  final TextEditingController controller;
  final String semanticLabel;
  final Key? fieldKey;
  final String? hint;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final String? counter;
  final Key? counterKey;
  final bool counterDanger;
  final String? counterSemantics;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: semanticLabel,
          hint: counterSemantics,
          child: TextField(
            key: fieldKey,
            controller: controller,
            focusNode: focusNode,
            minLines: 1,
            maxLines: maxLines,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            cursorColor: ui.accent,
            style: UiText.body(size: 16, height: 1.45, color: ui.ink),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: ui.fill,
              hintText: hint,
              hintStyle: UiText.body(
                size: 16,
                height: 1.45,
                color: ui.inkMuted,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              constraints: const BoxConstraints(minHeight: UiSize.input),
              border: uiFieldBorder(ui.border),
              enabledBorder: uiFieldBorder(ui.border),
              focusedBorder: uiFieldBorder(ui.accent, UiBorder.standard),
            ),
          ),
        ),
        if (counter != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 4),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: ExcludeSemantics(
                child: Text(
                  counter!,
                  key: counterKey,
                  style: UiText.body(
                    size: 12,
                    height: 1.3,
                    color: counterDanger ? ui.danger : ui.inkMuted,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
