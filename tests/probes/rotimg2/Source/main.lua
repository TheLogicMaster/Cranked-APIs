-- Probe: rotatedImage on random images and angles; the sources are dumped too.
import "CoreLibs/graphics"
local gfx = playdate.graphics
math.randomseed(4242)
local out = {}
local function dumpImg(im) local w, h = im:getSize(); local rows = {}
  for y = 0, h - 1 do local t = {}; for x = 0, w - 1 do local s = im:sample(x, y); t[#t + 1] = s == gfx.kColorBlack and "1" or (s == gfx.kColorWhite and "0" or "x") end; rows[#rows + 1] = table.concat(t) end
  return w .. "x" .. h, table.concat(rows, "/") end
for i = 1, 30 do
  local w, h = math.random(3, 16), math.random(3, 16)
  local im = gfx.image.new(w, h, gfx.kColorWhite)
  gfx.pushContext(im); gfx.setColor(gfx.kColorBlack)
  for k = 1, w * h // 3 do gfx.drawPixel(math.random(0, w - 1), math.random(0, h - 1)) end
  gfx.popContext()
  local ang = math.random(-3600, 3600) / 10
  local ssz, spix = dumpImg(im)
  local rsz, rpix = dumpImg(im:rotatedImage(ang))
  out[#out + 1] = "h" .. i .. "_" .. ang .. "\t" .. rsz .. "\t" .. rpix .. "\t" .. ssz .. "\t" .. spix
end
local fh = playdate.file.open("rotimg2.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
