-- Probe: scaled sprite images (setImage, setScale) at fractional positions, partly off screen; drawn area
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local cases = {}
local seed = 3
local function rnd(n) seed = (seed * 16807) % 2147483647 return seed % n end
local img = gfx.image.new(20, 12, gfx.kColorBlack)
for i = 1, 60 do cases[i] = { sc = 0.3 + rnd(600) / 100, x = -40 + rnd(4800) / 10, y = -30 + rnd(3000) / 10, cx = (i % 3) * 0.5, cy = ((i + 1) % 3) * 0.5, flip = i % 4 == 0 } end
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
    fh:write(string.format("%d sc=" .. cases[frame - 1].sc .. " pos=" .. cases[frame - 1].x .. "," .. cases[frame - 1].y .. " size=%.4f,%.4f bounds=%.4f,%.4f,%.4f,%.4f drawn=%d,%d-%d,%d args=%s\n", frame - 1, w, h, bx, by, bw, bh, minx, miny, maxx, maxy, s.lastArgs or "-"))
    s:remove()
  end
  if not c then fh:close() playdate.stop() return end
  s = gfx.sprite.new()
  s:setCenter(c.cx, c.cy)
  if c.flip then s:setImage(img, gfx.kImageFlippedX, c.sc) else s:setImage(img) s:setScale(c.sc) end
  s:moveTo(c.x, c.y)
  s:add()
  gfx.sprite.update()
end
