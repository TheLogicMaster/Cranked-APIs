-- Probe: playdate.scoreboards in the Simulator (offline): the functions present, what they return, and when
-- and with what their callbacks run.
local out, frame = {}, 0
local function dump(v, depth)
  depth = depth or 0
  if type(v) ~= "table" or depth > 3 then return tostring(v) end
  local keys = {}; for k in pairs(v) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  local t = {}; for _, k in ipairs(keys) do t[#t + 1] = tostring(k) .. "=" .. dump(v[k], depth + 1) end
  return "{" .. table.concat(t, ",") .. "}"
end
out[#out + 1] = "type " .. type(playdate.scoreboards)
if playdate.scoreboards then
  local names = {}; for k, v in pairs(playdate.scoreboards) do names[#names + 1] = k .. ":" .. type(v) end; table.sort(names)
  out[#out + 1] = "members " .. table.concat(names, " ")
  local function cb(name) return function(...) local a = { ... }; out[#out + 1] = string.format("frame %d %s n=%d %s", frame, name, select("#", ...), dump(a)) end end
  out[#out + 1] = "ret getScores " .. dump({ pcall(playdate.scoreboards.getScores, "highscores", cb("getScores")) })
  out[#out + 1] = "ret addScore " .. dump({ pcall(playdate.scoreboards.addScore, "highscores", 123, cb("addScore")) })
  out[#out + 1] = "ret getPersonalBest " .. dump({ pcall(playdate.scoreboards.getPersonalBest, "highscores", cb("getPersonalBest")) })
  out[#out + 1] = "ret getScoreboards " .. dump({ pcall(playdate.scoreboards.getScoreboards, cb("getScoreboards")) })
end
function playdate.update()
  frame = frame + 1
  if frame == 90 then
    local fh = playdate.file.open("scoreb.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
    if playdate.simulator then playdate.simulator.exit() end
    playdate.stop()
  end
end
