-- Probe: differential sprite and collision operations. Each seed builds a scene of random sprites and applies
-- random operations, logging every result (positions, collision lists, queries) so the first divergence shows.
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local geo = playdate.geometry
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
DETAIL = true
local state = 1
local function rnd(n) state = (state * 1103515245 + 12345) & 0x7fffffff return state % n end
local function rf(a, b) return a + rnd(10000) / 10000 * (b - a) end
local function f(v) return string.format("%.3f", v) end
local shapes = {}
for k = 1, 4 do
  local w, h = 4 + rnd(14), 4 + rnd(14)
  local img = gfx.image.new(w, h, gfx.kColorClear)
  gfx.pushContext(img) gfx.setColor(gfx.kColorBlack)
  if k == 1 then gfx.fillRect(0, 0, w, h) elseif k == 2 then gfx.fillEllipseInRect(0, 0, w, h) elseif k == 3 then gfx.fillTriangle(0, 0, w - 1, 0, 0, h - 1) else gfx.drawRect(0, 0, w, h) end
  gfx.popContext()
  shapes[k] = img
end
local responses = { gfx.sprite.kCollisionTypeSlide, gfx.sprite.kCollisionTypeFreeze, gfx.sprite.kCollisionTypeOverlap, gfx.sprite.kCollisionTypeBounce }
local function names(list) local t = {} for _, s in ipairs(list) do t[#t + 1] = s.name or "?" end table.sort(t) return table.concat(t, ",") end
for seed = 13, 72 do
  state = seed * 7919
  gfx.sprite.removeAll()
  local sprites = {}
  for i = 1, 6 + rnd(6) do
    local s = gfx.sprite.new(shapes[1 + rnd(4)])
    s.name = "s" .. i
    if rnd(3) == 0 then s:setCenter(rnd(3) / 2, rnd(3) / 2) end
    local w, h = s:getSize()
    if rnd(4) == 0 then s:setCollideRect(rnd(3), rnd(3), math.max(1, w - rnd(4)), math.max(1, h - rnd(4))) else s:setCollideRect(0, 0, w, h) end
    s.collisionResponse = responses[1 + rnd(4)]
    if rnd(5) == 0 then s:setGroups({ 1 + rnd(3) }) s:setCollidesWithGroups({ 1 + rnd(3) }) end
    s:moveTo(rf(20, 180), rf(20, 140))
    s:setZIndex(rnd(4))
    s:add()
    sprites[i] = s
  end
  if seed % 5 == 0 then
    local it = gfx.imagetable.new(2) it:setImage(1, shapes[1]) it:setImage(2, gfx.image.new(shapes[1]:getSize()))
    local tm = gfx.tilemap.new() tm:setImageTable(it) tm:setSize(6, 4)
    for x = 1, 6 do for y = 1, 4 do tm:setTileAtPosition(x, y, (x + y + seed) % 3 == 0 and 1 or 2) end end
    local walls = gfx.sprite.addWallSprites(tm, { 2 }, rnd(20), rnd(20))
    for k, w in ipairs(walls) do w.name = "w" .. k end
    fh:write(seed .. " walls " .. #walls .. "\n")
  end
  for step = 1, 60 do
    local s = sprites[1 + rnd(#sprites)]
    local op = rnd(9)
    local line
    if op <= 2 then
      local ax, ay, cols, n = s:moveWithCollisions(s.x + rf(-25, 25), s.y + rf(-25, 25))
      local parts = {}
      for k = 1, n do local c = cols[k] parts[#parts + 1] = c.other.name .. ":" .. c.type .. ":" .. f(c.touch.x) .. "," .. f(c.touch.y) .. ":" .. f(c.normal.x) .. "," .. f(c.normal.y) .. ":" .. f(c.ti) .. ":" .. tostring(c.overlaps) end
      line = "move " .. s.name .. " " .. f(ax) .. "," .. f(ay) .. " " .. table.concat(parts, ";")
    elseif op == 3 then
      local _, _, cols, n = s:checkCollisions(s.x + rf(-10, 10), s.y + rf(-10, 10))
      line = "check " .. s.name .. " n=" .. n
    elseif op == 4 then
      line = "overlap " .. s.name .. " " .. names(s:overlappingSprites())
      if DETAIL then
        local function wr(o) local x, y, w, h = o:getCollideBounds() local bx, by = o:getBounds() return o.name .. "[" .. f(bx + x) .. "," .. f(by + y) .. "," .. f(w) .. "," .. f(h) .. " g=" .. o:getGroupMask() .. " cw=" .. o:getCollidesWithGroupsMask() .. " en=" .. tostring(o:collisionsEnabled()) .. " vis=" .. tostring(o:isVisible()) .. "]" end
        local parts = { wr(s) }
        for _, o in ipairs(gfx.sprite.getAllSprites()) do if o ~= s then parts[#parts + 1] = wr(o) end end
        line = line .. " | " .. table.concat(parts, " ")
      end
    elseif op == 5 then
      local x, y = rf(0, 200), rf(0, 160)
      line = "atpoint " .. names(gfx.sprite.querySpritesAtPoint(x, y)) .. " inrect " .. names(gfx.sprite.querySpritesInRect(x - 20, y - 20, 40, 40))
    elseif op == 6 then
      local x1, y1, x2, y2 = rf(0, 200), rf(0, 160), rf(0, 200), rf(0, 160)
      local info = gfx.sprite.querySpriteInfoAlongLine(x1, y1, x2, y2)
      local parts = {}
      for _, i in ipairs(info) do parts[#parts + 1] = i.sprite.name .. ":" .. f(i.ti1) .. "-" .. f(i.ti2) .. ":" .. f(i.entryPoint.x) .. "," .. f(i.entryPoint.y) end
      line = "line " .. table.concat(parts, ";")
    elseif op == 7 then
      local o = sprites[1 + rnd(#sprites)]
      line = "alpha " .. s.name .. "-" .. o.name .. " " .. tostring(s:alphaCollision(o))
    elseif op == 8 and rnd(2) == 0 then
      local w, h = s:getSize()
      s:setCollideRect(rnd(4), rnd(4), math.max(1, w - rnd(6)), math.max(1, h - rnd(6)))
      local x, y, cw, ch = s:getCollideBounds()
      line = "rect " .. s.name .. " " .. f(x) .. "," .. f(y) .. "," .. f(cw) .. "," .. f(ch)
    else
      if rnd(2) == 0 then s:setCollisionsEnabled(not s:collisionsEnabled()) else s:moveTo(rf(20, 180), rf(20, 140)) end
      line = "toggle " .. s.name .. " " .. tostring(s:collisionsEnabled()) .. " " .. f(s.x) .. "," .. f(s.y)
    end
    fh:write(seed .. " " .. step .. " " .. line .. "\n")
  end
  fh:write(seed .. " all " .. #gfx.sprite.allOverlappingSprites() .. "\n")
  fh:flush()
end
fh:close()
function playdate.update() end
