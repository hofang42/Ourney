import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';

/// `.field-label` + multi-line (or length-limited) input with a character
/// counter. Same look as `UiTextField`, which has no `maxLength` / `maxLines`.
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
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(UiRadius.input),
      borderSide: BorderSide(color: c, width: w),
    );
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
            fillColor: ui.surfaceInput,
            hintText: hint,
            hintStyle: UiText.body(size: 15, color: ui.inkMuted),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            constraints: const BoxConstraints(minHeight: UiSize.input),
            border: border(ui.inputBorder),
            enabledBorder: border(ui.inputBorder),
            focusedBorder: border(ui.ink, 2),
          ),
        ),
      ],
    );
  }
}
