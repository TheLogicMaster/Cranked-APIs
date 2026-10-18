local out = {}
for _, name in ipairs({ "assets/pcm8", "assets/adpcm_mono", "assets/adpcm_stereo" }) do
    local s, err = playdate.sound.sample.new(name)
    if s then
        local fmt, rate = s:getFormat(), s:getSampleRate()
        out[#out + 1] = string.format("%s format=%s rate=%s length=%.4f", name, tostring(fmt), tostring(rate), s:getLength())
    else
        out[#out + 1] = name .. " failed: " .. tostring(err)
    end
end
local f = playdate.file.open("a.txt", playdate.file.kFileWrite); f:write(table.concat(out, "\n") .. "\n"); f:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
