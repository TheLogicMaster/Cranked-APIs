-- Probe: when a sprite's image draw mode change reaches the screen (a hit flash)
import "CoreLibs/sprites"
local gfx = playdate.graphics
local out = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function w(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end out:write(table.concat(t, "\t") .. "\n") end
local it = gfx.imagetable.new("assets/marks")
local function count(x0, y0)
  local img = gfx.getDisplayImage() local n = 0
  for y = y0 - 12, y0 + 11 do for x = x0 - 12, x0 + 11 do if img:sample(x, y) == gfx.kColorBlack then n = n + 1 end end end
  return n
end
gfx.setBackgroundColor(gfx.kColorWhite)
local A = gfx.sprite.new(it[1]) A:moveTo(50, 50) A:add()
local B = gfx.sprite.new(it[1]) B:moveTo(100, 50) B:add()
local C = gfx.sprite.new(it[1]) C:moveTo(150, 50) C:add()
C.update = function(self) if frame == 30 then self:setImageDrawMode(gfx.kDrawModeFillWhite) end if frame == 36 then self:setImageDrawMode(gfx.kDrawModeCopy) end end
local D = gfx.sprite.new() D:setSize(24, 24) D:moveTo(200, 50) D:add()
D.draw = function(self, x, y, w2, h2) it[1]:draw(0, 0) end
frame = 0
function playdate.update()
  frame = frame + 1
  local pre = { count(50, 50), count(100, 50), count(150, 50), count(200, 50) }
  if frame == 5 then A:setImageDrawMode(gfx.kDrawModeFillWhite) end
  if frame == 10 then A:setImageDrawMode(gfx.kDrawModeCopy) end
  if frame == 15 then A:setImageDrawMode(gfx.kDrawModeInverted) A:setImageDrawMode(gfx.kDrawModeCopy) end
  if frame == 20 then A:setImageDrawMode(gfx.kDrawModeFillWhite) A:markDirty() end
  if frame == 25 then A:setImageDrawMode(gfx.kDrawModeCopy) B:setImageDrawMode(gfx.kDrawModeFillWhite) end
  if frame == 26 then B:moveTo(101, 50) end
  if frame == 40 then D:setImageDrawMode(gfx.kDrawModeFillWhite) end
  if frame == 44 then D:markDirty() end
  if frame == 48 then A:setImageDrawMode(gfx.kDrawModeFillWhite) A:setImage(it[2]) end
  if frame == 52 then A:setImageDrawMode(gfx.kDrawModeInverted) A:setImageFlip(gfx.kImageFlippedX) end
  gfx.sprite.update()
  w(frame, "pre", table.concat(pre, " "), "post", count(50, 50), count(100, 50), count(150, 50), count(200, 50))
  if frame == 56 then out:close() end
end
