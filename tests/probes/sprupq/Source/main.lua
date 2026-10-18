-- Probe: sprite:update() on an instance (no override) versus gfx.sprite.update(); super.update from a subclass
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function log(s) fh:write(s .. "\n") fh:flush() end
local p = gfx.image.new("cursor")
class("Sub").extends(gfx.sprite)
local subCalls = 0
function Sub:update() subCalls += 1 Sub.super.update(self) end
local n = 0
local s1, s2, s3
local function hash()
  local img = gfx.getWorkingImage() local b, sum = 0, 0
  for y = 0, 239 do for x = 0, 399 do if img:sample(x, y) == gfx.kColorBlack then b += 1 sum = (sum * 31 + x * 7 + y) % 1000003 end end end
  return b, sum
end
local upd = 0
function playdate.update()
  n += 1
  if n == 1 then s1 = gfx.sprite.new(p) s1:moveTo(100, 100) s1:add() s2 = gfx.sprite.new(p) s2:moveTo(200, 100) s2:add()
    function s2:update() upd += 1 end end
  if n == 6 then s3 = Sub() s3:setImage(p) s3:moveTo(300, 50) s3:add() end
  if n == 8 then s1:moveTo(120, 140) end
  if n < 4 then s1:update()
  elseif n < 6 then gfx.sprite.update(nil)
  elseif n < 8 then gfx.sprite.update()
  elseif n < 10 then s3:update()
  elseif n < 12 then gfx.sprite.update(s1, s2)
  else gfx.sprite.update(5) end
  local b, h = hash()
  log(string.format("n=%d black=%d hash=%d upd=%d sub=%d", n, b, h, upd, subCalls))
  if n == 13 then fh:close() end
end
