-- Probe: a file player with no file: play, isPlaying over frames, load while "playing", stop, callbacks
local snd = playdate.sound
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function out(...) local t = table.pack(...) local p = {} for i = 1, t.n do p[i] = tostring(t[i]) end fh:write(table.concat(p, " | ") .. "\n") fh:flush() end
local fp = snd.fileplayer.new()
fp:setFinishCallback(function() out("finish callback a") end)
out("play", fp:play())
out("isPlaying", fp:isPlaying())
out("offset", fp:getOffset())
out("underrun", fp:didUnderrun())
local fp2 = snd.fileplayer.new()
out("play2 count", fp2:play(3))
local fp3 = snd.fileplayer.new()
out("load bad", fp3:load("nope"))
out("play after bad load", fp3:play())
out("isPlaying3", fp3:isPlaying())
local fp4 = snd.fileplayer.new()
out("play4", fp4:play())
fp4:pause()
out("paused isPlaying4", fp4:isPlaying())
out("load4 after pause", fp4:load("tone"))
local frame = 0
function playdate.update()
  frame = frame + 1
  if frame == 1 or frame == 5 or frame == 30 then
    out("frame", frame, "isPlaying", fp:isPlaying(), "offset", fp:getOffset(), "underrun", fp:didUnderrun())
  end
  if frame == 31 then
    out("load while playing", fp:load("tone"))
    fp:stop()
    out("after stop isPlaying", fp:isPlaying())
    out("load after stop", fp:load("tone"))
    out("play tone", fp:play())
    out("isPlaying tone", fp:isPlaying())
  end
  if frame == 60 then out("frame 60 isPlaying", fp:isPlaying()) fh:close() end
end
