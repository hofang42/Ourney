import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens.dart';
import '../typography.dart';
import 'ourney_icons.dart';
import 'pressable.dart';

const double _otpW = 48;

/// Limits input to Unicode code points, matching storage length checks.
class CodePointLimitFormatter extends TextInputFormatter {
  const CodePointLimitFormatter(this.max);

  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final runes = newValue.text.runes;
    if (runes.length <= max) return newValue;
    final text = String.fromCharCodes(runes.take(max));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Outline of every kit text field: 16dp radius, 1.5dp at rest, 2dp on focus
/// (pass [UiBorder.standard]). No shadow.
OutlineInputBorder uiFieldBorder(
  Color color, [
  double width = UiBorder.thin,
  double radius = UiRadius.field,
]) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(radius),
  borderSide: BorderSide(color: color, width: width),
);
const double _otpGap = 8;

/// `.flow-field`: bold label always visible above a 52dp field (16dp radius,
/// 1.5dp `ui.fieldBorder` outline (3:1), `ui.fill` background, no shadow). Focus swaps
/// the outline to a 2dp accent border, [error] to `danger`, and prints the
/// message under the field. [helper] sits below; [prefixText] and [trailing]
/// are inside the field.
class UiTextField extends StatefulWidget {
  const UiTextField({
    required this.label,
    required this.controller,
    this.fieldKey,
    this.hint,
    this.helper,
    this.error,
    this.invalid = false,
    this.prefixText,
    this.leading,
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
    this.obscureText = false,
    this.pill = false,
    this.expanded,
    super.key,
  });

  final String label;

  /// Single-line search fields: capsule shape instead of the 16dp radius.
  final bool pill;
  final TextEditingController controller;

  /// Whether this field's suggestions are visible, if it offers suggestions.
  final bool? expanded;

  /// Password field: hides the text (also disables suggestions/autocorrect).
  final bool obscureText;

  /// Key for the inner [TextField] (tests and focus).
  final Key? fieldKey;
  final String? hint;
  final String? helper;
  final String? error;

  /// Danger outline without a message (the screen prints its own status row).
  final bool invalid;
  final String? prefixText;

  /// Widget before the text inside the field (icon, bold prefix).
  final Widget? leading;
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
  State<UiTextField> createState() => _UiTextFieldState();
}

class _UiTextFieldState extends State<UiTextField> {
  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final hasError = widget.error != null || widget.invalid;
    final edge = hasError ? ui.danger : ui.fieldBorder;
    final focusEdge = hasError ? ui.danger : ui.accent;
    final radius = widget.pill ? UiRadius.capsule : UiRadius.field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(
            widget.label,
            style: UiText.body(
              size: 14,
              weight: FontWeight.w700,
              height: 1.4,
              color: ui.ink,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          container: true,
          label: widget.label,
          expanded: widget.expanded,
          child: TextField(
            key: widget.fieldKey,
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            autofillHints: widget.autofillHints,
            inputFormatters: widget.inputFormatters,
            textCapitalization: widget.textCapitalization,
            obscureText: widget.obscureText,
            autocorrect: widget.autocorrect && !widget.obscureText,
            enableSuggestions: widget.autocorrect && !widget.obscureText,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            cursorColor: ui.ink,
            style: UiText.body(
              size: 16,
              weight: FontWeight.w500,
              height: 1.4,
              color: ui.ink,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: ui.fill,
              hintText: widget.hint == widget.label ? null : widget.hint,
              hint: widget.hint == widget.label
                  ? ExcludeSemantics(child: Text(widget.label))
                  : null,
              hintStyle: UiText.body(size: 16, color: ui.inkMuted),
              prefixText: widget.leading == null ? widget.prefixText : null,
              prefixIcon: widget.leading == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(left: 14, right: 10),
                      child: widget.leading,
                    ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0),
              prefixStyle: UiText.body(
                size: 16,
                weight: FontWeight.w500,
                color: ui.inkMuted,
              ),
              suffixIcon: widget.trailing == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: widget.trailing,
                    ),
              suffixIconConstraints: const BoxConstraints(minWidth: 0),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              constraints: const BoxConstraints(minHeight: UiSize.input),
              border: uiFieldBorder(edge, UiBorder.thin, radius),
              enabledBorder: uiFieldBorder(edge, UiBorder.thin, radius),
              disabledBorder: uiFieldBorder(
                ui.border.withValues(alpha: 0.5),
                UiBorder.thin,
                radius,
              ),
              focusedBorder: uiFieldBorder(
                focusEdge,
                UiBorder.standard,
                radius,
              ),
            ),
          ),
        ),
        if (widget.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OurneyIcon(
                    name: 'warning',
                    size: 20,
                    flat: true,
                    color: ui.danger,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      widget.error!,
                      style: UiText.body(
                        size: 13,
                        weight: FontWeight.w600,
                        height: 1.4,
                        color: ui.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (widget.helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.helper!,
              style: UiText.body(size: 12, height: 1.5, color: ui.inkMuted),
            ),
          ),
      ],
    );
  }
}

/// `.otp-boxes`: [length] digit boxes (48x52, 8dp gap, 10dp radius, 1.5dp
/// `ui.fieldBorder` outline, no shadow) driven by ONE real text field, so paste,
/// SMS autofill (`oneTimeCode`) and `enterText` all work. The active box gets
/// a 2dp accent border; [hasError] swaps the outline to `danger`. Boxes
/// shrink evenly when the row is narrower than 328dp (320dp phones).
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
      child: LayoutBuilder(
        builder: (context, c) {
          final gaps = _otpGap * (widget.length - 1);
          final fit = (c.maxWidth - gaps) / widget.length;
          final w = fit.isFinite ? fit.clamp(22.0, _otpW) : _otpW;
          return Stack(
            children: [
              ExcludeSemantics(
                child: Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < widget.length; i++) ...[
                        if (i > 0) const SizedBox(width: _otpGap),
                        Container(
                          key: ValueKey('ui-otp-box-$i'),
                          width: w,
                          height: UiSize.input,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: ui.fill,
                            borderRadius: BorderRadius.circular(UiRadius.otp),
                            border: Border.all(
                              color: widget.hasError
                                  ? ui.danger
                                  : focused && i == active
                                  ? ui.accent
                                  : ui.fieldBorder,
                              width: focused && i == active
                                  ? UiBorder.standard
                                  : UiBorder.thin,
                            ),
                          ),
                          child: Text(
                            i < text.length ? text[i] : '',
                            style: TextStyle(
                              fontFamily: UiFonts.spaceGrotesk,
                              fontFamilyFallback: const [UiFonts.body],
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: ui.ink,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
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
                    style: const TextStyle(
                      fontSize: 1,
                      color: Colors.transparent,
                    ),
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
          );
        },
      ),
    );
  }
}

/// `.switch-row`: label, optional supporting line and a sticker switch
/// (46x27 track, 1.5dp outline, 18dp thumb, brand when on).
class UiSwitchRow extends StatelessWidget {
  const UiSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.divider = true,
    this.semanticsLabel,
    super.key,
  });

  final String label;

  /// Screen-reader label; defaults to [label].
  final String? semanticsLabel;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return UiPressable(
      onPressed: onChanged == null ? null : () => onChanged!(!value),
      semanticLabel: semanticsLabel ?? label,
      selected: value,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.zero,
      minSize: const Size(UiSize.tap, 64),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: divider
              ? Border(
                  bottom: BorderSide(color: ui.ink.withValues(alpha: 0.12)),
                )
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
              child: _StickerSwitch(value: value, enabled: onChanged != null),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickerSwitch extends StatelessWidget {
  const _StickerSwitch({required this.value, required this.enabled});

  final bool value;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: AnimatedContainer(
        key: const ValueKey('ui-switch-track'),
        duration: UiMotion.of(context, UiMotion.press),
        width: 46,
        height: 27,
        padding: const EdgeInsets.all(3),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: value ? ui.brand : ui.fill,
          borderRadius: BorderRadius.circular(UiRadius.capsule),
          border: ui.stickerBorder(UiBorder.thin),
        ),
        child: Container(
          key: const ValueKey('ui-switch-thumb'),
          width: 18,
          height: 18,
          decoration: BoxDecoration(color: ui.ink, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
