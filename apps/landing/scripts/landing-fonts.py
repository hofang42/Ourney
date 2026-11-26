"""Build or verify the landing WOFF2s using the checked-in mobile TTFs."""

import argparse
from pathlib import Path
from tempfile import TemporaryDirectory
from unicodedata import normalize

import ots
import uharfbuzz as hb
from fontTools import subset
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont
from fontTools.ttLib.tables import otTables

APPS = Path(__file__).resolve().parents[2]
SOURCE = APPS / "mobile/assets/fonts"
LANDING = APPS / "landing/assets/fonts"
FONTS = ("BeVietnamPro-Regular", "BeVietnamPro-SemiBold", "SpaceGrotesk-Variable")
LIGATURES = dict(zip(("ff", "fi", "fl", "ffi", "ffl"), range(0xFB00, 0xFB05)))
VIETNAMESE = "ÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĐĨŨƠƯàáâãèéêìíòóôõùúăđĩũơư" + "".join(
    map(chr, range(0x1EA0, 0x1EFA))
)
VIETNAMESE_REQUIRED = set(map(ord, VIETNAMESE + normalize("NFD", VIETNAMESE)))
WEB_RANGES = (
    (0x0000, 0x024F),  # Latin, including Vietnamese extended letters
    (0x0300, 0x036F),  # Vietnamese combining marks
    (0x1E00, 0x1EFF),  # Latin Extended Additional, including Vietnamese vowels
    (0x2000, 0x25FF),  # Punctuation, currency, arrows, symbols and geometric shapes
    (0xFB00, 0xFB04),
    (0xFEFF, 0xFEFF),
    (0xFFFD, 0xFFFD),
)


def shape(font, text):
    buffer = hb.Buffer()
    buffer.add_str(text)
    buffer.guess_segment_properties()
    buffer.language = "vi"
    hb.shape(font, buffer)
    return list(zip(buffer.glyph_infos, buffer.glyph_positions))


def complete_be_vietnam_ligatures(font, source):
    gsub = font["GSUB"].table
    feature = next(r.Feature for r in gsub.FeatureList.FeatureRecord if r.FeatureTag == "liga")
    lookup = gsub.LookupList.Lookup[feature.LookupListIndex[0]].SubTable[0]
    ligatures = lookup.ligatures["f"]
    names = {"f" + "".join(lig.Component): lig.LigGlyph for lig in ligatures}
    source_shaper = hb.Font(hb.Face(source.read_bytes()))
    order = font.getGlyphOrder()

    # Preserve the native ff, fi and ffi outlines. Build fl and ffl from the
    # native f/ff and l outlines at their original shaped positions.
    for text in ("fl", "ffl"):
        pen = TTGlyphPen(font.getGlyphSet())
        advance = 0
        first_bearing = None
        for info, position in shape(source_shaper, text):
            glyph = font.getGlyphName(info.codepoint)
            x = advance + position.x_offset
            pen.addComponent(glyph, (1, 0, 0, 1, x, position.y_offset))
            if first_bearing is None:
                first_bearing = font["hmtx"][glyph][1] + x
            advance += position.x_advance

        glyph = "_".join(text) + ".liga"
        order.append(glyph)
        font.setGlyphOrder(order)
        font["glyf"][glyph] = pen.glyph()
        font["hmtx"][glyph] = (advance, first_bearing)
        names[text] = glyph
        ligature = otTables.Ligature()
        ligature.Component = list(text[1:])
        ligature.CompCount = len(text)
        ligature.LigGlyph = glyph
        ligatures.append(ligature)

    # Longer substitutions must precede their shared prefixes.
    ligatures.sort(key=lambda lig: -lig.CompCount)
    for table in font["cmap"].tables:
        if table.isUnicode() and table.format in (4, 12):
            table.cmap.update({cp: names[text] for text, cp in LIGATURES.items()})


def build(name):
    source = SOURCE / f"{name}.ttf"
    with TTFont(source, recalcTimestamp=False) as font:
        if name.startswith("BeVietnamPro"):
            complete_be_vietnam_ligatures(font, source)
        options = subset.Options()
        options.layout_features = ["*"]
        subsetter = subset.Subsetter(options=options)
        subsetter.populate(unicodes={cp for lo, hi in WEB_RANGES for cp in range(lo, hi + 1)})
        subsetter.subset(font)
        font.flavor = "woff2"
        font.save(LANDING / f"{name}.woff2")


def check(name):
    path = LANDING / f"{name}.woff2"
    with TTFont(path) as font:
        if font.flavor != "woff2":
            raise ValueError(f"{path.name}: expected WOFF2")
        font.ensureDecompiled()
        cmap = font.getBestCmap()
        missing = VIETNAMESE_REQUIRED.union(LIGATURES.values()).difference(cmap)
        if missing:
            raise ValueError(f"{path.name}: missing {', '.join(f'U+{cp:04X}' for cp in sorted(missing))}")
        for cp in LIGATURES.values():
            if not font["glyf"][cmap[cp]].numberOfContours:
                raise ValueError(f"{path.name}: empty outline for U+{cp:04X}")
        with TemporaryDirectory() as tmp:
            sfnt = Path(tmp) / "sanitized.ttf"
            ots.sanitize(str(path), str(sfnt), check=True)
            shaper = hb.Font(hb.Face(sfnt.read_bytes()))

        for text in (VIETNAMESE, normalize("NFD", VIETNAMESE)):
            if any(info.codepoint == 0 for info, _ in shape(shaper, text)):
                raise ValueError(f"{path.name}: Vietnamese shaping produced .notdef")
        if name.startswith("BeVietnamPro"):
            for text, cp in LIGATURES.items():
                expected = font.getGlyphID(cmap[cp])
                glyphs = [info.codepoint for info, _ in shape(shaper, text)]
                if glyphs != [expected]:
                    raise ValueError(f"{path.name}: {text} did not shape as U+{cp:04X}")
        print(f"{path.name}: decoded, sanitized and shaped")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", action="store_true", help="rebuild before checking")
    args = parser.parse_args()
    for name in FONTS:
        if args.build:
            build(name)
        check(name)


if __name__ == "__main__":
    main()
