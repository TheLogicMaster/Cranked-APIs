-- Probe: tilemap tiles changed during a sprite update, with and without another sprite forcing partial redraws
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local n = 0
local tt = gfx.imagetable.new(2)
tt:setImage(1, gfx.image.new(8, 8, gfx.kColorWhite))
tt:setImage(2, gfx.image.new(8, 8, gfx.kColorBlack))
local function mk(y)
  local tm = gfx.tilemap.new() tm:setImageTable(tt) tm:setSize(10, 1)
  for i = 1, 10 do tm:setTileAtPosition(i, 1, 1) end
  local s = gfx.sprite.new() s:setTilemap(tm) s:setCenter(0, 0) s:moveTo(0, y) s:add()
  return s, tm
end
local A, tmA = mk(10)
local B, tmB = mk(30)
local mover = gfx.sprite.new(gfx.image.new(6, 40, gfx.kColorBlack)) mover:setCenter(0, 0) mover:add() mover:setZIndex(5)
function mover:update()
  self:moveTo(n % 2 == 0 and 2 or 10, 6)
  for i = 1, 10 do tmA:setTileAtPosition(i, 1, (n >> (i - 1)) & 1 == 1 and 2 or 1) end
end
function B:update()
  for i = 1, 10 do tmB:setTileAtPosition(i, 1, (n >> (i - 1)) & 1 == 1 and 2 or 1) end
end
function playdate.update()
  n += 1
  local disp = gfx.getDisplayImage()
  local function val(y)
    local v = 0
    for b = 2, 9 do if disp:sample(b * 8 + 4, y + 4) == gfx.kColorBlack then v = v | (1 << b) end end
    return v
  end
  if n > 2 and n < 24 then fh:write(n .. " A=" .. val(10) .. " B=" .. val(30) .. "\n") end
  gfx.sprite.update()
  if n == 24 then fh:close() end
end
