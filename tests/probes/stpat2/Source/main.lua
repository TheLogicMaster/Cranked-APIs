-- Probe: exact level at which each cell of gfx.setStencilPattern(level, ditherType) turns on (bisection)
import "CoreLibs/graphics"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local I = gfx.image
local types = { {"none", I.kDitherTypeNone}, {"diag", I.kDitherTypeDiagonalLine}, {"vert", I.kDitherTypeVerticalLine}, {"horiz", I.kDitherTypeHorizontalLine}, {"screen", I.kDitherTypeScreen}, {"b2", I.kDitherTypeBayer2x2}, {"b4", I.kDitherTypeBayer4x4}, {"b8", I.kDitherTypeBayer8x8} }
local img = gfx.image.new(8, 8, gfx.kColorWhite)
local function cells(lv, t)
  img:clear(gfx.kColorWhite)
  gfx.pushContext(img) gfx.setStencilPattern(lv, t) gfx.setColor(gfx.kColorBlack) gfx.fillRect(0, 0, 8, 8) gfx.popContext()
end
for _, t in ipairs(types) do
  local out = {}
  for y = 0, 7 do for x = 0, 7 do
    local lo, hi = 0, 1
    for k = 1, 20 do local mid = (lo + hi) / 2 cells(mid, t[2]) if img:sample(x, y) == gfx.kColorBlack then hi = mid else lo = mid end end
    out[#out + 1] = string.format("%.5f", hi)
  end end
  fh:write(t[1] .. " " .. table.concat(out, " ") .. "\n")
end
fh:close()
function playdate.update() end
