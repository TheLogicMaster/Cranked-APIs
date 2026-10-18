-- Probe: does getDisplayImage always return the previous frame? Each frame encodes its number in 16 pixels and
-- reads back the number shown; frames whose readback is not n - 1 are logged. Some frames are made slow on purpose.
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local n = 0
local bad = 0
function playdate.update()
  n += 1
  local img = gfx.getDisplayImage()
  local v = 0
  for b = 0, 15 do if img:sample(b, 0) == gfx.kColorBlack then v = v | (1 << b) end end
  if v ~= (n - 1) & 0xFFFF and n > 1 then bad += 1 if bad < 60 then fh:write(n .. " read " .. v .. "\n") end end
  gfx.clear(gfx.kColorWhite)
  gfx.setColor(gfx.kColorBlack)
  for b = 0, 15 do if (n >> b) & 1 == 1 then gfx.drawPixel(b, 0) end end
  if n % 7 == 0 then local t = playdate.getCurrentTimeMilliseconds() while playdate.getCurrentTimeMilliseconds() - t < 40 do end end
  if n == 600 then fh:write("bad " .. bad .. "\n") fh:close() end
end
