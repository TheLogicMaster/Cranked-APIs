local gfx = playdate.graphics
local out = {}
local function dump(img) local rows = {}; for y = 0, 23 do local b = {}; for x = 0, 23 do b[#b + 1] = img:sample(x, y) == gfx.kColorBlack and "0" or "1" end; rows[#rows + 1] = table.concat(b) end; return table.concat(rows, "/") end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillEllipseInRect(2, 2, 20, 20, 231, 286); gfx.popContext(); out[#out + 1] = "F0\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.drawEllipseInRect(2, 2, 20, 20, 231, 286); gfx.popContext(); out[#out + 1] = "O0\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillEllipseInRect(2, 2, 20, 20, 238, 231); gfx.popContext(); out[#out + 1] = "F1\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.drawEllipseInRect(2, 2, 20, 20, 238, 231); gfx.popContext(); out[#out + 1] = "O1\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillEllipseInRect(2, 2, 20, 20, 260, 300); gfx.popContext(); out[#out + 1] = "F2\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.drawEllipseInRect(2, 2, 20, 20, 260, 300); gfx.popContext(); out[#out + 1] = "O2\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillEllipseInRect(2, 2, 20, 20, 97, 94); gfx.popContext(); out[#out + 1] = "F3\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.drawEllipseInRect(2, 2, 20, 20, 97, 94); gfx.popContext(); out[#out + 1] = "O3\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillEllipseInRect(2, 2, 20, 20, 262, 243); gfx.popContext(); out[#out + 1] = "F4\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.drawEllipseInRect(2, 2, 20, 20, 262, 243); gfx.popContext(); out[#out + 1] = "O4\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillEllipseInRect(2, 2, 20, 20, 322, 314); gfx.popContext(); out[#out + 1] = "F5\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.drawEllipseInRect(2, 2, 20, 20, 322, 314); gfx.popContext(); out[#out + 1] = "O5\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillEllipseInRect(2, 2, 20, 20, 95, 48); gfx.popContext(); out[#out + 1] = "F6\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.drawEllipseInRect(2, 2, 20, 20, 95, 48); gfx.popContext(); out[#out + 1] = "O6\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillEllipseInRect(2, 2, 20, 20, 228, 155); gfx.popContext(); out[#out + 1] = "F7\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.drawEllipseInRect(2, 2, 20, 20, 228, 155); gfx.popContext(); out[#out + 1] = "O7\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillEllipseInRect(2, 2, 20, 20, 72, 46); gfx.popContext(); out[#out + 1] = "F8\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.drawEllipseInRect(2, 2, 20, 20, 72, 46); gfx.popContext(); out[#out + 1] = "O8\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillEllipseInRect(2, 2, 20, 20, 275, 355); gfx.popContext(); out[#out + 1] = "F9\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.drawEllipseInRect(2, 2, 20, 20, 275, 355); gfx.popContext(); out[#out + 1] = "O9\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillEllipseInRect(2, 2, 20, 20, 324, 21); gfx.popContext(); out[#out + 1] = "F10\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.drawEllipseInRect(2, 2, 20, 20, 324, 21); gfx.popContext(); out[#out + 1] = "O10\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillEllipseInRect(2, 2, 20, 20, 304, 202); gfx.popContext(); out[#out + 1] = "F11\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.drawEllipseInRect(2, 2, 20, 20, 304, 202); gfx.popContext(); out[#out + 1] = "O11\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillEllipseInRect(2, 2, 20, 20, 231, 334); gfx.popContext(); out[#out + 1] = "F12\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.drawEllipseInRect(2, 2, 20, 20, 231, 334); gfx.popContext(); out[#out + 1] = "O12\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillEllipseInRect(2, 2, 20, 20, 315, 332); gfx.popContext(); out[#out + 1] = "F13\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.drawEllipseInRect(2, 2, 20, 20, 315, 332); gfx.popContext(); out[#out + 1] = "O13\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillEllipseInRect(2, 2, 20, 20, 80, 319); gfx.popContext(); out[#out + 1] = "F14\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.drawEllipseInRect(2, 2, 20, 20, 80, 319); gfx.popContext(); out[#out + 1] = "O14\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillEllipseInRect(2, 2, 20, 20, 7, 270); gfx.popContext(); out[#out + 1] = "F15\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.drawEllipseInRect(2, 2, 20, 20, 7, 270); gfx.popContext(); out[#out + 1] = "O15\t" .. dump(img) end
local f = playdate.file.open("pies.txt", playdate.file.kFileWrite); f:write(table.concat(out, "\n") .. "\n"); f:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
