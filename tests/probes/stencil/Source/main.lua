-- Probe: stencil semantics. Stencil columns: 0-3 white, 4-7 black, 8-11 clear. Draw fills, images and sprites.
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local out = {}
local st = gfx.image.new(32, 4)  -- clear
gfx.pushContext(st); gfx.setColor(gfx.kColorWhite); gfx.fillRect(0, 0, 4, 4); gfx.setColor(gfx.kColorBlack); gfx.fillRect(4, 0, 4, 4); gfx.popContext()
local stOpaque = gfx.image.new(32, 4, gfx.kColorWhite)
gfx.pushContext(stOpaque); gfx.setColor(gfx.kColorBlack); gfx.fillRect(4, 0, 4, 4); gfx.popContext()
local black = gfx.image.new(12, 4, gfx.kColorBlack)
local function grab(img) local t = {}; for x = 0, 11 do local s = img:sample(x, 1); t[#t + 1] = s == gfx.kColorBlack and "1" or (s == gfx.kColorWhite and "0" or "c") end; return table.concat(t) end
local function case(name, stencil, fn)
  local ok, e = pcall(function()
  local d = gfx.image.new(12, 4, gfx.kColorWhite); gfx.pushContext(d); gfx.setStencilImage(stencil); fn(); gfx.clearStencil(); gfx.popContext()
  out[#out + 1] = name .. "|" .. grab(d)
  end)
  if not ok then out[#out + 1] = name .. "|ERR " .. tostring(e) end
end
case("fillRect clearbg", st, function() gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 0, 12, 4) end)
case("image clearbg", st, function() black:draw(0, 0) end)
case("fillRect opaque", stOpaque, function() gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 0, 12, 4) end)
case("image opaque", stOpaque, function() black:draw(0, 0) end)
case("small stencil", gfx.image.new(31, 4, gfx.kColorWhite), function() black:draw(0, 0) end)
local st8 = gfx.image.new(32, 2, gfx.kColorWhite); gfx.pushContext(st8); gfx.setColor(gfx.kColorBlack); gfx.fillRect(2, 0, 2, 2); gfx.popContext()
case("tiled", st8, function() gfx.setStencilImage(st8, true); black:draw(0, 0) end)
case("untiled below", st8, function() gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 0, 12, 4) end)
-- sprite stencil on the screen
local spr = gfx.sprite.new(black); spr:setCenter(0, 0); spr:moveTo(0, 0); spr:setStencilImage(st); spr:add()
local spr2 = gfx.sprite.new(black); spr2:setCenter(0, 0); spr2:moveTo(0, 10); spr2:setStencilImage(stOpaque); spr2:add()
local frame = 0
function playdate.update()
  frame = frame + 1
  local ok, e = pcall(gfx.sprite.update); if not ok then out[#out + 1] = "update|ERR " .. tostring(e) end
  if frame == 3 then
    local d = gfx.getWorkingImage()
    local function row(y) local t = {}; for x = 0, 11 do local s = d:sample(x, y); t[#t + 1] = s == gfx.kColorBlack and "1" or "0" end; return table.concat(t) end
    out[#out + 1] = "sprite clearbg|" .. row(1); out[#out + 1] = "sprite opaque|" .. row(11)
    local fh = playdate.file.open("stencil.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
    if playdate.simulator then playdate.simulator.exit() end
    playdate.stop()
  end
end
