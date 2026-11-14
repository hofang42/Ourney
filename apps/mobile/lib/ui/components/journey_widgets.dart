import 'package:flutter/material.dart';

import '../skins.dart';
import '../tokens.dart';
import '../typography.dart';
import 'avatar.dart';
import 'buttons.dart';
import 'feedback.dart';
import 'ourney_icons.dart';
import 'pressable.dart';
import 'surfaces.dart';

/// Text color on a pastel sticker fill. Pastels are identical in light and
/// dark (V2 `typePastel`), so the label stays a fixed near-black.
const Color _onPastel = Color(0xFF1A1A1A);

class _TypeSpec {
  const _TypeSpec(this.icon, this.pastel);
  final String icon;
  final Color pastel;
}

const Map<String, _TypeSpec> _types = {
  'weight': _TypeSpec('type-weight', UiTypePastel.weightLoss),
  'study': _TypeSpec('type-study', UiTypePastel.english),
  'trip': _TypeSpec('type-trip', UiTypePastel.trip),
  'couple': _TypeSpec('type-couple', UiTypePastel.couple),
  'workout': _TypeSpec('type-workout', UiTypePastel.workout),
  'custom': _TypeSpec('type-custom', UiTypePastel.custom),
};

/// Rounded sticker with the journey type icon on its pastel (`TypeBadge`).
///
/// [type] is one of `weight`, `study`, `trip`, `couple`, `workout`, `custom`
/// (unknown ids fall back to `custom`); use [idFor] to map a V2 label.
/// Decorative: the owning row carries the semantics.
class UiTypeBadge extends StatelessWidget {
  const UiTypeBadge({required this.type, this.size = 40, super.key});

  final String type;
  final double size;

  /// The six type ids.
  static const List<String> ids = [
    'weight',
    'study',
    'trip',
    'couple',
    'workout',
    'custom',
  ];

  /// Maps a V2 journey type label (Giảm cân, Tiếng Anh, Chuyến đi, Cặp đôi,
  /// Tập luyện, Tự đặt) to its id; anything else maps to `custom`.
  static String idFor(String label) => switch (label.trim()) {
    'Giảm cân' => 'weight',
    'Tiếng Anh' => 'study',
    'Chuyến đi' => 'trip',
    'Cặp đôi' => 'couple',
    'Tập luyện' => 'workout',
    _ => 'custom',
  };

  /// Pastel fill of type [id].
  static Color pastelFor(String id) => (_types[id] ?? _types['custom']!).pastel;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final spec = _types[type] ?? _types['custom']!;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: spec.pastel,
          borderRadius: BorderRadius.circular(size * 0.3),
          border: ui.stickerBorder(),
        ),
        child: OurneyIcon(
          name: spec.icon,
          size: (size * 0.6).roundToDouble(),
          active: true,
        ),
      ),
    );
  }
}

/// State of a [UiStreakHero] (V2 `hero-default|done|milestone|group`).
enum UiStreakHeroState { normal, done, milestone, group }

/// V2 Hub hero: big streak number with the flame (trophy at a milestone) on a
/// pastel sticker card with a hard shadow. Tappable when [onTap] is set.
class UiStreakHero extends StatelessWidget {
  const UiStreakHero({
    required this.streak,
    required this.title,
    this.subtitle,
    this.onTap,
    this.state = UiStreakHeroState.normal,
    super.key,
  });

  final int streak;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final UiStreakHeroState state;

  Color get _fill => switch (state) {
    UiStreakHeroState.normal => UiTypePastel.english,
    UiStreakHeroState.done => UiTypePastel.workout,
    UiStreakHeroState.milestone => UiTypePastel.trip,
    UiStreakHeroState.group => UiTypePastel.weightLoss,
  };

  @override
  Widget build(BuildContext context) {
    final label = 'Chuỗi $streak ngày. $title';
    final content = ExcludeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.heading(
                    font: 'Space Grotesk',
                    size: 20,
                    weight: 700,
                    height: 1.3,
                    color: _onPastel,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.body(
                      size: 14,
                      weight: FontWeight.w600,
                      height: 1.4,
                      color: _onPastel,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: UiSpace.md),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    OurneyIcon(
                      name: state == UiStreakHeroState.milestone
                          ? 'trophy'
                          : 'flame',
                      size: 44,
                      active: true,
                      inkColor: _onPastel,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$streak',
                      maxLines: 1,
                      style: UiText.heading(
                        font: 'Space Grotesk',
                        size: 80,
                        weight: 700,
                        height: 1.1,
                        tracking: -0.04,
                        color: _onPastel,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    final card = UiCard(
      color: _fill,
      padding: const EdgeInsets.all(UiSpace.xl),
      onPressed: onTap,
      semanticLabel: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 96),
        child: content,
      ),
    );
    if (onTap != null) return card;
    return Semantics(container: true, label: label, child: card);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.icon});

  final String label;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ui.fill,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: ui.outline, width: UiBorder.thin),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            OurneyIcon(name: icon!, size: 16),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.body(
                size: 12,
                weight: FontWeight.w700,
                height: 1.35,
                color: ui.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.members});

  final List<String> members;

  static const double _size = 28;
  static const double _step = 20;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final shown = members.take(3).toList();
    final extra = members.length - shown.length;
    final count = shown.length + (extra > 0 ? 1 : 0);
    if (count == 0) return const SizedBox.shrink();
    return SizedBox(
      width: _size + (count - 1) * _step,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * _step,
              child: UiAvatar(
                name: shown[i],
                colorIndex: UiAvatar.indexFor(shown[i]),
                size: _size,
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * _step,
              child: Container(
                width: _size,
                height: _size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ui.fill,
                  shape: BoxShape.circle,
                  border: Border.all(color: ui.surface, width: 2),
                ),
                child: Text(
                  '+$extra',
                  maxLines: 1,
                  style: UiText.body(
                    size: 11,
                    weight: FontWeight.w700,
                    height: 1.2,
                    color: ui.ink,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// V2 journey card: type badge, title, `Ngày N/M` and streak chips, progress
/// bar, member avatars and a 48dp snap button until today is done.
///
/// The card is a sticker (2dp outline, 4dp hard shadow, sticker press); the
/// snap button is a sibling control so it keeps its own semantics.
class UiJourneyCard extends StatelessWidget {
  const UiJourneyCard({
    required this.title,
    required this.type,
    required this.day,
    required this.totalDays,
    required this.streak,
    this.todayDone = false,
    this.subtitle,
    this.members = const [],
    this.onTap,
    this.onSnap,
    this.snapLabel = 'Chụp ảnh hôm nay',
    super.key,
  });

  final String title;

  /// A type id (`weight`...`custom`), see [UiTypeBadge].
  final String type;
  final int day;
  final int totalDays;
  final int streak;
  final bool todayDone;
  final String? subtitle;

  /// Member display names. Three avatars show, then `+N`.
  final List<String> members;
  final VoidCallback? onTap;
  final VoidCallback? onSnap;

  /// Semantics label of the snap button.
  final String snapLabel;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final dayText = 'Ngày $day/$totalDays';
    final progress = totalDays <= 0 ? 0.0 : (day / totalDays).clamp(0.0, 1.0);
    final label =
        '$title, $dayText, Chuỗi $streak ngày'
        '${subtitle == null ? '' : ', $subtitle'}';
    final showSnap = !todayDone;
    final body = ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UiTypeBadge(type: type, size: 44),
              const SizedBox(width: UiSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.body(
                        size: 16,
                        weight: FontWeight.w700,
                        height: 1.35,
                        color: ui.ink,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.body(
                          size: 13,
                          height: 1.4,
                          color: ui.inkMuted,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Chip(label: dayText),
                        _Chip(label: '$streak', icon: 'flame'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: UiSpace.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: UiProgressBar(
              value: progress,
              color: UiTypeBadge.pastelFor(type),
            ),
          ),
          if (members.isNotEmpty || showSnap || todayDone) ...[
            const SizedBox(height: UiSpace.md),
            Padding(
              padding: EdgeInsets.only(right: showSnap ? 56 : 0),
              child: SizedBox(
                height: 28,
                child: Row(
                  children: [
                    _AvatarStack(members: members),
                    const Spacer(),
                    if (todayDone)
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ui.successSoft,
                          shape: BoxShape.circle,
                          border: ui.stickerBorder(UiBorder.thin),
                        ),
                        child: const OurneyIcon(name: 'check', size: 16),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
    final card = UiCard(
      padding: const EdgeInsets.all(14),
      onPressed: onTap,
      semanticLabel: label,
      child: body,
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        onTap != null
            ? card
            : Semantics(container: true, label: label, child: card),
        if (showSnap)
          Positioned(
            right: 8,
            bottom: 8,
            child: UiPressable(
              onPressed: onSnap,
              semanticLabel: snapLabel,
              excludeChildSemantics: true,
              centerChild: true,
              shadowOffset: UiShadow.tiny,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ui.brand,
                  shape: BoxShape.circle,
                  border: ui.stickerBorder(),
                ),
                child: OurneyIcon(
                  name: 'camera',
                  size: 24,
                  color: ui.onBrand,
                  inkColor: ui.onBrand,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Kind of a [UiStateCard].
enum UiStateCardKind { empty, offline, error, loading }

/// V2 Hub state card (`HubStateCard` / `HubSkeleton`): sticker icon, title,
/// optional body and action. [UiStateCardKind.loading] shows skeleton blocks
/// and uses [title] only as its semantics label.
class UiStateCard extends StatelessWidget {
  const UiStateCard({
    required this.kind,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final UiStateCardKind kind;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  String get _icon => switch (kind) {
    UiStateCardKind.empty => 'plus',
    UiStateCardKind.offline => 'cloud-off',
    UiStateCardKind.error => 'warning',
    UiStateCardKind.loading => 'clock',
  };

  Color get _pastel => switch (kind) {
    UiStateCardKind.empty => UiTypePastel.weightLoss,
    UiStateCardKind.offline => UiTypePastel.custom,
    UiStateCardKind.error => UiTypePastel.trip,
    UiStateCardKind.loading => UiTypePastel.english,
  };

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    if (kind == UiStateCardKind.loading) {
      return Semantics(
        container: true,
        label: title,
        child: const ExcludeSemantics(
          child: UiCard(
            padding: EdgeInsets.all(UiSpace.lg),
            child: Row(
              children: [
                UiSkeleton(width: 56, height: 56, radius: 16),
                SizedBox(width: UiSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UiSkeleton(height: 16),
                      SizedBox(height: 8),
                      UiSkeleton(width: 120, height: 12),
                      SizedBox(height: 8),
                      UiSkeleton(width: 80, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return UiCard(
      padding: const EdgeInsets.all(UiSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _pastel,
              borderRadius: BorderRadius.circular(UiRadius.menu),
              border: ui.stickerBorder(),
            ),
            child: OurneyIcon(name: _icon, size: 40, active: true),
          ),
          const SizedBox(height: UiSpace.lg),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: UiText.h2(size: 20, color: ui.ink),
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(
              body!,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: UiText.muted(size: 14, color: ui.inkMuted),
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: UiSpace.lg),
            UiButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
