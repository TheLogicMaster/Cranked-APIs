local gfx = playdate.graphics
local out = {}
local function dump(img) local rows = {}; for y = 0, 23 do local b = {}; for x = 0, 23 do b[#b + 1] = img:sample(x, y) == gfx.kColorBlack and "0" or "1" end; rows[#rows + 1] = table.concat(b) end; return table.concat(rows, "/") end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(2, 2, 2, 20, 5, 20); gfx.popContext(); out[#out + 1] = "0\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(22, 2, 22, 20, 19, 20); gfx.popContext(); out[#out + 1] = "1\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(2, 2, 2, 20, 7, 20); gfx.popContext(); out[#out + 1] = "2\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(22, 2, 22, 20, 17, 20); gfx.popContext(); out[#out + 1] = "3\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(2, 2, 2, 20, 9, 20); gfx.popContext(); out[#out + 1] = "4\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(22, 2, 22, 20, 15, 20); gfx.popContext(); out[#out + 1] = "5\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(2, 2, 2, 20, 11, 20); gfx.popContext(); out[#out + 1] = "6\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(22, 2, 22, 20, 13, 20); gfx.popContext(); out[#out + 1] = "7\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(2, 2, 2, 20, 15, 20); gfx.popContext(); out[#out + 1] = "8\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(22, 2, 22, 20, 9, 20); gfx.popContext(); out[#out + 1] = "9\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(2, 2, 2, 20, 19, 20); gfx.popContext(); out[#out + 1] = "10\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(22, 2, 22, 20, 5, 20); gfx.popContext(); out[#out + 1] = "11\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(2, 2, 2, 5, 20, 5); gfx.popContext(); out[#out + 1] = "12\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(22, 2, 22, 5, 4, 5); gfx.popContext(); out[#out + 1] = "13\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(2, 2, 2, 8, 20, 8); gfx.popContext(); out[#out + 1] = "14\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(22, 2, 22, 8, 4, 8); gfx.popContext(); out[#out + 1] = "15\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(2, 2, 2, 11, 20, 11); gfx.popContext(); out[#out + 1] = "16\t" .. dump(img) end
do local img = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillPolygon(22, 2, 22, 11, 4, 11); gfx.popContext(); out[#out + 1] = "17\t" .. dump(img) end
local f = playdate.file.open("edges.txt", playdate.file.kFileWrite); f:write(table.concat(out, "\n") .. "\n"); f:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
