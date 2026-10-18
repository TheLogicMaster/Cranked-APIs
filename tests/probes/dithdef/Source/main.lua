-- Probe: the default type of setDitherPattern(alpha), compared with each explicit type, at several alphas.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local img = gfx.image.new(16, 16)
local function grab()
  local t = {}
  for y = 0, 15 do for x = 0, 15 do t[#t + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
  return table.concat(t)
end
local function fill(a, ty)
  img:clear(gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack)
  if ty then gfx.setDitherPattern(a, ty) else gfx.setDitherPattern(a) end
  gfx.fillRect(0, 0, 16, 16); gfx.popContext(); return grab()
end
local types = { None = gfx.image.kDitherTypeNone, Diagonal = gfx.image.kDitherTypeDiagonalLine, Bayer2 = gfx.image.kDitherTypeBayer2x2,
  Bayer4 = gfx.image.kDitherTypeBayer4x4, Bayer8 = gfx.image.kDitherTypeBayer8x8, Screen = gfx.image.kDitherTypeScreen }
for _, a in ipairs({0.1, 0.25, 0.4, 0.5, 0.6, 0.75, 0.9}) do
  local d = fill(a)
  local same = {}
  for name, ty in pairs(types) do if fill(a, ty) == d then same[#same + 1] = name end end
  table.sort(same)
  local n = 0; for c in d:gmatch("1") do n = n + 1 end
  out[#out + 1] = string.format("a%.2f|black=%d same=%s", a, n, table.concat(same, ","))
end
local fh = playdate.file.open("dithdef.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
