-- Probe: accelerometer values and running state before, during, and after start/stop, over frames.
local out, frame = {}, 0
local function rec(tag) local x, y, z = playdate.readAccelerometer(); out[#out + 1] = string.format("%d %s run=%s %s %s %s", frame, tag, tostring(playdate.accelerometerIsRunning()), tostring(x), tostring(y), tostring(z)) end
rec("load")
function playdate.update()
  frame = frame + 1
  if frame == 2 then playdate.startAccelerometer(); rec("afterstart") end
  if frame >= 2 and frame <= 6 then rec("tick") end
  if frame == 7 then playdate.stopAccelerometer(); rec("afterstop") end
  if frame == 8 then rec("later")
    local fh = playdate.file.open("accel.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
    if playdate.simulator then playdate.simulator.exit() end
    playdate.stop()
  end
end
