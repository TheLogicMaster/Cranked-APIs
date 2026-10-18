local s, err = playdate.sound.sample.new("assets/beep")
local f = playdate.file.open("snd.txt", playdate.file.kFileWrite)
f:write(tostring(s) .. " | " .. tostring(err) .. "\n"); f:close()
playdate.stop()
