-- Probe: a sprite's image drawn into at different points of the frame (inside the sprite's update, before and
-- after gfx.sprite.update); the next frame reads back the number the display shows for each sprite
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local n = 0
local function paint(img, v)
  gfx.pushContext(img) gfx.clear(gfx.kColorWhite) gfx.setColor(gfx.kColorBlack)
  for b = 0, 9 do if (v >> b) & 1 == 1 then gfx.drawPixel(b, 0) end end
  gfx.popContext()
end
local sprites = {}
for i = 1, 6 do
  local img = gfx.image.new(10, 2, gfx.kColorWhite)
  local s = gfx.sprite.new(img) s:setCenter(0, 0) s:moveTo(0, i * 4) s:add()
  sprites[i] = s
end
sprites[1].update = function(self) paint(self:getImage(), n) end
sprites[4].update = function(self) paint(self:getImage(), n) self:markDirty() end
sprites[5]:setZIndex(10) sprites[6]:setZIndex(-10)
sprites[1]:setZIndex(0)
local oldUpd = sprites[1].update
sprites[1].update = function(self) oldUpd(self) paint(sprites[5]:getImage(), n) paint(sprites[6]:getImage(), n) end
local log = {}
function playdate.update()
  n += 1
  local disp = gfx.getDisplayImage()
  local row = {}
  for i = 1, 6 do
    local v = 0
    for b = 0, 9 do if disp:sample(b, i * 4) == gfx.kColorBlack then v = v | (1 << b) end end
    row[#row + 1] = v
  end
  if n > 2 and n < 40 then fh:write(n .. " " .. table.concat(row, " ") .. "\n") end
  paint(sprites[2]:getImage(), n)
  gfx.sprite.update()
  paint(sprites[3]:getImage(), n)
  if n == 40 then fh:close() end
end
