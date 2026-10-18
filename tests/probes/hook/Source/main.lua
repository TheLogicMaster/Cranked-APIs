-- Probe: can a game replace playdate.graphics functions?
local gfx = playdate.graphics
local out = {}
local called = 0
local orig = gfx.setPattern
gfx.setPattern = function(...) called = called + 1; return orig(...) end
gfx.setPattern({ 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF })
out[#out + 1] = "after assign: replaced=" .. tostring(gfx.setPattern ~= orig) .. " wrapper called=" .. called
out[#out + 1] = "rawget same=" .. tostring(rawget(gfx, "setPattern") == gfx.setPattern) .. " mt=" .. tostring(getmetatable(gfx) ~= nil)
local f = playdate.file.open("w.txt", playdate.file.kFileAppend); out[#out + 1] = "append open=" .. tostring(f ~= nil); if f then f:write("x\n"); f:close() end
local fh = playdate.file.open("hook.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
