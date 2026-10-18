-- Probe: math.random's sequence without math.randomseed
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local t = {}
for i = 1, 5 do t[#t + 1] = tostring(math.random(1000000)) end
fh:write("random " .. table.concat(t, ",") .. "\n")
fh:write("randomf " .. string.format("%.6f", math.random()) .. "\n")
fh:close()
function playdate.update() end
