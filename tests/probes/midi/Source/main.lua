-- Probe: two format 0 MIDI files loaded as sequences: tempo, length, tracks and notes (song.mid to midi.txt,
-- song2.mid to midi2.txt)
local snd = playdate.sound
local function dump(file, outName)
    local out = {}
    local seq, err = snd.sequence.new(file)
    if not seq then out[#out + 1] = "load failed: " .. tostring(err) else
        out[#out + 1] = "tempo=" .. tostring(seq:getTempo()) .. " length=" .. tostring(seq:getLength()) .. " tracks=" .. tostring(seq:getTrackCount())
        for i = 1, seq:getTrackCount() do
            local t = seq:getTrackAtIndex(i)
            local notes = t:getNotes()
            out[#out + 1] = "track " .. i .. ": " .. #notes .. " notes, length " .. tostring(t:getLength())
            for _, n in ipairs(notes) do
                out[#out + 1] = string.format("  step=%s note=%s length=%s velocity=%s", tostring(n.step), tostring(n.note), tostring(n.length), tostring(n.velocity))
            end
        end
    end
    local f = playdate.file.open(outName, playdate.file.kFileWrite); f:write(table.concat(out, "\n") .. "\n"); f:close()
end
dump("song.mid", "midi.txt")
dump("song2.mid", "midi2.txt")
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
