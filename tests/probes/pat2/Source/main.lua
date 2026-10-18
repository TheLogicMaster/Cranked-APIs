-- Probe: setPattern phase. Each case fills a 24x24 area with a pattern and dumps it, in an image and on screen.
import "CoreLibs/graphics"
local gfx = playdate.graphics
math.randomseed(808)
local cases = {}
for pos = 0, 63 do local r, c = pos // 8, pos % 8
  local p = {}; for i = 0, 7 do p[i + 1] = (i == r) and (0xFF & ~(0x80 >> c)) or 0xFF end
  cases[#cases + 1] = { "blackpix" .. pos, p }
  local q = {}; for i = 0, 7 do q[i + 1] = (i == r) and (0x80 >> c) or 0 end
  cases[#cases + 1] = { "whitepix" .. pos, q }
end
for k = 1, 40 do local p = {}; for i = 1, 8 do p[i] = math.random(0, 255) end; cases[#cases + 1] = { "rand" .. k, p } end
local function dump(img, x0, y0)
  local t = {}
  for y = y0, y0 + 23 do for x = x0, x0 + 23 do t[#t + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
  return table.concat(t)
end
local out = {}
local f = 0
local origins = { { 0, 0 }, { 3, 5 } }
function playdate.update()
  f = f + 1
  if f == 1 then
    for _, c in ipairs(cases) do
      for _, o in ipairs(origins) do
        local img = gfx.image.new(32, 32, gfx.kColorWhite)
        gfx.pushContext(img); gfx.setPattern(c[2]); gfx.fillRect(o[1], o[2], 24, 24); gfx.popContext()
        out[#out + 1] = c[1] .. " img " .. o[1] .. "," .. o[2] .. "|" .. table.concat(c[2], ",") .. "|" .. dump(img, o[1], o[2])
      end
      local img = gfx.image.new(32, 32, gfx.kColorWhite)
      gfx.pushContext(img); gfx.setPattern(c[2]); gfx.fillTriangle(0, 0, 30, 0, 0, 30); gfx.popContext()
      out[#out + 1] = c[1] .. " tri 0,0|" .. table.concat(c[2], ",") .. "|" .. dump(img, 0, 0)
    end
    -- on screen: one case per 32-pixel cell, dumped on the next frame
    gfx.clear(gfx.kColorWhite)
    for i = 1, 30 do local c = cases[i * 5]; local x, y = ((i - 1) % 10) * 40 + 5, ((i - 1) // 10) * 40 + 7
      gfx.setPattern(c[2]); gfx.fillRect(x, y, 24, 24) end
  elseif f == 3 then
    local d = gfx.getDisplayImage()
    for i = 1, 30 do local c = cases[i * 5]; local x, y = ((i - 1) % 10) * 40 + 5, ((i - 1) // 10) * 40 + 7
      out[#out + 1] = c[1] .. " screen " .. x .. "," .. y .. "|" .. table.concat(c[2], ",") .. "|" .. dump(d, x, y) end
    local fh = playdate.file.open("pat2.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
    if playdate.simulator then playdate.simulator.exit() end; playdate.stop()
  end
end
