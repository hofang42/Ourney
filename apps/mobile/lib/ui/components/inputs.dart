import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens.dart';
import '../typography.dart';
import 'pressable.dart';

/// `.field-label` + input: bold 12px label above a 52dp field (12dp radius,
/// 1px `inputBorder`, ink 2dp border on focus). [helper] and [error] sit
/// below; [prefix] and [trailing] are inside the field.
class UiTextField extends StatelessWidget {
  const UiTextField({
    required this.label,
    required this.controller,
    this.fieldKey,
    this.hint,
    this.helper,
    this.error,
    this.prefixText,
    this.trailing,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.readOnly = false,
    super.key,
  });

  final String label;
  final TextEditingController controller;

  /// Key for the inner [TextField] (tests and focus).
  final Key? fieldKey;
  final String? hint;
  final String? helper;
  final String? error;
  final String? prefixText;
  final Widget? trailing;
  final bool enabled;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(UiRadius.input),
      borderSide: BorderSide(color: c, width: w),
    );
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: UiText.fieldLabel(color: ui.inkMuted)),
        const SizedBox(height: 7),
        TextField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          readOnly: readOnly,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          autocorrect: autocorrect,
          enableSuggestions: autocorrect,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          cursorColor: ui.ink,
          style: UiText.body(
            size: 15,
            weight: FontWeight.w500,
            height: 1.4,
            color: ui.ink,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: ui.surfaceInput,
            hintText: hint,
            hintStyle: UiText.body(size: 15, color: ui.inkMuted),
            prefixText: prefixText,
            prefixStyle: UiText.body(
              size: 15,
              weight: FontWeight.w500,
              color: ui.inkMuted,
            ),
            suffixIcon: trailing == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: trailing,
                  ),
            suffixIconConstraints: const BoxConstraints(minWidth: 0),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            constraints: const BoxConstraints(minHeight: UiSize.input),
            border: border(ui.inputBorder),
            enabledBorder: border(hasError ? ui.danger : ui.inputBorder),
            disabledBorder: border(ui.divider),
            focusedBorder: border(hasError ? ui.danger : ui.ink, 2),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Semantics(
              liveRegion: true,
              child: Text(
                error!,
                style: UiText.body(size: 12, color: ui.danger),
              ),
            ),
          )
        else if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              helper!,
              style: UiText.body(size: 12, height: 1.5, color: ui.inkMuted),
            ),
          ),
      ],
    );
  }
}

/// `.otp-row`: [length] digit boxes (54dp, 10dp radius) driven by ONE real
/// text field, so paste, SMS autofill (`oneTimeCode`) and `enterText` all
/// work. Tapping anywhere focuses it.
class UiOtpField extends StatefulWidget {
  const UiOtpField({
    required this.controller,
    required this.focusNode,
    required this.digitLabel,
    this.length = 6,
    this.enabled = true,
    this.hasError = false,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  /// Screen-reader label of the field, e.g. "6-digit code".
  final String digitLabel;
  final int length;
  final bool enabled;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<UiOtpField> createState() => _UiOtpFieldState();
}

class _UiOtpFieldState extends State<UiOtpField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
    widget.focusNode.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    widget.focusNode.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final text = widget.controller.text;
    final focused = widget.focusNode.hasFocus;
    final active = text.length.clamp(0, widget.length - 1);
    return Semantics(
      label: widget.digitLabel,
      textField: true,
      child: Stack(
        children: [
          ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) const SizedBox(width: 7),
                  Expanded(
                    child: Container(
                      height: UiSize.otp,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ui.surfaceInput,
                        borderRadius: BorderRadius.circular(UiRadius.otp),
                        border: Border.all(
                          color: widget.hasError
                              ? ui.danger
                              : (focused && i == active)
                              ? ui.ink
                              : ui.inputBorder,
                          width: focused && i == active ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        i < text.length ? text[i] : '',
                        style: UiText.body(
                          size: 20,
                          weight: FontWeight.w700,
                          height: 1.3,
                          color: ui.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // The real field: invisible, stretched over the boxes.
          Positioned.fill(
            child: Opacity(
              opacity: 0.011,
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                textInputAction: TextInputAction.done,
                enableInteractiveSelection: false,
                showCursor: false,
                cursorColor: Colors.transparent,
                style: const TextStyle(fontSize: 1, color: Colors.transparent),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.switch-row`: label, optional supporting line and a toggle.
class UiSwitchRow extends StatelessWidget {
  const UiSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.divider = true,
    super.key,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return UiPressable(
      onPressed: onChanged == null ? null : () => onChanged!(!value),
      semanticLabel: label,
      selected: value,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.zero,
      minSize: const Size(UiSize.tap, 64),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: divider
              ? Border(bottom: BorderSide(color: ui.divider))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.body(
                      size: 15,
                      weight: FontWeight.w600,
                      height: 1.35,
                      color: ui.ink,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: UiText.body(
                        size: 12,
                        height: 1.4,
                        color: ui.inkMuted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ExcludeSemantics(
              child: IgnorePointer(
                child: Switch(value: value, onChanged: onChanged),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
