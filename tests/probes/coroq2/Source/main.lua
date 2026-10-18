-- Probe: a yield in the main chunk; when does the rest run, and does update run before it
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function w(s) fh:write(s .. "\n") fh:flush() end
local frames = 0
function playdate.update() frames = frames + 1 if frames <= 3 then w("update " .. frames) end if frames == 6 then w("end") fh:close() end end
w("before yield")
local r = { coroutine.yield(1, 2) }
w("after yield 1: n=" .. #r .. " frames=" .. frames .. " " .. tostring(r[1]))
local r2 = { coroutine.yield() }
w("after yield 2: n=" .. #r2 .. " frames=" .. frames)
