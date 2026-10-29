import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'buttons.dart';

/// `.bottom-sheet`: 28dp top radius, paper background, grabber, 280ms
/// slide-in (supplied by [showUiSheet]). Content scrolls when it is taller
/// than the available height, so large text never overflows.
class UiSheet extends StatelessWidget {
  const UiSheet({required this.child, this.showGrabber = true, super.key});

  final Widget child;
  final bool showGrabber;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: UiSpace.maxContent(width) + 40,
          maxHeight: mq.size.height * 0.92,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: ui.bg,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(UiRadius.sheet),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 40,
                offset: Offset(0, -12),
              ),
            ],
          ),
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
                      borderRadius: BorderRadius.circular(UiRadius.capsule),
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
    );
  }
}

/// Opens [builder] in a [UiSheet] over the `.modal-layer` scrim.
Future<T?> showUiSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool dismissible = true,
  bool useRootNavigator = true,
}) {
  final ui = context.ui;
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
      duration: UiMotion.sheet,
      reverseDuration: UiMotion.sheet,
      curve: Curves.easeOut,
    ),
    builder: (context) => UiSheet(child: builder(context)),
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
}) async {
  final result = await showUiSheet<bool>(
    context: context,
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
