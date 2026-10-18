# Text

This file covers fonts and text: the font files (`.fnt` sources and compiled `.pft`), font families, glyphs, kerning,
tracking and leading, measuring text (`getTextSize`, `getTextWidth`), drawing it (`drawText`, `drawTextInRect`,
`font:drawText`, the CoreLibs helpers and localized text), wrapping and alignment, styled text, and the system fonts.
Glyphs are images and are drawn with the image draw mode; image drawing is in [images.md](images.md), and the drawing
context, clip rect and draw offset in [drawing.md](drawing.md) and [display.md](display.md). Unqualified rules were
measured in the Simulator (SDK 3.1.1); "on the device (3.1.2, by analysis)" marks the device's behaviour, and where the
two differ both are given. Numbers given for "the system font" are for its normal variant, Asheville Sans 14 Light,
unless a variant is named.

## The system fonts

- **Files:** `/System/Fonts` holds four Asheville fonts and seven Roobert fonts: Roobert 10 Bold, 11 Bold, 11 Medium, 11
  Medium extended, 20 Medium, 20 Medium extended and 24 Medium. Games load them by path, for example
  `loadFont("/System/Fonts/Roobert-10-Bold")`. They are the same files in the Simulator and on the device (on the device
  by analysis). The Playdate SDK's README licenses its fonts under CC BY 4.0, so an implementation can carry copies with
  attribution.
- **The system font** (`gfx.getSystemFont([variant])`) is Asheville Sans 14 in three variants: normal
  (`Asheville-Sans-14-Light`), bold and italic (`Asheville-Sans-14-Light-Oblique`). Its height is 20, its tracking 2
  (bold 1, italic 1) and its leading 0.
- **The CoreLibs keyboard** (`playdate.keyboard`) draws in Roobert-24-Keyboard-Medium (36 pixels high; "ABC@" is 132
  wide), which comes with the system's CoreLibs assets, not with the game.
- **Sample metrics** of the system font: "a" advances 7, a space 3, "H" 8, "A" 9, "W" 13; "Hello world" is 77 wide;
  U+FFFD (the replacement glyph, a diamond with a question mark) is 15 wide. `getGlyph("A")` returns a 20 by 20 image.

## Font files and loading

- **`gfx.font.new(path)`** loads a compiled `.pft`, with or without the extension. Like image tables, it also accepts a
  font's source name: "images/Score-table-8-16.png" for the compiled "images/Score.pft". A missing file returns nil
  and "file <path> not found: No such file". On the device (3.1.2, by analysis) names are matched ignoring case; the
  Linux Simulator is case-sensitive (`font.new("fonts/monocraft-18")` fails there for `Monocraft-18.fnt`).
- **`.fnt` sources** (text) set properties such as `tracking=-2` and are compiled by pdc into `.pft`.
- **Compiled layout** (as read by a loader):
  - The file starts with the "Playdate FNT" magic and a flags word. Bit 0 of the flags marks a **wide** font: 128 bytes
    of page flags, covering characters up to U+3FFFF, instead of 64. pdc writes wide fonts for large character sets (a
    6,857-glyph Chinese font is one).
  - Page flags hold 8 pages per byte, from the lowest bit of the first byte: page number = byte index * 8 + bit
    index. Each page holds 256 characters.
  - A page's glyph count is one byte, so a full page of 256 glyphs stores 0; the page's usage flags give the real
    count.
  - **Tracking** is a signed byte: the m6x11 font's -2 reads as -2 (a "Press A to start" prompt is then 140 pixels
    wide). A common mistake is to read it as unsigned, which makes text thousands of pixels wide.
  - **Kerning** pairs are stored on the left glyph, keyed by the right character. Short entries name a character in
    the same page as the glyph, by that page's number; long entries hold the character in the low 24 bits and the
    amount in the top byte.
- **C `makeFontFromData(data, length)`** wraps the given data (a `.pft` file's contents after its 16-byte header)
  without copying; on the device (3.1.2, by analysis) the deprecated two-argument form is the same with a length of 0
  (unbounded reads). Text drawn with such a font matches text drawn with the font loaded from its file.
- **C `loadFont(path, &err)`** accepts a NULL error pointer. On the device (3.1.2, by analysis), `getFontHeight(NULL)`
  returns 0.
- **Lifetime:** the font metatable has a `__gc`, so a font Lua drops is freed. Loading a font costs about its file
  size; an emulator that makes a bitmap per glyph at load time runs out of memory with large fonts (NotoSans), so make
  glyph images on first use.

## Glyphs

- **`font:getGlyph(c)`** returns the glyph's image and its advance ("a": 7, "W": 13). A missing page returns nil.
  - In the Simulator a string gives its first *byte* ("ab" is "a"), and a first byte from 0x80 gives an unrelated
    image or a crash: "\uFFFD" returns an unrelated 20 by 20 image and "\u00E9" crashes it.
  - On the device (3.1.2, by analysis) the string's first UTF-8 character is decoded; a bad continuation byte gives
    character 0.
  - In both, a number is read as its text: `getGlyph(65)` is the glyph for "6", and `getGlyph(97)` the one for "9".
    ASCII gives the same glyph in both.
  - For a character a wide font lacks (U+9FA5 in the Chinese font above) the Simulator crashes; on the device (3.1.2,
    by analysis) it returns nil.
- **C `getFontGlyph(font, c, &bitmap, &advance)`** returns the glyph with its bitmap and advance ("A": 9);
  `getFontPage` and `getPageGlyph` give the same.
- **Missing characters:** `gfx.drawText` draws a character the current font lacks with the font's U+FFFD glyph; if
  the font has none either, see "Fallback to the system font" below.
- **Zero-width code points** have no glyph and no advance; text is drawn and measured as if they were absent: the
  combining diacritical marks (U+0300 to U+036F), the zero width space (U+200B) and the variation selectors (U+FE00 to
  U+FE0F). Emoji sequences ending in U+FE0F therefore draw no extra box. `tests/probes/glyphq`, `glyphq2`
- **Stored rects:** like images, glyphs keep only their stored (trimmed) pixels plus the rect's offset in the cell.
  Drawing only the stored part is equivalent and faster.

## Tracking and leading

- **Tracking** is added between consecutive glyphs, never after the last. The font's own tracking (`font:getTracking`,
  `setTracking`) and the context's (`gfx.setFontTracking`, C `setTextTracking`) add up: `gfx.setFontTracking(3)` adds
  3 pixels per gap to `gfx.getTextSize`. `font:setTracking` truncates (1.6 is 1, -1.5 is -1). `gfx.getFontTracking()`
  returns a float.
- **Line height** = font height + font leading + context leading (C `setTextLeading`) + the call's leading
  adjustment: 20 per line for the system font. `font:setLeading(3)` reads back 3.
- **Lua and C keep separate text settings:** a C `setFont` or `setTextTracking` does not change Lua's font or
  tracking, and the other way round; each side's `pushContext` and `popContext` saves and restores only its own.
  `tests/probes/modeq`, `tests/probes/ctxq`

## Measuring text

### Width

`gfx.getTextSize(str, [fontFamily, [leadingAdjustment]])`, `font:getTextWidth(str)`, C `getTextWidth(font, text, len,
encoding, tracking)`:

- **Rule:** the sum of each glyph's advance, plus kerning, plus tracking between glyphs, except that the last glyph
  counts as the larger of its advance and its ink's right edge (the stored rect's left offset plus its width). Slanted
  glyphs reach past their advance: an italic "l" advances 2 but measures 5. Kerning example: the italic "a" kerns -1
  before "l", so "_ital_" is 22 wide. For the system font, "AV" and "VA" are both 20 (A + V is 18; the 2 is tracking).
- **Empty glyphs:** the italic system font's U+FFFD has no ink, an advance of 13, and an empty stored rect at x = 16
  with width 1. While no glyph with ink comes before it, that rect's right edge (17) counts: "\uFFFD" alone measures
  17, two in a row 31 (14 + 17), and after a space 21. After any glyph with ink only the advance counts: "a\uFFFD" is
  21 (8 + 13). Spaces never count this way. A model that matches every measured case: take the union of the glyphs'
  stored rects (an empty rect replaces an empty union) and use the larger of that and the advance-based width.
  `tests/probes/fffdq`, `fffdq3`
- **Multi-line:** the width is the widest line; the height is the line count times the line height:
  `getTextSize("Hello\nworld")` is 38 by 40, and with a leading adjustment of 5 it is 38 by 45. Results are integers.
- **C `getTextWidth`:** a NULL font means the current font. Its tracking argument is added per gap on top of the
  font's tracking ("Hello world" is 77 with 0 and 97 with 2), and the context tracking is not used. UTF-8
  "caf\xc3\xa9" is 40.
- **C `getTextHeightForMaxWidth(font, text, len, maxWidth, encoding, wrap, tracking, leading)`:** a NULL font means
  the current one; "one two three four" at 40 is 80.
- **CoreLibs `gfx.getTextSizeForMaxWidth("one two three four", 40)`** is 40 by 80.

### What `drawText` returns

`gfx.drawText` and `font:drawText` return the width and height of what they drew, as integers; C `drawText` returns
the width ("Hi 12": 31). The returned size is measured from ink, not from advances (`tests/probes/dtw`, `dtw2`):

- **Width** starts at the first glyph with ink and ends at the rightmost ink of the glyphs drawn. Leading and
  trailing spaces do not count: " a", "  a", "a" and "a " all return 7, and text without ink returns 0. "!" in
  Bitmore Medieval Bold returns 2 where `getTextSize` gives 3; the system font's "^" returns 5, not 8. Spaces inside a
  markup run (`*1 *`) drop out too.
- **Height** runs from the topmost ink of any line down to the bottom of the last line. "a" and "g" return 14, "H"
  19, "i" 18, text without ink 20; "Hi there" returns 44 by 19. "\na" returns 14, like "a", but empty lines at the end
  do count: "a\n" returns 34.
- **In a box** (below): the height counts every line, including those below the box (a 5-line text in a 40-pixel box
  returns 99), and the width is the widest line that starts inside the box, at most the box width, whatever the
  alignment.
- **Fallback glyphs** (below) make the returned height the system font's height.
- Text whose characters are all missing still returns the font's height.

## Drawing text

### `gfx.drawText(text, x, y, [width, height], [fontFamily], [leadingAdjustment], [wrapMode], [alignment])`

- **Position:** fractional x and y round to nearest (CoreLibs centering at 26.5 draws at 27). `font:drawText` rounds
  the same way.
- **Box:** with a width and height (or a rect in place of x, y, width, height), the text wraps, by word by default.
  The whole text is laid out; drawing is clipped to the box by pixels, so a line partly below the box is cut
  through, lines wholly below it do not show, and in clip mode a glyph crossing the right edge is cut, not dropped.
  Without a box, text does not wrap at the image edge; it continues and is clipped. `tests/probes/twrap`
- **Font family:** the argument after the box, a table such as `gfx.font.newFamily` returns, supplies the fonts for
  this call. A variant the family leaves out keeps the current font, and an empty table changes nothing.
  `tests/probes/ffam`
- **Optional arguments are read by value, not position:** after the font family slot (a table or nil), numbers are
  read in order until the first value that is not a number. Each is a wrap mode or an alignment by its marker bits,
  and any other number is the leading adjustment, the last one winning. So a nil stops the reading:
  `drawText(s, x, y, w, h, nil, nil, gfx.kWrapWord, gfx.kAlignCenter)` is left-aligned, despite the documentation's
  "pass nil to use the default leading". A common trap: `kTextAlignment.right` (a plain 1, meant for
  `drawTextAligned`) becomes a leading of 1. Another example: `drawText("ab\ncd", 1, 1, nil, 6)` puts the second line
  26 pixels down.
- **Constants:** `kWrapClip`, `kWrapCharacter` and `kWrapWord` are 0x1000000 to 0x1000002; `kAlignLeft`,
  `kAlignCenter` and `kAlignRight` are 0x2000000 to 0x2000002. Native calls use the low byte. `kTextAlignment` (left
  0, right 1, center 2) exists only once CoreLibs/graphics is imported.
- **Unmodeled case:** with nil as the width, `drawText("Hi", 1, 1, nil, gfx.kAlignRight)` returns 0 by 21 in the
  Simulator.
- **`font:drawText(text, x, y, [width, height], [leadingAdjustment], [wrapMode], [alignment])`** reads its options
  and returns its size the same way (word wrap by default in a box, marker bits, integer results).
  `tests/probes/fontdt`

### Wrapping and alignment

- **When a line wraps:** when a glyph's right edge (pen x plus its advance, not counting the tracking after it) passes
  the box. A word exactly as wide as the box stays on one line.
- **Word wrap** moves the glyphs after the last space to the next line and drops the spaces at the break.
- **Alignment:** a right-aligned line is shifted by the free space; a centered one by half of it, rounded down
  (measured in C). CoreLibs' `drawTextAligned` and `font:drawTextAligned` compute a fractional position themselves
  (centering on half pixels for odd widths), which `drawText` then rounds to nearest.
- **C `drawTextInRect(text, len, encoding, x, y, width, height, wrap, align)`** goes through the same layout and
  clips its text to the rect.

### Styled text

- **Markup (Lua only):** `*` toggles bold and `_` toggles italic, one style at a time. A marker for the style in
  effect returns to normal; a marker for the other style switches to it. So `_*Goal*_` is italic for nothing, then
  bold "Goal", then normal, then italic again for what follows. `tests/probes/markq`
- **Tracking:** the tracking before each glyph is that glyph's own font's tracking (normal 2, bold 1, italic 1), so
  "a*b*" is 16 wide (7 + 1 + 8) and "*a*b" 17. A common mistake is to use the previous glyph's font's tracking.
- **C text has no markup:** on the device (3.1.2, by analysis) C `drawText`, `drawTextInRect` and `getTextWidth` use the
  current font alone, and `*` and `_` are ordinary characters.
- **Positions:** a style marker adds no offset of its own; with the tracking rule above, 14 styled strings (style
  changes, kerning pairs, spaces, doubled markers) give the Simulator's glyph columns and widths (`tests/probes/sty`).

### Fallback to the system font

`tests/probes/glyphfb`

- **`gfx.drawText` falls back:** a character that the current font lacks, with no U+FFFD glyph either, is drawn with
  the system font's glyph of the same style. The fallback glyph sits at the top of the line like the others; the gap
  before it is the system font's tracking and the gap after it the next glyph's font's; the returned height becomes
  the system font's height. Games use this for the Playdate button symbols (U+24B6 onward) in custom fonts.
- **Font methods do not fall back** (`font:drawText`, `font:getTextWidth` and so on): the character is skipped, and so
  is the tracking after the glyph before it. A font whose "xx" is 13 wide gives 12 for "x?x".

### Draw modes

Glyphs are drawn as images, in the current image draw mode (see [images.md](images.md)): `kDrawModeFillWhite` draws
white text, and text drawn under `kDrawModeNXOR` follows that mode. Lua and C keep separate draw modes, so Lua text
uses Lua's mode even after C code set another (the SDK's Particles example draws its Lua text in Copy mode although
its C code set Inverted). Inside a sprite's draw callback the global mode applies, not the sprite's; see
[sprites.md](sprites.md).

### Fonts in the context

- **Lua `gfx.setFont(font, [variant])`:** `setFont(nil)` (or no argument) leaves the font unchanged. C `setFont(NULL)`
  selects the system font.
- **`gfx.setFontFamily(family)`:** a font instead of a table makes that font the normal variant; `setFontFamily(nil)`
  does nothing. `tests/probes/famq`
- **`gfx.getFont([variant])`** and `getSystemFont` return the same value each call, as does a font set with `setFont`.
- **`gfx.font.newFamily(paths)`** returns a table keyed by `gfx.font.kVariantNormal`, `kVariantBold` (1) and
  `kVariantItalic`.

### Dirty areas

Once any sprite exists, text drawn straight to the screen marks dirty areas for the next sprite update: each glyph
gives its stored pixels' left, right and top, extended down to the bottom of its line ("A" at y = 100 in the system
font gives the rect 100, 101, 9, 19, and "A\nB" a height of 39). A glyph drawn as an image gives only its stored rect,
and a space gives none. See [sprites.md](sprites.md).

## CoreLibs text helpers

- `gfx.drawTextInRect(text, x, y, width, height, [leadingAdjustment, [truncationString, [alignment, [font]]]])`,
  `drawTextAligned`, `getTextSizeForMaxWidth`, `imageWithText` and `spriteWithText` are Lua code in CoreLibs, which
  the game compiles in; they exist only once CoreLibs/graphics is imported. An implementation needs only the native
  calls they make. `drawTextInRect` returns the width, the height and whether the text was truncated (45, 40 and true
  in one sample). `imageWithText` draws through `lockFocus`.

## Localized text

`tests/probes/locq` (a compressed table), `locqu` (built with `pdc -u`); both give the same results.

- **File layout:** a `.pds` table is a 4-byte count, then count - 1 offsets (of entries 2 to count, from the start of
  the entries), then the entries. Each entry is a key and its value, both NUL-terminated. pdc sorts the keys in byte
  order, so capitals come first.
- **`gfx.getLocalizedText(key, [language])`** returns the value, or the key itself when it is missing.
  - `kLanguageJapanese` (1), or the string "jp", picks `jp.strings`; nil picks the system language; anything else
    (another number such as 7 or -1, the string "en", a table) picks English (`kLanguageEnglish`, 0).
  - A key missing from the Japanese table returns the key; there is no fallback to English.
- **`gfx.drawLocalizedText(key, x, y, [language], [leadingAdjustment])`**, or `(key, rect, ...)` with only the rect's
  position used, draws in the current font as `drawText` does and returns the drawn width and height. x and y round
  to nearest; a missing y is an argument error. Width and height are not part of the signature:
  `(key, 10, 50, 100, 40)` is language 100 (English) with a leading adjustment of 40. For a missing key it draws
  nothing and returns a single nil, although `getLocalizedText` returns the key.
- **`drawLocalizedTextAligned` and `drawLocalizedTextInRect`** (CoreLibs) look the key up the same way.
