import "CoreLibs/sprites"
local gfx = playdate.graphics
local log, frame = {}, 0
function playdate.update()
    frame = frame + 1
    if frame == 1 then
        gfx.setBackgroundColor(gfx.kColorBlack)
        log[#log + 1] = "bg after set: " .. tostring(gfx.getBackgroundColor())
        gfx.sprite.update()
        log[#log + 1] = "working after update: " .. tostring(gfx.getWorkingImage():sample(5, 5))
    elseif frame == 2 then
        log[#log + 1] = "display next frame: " .. tostring(gfx.getDisplayImage():sample(5, 5))
        gfx.sprite.update()
        log[#log + 1] = "working after second update: " .. tostring(gfx.getWorkingImage():sample(5, 5))
    elseif frame == 3 then
        log[#log + 1] = "display frame 3: " .. tostring(gfx.getDisplayImage():sample(5, 5))
        local f = playdate.file.open("bg.txt", playdate.file.kFileWrite); f:write(table.concat(log, "\n") .. "\n"); f:close()
        if playdate.simulator then playdate.simulator.exit() end
        playdate.stop()
    end
end
