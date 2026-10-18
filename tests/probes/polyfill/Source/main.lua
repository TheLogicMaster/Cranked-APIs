local gfx = playdate.graphics
local out = {}
local function dump(img) local rows = {}; for y = 0, 23 do local b = {}; for x = 0, 23 do b[#b + 1] = img:sample(x, y) == gfx.kColorBlack and "0" or "1" end; rows[#rows + 1] = table.concat(b) end; return table.concat(rows, "/") end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(15, 5, 23, 18, 9, 6); gfx.popContext(); out[#out + 1] = "0\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(23, 13, 22, 8, 17, 7); gfx.popContext(); out[#out + 1] = "1\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(20, 23, 15, 11, 13, 16); gfx.popContext(); out[#out + 1] = "2\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(23, 19, 6, 9, 17, 22); gfx.popContext(); out[#out + 1] = "3\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(10, 16, 2, 23, 6, 22); gfx.popContext(); out[#out + 1] = "4\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(23, 14, 22, 20, 4, 17); gfx.popContext(); out[#out + 1] = "5\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(6, 13, 1, 11, 20, 13); gfx.popContext(); out[#out + 1] = "6\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(14, 3, 23, 23, 4, 10); gfx.popContext(); out[#out + 1] = "7\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(12, 10, 11, 6, 10, 13); gfx.popContext(); out[#out + 1] = "8\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(13, 10, 18, 6, 13, 7); gfx.popContext(); out[#out + 1] = "9\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(6, 1, 23, 7, 0, 8); gfx.popContext(); out[#out + 1] = "10\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(16, 10, 18, 22, 13, 19); gfx.popContext(); out[#out + 1] = "11\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(3, 10, 20, 19, 7, 7); gfx.popContext(); out[#out + 1] = "12\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(14, 11, 4, 6, 11, 15); gfx.popContext(); out[#out + 1] = "13\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(19, 20, 4, 8, 12, 19); gfx.popContext(); out[#out + 1] = "14\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(10, 10, 22, 22, 14, 5); gfx.popContext(); out[#out + 1] = "15\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(21, 22, 4, 10, 6, 18); gfx.popContext(); out[#out + 1] = "16\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(21, 2, 3, 5, 0, 4); gfx.popContext(); out[#out + 1] = "17\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(14, 22, 7, 11, 7, 2); gfx.popContext(); out[#out + 1] = "18\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(6, 9, 7, 22, 14, 19); gfx.popContext(); out[#out + 1] = "19\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(8, 15, 16, 13, 21, 13); gfx.popContext(); out[#out + 1] = "20\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(6, 2, 9, 9, 8, 4); gfx.popContext(); out[#out + 1] = "21\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(18, 21, 23, 8, 16, 3); gfx.popContext(); out[#out + 1] = "22\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(15, 6, 6, 12, 5, 16); gfx.popContext(); out[#out + 1] = "23\t" .. dump(img) end
local f = playdate.file.open("h.txt", playdate.file.kFileWrite); f:write(table.concat(out, "\n") .. "\n"); f:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
