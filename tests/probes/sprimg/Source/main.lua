-- Probe: a sprite whose image changes between frames of the same imagetable
import "CoreLibs/sprites"
local gfx = playdate.graphics
local out = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function w(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end out:write(table.concat(t, "\t") .. "\n") end
local it = gfx.imagetable.new("assets/marks")
local s = gfx.sprite.new(it[1])
s:moveTo(50, 50) s:add()
local s2 = gfx.sprite.new(it[1])
s2:moveTo(100, 50) s2:add()
local frame = 0
local s3 = gfx.sprite.new(it[1])
s3:moveTo(150, 50) s3:add()
s3.n = 0
s3.update = function(self) self.n += 1 if self.n % 3 == 0 then self:setImage(it[(self.n // 3) % 3 + 1]) end end
local s4 = gfx.sprite.new(it[1])
s4:moveTo(200, 50) s4:add()
s4.n = 0
s4.update = function(self) self.n += 1 if self.n % 2 == 0 then self:setImage(it[(self.n // 2) % 3 + 1]) self:moveTo(200, 50) end end
local function count(x0, y0)
  local img = gfx.getDisplayImage() local n = 0
  for y = y0 - 12, y0 + 11 do for x = x0 - 12, x0 + 11 do if img:sample(x, y) == gfx.kColorBlack then n = n + 1 end end end
  return n
end
function playdate.update()
  frame = frame + 1
  w(frame, count(50, 50), count(100, 50), count(150, 50), count(200, 50))
  if frame % 3 == 0 then s:setImage(it[(frame // 3) % 3 + 1]) end
  if frame % 4 == 0 then s2:setImage(it[(frame // 4) % 3 + 1]) s2:moveTo(100, 50) end
  if frame == 7 then s:setImage(it[2]) s:setImage(it[2]) end
  gfx.sprite.update()
  if frame == 9 then s2:setImageDrawMode(gfx.kDrawModeFillWhite) end
  if frame == 11 then s2:setImageDrawMode(gfx.kDrawModeCopy) end
  if frame == 13 then s3:setImageDrawMode(gfx.kDrawModeInverted) end
  if frame == 15 then s3:setImageFlip(gfx.kImageFlippedX) end
  if frame == 17 then s3:setImageDrawMode(gfx.kDrawModeFillBlack) end
  if frame == 26 then out:close() end
end
