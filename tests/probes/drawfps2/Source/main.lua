-- drawFPS under a draw offset, a clip rect, an inverted image draw mode, inside an image context;
-- low refresh rates (single digits)
local gfx = playdate.graphics
local rates = { 2, 4, 7, 9, 30 }
local idx, t0 = 1, playdate.getCurrentTimeMilliseconds()
local f = playdate.file.open("fps2.txt", playdate.file.kFileWrite)
playdate.display.setRefreshRate(rates[1])
local function region(img, x0, y0, w, h)
    local rows = {}
    for y = y0, y0 + h - 1 do
        local r = {}
        for x = x0, x0 + w - 1 do
            local c = img:sample(x, y)
            r[#r + 1] = c == gfx.kColorBlack and "#" or (c == gfx.kColorWhite and "." or "?")
        end
        rows[#rows + 1] = table.concat(r)
    end
    return table.concat(rows, "/")
end
local side = gfx.image.new(40, 30, gfx.kColorBlack)
local n = 0
function playdate.update()
    n += 1
    local now = playdate.getCurrentTimeMilliseconds()
    gfx.clear(gfx.kColorBlack)
    playdate.drawFPS(10, 10)                                   -- A reference
    gfx.setDrawOffset(13, 7); playdate.drawFPS(100, 10); gfx.setDrawOffset(0, 0)   -- B offset only
    gfx.setClipRect(200, 10, 8, 6); playdate.drawFPS(200, 10); gfx.clearClipRect() -- C clip only
    gfx.setImageDrawMode(gfx.kDrawModeInverted); playdate.drawFPS(300, 10); gfx.setImageDrawMode(gfx.kDrawModeCopy) -- D inverted
    gfx.pushContext(side); playdate.drawFPS(5, 5); gfx.popContext()                  -- E inside an image context
    gfx.setScreenClipRect(10, 100, 8, 6); playdate.drawFPS(10, 100); gfx.clearClipRect() -- F screen clip
    local elapsed = now - t0
    if elapsed > 2500 and n % 2 == 0 then
        local img = gfx.getWorkingImage()
        local s = { region(img, 8, 8, 19, 16), region(img, 98, 8, 19, 16), region(img, 111, 15, 19, 16), region(img, 198, 8, 19, 16),
                    region(img, 298, 8, 19, 16), region(img, 3, 3, 19, 16), region(side, 3, 3, 19, 16), region(img, 8, 98, 19, 16) }
        f:write(string.format("rate=%d fps=%.3f n=%d\t%s\n", rates[idx], playdate.getFPS(), n, table.concat(s, "\t"))); f:flush()
    end
    if elapsed > 5000 then
        idx += 1
        if idx > #rates then f:close(); playdate.display.setRefreshRate(30); playdate.stop(); return end
        playdate.display.setRefreshRate(rates[idx]); t0 = now
    end
end
