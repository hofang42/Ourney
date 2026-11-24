import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../app/theme/motion.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../safety/safety_paths.dart';
import '../data/feedback_providers.dart';
import '../l10n/generated/feedback_localizations.dart';
import 'feedback_common.dart';

/// Result returned when the Create/Edit sheet closes.
sealed class CreateFeatureRequestResult {
  const CreateFeatureRequestResult();
}

/// User created or edited a request.
class FeatureRequestSaved extends CreateFeatureRequestResult {
  const FeatureRequestSaved(this.request, {required this.isEdit});
  final FeatureRequest request;
  final bool isEdit;
}

/// User tapped a duplicate suggestion (optionally casting a +1 vote) to jump
/// to that existing request.
class FeatureRequestDeflected extends CreateFeatureRequestResult {
  const FeatureRequestDeflected(this.requestId);
  final String requestId;
}

/// Opens the Create / Edit Feature Request bottom sheet (`showUiSheet`).
Future<CreateFeatureRequestResult?> showCreateFeatureRequestSheet(
  BuildContext context, {
  FeatureRequest? existing,
  String? initialTitle,
}) =>
    showUiSheet<CreateFeatureRequestResult>(
      context: context,
      builder: (context) => CreateFeatureRequestSheet(
        existing: existing,
        initialTitle: initialTitle,
      ),
    );

class CreateFeatureRequestSheet extends ConsumerStatefulWidget {
  const CreateFeatureRequestSheet({
    this.existing,
    this.initialTitle,
    super.key,
  });

  final FeatureRequest? existing;
  final String? initialTitle;

  bool get isEdit => existing != null;

  @override
  ConsumerState<CreateFeatureRequestSheet> createState() =>
      _CreateFeatureRequestSheetState();
}

class _CreateFeatureRequestSheetState
    extends ConsumerState<CreateFeatureRequestSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late FeatureRequestCategory _category;

  /// Stable client-generated UUID for idempotent creation retries.
  late final String _draftId;

  Timer? _similarDebounce;
  List<FeatureRequest> _similar = const [];
  bool _submitting = false;
  bool _submittedSuccessfully = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _draftId = existing.id;
      _titleController = TextEditingController(text: existing.title);
      _bodyController = TextEditingController(text: existing.body);
      _category = existing.category;
    } else {
      final savedDraft = ref.read(feedbackDraftProvider);
      _draftId =
          (savedDraft?.id != null && savedDraft!.id!.trim().isNotEmpty)
              ? savedDraft.id!.trim()
              : const Uuid().v4();
      final prefillTitle =
          (widget.initialTitle != null && widget.initialTitle!.trim().isNotEmpty)
              ? widget.initialTitle!.trim()
              : (savedDraft?.title ?? '');
      _titleController = TextEditingController(text: prefillTitle);
      _bodyController = TextEditingController(text: savedDraft?.body ?? '');
      _category = savedDraft?.category ?? FeatureRequestCategory.other;
      if (prefillTitle.runes.length >= 3) {
        _scheduleSimilarSearch(prefillTitle);
      }
    }
  }

  @override
  void dispose() {
    _similarDebounce?.cancel();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _persistDraft() {
    if (widget.isEdit || _submittedSuccessfully) return;
    final draft = FeedbackComposeDraft(
      id: _draftId,
      title: _titleController.text,
      body: _bodyController.text,
      category: _category,
    );
    unawaited(ref.read(feedbackDraftProvider.notifier).save(draft));
  }

  void _onTitleChanged(String value) {
    if (_error != null || _similar.isNotEmpty) {
      setState(() {
        _error = null;
        _similar = const [];
      });
    }
    _persistDraft();
    if (widget.isEdit) return;
    _scheduleSimilarSearch(value);
  }

  void _scheduleSimilarSearch(String raw) {
    _similarDebounce?.cancel();
    if (_similar.isNotEmpty) {
      setState(() => _similar = const []);
    }
    final trimmed = raw.trim();
    if (trimmed.runes.length < 3) {
      return;
    }
    _similarDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final matches = await ref
            .read(featureRequestRepositoryProvider)
            .searchSimilar(trimmed, limit: 3);
        if (!mounted || _titleController.text.trim() != trimmed) return;
        setState(() => _similar = matches.take(3).toList());
      } on Object {
        // Ignore live duplicate search errors (e.g. offline) while typing.
      }
    });
  }

  Future<void> _upvoteAndOpenSimilar(FeatureRequest match) async {
    OurneyHaptics.selection();
    final overlaid =
        ref.read(feedbackVoteOverlayProvider.notifier).applyTo(match);
    if (overlaid.canVote && !overlaid.votedByMe) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      final notifier = ref.read(feedbackVoteOverlayProvider.notifier);
      unawaited(
        notifier.toggle(overlaid).then((err) {
          if (err != null && messenger != null && messenger.mounted) {
            OurneyHaptics.warning();
            showUiToast(
              messenger.context,
              feedbackErrorMessage(messenger.context, OurneyException(err)),
              messenger: messenger,
            );
          }
        }),
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop(FeatureRequestDeflected(match.id));
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l10n = FeedbackL10n.of(context);
    final title = _titleController.text;
    final body = _bodyController.text;

    final titleErr = validateFeatureRequestTitle(title);
    if (titleErr != null) {
      OurneyHaptics.warning();
      setState(() {
        _error = switch (titleErr) {
          FeatureRequestTitleError.tooShort ||
          FeatureRequestTitleError.tooLong =>
            l10n.feedback_errorTitleLength,
          FeatureRequestTitleError.linksNotAllowed =>
            l10n.feedback_errorLinksNotAllowed,
        };
      });
      return;
    }

    final bodyErr = validateFeatureRequestBody(body);
    if (bodyErr != null) {
      OurneyHaptics.warning();
      setState(() {
        _error = switch (bodyErr) {
          FeatureRequestBodyError.tooShort ||
          FeatureRequestBodyError.tooLong =>
            l10n.feedback_errorBodyLength,
          FeatureRequestBodyError.linksNotAllowed =>
            l10n.feedback_errorLinksNotAllowed,
        };
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final repo = ref.read(featureRequestRepositoryProvider);
      final FeatureRequest saved;
      if (widget.isEdit) {
        saved = await repo.update(
          id: widget.existing!.id,
          title: title.trim(),
          body: body.trim(),
          category: _category,
        );
      } else {
        saved = await repo.create(
          id: _draftId,
          title: title.trim(),
          body: body.trim(),
          category: _category,
        );
        _submittedSuccessfully = true;
        await ref.read(feedbackDraftProvider.notifier).clear();
      }
      if (!mounted) return;
      OurneyHaptics.selection();
      Navigator.of(
        context,
      ).pop(FeatureRequestSaved(saved, isEdit: widget.isEdit));
    } on Object catch (e) {
      if (!mounted) return;
      OurneyHaptics.warning();
      final code = feedbackErrorCode(e);
      if (!widget.isEdit) {
        await ref.read(feedbackDraftProvider.notifier).save(
              FeedbackComposeDraft(
                id: _draftId,
                title: title,
                body: body,
                category: _category,
              ),
            );
        if (!mounted) return;
      }
      if (code == OurneyErrorCode.offline && !widget.isEdit) {
        setState(() => _error = l10n.feedback_errorOfflineDraftSaved);
      } else {
        setState(
          () => _error = feedbackErrorMessage(
            context,
            e,
            forCreate: !widget.isEdit,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FeedbackL10n.of(context);
    final app = AppLocalizations.of(context);
    final ui = context.ui;
    final voteOverlay = ref.watch(feedbackVoteOverlayProvider);

    return Column(
      key: const ValueKey('feedback-compose-sheet'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            widget.isEdit
                ? l10n.feedback_editSheetTitle
                : l10n.feedback_createSheetTitle,
            style: UiText.h2(color: ui.ink),
          ),
        ),
        const SizedBox(height: UiSpace.xs),
        Text(
          l10n.feedback_createSheetSub,
          style: UiText.muted(color: ui.inkMuted, size: 14),
        ),
        const SizedBox(height: UiSpace.lg),
        UiTextField(
          fieldKey: const ValueKey('feedback-title-input'),
          label: l10n.feedback_fieldTitleLabel,
          hint: l10n.feedback_fieldTitleHint,
          controller: _titleController,
          textCapitalization: TextCapitalization.sentences,
          inputFormatters: [
            LengthLimitingTextInputFormatter(featureRequestTitleMax),
          ],
          onChanged: _onTitleChanged,
        ),
        if (!widget.isEdit && _similar.isNotEmpty) ...[
          const SizedBox(height: UiSpace.md),
          UiCard(
            key: const ValueKey('feedback-similar-card'),
            color: ui.fill,
            shadowOffset: 0,
            padding: const EdgeInsets.all(UiSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.feedback_similarHeading,
                  style: UiText.fieldLabel(color: ui.inkMuted),
                ),
                const SizedBox(height: UiSpace.sm),
                for (final (idx, rawMatch) in _similar.indexed) ...[
                  if (idx > 0) ...[
                    const SizedBox(height: UiSpace.sm),
                    const UiDivider(),
                    const SizedBox(height: UiSpace.sm),
                  ],
                  Builder(
                    builder: (context) {
                      final ov = voteOverlay[rawMatch.id];
                      final match = ov == null
                          ? rawMatch
                          : rawMatch.copyWith(
                              votedByMe: ov.votedByMe,
                              voteCount: ov.voteCount,
                            );
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  match.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: UiText.body(
                                    size: 14,
                                    weight: FontWeight.w700,
                                    height: 1.35,
                                    color: ui.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                FeedbackStatusTag(status: match.status),
                              ],
                            ),
                          ),
                          const SizedBox(width: UiSpace.sm),
                          UiChip(
                            key: ValueKey('feedback-similar-vote-${match.id}'),
                            label: l10n.feedback_similarVoteChip(
                              match.voteCount,
                            ),
                            selected: match.votedByMe,
                            onPressed: () => _upvoteAndOpenSimilar(match),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: UiSpace.lg),
        Text(
          l10n.feedback_fieldCategoryLabel,
          style: UiText.fieldLabel(color: ui.inkMuted),
        ),
        const SizedBox(height: UiSpace.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final cat in FeatureRequestCategory.values)
              UiChip(
                key: ValueKey('feedback-cat-chip-${cat.wireName}'),
                label: feedbackCategoryLabel(l10n, cat),
                selected: _category == cat,
                onPressed: () {
                  OurneyHaptics.selection();
                  setState(() => _category = cat);
                  _persistDraft();
                },
              ),
          ],
        ),
        const SizedBox(height: UiSpace.lg),
        UiTextArea(
          fieldKey: const ValueKey('feedback-body-input'),
          label: l10n.feedback_fieldBodyLabel,
          hint: l10n.feedback_fieldBodyHint,
          controller: _bodyController,
          minLines: 3,
          maxLines: 6,
          maxLength: featureRequestBodyMax,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
            _persistDraft();
          },
        ),
        if (!widget.isEdit) ...[
          const SizedBox(height: UiSpace.xs),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: UiTextAction(
              key: const ValueKey('feedback-bug-contact-link'),
              label: l10n.feedback_bugEmailLink,
              expand: false,
              size: 13,
              alignment: AlignmentDirectional.centerStart,
              underline: true,
              onPressed: () {
                Navigator.of(context).pop();
                context.push(SafetyPaths.contact);
              },
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: UiSpace.md),
          UiInlineError(
            key: const ValueKey('feedback-compose-error'),
            message: _error!,
          ),
        ],
        const SizedBox(height: UiSpace.lg),
        UiButton(
          key: const ValueKey('feedback-compose-submit'),
          label: widget.isEdit
              ? l10n.feedback_saveChanges
              : l10n.feedback_submitAction,
          glyph: const OurneyIcon(name: 'send', flat: true),
          loading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
        const SizedBox(height: UiSpace.sm),
        UiTextAction(
          key: const ValueKey('feedback-compose-cancel'),
          label: app.common_cancel,
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
