-- Probe: a sprite's draw callback removes and re-adds another sprite; frame hashes
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function log(s) fh:write(s .. "\n") fh:flush() end
local p = gfx.image.new("cursor")
local function hash()
  local img = gfx.getWorkingImage() local b, sum = 0, 0
  for y = 0, 239 do for x = 0, 399 do if img:sample(x, y) == gfx.kColorBlack then b += 1 sum = (sum * 31 + x * 7 + y) % 1000003 end end end
  return b, sum
end
local icon
local a = gfx.sprite.new() a:setSize(120, 30) a:setCenter(0, 0) a:moveTo(40, 40) a:setZIndex(10)
local mode = 1
local draws = 0
function a:draw(x, y, w, h)
  draws += 1
  gfx.setColor(gfx.kColorBlack) gfx.drawRect(0, 0, 120, 30)
  if icon then icon:remove() end
  icon = gfx.sprite.new(p) icon:setZIndex(mode == 2 and 5 or 20) icon:moveTo(140, 55)
  if mode == 3 then icon:setImageDrawMode(gfx.kDrawModeInverted) end
  icon:add()
end
a:add()
local n = 0
function playdate.update()
  n += 1
  if n == 4 then a:markDirty() end
  if n == 6 then mode = 2 a:markDirty() end
  if n == 8 then mode = 3 a:moveTo(50, 60) end
  if n == 10 then gfx.sprite.redrawBackground() end
  gfx.sprite.update()
  local b, h = hash()
  log(string.format("n=%d black=%d hash=%d count=%d draws=%d", n, b, h, gfx.sprite.spriteCount(), draws))
  if n == 12 then fh:close() end
end
