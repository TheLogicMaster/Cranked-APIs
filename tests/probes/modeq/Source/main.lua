-- Probe (with src/main.c): the C draw mode and Lua's image draw mode
local gfx = playdate.graphics
local out = playdate.file.open("modeq.txt", playdate.file.kFileWrite)
local function log(s) out:write(s .. "\n") end
gfx.setImageDrawMode(gfx.kDrawModeXOR)
log("C sees after Lua XOR: " .. cmode(gfx.kDrawModeInverted))
log("Lua sees after C Inverted: " .. tostring(gfx.getImageDrawMode()))
log("C sees its own previous: " .. cmode(gfx.kDrawModeFillWhite))
gfx.setImageDrawMode(gfx.kDrawModeCopy)
log("C sees after Lua Copy: " .. cmode(gfx.kDrawModeCopy))
out:close()
function playdate.update() end
