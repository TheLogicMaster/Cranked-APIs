-- Probe: how fractional sprite clip rects round (x, y, width, height).
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local img = gfx.image.new(30, 30, gfx.kColorBlack)
local vals = { { 0, 0, 10.1, 10.1 }, { 0, 0, 10.5, 10.9 }, { 0.4, 0.4, 10, 10 }, { 0.5, 0.5, 10, 10 }, { 0.6, 0.6, 10, 10 },
  { 0.3, 0.3, 10.3, 10.3 }, { 0.7, 0.7, 10.7, 10.7 }, { 2.2, 3.8, 5.5, 6.1 }, { -0.5, -0.5, 10, 10 }, { 1.5, 1.5, 0.2, 0.2 } }
local list = {}
for i, v in ipairs(vals) do
  local bx, by = 10 + ((i - 1) % 5) * 70, 30 + ((i - 1) // 5) * 70
  local s = gfx.sprite.new(img); s:setCenter(0, 0); s:moveTo(bx, by)
  s:setClipRect(bx + v[1], by + v[2], v[3], v[4]); s:add()
  list[i] = { bx = bx, by = by, v = v }
end
local f = 0
function playdate.update()
  f = f + 1; gfx.sprite.update()
  if f == 3 then
    local d = gfx.getDisplayImage(); local out = {}
    for i, e in ipairs(list) do
      local minx, miny, maxx, maxy = 999, 999, -999, -999
      for y = e.by - 2, e.by + 32 do for x = e.bx - 2, e.bx + 32 do
        if d:sample(x, y) == gfx.kColorBlack then minx = math.min(minx, x - e.bx); maxx = math.max(maxx, x - e.bx); miny = math.min(miny, y - e.by); maxy = math.max(maxy, y - e.by) end
      end end
      out[#out + 1] = table.concat(e.v, ",") .. "\t" .. (maxx >= minx and string.format("x %d..%d y %d..%d", minx, maxx, miny, maxy) or "none")
    end
    local fh = playdate.file.open("sclip3.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
    if playdate.simulator then playdate.simulator.exit() end; playdate.stop()
  end
end
