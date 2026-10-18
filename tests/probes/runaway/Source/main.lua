-- Probe: game code that never returns (a loop that pcall keeps restarting). The emulator must still stop.
local n = 0
function playdate.update()
  n = n + 1
  if n == 3 then
    while true do
      pcall(function() while true do end end)
      local co = coroutine.create(function() while true do end end)
      coroutine.resume(co)
      table.sort({ 3, 2, 1, 5, 4 }, function(a, b) while true do end end)
    end
  end
end
