-- Probe: Lua sample player (play ranges, loops, reverse, ping-pong, playAt, callbacks, offsets, rates)
local snd = playdate.sound
local frame = 0
local s = snd.sample.new("assets/tone")
local log = {}
local function L(x) log[#log + 1] = x end
local P = {}
for i = 1, 6 do
    local p = snd.sampleplayer.new(s); p:setVolume(0.6)
    local n = i
    p:setFinishCallback(function(pl, arg) L("finish " .. n .. " arg " .. tostring(arg)) end, "a" .. n)
    p:setLoopCallback(function(pl, arg) L("loop " .. n .. " arg " .. tostring(arg)) end, "l" .. n)
    P[i] = p
end
function playdate.update()
    frame = frame + 1
    if frame == 5 then
        local t = snd.getCurrentTime() + 0.2
        P[1]:setPlayRange(1000, 5000); P[1]:playAt(t)
        P[2]:playAt(t + 1, 0.3, 0.9, -1.0)
        P[3]:setPlayRange(2000, 4000); P[3]:playAt(t + 2, 0, 0, 1.5)
        P[4]:setOffset(0.05); P[4]:playAt(t + 3, 0, 0, 0.75)
        P[5]:setRate(1.25); P[5]:playAt(t + 4)
        L("rate5 " .. P[5]:getRate())
        L("playing1 " .. tostring(P[1]:isPlaying()) .. " off4 " .. P[4]:getOffset())
    end
    if frame == 200 then P[6]:setPlayRange(1000, 3000); P[6]:play(3, 2.0); L("rate6 " .. P[6]:getRate()) end
    if frame == 240 then L("p6 " .. tostring(P[6]:isPlaying())) end
    if frame == 300 then P[6]:play(-1) end
    if frame == 330 then P[6]:stop(); L("p6 stopped " .. tostring(P[6]:isPlaying())) end
    if frame == 5 + 30 * 12 then
        captureSave("capture.raw")
        local f = playdate.file.open("log.txt", playdate.file.kFileWrite); for _, l in ipairs(log) do f:write(l .. "\n") end; f:close()
        if playdate.simulator then playdate.simulator.exit() end
    end
end
