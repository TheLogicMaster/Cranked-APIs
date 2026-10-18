-- Probe: drawFaded's dither phase at negative positions
import "CoreLibs/graphics"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local W, H = 64, 40
local imgs = { u1 = gfx.image.new("u1"), c1 = gfx.image.new("c1"), u2 = gfx.image.new("u2") }
for _, n in ipairs({"u1", "c1", "u2"}) do
  for _, pos in ipairs({{5, 7}, {5, -7}, {5, -6}, {5, -5}, {5, -3}, {5, -1}, {-5, 4}, {-6, 4}, {-3, -3}, {-11, -9}}) do
    for _, d in ipairs({gfx.image.kDitherTypeBayer4x4, gfx.image.kDitherTypeBayer8x8}) do
      local img = gfx.image.new(W, H, gfx.kColorWhite)
      gfx.pushContext(img) imgs[n]:drawFaded(pos[1], pos[2], 0.5962, d) gfx.popContext()
      local rows = {}
      for y = 0, H - 1 do local r = {} for x = 0, W - 1 do local c = img:sample(x, y) r[#r+1] = c == gfx.kColorBlack and "#" or (c == gfx.kColorWhite and "." or " ") end rows[#rows+1] = table.concat(r) end
      fh:write(n .. " " .. pos[1] .. " " .. pos[2] .. " " .. d .. "\n" .. table.concat(rows, "\n") .. "\n")
    end
  end
end
fh:close()
function playdate.update() end
