local gfx = playdate.graphics
local out = {}
for _, s in ipairs({ "a", "b", "*b*", "*a*", "a*b*", "*a*b", "a*b", "ab*", "a*bb*", "aa*b*", "a_b_", "*a*_b_", "a*b* ", "a*b*x" }) do
    local w, h = gfx.getTextSize(s)
    out[#out + 1] = "[" .. s .. "] width " .. w
end
local f = playdate.file.open("tw.txt", playdate.file.kFileWrite); f:write(table.concat(out, "\n") .. "\n"); f:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
