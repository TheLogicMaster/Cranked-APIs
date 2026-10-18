-- Sequence position (goToStep, getCurrentStep) and finish callbacks on stop, while not playing or
-- just after play/stop, so the results do not depend on frame timing.
local snd = playdate.sound
local out = {}
local function p(s) out[#out + 1] = s end
local seq = snd.sequence.new("song.mid")
p("start " .. seq:getCurrentStep() .. " playing " .. tostring(seq:isPlaying()))
for _, s in ipairs({ 5, 1, 0, 97, 504, 600 }) do seq:goToStep(s); p("goToStep " .. s .. " -> " .. seq:getCurrentStep()) end
local calls = 0
seq:goToStep(1)
seq:play(function(s) calls = calls + 1 end)
p("after play " .. tostring(seq:isPlaying()))
local frame = 0
function playdate.update()
    frame = frame + 1
    if frame == 3 then seq:stop(); p("after stop playing " .. tostring(seq:isPlaying()) .. " calls " .. calls) end
    if frame == 6 then p("calls a frame later " .. calls); seq:goToStep(97); p("goToStep 97 -> " .. seq:getCurrentStep()) end
    if frame == 8 then
        seq:stop(); p("stop while stopped, calls " .. calls)
        local f = playdate.file.open("seq.txt", playdate.file.kFileWrite); f:write(table.concat(out, "\n") .. "\n"); f:close()
        if playdate.simulator then playdate.simulator.exit() end
    end
end
