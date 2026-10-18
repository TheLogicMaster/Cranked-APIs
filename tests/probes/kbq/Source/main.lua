-- Probe: the CoreLibs keyboard, shown and dumped as a character grid after its show animation
import "CoreLibs/graphics"
import "CoreLibs/keyboard"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local n = 0
local f = gfx.font.new("CoreLibs/assets/keyboard/Roobert-24-Keyboard-Medium")
fh:write("font " .. tostring(f ~= nil) .. " " .. tostring(f and f:getHeight()) .. " " .. tostring(f and f:getTextWidth("ABC@")) .. "\n")
function playdate.update()
  n += 1
  gfx.clear()
  gfx.drawText("frame", 10, 10)
  if n == 20 or n == 40 then
    local img = gfx.getDisplayImage()
    fh:write("frame " .. n .. " " .. tostring(playdate.keyboard.left()) .. "\n")
    for y = 0, 239 do local r = {} for x = 200, 399 do r[#r + 1] = img:sample(x, y) == gfx.kColorBlack and "#" or "." end fh:write(table.concat(r) .. "\n") end
  end
  if n == 41 then fh:close() end
end
playdate.keyboard.show("Tune")
