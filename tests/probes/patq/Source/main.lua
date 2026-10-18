-- Probe: setPattern rows (0x55 drawn as 0xAA in the Simulator)
local gfx = playdate.graphics
local out = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function dump(name, img)
    local w, h = img:getSize(); local rows = {}
    for y = 0, h - 1 do local r = {} for x = 0, w - 1 do r[#r + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or "0" end rows[#rows + 1] = table.concat(r) end
    out:write(name .. "\t" .. table.concat(rows, "/") .. "\n")
end
local pats = { {0x55}, {0xAA}, {0x0A}, {0xA0}, {0xAA, 0x55}, {0x55, 0xAA}, {0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80}, {0xF0, 0x0F, 0xCC, 0x33, 0x81, 0x18, 0xE7, 0x7E} }
for i, p in ipairs(pats) do
    local full = {}
    for k = 1, 8 do full[k] = p[(k - 1) % #p + 1] end
    for _, off in ipairs({ {0, 0}, {1, 0}, {3, 5} }) do
        local img = gfx.image.new(16, 8, gfx.kColorWhite)
        gfx.pushContext(img); gfx.setPattern(full); gfx.fillRect(off[1], off[2], 16, 8); gfx.popContext()
        dump(string.format("pattern %d off %d,%d", i, off[1], off[2]), img)
    end
    local img = gfx.image.new(16, 8, gfx.kColorWhite)
    gfx.pushContext(img); gfx.setPattern(full); gfx.fillRect(0, 0, 16, 8); gfx.popContext()
    dump(string.format("pattern %d plain", i), img)
end
-- the frame buffer at an odd position
gfx.setPattern({0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55}); gfx.fillRect(3, 3, 16, 8)
dump("screen 0x55", gfx.getDisplayImage():copy())
out:close()
function playdate.update() end
