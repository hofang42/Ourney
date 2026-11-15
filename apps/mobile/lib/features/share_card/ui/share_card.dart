import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../ui/ui.dart';
import '../domain/share_card_content.dart';
import '../l10n/generated/share_card_localizations.dart';

/// Brand mark printed on every card (not translated).
const String shareCardLogo = 'Ourney';

/// Blur strength of a hidden photo, in logical points of the 360pt card
/// (x3 in the output).
const double shareCardBlurSigma = 18;

/// Line height for any Vietnamese text set at weight 800: stacked
/// diacritics (ệ, ữ, ấ) need room above the cap height or they get clipped.
const double shareCardDiacriticHeight = 1.32;

/// Brand wordmark width on a card (`<Wordmark size={56}>`), in design px.
const double _wordmarkSize = 19;

/// V2 skin ids that have a share card (`quiet`, `squad`, `memory`,
/// `couple`, `flexer`, `minimal`).
const List<String> shareCardSkins = [
  'quiet',
  'squad',
  'memory',
  'couple',
  'flexer',
  'minimal',
];

/// Whether the brand wordmark is hidden by default (`QuietShare` starts with
/// `hideBrand = true`, every other skin with false).
bool shareCardHidesBrandByDefault(String skinId) => skinId == 'quiet';

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

/// Design-space width of the card of [skinId] (`.<skin>-share-card` widths in
/// `app.css`); the card is laid out at this width and scaled to the 360pt
/// export size.
double shareCardDesignWidth(String skinId, ShareCardFormat format) {
  final story = format == ShareCardFormat.story;
  return switch (skinId) {
    'quiet' || 'squad' => story ? 230 : 270,
    'memory' || 'couple' => story ? 235 : 275,
    _ => story ? 230 : 275,
  };
}

const _ink = Color(0xFF1A1A22);

/// The share card (FR-E1) of one V2 skin, laid out at
/// [ShareCardFormat.logicalSize] and meant to be wrapped in a
/// [RepaintBoundary] and rendered at [ShareCardFormat.pixelRatio].
///
/// The six layouts mirror the Figma `QuietShare` / `SquadShare` /
/// `MemoryShare` / `CoupleShare` / `FlexerShare` / `MinimalShare` cards. A
/// card is an exported image, so its colors are fixed (they do not follow
/// light / dark), and text scaling is disabled inside it.
class ShareCard extends StatelessWidget {
  const ShareCard({
    required this.content,
    required this.format,
    required this.blur,
    this.photo,
    this.gallery = const [],
    this.skinId = 'minimal',
    this.hideBrand = false,
    super.key,
  });

  final ShareCardContent content;
  final ShareCardFormat format;

  /// Blur the photo (FR-B7).
  final bool blur;
  final ImageProvider? photo;

  /// More photos (newest first) for the contact sheet / grids.
  final List<ImageProvider> gallery;
  final String skinId;

  /// Hide the brand wordmark (the "Ẩn chữ ourney" switch).
  final bool hideBrand;

  @override
  Widget build(BuildContext context) {
    final l10n = ShareCardL10n.of(context);
    final size = format.logicalSize;
    final width = shareCardDesignWidth(skinId, format);
    final height = format == ShareCardFormat.story
        ? width * 16 / 9
        : width * 1.25;
    final ctx = _Ctx(
      l10n: l10n,
      content: content,
      format: format,
      blur: blur,
      photo: photo,
      gallery: gallery,
      hideBrand: hideBrand,
      width: width,
      height: height,
      locale: Localizations.localeOf(context).toLanguageTag(),
    );
    final Widget card = switch (skinId) {
      'quiet' => _QuietCard(ctx),
      'squad' => _SquadCard(ctx),
      'memory' => _MemoryCard(ctx),
      'couple' => _CoupleCard(ctx),
      'flexer' => _FlexerCard(ctx),
      _ => _MinimalCard(ctx),
    };

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: SizedBox.fromSize(
        key: ValueKey('share-card-${format.name}'),
        size: size,
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            key: ValueKey('share-card-skin-$skinId'),
            width: width,
            height: height,
            child: card,
          ),
        ),
      ),
    );
  }
}

/// Everything a card needs, resolved once.
class _Ctx {
  const _Ctx({
    required this.l10n,
    required this.content,
    required this.format,
    required this.blur,
    required this.photo,
    required this.gallery,
    required this.hideBrand,
    required this.width,
    required this.height,
    required this.locale,
  });

  final ShareCardL10n l10n;
  final ShareCardContent content;
  final ShareCardFormat format;
  final bool blur;
  final ImageProvider? photo;
  final List<ImageProvider> gallery;
  final bool hideBrand;
  final double width;
  final double height;
  final String locale;

  bool get story => format == ShareCardFormat.story;

  /// Total days of the journey, or today's day for an open-ended one.
  int get total => content.totalDays ?? math.max(content.dayNumber, 1);

  String? get metric {
    final value = content.metricValue;
    if (value == null) return null;
    final number = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: value == value.roundToDouble() ? 0 : 1,
    ).format(value);
    final unit = content.metricUnit;
    return unit == null || unit.isEmpty ? number : '$number $unit';
  }

  /// The photo for slot [i]: the chosen photo first, then the gallery.
  ImageProvider? photoAt(int i) {
    if (i == 0 && photo != null) return photo;
    final list = [
      for (final g in gallery)
        if (g != photo) g,
    ];
    final j = photo == null ? i : i - 1;
    return j >= 0 && j < list.length ? list[j] : null;
  }

  Widget wordmark({Color color = _ink}) => Positioned(
    right: width * 0.05,
    bottom: height * 0.04,
    child: IgnorePointer(
      child: UiWordmark(
        key: const ValueKey('share-card-logo'),
        size: _wordmarkSize,
        color: color,
      ),
    ),
  );
}

/// Fits [child] (laid out at [width]) inside the available box, centered,
/// shrinking only when it would overflow.
Widget _centered(double width, Widget child) => SizedBox.expand(
  child: FittedBox(
    fit: BoxFit.scaleDown,
    child: SizedBox(width: width, child: child),
  ),
);

/// A card photo: the check-in image (blurred when [blur]), or a tinted
/// placeholder with the journey glyph.
class _CardPhoto extends StatelessWidget {
  const _CardPhoto({
    required this.ctx,
    required this.image,
    required this.radius,
    required this.gradient,
    this.primary = false,
    this.glyphColor = const Color(0xFFFFFFFF),
    this.glyphSize = 36,
  });

  final _Ctx ctx;
  final ImageProvider? image;
  final double radius;
  final List<Color> gradient;

  /// Only the primary photo carries the test / semantic keys.
  final bool primary;
  final Color glyphColor;
  final double glyphSize;

  @override
  Widget build(BuildContext context) {
    final blurred = ctx.blur;
    final fallback = DecoratedBox(
      key: primary ? const ValueKey('share-card-illustration') : null,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: gradient,
        ),
      ),
      child: Center(
        child: glyphSize == 0
            ? null
            : uiJourneyGlyph(
                ctx.content.emoji,
                ctx.content.templateId,
                size: glyphSize,
                color: glyphColor,
              ),
      ),
    );
    Widget child = image == null
        ? fallback
        : Image(
            key: primary ? const ValueKey('share-card-photo') : null,
            image: image!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stack) => fallback,
          );
    if (image != null && blurred) {
      final sigma = shareCardBlurSigma * ctx.width / 360;
      child = ImageFiltered(
        key: primary ? const ValueKey('share-card-photo-blurred') : null,
        imageFilter: ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: TileMode.decal,
        ),
        child: child,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox.expand(child: child),
    );
  }
}

TextStyle _heading(
  String font, {
  required double size,
  required int weight,
  required Color color,
  double height = shareCardDiacriticHeight,
  double tracking = 0,
}) => UiText.heading(
  font: font,
  size: size,
  weight: weight,
  height: height,
  tracking: tracking,
  color: color,
);

// ---------------------------------------------------------------- quiet ---

/// `.quiet-share-card`: white sheet, 1dp line, a blurred portrait with
/// "NGÀY N" and "N ngày đều đặn".
class _QuietCard extends StatelessWidget {
  const _QuietCard(this.ctx);

  final _Ctx ctx;

  @override
  Widget build(BuildContext context) {
    final c = ctx.content;
    const ink = Color(0xFF0F172A);
    final padBlock = ctx.width * (ctx.story ? 0.13 : 0.18);
    final label = UiText.body(
      size: 12,
      weight: FontWeight.w700,
      height: 1.4,
      color: ink,
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border.fromBorderSide(
          BorderSide(color: Color(0xFFCBD5D1), width: UiBorder.hairline),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: padBlock),
            child: _centered(
              ctx.width - 36 - 2,
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 2 / 3,
                              child: _CardPhoto(
                                ctx: ctx,
                                image: ctx.photoAt(0),
                                primary: true,
                                radius: 8,
                                gradient: const [
                                  Color(0xFFD5E7DF),
                                  Color(0xFFF4EEE5),
                                ],
                                glyphColor: const Color(0xFF53605B),
                                glyphSize: 40,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              ctx.l10n.share_card_dayLabel(c.dayNumber),
                              key: const ValueKey('share-card-day'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: label,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ctx.l10n.share_card_steadyDays(c.number),
                    key: const ValueKey('share-card-caption'),
                    style: label.copyWith(fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ),
          if (!ctx.hideBrand) ctx.wordmark(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- squad ---

/// `.squad-share-poster`: cream poster, 2dp outline, hard shadow, a tilted
/// four-photo wall and a gold trophy stamp.
class _SquadCard extends StatelessWidget {
  const _SquadCard(this.ctx);

  final _Ctx ctx;

  @override
  Widget build(BuildContext context) {
    final c = ctx.content;
    const ink = Color(0xFF1E1B18);
    final padBlock = ctx.story ? ctx.width * 0.13 : 17.0;
    final heading = _heading(
      'Space Grotesk',
      size: 13,
      weight: 700,
      height: 1.35,
      color: ink,
    );
    Widget tile(int i) => Transform.rotate(
      angle: (i.isEven ? -3 : 4) * math.pi / 180,
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ink, width: UiBorder.standard),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: _CardPhoto(
              ctx: ctx,
              image: ctx.photoAt(i),
              primary: i == 0,
              radius: 4,
              gradient: const [Color(0xFFFFD8A0), Color(0xFFF7C6A9)],
              glyphColor: ink,
              glyphSize: 28,
            ),
          ),
        ),
      ),
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F1E5),
        border: Border.fromBorderSide(
          BorderSide(color: ink, width: UiBorder.standard),
        ),
        boxShadow: [BoxShadow(color: ink, offset: Offset(0, UiShadow.small))],
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 17, vertical: padBlock),
            child: _centered(
              ctx.width - 34 - 4,
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ctx.l10n.share_card_attended(
                      c.completedDays,
                      ctx.total,
                      c.dayNumber,
                    ),
                    key: const ValueKey('share-card-title'),
                    textAlign: TextAlign.center,
                    style: heading,
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Expanded(child: tile(0)),
                      const SizedBox(width: 8),
                      Expanded(child: tile(1)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: tile(2)),
                      const SizedBox(width: 8),
                      Expanded(child: tile(3)),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Center(
                    child: Transform.rotate(
                      angle: -4 * math.pi / 180,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9B949),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ink,
                            width: UiBorder.standard,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const OurneyIcon(
                                name: 'trophy',
                                size: 26,
                                color: Color(0xFFFFFFFF),
                                inkColor: ink,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                ctx.l10n.share_card_cup(
                                  c.headline == ShareCardHeadline.day
                                      ? c.completedDays
                                      : c.number,
                                ),
                                key: const ValueKey('share-card-number'),
                                style: UiText.body(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  height: 1.4,
                                  color: ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!ctx.hideBrand) ctx.wordmark(),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- memory ---

/// `.memory-contact-poster`: film contact sheet with sprocket borders and
/// mono frame numbers.
class _MemoryCard extends StatelessWidget {
  const _MemoryCard(this.ctx);

  final _Ctx ctx;

  static const _ink = Color(0xFF231F1E);

  @override
  Widget build(BuildContext context) {
    final c = ctx.content;
    final total = math.min(ctx.story ? 24 : 20, math.max(ctx.total, 1));
    final shot = math.min(c.photoCount, total);
    final title = ctx.l10n.share_card_tripPosterTitle(
      ctx.total,
      c.title.toUpperCase(),
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFF4EFE6),
        border: Border.fromBorderSide(
          BorderSide(color: _ink, width: UiBorder.standard),
        ),
        boxShadow: [
          BoxShadow(
            color: _ink,
            offset: Offset(UiShadow.small, UiShadow.small),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: _centered(
              ctx.width - 28 - 4,
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    key: const ValueKey('share-card-title'),
                    textAlign: TextAlign.center,
                    style: _heading(
                      'Fraunces',
                      size: 17,
                      weight: 600,
                      height: 1.25,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CustomPaint(
                    painter: _SprocketPainter(),
                    child: Container(
                      color: const Color(0xFF111111),
                      padding: const EdgeInsets.fromLTRB(4, 11, 4, 11),
                      child: GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 3,
                        crossAxisSpacing: 3,
                        childAspectRatio: 3 / 2,
                        padding: EdgeInsets.zero,
                        children: [
                          for (var i = 0; i < total; i++)
                            _Frame(ctx: ctx, index: i, shot: i < shot),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!ctx.hideBrand) ctx.wordmark(),
        ],
      ),
    );
  }
}

/// The 7dp dotted top and bottom borders of the contact sheet (`#f4efe6`).
class _SprocketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF4EFE6);
    for (final y in [3.5, size.height - 3.5]) {
      for (var x = 3.5; x < size.width; x += 14) {
        canvas.drawCircle(Offset(x, y), 3.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SprocketPainter old) => false;
}

class _Frame extends StatelessWidget {
  const _Frame({required this.ctx, required this.index, required this.shot});

  final _Ctx ctx;
  final int index;
  final bool shot;

  @override
  Widget build(BuildContext context) {
    final tones = [
      const [Color(0xFF6B7F58), Color(0xFFC9A86A)],
      const [Color(0xFF4A6B7F), Color(0xFFD9C7A0)],
      const [Color(0xFF8A5A44), Color(0xFFE0B98A)],
      const [Color(0xFF55627A), Color(0xFFB9C4D6)],
    ][index % 4];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF080808),
        border: Border.all(color: const Color(0xFF6B6258)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (shot)
            _CardPhoto(
              ctx: ctx,
              image: ctx.photoAt(index),
              primary: index == 0,
              radius: 0,
              gradient: tones,
              glyphSize: 0,
            ),
          Positioned(
            right: 2,
            bottom: 1,
            child: Text(
              '${index + 1}'.padLeft(2, '0'),
              style: const TextStyle(
                fontFamily: UiFonts.mono,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- couple ---

/// `.couple-share-card`: white rounded card, Playfair heading, a grid of
/// small portraits (6 columns in story, 4 in feed).
class _CoupleCard extends StatelessWidget {
  const _CoupleCard(this.ctx);

  final _Ctx ctx;

  @override
  Widget build(BuildContext context) {
    final c = ctx.content;
    final count = ctx.story ? 36 : 16;
    final cols = ctx.story ? 6 : 4;
    const ink = Color(0xFF261F22);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A261F22),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(17),
            child: _centered(
              ctx.width - 34,
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ctx.l10n.share_card_coupleTitle(
                      math.max(c.dayNumber, 1),
                      c.photoCount,
                    ),
                    key: const ValueKey('share-card-title'),
                    textAlign: TextAlign.center,
                    style: _heading(
                      'Playfair Display',
                      size: 15,
                      weight: 600,
                      height: 1.3,
                      tracking: 0.07,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: cols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 3 / 4,
                    padding: EdgeInsets.zero,
                    children: [
                      for (var i = 0; i < count; i++)
                        _CardPhoto(
                          ctx: ctx,
                          image: ctx.photoAt(i),
                          primary: i == 0,
                          radius: 6,
                          glyphSize: 0,
                          gradient: i.isEven
                              ? const [Color(0xFFF2B8C2), Color(0xFFE15B72)]
                              : const [Color(0xFFF6D3C7), Color(0xFFF08A6B)],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (!ctx.hideBrand) ctx.wordmark(),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- flexer ---

/// `.flexer-share-card`: full-bleed photo, glass HUD, activity bars.
class _FlexerCard extends StatelessWidget {
  const _FlexerCard(this.ctx);

  final _Ctx ctx;

  static const _lime = Color(0xFF3DE88C);
  static const _coral = Color(0xFFFF7B54);

  @override
  Widget build(BuildContext context) {
    final c = ctx.content;
    final h = ctx.height;
    final activity = c.activity.isEmpty
        ? List<bool>.filled(math.min(math.max(c.dayNumber, 1), 21), true)
        : c.activity;
    final metric = ctx.metric?.toUpperCase();
    return ClipRect(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF11131A)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _CardPhoto(
              ctx: ctx,
              image: ctx.photoAt(0),
              primary: true,
              radius: 0,
              glyphSize: 64,
              gradient: const [Color(0xFF252936), Color(0xFF11131A)],
            ),
            Positioned(
              top: h * 0.16,
              left: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0x9E000000),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x40FFFFFF)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metric ?? '${c.number}',
                        key: const ValueKey('share-card-number'),
                        maxLines: 1,
                        style: _heading(
                          'Barlow Condensed',
                          size: 27,
                          weight: 700,
                          height: 1.1,
                          color: const Color(0xFFFFFFFF),
                        ),
                      ),
                      Text(
                        ctx.l10n.share_card_dayLabel(c.dayNumber),
                        key: const ValueKey('share-card-day'),
                        style: UiText.body(
                          size: 12,
                          height: 1.4,
                          color: const Color(0xFFFFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: h * 0.19,
              height: 55,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < activity.length; i++) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      child: FractionallySizedBox(
                        heightFactor: !activity[i]
                            ? 0.35
                            : (i % 3 == 2 ? 0.67 : 0.9),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: activity[i] ? _lime : _coral,
                            borderRadius: BorderRadius.circular(
                              UiRadius.capsule,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: h * 0.12,
              child: Text(
                ctx.l10n.share_card_activeDays(c.completedDays),
                key: const ValueKey('share-card-caption'),
                textAlign: TextAlign.center,
                style: _heading(
                  'Barlow Condensed',
                  size: 15,
                  weight: 700,
                  height: 1.3,
                  color: const Color(0xFFFFFFFF),
                ),
              ),
            ),
            if (!ctx.hideBrand) ctx.wordmark(color: const Color(0xFFFFFFFF)),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- minimal ---

/// `.minimal-share-card`: white, light Space Grotesk statement and one small
/// portrait.
class _MinimalCard extends StatelessWidget {
  const _MinimalCard(this.ctx);

  final _Ctx ctx;

  @override
  Widget build(BuildContext context) {
    final c = ctx.content;
    const ink = Color(0xFF1C1C1E);
    final padBottom = ctx.story ? ctx.width * 0.18 : 24.0;
    final padTop = ctx.story ? ctx.width * 0.13 : 24.0;
    final line1 = c.totalDays == null
        ? ctx.l10n.share_card_minimalDaysOpen(c.completedDays)
        : ctx.l10n.share_card_minimalDays(c.completedDays, c.totalDays!);
    final pct = ctx.total == 0
        ? 0
        : (c.completedDays * 100 / (c.totalDays ?? math.max(c.dayNumber, 1)))
              .round()
              .clamp(0, 100);
    return ColoredBox(
      color: const Color(0xFFFFFFFF),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, padTop, 24, padBottom),
            child: _centered(
              ctx.width - 48,
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$line1\n${ctx.l10n.share_card_minimalRate(pct)}',
                    key: const ValueKey('share-card-title'),
                    textAlign: TextAlign.center,
                    style: _heading(
                      'Space Grotesk',
                      size: 26,
                      weight: 300,
                      height: 1.3,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 35),
                  SizedBox(
                    width: 118,
                    height: 118 * 4 / 3,
                    child: _CardPhoto(
                      ctx: ctx,
                      image: ctx.photoAt(0),
                      primary: true,
                      radius: 8,
                      glyphColor: const Color(0xFF626166),
                      glyphSize: 40,
                      gradient: const [Color(0xFFD7D5CF), Color(0xFFEFEDE7)],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!ctx.hideBrand) ctx.wordmark(),
        ],
      ),
    );
  }
}
