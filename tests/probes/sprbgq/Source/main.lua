-- Probe: sprites over a background drawing callback that sets and clears the clip rect; frame hash per step
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function log(s) fh:write(s .. "\n") fh:flush() end
local p = gfx.image.new("cursor")
local bg = gfx.image.new(400, 240, gfx.kColorWhite)
gfx.pushContext(bg) gfx.setColor(gfx.kColorBlack) gfx.drawRect(5, 5, 390, 230) gfx.popContext()
local mode = 0
gfx.sprite.setBackgroundDrawingCallback(function(x, y, w, h)
  if mode == 1 then gfx.setClipRect(x, y, w, h) bg:draw(0, 0) gfx.clearClipRect()
  else bg:draw(0, 0) end
end)
local n = 0
local s1, s2
local function hash()
  local img = gfx.getWorkingImage() local b, sum = 0, 0
  for y = 0, 239 do for x = 0, 399 do if img:sample(x, y) == gfx.kColorBlack then b += 1 sum = (sum * 31 + x * 7 + y) % 1000003 end end end
  return b, sum
end
function playdate.update()
  n += 1
  if n == 2 then s1 = gfx.sprite.new(p) s1:moveTo(100, 100) s1:add() s1:setZIndex(100) end
  if n == 4 then s2 = gfx.sprite.new(p) s2:setRotation(90) s2:moveTo(200, 100) s2:add() s2:setZIndex(5) end
  if n == 6 then s1:moveTo(110, 120) end
  if n == 8 then s2:setImage(p:copy()) s2:setRotation(90) end
  if n == 10 then mode = 1 gfx.sprite.redrawBackground() end
  if n == 12 then s1:moveTo(130, 120) s2:moveTo(230, 100) end
  if n == 14 then s2:setRotation(15) end
  gfx.sprite.update()
  local b, h = hash()
  log(string.format("n=%d black=%d hash=%d", n, b, h))
  if n == 16 then fh:close() end
end
