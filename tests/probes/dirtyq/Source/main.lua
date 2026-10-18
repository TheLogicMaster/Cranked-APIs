-- Probe: which dirty rects merge (background callback calls per frame, with their rects)
import "CoreLibs/sprites"
local gfx = playdate.graphics
local out = playdate.file.open("out.txt", playdate.file.kFileWrite)
local log = {}
gfx.sprite.setBackgroundDrawingCallback(function(x, y, w, h) log[#log + 1] = string.format("(%d,%d,%d,%d)", x, y, w, h) end)
local s = gfx.sprite.new(); s:setSize(20, 20); s:moveTo(100, 100); s:add()
function s:draw() gfx.fillRect(0, 0, 20, 20) end
-- each case: a move of the sprite, so its old and new rects touch or are apart
local moves = { {120, 100}, {120, 120}, {140, 130}, {150, 150}, {130, 170}, {120, 100}, {100, 100} }
local frame = 0
function playdate.update()
  frame += 1
  log = {}
  gfx.sprite.update()
  out:write(string.format("frame %d %s\n", frame, table.concat(log, " ")))
  local m = moves[frame]
  if m then s:moveTo(m[1], m[2]) else out:close() playdate.stop() end
end
