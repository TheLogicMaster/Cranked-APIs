-- Probe: the italic system font's replacement glyph U+FFFD measured through font methods
import "CoreLibs/graphics"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local R = "\u{FFFD}"
for _, v in ipairs({gfx.font.kVariantNormal, gfx.font.kVariantBold, gfx.font.kVariantItalic}) do
  local f = gfx.getFont(v)
  local g = f:getGlyph(R)
  local gw, gh = -1, -1
  if g then gw, gh = g:getSize() end
  local line = {"v" .. v, "track=" .. f:getTracking(), "h=" .. f:getHeight(), "glyph=" .. gw .. "x" .. gh}
  for _, t in ipairs({R, R .. R, "a" .. R, R .. "a", "a", "aa", " " .. R, "\u{2603}"}) do
    line[#line + 1] = "[" .. t:gsub(R, "R") .. "]=" .. f:getTextWidth(t)
  end
  local img = gfx.image.new(60, 30, gfx.kColorWhite)
  gfx.pushContext(img) local w, h = f:drawText(R, 0, 0) gfx.popContext()
  local ink = 0
  for y = 0, 29 do for x = 0, 59 do if img:sample(x, y) == gfx.kColorBlack then ink = ink + 1 end end end
  line[#line + 1] = "fdraw=" .. tostring(w) .. "x" .. tostring(h) .. " ink=" .. ink
  fh:write(table.concat(line, " ") .. "\n")
end
fh:close()
function playdate.update() end
