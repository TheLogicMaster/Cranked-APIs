-- Probe: whether fonts made and dropped every frame are freed
local gfx = playdate.graphics
local frame = 0
local kept
function playdate.update()
  frame = frame + 1
  for i = 1, 20 do local f = gfx.font.new("/System/Fonts/Asheville-Sans-14-Bold") if i == 1 and frame == 1 then kept = f end end
  if frame % 10 == 0 then collectgarbage("collect") end
  gfx.setFont(kept) gfx.drawText("still works " .. frame, 10, 10)
end
