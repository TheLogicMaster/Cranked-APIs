-- Probe: playdate.restart(args): does the game start again, what argv it gets, and when the restart happens
local runs = playdate.datastore.read("runs") or { n = 0 }
runs.n = runs.n + 1
playdate.datastore.write(runs, "runs")
local fh = playdate.file.open("out" .. runs.n .. ".txt", playdate.file.kFileWrite)
local a = {} for i, v in ipairs(playdate.argv or {}) do a[#a + 1] = "[" .. tostring(v) .. "]" end
fh:write("run " .. runs.n .. " argv " .. #(playdate.argv or {}) .. " " .. table.concat(a, " ") .. " global=" .. tostring(rawget(_G, "survivor")) .. "\n")
survivor = runs.n
local frame = 0
function playdate.update()
  frame = frame + 1
  if frame == 3 and runs.n == 1 then fh:write("restarting\n") fh:flush() playdate.restart("alpha beta  gamma") fh:write("after restart call, frame " .. frame .. "\n") fh:flush() end
  if frame == 3 and runs.n == 2 then fh:write("restarting with no args\n") fh:flush() playdate.restart() end
  if frame == 4 then fh:write("frame 4 reached in run " .. runs.n .. "\n") fh:close() end
end
