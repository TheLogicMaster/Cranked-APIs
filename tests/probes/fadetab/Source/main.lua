-- Probe: per-cell fadedImage thresholds for the non-Bayer ordered types (and Bayer 8x8 as a check):
-- for each type and k = 0..256, which cells of an 8x8 black image stay black at alpha k/255.
local gfx = playdate.graphics
local out = {}
local src = gfx.image.new(8, 8, gfx.kColorBlack)
local types = { {"None", gfx.image.kDitherTypeNone}, {"Diagonal", gfx.image.kDitherTypeDiagonalLine}, {"Vertical", gfx.image.kDitherTypeVerticalLine},
  {"Horizontal", gfx.image.kDitherTypeHorizontalLine}, {"Screen", gfx.image.kDitherTypeScreen}, {"Bayer8", gfx.image.kDitherTypeBayer8x8} }
for _, t in ipairs(types) do
  for k = 0, 256 do
    local f = src:fadedImage(k / 255, t[2]); local s = {}
    for y = 0, 7 do for x = 0, 7 do s[#s + 1] = f:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
    out[#out + 1] = t[1] .. " " .. k .. "|" .. table.concat(s)
  end
end
local fh = playdate.file.open("fadetab.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
