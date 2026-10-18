-- Probe: drawFaded pattern phase for a trimmed and an opaque image at negative and positive positions
import "CoreLibs/graphics"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local imgs = { tr = gfx.image.new("tr"), op = gfx.image.new("op") }
for _, name in ipairs({"tr", "op"}) do
  for _, pos in ipairs({{4, 4}, {4, -1}, {4, -2}, {4, -3}, {4, -4}, {4, -5}, {4, -6}, {4, -7}, {4, -8}, {4, -9}, {4, -10}, {-1, 4}, {-6, 4}, {-7, -7}, {5, 5}, {2, 1}, {2, 0}}) do
    for _, off in ipairs({0, 3}) do
      local img = gfx.image.new(40, 34, gfx.kColorWhite)
      gfx.pushContext(img) gfx.setDrawOffset(off, off) imgs[name]:drawFaded(pos[1], pos[2], 0.01, gfx.image.kDitherTypeBayer8x8) gfx.popContext()
      fh:write(name .. " " .. pos[1] .. "," .. pos[2] .. " off " .. off .. "\n")
      for y = 0, 33 do local r = {} for x = 0, 39 do r[#r + 1] = img:sample(x, y) == gfx.kColorBlack and "#" or "." end fh:write(table.concat(r) .. "\n") end
    end
  end
end
fh:close()
function playdate.update() end
