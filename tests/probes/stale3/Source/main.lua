-- Probe: dirty rects of images with transparent margins (trimmed by pdc), plain and flipped, and of text.
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local log, f, frameRects = {}, 0, {}
gfx.sprite.setBackgroundDrawingCallback(function(x, y, w, h) frameRects[#frameRects + 1] = string.format("%d,%d,%d,%d", x, y, w, h) end)
local s = gfx.sprite.new(); s:setSize(8, 8); s:moveTo(380, 220); s:add()
local m = gfx.image.new("images/margins")
local d = gfx.image.new("images/dot")
local runtime = gfx.image.new(30, 24)
gfx.pushContext(runtime); gfx.fillRect(3, 4, 22, 14); gfx.popContext()
local font = gfx.getSystemFont()
local cases = {
  { "margins", function() m:draw(100, 100) end },
  { "margins_flipX", function() m:draw(100, 100, gfx.kImageFlippedX) end },
  { "margins_flipY", function() m:draw(100, 100, gfx.kImageFlippedY) end },
  { "dot", function() d:draw(100, 100) end },
  { "runtime_image", function() runtime:draw(100, 100) end },
  { "margins_scaled2", function() m:drawScaled(100, 100, 2) end },
  { "margins_src", function() m:draw(100, 100, gfx.kImageUnflipped, 0, 0, 10, 10) end },
  { "text_A", function() gfx.drawText("A", 100, 100) end },
  { "text_g", function() gfx.drawText("g", 100, 100) end },
  { "text_dot", function() gfx.drawText(".", 100, 100) end },
  { "text_quote", function() gfx.drawText("'", 100, 100) end },
  { "text_Ag", function() gfx.drawText("Ag", 100, 100) end },
  { "text_space", function() gfx.drawText(" ", 100, 100) end },
  { "text_two_lines", function() gfx.drawText("A\nB", 100, 100) end },
  { "font_drawText", function() font:drawText("A", 100, 100) end },
  { "glyph_image", function() font:getGlyph("A"):draw(100, 100) end },
}
local pending, idx
function playdate.update()
  frameRects = {}
  gfx.sprite.update()
  if pending then log[#log + 1] = pending .. "\t" .. table.concat(frameRects, " "); pending = nil end
  if f % 3 == 0 then
    idx = f // 3 + 1
    local c = cases[idx]
    if c then c[2](); pending = c[1]
    else
      local fh = playdate.file.open("rects.txt", playdate.file.kFileWrite); fh:write(table.concat(log, "\n") .. "\n"); fh:close()
      if playdate.simulator then playdate.simulator.exit() end; playdate.stop()
    end
  end
  f = f + 1
end
