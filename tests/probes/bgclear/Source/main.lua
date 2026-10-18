-- Probe: is the dirty area cleared before the background callback? The callback draws a mostly transparent
-- image (one black pixel per 4) at a moving x; a sprite elsewhere keeps the frame dirty. Also with
-- setBackgroundColor(kColorClear) and (kColorBlack).
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local out, frame = {}, 0
local img = gfx.image.new(40, 4)  -- clear
gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); for x = 0, 39, 4 do gfx.drawPixel(x, 1) end; gfx.popContext()
gfx.sprite.setBackgroundDrawingCallback(function(x, y, w, h) img:draw(frame % 4, 0) end)
local s = gfx.sprite.new(gfx.image.new(4, 4, gfx.kColorBlack)); s:moveTo(200, 120); s:add()
local function row() local d = gfx.getWorkingImage(); local t = {}; for x = 0, 19 do t[#t + 1] = d:sample(x, 1) == gfx.kColorBlack and "1" or "0" end; return table.concat(t) end
function playdate.update()
  frame = frame + 1
  if frame == 6 then gfx.setBackgroundColor(gfx.kColorClear) end
  if frame == 10 then gfx.setBackgroundColor(gfx.kColorBlack) end
  gfx.sprite.redrawBackground()
  gfx.sprite.update()
  out[#out + 1] = frame .. " bg=" .. tostring(gfx.getBackgroundColor()) .. "|" .. row()
  if frame == 13 then
    local fh = playdate.file.open("bgclear.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
    if playdate.simulator then playdate.simulator.exit() end
    playdate.stop()
  end
end
