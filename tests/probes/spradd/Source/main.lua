-- Probe: sprites added or removed during sprite.update, and the update order
local gfx = playdate.graphics
local out = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function w(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end out:write(table.concat(t, "\t") .. "\n") end
local frame = 0
local function mk(name, z)
  local s = gfx.sprite.new()
  s:setSize(4, 4)
  if z then s:setZIndex(z) end
  s.update = function(self) w(frame, "update", name) if self.onUpdate then self:onUpdate() end end
  return s
end
local a, b, c = mk("a", 0), mk("b", 0), mk("c", 0)
a:add() b:add()
a.onUpdate = function(self) if frame == 1 then c:add() w(frame, "a added c") end end
local d = mk("d", -5)
b.onUpdate = function(self) if frame == 2 then d:add() w(frame, "b added d (z -5)") end if frame == 3 then a:remove() w(frame, "b removed a") end end
local e = mk("e", 10)
c.onUpdate = function(self) if frame == 4 then self:remove() e:add() w(frame, "c removed itself, added e") end end
local f1 = mk("f", 0)
function playdate.update()
  frame = frame + 1
  if frame == 5 then f1:add() w(frame, "f added before update") end
  if frame == 6 then b:setZIndex(20) w(frame, "b z 20") end
  w(frame, "begin")
  gfx.sprite.update()
  w(frame, "end", gfx.sprite.spriteCount())
  if frame == 8 then out:close() end
end
