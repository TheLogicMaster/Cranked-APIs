-- Probe: drawBlurred near the left and top edges (Bayer 4x4, an opaque striped image), to place the pattern
import "CoreLibs/graphics"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local img = gfx.image.new(9, 7, gfx.kColorWhite)
gfx.pushContext(img) gfx.setColor(gfx.kColorBlack) for x = 0, 8, 2 do gfx.drawLine(x, 0, x, 6) end gfx.popContext()
local function rows(c)
  local w, h = c:getSize() local t = {}
  for y = 0, h - 1 do local r = {} for x = 0, w - 1 do local v = c:sample(x, y) r[#r + 1] = v == gfx.kColorBlack and "#" or (v == gfx.kColorWhite and "." or " ") end t[#t + 1] = table.concat(r) end
  return table.concat(t, "/")
end
for _, x in ipairs({-12, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 5}) do
  for _, y in ipairs({-6, -3, 0, 2}) do
    local c = gfx.image.new(24, 18, gfx.kColorClear)
    gfx.pushContext(c) img:drawBlurred(x, y, 3, 1, gfx.image.kDitherTypeBayer4x4) gfx.popContext()
    fh:write(x .. " " .. y .. " " .. rows(c) .. "\n")
  end
end
fh:close()
function playdate.update() end
