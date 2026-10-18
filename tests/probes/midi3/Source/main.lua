-- A format 1 MIDI file (one track per chunk), with overlapping and unmatched notes, controllers,
-- RPN pitch bend range and pitch bends. Prints what the sequence holds.
local snd = playdate.sound
local out = {}
local function p(s) out[#out + 1] = s end
local seq, err = snd.sequence.new("song.mid")
if not seq then p("load failed: " .. tostring(err)) else
    p("tempo=" .. tostring(seq:getTempo()) .. " length=" .. tostring(seq:getLength()) .. " tracks=" .. tostring(seq:getTrackCount()))
    for i = 1, seq:getTrackCount() do
        local t = seq:getTrackAtIndex(i)
        local notes = t:getNotes()
        p("track " .. i .. ": " .. #notes .. " notes, length " .. tostring(t:getLength()) .. " polyphony " .. tostring(t:getPolyphony())
            .. " signals " .. tostring(#t:getControlSignals()))
        for _, n in ipairs(notes) do
            p(string.format("  step=%s note=%s length=%s velocity=%s", tostring(n.step), tostring(n.note), tostring(n.length), tostring(n.velocity)))
        end
        for _, s in ipairs(t:getControlSignals()) do
            p("  signal controller " .. tostring(s:getControllerType()))
        end
    end
end
local f = playdate.file.open("midi.txt", playdate.file.kFileWrite); f:write(table.concat(out, "\n") .. "\n"); f:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
