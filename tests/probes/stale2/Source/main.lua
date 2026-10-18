-- Probe: which rects does sprite.update redraw after drawing straight to the frame?
-- The background callback logs its rects; each case draws something directly in one frame.
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local log, f, frameRects = {}, 0, {}
gfx.sprite.setBackgroundDrawingCallback(function(x, y, w, h) frameRects[#frameRects + 1] = string.format("%d,%d,%d,%d", x, y, w, h) end)
local s = gfx.sprite.new(); s:setSize(8, 8); s:moveTo(380, 220); s:add()
local cases = {
  [3] = { "text", function() gfx.drawText("Hello", 100, 100) end },
  [6] = { "fillRect", function() gfx.fillRect(50, 60, 30, 20) end },
  [9] = { "pixel", function() gfx.drawPixel(200, 150) end },
  [12] = { "two_rects", function() gfx.fillRect(10, 10, 5, 5); gfx.fillRect(300, 200, 5, 5) end },
  [15] = { "line", function() gfx.drawLine(20, 30, 120, 90) end },
  [18] = { "image", function() local i = gfx.image.new(16, 12, gfx.kColorBlack); i:draw(150, 40) end },
  [21] = { "offset_text", function() gfx.setDrawOffset(7, 9); gfx.drawText("Hi", 100, 100); gfx.setDrawOffset(0, 0) end },
  [24] = { "clipped", function() gfx.setClipRect(0, 0, 40, 40); gfx.fillRect(20, 20, 100, 100); gfx.clearClipRect() end },
  [27] = { "image_ctx", function() local i = gfx.image.new(20, 20); gfx.pushContext(i); gfx.fillRect(0, 0, 20, 20); gfx.popContext() end },
  [30] = { "clear", function() gfx.clear() end },
  [33] = { "offscreen", function() gfx.fillRect(-50, -50, 20, 20) end },
  [36] = { "nothing", function() end },
}
local pending
function playdate.update()
  frameRects = {}
  gfx.sprite.update()
  if pending then log[#log + 1] = pending .. "\t" .. table.concat(frameRects, " "); pending = nil end
  local c = cases[f]
  if c then c[2](); pending = c[1] end
  if f == 40 then
    local fh = playdate.file.open("rects.txt", playdate.file.kFileWrite); fh:write(table.concat(log, "\n") .. "\n"); fh:close()
    if playdate.simulator then playdate.simulator.exit() end; playdate.stop()
  end
  f = f + 1
end
