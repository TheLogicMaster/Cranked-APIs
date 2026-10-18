-- Probe: image.new with fractional and negative sizes.
local gfx = playdate.graphics
local out = {}
for _, v in ipairs({1.2, 1.5, 1.6, 1.99, 2.5, 3.5, 10.49, 10.5, 10.51, 0.6, -0.4}) do
  local ok, img = pcall(gfx.image.new, v, v + 1)
  if ok and img then local w, h = img:getSize(); out[#out + 1] = string.format("%s|%s,%s", v, w, h)
  else out[#out + 1] = string.format("%s|%s", v, tostring(img)) end
end
local fh = playdate.file.open("imgfrac.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
