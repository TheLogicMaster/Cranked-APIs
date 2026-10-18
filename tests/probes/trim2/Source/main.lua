-- Probe: other drawing paths with images whose stored data is trimmed
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function dump(name, f)
  local img = gfx.image.new(120, 90, gfx.kColorClear)
  gfx.pushContext(img) local ok, e = pcall(f) gfx.popContext()
  fh:write(name .. " " .. tostring(ok) .. " " .. tostring(e) .. "\n")
  for y = 0, 89 do local r = {} for x = 0, 119 do local c = img:sample(x, y) r[#r+1] = c == gfx.kColorBlack and "#" or (c == gfx.kColorWhite and "." or " ") end fh:write(table.concat(r) .. "\n") end
end
for _, n in ipairs({"c1", "c2", "c3", "u1", "u2"}) do
  local i = gfx.image.new(n)
  fh:write(n .. " sizes " .. tostring(i:getSize()) .. "\n")
  for _, sc in ipairs({0.75, 1.5, 2.5, 0.33}) do
    local si = i:scaledImage(sc)
    fh:write(n .. " scaledImage size " .. sc .. " " .. tostring(si.width) .. " " .. tostring(si.height) .. "\n")
    dump(n .. " scaledImage " .. sc, function() si:draw(5, 6) end)
    dump(n .. " scaledImage xy " .. sc, function() i:scaledImage(sc, sc * 0.8):draw(5, 6) end)
    dump(n .. " rotatedImage0 " .. sc, function() i:rotatedImage(0, sc):draw(5, 6) end)
    dump(n .. " transform " .. sc, function() local t = playdate.geometry.affineTransform.new() t:scale(sc) i:drawWithTransform(t, 40, 30) end)
    dump(n .. " transformed " .. sc, function() local t = playdate.geometry.affineTransform.new() t:scale(sc) i:transformedImage(t):draw(5, 6) end)
    dump(n .. " sampled " .. sc, function() i:drawSampled(5, 6, 60, 50, 0.5, 0.5, 1 / sc, 0, 0, 1 / sc, 0.5, 0.5, 1, 0, false) end)
  end
  dump(n .. " tiled", function() i:drawTiled(3, 4, 100, 70) end)
  dump(n .. " flipX", function() i:draw(5, 6, gfx.kImageFlippedX) end)
  dump(n .. " flipXY", function() i:draw(5, 6, gfx.kImageFlippedXY) end)
  dump(n .. " source", function() i:draw(5, 6, gfx.kImageUnflipped, 2, 1, 10, 8) end)
  dump(n .. " source flip", function() i:draw(5, 6, gfx.kImageFlippedXY, 2, 1, 10, 8) end)
  dump(n .. " faded", function() i:drawFaded(5, 6, 0.5, gfx.image.kDitherTypeBayer4x4) end)
  dump(n .. " blurred", function() i:drawBlurred(5, 6, 2, 2, gfx.image.kDitherTypeBayer4x4) end)
  dump(n .. " rot90 1.5", function() i:drawRotated(50, 40, 90, 1.5) end)
  dump(n .. " rot45", function() i:drawRotated(50, 40, 45) end)
  dump(n .. " sprite scale", function()
    local s = gfx.sprite.new(i) s:setScale(1.5) s:moveTo(40, 30) s:add() gfx.sprite.update() s:remove() end)
  dump(n .. " sprite rot", function()
    local s = gfx.sprite.new(i) s:setRotation(90, 1.5) s:moveTo(40, 30) s:add() gfx.sprite.update() s:remove() end)
  dump(n .. " centered", function() i:drawCentered(30, 25) end)
  dump(n .. " anchored", function() i:drawAnchored(30, 25, 0.3, 0.7) end)
end
fh:close()
function playdate.update() end
