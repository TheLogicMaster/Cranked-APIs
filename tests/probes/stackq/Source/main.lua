-- Probe: deep recursion through native calls must raise a Lua error, never overflow the host stack
import "CoreLibs/sprites"
import "CoreLibs/timer"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function w(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end fh:write(table.concat(t, "\t") .. "\n") fh:flush() end
local function short(e) e = tostring(e) return (e:gsub("^.-:%d+: ", "")):sub(1, 60) end
local depth
local function try(name, f) depth = 0 local t0 = playdate.getCurrentTimeMilliseconds() local ok, e = pcall(f) w(name, ok, short(e), depth, playdate.getCurrentTimeMilliseconds() - t0, collectgarbage("count")) end
try("pure lua", function() local function r() depth = depth + 1 return 1 + r() end return r() end)
try("sort comparator", function() local function r() depth = depth + 1 table.sort({3, 2, 1}, function(a, b) r() return a < b end) end r() end)
try("gsub callback", function() local function r() depth = depth + 1 return (("x"):gsub("x", function() return r() end)) end r() end)
try("pcall nest", function() local function r() depth = depth + 1 local ok, e = pcall(r) if not ok then error(e, 0) end end r() end)
try("xpcall nest", function() local function r() depth = depth + 1 local ok, e = xpcall(r, function(m) return m end) if not ok then error(e, 0) end end r() end)
try("coroutine nest", function() local function r() depth = depth + 1 local co = coroutine.wrap(r) co() end r() end)
try("metamethod __index", function() local t = setmetatable({}, {}) getmetatable(t).__index = function(s, k) depth = depth + 1 return s[k] end return t.x end)
try("tostring __tostring", function() local t = setmetatable({}, {}) getmetatable(t).__tostring = function(s) depth = depth + 1 return tostring(s) end return tostring(t) end)
try("__lt via sort", function() local mt = {} mt.__lt = function(a, b) depth = depth + 1 return a < b end local a, b = setmetatable({}, mt), setmetatable({}, mt) return a < b end)
try("performOnAllSprites", function()
  local s = gfx.sprite.new() s:add()
  local function r() depth = depth + 1 gfx.sprite.performOnAllSprites(function() r() end) end
  r() end)
try("pushContext deep", function() local img = gfx.image.new(4, 4) for i = 1, 100000 do depth = depth + 1 gfx.pushContext(img) end end)
for i = 1, depth do pcall(gfx.popContext) end
try("lockFocus deep", function() local img = gfx.image.new(4, 4) for i = 1, 100000 do depth = depth + 1 gfx.lockFocus(img) end end)
gfx.unlockFocus()
try("sprite draw recursion", function()
  local s = gfx.sprite.new() s:setSize(10, 10) s:moveTo(20, 20)
  s.draw = function() depth = depth + 1 s:markDirty() gfx.sprite.update() end
  s:add() gfx.sprite.update() s:remove() end)
try("image draw in context", function() local img = gfx.image.new(4, 4) local function r() depth = depth + 1 gfx.pushContext(img) r() end r() end)
try("json encode nested", function() local t = {} local c = t for i = 1, 100000 do c[1] = {} c = c[1] depth = depth + 1 end return json.encode(t) end)
try("json decode nested", function() depth = 1 local v = json.decode(string.rep("[", 100000) .. string.rep("]", 100000)) return type(v) end)
try("json decode nested obj", function() depth = 1 local v = json.decode(string.rep('{"a":', 100000) .. "1" .. string.rep("}", 100000)) return type(v) end)
try("deepcopy deep", function() local t = {} local c = t for i = 1, 5000 do c[1] = {} c = c[1] end depth = 1 return table.deepcopy and type(table.deepcopy(t)) end)
try("printTable deep", function() local t = {} local c = t for i = 1, 300 do c[1] = {} c = c[1] end depth = 1 return printTable and pcall(printTable, t) end)
try("string.rep huge", function() depth = 1 return #string.rep("x", 2^31) end)
try("load nested", function() return load(string.rep("(", 10000) .. "1" .. string.rep(")", 10000)) end)
try("timer callback nest", function() local function r() depth = depth + 1 local t = playdate.timer.new(0, r) playdate.timer.updateTimers() end r() end)
w("done")
fh:close()
function playdate.update() end
