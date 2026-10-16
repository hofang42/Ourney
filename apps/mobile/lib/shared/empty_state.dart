import 'package:flutter/material.dart';

import '../app/theme/tokens.dart';
import 'chunky_button.dart';

/// Empty state: icon, title, optional message and one call to action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    this.message,
    this.icon = Icons.explore_outlined,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(OurneySpacing.screenMargin),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 44, color: c.primaryDeep),
                ),
              ),
              const SizedBox(height: OurneySpacing.xl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: text.displaySmall,
              ),
              if (message != null) ...[
                const SizedBox(height: OurneySpacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: c.inkMuted),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: OurneySpacing.xl),
                ChunkyButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  expand: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
