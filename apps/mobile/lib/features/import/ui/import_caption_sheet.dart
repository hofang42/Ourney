import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../ui/ui.dart';
import '../../checkin/l10n/generated/checkin_localizations.dart';
import '../data/import_draft.dart';
import '../l10n/generated/import_localizations.dart';
import 'import_widgets.dart';

Future<void> showImportCaptionSheet(
  BuildContext context, {
  required List<DraftPhoto> ordered,
  required int start,
  required Future<void> Function(DraftPhoto) onEditDate,
}) async {
  if (ordered.isEmpty) return;
  await showUiSheet<void>(
    context: context,
    builder: (_) =>
        _CaptionSheet(ordered: ordered, start: start, onEditDate: onEditDate),
  );
}

class _CaptionSheet extends StatefulWidget {
  const _CaptionSheet({
    required this.ordered,
    required this.start,
    required this.onEditDate,
  });
  final List<DraftPhoto> ordered;
  final int start;
  final Future<void> Function(DraftPhoto) onEditDate;

  @override
  State<_CaptionSheet> createState() => _CaptionSheetState();
}

class _CaptionSheetState extends State<_CaptionSheet>
    with WidgetsBindingObserver {
  late List<DraftPhoto> _ordered = List.of(widget.ordered);
  late int _index = widget.start.clamp(0, _ordered.length - 1);
  late final TextEditingController _controller = TextEditingController(
    text: String.fromCharCodes((_photo.caption ?? '').runes.take(captionMax)),
  );
  final FocusNode _focus = FocusNode();
  final GlobalKey _fieldKey = GlobalKey();
  bool _keyboardWasUp = false;
  DraftPhoto get _photo => _ordered[_index];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
    _focus.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
  }

  void _changed() {
    // Also persists on swipe, scrim, back, or navigation away from the route.
    _photo.caption = String.fromCharCodes(
      _controller.text.runes.take(captionMax),
    );
    setState(() {});
  }

  @override
  void didChangeMetrics() {
    final up = View.of(context).viewInsets.bottom > 0;
    if (_keyboardWasUp && !up && _focus.hasFocus) _focus.unfocus();
    _keyboardWasUp = up;
  }

  void _step(int by) {
    _photo.caption = String.fromCharCodes(
      _controller.text.runes.take(captionMax),
    );
    setState(() {
      _index += by;
      final text = String.fromCharCodes(
        (_photo.caption ?? '').runes.take(captionMax),
      );
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
  }

  Future<void> _editDate() async {
    final id = _photo.id;
    _photo.caption = String.fromCharCodes(
      _controller.text.runes.take(captionMax),
    );
    await widget.onEditDate(_photo);
    if (!mounted) return;
    setState(() {
      _ordered = datedSorted(_ordered);
      _index = _ordered.indexWhere((p) => p.id == id);
    });
  }

  @override
  void dispose() {
    _photo.caption = String.fromCharCodes(
      _controller.text.runes.take(captionMax),
    );
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_changed);
    _focus.removeListener(_changed);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = ImportL10n.of(context);
    final date = _photo.date!;
    final dateLabel = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(DateTime(date.year, date.month, date.day));
    final day = _ordered.first.date!.daysUntil(date) + 1;
    final count = _controller.text.runes.length;
    final typing = _focus.hasFocus;
    final field = UiCaptionField(
      key: _fieldKey,
      fieldKey: const ValueKey('import-caption-field'),
      controller: _controller,
      focusNode: _focus,
      semanticLabel: l10n.import_captionHint,
      hint: l10n.import_captionHint,
      inputFormatters: const [CodePointLimitFormatter(captionMax)],
      counter: count >= 120
          ? CheckinL10n.of(context).checkin_captionCounter(count, captionMax)
          : null,
      counterSemantics: CheckinL10n.of(context)
          .checkin_captionCounterSemantics(count, captionMax),
      counterDanger: count >= captionMax,
    );
    return SingleChildScrollView(
      key: const ValueKey('import-caption-sheet'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.import_captionSheetEyebrow(day, dateLabel),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: UiText.h2(size: 20, color: ui.ink).copyWith(height: 1.35),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: UiChip(
              key: const ValueKey('import-caption-date'),
              label: l10n.import_captionEditDate,
              glyph: const OurneyIcon(name: 'calendar', flat: true, size: 18),
              onPressed: _editDate,
            ),
          ),
          const SizedBox(height: 8),
          if (!typing)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: UiCamera.bg,
                  constraints: BoxConstraints(
                    maxHeight: math.min(
                      224,
                      MediaQuery.sizeOf(context).height * .3,
                    ),
                  ),
                  child: Image.file(
                    File(_photo.path),
                    cacheWidth:
                        (MediaQuery.sizeOf(context).width *
                                MediaQuery.devicePixelRatioOf(context))
                            .round(),
                    fit: BoxFit.contain,
                    errorBuilder: (_, error, stack) =>
                        ImportThumb(path: _photo.path, height: 180),
                  ),
                ),
              ),
            ),
          Row(
            key: const ValueKey('import-caption-compose'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: typing ? 72 : 0,
                height: typing ? 96 : 0,
                child: typing
                    ? UiPressable(
                        onPressed: _focus.unfocus,
                        semanticLabel: l10n.import_captionHideKeyboard,
                        child: ImportThumb(path: _photo.path, height: 96),
                      )
                    : null,
              ),
              SizedBox(width: typing ? 12 : 0),
              Expanded(child: field),
            ],
          ),
          if (_controller.text.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.import_captionHelper,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: UiText.body(size: 12, height: 1.4, color: ui.inkMuted),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              UiIconButton(
                key: const ValueKey('import-caption-prev'),
                glyph: const OurneyIcon(name: 'chevron-left', flat: true),
                label: l10n.import_captionPrev,
                onPressed: _index == 0 ? null : () => _step(-1),
              ),
              UiIconButton(
                key: const ValueKey('import-caption-next'),
                glyph: const OurneyIcon(name: 'chevron-right', flat: true),
                label: l10n.import_captionNext,
                onPressed: _index == _ordered.length - 1
                    ? null
                    : () => _step(1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: UiButton(
                  key: const ValueKey('import-caption-done'),
                  label: l10n.import_captionDone,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
