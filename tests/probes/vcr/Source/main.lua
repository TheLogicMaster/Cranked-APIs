-- Probe: vcrPauseFilterImage on larger images, consecutive calls (global LFSR)
local gfx = playdate.graphics
local f = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function dump(img)
    local w, h = img:getSize()
    local rows = {}
    for y = 0, h - 1 do
        local r = {}
        for x = 0, w - 1 do local c = img:sample(x, y); r[#r + 1] = c == gfx.kColorBlack and "0" or (c == gfx.kColorWhite and "1" or "x") end
        rows[#rows + 1] = table.concat(r)
    end
    return w .. "x" .. h .. ":" .. table.concat(rows, "/")
end
local function pattern(w, h, clear)
    local img = gfx.image.new(w, h, clear and gfx.kColorClear or gfx.kColorWhite)
    gfx.pushContext(img)
    gfx.setColor(gfx.kColorBlack)
    for i = 0, w + h, 7 do gfx.drawLine(i, 0, i - h, h) end
    gfx.fillRect(w // 3, h // 3, w // 3, h // 3)
    gfx.popContext()
    return img
end
local cases = { {400, 240}, {37, 19}, {64, 64}, {1, 9}, {33, 250}, {120, 240, true}, {400, 240} }
for i, c in ipairs(cases) do
    local srcimg = pattern(c[1], c[2], c[3])
    f:write("src" .. i .. "\t" .. dump(srcimg) .. "\n")
    local out = srcimg:vcrPauseFilterImage()
    f:write("case" .. i .. "\t" .. dump(out) .. "\n"); f:flush()
end
f:close()
playdate.stop()
function playdate.update() end
