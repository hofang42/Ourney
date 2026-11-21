import 'dart:ui' as ui_;

import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../../ui/ui.dart';
import '../../domain/wrapped_story.dart';
import '../journey_photo.dart';

/// `WrappedVisual`: the drawing above a story headline, per skin. Built from
/// the journey's own photos where the Figma shows photos, and from drawn
/// shapes (curve, trophy path, bars, chain) elsewhere.
class WrappedVisual extends StatelessWidget {
  const WrappedVisual({
    required this.skin,
    required this.stats,
    required this.page,
    this.blurPhotos = false,
    super.key,
  });

  final PersonaSkinId skin;
  final WrappedStats stats;
  final int page;
  final bool blurPhotos;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return switch (skin) {
      PersonaSkinId.quietTransformer =>
        page == 2
            ? _Curve(
                key: const ValueKey('wrapped-quiet-curve'),
                color: ui.accent,
                points: const [
                  Offset(0, .82),
                  Offset(.28, .63),
                  Offset(.43, .77),
                  Offset(.6, .37),
                  Offset(.84, .23),
                  Offset(1, .1),
                ],
                smooth: true,
              )
            : _Photos(
                key: const ValueKey('wrapped-quiet-photos'),
                photos: _firstLast(stats.photos),
                blur: blurPhotos,
              ),
      PersonaSkinId.accountabilitySquad =>
        page == 2
            ? OurneyIcon(
                key: const ValueKey('wrapped-trophy'),
                name: 'trophy',
                size: 94,
                active: true,
                semanticLabel: null,
              )
            : Row(
                key: const ValueKey('wrapped-squad-path'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 4; i++)
                    Container(
                      width: 17,
                      height: 17,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: ui.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: ui.outline, width: 2),
                      ),
                    ),
                  const OurneyIcon(name: 'trophy', size: 28, active: true),
                ],
              ),
      PersonaSkinId.memoryCollectors => _Film(
        key: const ValueKey('wrapped-memory-film'),
        photos: stats.photos.reversed.take(4).toList(),
      ),
      PersonaSkinId.coupleRituals => Row(
        key: const ValueKey('wrapped-couple-frame'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Frame(
            checkIn: stats.photos.isEmpty ? null : stats.photos.first,
            partner: false,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: OurneyIcon(name: 'heart', size: 34, active: true),
          ),
          _Frame(
            checkIn: stats.photos.isEmpty ? null : stats.photos.last,
            partner: true,
          ),
        ],
      ),
      PersonaSkinId.aestheticFlexer =>
        page == 2
            ? _Curve(
                key: const ValueKey('wrapped-flexer-chart'),
                color: ui.accent,
                points: const [
                  Offset(0, .82),
                  Offset(.14, .68),
                  Offset(.28, .73),
                  Offset(.4, .39),
                  Offset(.54, .54),
                  Offset(.68, .24),
                  Offset(.82, .36),
                  Offset(1, .08),
                ],
              )
            : _Bars(
                key: const ValueKey('wrapped-flexer-bars'),
                done: stats.days,
                total: stats.total,
                color: ui.accent,
              ),
      PersonaSkinId.minimalistHabit => _Chain(
        key: const ValueKey('wrapped-minimal-chain'),
        done: stats.days,
        total: stats.total,
        color: ui.accent,
      ),
    };
  }

  static List<CheckIn> _firstLast(List<CheckIn> all) => all.isEmpty
      ? const []
      : all.length == 1
      ? [all.first]
      : [all.first, all.last];
}

class _Frame extends StatelessWidget {
  const _Frame({required this.checkIn, required this.partner});

  final CheckIn? checkIn;
  final bool partner;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final c = checkIn;
    return Flexible(
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 120),
          decoration: BoxDecoration(
            color: ui.fill,
            borderRadius: BorderRadius.circular(UiRadius.input),
            border: Border.all(color: ui.outline, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: c == null
              ? null
              : JourneyPhoto(
                  checkIn: c,
                  partner: partner && c.partnerPhotoPath != null,
                  fallback: const SizedBox.shrink(),
                ),
        ),
      ),
    );
  }
}

class _Photos extends StatelessWidget {
  const _Photos({required this.photos, required this.blur, super.key});

  final List<CheckIn> photos;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final items = photos.isEmpty ? <CheckIn?>[null, null] : photos;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final c in items)
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 130),
                  decoration: BoxDecoration(
                    color: ui.fill,
                    borderRadius: BorderRadius.circular(UiRadius.input),
                    border: Border.all(color: ui.outline, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: c == null
                      ? null
                      : ImageFiltered(
                          enabled: blur,
                          imageFilter: ui_.ImageFilter.blur(
                            sigmaX: 14,
                            sigmaY: 14,
                          ),
                          child: JourneyPhoto(
                            checkIn: c,
                            fallback: const SizedBox.shrink(),
                          ),
                        ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Film extends StatelessWidget {
  const _Film({required this.photos, super.key});

  final List<CheckIn> photos;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final items = photos.isEmpty
        ? List<CheckIn?>.filled(4, null)
        : <CheckIn?>[...photos];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in items)
          SizedBox(
            width: 68,
            height: 88,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ui.fill,
                border: Border.all(color: ui.outline, width: 2),
              ),
              child: c == null
                  ? null
                  : JourneyPhoto(checkIn: c, fallback: const SizedBox.shrink()),
            ),
          ),
      ],
    );
  }
}

class _Curve extends StatelessWidget {
  const _Curve({
    required this.color,
    required this.points,
    this.smooth = false,
    super.key,
  });

  final Color color;
  final List<Offset> points;
  final bool smooth;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 110,
      width: double.infinity,
      child: CustomPaint(painter: _CurvePainter(color, points, smooth)),
    ),
  );
}

class _CurvePainter extends CustomPainter {
  _CurvePainter(this.color, this.points, this.smooth);

  final Color color;
  final List<Offset> points;
  final bool smooth;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = [
      for (final p in points)
        Offset(6 + p.dx * (size.width - 12), 6 + p.dy * (size.height - 12)),
    ];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      if (smooth) {
        final mid = (pts[i - 1].dx + pts[i].dx) / 2;
        path.cubicTo(mid, pts[i - 1].dy, mid, pts[i].dy, pts[i].dx, pts[i].dy);
      } else {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(pts.last, 7, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.color != color || old.points != points || old.smooth != smooth;
}

class _Bars extends StatelessWidget {
  const _Bars({
    required this.done,
    required this.total,
    required this.color,
    super.key,
  });

  final int done;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final n = total.clamp(1, 30);
    return ExcludeSemantics(
      child: SizedBox(
        height: 96,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < n; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    height: 24 + ((i * 37) % 60).toDouble(),
                    decoration: BoxDecoration(
                      color: i < done ? color : ui.fill,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Chain extends StatelessWidget {
  const _Chain({
    required this.done,
    required this.total,
    required this.color,
    super.key,
  });

  final int done;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final n = total.clamp(1, 60);
    return ExcludeSemantics(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var i = 0; i < n; i++)
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: i < done ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: i < done ? color : ui.border,
                  width: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
