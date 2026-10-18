-- Probe: drawRect with small sizes and line widths (pixel lists)
import "CoreLibs/graphics"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local W, H = 40, 30
for _, lw in ipairs({1, 2, 3}) do
  for _, sl in ipairs({gfx.kStrokeCentered, gfx.kStrokeInside, gfx.kStrokeOutside}) do
    for _, sz in ipairs({{5, 1}, {1, 5}, {1, 1}, {2, 1}, {1, 2}, {2, 2}, {3, 3}, {6, 4}, {0, 3}, {3, 0}, {-3, 2}, {4, -2}}) do
      local img = gfx.image.new(W, H, gfx.kColorWhite)
      gfx.pushContext(img) gfx.setLineWidth(lw) gfx.setStrokeLocation(sl) gfx.drawRect(10, 10, sz[1], sz[2]) gfx.popContext()
      local p = {}
      for y = 0, H - 1 do for x = 0, W - 1 do if img:sample(x, y) == gfx.kColorBlack then p[#p+1] = x .. ":" .. y end end end
      fh:write(lw .. " " .. sl .. " " .. sz[1] .. "x" .. sz[2] .. " | " .. table.concat(p, " ") .. "\n")
    end
  end
end
fh:close()
function playdate.update() end
