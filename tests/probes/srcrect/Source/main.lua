-- Probe: fractional source rects in image:draw (rect object and numbers), and fractional draw positions.
local gfx = playdate.graphics
local out = {}
local src = gfx.image.new(16, 1, gfx.kColorWhite)
gfx.pushContext(src); gfx.setColor(gfx.kColorBlack); for x = 0, 15, 3 do gfx.drawPixel(x, 0) end; gfx.popContext()
local function row(fn)
  local d = gfx.image.new(16, 1, gfx.kColorWhite); gfx.pushContext(d); fn(); gfx.popContext()
  local t = {}; for x = 0, 15 do t[#t + 1] = d:sample(x, 0) == gfx.kColorBlack and "1" or "0" end; return table.concat(t)
end
for _, v in ipairs({0, 0.4, 0.5, 0.6, 1.5, 2.5, 2.7, 3.49, 3.5, -0.5, 7.999}) do
  out[#out + 1] = "rectobj " .. v .. "|" .. row(function() src:draw(0, 0, gfx.kImageUnflipped, playdate.geometry.rect.new(v, 0, 10, 1)) end)
  out[#out + 1] = "numbers " .. v .. "|" .. row(function() src:draw(0, 0, gfx.kImageUnflipped, v, 0, 10, 1) end)
  out[#out + 1] = "pos " .. v .. "|" .. row(function() src:draw(v, 0) end)
  out[#out + 1] = "rectw " .. v .. "|" .. row(function() src:draw(0, 0, gfx.kImageUnflipped, playdate.geometry.rect.new(1, 0, 5 + v, 1)) end)
end
local fh = playdate.file.open("srcrect.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
