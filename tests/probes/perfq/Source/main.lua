import "CoreLibs/graphics"
-- Probe: cost of common calls (milliseconds for many iterations)
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function t(name, n, f) local t0 = playdate.getCurrentTimeMilliseconds() for i = 1, n do f(i) end fh:write(name .. " " .. (playdate.getCurrentTimeMilliseconds() - t0) .. "\n") end
local img = gfx.image.new(400, 240, gfx.kColorWhite)
local small = gfx.image.new(16, 16, gfx.kColorBlack)
t("sample 96000", 96000, function(i) img:sample(i % 400, i % 240) end)
t("lua loop 1e6", 1000000, function(i) end)
t("math.sin 1e5", 100000, function(i) math.sin(i) end)
t("drawPixel 1e5", 100000, function(i) gfx.drawPixel(i % 400, i % 240) end)
t("small draw 2e4", 20000, function(i) small:draw(i % 380, i % 220) end)
t("fillRect 1e4", 10000, function(i) gfx.fillRect(i % 300, i % 200, 50, 30) end)
t("drawText 2e3", 2000, function(i) gfx.drawText("Hello world", 10, 10) end)
t("getDisplayImage 100", 100, function(i) gfx.getDisplayImage() end)
t("table alloc 1e5", 100000, function(i) local x = {i, i + 1} end)
t("string concat 1e5", 100000, function(i) local s = "a" .. i end)
t("fillCircle 2e3", 2000, function(i) gfx.fillCircleAtPoint(200, 120, 50) end)
t("rotated draw 300", 300, function(i) small:drawRotated(200, 120, i) end)
fh:close()
function playdate.update() end
