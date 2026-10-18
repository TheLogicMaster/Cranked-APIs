-- capture playdate.drawFPS output (working frame buffer) at several refresh rates and positions
local gfx = playdate.graphics
local rates = { 10, 21, 32, 43, 14, 25, 36, 47, 18, 29, 50, 5, 0 }
local idx, t0 = 1, playdate.getCurrentTimeMilliseconds()
local f = playdate.file.open("fps.txt", playdate.file.kFileWrite)
local pos = { {0, 0}, {101, 57}, {383, 228} }
playdate.display.setRefreshRate(rates[1])
local function region(img, x0, y0, w, h)
    local rows = {}
    for y = y0, y0 + h - 1 do
        local r = {}
        for x = x0, x0 + w - 1 do
            local c = (x >= 0 and y >= 0 and x < 400 and y < 240) and img:sample(x, y) or gfx.kColorClear
            r[#r + 1] = c == gfx.kColorBlack and "#" or (c == gfx.kColorWhite and "." or "?")
        end
        rows[#rows + 1] = table.concat(r)
    end
    return table.concat(rows, "/")
end
local n = 0
function playdate.update()
    n += 1
    local now = playdate.getCurrentTimeMilliseconds()
    gfx.clear(gfx.kColorBlack)
    for i, p in ipairs(pos) do playdate.drawFPS(p[1], p[2]) end
    -- with a draw offset and a clip rect: screen coordinates expected
    gfx.setDrawOffset(13, 7); gfx.setClipRect(0, 0, 5, 5)
    playdate.drawFPS(200, 150)
    gfx.clearClipRect(); gfx.setDrawOffset(0, 0)
    local elapsed = now - t0
    if elapsed > 1500 and n % 3 == 0 then
        local img = gfx.getWorkingImage()
        local s = {}
        for i, p in ipairs(pos) do s[#s + 1] = region(img, p[1] - 2, p[2] - 2, 19, 16) end
        s[#s + 1] = region(img, 198, 148, 19, 16)
        s[#s + 1] = region(img, 211, 155, 19, 16)
        f:write(string.format("rate=%d fps=%.3f n=%d\t%s\n", rates[idx], playdate.getFPS(), n, table.concat(s, "\t"))); f:flush()
    end
    if elapsed > 3000 then
        idx += 1
        if idx > #rates then f:close(); playdate.display.setRefreshRate(30); playdate.stop(); return end
        playdate.display.setRefreshRate(rates[idx]); t0 = now
    end
end
