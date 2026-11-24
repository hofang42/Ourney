import SwiftUI

/// Pure SwiftUI port of `OurneyIconPainter` and `parseSvgPath` from
/// `apps/mobile/lib/ui/components/ourney_icons.dart` (§5.3.2).
/// Zero SF Symbols, zero emojis, zero Unicode symbol glyphs.
public struct OurneyIconView: View {
  public let name: String
  public let size: CGFloat
  public let ink: Color
  public let flat: Bool
  public let overrideColor: Color?

  public init(
    name: String,
    size: CGFloat = 20,
    ink: Color = Color(.sRGB, red: 0.102, green: 0.102, blue: 0.102, opacity: 1.0),
    flat: Bool = false,
    overrideColor: Color? = nil
  ) {
    self.name = name
    self.size = size
    self.ink = ink
    self.flat = flat
    self.overrideColor = overrideColor
  }

  public var body: some View {
    OurneyRenderingModeReader { isFullColor in
      let useFlat = flat || !isFullColor
      let spec = OurneyIconRegistry.spec(for: name)
      let fillColor = overrideColor ?? (useFlat ? ink : spec.stickerColor)

      Canvas { context, canvasSize in
        let scale = min(canvasSize.width, canvasSize.height) / 24.0
        guard scale > 0 else { return }

        var strokePath = Path()
        var fillPath = Path()
        for prim in spec.primitives {
          let p = prim.buildPath(scale: scale)
          strokePath.addPath(p)
          if prim.fill {
            fillPath.addPath(p)
          }
        }

        let tiny = min(canvasSize.width, canvasSize.height) < 16.0
        let strokeStyle = StrokeStyle(
          lineWidth: tiny ? 1.6 : 2.0,
          lineCap: .round,
          lineJoin: .round
        )

        if useFlat {
          context.stroke(strokePath, with: .color(fillColor), style: strokeStyle)
          return
        }

        // 1. Outer ink sticker halo
        let haloWidth: CGFloat = tiny
          ? min(max(canvasSize.width * 0.28, 2.8), 3.8)
          : min(max(canvasSize.width * 0.22, 3.8), 5.6)
        let haloStyle = StrokeStyle(
          lineWidth: haloWidth,
          lineCap: .round,
          lineJoin: .round
        )
        if !spec.isOpenStroke && !fillPath.isEmpty {
          context.fill(fillPath, with: .color(ink))
        }
        context.stroke(strokePath, with: .color(ink), style: haloStyle)

        // 2. Colored sticker body
        let bodyStrokeStyle = StrokeStyle(
          lineWidth: tiny ? 1.4 : 2.0,
          lineCap: .round,
          lineJoin: .round
        )
        if !spec.isOpenStroke && !fillPath.isEmpty {
          context.fill(fillPath, with: .color(fillColor))
        }
        context.stroke(strokePath, with: .color(fillColor), style: bodyStrokeStyle)

        // 3. Inner flame core (#FF9F1C) when drawing the two-tone flame sticker
        if let coreD = spec.corePathD, let coreColor = spec.coreColor, overrideColor == nil {
          let corePath = OurneySvgPathParser.parse(coreD, scale: scale)
          context.fill(corePath, with: .color(coreColor))
        }

        // 4. Interior ink detail stroke (book spine, lock keyhole, camera lens, clock hands, suitcase strap)
        if let detailPrim = spec.interiorInkDetail {
          let detailPath = detailPrim.buildPath(scale: scale)
          let detailStyle = StrokeStyle(
            lineWidth: tiny ? 1.35 : 1.75,
            lineCap: .round,
            lineJoin: .round
          )
          context.stroke(detailPath, with: .color(ink), style: detailStyle)
        }
      }
      .frame(width: size, height: size)
      .accessibilityHidden(true)
    }
  }
}

// MARK: - Primitive & Registry Definitions

enum OurneyIconPrimitive {
  case path(String, fill: Bool)
  case circle(cx: CGFloat, cy: CGFloat, r: CGFloat, fill: Bool)

  var fill: Bool {
    switch self {
    case .path(_, let f): return f
    case .circle(_, _, _, let f): return f
    }
  }

  func buildPath(scale: CGFloat) -> Path {
    switch self {
    case .path(let d, _):
      return OurneySvgPathParser.parse(d, scale: scale)
    case .circle(let cx, let cy, let r, _):
      let rect = CGRect(
        x: (cx - r) * scale,
        y: (cy - r) * scale,
        width: r * 2 * scale,
        height: r * 2 * scale
      )
      var p = Path()
      p.addEllipse(in: rect)
      return p
    }
  }
}

struct OurneyIconSpec {
  let primitives: [OurneyIconPrimitive]
  let stickerColor: Color
  let isOpenStroke: Bool
  let corePathD: String?
  let coreColor: Color?
  let interiorInkDetail: OurneyIconPrimitive?

  init(
    primitives: [OurneyIconPrimitive],
    stickerHex: UInt32,
    isOpenStroke: Bool = false,
    corePathD: String? = nil,
    coreHex: UInt32? = nil,
    interiorInkDetail: OurneyIconPrimitive? = nil
  ) {
    self.primitives = primitives
    self.stickerColor = OurneyRGB(hex: stickerHex).color
    self.isOpenStroke = isOpenStroke
    self.corePathD = corePathD
    self.coreColor = coreHex.map { OurneyRGB(hex: $0).color }
    self.interiorInkDetail = interiorInkDetail
  }
}

enum OurneyIconRegistry {
  static func spec(for rawName: String) -> OurneyIconSpec {
    if let direct = icons[rawName] {
      return direct
    }
    switch rawName {
    case "scales", "weight":
      return icons["type-weight"]!
    case "book", "study":
      return icons["type-study"]!
    case "trip":
      return icons["type-trip"]!
    case "couple", "heart", "react-heart":
      return icons["type-couple"]!
    case "fitness", "workout":
      return icons["type-workout"]!
    case "custom", "pencil":
      return icons["type-custom"]!
    case "timer":
      return icons["clock"]!
    default:
      return icons["sparkle"]!
    }
  }

  /// Authoritative 24x24 vector primitives from `apps/mobile/lib/ui/components/ourney_icons.dart`.
  private static let icons: [String: OurneyIconSpec] = [
    "flame": OurneyIconSpec(
      primitives: [
        .path("M12 21c-4.4 0-7-2.6-7-6.5 0-3 2-5.2 4.3-7.7.1 2 1.1 3 2 3.5.4-3.5 2.1-5.8 4.3-7.3.1 3.6 3.4 5.7 3.4 10 0 4.8-3 8-7 8Z", fill: true)
      ],
      stickerHex: 0xC2452B,
      corePathD: "M12 18.6c-2 0-3.3-1.2-3.3-3 0-1.4.8-2.5 2-3.6.1 1 .6 1.6 1.2 1.9.2-1.7 1-2.8 2-3.6.1 1.7 1.8 2.8 1.8 5.1 0 2-1.5 3.2-3.7 3.2Z",
      coreHex: 0xFF9F1C
    ),
    "camera": OurneyIconSpec(
      primitives: [
        .path("M4 7.5h3l1.5-2h7l1.5 2h3v11H4Z", fill: true),
        .circle(cx: 12, cy: 13, r: 3.5, fill: true),
      ],
      stickerHex: 0x10B981,
      interiorInkDetail: .circle(cx: 12, cy: 13, r: 3.2, fill: false)
    ),
    "check": OurneyIconSpec(
      primitives: [
        .path("m6 12.5 4 4 8-9", fill: false)
      ],
      stickerHex: 0x10B981,
      isOpenStroke: true
    ),
    "check-circle": OurneyIconSpec(
      primitives: [
        .circle(cx: 12, cy: 12, r: 9, fill: true),
        .path("m8 12.5 3 3 5-6", fill: false),
      ],
      stickerHex: 0x10B981,
      interiorInkDetail: .path("m8 12.5 3 3 5-6", fill: false)
    ),
    "clock": OurneyIconSpec(
      primitives: [
        .circle(cx: 12, cy: 12, r: 8, fill: true),
        .path("M12 7v5l3.5 2M9 2h6", fill: false),
      ],
      stickerHex: 0x2AA7E0,
      interiorInkDetail: .path("M12 7v5l3.5 2", fill: false)
    ),
    "journeys": OurneyIconSpec(
      primitives: [
        .path("M3.5 5.5 9 3l6 2.5L20.5 3v15.5L15 21l-6-2.5L3.5 21Z", fill: true),
        .path("M9 3v15.5M15 5.5V21", fill: true),
        .path("m6 14 2-2 3 2 4-5 2 2", fill: true),
      ],
      stickerHex: 0xC2452B,
      interiorInkDetail: .path("M9 3v15.5M15 5.5V21", fill: false)
    ),
    "squad": OurneyIconSpec(
      primitives: [
        .circle(cx: 9, cy: 8, r: 3, fill: true),
        .circle(cx: 17, cy: 9, r: 2.5, fill: true),
        .path("M3.5 19c.4-4 2.2-6 5.5-6s5.1 2 5.5 6M14 14c3.7-.5 5.8 1.2 6.3 4.5", fill: true),
      ],
      stickerHex: 0xFF9F1C
    ),
    "chevron-right": OurneyIconSpec(
      primitives: [
        .path("m9 5 7 7-7 7", fill: false)
      ],
      stickerHex: 0x2AA7E0,
      isOpenStroke: true
    ),
    "close": OurneyIconSpec(
      primitives: [
        .path("m5 5 14 14M19 5 5 19", fill: false)
      ],
      stickerHex: 0xC2452B,
      isOpenStroke: true
    ),
    "lock": OurneyIconSpec(
      primitives: [
        .path("M6 10h12v10H6Z", fill: true),
        .path("M8.5 10V7.5a3.5 3.5 0 0 1 7 0V10", fill: false),
        .path("M12 14v2.5", fill: false),
      ],
      stickerHex: 0x2AA7E0,
      interiorInkDetail: .path("M12 14v2.5", fill: false)
    ),
    "sparkle": OurneyIconSpec(
      primitives: [
        .path("m12 3 1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8Z", fill: true),
        .path("m19 15 .8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8Z", fill: true),
      ],
      stickerHex: 0xFF9F1C
    ),
    "type-weight": OurneyIconSpec(
      primitives: [
        .path("M12 4v16M7 20h10M5 7h14", fill: false),
        .path("M5 7l-3 6h6ZM19 7l-3 6h6Z", fill: true),
      ],
      stickerHex: 0x10B981
    ),
    "type-study": OurneyIconSpec(
      primitives: [
        .path("M4 4h6c2 0 2 2 2 2v14c0-2-2-2-2-2H4ZM20 4h-6c-2 0-2 2-2 2v14c0-2 2-2 2-2h6Z", fill: true)
      ],
      stickerHex: 0xFF9F1C,
      interiorInkDetail: .path("M12 6v14", fill: false)
    ),
    "type-trip": OurneyIconSpec(
      primitives: [
        .path("M6 7h12v14H6Z", fill: true),
        .path("M9 7V4h6v3M9 11h6M10 21v1M14 21v1", fill: false),
      ],
      stickerHex: 0xC2452B,
      interiorInkDetail: .path("M9 11h6", fill: false)
    ),
    "type-couple": OurneyIconSpec(
      primitives: [
        .path("M12 20S4 15.5 4 9.5C4 5 9.5 4 12 8c2.5-4 8-3 8 1.5 0 6-8 10.5-8 10.5Z", fill: true)
      ],
      stickerHex: 0xFF4D6D
    ),
    "type-workout": OurneyIconSpec(
      primitives: [
        .path("M7 8v8M4 10v4M17 8v8M20 10v4M7 12h10", fill: false)
      ],
      stickerHex: 0x2AA7E0,
      isOpenStroke: true
    ),
    "type-custom": OurneyIconSpec(
      primitives: [
        .path("m12 3 1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8Z", fill: true),
        .path("m19 15 .8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8Z", fill: true),
      ],
      stickerHex: 0xA13CC9
    ),
    "trophy": OurneyIconSpec(
      primitives: [
        .path("M7 4h10v5c0 3.5-2 5.5-5 5.5S7 12.5 7 9Z", fill: true),
        .path("M7 6H4v2c0 2 1.2 3 3.5 3M17 6h3v2c0 2-1.2 3-3.5 3M12 14.5V19M8 20h8", fill: false),
      ],
      stickerHex: 0xFF9F1C
    ),
    "star": OurneyIconSpec(
      primitives: [
        .path("m12 3 2.6 5.4 5.9.8-4.3 4.2 1 5.9-5.2-2.8-5.2 2.8 1-5.9-4.3-4.2 5.9-.8Z", fill: true)
      ],
      stickerHex: 0xFF9F1C
    ),
  ]
}

// MARK: - SVG Path Parser (Port of parseSvgPath in ourney_icons.dart)

enum OurneySvgPathParser {
  private static let tokenRegex = try! NSRegularExpression(
    pattern: #"[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?"#
  )

  static func parse(_ d: String, scale: CGFloat = 1.0) -> Path {
    let nsRange = NSRange(d.startIndex..<d.endIndex, in: d)
    let matches = tokenRegex.matches(in: d, range: nsRange)
    let tokens: [String] = matches.compactMap { match in
      guard let range = Range(match.range, in: d) else { return nil }
      return String(d[range])
    }

    var path = Path()
    var i = 0
    var cmd: Character = " "
    var x: CGFloat = 0
    var y: CGFloat = 0
    var sx: CGFloat = 0
    var sy: CGFloat = 0
    var lcx: CGFloat?
    var lcy: CGFloat?
    var lqx: CGFloat?
    var lqy: CGFloat?

    func nextNum() -> CGFloat {
      guard i < tokens.count else { return 0 }
      let raw = tokens[i]
      i += 1
      return CGFloat(Double(raw) ?? 0)
    }

    func isCommandToken(_ token: String) -> Bool {
      guard token.count == 1, let first = token.first else { return false }
      return first.isLetter
    }

    while i < tokens.count {
      if isCommandToken(tokens[i]) {
        cmd = tokens[i].first!
        i += 1
        if cmd == "Z" || cmd == "z" {
          path.closeSubpath()
          x = sx
          y = sy
          lcx = nil
          lcy = nil
          lqx = nil
          lqy = nil
          continue
        }
      } else if cmd == " " {
        break
      } else if cmd == "M" {
        cmd = "L"
      } else if cmd == "m" {
        cmd = "l"
      }

      let isRel = cmd.isLowercase
      let ox: CGFloat = isRel ? x : 0
      let oy: CGFloat = isRel ? y : 0
      let upper = cmd.uppercased().first!

      switch upper {
      case "M":
        x = nextNum() + ox
        y = nextNum() + oy
        sx = x
        sy = y
        path.move(to: CGPoint(x: x * scale, y: y * scale))
        lcx = nil
        lcy = nil
        lqx = nil
        lqy = nil
      case "L":
        x = nextNum() + ox
        y = nextNum() + oy
        path.addLine(to: CGPoint(x: x * scale, y: y * scale))
        lcx = nil
        lcy = nil
        lqx = nil
        lqy = nil
      case "H":
        x = nextNum() + ox
        path.addLine(to: CGPoint(x: x * scale, y: y * scale))
        lcx = nil
        lcy = nil
        lqx = nil
        lqy = nil
      case "V":
        y = nextNum() + oy
        path.addLine(to: CGPoint(x: x * scale, y: y * scale))
        lcx = nil
        lcy = nil
        lqx = nil
        lqy = nil
      case "C":
        let x1 = nextNum() + ox
        let y1 = nextNum() + oy
        let x2 = nextNum() + ox
        let y2 = nextNum() + oy
        x = nextNum() + ox
        y = nextNum() + oy
        path.addCurve(
          to: CGPoint(x: x * scale, y: y * scale),
          control1: CGPoint(x: x1 * scale, y: y1 * scale),
          control2: CGPoint(x: x2 * scale, y: y2 * scale)
        )
        lcx = x2
        lcy = y2
        lqx = nil
        lqy = nil
      case "S":
        let x1 = lcx != nil ? (2 * x - lcx!) : x
        let y1 = lcy != nil ? (2 * y - lcy!) : y
        let x2 = nextNum() + ox
        let y2 = nextNum() + oy
        x = nextNum() + ox
        y = nextNum() + oy
        path.addCurve(
          to: CGPoint(x: x * scale, y: y * scale),
          control1: CGPoint(x: x1 * scale, y: y1 * scale),
          control2: CGPoint(x: x2 * scale, y: y2 * scale)
        )
        lcx = x2
        lcy = y2
        lqx = nil
        lqy = nil
      case "Q":
        let x1 = nextNum() + ox
        let y1 = nextNum() + oy
        x = nextNum() + ox
        y = nextNum() + oy
        path.addQuadCurve(
          to: CGPoint(x: x * scale, y: y * scale),
          control: CGPoint(x: x1 * scale, y: y1 * scale)
        )
        lqx = x1
        lqy = y1
        lcx = nil
        lcy = nil
      case "T":
        let x1 = lqx != nil ? (2 * x - lqx!) : x
        let y1 = lqy != nil ? (2 * y - lqy!) : y
        x = nextNum() + ox
        y = nextNum() + oy
        path.addQuadCurve(
          to: CGPoint(x: x * scale, y: y * scale),
          control: CGPoint(x: x1 * scale, y: y1 * scale)
        )
        lqx = x1
        lqy = y1
        lcx = nil
        lcy = nil
      case "A":
        let rx = abs(nextNum())
        let ry = abs(nextNum())
        let xAxisRotation = nextNum() * .pi / 180.0
        let largeArcFlag = nextNum() != 0
        let sweepFlag = nextNum() != 0
        let nx = nextNum() + ox
        let ny = nextNum() + oy
        addSvgArc(
          to: &path,
          from: CGPoint(x: x, y: y),
          to: CGPoint(x: nx, y: ny),
          rx: rx,
          ry: ry,
          phi: xAxisRotation,
          largeArc: largeArcFlag,
          sweep: sweepFlag,
          scale: scale
        )
        x = nx
        y = ny
        lcx = nil
        lcy = nil
        lqx = nil
        lqy = nil
      default:
        break
      }
    }
    return path
  }

  /// Standard W3C SVG F.6.5 endpoint-to-center arc parameterization approximated via cubic Beziers.
  private static func addSvgArc(
    to path: inout Path,
    from p1: CGPoint,
    to p2: CGPoint,
    rx rawRx: CGFloat,
    ry rawRy: CGFloat,
    phi: CGFloat,
    largeArc: Bool,
    sweep: Bool,
    scale: CGFloat
  ) {
    if p1 == p2 { return }
    if rawRx == 0 || rawRy == 0 {
      path.addLine(to: CGPoint(x: p2.x * scale, y: p2.y * scale))
      return
    }
    var rx = abs(rawRx)
    var ry = abs(rawRy)
    let cosPhi = cos(phi)
    let sinPhi = sin(phi)
    let dx2 = (p1.x - p2.x) / 2.0
    let dy2 = (p1.y - p2.y) / 2.0
    let x1p = cosPhi * dx2 + sinPhi * dy2
    let y1p = -sinPhi * dx2 + cosPhi * dy2

    let rxSq = rx * rx
    let rySq = ry * ry
    let x1pSq = x1p * x1p
    let y1pSq = y1p * y1p

    let lambda = (x1pSq / rxSq) + (y1pSq / rySq)
    if lambda > 1.0 {
      let root = sqrt(lambda)
      rx *= root
      ry *= root
    }

    let rxSq2 = rx * rx
    let rySq2 = ry * ry
    let num = max(0.0, rxSq2 * rySq2 - rxSq2 * y1pSq - rySq2 * x1pSq)
    let den = rxSq2 * y1pSq + rySq2 * x1pSq
    let sign: CGFloat = (largeArc == sweep) ? -1.0 : 1.0
    let coef = sign * sqrt(den == 0 ? 0 : num / den)
    let cxp = coef * ((rx * y1p) / ry)
    let cyp = coef * (-(ry * x1p) / rx)

    let cx = cosPhi * cxp - sinPhi * cyp + (p1.x + p2.x) / 2.0
    let cy = sinPhi * cxp + cosPhi * cyp + (p1.y + p2.y) / 2.0

    func angle(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat {
      let dot = ux * vx + uy * vy
      let len = sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy))
      let clamped = min(max(len == 0 ? 1 : dot / len, -1.0), 1.0)
      let a = acos(clamped)
      return (ux * vy - uy * vx) < 0 ? -a : a
    }

    let ux = (x1p - cxp) / rx
    let uy = (y1p - cyp) / ry
    let vx = (-x1p - cxp) / rx
    let vy = (-y1p - cyp) / ry

    let theta1 = angle(1, 0, ux, uy)
    var dTheta = angle(ux, uy, vx, vy)
    if !sweep && dTheta > 0 {
      dTheta -= 2.0 * .pi
    } else if sweep && dTheta < 0 {
      dTheta += 2.0 * .pi
    }

    let segments = max(1, Int(ceil(abs(dTheta) / (.pi / 2.0))))
    let delta = dTheta / CGFloat(segments)
    let alpha = (4.0 / 3.0) * tan(delta / 4.0)

    for seg in 0..<segments {
      let t1 = theta1 + CGFloat(seg) * delta
      let t2 = t1 + delta
      let cos1 = cos(t1), sin1 = sin(t1)
      let cos2 = cos(t2), sin2 = sin(t2)

      let q1x = rx * (cos1 - alpha * sin1)
      let q1y = ry * (sin1 + alpha * cos1)
      let q2x = rx * (cos2 + alpha * sin2)
      let q2y = ry * (sin2 - alpha * cos2)
      let endX = rx * cos2
      let endY = ry * sin2

      let c1 = CGPoint(
        x: (cx + cosPhi * q1x - sinPhi * q1y) * scale,
        y: (cy + sinPhi * q1x + cosPhi * q1y) * scale
      )
      let c2 = CGPoint(
        x: (cx + cosPhi * q2x - sinPhi * q2y) * scale,
        y: (cy + sinPhi * q2x + cosPhi * q2y) * scale
      )
      let end = CGPoint(
        x: (cx + cosPhi * endX - sinPhi * endY) * scale,
        y: (cy + sinPhi * endX + cosPhi * endY) * scale
      )
      path.addCurve(to: end, control1: c1, control2: c2)
    }
  }
}
