-- Probe: the order of gfx.sprite.getAllSprites() with z indices, before and after an update, after z changes,
-- removals and re-adds
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function order(label) local t = {} for _, s in ipairs(gfx.sprite.getAllSprites()) do t[#t + 1] = s.name .. "(" .. s:getZIndex() .. ")" end fh:write(label .. ": " .. table.concat(t, " ") .. "\n") end
local zs = { 3, 1, 2, 0, 1, 3, 0, 2 }
local sp = {}
for i, z in ipairs(zs) do local s = gfx.sprite.new() s.name = "s" .. i s:setSize(4, 4) s:moveTo(10, 10) s:setZIndex(z) s:add() sp[i] = s end
order("added")
local frame = 0
function playdate.update()
  frame = frame + 1
  if frame == 1 then order("before update 1") gfx.sprite.update() order("after update 1") end
  if frame == 2 then sp[2]:setZIndex(5) order("z change") gfx.sprite.update() order("after update 2") end
  if frame == 3 then sp[4]:remove() sp[4]:add() order("readd") sp[7]:setZIndex(3) order("z equal") gfx.sprite.update() order("after update 3") end
  if frame == 4 then local n = gfx.sprite.new() n.name = "n" n:setZIndex(-2) n:add() order("new low z") fh:close() end
end
