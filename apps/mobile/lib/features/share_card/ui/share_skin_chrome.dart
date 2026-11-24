import 'package:flutter/material.dart';

import '../../../app/theme/motion.dart';
import '../../../ui/ui.dart';
import '../l10n/generated/share_card_localizations.dart';

/// Per-skin chrome of the share screens (Figma `*TopBar`, `*-share-tabs`,
/// share buttons, `PosterShareSheet`, `SquadShareSheet`, `QuietPrivacySheet`).
/// Everything reads the nearest [UiSkinScope].

const Color _squadViolet = Color(0xFF7556F8);
const Color _memoryOlive = Color(0xFF4A6B53);
const Color _coupleBerry = Color(0xFF9D174D);

TextStyle _skinHeading(
  BuildContext context, {
  required double size,
  int weight = 700,
  double tracking = 0,
  Color? color,
}) {
  final skin = UiSkinScope.of(context);
  return UiText.heading(
    font: skin.headingFont,
    size: size,
    weight: weight,
    height: 1.35,
    tracking: tracking,
    color: color ?? context.ui.ink,
  );
}

/// `.<skin>-topbar`: 74dp row, 44dp back, centered title, 44dp spacer.
class ShareTopBar extends StatelessWidget {
  const ShareTopBar({
    required this.skinId,
    required this.title,
    required this.onBack,
    required this.backLabel,
    super.key,
  });

  final String skinId;
  final String title;
  final VoidCallback onBack;
  final String backLabel;

  /// Quiet skin: title and a "Private" pill. At large text scales the pill
  /// moves to its own line so neither loses its label.
  Widget _quietLabel(BuildContext context, String upper, ShareCardL10n l10n) {
    final ui = context.ui;
    final big = MediaQuery.textScalerOf(context).scale(16) / 16 > 1.2;
    final heading = Text(
      upper,
      maxLines: big ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: UiText.body(
        size: 12,
        weight: FontWeight.w700,
        tracking: 0.08,
        color: ui.ink,
      ),
    );
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: ui.border),
        borderRadius: BorderRadius.circular(UiRadius.capsule),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OurneyIcon(name: 'lock', flat: true, size: 13, color: ui.ink),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              l10n.share_card_quietPrivate,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.body(size: 12, height: 1.3, color: ui.ink),
            ),
          ),
        ],
      ),
    );
    if (big) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [heading, const SizedBox(height: 4), pill],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: heading),
        const SizedBox(width: 7),
        Flexible(child: pill),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = ShareCardL10n.of(context);
    final upper = title.toUpperCase();
    final big = MediaQuery.textScalerOf(context).scale(16) / 16 > 1.2;
    final Widget label = switch (skinId) {
      'quiet' => _quietLabel(context, upper, l10n),
      _ => Text(
        upper,
        maxLines: big ? 2 : 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: switch (skinId) {
          'memory' => const TextStyle(
            fontFamily: UiFonts.mono,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.35,
            letterSpacing: 0.72,
          ),
          'flexer' => _skinHeading(context, size: 15, tracking: 0.12),
          'minimal' => UiText.body(
            size: 12,
            weight: FontWeight.w500,
            height: 1.35,
            tracking: 0.06,
          ),
          _ => _skinHeading(
            context,
            size: 12,
            weight: skinId == 'couple' ? 600 : 700,
            tracking: 0.08,
          ),
        }.copyWith(color: ui.ink),
      ),
    };
    final border = switch (skinId) {
      'squad' => Border(
        bottom: BorderSide(color: ui.outline, width: UiBorder.standard),
      ),
      'memory' => Border(bottom: BorderSide(color: ui.outline)),
      _ => null,
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      decoration: BoxDecoration(color: ui.bg, border: border),
      child: Row(
        children: [
          UiPressable(
            key: const ValueKey('share-card-back'),
            onPressed: onBack,
            semanticLabel: backLabel,
            excludeChildSemantics: true,
            minSize: const Size.square(UiSize.tap),
            centerChild: true,
            borderRadius: BorderRadius.circular(UiRadius.capsule),
            child: SizedBox.square(
              dimension: 44,
              child: Center(
                child: OurneyIcon(
                  name: 'back',
                  flat: true,
                  size: 21,
                  color: ui.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: label),
          const SizedBox(width: 8 + UiSize.tap),
        ],
      ),
    );
  }
}

/// `*-share-tabs`: the 9:16 / 4:5 switch, drawn per skin.
class ShareRatioTabs<T> extends StatelessWidget {
  const ShareRatioTabs({
    required this.skinId,
    required this.values,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String skinId;

  /// `(value, label)` pairs, left to right.
  final List<(T, String)> values;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final v = UiSkinScope.of(context).variant;
    final flexer = skinId == 'flexer';
    final minimal = skinId == 'minimal';
    final quiet = skinId == 'quiet';

    // (selected fill, selected label, selected outline)
    final (Color selFill, Color selInk, Color? selBorder) = switch (skinId) {
      'squad' => (v.button, const Color(0xFF1A1A1A), ui.outline),
      'memory' => (v.button, Colors.white, ui.outline),
      'couple' => (v.button, const Color(0xFF1A1316), null),
      'flexer' => (v.accent, const Color(0xFF090A0F), null),
      'minimal' => (v.button, const Color(0xFF1C1C1E), null),
      _ => (Colors.transparent, ui.ink, null),
    };

    Widget tab((T, String) item) {
      final selected = item.$1 == value;
      final radius = BorderRadius.circular(minimal ? 8 : UiRadius.capsule);
      final decoration = quiet
          ? BoxDecoration(
              border: Border(
                bottom: selected
                    ? BorderSide(color: ui.outline, width: UiBorder.standard)
                    : BorderSide.none,
              ),
            )
          : BoxDecoration(
              color: selected ? selFill : (minimal ? ui.surface : null),
              borderRadius: radius,
              border: selected && selBorder != null
                  ? Border.all(color: selBorder, width: UiBorder.standard)
                  : (flexer && !selected
                        ? Border.all(color: ui.ink.withValues(alpha: 0.25))
                        : (minimal
                              ? Border.all(
                                  color: ui.outline,
                                  width: UiBorder.standard,
                                )
                              : null)),
            );
      final label = Text(
        item.$2,
        maxLines: 1,
        style: UiText.body(
          size: 15,
          weight: FontWeight.w700,
          height: 1.3,
          color: quiet
              ? (selected ? ui.ink : ui.inkMuted)
              : (selected ? selInk : ui.ink),
        ),
      );
      final child = Container(
        alignment: Alignment.center,
        constraints: const BoxConstraints(minHeight: 44),
        padding: EdgeInsets.symmetric(horizontal: flexer || minimal ? 15 : 8),
        decoration: decoration,
        child: label,
      );
      final pressable = UiPressable(
        key: ValueKey('share-card-format-${item.$2}'),
        onPressed: () {
          OurneyHaptics.selection();
          onChanged(item.$1);
        },
        selected: selected,
        semanticLabel: item.$2,
        excludeChildSemantics: true,
        borderRadius: radius,
        // 44dp visual inside a 48dp hit box (U5).
        minSize: const Size(UiSize.tap, UiSize.tap),
        centerChild: true,
        child: child,
      );
      return flexer || minimal ? pressable : Expanded(child: pressable);
    }

    final row = Row(
      mainAxisSize: flexer || minimal ? MainAxisSize.min : MainAxisSize.max,
      children: [
        for (var i = 0; i < values.length; i++) ...[
          if (i > 0 && (flexer || minimal)) const SizedBox(width: 7),
          tab(values[i]),
        ],
      ],
    );
    final Widget body = switch (skinId) {
      'quiet' => DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: ui.border)),
        ),
        child: row,
      ),
      'squad' || 'memory' || 'couple' => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: skinId == 'couple' ? ui.surface : ui.surface,
          borderRadius: BorderRadius.circular(UiRadius.capsule),
          border: Border.all(
            color: skinId == 'couple'
                ? ui.ink.withValues(alpha: 0.2)
                : ui.outline,
            width: skinId == 'couple' ? UiBorder.hairline : UiBorder.standard,
          ),
          boxShadow: switch (skinId) {
            'squad' => [
              BoxShadow(
                color: ui.hardShadowColor,
                offset: const Offset(0, UiShadow.small),
              ),
            ],
            'memory' => [
              BoxShadow(
                color: ui.hardShadowColor,
                offset: const Offset(UiShadow.small, UiShadow.small),
              ),
            ],
            _ => null,
          },
        ),
        child: row,
      ),
      _ => Align(alignment: Alignment.centerLeft, child: row),
    };
    return KeyedSubtree(key: const ValueKey('share-card-format'), child: body);
  }
}

/// The big call-to-action under the card: `quiet-export`, `squad-share-button`,
/// `memory-share-button`, `couple-share-button`, `flexer-primary`,
/// `minimal-export`.
class ShareActionButton extends StatelessWidget {
  const ShareActionButton({
    required this.skinId,
    required this.label,
    required this.onPressed,
    this.glyph,
    this.loading = false,
    super.key,
  });

  final String skinId;
  final String label;
  final VoidCallback? onPressed;
  final String? glyph;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final v = UiSkinScope.of(context).variant;
    final (
      Color fill,
      Color fg,
      Border? border,
      List<BoxShadow>? shadow,
      double r,
    ) = switch (skinId) {
      'squad' => (
        _squadViolet,
        Colors.white,
        Border.all(color: ui.outline, width: UiBorder.standard),
        [
          BoxShadow(
            color: ui.hardShadowColor,
            offset: const Offset(0, UiShadow.small),
          ),
        ],
        UiRadius.capsule,
      ),
      'memory' => (
        _memoryOlive,
        ui.isDark ? ui.ink : Colors.white,
        Border.all(color: ui.outline, width: UiBorder.standard),
        [
          BoxShadow(
            color: ui.hardShadowColor,
            offset: const Offset(UiShadow.small, UiShadow.small),
          ),
        ],
        UiRadius.capsule,
      ),
      'couple' => (
        v.button,
        const Color(0xFF1A1316),
        Border.all(color: ui.outline, width: UiBorder.standard),
        [
          const BoxShadow(
            color: _coupleBerry,
            offset: Offset(UiShadow.small, UiShadow.small),
          ),
        ],
        UiRadius.capsule,
      ),
      'flexer' => (
        v.button,
        const Color(0xFF090A0F),
        Border.all(color: v.accent, width: UiBorder.thin),
        [
          BoxShadow(color: v.accent, blurRadius: 10),
          BoxShadow(
            color: v.accent,
            offset: const Offset(UiShadow.large, UiShadow.large),
          ),
        ],
        UiRadius.capsule,
      ),
      'minimal' => (
        ui.isDark ? const Color(0xFF3F3F46) : const Color(0xFF27272A),
        Colors.white,
        null,
        null,
        8.0,
      ),
      _ => (
        const Color(0xFF111827),
        Colors.white,
        null,
        null,
        UiRadius.capsule,
      ),
    };
    return UiPressable(
      onPressed: onPressed,
      semanticLabel: label,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(r),
      minSize: const Size(48, 48),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: onPressed == null ? fill.withValues(alpha: 0.6) : fill,
          borderRadius: BorderRadius.circular(r),
          border: border,
          boxShadow: shadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox.square(
                dimension: 19,
                child: UiSpinner(strokeWidth: 2, color: fg),
              )
            else if (glyph != null)
              OurneyIcon(name: glyph!, flat: true, size: 19, color: fg),
            if (loading || glyph != null) const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: UiText.body(
                  size: 14,
                  weight: skinId == 'minimal'
                      ? FontWeight.w500
                      : FontWeight.w700,
                  height: 1.4,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.quiet-share-controls`: the privacy note and the "Ẩn chữ ourney" switch.
class QuietShareControls extends StatelessWidget {
  const QuietShareControls({
    required this.note,
    required this.hideBrand,
    required this.onHideBrand,
    super.key,
  });

  final String? note;
  final bool hideBrand;
  final ValueChanged<bool> onHideBrand;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = ShareCardL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OurneyIcon(
                  name: 'lock',
                  flat: true,
                  size: 15,
                  color: ui.inkMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    note!,
                    key: const ValueKey('share-card-metric-hidden'),
                    style: UiText.body(
                      size: 12,
                      height: 1.45,
                      color: ui.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              ui.inkMuted.withValues(alpha: 0.12),
              ui.surface,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: UiSwitchRow(
            key: const ValueKey('share-card-hide-brand'),
            label: l10n.share_card_hideBrand,
            value: hideBrand,
            divider: false,
            onChanged: onHideBrand,
          ),
        ),
      ],
    );
  }
}

/// `PosterShareSheet` / `SquadShareSheet`: title, "Ẩn chữ ourney" toggle
/// row, then Messages / Other apps / Save image.
Future<void> showShareSheet({
  required BuildContext context,
  required String skinId,
  required String title,
  required bool hideBrand,
  required ValueChanged<bool> onHideBrand,
  required VoidCallback onAction,
}) {
  var hidden = hideBrand;
  return showUiSheet<void>(
    context: context,
    accent: const Color(0x00000000),
    builder: (sheetContext) => UiSkinScope(
      skinId: skinId,
      child: StatefulBuilder(
        builder: (context, setState) {
          final ui = context.ui;
          final l10n = ShareCardL10n.of(context);
          final close = MaterialLocalizations.of(context).closeButtonLabel;
          final (
            Color fill,
            double radius,
            Border border,
            List<BoxShadow>? sh,
          ) = switch (skinId) {
            'squad' => (
              ui.surface,
              14.0,
              Border.all(color: ui.outline, width: UiBorder.standard),
              [
                BoxShadow(
                  color: ui.hardShadowColor,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            'memory' => (
              ui.surface,
              14.0,
              Border.all(color: ui.outline, width: UiBorder.standard),
              [
                BoxShadow(
                  color: ui.hardShadowColor,
                  offset: const Offset(3, 3),
                ),
              ],
            ),
            'couple' => (
              ui.surface,
              14.0,
              Border.all(color: ui.ink.withValues(alpha: 0.2)),
              [
                BoxShadow(
                  color: ui.ink.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            'flexer' => (
              ui.surface,
              14.0,
              Border.all(color: UiSkinScope.of(context).variant.accent),
              null,
            ),
            _ => (
              ui.surface,
              8.0,
              Border.all(color: ui.outline, width: UiBorder.standard),
              [
                BoxShadow(
                  color: ui.hardShadowColor,
                  offset: const Offset(3, 3),
                ),
              ],
            ),
          };
          Widget row(
            Widget child, {
            VoidCallback? onTap,
            Key? key,
            String? label,
          }) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: UiPressable(
              key: key,
              onPressed: onTap,
              semanticLabel: label,
              excludeChildSemantics: label != null,
              borderRadius: BorderRadius.circular(radius),
              minSize: const Size(48, 48),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(radius),
                  border: border,
                  boxShadow: sh,
                ),
                child: child,
              ),
            ),
          );
          Widget action(String label, String key) => row(
            Center(
              child: Text(
                label,
                style: UiText.body(
                  size: 15,
                  weight: FontWeight.w700,
                  height: 1.4,
                  color: ui.ink,
                ),
              ),
            ),
            key: ValueKey(key),
            label: label,
            onTap: () {
              Navigator.of(sheetContext).pop();
              onAction();
            },
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        title,
                        key: const ValueKey('share-card-sheet-title'),
                        style: _skinHeading(
                          context,
                          size: 24,
                          weight: skinId == 'memory' || skinId == 'minimal'
                              ? 300
                              : 700,
                        ),
                      ),
                    ),
                  ),
                  UiPressable(
                    key: const ValueKey('share-card-sheet-close'),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    semanticLabel: close,
                    excludeChildSemantics: true,
                    minSize: const Size.square(44),
                    borderRadius: BorderRadius.circular(UiRadius.capsule),
                    child: SizedBox.square(
                      dimension: 44,
                      child: Center(
                        child: OurneyIcon(
                          name: 'close',
                          flat: true,
                          size: 21,
                          color: ui.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              row(
                Row(
                  children: [
                    OurneyIcon(
                      name: hidden ? 'eye-off' : 'eye',
                      flat: true,
                      size: 20,
                      color: ui.ink,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.share_card_hideBrand,
                        style: UiText.body(
                          size: 15,
                          weight: FontWeight.w700,
                          height: 1.4,
                          color: ui.ink,
                        ),
                      ),
                    ),
                    Text(
                      hidden
                          ? l10n.share_card_brandOn
                          : l10n.share_card_brandOff,
                      key: const ValueKey('share-card-sheet-brand-state'),
                      style: UiText.body(size: 12, height: 1.4, color: ui.ink),
                    ),
                  ],
                ),
                key: const ValueKey('share-card-sheet-brand'),
                label: l10n.share_card_hideBrand,
                onTap: () {
                  setState(() => hidden = !hidden);
                  onHideBrand(hidden);
                },
              ),
              action(
                l10n.share_card_sheetMessages,
                'share-card-sheet-messages',
              ),
              action(l10n.share_card_sheetOther, 'share-card-sheet-other'),
              action(l10n.share_card_sheetSave, 'share-card-sheet-save'),
            ],
          );
        },
      ),
    ),
  );
}

/// `QuietPrivacySheet`: "Hiện số kg trên thẻ?". Resolves true when the user
/// chooses "Vẫn hiện", false for "Giữ ẩn" / dismiss.
Future<bool> showQuietPrivacySheet(BuildContext context) async {
  final result = await showUiSheet<bool>(
    context: context,
    builder: (sheetContext) {
      final ui = sheetContext.ui;
      final l10n = ShareCardL10n.of(sheetContext);
      final close = MaterialLocalizations.of(sheetContext).closeButtonLabel;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l10n.share_card_privacyTitle,
                    key: const ValueKey('share-card-privacy-title'),
                    style: UiText.heading(
                      font: 'Fraunces',
                      size: 25,
                      weight: 300,
                      height: 1.25,
                      color: ui.ink,
                    ),
                  ),
                ),
              ),
              UiPressable(
                onPressed: () => Navigator.of(sheetContext).pop(false),
                semanticLabel: close,
                excludeChildSemantics: true,
                minSize: const Size.square(44),
                borderRadius: BorderRadius.circular(UiRadius.capsule),
                child: SizedBox.square(
                  dimension: 44,
                  child: Center(
                    child: OurneyIcon(
                      name: 'close',
                      flat: true,
                      size: 21,
                      color: ui.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.share_card_privacyBody,
            style: UiText.body(size: 13, height: 1.5, color: ui.inkMuted),
          ),
          const SizedBox(height: 16),
          UiButton(
            key: const ValueKey('share-card-privacy-keep'),
            label: l10n.share_card_privacyKeep,
            onPressed: () => Navigator.of(sheetContext).pop(false),
          ),
          const SizedBox(height: 7),
          UiButton(
            key: const ValueKey('share-card-privacy-show'),
            label: l10n.share_card_privacyShow,
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
