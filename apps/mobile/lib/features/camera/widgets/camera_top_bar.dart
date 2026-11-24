import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../l10n/generated/camera_localizations.dart';

/// Camera top bar (Figma V2 `camera-safe-top`): the selected journey in one
/// chip on the left (accent dot, "Name · Day N", tap opens the searchable
/// picker), and the camera tools on the right (flash, grid, ghost guide).
///
/// The chip text shrinks to 13px before anything is cut; a name still too
/// long ends in an ellipsis (the full name is in the semantics label and the
/// picker).
class CameraTopBar extends StatelessWidget {
  const CameraTopBar({
    required this.journeys,
    required this.selected,
    required this.onOpenPicker,
    required this.onRetry,
    required this.tools,
    this.chipLabel,
    this.accent,
    this.direction = 1,
    super.key,
  });

  final AsyncValue<List<Journey>> journeys;
  final Journey? selected;
  final VoidCallback onOpenPicker;
  final VoidCallback onRetry;

  /// Tool buttons, already keyed (`capture-flash`, `capture-grid`, ...).
  final List<Widget> tools;

  /// Chip text, e.g. "Giảm cân · Ngày 12"; defaults to the journey title.
  final String? chipLabel;

  /// Persona accent of the chip dot.
  final Color? accent;

  /// Horizontal swipe direction (`>= 0` next journey, `< 0` previous journey).
  final int direction;

  @override
  Widget build(BuildContext context) {
    final l10n = CameraL10n.of(context);
    final Widget lead;
    if (journeys.hasError && !journeys.hasValue) {
      lead = Row(
        children: [
          OurneyIcon(
            name: 'error',
            flat: true,
            color: context.ui.danger,
            size: 20,
          ),
          const SizedBox(width: UiSpace.sm),
          Flexible(
            child: Text(
              l10n.camera_journeysError,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: UiText.body(size: 13, height: 1.35, color: UiCamera.ink),
            ),
          ),
          Flexible(
            child: UiTextAction(
              label: AppLocalizations.of(context).common_retry,
              onPressed: onRetry,
            ),
          ),
        ],
      );
    } else if (selected == null) {
      lead = const SizedBox(height: UiSize.tap);
    } else {
      lead = Align(
        alignment: AlignmentDirectional.centerStart,
        child: _NameChip(
          key: const ValueKey('capture-journey-chip'),
          name: chipLabel ?? selected!.title,
          accent: accent,
          direction: direction,
          semanticLabel:
              '${chipLabel ?? selected!.title}, ${l10n.camera_journeyPicker}',
          onPressed: onOpenPicker,
        ),
      );
    }
    return Row(
      children: [
        Expanded(child: lead),
        const SizedBox(width: UiSpace.xs),
        ...tools,
      ],
    );
  }
}

/// Glass capsule with the journey name and a caret.
class _NameChip extends StatelessWidget {
  const _NameChip({
    required this.name,
    required this.semanticLabel,
    required this.onPressed,
    this.accent,
    this.direction = 1,
    super.key,
  });

  final String name;
  final Color? accent;
  final int direction;
  final String semanticLabel;
  final VoidCallback onPressed;

  // Dark-only camera: cream glass over the viewfinder, camera bg as ink.
  static final _paper = UiCamera.ink.withValues(alpha: 0.88);
  static const _ink = UiCamera.bg;

  @override
  Widget build(BuildContext context) {
    return UiPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(UiRadius.capsule),
      shadowOffset: UiShadow.tiny,
      shadowColor: UiCamera.shadow,
      child: Container(
        constraints: const BoxConstraints(minHeight: UiSize.tap),
        padding: const EdgeInsetsDirectional.only(start: 14, end: 10),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(UiRadius.capsule),
          border: Border.all(color: UiCamera.shadow, width: UiBorder.standard),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (accent != null) ...[
              Container(
                key: const ValueKey('capture-chip-dot'),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: ClipRect(
                child: UiDirectionalSwitcher(
                  step: name,
                  direction: direction,
                  duration: UiMotion.fast,
                  slideOffset: 10.0,
                  alignment: AlignmentDirectional.centerStart,
                  child: _FitText(
                    key: ValueKey<String>(name),
                    text: name,
                    color: _ink,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const OurneyIcon(
              name: 'chevron-down',
              flat: true,
              size: 16,
              color: _ink,
            ),
          ],
        ),
      ),
    );
  }
}

typedef _FitCacheKey = ({
  String text,
  int maxWidthPx,
  int scalePermille,
  TextDirection direction,
});

/// 15px, shrunk down to 13px to fit; a name still too long ends in an
/// ellipsis (two lines at large text scales). The full name is in the
/// semantics label and the journey picker.
///
/// Caches resolved font sizes by `(text, maxWidth, textScale, direction)` so
/// `TextPainter.layout()` is never called in a loop on repeated builds or
/// animation ticks.
class _FitText extends StatelessWidget {
  const _FitText({required this.text, required this.color, super.key});

  final String text;
  final Color color;

  static final Map<_FitCacheKey, double> _sizeCache =
      <_FitCacheKey, double>{};

  TextStyle _style(double size) => UiText.body(
    size: size,
    weight: FontWeight.w700,
    height: 1.3,
    color: color,
  );

  double _resolveSize(
    String value,
    double maxWidth,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final widthPx = maxWidth.isFinite ? maxWidth.floor() : 10000;
    final scalePermille = (scaler.scale(16) * 1000 / 16).round();
    final key = (
      text: value,
      maxWidthPx: widthPx,
      scalePermille: scalePermille,
      direction: direction,
    );
    final cached = _sizeCache[key];
    if (cached != null) return cached;

    var size = 15.0;
    bool fits(double s) {
      final p = TextPainter(
        text: TextSpan(text: value, style: _style(s)),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final ok = p.width <= maxWidth;
      p.dispose();
      return ok;
    }

    while (size > 13 && !fits(size)) {
      size -= 1;
    }
    if (_sizeCache.length >= 64) {
      _sizeCache.remove(_sizeCache.keys.first);
    }
    _sizeCache[key] = size;
    return size;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final scaler = MediaQuery.textScalerOf(context);
        final dir = Directionality.of(context);
        final size = _resolveSize(text, box.maxWidth, scaler, dir);
        final big = scaler.scale(16) / 16 > 1.35;
        return Text(
          text,
          maxLines: big ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: _style(size),
        );
      },
    );
  }
}
