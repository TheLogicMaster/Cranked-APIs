-- Probe: querySpriteInfoAlongLine and querySpritesAlongLine over random segments, exact values
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local seed = 11
local function rnd(n) seed = (seed * 16807) % 2147483647 return seed % n end
local function box(name, x, y, w, h) local s = gfx.sprite.new() s.name = name s:setSize(w, h) s:setCenter(0, 0) s:moveTo(x, y) s:setCollideRect(0, 0, w, h) s:add() return s end
box("top", 0, 0, 400, 5) box("left", 0, 5, 5, 230) box("right", 395, 5, 5, 230) box("bottom", 0, 235, 400, 5)
for i = 1, 6 do box("b" .. i, 50 + rnd(270), 50 + rnd(100), 10 + rnd(30), 10 + rnd(90)) end
local p = gfx.sprite.new() p.name = "player" p:setSize(20, 20) p:setCollideRect(0, 0, 20, 20) p:moveTo(190.5, 123.25) p:add()
local af = playdate.geometry.affineTransform.new()
local line0 = playdate.geometry.lineSegment.new(0, 0, 500, 0)
local function f(v) return string.format("%.7g", v) end
for i = 1, 200 do
  af:reset()
  af:rotate(i * 7.3 + rnd(1000) / 100)
  af:translate(20 + rnd(3600) / 10, 20 + rnd(2000) / 10)
  local tls = af:transformedLineSegment(line0)
  local info, n = gfx.sprite.querySpriteInfoAlongLine(tls)
  local parts = {}
  for _, c in ipairs(info) do parts[#parts + 1] = c.sprite.name .. "(" .. f(c.ti1) .. "," .. f(c.ti2) .. " " .. f(c.entryPoint.x) .. "," .. f(c.entryPoint.y) .. " " .. f(c.exitPoint.x) .. "," .. f(c.exitPoint.y) .. ")" end
  local names = {} for _, s in ipairs(gfx.sprite.querySpritesAlongLine(tls)) do names[#names + 1] = s.name end
  fh:write(i .. " " .. f(tls.x1) .. "," .. f(tls.y1) .. "->" .. f(tls.x2) .. "," .. f(tls.y2) .. " n=" .. tostring(n) .. " " .. table.concat(parts, " ") .. " | " .. table.concat(names, ",") .. "\n")
end
fh:close()
function playdate.update() end
