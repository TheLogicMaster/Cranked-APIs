-- Probe: sprites moving by fractional steps over a background; display rows hashed every frame
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local img = gfx.image.new(58, 58)
gfx.pushContext(img) gfx.setLineCapStyle(gfx.kLineCapStyleRound) gfx.setLineWidth(10) gfx.drawLine(29, 29, 20, 53) gfx.popContext()
local box = gfx.image.new(21, 15, gfx.kColorBlack)
gfx.sprite.setBackgroundDrawingCallback(function(x, y, w, h) gfx.setPattern({0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55}) gfx.fillRect(x, y, w, h) end)
local s = gfx.sprite.new(img) s:moveTo(100.5, 100.25) s:add()
local b = gfx.sprite.new(box) b:moveTo(200.5, 50.5) b:add()
local c = gfx.sprite.new() c:setSize(30.6, 20.2) c:moveTo(300.3, 150.7) c:add()
c.draw = function(self, x, y, w, h) gfx.setColor(gfx.kColorBlack) gfx.fillRect(0, 0, 40, 40) end
local frame = 0
local function hash()
  local im = gfx.getDisplayImage() local out = {}
  for y = 0, 239, 1 do local hsh = 0 for x = 0, 399 do if im:sample(x, y) == gfx.kColorBlack then hsh = (hsh * 31 + x) % 1000003 end end out[#out+1] = hsh end
  return table.concat(out, ",")
end
function playdate.update()
  frame = frame + 1
  s:moveBy(0.37, 0.61) b:moveBy(-0.5, 0.25) c:moveBy(0.25, -0.33)
  gfx.sprite.update()
  if frame > 1 then fh:write(frame .. " " .. hash() .. "\n") end
  if frame == 40 then fh:close() end
end
