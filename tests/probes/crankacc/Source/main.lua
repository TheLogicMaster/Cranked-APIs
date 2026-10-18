-- Probe: getCrankChange's two values while the crank is turned (mouse wheel in the Simulator)
local log = {}
local frame = 0
function playdate.update()
    frame = frame + 1
    local c, a = playdate.getCrankChange()
    if c ~= 0 then log[#log + 1] = string.format("%.9g %.9g", c, a) end
    if frame % 30 == 0 then
        local f = playdate.file.open("log.txt", playdate.file.kFileWrite); for _, l in ipairs(log) do f:write(l .. "\n") end; f:close()
    end
end
