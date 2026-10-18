-- Probe: tilemap sprites hiding sprites below (whole dirty rects, and new bounds cut to the clear tiles)
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local frame = 0
local function logger(name) return function(self, x, y, w, h) fh:write(frame .. " " .. name .. " " .. x .. "," .. y .. "," .. w .. "," .. h .. "\n") end end
local it = gfx.imagetable.new(2)
it:setImage(1, gfx.image.new(20, 20, gfx.kColorWhite))
it:setImage(2, gfx.image.new(20, 20))
local tm = gfx.tilemap.new() tm:setImageTable(it) tm:setSize(5, 4)
-- row-major, 1 = opaque, 2 = masked, 0 = empty
tm:setTiles({ 1, 1, 1, 1, 1,  1, 1, 2, 1, 1,  1, 0, 1, 1, 1,  1, 1, 1, 1, 1 }, 5)
local T = gfx.sprite.new() T:setTilemap(tm) T:setCenter(0, 0) T:moveTo(100, 50) T:setZIndex(10) T:add()
local A = gfx.sprite.new() A:setSize(10, 10) A:setCenter(0, 0) A:moveTo(340, 190) A.draw = logger("A") A:add()
local bg = gfx.sprite.new() bg:setSize(400, 240) bg:setCenter(0, 0) bg:moveTo(0, 0) bg:setZIndex(-100) bg.draw = logger("bg") bg:add()
local moves = { [3] = { 105, 55, "under opaque tiles" }, [5] = { 142, 72, "under the masked tile" }, [7] = { 115, 85, "across the empty tile" },
  [9] = { 95, 55, "sticking out left" }, [11] = { 125, 75, "across opaque and masked" } }
function playdate.update()
  frame = frame + 1
  local m = moves[frame]
  if m then fh:write("-- " .. m[3] .. "\n") A:moveTo(m[1], m[2]) elseif frame > 2 and frame % 2 == 0 then A:moveTo(340, 190) end
  if frame == 13 then fh:write("-- dirty rect over opaque tiles\n") gfx.sprite.addDirtyRect(102, 52, 10, 10) end
  if frame == 14 then fh:write("-- dirty rect over the empty tile\n") gfx.sprite.addDirtyRect(122, 92, 10, 10) end
  if frame <= 14 then gfx.sprite.update() elseif frame == 15 then fh:close() end
end
