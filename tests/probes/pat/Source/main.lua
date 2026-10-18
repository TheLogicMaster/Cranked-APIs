local gfx = playdate.graphics
local out = {}
local function dump(img) local w, h = img:getSize(); local rows = {}; for y = 0, h - 1 do local b = {}; for x = 0, w - 1 do local s = img:sample(x, y); b[#b + 1] = s == gfx.kColorWhite and "1" or (s == gfx.kColorBlack and "0" or "x") end; rows[#rows + 1] = table.concat(b) end; return table.concat(rows, "/") end
local function test(name, pattern)
    local img = gfx.image.new(8, 8, gfx.kColorWhite)
    gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.setPattern(pattern); gfx.fillRect(0, 0, 8, 8); gfx.popContext()
    out[#out + 1] = name .. "\t" .. dump(img)
end
test("aa row0 only", { 0xaa, 0, 0, 0, 0, 0, 0, 0 })
test("a0 row0 only", { 0xa0, 0, 0, 0, 0, 0, 0, 0 })
test("0a row0 only", { 0x0a, 0, 0, 0, 0, 0, 0, 0 })
test("c0 row0 only", { 0xc0, 0, 0, 0, 0, 0, 0, 0 })
test("55 row0 only", { 0x55, 0, 0, 0, 0, 0, 0, 0 })
test("all aa", { 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa })
local f = playdate.file.open("pat.txt", playdate.file.kFileWrite); f:write(table.concat(out, "\n") .. "\n"); f:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
