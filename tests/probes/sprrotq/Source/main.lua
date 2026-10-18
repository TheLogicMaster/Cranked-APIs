-- Probe: sprites with rotation drawn by sprite.update; per-frame pixel hash of the frame
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function log(s) fh:write(s .. "\n") fh:flush() end
local p = gfx.image.new("cursor") local c = gfx.image.new("panel")
log((("p " .. tostring(p) .. " c " .. tostring(c)):gsub("0x%x+", "ADDR"))) -- host addresses print as ADDR
local cases = {0, -15, 15, 360, -90, 200.5}
local n, i, s = 0, 0, nil
local function hash()
  local img = gfx.getWorkingImage() local b, sum = 0, 0
  for y = 0, 239, 1 do for x = 0, 399, 1 do if img:sample(x, y) == gfx.kColorBlack then b += 1 sum = (sum * 31 + x * 7 + y) % 1000003 end end end
  return b, sum
end
function playdate.update()
  n += 1
  if n % 2 == 1 then
    i += 1
    if s then s:remove() s = nil end
    if i > #cases * 2 then if fh then fh:close() fh = nil end return end
    local img = i <= #cases and p or c
    s = gfx.sprite.new(img) s:setRotation(cases[(i - 1) % #cases + 1]) s:add() s:setZIndex(3) s:moveTo(120, 100)
  end
  gfx.sprite.update()
  if n % 2 == 0 then
    local b, h = hash()
    log(string.format("i=%d rot=%s w=%d h=%d black=%d hash=%d bounds=%s", i, tostring(s:getRotation()), s.width, s.height, b, h, tostring(s:getBoundsRect())))
  end
end
