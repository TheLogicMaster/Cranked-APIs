local log, last, frame = {}, "", 0
local t0 = playdate.getCurrentTimeMilliseconds()
function playdate.update()
    frame = frame + 1
    local cur = playdate.getButtonState()
    local s = string.format("btn=%d crank=%.1f docked=%s", cur, playdate.getCrankPosition(), tostring(playdate.isCrankDocked()))
    if s ~= last then log[#log + 1] = string.format("%d\t%s", playdate.getCurrentTimeMilliseconds() - t0, s); last = s end
    if frame % 30 == 0 then local f = playdate.file.open("keys.txt", playdate.file.kFileWrite); f:write(table.concat(log, "\n") .. "\n"); f:close() end
end
