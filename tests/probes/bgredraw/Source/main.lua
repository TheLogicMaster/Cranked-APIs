-- Probe: a background drawing callback that calls sprite.redrawBackground() and changes the draw offset and
-- clip rect inside itself, with a sprite on top. Counts callback calls and dumps frames.
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local img = gfx.image.new(100, 60, gfx.kColorWhite)
gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.drawRect(0, 0, 100, 60); gfx.fillRect(10, 10, 20, 20); gfx.popContext()
local calls, frame = 0, 0
local out = {}
bgcb = function(x, y, w, h)
  calls = calls + 1
  rects = (rects or '') .. string.format('[%d %d %d %d]', x, y, w, h)
  gfx.setClipRect(x, y, w, h)
  gfx.setDrawOffset(-10, -5)
  gfx.clear()
  gfx.sprite.redrawBackground()
  img:draw(-8, -8)
  gfx.clearClipRect()
end
gfx.sprite.setBackgroundDrawingCallback(bgcb)
local s = gfx.sprite.new(gfx.image.new(8, 8, gfx.kColorBlack)); s:moveTo(150, 100); s:add()
local function dump()
  local d = gfx.getDisplayImage(); local t = {}
  for y = 0, 29 do for x = 0, 39 do t[#t + 1] = d:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
  return table.concat(t)
end
function playdate.update()
  frame = frame + 1
  if frame == 3 then s:moveBy(5, 0) end
  if frame == 4 then gfx.sprite.setBackgroundDrawingCallback(bgcb) end
  if frame == 5 then local bs = gfx.sprite.getAllSprites()[1]; if bs then bs:add() end end
  gfx.sprite.update()
  gfx.setDrawOffset(-10, -5)
  gfx.drawLine(0, 0, 200, 150)
  if frame >= 2 and frame <= 7 then out[#out + 1] = string.format("f%d calls=%d %s|%s", frame, calls, rects or "", dump()); rects = "" end
  if frame == 8 then
    local fh = playdate.file.open("bgredraw.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
    if playdate.simulator then playdate.simulator.exit() end
  end
end
