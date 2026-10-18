local names = {}
for k, v in pairs(playdate.graphics.sprite) do if type(v) == "function" then names[#names + 1] = k end end
table.sort(names)
local f = playdate.file.open("spm.txt", playdate.file.kFileWrite); f:write(table.concat(names, "\n") .. "\n"); f:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
