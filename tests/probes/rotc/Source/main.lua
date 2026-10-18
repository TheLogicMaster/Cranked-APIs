-- Probe: rotated sprites with off-middle centers: bounds and drawn pixels.
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local img = gfx.image.new(6, 14, gfx.kColorWhite)
gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillRect(1, 0, 4, 14); gfx.fillRect(0, 10, 6, 4); gfx.popContext()
local centers = { { 0.5, 0.5 }, { 0.5, 1 }, { 0, 0 }, { 1, 0.5 }, { 0.5, 1.2 } }
local angles = { 30, 45, -20, 90, 60 }
local cases = {}
for i, c in ipairs(centers) do for j, a in ipairs(angles) do
  local x, y = 20 + (j - 1) * 76, 24 + (i - 1) * 46
  local s = gfx.sprite.new(img); s:setCenter(c[1], c[2]); s:moveTo(x, y); s:setRotation(a); s:add()
  cases[#cases + 1] = { name = string.format("c%.1f,%.1f_a%d", c[1], c[2], a), s = s, x = x, y = y }
end end
local f = 0
function playdate.update()
  f = f + 1; gfx.sprite.update()
  if f == 3 then
    local d = gfx.getDisplayImage(); local out = {}
    for _, c in ipairs(cases) do
      local rows = {}
      for yy = c.y - 22, c.y + 21 do local r = {}; for xx = c.x - 19, c.x + 19 do r[#r + 1] = d:sample(xx, yy) == gfx.kColorBlack and "1" or "0" end; rows[#rows + 1] = table.concat(r) end
      out[#out + 1] = c.name .. "\t" .. tostring(c.s:getBoundsRect()) .. "\t" .. table.concat(rows, "/")
    end
    local fh = playdate.file.open("rotc.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
    if playdate.simulator then playdate.simulator.exit() end; playdate.stop()
  end
end
