import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'buttons.dart';

/// V2 `.app-sheet`: 24dp top radius, 2dp outline on top/left/right only,
/// hard `0 -4px 0` top shadow in [accent], grabber, solid `ui.bg` body.
/// Enter motion (190ms ease-out) is supplied by [showUiSheet]. Content scrolls
/// when taller than the available height, so large text never overflows.
class UiSheet extends StatelessWidget {
  const UiSheet({
    required this.child,
    this.showGrabber = true,
    this.accent,
    super.key,
  });

  final Widget child;
  final bool showGrabber;

  /// Top hard-shadow color (`--accent`). Defaults to `context.ui.brand`.
  final Color? accent;

  static const double radius = 24;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    const outer = BorderRadius.vertical(top: Radius.circular(radius));
    const inner = BorderRadius.vertical(
      top: Radius.circular(radius - UiBorder.standard),
    );
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: UiSpace.maxContent(width) + 40,
          maxHeight: mq.size.height * 0.92,
        ),
        // A non-uniform border cannot follow a radius, so the 2dp outline is
        // the ink-colored outer shape and the solid body is inset on top/sides.
        child: DecoratedBox(
          key: const ValueKey('ui-sheet-outline'),
          decoration: BoxDecoration(
            color: ui.outline,
            borderRadius: outer,
            boxShadow: [
              BoxShadow(
                color: accent ?? ui.brand,
                offset: const Offset(0, -UiShadow.large),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              UiBorder.standard,
              UiBorder.standard,
              UiBorder.standard,
              0,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(color: ui.bg, borderRadius: inner),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  UiSpace.xl,
                  12,
                  UiSpace.xl,
                  28 + mq.viewPadding.bottom + mq.viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showGrabber) ...[
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: ui.grabber,
                            borderRadius: BorderRadius.circular(
                              UiRadius.capsule,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: UiSpace.lg),
                    ],
                    Flexible(child: SingleChildScrollView(child: child)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens [builder] in a [UiSheet] over the `.app-sheet-scrim` scrim.
Future<T?> showUiSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool dismissible = true,
  bool useRootNavigator = true,
  Color? accent,
}) {
  final ui = context.ui;
  final duration = UiMotion.of(context, const Duration(milliseconds: 190));
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    isDismissible: dismissible,
    enableDrag: dismissible,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: ui.scrim,
    constraints: const BoxConstraints(maxWidth: double.infinity),
    sheetAnimationStyle: AnimationStyle(
      duration: duration,
      reverseDuration: duration,
      curve: Curves.easeOut,
    ),
    builder: (context) => UiSheet(accent: accent, child: builder(context)),
  );
}

/// `.permission-sheet`: round icon, h2 title, muted body, primary + "Not now".
/// Pops `true` for the primary action and `false` for the secondary one.
class UiPermissionSheetContent extends StatelessWidget {
  const UiPermissionSheetContent({
    required this.icon,
    required this.title,
    required this.primaryLabel,
    required this.secondaryLabel,
    this.body,
    this.primaryKey,
    this.secondaryKey,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String primaryLabel;
  final String secondaryLabel;
  final Key? primaryKey;
  final Key? secondaryKey;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: UiSize.permissionIcon,
            height: UiSize.permissionIcon,
            margin: const EdgeInsets.only(top: 4, bottom: 14),
            decoration: BoxDecoration(
              color: ui.permissionIconBg,
              shape: BoxShape.circle,
              border: ui.stickerBorder(),
            ),
            child: Icon(icon, size: 27, color: ui.ink),
          ),
        ),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: UiText.h2(color: ui.ink),
          ),
        ),
        if (body != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Text(
              body!,
              textAlign: TextAlign.center,
              style: UiText.muted(color: ui.inkMuted, size: 14),
            ),
          ),
        const SizedBox(height: 20),
        UiButton(
          key: primaryKey,
          label: primaryLabel,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: UiSpace.sm),
        UiButton.secondary(
          key: secondaryKey,
          label: secondaryLabel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

/// Shows a permission rationale sheet. Resolves to `true` when the person
/// takes the primary action, `false` for "Not now" or a dismissal.
Future<bool> showUiPermissionSheet({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String primaryLabel,
  required String secondaryLabel,
  String? body,
  Key? sheetKey,
  Key? primaryKey,
  Key? secondaryKey,
  Color? accent,
}) async {
  final result = await showUiSheet<bool>(
    context: context,
    accent: accent,
    builder: (context) => UiPermissionSheetContent(
      key: sheetKey,
      icon: icon,
      title: title,
      body: body,
      primaryLabel: primaryLabel,
      secondaryLabel: secondaryLabel,
      primaryKey: primaryKey,
      secondaryKey: secondaryKey,
    ),
  );
  return result ?? false;
}
