-- Probe: collision info points (touch, slide, bounce) and rects for sprites with centers other than 0,0 and
-- offset collide rects, for every response type
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function f(v) return string.format("%.4f", v) end
local function pt(p) return p and (f(p.x) .. "," .. f(p.y)) or "nil" end
local function rc(r) return r and (f(r.x) .. "," .. f(r.y) .. "," .. f(r.width) .. "," .. f(r.height)) or "nil" end
local wall = gfx.sprite.new() wall:setSize(40, 10) wall:setCenter(0, 0) wall:moveTo(50, 60) wall:setCollideRect(0, 0, 40, 10) wall:add()
for _, resp in ipairs({ gfx.sprite.kCollisionTypeSlide, gfx.sprite.kCollisionTypeFreeze, gfx.sprite.kCollisionTypeOverlap, gfx.sprite.kCollisionTypeBounce }) do
  for _, cfg in ipairs({ { 0.5, 0.5, 0, 0, 15, 15 }, { 0.5, 0.5, 2, 2, 11, 10 }, { 0.25, 0.75, 3, 1, 6, 8 }, { 1, 1, 0, 0, 12, 9 }, { 0, 0, 4, 4, 5, 5 } }) do
    local s = gfx.sprite.new() s:setSize(15, 15) s:setCenter(cfg[1], cfg[2]) s:setCollideRect(cfg[3], cfg[4], cfg[5], cfg[6])
    s.collisionResponse = resp
    s:moveTo(62.3, 40.6) s:add()
    local ax, ay, cols, n = s:moveWithCollisions(66.7, 70.2)
    local parts = {}
    for i = 1, n do local c = cols[i]
      parts[#parts + 1] = string.format("type=%d move=%s normal=%s touch=%s slide=%s bounce=%s spriteRect=%s otherRect=%s ti=%s", c.type, pt(c.move), pt(c.normal), pt(c.touch), pt(c.slide), pt(c.bounce), rc(c.spriteRect), rc(c.otherRect), f(c.ti))
    end
    fh:write(string.format("resp=%d c=%s,%s cr=%d,%d,%d,%d actual=%s,%s n=%d %s\n", resp, cfg[1], cfg[2], cfg[3], cfg[4], cfg[5], cfg[6], f(ax), f(ay), n, table.concat(parts, " ; ")))
    local _, _, cc, cn = s:checkCollisions(s.x + 3.3, s.y + 2.2)
    fh:write("  check n=" .. cn .. (cn > 0 and (" touch=" .. pt(cc[1].touch) .. " move=" .. pt(cc[1].move)) or "") .. "\n")
    s:remove()
  end
end
fh:close()
function playdate.update() end
