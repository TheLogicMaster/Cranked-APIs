local gfx = playdate.graphics
local out = {}
local function dump(img) local rows = {}; for y = 0, 23 do local b = {}; for x = 0, 23 do b[#b + 1] = img:sample(x, y) == gfx.kColorBlack and "0" or "1" end; rows[#rows + 1] = table.concat(b) end; return table.concat(rows, "/") end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(10, 4, 12, 20, 1, 2); gfx.popContext(); out[#out + 1] = "0\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(17, 3, 11, 18, 1, 16); gfx.popContext(); out[#out + 1] = "1\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(6, 1, 2, 13, 13, 2); gfx.popContext(); out[#out + 1] = "2\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(7, 2, 17, 13, 1, 18); gfx.popContext(); out[#out + 1] = "3\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(3, 7, 20, 20, 18, 1); gfx.popContext(); out[#out + 1] = "4\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(18, 18, 12, 1, 7, 1); gfx.popContext(); out[#out + 1] = "5\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(17, 4, 9, 13, 4, 17); gfx.popContext(); out[#out + 1] = "6\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(3, 18, 9, 17, 21, 5); gfx.popContext(); out[#out + 1] = "7\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(3, 18, 18, 20, 6, 11); gfx.popContext(); out[#out + 1] = "8\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(3, 17, 22, 2, 18, 1); gfx.popContext(); out[#out + 1] = "9\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(19, 6, 15, 21, 17, 13); gfx.popContext(); out[#out + 1] = "10\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(10, 14, 18, 14, 11, 9); gfx.popContext(); out[#out + 1] = "11\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(7, 5, 22, 7, 2, 18); gfx.popContext(); out[#out + 1] = "12\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(9, 16, 15, 10, 23, 14); gfx.popContext(); out[#out + 1] = "13\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(9, 19, 2, 3, 16, 13); gfx.popContext(); out[#out + 1] = "14\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(5, 10, 4, 15, 13, 1); gfx.popContext(); out[#out + 1] = "15\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(21, 2, 17, 18, 10, 10); gfx.popContext(); out[#out + 1] = "16\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(22, 11, 19, 15, 18, 14); gfx.popContext(); out[#out + 1] = "17\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(2, 2, 8, 15, 22, 21); gfx.popContext(); out[#out + 1] = "18\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(2, 1, 23, 22, 9, 20); gfx.popContext(); out[#out + 1] = "19\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(18, 21, 14, 9, 22, 12); gfx.popContext(); out[#out + 1] = "20\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(21, 11, 0, 14, 11, 5); gfx.popContext(); out[#out + 1] = "21\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(19, 3, 15, 1, 6, 9); gfx.popContext(); out[#out + 1] = "22\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(4, 23, 7, 12, 12, 15); gfx.popContext(); out[#out + 1] = "23\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(2, 5, 14, 12, 17, 8, 4, 13); gfx.popContext(); out[#out + 1] = "24\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(17, 8, 22, 13, 11, 21, 12, 7); gfx.popContext(); out[#out + 1] = "25\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(4, 2, 5, 4, 7, 21, 7, 0); gfx.popContext(); out[#out + 1] = "26\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(15, 18, 5, 8, 9, 0, 4, 13); gfx.popContext(); out[#out + 1] = "27\t" .. dump(img) end
local f = playdate.file.open("polys.txt", playdate.file.kFileWrite); f:write(table.concat(out, "\n") .. "\n"); f:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
