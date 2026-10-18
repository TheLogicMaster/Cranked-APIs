-- Probe: sprites that grow by fractional sizes and move by fractional steps each frame; each frame's display
-- is written out
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local img = gfx.image.new(20, 12, gfx.kColorBlack)
gfx.pushContext(img) gfx.setColor(gfx.kColorWhite) gfx.fillRect(3, 3, 14, 6) gfx.popContext()
local sprites = {}
for i = 1, 6 do
  local s = gfx.sprite.new()
  s.time = i * 3
  s.angle = i * 1.1
  s.update = function(self)
    self.time += 1
    local d = self.time * self.time / 4
    local scale = d / 40 + self.time / 10
    self.scale = scale
    if self.cached then
      if self:getImage() == nil then self:setImage(img) end
      self:setScale(scale)
    else
      self:setImage(nil)
      self:setSize(img.width * scale, img.height * scale)
    end
    self:moveTo(200 + d * math.cos(self.angle), 120 + d * math.sin(self.angle))
  end
  s.draw = function(self, x, y, w, h) img:drawScaled(0, 0, self.scale) end
  s.cached = i % 2 == 0
  if s.cached then s:setImage(img) end
  s:setScale(0)
  s:moveTo(200, 120)
  s:add()
  sprites[i] = s
end
local frame = 0
local function hexrows()
  local im = gfx.getDisplayImage()
  local t = {}
  for y = 0, 239, 1 do local r = {} for x = 0, 399, 4 do local v = 0 for k = 0, 3 do if im:sample(x + k, y) == gfx.kColorBlack then v = v + (1 << k) end end r[#r + 1] = string.format("%x", v) end t[#t + 1] = table.concat(r) end
  return table.concat(t, "/")
end
function playdate.update()
  frame = frame + 1
  if frame > 1 and frame <= 26 then fh:write("f" .. (frame - 1) .. " " .. hexrows() .. "\n") end
  if frame == 27 then fh:close() end
  if frame == 8 then gfx.setBackgroundColor(gfx.kColorClear) end
  if frame == 14 then gfx.setBackgroundColor(gfx.kColorWhite) gfx.clear() end
  if frame == 18 then for _, sp in ipairs(sprites) do sp.cached = not sp.cached end end
  gfx.sprite.update()
end
