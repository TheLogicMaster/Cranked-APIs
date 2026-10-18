-- Probe: how many nested pcall levels fit before "C stack overflow", from the main chunk, from update, from a
-- coroutine, from a timer-like callback (sprite draw) and from a coroutine resumed in update
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function depth()
  local d = 0
  local function r() d = d + 1 local ok, e = pcall(r) if not ok then error(e, 0) end end
  pcall(r)
  return d
end
local function sdepth()
  local d = 0
  local function r() d = d + 1 table.sort({2, 1}, function(a, b) r() return a < b end) end
  pcall(r)
  return d
end
fh:write("main " .. depth() .. " " .. sdepth() .. "\n")
fh:write("main co " .. coroutine.wrap(function() return depth() .. " " .. sdepth() end)() .. "\n")
local s = playdate.graphics.sprite.new() s:setSize(10, 10) s:moveTo(20, 20) s:add()
local logged = false
function s:draw() if not logged then logged = true fh:write("draw " .. depth() .. " " .. sdepth() .. "\n") end end
local n = 0
function playdate.update()
  n += 1
  if n == 1 then
    fh:write("update " .. depth() .. " " .. sdepth() .. "\n")
    fh:write("update co " .. coroutine.wrap(function() return depth() .. " " .. sdepth() end)() .. "\n")
    playdate.graphics.sprite.update()
    fh:close()
  end
end
