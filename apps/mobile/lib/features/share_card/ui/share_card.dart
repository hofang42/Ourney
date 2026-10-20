import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/template_icons.dart';
import '../domain/share_card_content.dart';
import '../l10n/generated/share_card_localizations.dart';

/// Brand mark printed on every card (not translated).
const String shareCardLogo = 'Ourney';

/// Blur strength of a hidden photo, in logical points (x3 in the output).
const double shareCardBlurSigma = 18;

/// Line height for any Vietnamese text set at weight 800: stacked
/// diacritics (ệ, ữ, ấ) need room above the cap height or they get clipped.
const double shareCardDiacriticHeight = 1.32;

const _white = Color(0xFFFFFFFF);
const _ink = Color(0xFF1A1A22);
const _primaryDeep = Color(0xFFE11D48);

/// Keeps white text legible over bright photos (on top of the scrim).
const _textShadows = [
  Shadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 1)),
];

/// Big number caption and kicker for [content], localized.
({String? kicker, String caption}) shareCardCaption(
  ShareCardL10n l10n,
  ShareCardContent content,
) => switch (content.headline) {
  ShareCardHeadline.streak => (
    kicker: null,
    caption: l10n.share_card_captionStreak(content.number),
  ),
  ShareCardHeadline.checkedIn => (
    kicker: null,
    caption: l10n.share_card_captionCheckedIn(content.number),
  ),
  ShareCardHeadline.finished => (
    kicker: l10n.share_card_kickerFinished,
    caption: l10n.share_card_captionFinished(
      content.number,
      content.totalDays ?? content.number,
    ),
  ),
  ShareCardHeadline.day => (
    kicker: l10n.share_card_kickerDay,
    caption: content.totalDays == null
        ? ''
        : l10n.share_card_captionDayOf(content.totalDays!),
  ),
};

/// The share card (FR-E1): one theme (coral -> violet hero gradient), laid
/// out at [ShareCardFormat.logicalSize] and meant to be wrapped in a
/// [RepaintBoundary] and rendered at [ShareCardFormat.pixelRatio].
///
/// Text scaling is disabled inside the card: it is an image with a fixed
/// pixel size, not UI (the screen around it follows the user's text size).
class ShareCard extends StatelessWidget {
  const ShareCard({
    required this.content,
    required this.format,
    required this.blur,
    this.photo,
    super.key,
  });

  final ShareCardContent content;
  final ShareCardFormat format;

  /// Blur the photo (FR-B7).
  final bool blur;
  final ImageProvider? photo;

  @override
  Widget build(BuildContext context) {
    final l10n = ShareCardL10n.of(context);
    final size = format.logicalSize;
    final story = format == ShareCardFormat.story;
    final caption = shareCardCaption(l10n, content);
    final metric = _metricText(context);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: SizedBox.fromSize(
        key: ValueKey('share-card-${format.name}'),
        size: size,
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: OurneyColors.heroGradient),
          child: Padding(
            padding: format.contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(content: content, maxLines: story ? 2 : 1),
                const SizedBox(height: OurneySpacing.md),
                Expanded(
                  child: _PhotoPanel(
                    content: content,
                    photo: photo,
                    blur: blur,
                    kicker: caption.kicker,
                    caption: caption.caption,
                    numberSize: story ? 120 : 104,
                    milestone: _milestoneText(l10n),
                  ),
                ),
                const SizedBox(height: OurneySpacing.md),
                _Footer(metric: metric),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _milestoneText(ShareCardL10n l10n) => switch (content.milestone) {
    Milestone.sevenDays => l10n.share_card_milestone7,
    Milestone.thirtyDays => l10n.share_card_milestone30,
    Milestone.completed => l10n.share_card_milestoneCompleted,
    null => null,
  };

  String? _metricText(BuildContext context) {
    final value = content.metricValue;
    if (value == null) return null;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final number = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: value == value.roundToDouble() ? 0 : 1,
    ).format(value);
    final unit = content.metricUnit;
    return unit == null || unit.isEmpty ? number : '$number $unit';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.content, required this.maxLines});

  final ShareCardContent content;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          journeyIcon(content.emoji, content.templateId),
          size: 30,
          color: _white,
        ),
        const SizedBox(width: OurneySpacing.sm),
        Expanded(
          child: Text(
            content.title,
            key: const ValueKey('share-card-title'),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: displayStyle(
              size: 24,
              color: _white,
              height: shareCardDiacriticHeight,
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoPanel extends StatelessWidget {
  const _PhotoPanel({
    required this.content,
    required this.photo,
    required this.blur,
    required this.kicker,
    required this.caption,
    required this.numberSize,
    required this.milestone,
  });

  final ShareCardContent content;
  final ImageProvider? photo;
  final bool blur;
  final String? kicker;
  final String caption;
  final double numberSize;
  final String? milestone;

  @override
  Widget build(BuildContext context) {
    final fallback = _Illustration(
      icon: journeyIcon(content.emoji, content.templateId),
    );
    Widget image = photo == null
        ? fallback
        : Image(
            key: const ValueKey('share-card-photo'),
            image: photo!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stack) => fallback,
          );
    if (photo != null && blur) {
      image = ImageFiltered(
        key: const ValueKey('share-card-photo-blurred'),
        imageFilter: ImageFilter.blur(
          sigmaX: shareCardBlurSigma,
          sigmaY: shareCardBlurSigma,
          tileMode: TileMode.decal,
        ),
        child: image,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(OurneyRadii.card + 4),
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          // Scrim so white text stays readable over any photo (AA for the
          // bold >= 18pt text used here).
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.1, 0.55, 1],
                colors: [
                  Color(0x00000000),
                  Color(0x66000000),
                  Color(0xCC000000),
                ],
              ),
            ),
          ),
          if (milestone != null)
            Positioned(
              top: OurneySpacing.lg,
              left: OurneySpacing.lg,
              right: OurneySpacing.lg,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _Badge(text: milestone!),
              ),
            ),
          Positioned(
            left: OurneySpacing.lg,
            right: OurneySpacing.lg,
            bottom: OurneySpacing.lg,
            child: _Stats(
              kicker: kicker,
              number: content.number,
              caption: caption,
              numberSize: numberSize,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({
    required this.kicker,
    required this.number,
    required this.caption,
    required this.numberSize,
  });

  final String? kicker;
  final int number;
  final String caption;
  final double numberSize;

  @override
  Widget build(BuildContext context) {
    final label = displayStyle(
      size: 24,
      color: _white,
      height: shareCardDiacriticHeight,
    ).copyWith(shadows: _textShadows);
    Widget line(String text, Key key) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(text, key: key, maxLines: 1, style: label),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (kicker != null) line(kicker!, const ValueKey('share-card-kicker')),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '$number',
            key: const ValueKey('share-card-number'),
            maxLines: 1,
            // Digits only: no diacritics, so a tight line height is safe.
            style: displayStyle(
              size: numberSize,
              color: _white,
              height: 1.08,
            ).copyWith(shadows: _textShadows),
          ),
        ),
        if (caption.isNotEmpty)
          line(caption, const ValueKey('share-card-caption')),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(OurneyRadii.capsule),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OurneySpacing.md,
          vertical: OurneySpacing.xs,
        ),
        child: Text(
          text,
          key: const ValueKey('share-card-milestone'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          // primaryDeep on white: >= 4.5:1.
          style: displayStyle(
            size: 16,
            color: _primaryDeep,
            height: shareCardDiacriticHeight,
          ),
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('share-card-illustration'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0x40FFFFFF), Color(0x14FFFFFF)],
        ),
      ),
      child: Align(
        alignment: const Alignment(0, -0.35),
        child: Icon(icon, size: 96, color: _white),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.metric});

  final String? metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _white,
            shape: BoxShape.circle,
          ),
          child: Text(
            'O',
            style: displayStyle(size: 16, color: _ink, height: 1),
          ),
        ),
        const SizedBox(width: OurneySpacing.sm),
        Text(
          shareCardLogo,
          key: const ValueKey('share-card-logo'),
          style: displayStyle(size: 22, color: _white, height: 1.2),
        ),
        const Spacer(),
        if (metric != null)
          Flexible(
            child: Text(
              metric!,
              key: const ValueKey('share-card-metric'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFamily: kBodyFont,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _white,
                height: shareCardDiacriticHeight,
              ),
            ),
          ),
      ],
    );
  }
}
