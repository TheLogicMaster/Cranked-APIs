-- Probe: the userval_count field of every class table reachable from playdate
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local seen, list = {}, {}
local function walk(t, path, depth)
  if depth > 4 or seen[t] then return end
  seen[t] = true
  local uc = rawget(t, "userval_count")
  if uc ~= nil then list[#list + 1] = path .. " " .. tostring(uc) end
  local keys = {}
  for k, v in pairs(t) do if type(k) == "string" and type(v) == "table" then keys[#keys + 1] = k end end
  table.sort(keys)
  for _, k in ipairs(keys) do walk(t[k], path .. "." .. k, depth + 1) end
end
walk(playdate, "playdate", 0)
table.sort(list)
for _, l in ipairs(list) do fh:write(l .. "\n") end
fh:close()
function playdate.update() end
