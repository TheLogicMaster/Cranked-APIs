local gfx = playdate.graphics
local out = {}
local ok, f = pcall(gfx.font.new, "GreatVibes-Regular-109")
out[#out + 1] = "load ok=" .. tostring(ok) .. " font=" .. tostring(f ~= nil)
if ok and f then out[#out + 1] = "height " .. f:getHeight() .. " width(A) " .. f:getTextWidth("A") .. " width(Hello) " .. f:getTextWidth("Hello") end
local fh = playdate.file.open("bf.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
