-- Probe: does a hidden or removed opaque sprite still cut the dirty rects of sprites moving under it?
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local frame = 0
local function logger(name) return function(self, x, y, w, h) fh:write(frame .. " " .. name .. " " .. x .. "," .. y .. "," .. w .. "," .. h .. "\n") end end
local O = gfx.sprite.new(gfx.image.new(100, 100, gfx.kColorWhite)) O:setCenter(0, 0) O:moveTo(100, 50) O:setZIndex(10) O:add()
local A = gfx.sprite.new() A:setSize(40, 40) A:setCenter(0, 0) A:moveTo(340, 190) A.draw = logger("A") A:add()
function playdate.update()
  frame = frame + 1
  if frame == 3 then fh:write("-- O hidden\n") O:setVisible(false) end
  if frame == 5 then fh:write("-- A under hidden O\n") A:moveTo(120, 60) end
  if frame == 7 then fh:write("-- A away, O removed and shown\n") A:moveTo(340, 190) O:setVisible(true) O:remove() end
  if frame == 9 then fh:write("-- A under removed O\n") A:moveTo(120, 60) end
  if frame == 11 then fh:write("-- O added back\n") O:add() end
  if frame == 13 then fh:write("-- A moves within O\n") A:moveTo(125, 60) end
  if frame <= 14 then gfx.sprite.update() elseif frame == 15 then fh:close() end
end
