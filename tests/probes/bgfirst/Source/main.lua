-- Probe: on which frames a background drawing callback runs, after a start-up sequence such as games use
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local frame = 0
local variant = ...
playdate.display.setRefreshRate(30)
gfx.setBackgroundColor(gfx.kColorBlack)
gfx.sprite.removeAll()
gfx.setDrawOffset(0, 0)
class("Scene").extends(gfx.sprite)
function Scene:init() Scene.super.init(self) end
local scene = Scene()
scene:moveTo(0, 0)
gfx.sprite.setAlwaysRedraw(true)
local img = gfx.image.new(20, 20, gfx.kColorWhite)
gfx.sprite.setBackgroundDrawingCallback(function(x, y, w, h) fh:write(frame .. " bg " .. x .. "," .. y .. "," .. w .. "," .. h .. "\n") img:draw(0, 0) end)
scene:add()
local s2 = gfx.sprite.new()
s2:add()
local s3 = gfx.sprite.new()
s3:moveTo(0, 0) s3:setImage(img) s3:setZIndex(26000) s3:setCenter(0, 0) s3:setIgnoresDrawOffset(true) s3:add()
function playdate.update()
  frame = frame + 1
  if frame <= 5 then fh:write(frame .. " update\n") end
  gfx.sprite.update()
  s3:setImage(img)
  if frame == 6 then fh:close() end
end
