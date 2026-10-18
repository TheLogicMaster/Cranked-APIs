-- Probe: animator with point values, delay and easing driving a sprite; logs per frame
import "CoreLibs/graphics"
import "CoreLibs/animator"
import "CoreLibs/easing"
import "CoreLibs/sprites"
import "CoreLibs/timer"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function log(s) fh:write(s .. "\n") fh:flush() end
local img = gfx.image.new(10, 20, gfx.kColorBlack)
local s = gfx.sprite.new(img)
s:setRotation(30) s:add() s:setZIndex(5)
local a1 = gfx.animator.new(500, playdate.geometry.point.new(0, 0), playdate.geometry.point.new(100, 50), playdate.easingFunctions.inCubic, 200)
local a2 = gfx.animator.new(500, 0, 90, playdate.easingFunctions.outCubic)
local a3 = gfx.animator.new(300, 10, 20)
local ok, e = pcall(function() s:moveTo(a1:currentValue()) end)
log("moveTo point " .. tostring(ok) .. " " .. tostring(e) .. " " .. s.x .. " " .. s.y)
local t = playdate.timer.new(400, 0, 1)
local n = 0
function playdate.update()
  n += 1
  local v = a1:currentValue()
  local ok2, e2 = pcall(function() s:moveTo(v) end)
  s:setRotation(a2:currentValue())
  gfx.sprite.update()
  playdate.timer.updateTimers()
  if n % 3 == 0 and n < 60 then
    log(string.format("%d v=%s ended=%s %s x=%.2f y=%.2f r=%.2f a3=%s e3=%s t=%s w=%d h=%d", n, tostring(v), tostring(a1:ended()), tostring(ok2), s.x, s.y, s:getRotation(), tostring(a3:currentValue()), tostring(a3:ended()), tostring(t.value), s.width, s.height))
  end
  if n == 60 then
    log("progress " .. tostring(a1:progress()) .. " " .. tostring(a1.duration) .. " " .. tostring(a1.delay))
    fh:close()
  end
end
