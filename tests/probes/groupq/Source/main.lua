-- Probe: how group masks decide overlaps and collisions (group 0, nonzero groups, collides-with masks)
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function mk(x, y, w, h) local s = gfx.sprite.new() s:setSize(w, h) s:setCenter(0, 0) s:moveTo(x, y) s:setCollideRect(0, 0, w, h) s:add() return s end
local cases = { { 0, nil, 0, nil }, { 2, nil, 0, nil }, { 0, nil, 2, nil }, { 2, nil, 2, nil }, { 1, 2, 2, nil }, { 1, 4, 2, nil }, { 1, 4, 2, 1 }, { 1, 0, 2, 0 }, { 0, 0, 0, 0 }, { 2, 2, 0, 0 }, { 0, 1, 0, nil }, { 0, 1, 0, 2 }, { 0, 0, 0, 3 } }
for i, c in ipairs(cases) do
  local a = mk(10, 10, 20, 20) local b = mk(25, 10, 20, 20)
  a:setGroupMask(c[1]) if c[2] then a:setCollidesWithGroupsMask(c[2]) end
  b:setGroupMask(c[3]) if c[4] then b:setCollidesWithGroupsMask(c[4]) end
  local all = #gfx.sprite.allOverlappingSprites()
  local ao, bo = #a:overlappingSprites(), #b:overlappingSprites()
  local _, _, _, n = a:checkCollisions(40, 10)
  local _, _, _, m = b:checkCollisions(0, 10)
  fh:write(string.format("case %d a(g=%d,cw=%s) b(g=%d,cw=%s): all=%d aOver=%d bOver=%d aHits=%d bHits=%d acw=%d\n", i, c[1], tostring(c[2]), c[3], tostring(c[4]), all, ao, bo, n, m, a:getCollidesWithGroupsMask()))
  a:remove() b:remove()
end
fh:close()
function playdate.update() end
