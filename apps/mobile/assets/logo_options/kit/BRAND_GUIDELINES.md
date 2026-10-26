# Ourney — Brand & Logo Guidelines

> **One-sentence idea**: An open circular journey trail (**`O`**) leading up to a bold tactile **Shutter Milestone Dot** at `45°` — capturing *every day's photo check-in on a shared path*.

---

## 1. Logo System & Master Files

- **Versions**:
  - **Primary Lockup (Horizontal)**: `source/ourney-logo-horizontal-color.svg` (use for app headers, website nav, wide banners).
  - **Stacked Lockup (Vertical)**: `source/ourney-logo-stacked-color.svg` (use for splash screens, tote bags, square posters, merchandise).
  - **Standalone Symbol (`Milestone Loop`)**: `source/ourney-symbol-color.svg` (use for avatars, badges, watermark stamps).
  - **Small-Size Cut (`16–32 px`)**: `source/ourney-symbol-small.svg` (thickened loop & enlarged shutter dot for favicons and tiny UI badges).
  - **Standalone Wordmark**: `source/ourney-wordmark-color.svg` (use when the symbol is already present nearby).
- **Directories**:
  - `source/*.svg` — Master vector files (pure geometric outlines, zero `<text>` font dependencies, `100/100` SVG audit score).
  - `digital/*.svg|png` — Full colour, one-colour black, one-colour white (reversed), and one-colour Terracotta (`#CC4A2F`) variants at `512px`, `1024px`, and `1200px`.
  - `web-icons/*` — `favicon.ico` (`16/32/48px`), `apple-touch-icon.png` (`180px`), `icon-192.png`, `icon-512.png`, `maskable-512.png`, `site.webmanifest`, and `head-snippet.html`.

---

## 2. Clear Space & Positioning

- **Clear Space Unit (`1 × D`)**: Keep an unobstructed margin of **`1 × D`** around the logo on all four sides, where **`D`** is the diameter of the **Shutter Milestone Dot** (`52` units on the `256` symbol canvas, or `≈ 20%` of the symbol's height).
- **Optical Centring**: When placing the standalone symbol inside a square or circular container, use `ourney-symbol-square.svg` or `ourney-icon-app-icon.svg`.

---

## 3. Minimum Sizes

| Version | Screen (Digital) | Print / Physical | Notes |
|---|---|---|---|
| **Horizontal Lockup** | `96 px` wide | `24 mm` wide | Below `96 px`, switch to the standalone Symbol |
| **Stacked Lockup** | `72 px` wide | `18 mm` wide | Ideal for centred cards and splash screens |
| **Standalone Symbol** | `16 px × 16 px` | `5 mm × 5 mm` | For `16–24 px`, always use `ourney-symbol-small.svg` / `favicon.ico` |

---

## 4. Brand Colour Palette

| Colour Name | Role | HEX | RGB | CMYK | Pantone (Approx.) | Contrast |
|---|---|---|---|---|---|---|
| **Ourney Terracotta** | Shutter Milestone Dot, App Icon Tile, Primary CTA | `#CC4A2F` | `204, 74, 47` | `15, 81, 88, 4` | `7626 C` | `4.62 : 1` on White |
| **Editorial Ink** | Journey Loop (`O`), Wordmark, One-Colour Dark | `#1E1B18` | `30, 27, 24` | `70, 67, 68, 78` | `Black 7 C` | `15.8 : 1` on Paper |
| **Warm Paper** | Light Background, Reversed Loop on Dark Mode | `#F6F2EA` | `246, 242, 234` | `3, 4, 8, 0` | `7527 C` | `14.9 : 1` vs Ink |
| **Dark Mode Coral** | Shutter Dot on Dark Surfaces (`#141312`) | `#FF6B4A` | `255, 107, 74` | `0, 68, 72, 0` | `171 C` | `5.84 : 1` on `#141312` |
| **Sun Amber** | Shutter Dot Accent on Terracotta (`#CC4A2F`) Tile | `#FFD166` | `255, 209, 102` | `0, 19, 68, 0` | `1215 C` | `2.85 : 1` vs `#CC4A2F` |

### Approved Background Combinations
1. **Light Mode (Warm Paper `#F6F2EA` or White `#FFFFFF`)**: Use `ourney-logo-horizontal-color.svg` (`#1E1B18` loop/type + `#CC4A2F` dot).
2. **Dark Mode (`#141312` or `#0B0F12`)**: Use `ourney-logo-horizontal-on-dark.svg` (irradiation-thinned `#F6F2EA` loop/type + `#FF6B4A` dot).
3. **Brand Terracotta Tile (`#CC4A2F`)**: Use `ourney-symbol-on-tile.svg` (`#FFFFFF` loop + `#FFD166` dot) or pure white `ourney-symbol-white.svg`.
4. **Photography / Live Viewfinder Scrims**: Place `ourney-logo-horizontal-white.svg` or `ourney-symbol-white.svg` over a dark translucent pill (`Colors.black.withValues(alpha: 0.55)`).

---

## 5. Typography System

- **Logo Wordmark**: Custom-constructed geometric lowercase paths (`o-u-r-n-e-y`, `26`-unit constant stem weight, optical overshoots, `40°` terminal on `e`). Never re-type the logo wordmark using a system font.
- **Display & Headings**: **Bricolage Grotesque** (SemiBold / Bold, bundled in `apps/mobile/assets/fonts/BricolageGrotesque-Variable.ttf`, Open Font License).
- **UI & Body Copy (Vietnamese-Optimized)**: **Be Vietnam Pro** (Regular / Medium / SemiBold / Bold, bundled in `apps/mobile/assets/fonts/BeVietnamPro-*.ttf`, Open Font License).

---

## 6. Logo Misuse (Don'ts)

- **Don't** rotate the symbol — the Shutter Milestone Dot must always sit at the upper-right (`45°`) summit.
- **Don't** close the negative-space gaps around the Shutter Milestone Dot or attach it to the ring.
- **Don't** apply generic rainbow gradients, drop shadows, or 3D bevels to the mark.
- **Don't** swap the colours of the Loop and the Dot on light backgrounds (the Loop carries the structural weight in Ink; the Dot is the focal Terracotta accent).
- **Don't** use the standard symbol below `24 px` when `ourney-symbol-small.svg` (`favicon`) is available.
