-- Probe: a sprite's opaque flag after rotation and scaling
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local img = gfx.image.new(20, 10, gfx.kColorBlack)
local s = gfx.sprite.new(img)
local function w(label) fh:write(label .. " opaque=" .. tostring(s:isOpaque()) .. " img=" .. tostring(s:getImage() == img) .. "\n") end
w("new")
s:setRotation(30) w("rot30")
s:setRotation(90) w("rot90")
s:setRotation(0) w("rot0")
s:setScale(2) w("scale2")
s:setScale(1) w("scale1")
s:setOpaque(true) s:setRotation(45) w("setOpaque then rot45")
s:setRotation(0) w("rot0 again")
s:setImage(img, 0, 2) w("setImage scale2")
s:setImage(img, 0, 1) w("setImage scale1")
local m = gfx.image.new(20, 10)
s:setImage(m) w("masked")
s:setRotation(30) w("masked rot30")
s:setRotation(0) s:setOpaque(true) s:setRotation(30) w("masked opaque rot30")
fh:close()
function playdate.update() end
