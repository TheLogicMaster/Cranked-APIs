-- Probe: sprite.clearClipRectsInRange with a sprite the last update drew (frame 3), and then with an empty display
-- list after that sprite was removed (frame 6). Each frame is logged, so the output shows whether the game keeps
-- running after each call.
local gfx = playdate.graphics
local frame = 0
local function log(t) local f = playdate.file.open("out.txt", playdate.file.kFileAppend) f:write(t .. "\n") f:close() end
playdate.file.delete("out.txt")
local s = gfx.sprite.new()
s:setSize(10, 10) s:moveTo(50, 50) s:setZIndex(3) s:add()
function playdate.update()
  frame += 1
  gfx.sprite.update()
  log("frame " .. frame .. " sprites " .. gfx.sprite.spriteCount())
  if frame == 3 then
    gfx.sprite.setClipRectsInRange(0, 0, 20, 20, 1, 5) log("set")
    gfx.sprite.clearClipRectsInRange(1, 5) log("cleared")
  end
  if frame == 5 then s:remove() log("removed") end
  if frame == 6 then gfx.sprite.clearClipRectsInRange(1, 5) log("cleared with no sprites") end
  if frame == 10 then log("done") if playdate.simulator then playdate.simulator.exit() end playdate.stop() end
end
