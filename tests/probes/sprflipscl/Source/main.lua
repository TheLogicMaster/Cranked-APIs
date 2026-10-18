-- Probe: sprites drawn with both a flip and a scale (via setImage and setScale), at whole and half positions
import "CoreLibs/sprites"
local gfx = playdate.graphics
local img = gfx.image.new(9, 7, gfx.kColorClear)
gfx.pushContext(img) gfx.fillRect(0, 0, 3, 7) gfx.fillRect(3, 0, 6, 2) gfx.drawPixel(8, 6) gfx.popContext()
local cases = {}
local i = 0
for _, fl in ipairs({ gfx.kImageUnflipped, gfx.kImageFlippedX, gfx.kImageFlippedY, gfx.kImageFlippedXY }) do
  for _, sc in ipairs({ { 2, 2 }, { 0.5, 0.5 }, { 1.5, 3 }, { 3, 1 } }) do
    local s = gfx.sprite.new()
    s:setImage(img, fl, sc[1], sc[2])
    s:moveTo(20 + (i % 8) * 45 + (i % 3) * 0.5, 30 + (i // 8) * 60 + (i % 2) * 0.5)
    s:add()
    i = i + 1
  end
end
local s2 = gfx.sprite.new(img) s2:setImageFlip(gfx.kImageFlippedX) s2:setScale(2) s2:moveTo(200, 200) s2:add()
local frame = 0
function playdate.update()
  frame = frame + 1
  gfx.sprite.update()
  if frame == 3 then
    local d = gfx.getDisplayImage()
    local rows = {}
    for y = 0, 239 do local bits = {} for x = 0, 399, 4 do local v = 0 for b = 0, 3 do if d:sample(x + b, y) == gfx.kColorBlack then v = v + (1 << (3 - b)) end end bits[#bits + 1] = string.format("%x", v) end rows[#rows + 1] = table.concat(bits) end
    local f = playdate.file.open("out.txt", playdate.file.kFileWrite) f:write(table.concat(rows, "\n") .. "\n") f:close()
  end
end
