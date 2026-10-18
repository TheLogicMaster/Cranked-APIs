-- Probe: which thread runs the main chunk, the update callback and other callbacks
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local mainThread = coroutine.running()
local function w(s) fh:write(s .. "\n") end
local function info(label)
  local co, ismain = coroutine.running()
  w(string.format("%s yieldable=%s ismain=%s same_as_chunk=%s status=%s", label, tostring(coroutine.isyieldable()), tostring(ismain), tostring(co == mainThread), coroutine.status(co)))
end
info("chunk")
local ok, e = pcall(function() info("chunk pcall") end)
local t = 0
function playdate.gameWillPause() info("pause") end
function playdate.update()
  t = t + 1
  if t == 1 then
    info("update")
    local ok, e = pcall(coroutine.yield, 5)
    w("yield in update: " .. tostring(ok) .. " " .. tostring(e))
    playdate.timer = playdate.timer
  end
  if t == 2 then
    playdate.graphics.sprite.new() 
    local ok2, e2 = pcall(coroutine.close, mainThread)
    w("close chunk thread: " .. tostring(ok2) .. " " .. tostring(e2))
  end
  if t == 3 then fh:close() end
end
