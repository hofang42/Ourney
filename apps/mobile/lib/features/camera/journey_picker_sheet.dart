import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../ui/ui.dart';
import 'l10n/generated/camera_localizations.dart';

/// Opens the searchable "all journeys" sheet of the camera. Returns the
/// chosen journey id (or null when dismissed). Selecting never navigates, so
/// the preview underneath keeps running.
Future<String?> showJourneyPickerSheet(
  BuildContext context, {
  required List<Journey> journeys,
  required String? selectedId,
}) {
  return showUiSheet<String>(
    context: context,
    builder: (ctx) =>
        JourneyPickerSheet(journeys: journeys, selectedId: selectedId),
  );
}

/// Search field plus the filtered list of journeys (title match, accent
/// insensitive), the selected one marked with a check.
class JourneyPickerSheet extends StatefulWidget {
  const JourneyPickerSheet({
    required this.journeys,
    required this.selectedId,
    super.key,
  });

  final List<Journey> journeys;
  final String? selectedId;

  @override
  State<JourneyPickerSheet> createState() => _JourneyPickerSheetState();
}

class _JourneyPickerSheetState extends State<JourneyPickerSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CameraL10n.of(context);
    final ui = context.ui;
    final q = _query.text.trim().toLowerCase();
    final shown = [
      for (final j in widget.journeys)
        if (q.isEmpty || j.title.toLowerCase().contains(q)) j,
    ];
    return UiSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.camera_pickerTitle,
            style: UiText.body(
              size: 20,
              weight: FontWeight.w800,
              height: 1.3,
              color: ui.ink,
            ),
          ),
          const SizedBox(height: UiSpace.md),
          UiTextField(
            fieldKey: const ValueKey('journey-picker-search'),
            label: l10n.camera_pickerSearch,
            controller: _query,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: UiSpace.md),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: UiSpace.lg),
              child: Text(
                l10n.camera_pickerEmpty,
                key: const ValueKey('journey-picker-empty'),
                textAlign: TextAlign.center,
                style: UiText.body(size: 14, height: 1.4, color: ui.inkMuted),
              ),
            ),
          for (final j in shown)
            UiPressable(
              key: ValueKey('journey-picker-${j.id}'),
              onPressed: () => Navigator.of(context).pop(j.id),
              semanticLabel: j.title,
              selected: j.id == widget.selectedId,
              excludeChildSemantics: true,
              borderRadius: BorderRadius.circular(UiRadius.menu),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: UiSpace.sm,
                  horizontal: UiSpace.sm,
                ),
                child: Row(
                  children: [
                    uiJourneyGlyph(j.emoji, j.templateId, size: 28),
                    const SizedBox(width: UiSpace.sm),
                    Expanded(
                      child: Text(
                        j.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.body(
                          size: 15,
                          weight: FontWeight.w600,
                          height: 1.4,
                          color: ui.ink,
                        ),
                      ),
                    ),
                    if (j.id == widget.selectedId)
                      OurneyIcon(
                        name: 'check',
                        size: 20,
                        flat: true,
                        color: ui.ink,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
