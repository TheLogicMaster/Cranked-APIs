-- Probe: checkAlphaCollision and sprite alphaCollision with an image that has no mask
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local ring = gfx.image.new(16, 16, gfx.kColorClear)
gfx.pushContext(ring) gfx.setColor(gfx.kColorBlack) gfx.setLineWidth(2) gfx.drawCircleAtPoint(8, 8, 6) gfx.popContext()
local solid = gfx.image.new(5, 5, gfx.kColorBlack)
local wsolid = gfx.image.new(3, 4, gfx.kColorWhite)
for _, pair in ipairs({ { solid, ring, "solid-ring" }, { ring, solid, "ring-solid" }, { wsolid, ring, "wsolid-ring" } }) do
  for y = -6, 17 do
    local r = {}
    for x = -6, 17 do r[#r + 1] = gfx.checkAlphaCollision(pair[1], x, y, 0, pair[2], 0, 0, 0) and "1" or "0" end
    fh:write(pair[3] .. " y=" .. y .. " " .. table.concat(r) .. "\n")
  end
end
local a = gfx.sprite.new(solid) a:setCenter(0, 0) a:setCollideRect(0, 0, 5, 5) a:add()
local b = gfx.sprite.new(ring) b:setCenter(0, 0) b:setCollideRect(0, 0, 16, 16) b:moveTo(20, 20) b:add()
for y = -6, 17 do
  local r = {}
  for x = -6, 17 do a:moveTo(20 + x, 20 + y) r[#r + 1] = a:alphaCollision(b) and "1" or "0" end
  fh:write("sprite y=" .. y .. " " .. table.concat(r) .. "\n")
end
for y = -6, 17 do
  local r = {}
  for x = -6, 17 do a:moveTo(20 + x, 20 + y) r[#r + 1] = b:alphaCollision(a) and "1" or "0" end
  fh:write("sprite rev y=" .. y .. " " .. table.concat(r) .. "\n")
end
local n = gfx.sprite.new(solid) n:setCenter(0, 0) n:setCollideRect(0, 0, 5, 5) n:moveTo(24, 21)
a:moveTo(24, 21)
fh:write("never added " .. tostring(n:alphaCollision(b)) .. " " .. tostring(b:alphaCollision(n)) .. " added " .. tostring(a:alphaCollision(b)) .. "\n")
n:add() fh:write("after add " .. tostring(n:alphaCollision(b)) .. "\n")
n:remove() fh:write("after remove " .. tostring(n:alphaCollision(b)) .. "\n")
local t = gfx.sprite.new() t:setCenter(0, 0) t:setSize(5, 5) t:setCollideRect(0, 0, 5, 5) t:moveTo(24, 21) t:add()
fh:write("no image " .. tostring(t:alphaCollision(b)) .. "\n")
local tm = gfx.tilemap.new() local it = gfx.imagetable.new(1) it:setImage(1, solid) tm:setImageTable(it) tm:setSize(1, 1) tm:setTileAtPosition(1, 1, 1)
t:setTilemap(tm) fh:write("tilemap " .. tostring(t:alphaCollision(b)) .. "\n")
local blob = gfx.image.new(6, 5, gfx.kColorClear) gfx.pushContext(blob) gfx.setColor(gfx.kColorBlack) gfx.fillRect(1, 1, 3, 2) gfx.fillRect(4, 3, 2, 2) gfx.popContext()
a:setImage(blob) a:setCollideRect(0, 0, 6, 5)
a:setScale(2) a:moveTo(10, 15) local r = {}
for x = 4, 44 do a:moveTo(4 + x * 0.5, 13 + (x % 7)) r[#r + 1] = a:alphaCollision(b) and "1" or "0" end
fh:write("scaled " .. table.concat(r) .. "\n")
a:setScale(1) a:setRotation(45) a:setCollideRect(0, 0, 6, 5) r = {}
for x = 4, 44 do a:moveTo(4 + x * 0.5, 13 + (x % 7)) r[#r + 1] = a:alphaCollision(b) and "1" or "0" end
fh:write("rotated " .. table.concat(r) .. "\n")
fh:close()
function playdate.update() end
