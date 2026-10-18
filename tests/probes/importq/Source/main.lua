-- Probe: whether a second import of the same file runs it again, from main and from another file
import "CoreLibs/sprites"
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local f1 = playdate.graphics.sprite.setBackgroundDrawingCallback
playdate.graphics.sprite.setBackgroundDrawingCallback = function() end
local mine = playdate.graphics.sprite.setBackgroundDrawingCallback
counter = 0
import "mod"
fh:write("after mod: same=" .. tostring(playdate.graphics.sprite.setBackgroundDrawingCallback == mine) .. " orig=" .. tostring(playdate.graphics.sprite.setBackgroundDrawingCallback == f1) .. " counter=" .. counter .. "\n")
import "mod"
fh:write("mod twice: counter=" .. counter .. "\n")
import "CoreLibs/sprites"
fh:write("main again: same=" .. tostring(playdate.graphics.sprite.setBackgroundDrawingCallback == mine) .. "\n")
fh:close()
function playdate.update() end
