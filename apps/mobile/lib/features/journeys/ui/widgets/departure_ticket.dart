import 'dart:math' as math;
import 'dart:ui' show ClipOp;

import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';

/// Which edge of a ticket piece is a perforation seam (torn edge).
enum _Seam { none, top, bottom, left, right }

/// V2 "vé khởi hành" (step 5 of journey creation): one ticket per skin.
///
/// quiet = private profile card with a lock, squad = mission card with a
/// trophy, memory = trip ticket (film-roll line shown once), couple = torn
/// double ticket with both names, flexer = race bib, minimal = index card.
///
/// Everything dynamic comes from the caller: [durationLabel] (for example
/// "21 ngày" or "không hẹn ngày về", never a hard-coded 30), [goalLine],
/// [datesLabel], [milestones] and the couple names [leftName]/[rightName].
/// The fixed copy ([privateLabel], [tagline], ...) defaults to the V2
/// Vietnamese strings and can be overridden with the caller's l10n.
///
/// Plays a `260ms` ([UiMotion.sheetEnter], [UiCurves.stampDecel]) stamp-in
/// settle on mount (`scale 0.95 -> 1.0` + [FadeTransition]). Under Reduce
/// Motion, renders immediately at resting scale and opacity with zero tickers.
class DepartureTicket extends StatefulWidget {
  const DepartureTicket({
    required this.skinId,
    required this.title,
    required this.goalLine,
    required this.durationLabel,
    this.datesLabel,
    this.milestones = const [],
    this.leftName,
    this.rightName,
    this.variant = 0,
    this.onChangeVariant,
    this.privateLabel = 'HỒ SƠ RIÊNG TƯ',
    this.memoryLabel = 'VÉ KÝ ỨC',
    this.tagline,
    this.changeVariantLabel = 'Đổi màu',
    super.key,
  });

  /// `quiet`, `squad`, `memory`, `couple`, `flexer` or `minimal`.
  final String skinId;
  final String title;

  /// Goal / trophy / film-roll line, depending on the skin.
  final String goalLine;

  /// Duration text computed by the caller.
  final String durationLabel;
  final String? datesLabel;
  final List<String> milestones;

  /// Couple skin only; the caller supplies the real names.
  final String? leftName;
  final String? rightName;
  final int variant;

  /// Shows a "change color" action under the ticket when set.
  final VoidCallback? onChangeVariant;
  final String privateLabel;
  final String memoryLabel;

  /// Closing line; defaults to the V2 line of the skin.
  final String? tagline;
  final String changeVariantLabel;

  static const double _angle = -0.8 * math.pi / 180;
  static const Duration stampSettleDuration = UiMotion.sheetEnter;

  static const _taglines = {
    'quiet': 'Chỉ mình mình thấy. Từng chút một.',
    'squad': 'Điểm danh mỗi ngày, cả hội cùng lên!',
    'memory': 'Mang về thật nhiều khung hình.',
    'couple': 'Mỗi ngày một nửa, ghép lại thành một.',
    'flexer': 'Ra khỏi giường. Tập tiếp.',
    'minimal': '',
  };

  /// `lock` / `trophy` / `heart` may not be drawn yet: fall back to an
  /// existing sticker so the ticket never shows an empty hole.
  static String _icon(String wanted, String fallback) =>
      ourneyIconPath(wanted) != null ? wanted : fallback;

  @override
  State<DepartureTicket> createState() => _DepartureTicketState();
}

class _DepartureTicketState extends State<DepartureTicket>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  CurvedAnimation? _curved;
  Animation<double>? _scale;
  bool _started = false;

  void _ensureAnimation() {
    if (_ctrl != null) return;
    final ctrl = AnimationController(
      vsync: this,
      duration: DepartureTicket.stampSettleDuration,
    );
    _ctrl = ctrl;
    final curved = CurvedAnimation(
      parent: ctrl,
      curve: UiCurves.stampDecel,
    );
    _curved = curved;
    _scale = Tween<double>(begin: UiMotion.popMinScale, end: 1.0).animate(
      curved,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = UiMotion.reduced(context);
    if (!_started) {
      _started = true;
      if (!reduced) {
        _ensureAnimation();
        _ctrl!.forward();
      }
    } else if (reduced && (_ctrl?.isAnimating ?? false)) {
      _ctrl?.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant DepartureTicket oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.skinId != oldWidget.skinId && !UiMotion.reduced(context)) {
      _ensureAnimation();
      _ctrl!.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _curved?.dispose();
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UiSkinScope(
      skinId: widget.skinId,
      variant: widget.variant,
      child: Builder(builder: _build),
    );
  }

  Widget _build(BuildContext context) {
    final scope = UiSkinScope.of(context);
    final ui = context.ui;
    final reduced = UiMotion.reduced(context);
    final s = _Style(
      ui: ui,
      accent: scope.variant.accent,
      font: scope.skin.headingFont,
      border: scope.skin.borderWidth,
      isDark: ui.isDark,
    );
    final line =
        widget.tagline ?? DepartureTicket._taglines[widget.skinId] ?? '';
    final Widget ticket = switch (widget.skinId) {
      'quiet' => _quiet(s, line),
      'squad' => _squad(s, line),
      'memory' => _memory(s, line),
      'couple' => _couple(s, line),
      'flexer' => _flexer(s, line),
      _ => _minimal(s),
    };
    Widget rotatedTicket = Padding(
      padding: const EdgeInsets.only(right: 5, bottom: 5),
      child: Transform.rotate(
        angle: DepartureTicket._angle,
        child: ticket,
      ),
    );
    if (!reduced && _curved != null && _scale != null) {
      rotatedTicket = FadeTransition(
        opacity: _curved!,
        child: ScaleTransition(
          scale: _scale!,
          child: rotatedTicket,
        ),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 342),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            rotatedTicket,
            if (widget.onChangeVariant != null)
              Align(
                child: UiTextAction(
                  label: widget.changeVariantLabel,
                  onPressed: widget.onChangeVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---- skins ----

  Widget _quiet(_Style s, String line) {
    final lock = Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: s.accent, width: 3),
      ),
      child: OurneyIcon(
        name: DepartureTicket._icon('lock', 'profile'),
        size: 28,
        flat: true,
        color: s.accent,
      ),
    );
    return _Tear(
      s: s,
      radius: 8,
      seam: _Seam.bottom,
      top: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 9, color: s.accent),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                lock,
                const SizedBox(height: 12),
                _eyebrow(s, widget.privateLabel),
                const SizedBox(height: 8),
                Text(
                  widget.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: s.h(25),
                ),
                const SizedBox(height: 4),
                Text(widget.durationLabel, style: s.body(14, w: FontWeight.w700)),
                if (widget.datesLabel != null)
                  Text(widget.datesLabel!, style: s.body(13)),
                const SizedBox(height: 8),
                Text(widget.goalLine, style: s.body(14)),
                if (widget.milestones.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        horizontal: BorderSide(color: s.ui.outline),
                      ),
                    ),
                    child: Text(
                      widget.milestones.join(' · '),
                      style: s.body(12, w: FontWeight.w800),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      stub: Text(line, style: s.body(13, h: 1.45)),
    );
  }

  Widget _squad(_Style s, String line) {
    return _Tear(
      s: s,
      radius: 14,
      seam: _Seam.none,
      borderWidth: 3,
      shadow: 5,
      top: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: s.accent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              widget.durationLabel.toUpperCase(),
              style: s.body(12, w: FontWeight.w900, c: s.onAccent, t: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: s.h(25),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (var i = 0; i < 4; i++)
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: s.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: s.ui.outline, width: 1.5),
                        ),
                      ),
                    OurneyIcon(
                      name: DepartureTicket._icon('trophy', 'squad'),
                      size: 26,
                      active: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(widget.goalLine, style: s.body(16, w: FontWeight.w800)),
                if (widget.datesLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(widget.datesLabel!, style: s.body(13)),
                ],
                if (widget.milestones.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(widget.milestones.join(' · '), style: s.body(12)),
                ],
                const SizedBox(height: 16),
                Text(line, style: s.body(13, h: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _memory(_Style s, String line) {
    final paper = s.isDark ? s.ui.surface : s.ui.bg;
    return _Tear(
      s: s,
      radius: 4,
      seam: _Seam.bottom,
      paper: paper,
      top: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _eyebrow(s, widget.memoryLabel, f: UiFonts.mono),
            const SizedBox(height: 10),
            Text(
              widget.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: s.h(24),
            ),
            const SizedBox(height: 8),
            if (widget.datesLabel != null)
              Text(widget.datesLabel!, style: s.body(14, f: UiFonts.mono)),
            Text(
              widget.durationLabel.toUpperCase(),
              style: s.body(12, w: FontWeight.w700, f: UiFonts.mono),
            ),
            if (widget.milestones.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(widget.milestones.join(' · '), style: s.body(12)),
            ],
          ],
        ),
      ),
      stub: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // The film-roll line is rendered exactly once (V2 showed it twice).
          Text(
            widget.goalLine,
            style: s.body(14, w: FontWeight.w800, f: UiFonts.mono),
          ),
          const SizedBox(height: 6),
          ExcludeSemantics(
            child: SizedBox(
              key: const ValueKey('ticket-film-roll'),
              height: 22,
              width: 120,
              child: CustomPaint(painter: _FilmRollPainter(s.ink)),
            ),
          ),
          if (line.isNotEmpty) Text(line, style: s.body(13, h: 1.45)),
        ],
      ),
    );
  }

  Widget _couple(_Style s, String line) {
    Widget half(String? name, {required bool left}) => Expanded(
      child: _Tear(
        s: s,
        radius: 24,
        seam: left ? _Seam.right : _Seam.left,
        top: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 238),
          child: Center(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                left ? 12 : 22,
                20,
                left ? 22 : 12,
                20,
              ),
              child: Text(
                name ?? '',
                textAlign: TextAlign.center,
                style: s.h(20, w: 800),
              ),
            ),
          ),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  half(widget.leftName, left: true),
                  const SizedBox(width: 8),
                  half(widget.rightName, left: false),
                ],
              ),
            ),
            OurneyIcon(
              name: DepartureTicket._icon('heart', 'react-heart'),
              size: 30,
              active: true,
              color: s.accent,
              inkColor: s.ink,
              // The ticket is paper, not the app surface: no dark die-cut ring.
              dieCut: const Color(0x00000000),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          widget.title,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: s.h(22),
        ),
        const SizedBox(height: 4),
        Text(
          widget.durationLabel,
          textAlign: TextAlign.center,
          style: s.body(14, w: FontWeight.w700),
        ),
        if (widget.datesLabel != null)
          Text(widget.datesLabel!, textAlign: TextAlign.center, style: s.body(13)),
        const SizedBox(height: 6),
        Text(widget.goalLine, textAlign: TextAlign.center, style: s.body(14)),
        if (line.isNotEmpty)
          Text(line, textAlign: TextAlign.center, style: s.body(13, h: 1.45)),
      ],
    );
  }

  Widget _flexer(_Style s, String line) {
    final digits =
        RegExp(r'^\d+').firstMatch(widget.durationLabel.trim())?.group(0);
    Widget pin(Alignment a) => Align(
      alignment: a,
      child: Container(
        width: 9,
        height: 9,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: s.ui.outline, width: 2),
        ),
      ),
    );
    return _Tear(
      s: s,
      radius: 0,
      seam: _Seam.none,
      borderColor: s.accent,
      shadowColor: s.accent,
      borderWidth: 3,
      shadow: 4,
      top: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: Stack(
                children: [
                  pin(Alignment.topLeft),
                  pin(Alignment.topRight),
                  pin(Alignment.bottomLeft),
                  pin(Alignment.bottomRight),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ExcludeSemantics(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: digits == null
                        ? SizedBox(
                            key: const ValueKey('ticket-infinity'),
                            width: 150,
                            height: 90,
                            child: CustomPaint(
                              painter: _InfinityPainter(s.ink),
                            ),
                          )
                        : Text(
                            digits,
                            style: UiText.heading(
                              font: s.font,
                              size: 112,
                              weight: 900,
                              height: 1.3,
                              color: s.ink,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.durationLabel,
                  textAlign: TextAlign.center,
                  style: s.body(14, w: FontWeight.w800, t: 0.06),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: s.h(24),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.goalLine,
                  textAlign: TextAlign.center,
                  style: s.body(14),
                ),
                if (widget.datesLabel != null)
                  Text(
                    widget.datesLabel!,
                    textAlign: TextAlign.center,
                    style: s.body(13),
                  ),
                if (line.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    line,
                    textAlign: TextAlign.center,
                    style: s.body(13, h: 1.45),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _minimal(_Style s) {
    return _Tear(
      s: s,
      radius: 0,
      seam: _Seam.none,
      grid: true,
      topBar: s.accent,
      top: Padding(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: s.h(25),
            ),
            const SizedBox(height: 10),
            Text(widget.goalLine, style: s.body(14, f: UiFonts.mono)),
            const SizedBox(height: 14),
            Text(
              widget.durationLabel.toUpperCase(),
              style: s.body(12, w: FontWeight.w900, t: 0.1, f: UiFonts.mono),
            ),
            if (widget.datesLabel != null)
              Text(widget.datesLabel!, style: s.body(12, f: UiFonts.mono)),
            if (widget.milestones.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(widget.milestones.join(' · '), style: s.body(12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _eyebrow(_Style s, String text, {String? f}) => Text(
    text,
    style: s.body(12, w: FontWeight.w900, t: 0.1, f: f),
  );
}

/// Resolved colors and text styles of one ticket.
class _Style {
  _Style({
    required this.ui,
    required this.accent,
    required this.font,
    required this.border,
    required this.isDark,
  });

  final OurneyUi ui;
  final Color accent;

  /// Skin `headingFont` name (StyleGuide spelling) for [UiText.heading].
  final String font;
  final double border;
  final bool isDark;

  Color get ink => ui.ink;
  Color get onAccent =>
      ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
      ? (isDark ? ui.ink : const Color(0xFFFFFFFF))
      : (isDark ? ui.bg : const Color(0xFF1C1C1E));

  TextStyle h(double size, {int w = 700}) => UiText.heading(
    font: font,
    size: size,
    weight: w,
    height: 1.3,
    color: ink,
  );

  TextStyle body(
    double size, {
    FontWeight w = FontWeight.w500,
    double h = 1.35,
    double t = 0,
    Color? c,
    String? f,
  }) {
    final base = UiText.body(
      size: size,
      weight: w,
      height: h,
      tracking: t,
      color: c ?? ink,
    );
    return f == null ? base : base.copyWith(fontFamily: f);
  }
}

/// A ticket made of a main piece and an optional stub (or, for couple halves,
/// one piece with a torn edge). The seam carries a dashed line and two notches.
class _Tear extends StatelessWidget {
  const _Tear({
    required this.s,
    required this.radius,
    required this.seam,
    required this.top,
    this.stub,
    this.paper,
    this.borderColor,
    this.shadowColor,
    this.borderWidth,
    this.shadow = 4,
    this.grid = false,
    this.topBar,
  });

  final _Style s;
  final double radius;
  final _Seam seam;
  final Widget top;
  final Widget? stub;
  final Color? paper;
  final Color? borderColor;
  final Color? shadowColor;
  final double? borderWidth;
  final double shadow;
  final bool grid;
  final Color? topBar;

  @override
  Widget build(BuildContext context) {
    final fill = paper ?? s.ui.surface;
    final bw = borderWidth ?? s.border;
    Widget piece(Widget child, _Seam edge, {required bool first}) {
      return CustomPaint(
        painter: _PiecePainter(
          fill: fill,
          border: borderColor ?? s.ui.outline,
          shadowColor: shadowColor ?? s.ui.hardShadowColor,
          borderWidth: bw,
          shadow: shadow,
          radius: radius,
          seam: edge,
          dash: s.ink.withValues(alpha: 0.6),
          grid: grid ? s.ink.withValues(alpha: 0.10) : null,
          topBar: first ? topBar : null,
        ),
        child: Padding(padding: EdgeInsets.all(bw), child: child),
      );
    }

    final main = piece(top, seam, first: true);
    if (stub == null) return main;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        main,
        piece(
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
            child: stub,
          ),
          _Seam.top,
          first: false,
        ),
      ],
    );
  }
}

class _PiecePainter extends CustomPainter {
  _PiecePainter({
    required this.fill,
    required this.border,
    required this.shadowColor,
    required this.borderWidth,
    required this.shadow,
    required this.radius,
    required this.seam,
    required this.dash,
    this.grid,
    this.topBar,
  });

  final Color fill;
  final Color border;
  final Color shadowColor;
  final double borderWidth;
  final double shadow;
  final double radius;
  final _Seam seam;
  final Color dash;
  final Color? grid;
  final Color? topBar;

  static const double _notch = 9;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final round = Radius.circular(radius);
    final rrect = RRect.fromRectAndCorners(
      Offset.zero & size,
      topLeft: seam == _Seam.top || seam == _Seam.left ? Radius.zero : round,
      topRight: seam == _Seam.top || seam == _Seam.right ? Radius.zero : round,
      bottomLeft: seam == _Seam.bottom || seam == _Seam.left
          ? Radius.zero
          : round,
      bottomRight: seam == _Seam.bottom || seam == _Seam.right
          ? Radius.zero
          : round,
    );
    // Notch centres sit at the two ends of the seam edge.
    final notches = switch (seam) {
      _Seam.none => const <Offset>[],
      _Seam.top => [Offset.zero, Offset(w, 0)],
      _Seam.bottom => [Offset(0, h), Offset(w, h)],
      _Seam.left => [Offset.zero, Offset(0, h)],
      _Seam.right => [Offset(w, 0), Offset(w, h)],
    };
    var shape = Path()..addRRect(rrect);
    for (final c in notches) {
      shape = Path.combine(
        PathOperation.difference,
        shape,
        Path()..addOval(Rect.fromCircle(center: c, radius: _notch)),
      );
    }
    canvas.drawPath(
      shape.shift(Offset(shadow, shadow)),
      Paint()..color = shadowColor,
    );
    canvas.drawPath(shape, Paint()..color = fill);

    canvas.save();
    canvas.clipPath(shape);
    if (grid != null) {
      final p = Paint()
        ..color = grid!
        ..strokeWidth = 1;
      for (var x = 20.0; x < w; x += 20) {
        canvas.drawLine(Offset(x, 0), Offset(x, h), p);
      }
      for (var y = 20.0; y < h; y += 20) {
        canvas.drawLine(Offset(0, y), Offset(w, y), p);
      }
    }
    if (topBar != null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, 6), Paint()..color = topBar!);
    }
    // Outline (inner half of a doubled stroke), minus the straight seam
    // segment between the notches.
    final bw = borderWidth;
    final gap = switch (seam) {
      _Seam.top => Rect.fromLTRB(_notch, -bw, w - _notch, bw),
      _Seam.bottom => Rect.fromLTRB(_notch, h - bw, w - _notch, h + bw),
      _Seam.left => Rect.fromLTRB(-bw, _notch, bw, h - _notch),
      _Seam.right => Rect.fromLTRB(w - bw, _notch, w + bw, h - _notch),
      _Seam.none => null,
    };
    if (gap != null) canvas.clipRect(gap, clipOp: ClipOp.difference);
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bw * 2
        ..color = border,
    );
    canvas.restore();

    // Dashed perforation along the seam.
    if (seam != _Seam.none) {
      final horizontal = seam == _Seam.top || seam == _Seam.bottom;
      final line = Paint()
        ..color = dash
        ..strokeWidth = 2;
      final len = horizontal ? w : h;
      final end = len - _notch - 6;
      for (var d = _notch + 6; d < end; d += 10) {
        final e = math.min(d + 5, end);
        final a = switch (seam) {
          _Seam.top => Offset(d, 1),
          _Seam.bottom => Offset(d, h - 1),
          _Seam.left => Offset(1, d),
          _ => Offset(w - 1, d),
        };
        canvas.drawLine(
          a,
          horizontal ? Offset(e, a.dy) : Offset(a.dx, e),
          line,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PiecePainter old) =>
      old.fill != fill ||
      old.border != border ||
      old.shadowColor != shadowColor ||
      old.borderWidth != borderWidth ||
      old.shadow != shadow ||
      old.radius != radius ||
      old.seam != seam ||
      old.dash != dash ||
      old.grid != grid ||
      old.topBar != topBar;
}

/// Open-ended bib mark: a drawn lemniscate (no Unicode glyph).
class _InfinityPainter extends CustomPainter {
  const _InfinityPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final a = w / 2 - 6;
    final path = Path();
    for (var i = 0; i <= 80; i++) {
      final t = i / 80 * 2 * math.pi;
      final d = 1 + math.sin(t) * math.sin(t);
      final x = cx + a * math.cos(t) / d;
      final y = cy + a * math.sin(t) * math.cos(t) / d * 1.5;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_InfinityPainter old) => old.color != color;
}

/// Film-roll strip: sprocket holes along a ruled band.
class _FilmRollPainter extends CustomPainter {
  const _FilmRollPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    const hole = 5.0;
    const gap = 4.0;
    var x = 0.0;
    while (x + hole <= size.width) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, hole, 5),
          const Radius.circular(1),
        ),
        p,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - 5, hole, 5),
          const Radius.circular(1),
        ),
        p,
      );
      x += hole + gap;
    }
    canvas.drawRect(Rect.fromLTWH(0, size.height / 2 - 1, size.width, 2), p);
  }

  @override
  bool shouldRepaint(_FilmRollPainter old) => old.color != color;
}
