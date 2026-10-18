-- Probe: return counts and types for sound, timers, animators, geometry operators and string helpers
import "CoreLibs/graphics"
import "CoreLibs/timer"
import "CoreLibs/frameTimer"
import "CoreLibs/animator"
import "CoreLibs/nineslice"
import "CoreLibs/math"
import "CoreLibs/string"
import "CoreLibs/crank"
local gfx = playdate.graphics
local geo = playdate.geometry
local snd = playdate.sound
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function desc(v)
  local t = type(v)
  if t == "number" then return (math.type(v) == "integer" and "i:" or "f:") .. string.format("%.4g", v) end
  if t == "userdata" or t == "table" then local mt = getmetatable(v) return (mt and mt.__name) or t end
  if t == "string" then return "s:" .. v end
  return t
end
local function run(name, fn, ...)
  local r = table.pack(pcall(fn, ...))
  if not r[1] then fh:write(name .. " ERR " .. tostring(r[2]):gsub("^.-:%d+: ", "") .. "\n") return end
  local s = {}
  for i = 2, r.n do s[#s + 1] = desc(r[i]) end
  fh:write(name .. " " .. (r.n - 1) .. " " .. table.concat(s, ",") .. "\n")
end
local syn = snd.synth.new(snd.kWaveSquare)
local smp = snd.sample.new(0.1)
local sp = snd.sampleplayer.new(smp)
local fp = snd.fileplayer.new()
local ch = snd.channel.new()
local seq = snd.sequence.new()
local tr = snd.track.new()
local inst = snd.instrument.new()
local env = snd.envelope.new(0.1, 0.1, 0.5, 0.2)
local lfo = snd.lfo.new(snd.kLFOSine)
local flt = snd.twopolefilter.new(snd.kFilterLowPass)
local dly = snd.delayline.new(0.5)
local cntl = snd.controlsignal.new()
local tm = playdate.timer.new(1000, 0, 10)
local ft = playdate.frameTimer.new(10, 0, 10)
local an = gfx.animator.new(1000, 0, 10)
local pt, pt2 = geo.point.new(1, 2), geo.point.new(3, 5)
local v1, v2 = geo.vector2D.new(1, 2), geo.vector2D.new(3, 4)
local tf = geo.affineTransform.new()
local calls = {
  { "syn:playNote", syn.playNote, syn, 440, 0.5, 0.1 }, { "syn:playMIDINote", syn.playMIDINote, syn, 60, 0.5, 0.1 }, { "syn:noteOff", syn.noteOff, syn },
  { "syn:isPlaying", syn.isPlaying, syn }, { "syn:getVolume", syn.getVolume, syn }, { "syn:setVolume", syn.setVolume, syn, 0.5 }, { "syn:copy", syn.copy, syn },
  { "syn:setADSR", syn.setADSR, syn, 0, 0, 1, 0 }, { "syn:getEnvelope", syn.getEnvelope, syn }, { "syn:setWaveform", syn.setWaveform, syn, snd.kWaveSine },
  { "smp:getLength", smp.getLength, smp }, { "smp:getSampleRate", smp.getSampleRate, smp }, { "smp:getFormat", smp.getFormat, smp }, { "smp:getSubsample", smp.getSubsample, smp, 0, 100 },
  { "sp:play", sp.play, sp }, { "sp:isPlaying", sp.isPlaying, sp }, { "sp:stop", sp.stop, sp }, { "sp:getLength", sp.getLength, sp }, { "sp:getVolume", sp.getVolume, sp },
  { "sp:getRate", sp.getRate, sp }, { "sp:getOffset", sp.getOffset, sp }, { "sp:getSample", sp.getSample, sp }, { "sp:setRange", sp.setRange, sp, 0, 100 }, { "sp:copy", sp.copy, sp },
  { "fp:isPlaying", fp.isPlaying, fp }, { "fp:getLength", fp.getLength, fp }, { "fp:getOffset", fp.getOffset, fp }, { "fp:getVolume", fp.getVolume, fp }, { "fp:getRate", fp.getRate, fp },
  { "fp:play", fp.play, fp }, { "fp:didUnderrun", fp.didUnderrun, fp }, { "fp:load missing", fp.load, fp, "nope" },
  { "ch:addSource", ch.addSource, ch, syn }, { "ch:removeSource", ch.removeSource, ch, syn }, { "ch:getVolume", ch.getVolume, ch }, { "ch:addEffect", ch.addEffect, ch, flt },
  { "ch:removeEffect", ch.removeEffect, ch, flt }, { "ch:getDryLevelSignal", ch.getDryLevelSignal, ch }, { "ch:remove", ch.remove, ch },
  { "seq:getLength", seq.getLength, seq }, { "seq:getTrackCount", seq.getTrackCount, seq }, { "seq:isPlaying", seq.isPlaying, seq }, { "seq:getTempo", seq.getTempo, seq },
  { "seq:getCurrentStep", seq.getCurrentStep, seq }, { "seq:addTrack", seq.addTrack, seq, tr }, { "seq:getTrackAtIndex", seq.getTrackAtIndex, seq, 1 },
  { "tr:addNote", tr.addNote, tr, 1, 60, 4 }, { "tr:getLength", tr.getLength, tr }, { "tr:getNotes", tr.getNotes, tr }, { "tr:getPolyphony", tr.getPolyphony, tr },
  { "tr:getNotesActive", tr.getNotesActive, tr }, { "tr:getInstrument", tr.getInstrument, tr }, { "inst:addVoice", inst.addVoice, inst, syn }, { "inst:getVolume", inst.getVolume, inst },
  { "env:getValue", env.getValue, env }, { "env:trigger", env.trigger, env, 1, 0.5 }, { "lfo:getValue", lfo.getValue, lfo }, { "flt:setFrequency", flt.setFrequency, flt, 1000 },
  { "dly:addTap", dly.addTap, dly, 0.1 }, { "cntl:getValue", cntl.getValue, cntl }, { "cntl:addEvent", cntl.addEvent, cntl, 1, 0.5 },
  { "snd.getCurrentTime", snd.getCurrentTime }, { "snd.resetTime", snd.resetTime }, { "snd.getSampleRate", snd.getSampleRate }, { "snd.kFormat16bitMono", function() return snd.kFormat16bitMono end },
  { "tm.currentTime", function() return tm.currentTime, tm.timeLeft, tm.value, tm.duration end }, { "tm:pause", tm.pause, tm }, { "tm:start", tm.start, tm }, { "tm:remove", tm.remove, tm },
  { "timer.performAfterDelay", playdate.timer.performAfterDelay, 10, function() end }, { "timer.keyRepeatTimer", playdate.timer.keyRepeatTimer, function() end },
  { "ft.frame", function() return ft.frame, ft.value, ft.duration end }, { "an:currentValue", an.currentValue, an }, { "an:valueAtTime", an.valueAtTime, an, 500 }, { "an:progress", an.progress, an },
  { "an:ended", an.ended, an }, { "an:reset", an.reset, an },
  { "pt+v", function() return pt + v1 end }, { "pt-pt", function() return pt2 - pt end }, { "pt*tf", function() return pt * tf end }, { "v*2", function() return v1 * 2 end },
  { "v*v", function() return v1 * v2 end }, { "v+v", function() return v1 + v2 end }, { "-v", function() return -v1 end }, { "v/2", function() return v1 / 2 end }, { "v==v", function() return v1 == geo.vector2D.new(1, 2) end },
  { "pt==pt", function() return pt == geo.point.new(1, 2) end }, { "pt..pt", function() return pt .. pt2 end }, { "tostring pt", tostring, pt }, { "tostring v", tostring, v1 },
  { "tostring rect", tostring, geo.rect.new(1, 2, 3, 4) }, { "tostring line", tostring, geo.lineSegment.new(1, 2, 3, 4) }, { "tostring tf", tostring, tf },
  { "pt.x", function() return pt.x, pt.y end }, { "v.dx", function() return v1.dx, v1.dy, v1.x end }, { "rect fields", function() local r = geo.rect.new(1, 2, 3, 4) return r.x, r.y, r.width, r.height, r.w, r.h, r.top, r.left, r.bottom, r.right, r.size, r.origin end },
  { "tf*tf", function() return tf * geo.affineTransform.new() end }, { "tf:invert", tf.invert, tf }, { "tf:translatedBy", tf.translatedBy, tf, 1, 2 },
  { "geo.vector2D.newPolar", geo.vector2D.newPolar, 2, 90 }, { "geo.size.new", geo.size.new, 3, 4 }, { "geo.arc.new", geo.arc.new, 0, 0, 10, 0, 90 },
  { "arc:length", function() return geo.arc.new(0, 0, 10, 0, 90):length() end }, { "arc:pointOnArc", function() return geo.arc.new(0, 0, 10, 0, 90):pointOnArc(5) end },
  { "math.lerp", math.lerp, 0, 10, 0.5 }, { "string.trimWhitespace", string.trimWhitespace, "  a  " }, { "string.UUID", function() return #string.UUID(8) end },
  { "crankTicks", playdate.getCrankTicks, 6 }, { "gfx.nineSlice.new missing", gfx.nineSlice.new, "nope", 1, 1, 2, 2 },
  { "pd.getSystemMenu:getMenuItems", function() return playdate.getSystemMenu():getMenuItems() end }, { "pd.getSystemMenu:addMenuItem", function() return playdate.getSystemMenu():addMenuItem("x", function() end) end },
  { "menu item fields", function() local m = playdate.getSystemMenu():getMenuItems()[1] return m and m:getTitle(), m and m:getValue() end },
  { "string.format %s nil", string.format, "%s", nil }, { "print return", print, "x" }, { "printTable", printTable, {} },
  { "table.indexOfElement", table.indexOfElement, { 1, 2, 3 }, 2 }, { "table.getsize", table.getsize, { 1, 2, a = 3 } }, { "table.create", table.create, 3, 3 },
  { "table.shallowcopy", function() return #table.shallowcopy({ 1, 2 }) end }, { "table.deepcopy", function() return #table.deepcopy({ 1, { 2 } }) end },
  { "where", where }, { "sample", sample, "x", function() end }, { "playdate.argv", function() return playdate.argv and #playdate.argv end },
  { "pd.isSimulator", function() return playdate.isSimulator end }, { "pd.getFPS", playdate.getFPS }, { "pd.display.getRefreshRate", playdate.display.getRefreshRate },
}
for _, c in ipairs(calls) do run(c[1], table.unpack(c, 2)) end
fh:close()
function playdate.update() end
