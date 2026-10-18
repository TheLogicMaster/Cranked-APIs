-- Probe: in which frame things set up in the main chunk first run: a sprite's update, timers, frame timers,
-- setAlwaysRedraw sprites, and a sprite added by a timer
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/frameTimer"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local n = 0
local function log(s) fh:write(n .. " " .. s .. "\n") end
local s = gfx.sprite.new() s:setSize(10, 10) s:moveTo(20, 20) s:add()
function s:update() log("sprite update") end
gfx.sprite.setAlwaysRedraw(true)
playdate.timer.performAfterDelay(0, function() log("timer 0") end)
playdate.timer.performAfterDelay(1, function() log("timer 1") end)
playdate.timer.performAfterDelay(40, function() log("timer 40") end)
playdate.frameTimer.performAfterDelay(1, function() log("frametimer 1") end)
playdate.frameTimer.performAfterDelay(0, function() log("frametimer 0") end)
local t0 = playdate.getCurrentTimeMilliseconds()
function playdate.update()
  n += 1
  log("update")
  gfx.sprite.update()
  playdate.timer.updateTimers()
  playdate.frameTimer.updateTimers()
  if n == 6 then fh:close() end
end
