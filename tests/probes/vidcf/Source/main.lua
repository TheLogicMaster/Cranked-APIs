-- Probe: video:getCurrentFrame after renderFrame calls
local out = playdate.file.open("out.txt", playdate.file.kFileWrite)
local v = playdate.graphics.video.new("video/appear_frames")
out:write("fresh\t" .. tostring(v:getCurrentFrame()) .. "\n")
for _, n in ipairs({ 1, 3, 2, 0, 99, 4 }) do
    local ok = v:renderFrame(n)
    out:write("render " .. n .. "\t" .. tostring(ok) .. " " .. tostring(v:getCurrentFrame()) .. "\n")
end
out:close()
function playdate.update() end
