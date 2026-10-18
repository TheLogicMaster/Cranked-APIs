import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "cases8"
local f = playdate.file.open("out8.txt", playdate.file.kFileWrite)
runCases8(function(s) f:write(s .. "\n"); f:flush() end)
f:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
