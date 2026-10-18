-- Probe: what font:drawText returns, beside gfx.drawText
local gfx = playdate.graphics
local out = playdate.file.open("out.txt", playdate.file.kFileWrite)
local f = gfx.getSystemFont()
local img = gfx.image.new(400, 240)
gfx.pushContext(img)
local cases = {
    { "Hello", 0, 0 }, { "a", 0, 0 }, { "H", 0, 0 }, { " ", 0, 0 }, { "Hello\nWorld", 10, 10 },
    { "Hello world this wraps", 0, 0, 60, 80 }, { "Hello world this wraps", 0, 0, 60, 80, 3 },
}
local function sig(im)
    local h = 0
    for y = 0, 99 do for x = 0, 119 do if im:sample(x, y) == gfx.kColorBlack then h = (h * 31 + x * 7 + y * 13) % 1000000007 end end end
    return h
end
gfx.popContext()
for i, c in ipairs(cases) do
    local im = gfx.image.new(120, 100, gfx.kColorWhite)
    gfx.pushContext(im); f:drawText(table.unpack(c)); gfx.popContext()
    out:write(string.format("pixels %d\t%d\n", i, sig(im)))
end
gfx.pushContext(img)
for i, c in ipairs(cases) do
    local w1, h1 = f:drawText(table.unpack(c))
    local w2, h2 = gfx.drawText(table.unpack(c))
    out:write(string.format("case %d\tfont %s %s | gfx %s %s\n", i, tostring(w1), tostring(h1), tostring(w2), tostring(h2)))
end
local w, h = f:drawText("Hello", playdate.geometry.rect.new(0, 0, 50, 40))
out:write("rect\t" .. tostring(w) .. " " .. tostring(h) .. "\n")
gfx.popContext()
out:close()
function playdate.update() end
