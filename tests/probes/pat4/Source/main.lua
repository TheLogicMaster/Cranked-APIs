-- Probe: setPattern phase with explicit x, y arguments, and with 16-entry (pattern + mask) tables.
import "CoreLibs/graphics"
local gfx = playdate.graphics
math.randomseed(4711)
local out = {}
local img = gfx.image.new(16, 16)
local function run(name, p, ...)
  img:clear(gfx.kColorWhite)
  gfx.pushContext(img); gfx.setPattern(p, ...); gfx.fillRect(0, 0, 16, 16); gfx.popContext()
  local t = {}
  for y = 0, 15 do for x = 0, 15 do local s = img:sample(x, y); t[#t + 1] = s == gfx.kColorBlack and "1" or "0" end end
  out[#out + 1] = name .. "|" .. table.concat(p, ",") .. "|" .. table.concat({ ... }, ",") .. "|" .. table.concat(t)
end
for k = 1, 24 do
  local p = {}; for i = 1, 8 do p[i] = math.random(0, 255) end
  run("noargs" .. k, p)
  run("xy" .. k, p, k % 8, (k * 3) % 8)
  run("x_only" .. k, p, 5)
  local q = {}; for i = 1, 8 do q[i] = p[i] end; for i = 9, 16 do q[i] = 0xFF end
  run("mask_full" .. k, q)
  local r = {}; for i = 1, 8 do r[i] = p[i] end; for i = 9, 16 do r[i] = math.random(0, 255) end
  run("mask_rand" .. k, r)
end
local fh = playdate.file.open("pat4.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
