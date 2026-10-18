-- Probe: the order of sprite:update() calls with z indices, sprites added before and during the update pass,
-- z changes, and removal during the pass
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local log = {}
local frame = 0
local function mk(name, z)
  local s = gfx.sprite.new() s.name = name s:setSize(4, 4) s:moveTo(10, 10) s:setZIndex(z)
  function s:update() log[#log + 1] = self.name if self.onUpdate then self:onUpdate() end end
  return s
end
local a, b, c, d = mk("a30", 30), mk("b0", 0), mk("c10", 10), mk("d30", 30)
a:add() b:add() c:add() d:add()
local spawned
a.onUpdate = function() if frame == 2 then spawned = mk("s0", 0) spawned:add() end if frame == 4 then local t = mk("t50", 50) t:add() end end
c.onUpdate = function() if frame == 5 then b:setZIndex(40) end if frame == 7 then d:remove() end if frame == 8 then d:add() end end
local e = mk("e5", 5)
function playdate.update()
  frame = frame + 1
  if frame == 3 then e:add() end
  log = {}
  gfx.sprite.update()
  fh:write("frame " .. frame .. ": " .. table.concat(log, " ") .. "\n")
  if frame == 10 then fh:close() end
end
