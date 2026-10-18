-- Probe: drawRotated (angles 0, 90, 180, 360) and drawCentered at fractional centers; left/top edge of the result
import "CoreLibs/graphics"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function log(s) fh:write(s .. "\n") end
local function edges(img)
  local l, t, r, b = 999, 999, -1, -1
  for y = 0, 59 do for x = 0, 99 do if img:sample(x, y) == gfx.kColorBlack then l = math.min(l, x) t = math.min(t, y) r = math.max(r, x) b = math.max(b, y) end end end
  return l, t, r, b
end
for _, sz in ipairs({{20, 10}, {21, 11}, {20, 11}, {21, 10}}) do
  local src = gfx.image.new(sz[1], sz[2], gfx.kColorBlack)
  for _, a in ipairs({0, 90, 180, 360, -90}) do
    for _, c in ipairs({30, 30.25, 30.5, 30.75, -2.5, 2.5, -2.25, -2.75}) do
      local img = gfx.image.new(100, 60, gfx.kColorWhite)
      gfx.pushContext(img) gfx.setDrawOffset(20, 20) src:drawRotated(c, c, a) gfx.popContext()
      local l, t, r, b = edges(img)
      log(string.format("%dx%d a=%d c=%s: %d %d %d %d", sz[1], sz[2], a, tostring(c), l - 20, t - 20, r - 20, b - 20))
    end
  end
  for _, c in ipairs({30.5, -2.5, 2.5, -2.25, -2.75}) do
    local img = gfx.image.new(100, 60, gfx.kColorWhite)
    gfx.pushContext(img) gfx.setDrawOffset(20, 20) src:drawScaled(c, c, 1) src:drawRotated(c, c + 30, 0, 2) gfx.popContext()
    local l, t, r, b = edges(img)
    log(string.format("%dx%d scaled c=%s: %d %d %d %d", sz[1], sz[2], tostring(c), l - 20, t - 20, r - 20, b - 20))
  end
end
fh:close()
function playdate.update() end
