-- Probe: fadedImage of a solid black 16x16 image for each ordered dither type at several alphas.
local gfx = playdate.graphics
local out = {}
local src = gfx.image.new(16, 16, gfx.kColorBlack)
local types = { None = gfx.image.kDitherTypeNone, Diagonal = gfx.image.kDitherTypeDiagonalLine, Vertical = gfx.image.kDitherTypeVerticalLine,
  Horizontal = gfx.image.kDitherTypeHorizontalLine, Screen = gfx.image.kDitherTypeScreen, Bayer2 = gfx.image.kDitherTypeBayer2x2,
  Bayer4 = gfx.image.kDitherTypeBayer4x4, Bayer8 = gfx.image.kDitherTypeBayer8x8 }
local names = {}; for k in pairs(types) do names[#names + 1] = k end; table.sort(names)
for _, n in ipairs(names) do
  for _, a in ipairs({0.1, 0.3, 0.5, 0.7, 0.9}) do
    local f = src:fadedImage(a, types[n]); local t = {}
    for y = 0, 15 do for x = 0, 15 do local s = f:sample(x, y); t[#t + 1] = s == gfx.kColorBlack and "1" or (s == gfx.kColorWhite and "0" or ".") end end
    out[#out + 1] = n .. " " .. a .. "|" .. table.concat(t)
  end
end
local fh = playdate.file.open("fadeds.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
