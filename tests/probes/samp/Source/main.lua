-- Probe: image:sample with integer and fractional coordinates, inside and outside.
local gfx = playdate.graphics
local out = {}
local i = gfx.image.new(4, 4, gfx.kColorWhite)
gfx.pushContext(i); gfx.setColor(gfx.kColorBlack); gfx.drawPixel(2, 2); gfx.drawPixel(3, 3); gfx.popContext()
for _, p in ipairs({ {4, 0}, {0, 4}, {5, 0}, {0, 5}, {5, 5}, {10, 1}, {4, -1}, {100, 100}, {3, 4}, {4, 3} }) do
  out[#out + 1] = p[1] .. "," .. p[2] .. "|" .. tostring(i:sample(p[1], p[2]))
end
local fh = playdate.file.open("samp.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
