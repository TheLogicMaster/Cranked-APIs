-- Lua API fuzzer. Calls every function in the playdate tables (and every method of the classes it
-- can make an instance of) with random arguments inside pcall. A host crash, a hang or a slow call is the finding;
-- Lua errors are expected. Before each call the call is written to progress.txt, so the last line names the call
-- that crashed or hung. Usage: run for long enough; results in fuzz.txt.
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
local gfx <const> = playdate.graphics
local snd <const> = playdate.sound
local geo <const> = playdate.geometry

local SEED = 1234
local CALLS_PER_FUNCTION = 12
local PER_FRAME = 60
do -- config.txt (written by run.sh): calls per function, then the seed
    local f = playdate.file.open("config.txt")
    if f then
        local l = f:readline(); f:close()
        local c, sd = (l or ""):match("(%d+)%s+(%d+)")
        if c then CALLS_PER_FUNCTION = tonumber(c); SEED = tonumber(sd) end
    end
end
math.randomseed(SEED)

local skip = {
    ["playdate.stop"] = true, ["playdate.restart"] = true, ["playdate.wait"] = true, ["playdate.start"] = true, ["playdate.exitToLauncher"] = true,
    ["playdate.update"] = true, ["playdate.simulator.exit"] = true, ["playdate.simulator.writeToFile"] = true,
    ["playdate.gameWillTerminate"] = true, ["playdate.deviceWillSleep"] = true, ["playdate.deviceWillLock"] = true,
    ["playdate.file.run"] = true, ["playdate.file.load"] = true, -- would run arbitrary game files
    ["playdate.setCollectsGarbage"] = true, ["playdate.setMinimumGCTime"] = true, ["playdate.setGCScaling"] = true,
    ["playdate.display.setRefreshRate"] = true, -- keeps the run's length predictable
    ["playdate.graphics.sprite.removeAll"] = false,
    ["playdate.inputHandlers.pop"] = true, ["playdate.inputHandlers.push"] = true,
    ["playdate.system.exit"] = true,
    ["playdate.file.delete"] = true, ["playdate.file.rename"] = true, -- would remove the fuzzer's own logs
}

-- instances for the classes
local inst = {}
local function add(name, f) local ok, v = pcall(f); if ok and v ~= nil then inst[#inst + 1] = { name, v } end end
add("image", function() return gfx.image.new(24, 16, gfx.kColorBlack) end)
add("image2", function() return gfx.image.new(5, 3) end)
add("font", function() return gfx.getSystemFont() end)
add("sprite", function() local s = gfx.sprite.new(gfx.image.new(8, 8)); return s end)
add("imagetable", function() local t = gfx.imagetable.new(3); for i = 1, 3 do t:setImage(i, gfx.image.new(8, 8)) end; return t end)
add("tilemap", function() local m = gfx.tilemap.new(); local t = gfx.imagetable.new(2); t:setImage(1, gfx.image.new(8, 8)); t:setImage(2, gfx.image.new(8, 8)); m:setImageTable(t); m:setSize(4, 4); return m end)
add("nineslice", function() return gfx.nineSlice and gfx.nineSlice.new and nil end)
add("sample", function() return snd.sample.new(0.1) end)
add("sampleplayer", function() return snd.sampleplayer.new(snd.sample.new(0.1)) end)
add("fileplayer", function() return snd.fileplayer.new() end)
add("synth", function() return snd.synth.new(snd.kWaveSine) end)
add("lfo", function() return snd.lfo.new() end)
add("envelope", function() return snd.envelope.new() end)
add("channel", function() return snd.channel.new() end)
add("instrument", function() return snd.instrument.new() end)
add("sequence", function() return snd.sequence.new() end)
add("track", function() return snd.track.new() end)
add("controlsignal", function() return snd.controlsignal.new() end)
add("delayline", function() return snd.delayline.new(0.1) end)
add("bitcrusher", function() return snd.bitcrusher.new() end)
add("ringmod", function() return snd.ringmod.new() end)
add("onepolefilter", function() return snd.onepolefilter.new() end)
add("twopolefilter", function() return snd.twopolefilter.new(snd.kFilterLowPass) end)
add("overdrive", function() return snd.overdrive.new() end)
add("micinput", function() return nil end)
add("point", function() return geo.point.new(1, 2) end)
add("vector2D", function() return geo.vector2D.new(1, 2) end)
add("rect", function() return geo.rect.new(1, 2, 3, 4) end)
add("size", function() return geo.size.new(3, 4) end)
add("affineTransform", function() return geo.affineTransform.new() end)
add("lineSegment", function() return geo.lineSegment.new(0, 0, 5, 5) end)
add("arc", function() return geo.arc.new(10, 10, 5, 0, 90) end)
add("polygon", function() return geo.polygon.new(0, 0, 10, 0, 5, 5, 0, 0) end)
add("graph", function() return playdate.pathfinder.graph.new2DGrid(4, 4, true) end)
add("node", function() local g = playdate.pathfinder.graph.new2DGrid(3, 3); return g:nodeWithXY(1, 1) end)
add("menu", function() return playdate.getSystemMenu() end)
add("file", function() return playdate.file.open("fuzzfile.txt", playdate.file.kFileWrite) end)
add("video", function() return nil end)
add("timer", function() return playdate.timer and playdate.timer.new(100) or nil end)

local function classOf(v)
    local mt = getmetatable(v)
    if type(mt) ~= "table" then return nil end
    return mt
end
local byClass = {}
for _, e in ipairs(inst) do
    local mt = classOf(e[2])
    if mt then byClass[mt] = e[2]; if type(mt.__index) == "table" then byClass[mt.__index] = e[2] end end
end

local pool = {
    0, 1, -1, 2, 3, 7.5, -0.5, 255, 1000, -1000, 65536, 2147483647, -2147483648, 4294967296, 1e7, -1e7,
    0 / 0, math.huge, -math.huge, 0.001, "", "abc", "C4", "assets/none", "%s%s%n", "\0", true, false, nil, {}, { 1, 2, 3 },
    { x = 1, y = 2 }, function() end, function() return 1 end,
}
for _, e in ipairs(inst) do pool[#pool + 1] = e[2] end
local NPOOL = #pool + 1 -- nil is in the pool: index past the end gives nil as well

local function randomArg() return pool[math.random(1, NPOOL)] end

-- collect functions
local funcs = {}
local seen = {}
local function walk(t, path, depth)
    if seen[t] or depth > 4 then return end
    seen[t] = true
    local keys = {}
    for k in pairs(t) do if type(k) == "string" then keys[#keys + 1] = k end end
    table.sort(keys)
    for _, k in ipairs(keys) do
        local v = rawget(t, k)
        local p = path .. "." .. k
        if type(v) == "function" then
            if not skip[p] and k ~= "__gc" and k ~= "__close" and k ~= "update" and not k:match("^__") then funcs[#funcs + 1] = { p, v, t } end
        elseif type(v) == "table" and k ~= "inputHandlers" and k ~= "_G" and k ~= "__index" then
            walk(v, p, depth + 1)
        end
    end
end
walk(playdate, "playdate", 0)

-- functions to leave out (the driver adds each one that crashed or hung), one name per line
do
    local f = playdate.file.open("skip.txt")
    if f then while true do local l = f:readline(); if not l then break end; if #l > 0 then skip[l] = true end end; f:close() end
    local kept = {}
    for _, e in ipairs(funcs) do if not skip[e[1]] then kept[#kept + 1] = e end end
    funcs = kept
end
local function hash(s) local h = 5381; for i = 1, #s do h = (h * 33 + s:byte(i)) % 2147483647 end; return h end
local progress = playdate.file.open("progress.txt", playdate.file.kFileWrite)
local out = playdate.file.open("fuzz.txt", playdate.file.kFileWrite)
out:write("functions " .. #funcs .. "\n"); out:flush()
local fi, ci, total, errors, slow = 1, 0, 0, 0, 0
local finished = false

local function step()
    local f = funcs[fi]
    local name, fn, owner = f[1], f[2], f[3]
    if ci == 0 then math.randomseed(SEED + hash(name)) end -- each function's calls do not depend on the others
    local args, n = {}, math.random(0, 5)
    local self = byClass[owner]
    local start = 1
    if self and math.random() < 0.85 then args[1] = self; start = 2; n = math.max(n, 1) end
    for i = start, n do args[i] = randomArg() end
    local desc = {}
    for i = 1, n do local a = args[i]; local d = type(a) == "userdata" and "<" .. (getmetatable(a) and (getmetatable(a).__name or "?") or "?") .. ">" or type(a) == "table" and (getmetatable(a) and "<object>" or "{}") or type(a) == "string" and string.format("%q", a) or tostring(a); desc[i] = d end
    progress:write(name .. " #" .. ci .. " (" .. table.concat(desc, ", ") .. ")\n"); progress:flush()
    local t0 = playdate.getCurrentTimeMilliseconds()
    local ok, err = pcall(fn, table.unpack(args, 1, n))
    local dt = playdate.getCurrentTimeMilliseconds() - t0
    total = total + 1
    if not ok then errors = errors + 1 end
    if dt > 200 then slow = slow + 1; out:write("SLOW " .. dt .. " ms " .. name .. " #" .. ci .. "\n"); out:flush() end
    ci = ci + 1
    if ci >= CALLS_PER_FUNCTION then ci = 0; fi = fi + 1 end
end

function playdate.update()
    if finished then return end
    -- keep drawing state sane between frames
    pcall(gfx.setDrawOffset, 0, 0); pcall(gfx.clearClipRect); pcall(gfx.setImageDrawMode, gfx.kDrawModeCopy)
    for _ = 1, PER_FRAME do
        if fi > #funcs then
            finished = true
            out:write(string.format("done calls %d errors %d slow %d\n", total, errors, slow)); out:close(); progress:close()
            if playdate.simulator then playdate.simulator.exit() end
            return
        end
        step()
    end
end
