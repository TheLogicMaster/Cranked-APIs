-- Probe: power status and battery readings
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local p = playdate.getPowerStatus()
local keys = {} for k in pairs(p) do keys[#keys + 1] = k end table.sort(keys)
for _, k in ipairs(keys) do fh:write(k .. "=" .. tostring(p[k]) .. "\n") end
fh:write("battery " .. tostring(playdate.getBatteryPercentage()) .. " " .. tostring(playdate.getBatteryVoltage()) .. "\n")
fh:close()
function playdate.update() end
