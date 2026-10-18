-- Probe: whether sprites covered by an opaque sprite still draw (draw callbacks logged per frame)
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local frame = 0
local function logger(name) return function(self, x, y, w, h) fh:write(frame .. " " .. name .. " " .. x .. "," .. y .. "," .. w .. "," .. h .. "\n") end end
local low = gfx.sprite.new() low:setSize(100, 100) low:moveTo(50, 50) low.draw = logger("low") low:add()
local mid = gfx.sprite.new() mid:setSize(60, 60) mid:moveTo(200, 120) mid.draw = logger("mid") mid:add()
local opaqueImg = gfx.image.new(400, 240, gfx.kColorWhite)
local maskedImg = gfx.image.new(400, 240, gfx.kColorClear)
local top = gfx.sprite.new(opaqueImg) top:setCenter(0, 0) top:moveTo(0, 0) top:setZIndex(100) top:add()
local cover = gfx.sprite.new() cover:setSize(80, 80) cover:moveTo(200, 120) cover:setZIndex(50) cover.draw = logger("cover")
local steps = {
  [1] = function() fh:write("-- full opaque image on top\n") end,
  [2] = function() fh:write("-- masked image set: opaque=" .. tostring((function() top:setImage(maskedImg) return top:isOpaque() end)()) .. "\n") end,
  [3] = function() fh:write("-- same masked again, setOpaque(true)\n") top:setOpaque(true) top:setImage(maskedImg) top:markDirty() end,
  [4] = function() fh:write("-- top hidden\n") top:setVisible(false) end,
  [5] = function() fh:write("-- callback cover opaque over mid\n") cover:setOpaque(true) cover:add() gfx.sprite.addDirtyRect(0, 0, 400, 240) end,
  [6] = function() fh:write("-- dirty rect only inside cover\n") gfx.sprite.addDirtyRect(190, 110, 20, 20) end,
  [7] = function() fh:write("-- dirty rect half inside cover\n") gfx.sprite.addDirtyRect(150, 110, 60, 20) end,
  [8] = function() fh:write("-- cover not opaque\n") cover:setOpaque(false) gfx.sprite.addDirtyRect(190, 110, 20, 20) end,
  [9] = function() fh:write("-- cover opaque, smaller than mid\n") cover:setOpaque(true) cover:setSize(40, 40) gfx.sprite.addDirtyRect(0, 0, 400, 240) end,
  [10] = function() fh:write("-- cover opaque, ignores draw offset with offset\n") cover:setSize(80, 80) gfx.setDrawOffset(5, 0) gfx.sprite.addDirtyRect(0, 0, 400, 240) end,
  [11] = function() gfx.setDrawOffset(0, 0) fh:close() fh = nil end,
}
function playdate.update()
  frame = frame + 1
  if steps[frame] then steps[frame]() end
  if fh then gfx.sprite.update() end
end
