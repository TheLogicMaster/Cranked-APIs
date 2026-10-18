-- Probe: sprite:alphaCollision at fractional positions, with flips, partial and missing collide rects, and
-- gfx.checkAlphaCollision with flips
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function shape(w, h, f)
  local img = gfx.image.new(w, h, gfx.kColorClear)
  gfx.pushContext(img) gfx.setColor(gfx.kColorBlack) f(w, h) gfx.popContext()
  return img
end
local tri = shape(9, 7, function(w, h) gfx.fillTriangle(0, 0, 8, 0, 0, 6) end)
local ring = shape(16, 16, function() gfx.setLineWidth(2) gfx.drawCircleAtPoint(8, 8, 6) end)
local dot = shape(6, 6, function() gfx.fillRect(4, 1, 2, 2) end)
local solid = gfx.image.new(5, 5, gfx.kColorBlack)
local a = gfx.sprite.new(tri) a:add()
local b = gfx.sprite.new(ring) b:add()
b:moveTo(50, 50)
local out = {}
local rr = {} for y = 0, 15 do local r = {} for x = 0, 15 do r[#r + 1] = ring:sample(x, y) == gfx.kColorBlack and "#" or "." end rr[#rr + 1] = table.concat(r) end
fh:write("ring " .. table.concat(rr, "/") .. "\n")
local function run(label, setup)
  local res = {}
  for _, dx in ipairs({ -9.5, -7.25, -6.7, -5.5, -4.2, -3.9, -2.5, -1.5, -0.3, 0, 0.6, 2.4, 3.5, 4.75, 6.1, 7.9, 9.4 }) do
    for _, dy in ipairs({ -7.6, -4.4, -1.5, 0, 2.5, 5.3, 8.2 }) do
      a:moveTo(50 + dx, 50 + dy)
      res[#res + 1] = a:alphaCollision(b) and "1" or "0"
    end
  end
  fh:write(label .. " " .. table.concat(res) .. "\n")
end
a:setCollideRect(0, 0, 9, 7) b:setCollideRect(0, 0, 16, 16)
run("full", nil)
a:setImageFlip(gfx.kImageFlippedX) run("aflipX")
a:setImageFlip(gfx.kImageFlippedY) run("aflipY")
a:setImageFlip(gfx.kImageFlippedXY) run("aflipXY")
a:setImageFlip(gfx.kImageUnflipped) b:setImageFlip(gfx.kImageFlippedX) run("bflipX")
b:setImageFlip(gfx.kImageUnflipped)
a:setCollideRect(2, 1, 4, 3) run("a partial rect")
a:setCollideRect(0, 0, 9, 7) b:setCollideRect(4, 4, 8, 8) run("b partial rect")
b:clearCollideRect() run("b no rect")
b:setCollideRect(0, 0, 16, 16)
a:setImage(dot) a:setCollideRect(0, 0, 6, 6) run("dot")
a:setImage(solid) a:setCollideRect(0, 0, 5, 5) run("solid")
a:moveTo(50, 47.5) fh:write("solid bounds " .. table.concat({ a:getBounds() }, ",") .. " cb " .. table.concat({ a:getCollideBounds() }, ",") .. " mask " .. tostring(solid:hasMask()) .. "\n")
a:setCenter(0, 0) run("solid center0")
a:setCenter(0.5, 0.5) a:setImage(tri) a:setCollideRect(0, 0, 9, 7)
a:setVisible(false) run("invisible")
a:setVisible(true) a:remove() run("removed") a:add()
a:setScale(2) run("scaled")
a:setScale(1)
-- the image function
local res = {}
for _, f1 in ipairs({ 0, 1, 2, 3 }) do
  for _, f2 in ipairs({ 0, 1 }) do
    for x = -9, 16, 1 do
      for y = -7, 16, 3 do
        res[#res + 1] = gfx.checkAlphaCollision(tri, x, y, f1, ring, 0, 0, f2) and "1" or "0"
      end
    end
    fh:write("check f1=" .. f1 .. " f2=" .. f2 .. " " .. table.concat(res) .. "\n") res = {}
  end
end
fh:write("check solid " .. tostring(gfx.checkAlphaCollision(solid, 2, 2, 0, solid, 6, 6, 0)) .. " " .. tostring(gfx.checkAlphaCollision(solid, 2, 2, 0, solid, 7, 2, 0)) .. " " .. tostring(gfx.checkAlphaCollision(solid, 2.9, 2, 0, solid, 6.5, 2, 0)) .. "\n")
fh:close()
function playdate.update() end
