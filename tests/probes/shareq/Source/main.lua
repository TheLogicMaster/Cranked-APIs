-- Probe: whether images given to or taken from containers share pixels with the original (image tables,
-- masks, sprites, tilemaps) after later drawing into either side
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function px(im) return im:sample(1, 1) == gfx.kColorWhite and "w" or (im:sample(1, 1) == gfx.kColorBlack and "b" or "c") end
local function paint(im, c) gfx.pushContext(im) gfx.setColor(c) gfx.fillRect(0, 0, 4, 4) gfx.popContext() end
local img = gfx.image.new(4, 4, gfx.kColorBlack)
local t = gfx.imagetable.new(2)
t:setImage(1, img)
paint(img, gfx.kColorWhite)
fh:write("table after drawing into original: " .. px(t:getImage(1)) .. "\n")
paint(t:getImage(1), gfx.kColorBlack)
fh:write("original after drawing into table image: " .. px(img) .. " table " .. px(t:getImage(1)) .. "\n")
local m = gfx.image.new(4, 4, gfx.kColorClear)
paint(m, gfx.kColorBlack)
local mask = m:getMaskImage()
paint(mask, gfx.kColorBlack)
fh:write("mask drawn black, image pixel: " .. px(m) .. " mask again " .. px(m:getMaskImage()) .. "\n")
local s = gfx.sprite.new(img)
paint(img, gfx.kColorWhite)
fh:write("sprite image after drawing into original: " .. px(s:getImage()) .. "\n")
local a = gfx.image.new(4, 4, gfx.kColorWhite)
local b = gfx.image.new(4, 4, gfx.kColorBlack)
b:setMaskImage(a)
paint(a, gfx.kColorBlack)
fh:write("setMaskImage then mask source drawn black: " .. px(b) .. "\n")
local t2 = gfx.imagetable.new(1)
local c = gfx.image.new(4, 4, gfx.kColorWhite)
t2:setImage(1, c)
fh:write("table:getImage == set: " .. tostring(t2:getImage(1) == c) .. "\n")
c = nil collectgarbage() collectgarbage()
fh:write("table image after original collected: " .. px(t2:getImage(1)) .. "\n")
fh:close()
function playdate.update() end
