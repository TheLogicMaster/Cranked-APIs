-- Probe: sprites with fractional sizes and positions; their bounds and the area their draw callback covers
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local cases = {}
local seed = 3
local function rnd(n) seed = (seed * 16807) % 2147483647 return seed % n end
for i = 1, 40 do cases[i] = { w = 3 + rnd(400) / 10, h = 3 + rnd(300) / 10, x = 60 + rnd(2800) / 10, y = 50 + rnd(1400) / 10, cx = (i % 3) * 0.5, cy = ((i + 1) % 3) * 0.5 } end
local frame = 0
local s
function playdate.update()
  frame = frame + 1
  local c = cases[frame]
  if s then
    -- what the previous case drew: the bounding box of black pixels on the working image
    local img = gfx.getWorkingImage()
    local minx, miny, maxx, maxy = 999, 999, -1, -1
    for y = 0, 239 do for x = 0, 399 do if img:sample(x, y) == gfx.kColorBlack then if x < minx then minx = x end if x > maxx then maxx = x end if y < miny then miny = y end if y > maxy then maxy = y end end end end
    local bx, by, bw, bh = s:getBounds()
    local w, h = s:getSize()
    fh:write(string.format("%d size=%.4f,%.4f bounds=%.4f,%.4f,%.4f,%.4f drawn=%d,%d-%d,%d args=%s\n", frame - 1, w, h, bx, by, bw, bh, minx, miny, maxx, maxy, s.lastArgs or "-"))
    s:remove()
  end
  if not c then fh:close() playdate.stop() return end
  s = gfx.sprite.new()
  s:setCenter(c.cx, c.cy)
  s:setSize(c.w, c.h)
  s:moveTo(c.x, c.y)
  s.draw = function(self, x, y, w, h) self.lastArgs = string.format("%g,%g,%g,%g", x, y, w, h) gfx.setColor(gfx.kColorBlack) gfx.fillRect(-50, -50, 500, 500) end
  s:add()
  gfx.sprite.update()
end
