-- Probe: the keys, types and values of playdate.metadata, and getHeadphoneState's results
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local ks = {}
for k, v in pairs(playdate.metadata) do ks[#ks + 1] = k .. "=" .. type(v) .. (math.type(v) and (":" .. math.type(v)) or "") .. ":" .. (k == "buildtime" and "T" or tostring(v)) end
table.sort(ks)
fh:write(table.concat(ks, "\n") .. "\n")
fh:write("headphone " .. select("#", playdate.sound.getHeadphoneState()) .. " " .. tostring(playdate.sound.getHeadphoneState()) .. " " .. tostring(select(2, playdate.sound.getHeadphoneState())) .. "\n")
fh:close()
function playdate.update() end
