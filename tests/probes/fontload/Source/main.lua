local gfx = playdate.graphics
local out = {}
local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?"
local function widths(f) local w = {}; for i = 1, #chars do w[#w + 1] = f:getTextWidth(chars:sub(i, i)) end; return table.concat(w, ",") end
local bundled = gfx.font.new("Oblique")
out[#out + 1] = "bundled " .. (bundled and widths(bundled) or "nil")
out[#out + 1] = "systemItalic " .. widths(gfx.getSystemFont(gfx.font.kVariantItalic))
out[#out + 1] = "systemNormal " .. widths(gfx.getSystemFont(gfx.font.kVariantNormal))
local f = playdate.file.open("fl.txt", playdate.file.kFileWrite); f:write(table.concat(out, "\n") .. "\n"); f:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
