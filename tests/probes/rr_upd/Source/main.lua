import "CoreLibs/graphics"
import "cases6"
local skip = {}
for _, n in ipairs({ "out6.txt", "skip.txt" }) do local f = playdate.file.open(n); if f then while true do local l = f:readline(); if not l then break end; local k = l:match("^([^\t]+)"); if k then skip[k] = true end end; f:close() end end
local function go() local f = playdate.file.open("out6.txt", playdate.file.kFileAppend); runCases6(function(s) f:write(s .. "\n"); f:flush() end, skip); f:close(); playdate.stop() end
local done = false; function playdate.update() if not done then done = true; go() end end
