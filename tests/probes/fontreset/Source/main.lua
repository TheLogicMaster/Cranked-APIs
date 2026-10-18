-- Probe: which graphics state set in the main chunk survives into the first updates
import "CoreLibs/graphics"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local custom = gfx.font.new("font-Bitmore-Medieval-Bold")
local custom2 = gfx.font.new("font-Bitmore-Medieval-Bold", gfx.font.kVariantBold)
gfx.setFont(custom)
gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
gfx.setColor(gfx.kColorWhite)
gfx.setLineWidth(5)
gfx.setDrawOffset(3, 4)
gfx.setBackgroundColor(gfx.kColorBlack)
local function state(tag)
  local ox, oy = gfx.getDrawOffset()
  fh:write(string.format("%s font=%s mode=%s color=%s lw=%s off=%s,%s bg=%s\n", tag, gfx.getFont() == custom and "custom" or (gfx.getFont() == gfx.getSystemFont() and "system" or "other"), tostring(gfx.getImageDrawMode()), tostring(gfx.getColor()), tostring(gfx.getLineWidth()), tostring(ox), tostring(oy), tostring(gfx.getBackgroundColor())))
end
state("main")
fh:write("custom2 " .. tostring(custom2 ~= nil) .. "\n")
local n = 0
function playdate.update()
  n += 1
  state("update" .. n)
  if n == 1 then gfx.setFont(custom) end
  if n == 3 then fh:close() end
end
