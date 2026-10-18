-- Probe: drawTriangle with vertices off the target
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local W, H = 160, 120
local function dump(name, f)
  local img = gfx.image.new(W, H, gfx.kColorWhite)
  gfx.pushContext(img) f() gfx.popContext()
  fh:write(name .. "\n")
  for y = 0, H - 1 do local r = {} for x = 0, W - 1 do r[#r+1] = img:sample(x, y) == gfx.kColorBlack and "#" or "." end fh:write(table.concat(r) .. "\n") end
end
dump("t1", function() gfx.drawTriangle(-20, 5, 172, -20, 125, 12) end)
dump("l1", function() gfx.drawLine(-20, 5, 172, -20) end)
dump("l2", function() gfx.drawLine(172, -20, 125, 12) end)
dump("l3", function() gfx.drawLine(125, 12, -20, 5) end)
dump("l1r", function() gfx.drawLine(172, -20, -20, 5) end)
dump("t2", function() gfx.drawTriangle(10, 10, 150, 30, 60, 110) end)
dump("l4", function() gfx.drawLine(-50, -30, 200, 150) end)
dump("l5", function() gfx.drawLine(-20, 60, 180, 61) end)
dump("l6", function() gfx.drawLine(30, -40, 31, 200) end)
dump("l7w3", function() gfx.setLineWidth(3) gfx.drawLine(-20, 5, 172, -20) end)
fh:close()
function playdate.update() end
