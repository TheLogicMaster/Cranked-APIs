-- Probe: do drawing calls with huge coordinates take time proportional to the coordinates? (Simulator only)
local gfx = playdate.graphics
local f = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function t(name, fn)
    local img = gfx.image.new(64, 64, gfx.kColorWhite)
    gfx.pushContext(img); gfx.setColor(gfx.kColorBlack)
    playdate.resetElapsedTime(); fn(); local e = playdate.getElapsedTime()
    gfx.popContext()
    f:write(string.format("%s\t%.6f\n", name, e)); f:flush()
end
for _, n in ipairs({ 1e3, 1e5, 1e6, 1e7, 1e8 }) do
    t("line diag " .. n, function() gfx.drawLine(0, 0, n, n) end)
    t("line horiz " .. n, function() gfx.drawLine(0, 5, n, 5) end)
    t("line steep " .. n, function() gfx.drawLine(5, 0, 6, n) end)
    t("fillRect " .. n, function() gfx.fillRect(0, 0, n, n) end)
    t("drawRect " .. n, function() gfx.drawRect(-n, -n, 2 * n, 2 * n) end)
    t("fillEllipse " .. n, function() gfx.fillEllipseInRect(-n, -n, 2 * n, 2 * n) end)
    t("drawEllipse " .. n, function() gfx.drawEllipseInRect(-n, -n, 2 * n, 2 * n) end)
    t("fillPolygon " .. n, function() gfx.fillPolygon(0, 0, n, 0, 0, n) end)
end
f:close()
playdate.stop()
function playdate.update() end
