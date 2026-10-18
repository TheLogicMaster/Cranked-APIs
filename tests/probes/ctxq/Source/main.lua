-- Probe (with src/main.c): graphics state between Lua and the C API. Each case resets, changes one setting
-- on one side, draws on the other, and logs where the pixels landed.
local gfx = playdate.graphics
local out = playdate.file.open("ctxq.txt", playdate.file.kFileWrite)
local function log(...) local t = {} for i, v in ipairs({...}) do t[i] = tostring(v) end out:write(table.concat(t, " ") .. "\n") end
local snap
local function take() snap = gfx.getWorkingImage() end
local function black(x, y) if not snap then take() end return snap:sample(x, y) == gfx.kColorBlack and 1 or 0 end
local function reset()
  gfx.setDrawOffset(0, 0); coffset(0, 0); gfx.clearClipRect(); cclearclip(); gfx.setImageDrawMode(0); cmode(0)
  gfx.setFontTracking(0); ctracking(0); gfx.setLineWidth(1)
  gfx.clear(gfx.kColorWhite)
  snap = nil
end
local function frame()
  reset(); gfx.setDrawOffset(20, 0); cfill(0, 0, 4, 4)
  log("lua offset, C fill: at0", black(1, 1), "at20", black(21, 1))
  reset(); coffset(20, 0); gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 0, 4, 4)
  log("C offset, lua fill: at0", black(1, 1), "at20", black(21, 1))
  reset(); coffset(20, 0); cfill(0, 0, 4, 4); log("C offset, C fill: at20", black(21, 1))
  reset(); gfx.setClipRect(100, 0, 50, 50); cfill(0, 0, 200, 10)
  log("lua clip, C fill: at10", black(10, 5), "at120", black(120, 5))
  reset(); cclip(100, 0, 50, 50); gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 0, 200, 10)
  log("C clip, lua fill: at10", black(10, 5), "at120", black(120, 5))
  reset(); gfx.setFontTracking(5); log("lua tracking, C width:", ctextwidth("MMMM"), "lua width:", gfx.getTextSize("MMMM"))
  reset(); ctracking(5); log("C tracking, lua width:", gfx.getTextSize("MMMM"), "C width:", ctextwidth("MMMM"))
  reset(); gfx.setImageDrawMode(gfx.kDrawModeFillWhite); gfx.fillRect(0, 0, 400, 20); local w = ctext("MMMM", 0, 2)
  local n = 0 for x = 0, 60 do for y = 0, 18 do n = n + black(x, y) end end
  log("lua FillWhite, C text on black: black pixels", n)
  reset(); gfx.fillRect(0, 0, 400, 20); cmode(gfx.kDrawModeFillWhite); gfx.drawText("MMMM", 0, 2)
  n = 0 for x = 0, 60 do for y = 0, 18 do n = n + black(x, y) end end
  log("C FillWhite, lua text on black: black pixels", n)
  reset(); gfx.setLineWidth(5); cline(0, 50, 100, 50, 1); local thick = 0 for y = 44, 56 do thick = thick + black(50, y) end
  log("lua line width 5, C line width 1: rows", thick)
  reset(); gfx.pushContext(); gfx.setDrawOffset(30, 0); cfill(0, 0, 4, 4); gfx.popContext()
  log("lua pushContext+offset, C fill: at0", black(1, 1), "at30", black(31, 1))
  reset(); cpush(); gfx.setDrawOffset(30, 0); cpop(); gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 0, 4, 4)
  log("C push, lua offset, C pop, lua fill: at0", black(1, 1), "at30", black(31, 1))
  reset(); local bold = gfx.getSystemFont(gfx.font.kVariantBold); local normal = gfx.getSystemFont()
  gfx.setFont(bold); log("lua bold font, C width (NULL font):", ctextwidth("MMMM"), "bold", bold:getTextWidth("MMMM"), "normal", normal:getTextWidth("MMMM"))
  gfx.setFont(normal); log("C sets a font:", csetfont("/System/Fonts/Roobert-20-Medium.pft"), "lua width now", gfx.getTextSize("MMMM"), "C width", ctextwidth("MMMM"))
  gfx.setFont(normal)
  reset(); gfx.setLineCapStyle(gfx.kLineCapStyleRound); cline(50, 100, 100, 100, 9)
  log("lua round caps, C line: pixel past the end", black(102, 100), "before start", black(47, 100)); gfx.setLineCapStyle(gfx.kLineCapStyleButt)
  reset(); ccap(1); gfx.setColor(gfx.kColorBlack); gfx.setLineWidth(9); gfx.drawLine(50, 100, 100, 100)
  log("C round caps, lua line: pixel past the end", black(102, 100), "before start", black(47, 100)); ccap(0)
  reset(); gfx.setImageDrawMode(gfx.kDrawModeXOR); gfx.pushContext(); gfx.setImageDrawMode(gfx.kDrawModeCopy); gfx.popContext()
  log("lua mode after lua push/pop:", gfx.getImageDrawMode())
  reset(); gfx.setImageDrawMode(gfx.kDrawModeXOR); cpush(); log("lua mode inside C push:", gfx.getImageDrawMode()); cpop()
  reset(); cmode(gfx.kDrawModeXOR); gfx.pushContext(); log("C mode seen inside lua push:", cmode(0)); gfx.popContext(); log("C mode after lua pop:", cmode(0))
  reset(); local st = gfx.image.new(400, 240, gfx.kColorBlack); gfx.pushContext(st); gfx.setColor(gfx.kColorWhite); gfx.fillRect(0, 0, 200, 240); gfx.popContext()
  gfx.setStencilImage(st); cfill(0, 150, 400, 10); log("lua stencil, C fill: left", black(100, 155), "right", black(300, 155)); gfx.setStencilImage(nil)
  reset(); cstencil(1); gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 150, 400, 10); log("C stencil, lua fill: left", black(100, 155), "right", black(300, 155)); cstencil(0)
  reset(); cbg(gfx.kColorBlack); gfx.clear(); log("C background black, lua clear(): black", black(5, 200)); cbg(gfx.kColorWhite)
  reset(); gfx.setBackgroundColor(gfx.kColorBlack); log("lua background black, then C mode after:", cmode(0)); gfx.setBackgroundColor(gfx.kColorWhite)
  reset(); cpush(); cmode(gfx.kDrawModeXOR); cpop(); log("C mode after C push, set XOR, pop:", cmode(0))
  reset(); gfx.setImageDrawMode(gfx.kDrawModeXOR); cpush(); gfx.setImageDrawMode(gfx.kDrawModeCopy); cpop(); log("lua mode after C push, lua Copy, C pop:", gfx.getImageDrawMode())
  reset(); gfx.setFont(bold); gfx.pushContext(); gfx.setFont(normal); gfx.popContext(); log("lua font after lua push/pop is bold:", gfx.getFont() == bold); gfx.setFont(normal)
  reset(); gfx.setFontTracking(3); gfx.pushContext(); gfx.setFontTracking(0); gfx.popContext(); log("lua tracking after push/pop:", gfx.getFontTracking())
  reset(); coffset(10, 0); gfx.pushContext(); log("C offset then lua pushContext: lua offset", gfx.getDrawOffset()); gfx.popContext()
end
local done = false
function playdate.update()
  if not done then done = true; frame(); out:close() end
end
