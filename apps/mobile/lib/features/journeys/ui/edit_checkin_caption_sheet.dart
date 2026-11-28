import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../checkin/l10n/generated/checkin_localizations.dart';
import '../data/journeys_providers.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'journey_photo.dart';
import 'journey_style.dart';

Future<void> showEditCheckInCaptionSheet(
  BuildContext context, {
  required CheckIn checkIn,
  required Journey journey,
  required LocalDate today,
}) => showUiSheet<void>(
  context: context,
  builder: (_) => UiSkinScope(
    skinId: uiSkinIdFor(skinOfJourney(journey)),
    variant: journey.color ?? 0,
    child: EditCheckInCaptionSheet(
      checkIn: checkIn,
      journey: journey,
      today: today,
    ),
  ),
);

class EditCheckInCaptionSheet extends ConsumerStatefulWidget {
  const EditCheckInCaptionSheet({
    required this.checkIn,
    required this.journey,
    required this.today,
    super.key,
  });

  final CheckIn checkIn;
  final Journey journey;
  final LocalDate today;

  @override
  ConsumerState<EditCheckInCaptionSheet> createState() =>
      _EditCheckInCaptionSheetState();
}

class _EditCheckInCaptionSheetState
    extends ConsumerState<EditCheckInCaptionSheet> {
  late final _controller = TextEditingController(text: widget.checkIn.caption);
  bool _saving = false;
  OurneyErrorCode? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save({bool clear = false}) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(checkInRepositoryProvider)
          .updateCaption(widget.checkIn.id, clear ? null : _controller.text);
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      final cause = rootError(error);
      final code = cause is OurneyException ? cause.error : null;
      if (code == OurneyErrorCode.ended || code == OurneyErrorCode.forbidden) {
        showUiToast(context, AppLocalizations.of(context).common_errorGeneric);
        Navigator.of(context).pop();
        return;
      }
      if (code == OurneyErrorCode.contentPolicy) {
        unawaited(UiHaptics.reject());
      }
      setState(() {
        _saving = false;
        _error = code ?? OurneyErrorCode.unknown;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    final template = templateFor(widget.journey.templateId);
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    final past = widget.checkIn.localDate.isBefore(widget.today);
    final prompt = past
        ? (vi ? template.retellCaptionPromptVi : template.retellCaptionPromptEn)
        : (vi ? template.captionPromptVi : template.captionPromptEn);
    final date = widget.checkIn.localDate;
    final label = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(DateTime(date.year, date.month, date.day));
    final count = _controller.text.runes.length;
    final counter = CheckinL10n.of(context);
    final error = switch (_error) {
      null => null,
      OurneyErrorCode.contentPolicy => l10n.journeys_captionContentPolicy,
      OurneyErrorCode.offline => l10n.journeys_captionOffline,
      _ => AppLocalizations.of(context).common_errorGeneric,
    };
    return PopScope(
      canPop: !_saving,
      child: Column(
        key: const ValueKey('edit-checkin-caption-sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.journeys_captionSheetTitle,
            style: UiText.h2(color: ui.ink).copyWith(height: 1.35),
          ),
          const SizedBox(height: UiSpace.md),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(UiRadius.otp),
                child: SizedBox(
                  width: 72,
                  height: 96,
                  child: JourneyPhoto(checkIn: widget.checkIn),
                ),
              ),
              const SizedBox(width: UiSpace.md),
              Expanded(
                child: Text(
                  l10n.journeys_dayCaptionDate(
                    widget.journey.startDate.daysUntil(date) + 1,
                    label,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.body(height: 1.35, color: ui.inkMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: UiSpace.md),
          UiCaptionField(
            fieldKey: const ValueKey('edit-checkin-caption-field'),
            controller: _controller,
            semanticLabel: l10n.journeys_captionSheetTitle,
            hint: prompt,
            readOnly: _saving,
            inputFormatters: const [CodePointLimitFormatter(captionMax)],
            counter: count >= 120
                ? counter.checkin_captionCounter(count, captionMax)
                : null,
            counterSemantics: counter.checkin_captionCounterSemantics(
              count,
              captionMax,
            ),
            counterDanger: count >= captionMax,
            onChanged: (_) => setState(() {}),
          ),
          if (widget.journey.visibility == JourneyVisibility.link) ...[
            const SizedBox(height: UiSpace.sm),
            Text(
              l10n.journeys_captionPublicHint,
              style: UiText.body(size: 12, height: 1.4, color: ui.inkMuted),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: UiSpace.sm),
            Semantics(
              liveRegion: true,
              child: Text(
                error,
                key: const ValueKey('edit-checkin-caption-error'),
                style: UiText.body(size: 14, height: 1.4, color: ui.danger),
              ),
            ),
          ],
          const SizedBox(height: UiSpace.lg),
          UiButton(
            key: const ValueKey('edit-checkin-caption-save'),
            label: l10n.journeys_captionSave,
            loading: _saving,
            onPressed: _saving ? null : () => _save(),
          ),
          if (normalizeCaption(widget.checkIn.caption) != null ||
              normalizeCaption(_controller.text) != null)
            UiButton.ghost(
              key: const ValueKey('edit-checkin-caption-clear'),
              label: l10n.journeys_captionClear,
              onPressed: _saving ? null : () => _save(clear: true),
            ),
        ],
      ),
    );
  }
}
