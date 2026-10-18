import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/nineslice"
import "cases4"
local skip = {}
for _, n in ipairs({ "out4.txt", "skip.txt" }) do local f = playdate.file.open(n); if f then while true do local l = f:readline(); if not l then break end; local k = l:match("^([^\t]+)"); if k then skip[k] = true end end; f:close() end end
local function go() local f = playdate.file.open("out4.txt", playdate.file.kFileAppend); runCases4(function(s) f:write(s .. "\n"); f:flush() end, skip); f:close(); playdate.stop() end
go()
