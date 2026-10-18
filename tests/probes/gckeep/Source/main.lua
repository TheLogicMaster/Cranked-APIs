-- Probe: which objects the garbage collector frees when the game keeps no reference: files (closed when collected?),
-- sound channels, and effects added to a channel. A weak-valued table shows whether each was collected.
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function log(s) fh:write(s .. "\n") fh:flush() end
local weak = setmetatable({}, { __mode = "v" })
-- files: 200 opens without keeping them, collecting every 10; the open-file limit is 64
local ok, failed = 0, 0
for i = 1, 200 do
  local f = playdate.file.open("main.pdz")
  if f then ok += 1 else failed += 1 end
  if i == 1 then weak.file = f end
  f = nil
  if i % 10 == 0 then collectgarbage("collect") end
end
log("files opened " .. ok .. " failed " .. failed .. " first collected " .. tostring(weak.file == nil))
-- a channel and an effect added to it, no references kept
do
  local c = playdate.sound.channel.new()
  local d = playdate.sound.delayline.new(0.5)
  c:addEffect(d)
  weak.channel, weak.effect = c, d
  local c2 = playdate.sound.channel.new()
  weak.channel2 = c2
  c2:remove()
  local d2 = playdate.sound.delayline.new(0.5)
  weak.effect2 = d2
end
collectgarbage("collect") collectgarbage("collect")
log("channel collected " .. tostring(weak.channel == nil) .. " its effect collected " .. tostring(weak.effect == nil))
log("removed channel collected " .. tostring(weak.channel2 == nil) .. " lone effect collected " .. tostring(weak.effect2 == nil))
local frame = 0
function playdate.update()
  frame += 1
  if frame == 5 then
    collectgarbage("collect")
    log("frame 5: channel collected " .. tostring(weak.channel == nil) .. " removed channel collected " .. tostring(weak.channel2 == nil))
    fh:close()
    if playdate.simulator then playdate.simulator.exit() end
  end
end
