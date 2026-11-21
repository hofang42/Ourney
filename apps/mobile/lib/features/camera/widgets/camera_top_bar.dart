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
/// bugs.md A1: the chip is one line. The text
/// shrinks to 13px before anything is cut; a name still too long glides once
/// to its end and back instead of ending in "...".
class CameraTopBar extends StatelessWidget {
  const CameraTopBar({
    required this.journeys,
    required this.selected,
    required this.onOpenPicker,
    required this.onRetry,
    required this.tools,
    this.chipLabel,
    this.accent,
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
    super.key,
  });

  final String name;
  final Color? accent;
  final String semanticLabel;
  final VoidCallback onPressed;

  static const _paper = Color(0xE0FFFFFF);
  static const _ink = Color(0xFF111114);

  @override
  Widget build(BuildContext context) {
    return UiPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(UiRadius.capsule),
      child: Container(
        constraints: const BoxConstraints(minHeight: UiSize.tap),
        padding: const EdgeInsetsDirectional.only(start: 14, end: 10),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(UiRadius.capsule),
          border: Border.all(color: UiCamera.shadow, width: UiBorder.standard),
          boxShadow: UiShadow.hard(UiCamera.shadow, UiShadow.tiny),
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
              child: _FitOrGlide(text: name, color: _ink),
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

/// One line of text: 15px, shrunk down to 13px to fit; if it still does not
/// fit, it scrolls once to the end and back (no motion when animations are
/// reduced: the start of the name stays visible and the full name is in the
/// semantics label and the journey picker).
class _FitOrGlide extends StatefulWidget {
  const _FitOrGlide({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  State<_FitOrGlide> createState() => _FitOrGlideState();
}

class _FitOrGlideState extends State<_FitOrGlide>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  String? _glidedFor;

  /// Hold, glide to the end, hold, glide back: one ticker-driven run (no
  /// timers, so it pauses with the tab and never outlives the widget).
  late final AnimationController _glide = AnimationController(vsync: this)
    ..addListener(() {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_path.value * _scroll.position.maxScrollExtent);
    });
  late final Animation<double> _path = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween<double>(0), weight: 15),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 0,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 50,
    ),
    TweenSequenceItem(tween: ConstantTween<double>(1), weight: 20),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 15,
    ),
  ]).animate(_glide);

  @override
  void dispose() {
    _glide.dispose();
    _scroll.dispose();
    super.dispose();
  }

  TextStyle _style(double size) => UiText.body(
    size: size,
    weight: FontWeight.w700,
    height: 1.3,
    color: widget.color,
  );

  void _glideOnce() {
    if (_glidedFor == widget.text) return;
    _glidedFor = widget.text;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (max <= 0 || UiMotion.of(context, UiMotion.theme) == Duration.zero) {
        return;
      }
      _glide
        ..duration = Duration(
          milliseconds: (max * 36).clamp(1600, 7000).toInt(),
        )
        ..forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        var size = 15.0;
        final scaler = MediaQuery.textScalerOf(context);
        bool fits(double s) {
          final p = TextPainter(
            text: TextSpan(text: widget.text, style: _style(s)),
            textDirection: Directionality.of(context),
            textScaler: scaler,
            maxLines: 1,
          )..layout();
          final ok = p.width <= box.maxWidth;
          p.dispose();
          return ok;
        }

        while (size > 13 && !fits(size)) {
          size -= 1;
        }
        final text = Text(
          widget.text,
          maxLines: 1,
          softWrap: false,
          style: _style(size),
        );
        if (fits(size)) return text;
        _glideOnce();
        return SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: text,
        );
      },
    );
  }
}
