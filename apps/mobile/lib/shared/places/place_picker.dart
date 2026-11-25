import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../ui/ui.dart';
import 'place_catalog.dart';

/// An inline autocomplete. Typed places are valid even without a selection.
class PlacePicker extends StatefulWidget {
  const PlacePicker({
    required this.controller,
    required this.fieldKey,
    required this.label,
    required this.hint,
    this.onChanged,
    this.destination,
    this.recent = const [],
    this.browseWhenEmpty = false,
    this.maxRunes,
    this.inputFormatters,
    super.key,
  });

  final TextEditingController controller;
  final Key fieldKey;
  final String label;
  final String hint;
  final ValueChanged<String>? onChanged;
  final String? destination;
  final List<String> recent;
  final bool browseWhenEmpty;
  final int? maxRunes;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<PlacePicker> {
  final _focus = FocusNode();
  bool _expanded = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _select(String value) {
    unawaited(UiHaptics.selection());
    widget.controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    widget.onChanged?.call(value);
    _close();
  }

  void _close() {
    if (_expanded) setState(() => _expanded = false);
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _focus,
    canRequestFocus: false,
    onFocusChange: (focused) {
      // The page can dismiss the keyboard on drag. Keep the list open so
      // results below the keyboard can still be reached by scrolling.
      if (focused && !_expanded) setState(() => _expanded = true);
    },
    child: TextFieldTapRegion(
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final query = widget.controller.text.trim();
          final show = _expanded || (widget.browseWhenEmpty && query.isEmpty);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UiTextField(
                fieldKey: widget.fieldKey,
                pill: widget.browseWhenEmpty,
                label: widget.label,
                hint: widget.hint,
                controller: widget.controller,
                leading: const OurneyIcon(name: 'map-pin', size: 20),
                textCapitalization: TextCapitalization.words,
                autocorrect: false,
                inputFormatters: widget.inputFormatters,
                onChanged: widget.onChanged,
                onSubmitted: (_) => _close(),
              ),
              if (show) _suggestions(context, query),
            ],
          );
        },
      ),
    ),
  );

  Widget _suggestions(BuildContext context, String query) {
    final options = placeSuggestions(
      query: query,
      language: Localizations.localeOf(context).languageCode,
      destination: widget.destination,
      recent: widget.recent,
      maxRunes: widget.maxRunes,
    );
    final offerCustom =
        query.isNotEmpty && !options.any((item) => item.value == query);
    final customIndex = options.isEmpty ? 0 : 1;
    final ui = context.ui;
    final radius = BorderRadius.circular(UiRadius.input);
    return Padding(
      padding: const EdgeInsets.only(top: UiSpace.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ui.surface,
          borderRadius: radius,
          border: Border.all(color: ui.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 224),
          child: ListView.builder(
            // Reset scrolling when results change so the best match is visible.
            key: ValueKey(query),
            primary: false,
            padding: const EdgeInsets.all(UiSpace.xs),
            shrinkWrap: true,
            itemCount: options.length + (offerCustom ? 1 : 0),
            itemBuilder: (context, index) {
              if (offerCustom && index == customIndex) {
                return _row(
                  context,
                  key: const ValueKey('place-use-text'),
                  label: AppLocalizations.of(context).common_usePlace(query),
                  value: query,
                );
              }
              final item =
                  options[offerCustom && index > customIndex
                      ? index - 1
                      : index];
              return _row(
                context,
                key: ValueKey(item.id ?? 'recent:${item.value}'),
                label: item.value,
                value: item.value,
                country: item.country,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required Key key,
    required String label,
    required String value,
    String? country,
  }) {
    final ui = context.ui;
    return UiPressable(
      key: key,
      onPressed: () => _select(value),
      semanticLabel: country == null ? label : '$label, $country',
      excludeChildSemantics: true,
      pressOffset: UiShadow.tiny,
      borderRadius: BorderRadius.circular(UiRadius.input),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: UiSpace.md,
          vertical: UiSpace.xs,
        ),
        child: Row(
          children: [
            const OurneyIcon(name: 'map-pin', size: 18),
            const SizedBox(width: UiSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.body(color: ui.ink, height: 1.3),
                  ),
                  if (country != null)
                    Text(
                      country,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.muted(color: ui.inkMuted)
                          .copyWith(height: 1.4),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
