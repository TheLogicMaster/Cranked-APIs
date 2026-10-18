-- Audio stress for the file player, sample player and delay tap code. Random operations with odd
-- values every frame, while the mixer runs; it must not crash, hang or trip ASan. Logs a count at the end.
local snd = playdate.sound
local seedFile = playdate.file.open("seed.txt"); local seed = seedFile and tonumber(seedFile:readline()) or 4242; if seedFile then seedFile:close() end; math.randomseed(seed)
local files = { "assets/m44", "assets/m22", "assets/m32", "assets/s44", "assets/cbr", "assets/vbr", "assets/tag" }
local odd = { 0, -1, 1, 0.5, 2, 7.9, 1e9, -1e9, 0 / 0, 1 / 0, -1 / 0, 1e-9, 1000, 0.0001, 3, -0.25 }
local function pick(t) return t[math.random(#t)] end
local function num() if math.random() < 0.5 then return pick(odd) end return (math.random() - 0.3) * 4 end
local players, samplers, taps, mods = {}, {}, {}, {}
for i = 1, 6 do players[i] = snd.fileplayer.new(pick(files)) end
local sample = snd.sample.new("assets/m22")
for i = 1, 4 do samplers[i] = snd.sampleplayer.new(sample) end
local line = snd.delayline.new(4000)
line:setMix(0.5)
for i = 1, 3 do taps[i] = line:addTap(math.random(1, 3999)) end
local ch = snd.channel.new()
ch:addEffect(line)
for i = 1, 3 do ch:addSource(taps[i]) end
local function newMod()
    local r = math.random(4)
    if r == 1 then local l = snd.lfo.new(math.random(0, 7)); l:setRate(num()); l:setDepth(num()); l:setCenter(num()); return l end
    if r == 2 then local e = snd.envelope.new(math.random(), math.random(), math.random(), math.random()); return e end
    if r == 3 then local c = snd.controlsignal.new(); c:addEvent(1, num(), true); c:addEvent(math.random(2, 30), num(), false); return c end
    return nil
end
local ops = 0
local frame = 0
function playdate.update()
    frame = frame + 1
    for _ = 1, 6 do
        ops = ops + 1
        local p = pick(players)
        local r = math.random(16)
        pcall(function()
            if r == 1 then p:play(math.random(0, 3))
            elseif r == 2 then p:stop()
            elseif r == 3 then p:pause()
            elseif r == 4 then p:setRate(num())
            elseif r == 5 then p:setLoopRange(num(), num(), function() ops = ops + 1 end)
            elseif r == 6 then p:setOffset(num())
            elseif r == 7 then p:setBufferSize(num())
            elseif r == 8 then p:setRateMod(newMod())
            elseif r == 9 then p:setVolume(num(), num(), math.random() < 0.5 and math.random() or nil)
            elseif r == 10 then p:load(pick(files))
            elseif r == 11 then local s = pick(samplers); s:setRateMod(newMod()); s:play(math.random(-1, 2), num())
            elseif r == 12 then local s = pick(samplers); s:setPlayRange(math.random(-100, 50000), math.random(-100, 50000)); s:setRate(num())
            elseif r == 13 then local t = pick(taps); t:setDelay(math.random(-5000, 9000))
            elseif r == 14 then local t = pick(taps); t:setDelayMod(newMod())
            elseif r == 15 then p:setStopOnUnderrun(math.random() < 0.5); p:getOffset(); p:getLength(); p:didUnderrun()
            else p:setLoopCallback(function() ops = ops + 1 end) end
        end)
    end
    if frame == 900 then
        local f = playdate.file.open("done.txt", playdate.file.kFileWrite); f:write("ops " .. ops .. "\n"); f:close()
    end
end
