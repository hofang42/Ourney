# ADR 0003: Liquid Glass dock via liquid_glass_widgets

Status: accepted (docs/bugs.md #11)

## Context
The owner wants real iOS 26 Liquid Glass (refraction, specular rim, adaptive
tint) on the floating dock, not blur plus border.

## Decision
Use `liquid_glass_widgets` ^1.17.3 (MIT, no third-party deps, Flutter >= 3.41,
Android/iOS/desktop; repo is on Flutter 3.47). `GlassContainer(useOwnLayer)`
wraps the dock capsule. Rejected: `liquid_glass_renderer` (1.0.0-dev, needs the
preview Flutter GPU flag, "not battle-tested"); `liquid_glass_easy` (no stated
SDK floor, no test story, Skia needs a background widget).

## Fallback
`UiDock` draws the old blurred translucent capsule (`UiGlass`, no shader) when
`MediaQuery.highContrast`, the `reduceTransparency` argument, `liquid: false`,
web, or `flutter test` (shader not loadable). The package itself drops to a
cheaper tier on Skia/low-end/thermal throttle.

## Consequences
- Selection indicator is an accent-tinted capsule with a specular rim (not a
  second shader, glass-on-glass degrades in this package).
- Liquid path has no black outline or hard shadow (Apple look); fallback keeps
  them.
- Shader cost and Impeller on Android must be verified on device.
- Optional: call `LiquidGlassWidgets.initialize()` in main() to pre-warm shaders.
