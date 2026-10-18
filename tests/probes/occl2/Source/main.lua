-- Probe: whether a moved sprite's new dirty rect is cut by an opaque sprite above it (callbacks log their rects)
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local frame = 0
local function logger(name) return function(self, x, y, w, h) fh:write(frame .. " " .. name .. " " .. x .. "," .. y .. "," .. w .. "," .. h .. "\n") end end
local O = gfx.sprite.new(gfx.image.new(100, 100, gfx.kColorWhite)) O:setCenter(0, 0) O:moveTo(100, 50) O:setZIndex(10) O:add()
local A = gfx.sprite.new() A:setSize(40, 40) A:setCenter(0, 0) A:moveTo(340, 190) A.draw = logger("A") A:add()
local B = gfx.sprite.new() B:setSize(30, 30) B:setCenter(0, 0) B:moveTo(60, 60) B.draw = logger("B") B:add()
local bg = gfx.sprite.new() bg:setSize(400, 240) bg:setCenter(0, 0) bg:moveTo(0, 0) bg:setZIndex(-100) bg.draw = logger("bg") bg:add()
local far = { 340, 190 }
local moves = { [3] = { 10, 60, "left of O" }, [5] = { 120, 60, "inside O" }, [7] = { 180, 60, "right edge" }, [9] = { 120, 130, "bottom edge" },
  [11] = { 120, 20, "top edge" }, [13] = { 80, 60, "left edge" }, [15] = { 10, 160, "left, below O" }, [17] = { 110, 60, "inside, then O moves" } }
function playdate.update()
  frame = frame + 1
  local m = moves[frame]
  if m then fh:write("-- " .. m[3] .. "\n") A:moveTo(m[1], m[2]) elseif frame > 2 and frame % 2 == 0 then A:moveTo(far[1], far[2]) end
  if frame == 17 then O:moveTo(105, 50) end
  if frame <= 18 then gfx.sprite.update() elseif frame == 19 then fh:close() end
end
