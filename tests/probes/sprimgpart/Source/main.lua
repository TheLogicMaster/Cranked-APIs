-- Probe: an image changed during the update while another moving sprite forces a partial redraw of it. Each
-- frame reads back the value shown in two corners of the big sprite (one under the mover, one away from it)
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local n = 0
local function paint(img, v)
  gfx.pushContext(img) gfx.clear(gfx.kColorWhite) gfx.setColor(gfx.kColorBlack)
  for b = 0, 9 do if (v >> b) & 1 == 1 then gfx.fillRect(b * 4, 0, 4, 4) gfx.fillRect(60 + b * 4, 0, 4, 4) end end
  gfx.popContext()
end
local bigA = gfx.image.new(100, 4, gfx.kColorWhite)
local A = gfx.sprite.new(bigA) A:setCenter(0, 0) A:moveTo(0, 10) A:add() A:setZIndex(0)
local bigB = gfx.image.new(100, 4, gfx.kColorWhite)
local B = gfx.sprite.new(bigB) B:setCenter(0, 0) B:moveTo(0, 30) B:add() B:setZIndex(0)
local mover = gfx.sprite.new(gfx.image.new(6, 30, gfx.kColorBlack)) mover:setCenter(0, 0) mover:add() mover:setZIndex(5)
local mode = 1
function mover:update()
  -- moves over the left part of A and B, alternating position so each frame dirties that area
  self:moveTo(n % 2 == 0 and 2 or 10, 6)
  if mode == 1 then paint(bigA, n) end
end
function B:update() if mode == 1 then paint(bigB, n) end end
function playdate.update()
  n += 1
  local disp = gfx.getDisplayImage()
  local function val(x0, y)
    local v = 0
    for b = 0, 9 do if disp:sample(x0 + b * 4 + 1, y + 1) == gfx.kColorBlack then v = v | (1 << b) end end
    return v
  end
  if n > 2 and n < 30 then fh:write(n .. " A(right)=" .. val(60, 10) .. " B(right)=" .. val(60, 30) .. "\n") end
  gfx.sprite.update()
  if n == 30 then fh:close() end
end
