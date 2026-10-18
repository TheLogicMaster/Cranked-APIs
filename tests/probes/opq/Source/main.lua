-- Probe: sprite opaque flag after setImage with images with and without masks, and image.new mask presence
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function w(s) fh:write(s .. "\n") end
local imgs = { clear = gfx.image.new(10, 10), clear2 = gfx.image.new(10, 10, gfx.kColorClear), black = gfx.image.new(10, 10, gfx.kColorBlack), white = gfx.image.new(10, 10, gfx.kColorWhite) }
for _, k in ipairs({"clear", "clear2", "black", "white"}) do
  local im = imgs[k]
  local s = gfx.sprite.new() w(k .. " hasMask=" .. tostring(im:hasMask()) .. " new=" .. tostring(s:isOpaque()))
  s:setImage(im) w(k .. " after setImage " .. tostring(s:isOpaque()))
  local s2 = gfx.sprite.new(im) w(k .. " sprite.new(img) " .. tostring(s2:isOpaque()))
  s2:setOpaque(true) w(k .. " setOpaque(true) " .. tostring(s2:isOpaque()))
  s2:setImage(im) w(k .. " setImage again " .. tostring(s2:isOpaque()))
end
local c = gfx.image.new(10, 10)
gfx.pushContext(c) imgs.black:draw(0, 0) gfx.popContext()
w("composited hasMask=" .. tostring(c:hasMask()))
local s3 = gfx.sprite.new() s3:setTilemap(gfx.tilemap.new()) w("tilemap " .. tostring(s3:isOpaque()))
fh:close()
function playdate.update() end
