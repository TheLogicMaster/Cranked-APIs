-- Probe: downscaled drawing (drawRotated with angle 0 and a scale, drawScaled) of a patterned image
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = playdate.file.open("out.txt", playdate.file.kFileWrite)
local src = gfx.image.new(37, 29, gfx.kColorWhite)
gfx.pushContext(src)
for y = 0, 28 do for x = 0, 36 do if ((x * 7 + y * 3) % 5 < 2) or (x % 9 == 0) then gfx.drawPixel(x, y) end end end
gfx.popContext()
local target = gfx.image.new(120, 120, gfx.kColorWhite)
local function dump(name)
  local rows = {}
  for y = 0, 119 do local r = {} for x = 0, 119 do r[#r + 1] = target:sample(x, y) == gfx.kColorBlack and "1" or "0" end rows[#rows + 1] = table.concat(r) end
  out:write(name .. "\t" .. table.concat(rows, "/") .. "\n")
end
local cases = {
  { "rot0 0.75", function() src:drawRotated(60, 60, 0, 0.75) end },
  { "rot0 0.5", function() src:drawRotated(60, 60, 0, 0.5) end },
  { "rot0 1.3", function() src:drawRotated(60, 60, 0, 1.3) end },
  { "rot0 0.75 0.6", function() src:drawRotated(60, 60, 0, 0.75, 0.6) end },
  { "scaled 0.75", function() src:drawScaled(10, 10, 0.75) end },
  { "scaled 0.5", function() src:drawScaled(10, 10, 0.5) end },
  { "scaled 0.33", function() src:drawScaled(10, 10, 0.33) end },
  { "scaled 0.75 1.25", function() src:drawScaled(10, 10, 0.75, 1.25) end },
  { "scaled 2.5", function() src:drawScaled(10, 10, 2.5) end },
  { "rot180 0.75", function() src:drawRotated(60, 60, 180, 0.75) end },
  { "scaledImage 0.75", function() src:scaledImage(0.75):draw(10, 10) end },
  { "rotatedImage 0 0.75", function() src:rotatedImage(0, 0.75):draw(10, 10) end },
  { "rotatedImage 90 0.75 on pattern", function() gfx.setPattern({0x55,0xaa,0x55,0xaa,0x55,0xaa,0x55,0xaa}) gfx.fillRect(0,0,120,120) src:rotatedImage(90, 0.75):draw(10, 10) end },
  { "rotatedImage 180 0.6 on pattern", function() gfx.setPattern({0x55,0xaa,0x55,0xaa,0x55,0xaa,0x55,0xaa}) gfx.fillRect(0,0,120,120) src:rotatedImage(180, 0.6):draw(10, 10) end },
  { "rotatedImage 0 0.75 on pattern", function() gfx.setPattern({0x55,0xaa,0x55,0xaa,0x55,0xaa,0x55,0xaa}) gfx.fillRect(0,0,120,120) src:rotatedImage(0, 0.75):draw(10, 10) end },
  { "rotatedImage 45 0.75 on pattern", function() gfx.setPattern({0x55,0xaa,0x55,0xaa,0x55,0xaa,0x55,0xaa}) gfx.fillRect(0,0,120,120) src:rotatedImage(45, 0.75):draw(10, 10) end },
  { "rotatedImage 90 1 on pattern", function() gfx.setPattern({0x55,0xaa,0x55,0xaa,0x55,0xaa,0x55,0xaa}) gfx.fillRect(0,0,120,120) src:rotatedImage(90):draw(10, 10) end },
  { "masked rotatedImage 0 0.75 on pattern", function() gfx.setPattern({0x55,0xaa,0x55,0xaa,0x55,0xaa,0x55,0xaa}) gfx.fillRect(0,0,120,120) local m = src:copy() m:addMask(true) m:rotatedImage(0, 0.75):draw(10, 10) end },
  { "rotatedImage 90.005 0.75 on pattern", function() gfx.setPattern({0x55,0xaa,0x55,0xaa,0x55,0xaa,0x55,0xaa}) gfx.fillRect(0,0,120,120) src:rotatedImage(90.005, 0.75):draw(10, 10) end },
}
for _, c in ipairs(cases) do target:clear(gfx.kColorWhite) gfx.pushContext(target) c[2]() gfx.popContext() dump(c[1]) end
for _, a in ipairs({ {0, 0.75}, {0, 0.5}, {0, 1.3}, {0, 2}, {45, 0.75}, {90, 0.75}, {180, 0.75}, {30, 1}, {0, -0.75} }) do
  local im = src:rotatedImage(a[1], a[2]) local w, h = im:getSize() out:write("size " .. a[1] .. " " .. a[2] .. "\t" .. w .. "x" .. h .. "\n")
end
out:close()
function playdate.update() end
