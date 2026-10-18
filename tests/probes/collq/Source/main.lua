-- Probe: moveWithCollisions and checkCollisions results for every response type, groups and odd cases
import "CoreLibs/sprites"
local gfx = playdate.graphics
playdate.file.delete("out.txt")
local fh = { write = function(_, t) local f = playdate.file.open("out.txt", playdate.file.kFileAppend) f:write(t) f:close() end, close = function() end }
local function f(v) if type(v) == "number" then return string.format("%.3f", v) end return tostring(v) end
local function pt(p) return p and (f(p.x) .. "," .. f(p.y)) or "nil" end
local function rc(r) return r and (f(r.x) .. "," .. f(r.y) .. "," .. f(r.width) .. "," .. f(r.height)) or "nil" end
local function dump(label, ax, ay, cols, n)
  fh:write(label .. " -> " .. f(ax) .. "," .. f(ay) .. " n=" .. tostring(n) .. "\n")
  for i, c in ipairs(cols or {}) do
    fh:write(string.format("  %d other=%s type=%s overlaps=%s ti=%s move=%s normal=%s touch=%s sr=%s or=%s bounce=%s slide=%s\n", i, tostring(c.other.name), tostring(c.type), tostring(c.overlaps), f(c.ti), pt(c.move), pt(c.normal), pt(c.touch), rc(c.spriteRect), rc(c.otherRect), pt(c.bounce), pt(c.slide)))
  end
end
local function mk(name, x, y, w, h, resp)
  local s = gfx.sprite.new() s.name = name s:setSize(w, h) s:setCenter(0, 0) s:moveTo(x, y) s:setCollideRect(0, 0, w, h) s:add()
  if resp then s.collisionResponse = resp end
  return s
end
local wall = mk("wall", 50, 0, 10, 100)
local floor = mk("floor", 0, 60, 200, 10)
local box = mk("box", 80, 30, 10, 10)
for _, resp in ipairs({ gfx.sprite.kCollisionTypeSlide, gfx.sprite.kCollisionTypeFreeze, gfx.sprite.kCollisionTypeOverlap, gfx.sprite.kCollisionTypeBounce }) do
  local p = mk("p", 10, 20, 10, 10, resp)
  local ax, ay, cols, n = p:moveWithCollisions(70, 55)
  dump("resp " .. resp .. " diag", ax, ay, cols, n)
  p:moveTo(10, 20)
  ax, ay, cols, n = p:moveWithCollisions(100, 20)
  dump("resp " .. resp .. " right", ax, ay, cols, n)
  p:remove()
end
local p = mk("p", 10, 20, 10, 10, function(self, other) if other.name == "wall" then return "overlap" end return gfx.sprite.kCollisionTypeSlide end)
local ax, ay, cols, n = p:moveWithCollisions(120, 52)
dump("fn resp", ax, ay, cols, n)
p:moveTo(10, 20)
ax, ay, cols, n = p:checkCollisions(120, 52)
dump("check", ax, ay, cols, n)
fh:write("after check pos " .. f(p.x) .. "," .. f(p.y) .. "\n")
p:moveTo(10, 20)
p:setGroups({ 1 }) wall:setGroups({ 2 }) p:setCollidesWithGroups({ 3 })
ax, ay, cols, n = p:moveWithCollisions(120, 20)
dump("groups miss", ax, ay, cols, n)
p:setCollidesWithGroups({ 2 }) p:moveTo(10, 20)
ax, ay, cols, n = p:moveWithCollisions(120, 20)
dump("groups hit", ax, ay, cols, n)
p:setCollidesWithGroupsMask(0xFFFFFFFF) p:moveTo(48, 20)
ax, ay, cols, n = p:moveWithCollisions(49, 20)
dump("start overlapping", ax, ay, cols, n)
p:moveTo(10.5, 20.25)
ax, ay, cols, n = p:moveWithCollisions(60.75, 20.25)
dump("fractional", ax, ay, cols, n)
p:setCollisionsEnabled(false) p:moveTo(10, 20)
ax, ay, cols, n = p:moveWithCollisions(120, 20)
dump("disabled", ax, ay, cols, n)
p:setCollisionsEnabled(true) p:remove()
fh:write("overlapping " .. #box:overlappingSprites() .. " all " .. #gfx.sprite.allOverlappingSprites() .. "\n")
local q = gfx.sprite.querySpritesAlongLine(0, 25, 200, 25) local names = {} for _, s in ipairs(q) do names[#names + 1] = s.name end fh:write("along " .. table.concat(names, ",") .. "\n")
local info = gfx.sprite.querySpriteInfoAlongLine(0, 25, 200, 25)
for _, i in ipairs(info) do fh:write(string.format("  %s ti1=%s ti2=%s entry=%s exit=%s\n", i.sprite.name, f(i.ti1), f(i.ti2), pt(i.entryPoint), pt(i.exitPoint))) end
fh:close()
function playdate.update() end
