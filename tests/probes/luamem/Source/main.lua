local out = {}
collectgarbage("collect"); local base = collectgarbage("count")
out[#out + 1] = string.format("baseline %.0f KB", base)
local arr = {}; for i = 1, 100000 do arr[i] = i * 0.5 end
collectgarbage("collect"); out[#out + 1] = string.format("array of 100000 numbers: +%.0f KB", collectgarbage("count") - base)
local before = collectgarbage("count")
local recs = {}; for i = 1, 20000 do recs[i] = { x = i, y = i, id = i } end
collectgarbage("collect"); out[#out + 1] = string.format("20000 records {x, y, id}: +%.0f KB", collectgarbage("count") - before)
before = collectgarbage("count")
local map = {}; for i = 1, 20000 do map["key" .. i] = i end
collectgarbage("collect"); out[#out + 1] = string.format("map of 20000 string keys: +%.0f KB", collectgarbage("count") - before)
local f = playdate.file.open("mem.txt", playdate.file.kFileWrite); f:write(table.concat(out, "\n") .. "\n"); f:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
