-- Probe for update-loop and video functions.
local gfx = playdate.graphics
local cases6 = {}
local function c(name, f) cases6[#cases6 + 1] = { name, f } end
local function all(...) local p = table.pack(...); local o = {}; for i = 1, p.n do local x = p[i]; o[i] = (type(x) == "number" and (tostring(x) .. (math.type(x) == "integer" and "i" or "f"))) or tostring(x) end; return table.concat(o, " | ") end
local function dump(img) local w, h = img:getSize(); local rows = {}; for y = 0, h - 1 do local b = {}; for x = 0, w - 1 do local s = img:sample(x, y); b[#b + 1] = s == gfx.kColorWhite and "1" or (s == gfx.kColorBlack and "0" or "x") end; rows[#rows + 1] = table.concat(b) end; return "PIX:" .. w .. "x" .. h .. ":" .. table.concat(rows, "/") end
local VIDEO = "video/appear_frames"
c("video.new", function() local v = gfx.video.new(VIDEO); return all(v ~= nil, v and v:getSize()) end)
c("video.new missing", function() return all(gfx.video.new("video/none")) end)
c("video:getFrameCount/getFrameRate", function() local v = gfx.video.new(VIDEO); return all(v:getFrameCount(), v:getFrameRate()) end)
c("video:getContext", function() local v = gfx.video.new(VIDEO); local ctx = v:getContext(); local w, h = ctx:getSize(); return all(w, h) end)
c("video:setContext/renderFrame", function() local v = gfx.video.new(VIDEO); local w, h = v:getSize(); local img = gfx.image.new(w, h, gfx.kColorWhite); v:setContext(img); v:renderFrame(10); local black = 0; for y = 0, h - 1, 4 do for x = 0, w - 1, 4 do if img:sample(x, y) == gfx.kColorBlack then black = black + 1 end end end; return all(black) end)
c("video:renderFrame out of range", function() local v = gfx.video.new(VIDEO); v:setContext(gfx.image.new(v:getSize())); return all(pcall(v.renderFrame, v, 100000)) end)
c("video:useScreenContext", function() local v = gfx.video.new(VIDEO); v:useScreenContext(); return "ok" end)
c("wait inside update", function() local t0 = playdate.getCurrentTimeMilliseconds(); playdate.wait(30); local dt = playdate.getCurrentTimeMilliseconds() - t0; return all(dt >= 25, dt < 500) end)
c("drawLocalizedTextInRect missing key", function() local img = gfx.image.new(48, 24, gfx.kColorWhite); gfx.pushContext(img); gfx.drawLocalizedTextInRect("no_such_key", 0, 0, 48, 24); gfx.popContext(); return dump(img) end)
function caseNames6() local n = {}; for i, x in ipairs(cases6) do n[i] = x[1] end; return n end
function runCases6(write, skip)
    skip = skip or {}
    for _, case in ipairs(cases6) do
        if not skip[case[1]] then
            local ok, r = pcall(case[2])
            local out = ok and tostring(r) or ("ERR " .. tostring(r))
            write(case[1] .. "\t" .. out:gsub("\n", "\\n"):gsub("\t", "\\t"))
        end
    end
end
