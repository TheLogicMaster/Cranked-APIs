-- Probe (with src/main.c): state shared, or not, between the C API and Lua
import "CoreLibs/sprites"
local gfx = playdate.graphics
local out = playdate.file.open("syncq.txt", playdate.file.kFileWrite)
local function log(...) local t = {} for i, v in ipairs({...}) do t[i] = tostring(v) end out:write(table.concat(t, " ") .. "\n") end
local frame = 0
function playdate.update()
  frame += 1
  if frame == 2 then
    playdate.resetElapsedTime(); creset()
    local t0 = playdate.getCurrentTimeMilliseconds() while playdate.getCurrentTimeMilliseconds() - t0 < 50 do end
    playdate.resetElapsedTime()
    log("after lua reset: C elapsed under 0.02:", celapsed() < 0.02, "lua elapsed under 0.02:", playdate.getElapsedTime() < 0.02)
    creset()
    t0 = playdate.getCurrentTimeMilliseconds() while playdate.getCurrentTimeMilliseconds() - t0 < 50 do end
    creset()
    log("after C reset: lua elapsed under 0.02:", playdate.getElapsedTime() < 0.02)
    crate(20); log("C rate 20, lua rate:", playdate.display.getRefreshRate())
    playdate.display.setRefreshRate(30); log("lua rate 30 set")
    log("sprites: lua", #gfx.sprite.getAllSprites(), "C", cspritecount())
    local s = gfx.sprite.new(); s:add(); caddsprite()
    log("after one each: lua", #gfx.sprite.getAllSprites(), "C", cspritecount(), "lua spriteCount", gfx.sprite.spriteCount())
    gfx.clear(gfx.kColorWhite); gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 0, 8, 1)
    log("lua fill, C frame byte:", cframebyte(0, 0))
    cscale(2); log("C scale 2: lua width", playdate.display.getWidth(), "scale", playdate.display.getScale(), "C width", cwidth())
    playdate.display.setScale(1); log("lua scale 1: C width", cwidth())
    cinverted(1); log("C inverted: lua", playdate.display.getInverted()); cinverted(0)
    out:close()
  end
end
