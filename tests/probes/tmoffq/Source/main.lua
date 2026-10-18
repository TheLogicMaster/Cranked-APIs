-- Probe: tilemap draw, drawIgnoringOffset and image drawIgnoringOffset under a draw offset, in an image context
-- and on the screen
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local tile = gfx.image.new(4, 4, gfx.kColorWhite)
gfx.pushContext(tile) gfx.setColor(gfx.kColorBlack) gfx.fillRect(0, 0, 2, 2) gfx.popContext()
local it = gfx.imagetable.new(1) it:setImage(1, tile)
local tm = gfx.tilemap.new() tm:setImageTable(it) tm:setSize(3, 2) for x = 1, 3 do for y = 1, 2 do tm:setTileAtPosition(x, y, 1) end end
local function sig(img) local n, s = 0, 0 local W, H = img:getSize() for y = 0, H - 1 do for x = 0, W - 1 do if img:sample(x, y) == gfx.kColorBlack then n = n + 1 s = (s * 31 + x * 7 + y) % 1000003 end end end return n .. ":" .. s end
for _, off in ipairs({ { 0, 0 }, { 5, 3 }, { -3, 7 } }) do
  for _, mode in ipairs({ "draw", "ignore", "image ignore", "drawrect" }) do
    local t = gfx.image.new(40, 30, gfx.kColorWhite)
    gfx.pushContext(t) gfx.setDrawOffset(off[1], off[2])
    local ok, e = pcall(function()
      if mode == "draw" then tm:draw(2, 2)
      elseif mode == "ignore" then tm:drawIgnoringOffset(2, 2)
      elseif mode == "image ignore" then tile:drawIgnoringOffset(2, 2)
      else tm:draw(2, 2, playdate.geometry.rect.new(3, 1, 6, 6)) end
    end)
    gfx.popContext()
    fh:write(string.format("off=%d,%d %s %s %s %s\n", off[1], off[2], mode, tostring(ok), ok and "" or tostring(e), sig(t)))
  end
end
local frame = 0
function playdate.update()
  frame = frame + 1
  if frame == 2 then
    gfx.clear(gfx.kColorWhite) gfx.setDrawOffset(5, 3) tm:drawIgnoringOffset(10, 10) tm:draw(30, 10) gfx.setDrawOffset(0, 0)
  elseif frame == 3 then
    fh:write("screen " .. sig(gfx.getDisplayImage()) .. "\n") fh:close()
  end
end
