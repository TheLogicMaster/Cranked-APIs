-- Probe suite runner: runs the Lua probes packed into this bundle one after another, so that one install and one
-- launch on a Playdate runs them all. build_suite.py writes manifest.json and copies each probe's compiled files to
-- p/<name>/ in the bundle.
--
-- Each probe's main.pdz is run with playdate.file.run in an environment table of its own, in a coroutine. While it
-- runs:
-- - every relative path it gives a file, datastore, image, font, sound or JSON function is redirected to p/<name>/,
--   so its assets are found in the bundle and its outputs land in the suite's data folder under p/<name>/;
-- - print goes to p/<name>/console.txt;
-- - playdate.simulator.exit() and playdate.stop() (which probes call when they finish) end the probe;
-- - errors in its update are caught and written to p/<name>/error.txt.
-- A probe also ends after manifest.maxFrames frames, or after `idleFrames` frames without output once it has
-- written something. Between probes the runner puts back the playdate table's callbacks and resets the graphics,
-- display, sprite, timer, menu and input state.
--
-- Progress is in the data folder's suite.txt: a line when a probe starts and one with how it ended. Hold B at launch
-- to start again from the first probe; otherwise a run that was interrupted continues where it stopped.

local gfx <const> = playdate.graphics
local rawOpen = playdate.file.open -- the runner's own files: not redirected, and not counted as a probe's output
local realSimulator = playdate.simulator
local runFile = playdate.file.run
local manifest = json.decodeFile("manifest.json")
local probes = manifest.probes
local idleFrames = manifest.idleFrames or 150

local function logLine(text) -- opened and closed each time, so that the runner holds no file open while a probe runs
  local f = rawOpen("suite.txt", playdate.file.kFileAppend)
  if f then f:write(text .. "\n"); f:close() end
end

-- the probes already finished (a run that was interrupted continues after them). suite.txt has "<name> started"
-- when a probe starts and "<name> <how it ended> frames=<n>" when it ends. A probe that started and did not end was
-- running when the run stopped: it is run again once, and skipped (logged as "crashed") if that happens twice.
local finished = {}
if not playdate.buttonIsPressed(playdate.kButtonB) then
  local f = rawOpen("suite.txt")
  local open, interrupted = nil, {}
  if f then
    while true do
      local line = f:readline(); if not line then break end
      local name, what = line:match("^(%S+) (%S+)")
      if name == "suite" then
      elseif what == "started" then open = name
      elseif what == "interrupted" then interrupted[name] = true; open = nil
      elseif name then finished[name] = true; open = nil end
    end
    f:close()
  end
  if open then
    if interrupted[open] then finished[open] = true; logLine(open .. " crashed frames=0")
    else logLine(open .. " interrupted") end
  end
else
  playdate.file.delete("suite.txt")
end

-- path redirection -------------------------------------------------------------------------------------------------

local prefix = ""      -- "p/<name>/" while a probe runs
local lastOutput = 0   -- frame of the probe's last output (file write, print); 0 until the first
local frame = 0
local function redirect(path)
  if type(path) ~= "string" or prefix == "" then return path end
  if path:sub(1, 8) == "/System/" or path:sub(1, 7) == "System/" then return path end
  while path:sub(1, 1) == "/" or path:sub(1, 2) == "./" do path = path:sub(path:sub(1, 1) == "/" and 2 or 3) end
  return prefix .. path
end

-- wrap(table, function name, indexes of path arguments): the paths are redirected. A read that finds nothing at the
-- redirected path is tried again with the path as given, for assets compiled into the probe's code (pdc stores an
-- imported image or sound in main.pdz under its own name), and for files at the bundle's root.
-- The original function is called through pcall, so an error it raises has no position of the runner's; it is raised
-- again at the probe's call (error level 3), with the redirected path put back as the probe gave it. Errors that
-- already carry a position (from Lua code the call ran, such as a chunk file.run ran) are raised unchanged.
local function call(original, args)
  local r = table.pack(pcall(original, table.unpack(args, 1, args.n)))
  if r[1] then return true, r end
  return false, r[2]
end
local function unredirect(msg) -- the redirected paths in a message put back as the probe gave them
  if type(msg) ~= "string" or prefix == "" then return msg end
  local i = msg:find(prefix, 1, true)
  while i do msg = msg:sub(1, i - 1) .. msg:sub(i + #prefix); i = msg:find(prefix, i, true) end
  return msg
end
local function raise(msg)
  if type(msg) ~= "string" then error(msg, 0) end
  msg = unredirect(msg)
  if msg:match("^[^%s:]+:%d+: ") then error(msg, 0) end
  error(msg, 3)
end
local readers = { open = true, exists = true, isdir = true, getSize = true, getType = true, modtime = true,
  listFiles = true, load = true, read = true, readImage = true, new = true, decodeFile = true, imageSizeAtPath = true }
local function wrap(t, name, ...)
  if not t or type(t[name]) ~= "function" then return end
  local original, indexes = t[name], { ... }
  t[name] = function(...)
    local args = table.pack(...)
    local given = table.pack(...)
    local changed = false
    for _, i in ipairs(indexes) do
      local r = redirect(args[i]); if r ~= args[i] then changed = true end; args[i] = r
    end
    local isRead = readers[name]
      and not (t == playdate.file and name == "open" and args[2] and args[2] ~= playdate.file.kFileRead)
    local ok, r = call(original, args)
    if changed and isRead and not (ok and r[2] ~= nil and r[2] ~= false) then
      -- the retry's result is used only when it finds something; otherwise the first call's (its error names the
      -- probe's file, which exists and could not be read)
      local ok2, r2 = call(original, given)
      if ok2 and r2[2] ~= nil and r2[2] ~= false then ok, r = ok2, r2 end
    end
    if not ok then raise(r) end
    -- an error message returned with nil ("file p/<name>/x not found") names the path as the probe gave it
    if changed and r[2] == nil then for i = 3, r.n do r[i] = unredirect(r[i]) end end
    return table.unpack(r, 2, r.n)
  end
end
local snd = playdate.sound
local file = playdate.file
wrap(file, "open", 1); wrap(file, "exists", 1); wrap(file, "isdir", 1); wrap(file, "mkdir", 1); wrap(file, "delete", 1)
wrap(file, "getSize", 1); wrap(file, "getType", 1); wrap(file, "modtime", 1); wrap(file, "rename", 1, 2)
wrap(file, "listFiles", 1); wrap(file, "load", 1); wrap(file, "run", 1)
wrap(playdate.datastore, "read", 1); wrap(playdate.datastore, "write", 2); wrap(playdate.datastore, "delete", 1)
wrap(playdate.datastore, "readImage", 1); wrap(playdate.datastore, "writeImage", 2)
-- datastore images: a name without a folder is stored in the data folder's images/ (measured, tests/probes/dsimg),
-- one with a folder where it says. The redirected name always has a folder, so images/ is added before the
-- redirection (this wrapper is outside it).
do
  local function imageName(path)
    if type(path) == "string" and prefix ~= "" and not path:find("/", 1, true) then return "images/" .. path end
    return path
  end
  local ds = playdate.datastore
  local readImage, writeImage = ds.readImage, ds.writeImage
  ds.readImage = function(path, ...) return readImage(imageName(path), ...) end
  ds.writeImage = function(image, path, ...) return writeImage(image, imageName(path), ...) end
end
wrap(gfx.image, "new", 1); wrap(gfx.image, "load", 2); wrap(gfx.imagetable, "new", 1); wrap(gfx.imagetable, "load", 2)
wrap(gfx.font, "new", 1); wrap(gfx.video, "new", 1); wrap(gfx, "imageSizeAtPath", 1)
wrap(snd.sample, "new", 1); wrap(snd.sample, "load", 2); wrap(snd.sampleplayer, "new", 1)
wrap(snd.fileplayer, "new", 1); wrap(snd.fileplayer, "load", 2); wrap(snd.sequence, "new", 1)
wrap(json, "decodeFile", 1); wrap(json, "encodeToFile", 1)
-- font.newFamily takes a table of paths
if gfx.font.newFamily then
  local original = gfx.font.newFamily
  gfx.font.newFamily = function(paths)
    local t = {}
    for k, v in pairs(paths or {}) do t[k] = redirect(v) end
    return original(t)
  end
end
-- writes count as output
do
  local original = file.open
  file.open = function(path, mode, ...)
    if mode == file.kFileWrite or mode == file.kFileAppend then lastOutput = frame end
    return original(path, mode, ...)
  end
end

-- CoreLibs is imported once, here: a module imported again is not run again, so a probe that imports one finds its
-- globals (class, kTextAlignment, playdate.timer, ...) through _G. Probes that test behaviour without CoreLibs are
-- excluded (excluded.txt). It is imported after the wrappers above are installed, since CoreLibs keeps its own
-- references to some functions (nineslice keeps playdate.graphics.image.new).
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/frameTimer"
import "CoreLibs/animation"
import "CoreLibs/animator"
import "CoreLibs/easing"
import "CoreLibs/nineslice"
import "CoreLibs/ui"
import "CoreLibs/crank"
import "CoreLibs/keyboard"
import "CoreLibs/math"
import "CoreLibs/string"
import "CoreLibs/qrcode"
import "CoreLibs/accelerometer"
import "CoreLibs/logic"


-- state between probes ----------------------------------------------------------------------------------------------

-- the fields of the playdate tables as they are now (after CoreLibs and the wrappers), put back between probes: a
-- probe may replace a function or add fields, in playdate itself or in the tables under it
local saved = {}
local function snapshot(t, depth)
  if type(t) ~= "table" or saved[t] then return end
  local copy = {}
  saved[t] = copy
  for k, v in pairs(t) do
    copy[k] = v
    if depth > 0 and type(v) == "table" then snapshot(v, depth - 1) end
  end
end
snapshot(playdate, 2); snapshot(json, 0)
local function restore()
  for t, copy in pairs(saved) do
    local extra = {}
    for k in pairs(t) do if copy[k] == nil then extra[#extra + 1] = k end end
    for _, k in ipairs(extra) do pcall(function() t[k] = nil end) end
    for k, v in pairs(copy) do if rawget(t, k) ~= v then pcall(function() t[k] = v end) end end
  end
end
local systemFonts = {}
for _, variant in ipairs({ "normal", "bold", "italic" }) do
  local f = gfx.getSystemFont(variant)
  if f then systemFonts[variant] = { font = f, leading = f:getLeading(), tracking = f:getTracking() } end
end

-- A draw straight to the frame (outside sprite drawing) marks its area dirty for the next sprite update, and so do
-- removed sprites. settle() runs a sprite update with only an offscreen sprite of its own, which uses up that dirty
-- area, so that a probe's first sprite update redraws only what the probe changed.
local function settle()
  pcall(function()
    local s = gfx.sprite.new(); s:setSize(1, 1); s:moveTo(-10, -10); s:add()
    gfx.sprite.update(); s:remove(); gfx.sprite.update()
  end)
end

local function resetState()
  pcall(function() gfx.sprite.setBackgroundDrawingCallback(nil) end) -- CoreLibs keeps its background sprite
  restore()
  playdate.simulator = nil
  pcall(function() gfx.sprite.removeAll() end)
  pcall(function() gfx.sprite.setAlwaysRedraw(false) end)
  pcall(function() for _, s in ipairs(playdate.sound.playingSources()) do s:stop() end end)
  pcall(function() playdate.setCollectsGarbage(true) end)
  pcall(function() playdate.sound.resetTime(); playdate.resetElapsedTime() end) -- the clocks a probe can reset
  for _, timers in ipairs({ playdate.timer, playdate.frameTimer }) do
    pcall(function() for _, t in ipairs(timers.allTimers()) do t:remove() end end)
  end
  pcall(function() playdate.getSystemMenu():removeAllMenuItems() end)
  pcall(function() playdate.setMenuImage(nil) end)
  pcall(function() for _ = 1, 16 do playdate.inputHandlers.pop() end end)
  pcall(function() playdate.stopAccelerometer() end)
  pcall(function() playdate.setAutoLockDisabled(true); playdate.setCrankSoundsDisabled(false) end)
  pcall(function()
    -- set only when changed: a display change makes the sprite system redraw the whole screen on the next update
    local d = playdate.display
    if d.getRefreshRate() ~= 30 then d.setRefreshRate(30) end
    if d.getScale() ~= 1 then d.setScale(1) end
    if d.getInverted() then d.setInverted(false) end
    local mx, my = d.getMosaic(); if mx ~= 0 or my ~= 0 then d.setMosaic(0, 0) end
    local ox, oy = d.getOffset(); if ox ~= 0 or oy ~= 0 then d.setOffset(0, 0) end
    local fx, fy = d.getFlipped(); if fx or fy then d.setFlipped(false, false) end
  end)
  pcall(function()
    gfx.setDrawOffset(0, 0); gfx.clearClipRect(); gfx.setColor(gfx.kColorBlack); gfx.setBackgroundColor(gfx.kColorWhite)
    gfx.setImageDrawMode(gfx.kDrawModeCopy); gfx.setLineWidth(1); gfx.setLineCapStyle(gfx.kLineCapStyleButt)
    gfx.setStrokeLocation(gfx.kStrokeCentered); gfx.setPolygonFillRule(gfx.kPolygonFillNonZero)
    for variant, f in pairs(systemFonts) do
      f.font:setLeading(f.leading); f.font:setTracking(f.tracking); gfx.setFont(f.font, variant)
    end
    gfx.setFont(gfx.getSystemFont()); gfx.setFontTracking(0); gfx.setStencilImage(nil)
    gfx.clear(gfx.kColorWhite)
  end)
  collectgarbage("collect")
  gfx.clear(gfx.kColorWhite)
  collectgarbage("collect")
end

-- running one probe -------------------------------------------------------------------------------------------------

local index, current, probeUpdate, probeFrames, ended = 0, nil, nil, 0, nil
local realPrint = print

local suiteUpdate
local function finish(reason)
  if not current then return end
  local name = current.name
  prefix = ""
  logLine(string.format("%s %s frames=%d", name, reason, probeFrames))
  current, probeUpdate = nil, nil
  resetState()
  playdate.update = suiteUpdate
end

local function writeText(name, file_, text)
  local f = rawOpen("p/" .. name .. "/" .. file_, playdate.file.kFileAppend)
  if f then f:write(text); f:close() end
end

local function start(probe)
  current, probeFrames, ended, lastOutput = probe, 0, nil, 0
  logLine(probe.name .. " started")
  playdate.file.mkdir("p/" .. probe.name)
  prefix = "p/" .. probe.name .. "/"
  local env = setmetatable({}, { __index = _G })
  env.print = function(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[#parts + 1] = tostring((select(i, ...))) end
    lastOutput = frame
    writeText(probe.name, "console.txt", table.concat(parts, "\t") .. "\n")
  end
  playdate.simulator = { exit = function() ended = "exit" end }
  playdate.stop = function() ended = ended or "stop" end -- probes stop their update loop when done
  playdate.start = function() end
  playdate.update = nil
  -- the main chunk runs in a coroutine of its own, as a game's does (not the thread the update runs on). runFile is
  -- the unredirected file.run (file.load does not take a .pdz with imports). The chunk cannot yield: file.run calls it
  -- from C.
  local co = coroutine.create(function() return runFile("p/" .. probe.name .. "/main.pdz", env) end)
  local ok, err = coroutine.resume(co)
  if ok and coroutine.status(co) ~= "dead" then ok, err = false, "the main chunk yielded" end
  if not ok then
    writeText(probe.name, "error.txt", tostring(err) .. "\n")
    finish("load-error")
    return
  end
  probeUpdate = playdate.update
  playdate.update = nil
  if not probeUpdate then finish("no-update") end
end

local function step()
  frame += 1
  if current then
    probeFrames += 1
    if probeUpdate then
      local ok, err = pcall(probeUpdate)
      if not ok then writeText(current.name, "error.txt", tostring(err) .. "\n"); finish("update-error"); return end
      -- the probe may have replaced its update function
      if playdate.update and playdate.update ~= suiteUpdate then probeUpdate = playdate.update end
      playdate.update = suiteUpdate
    end
    if not current then return end
    local limit = current.frames or manifest.maxFrames or 900
    if ended then finish(ended)
    elseif probeFrames >= limit then finish("frame-limit")
    elseif lastOutput > 0 and frame - lastOutput >= (current.idle or idleFrames)
      and probeFrames > (current.minFrames or 30) then
      finish("idle")
    end
    return
  end
  repeat index += 1 until index > #probes or not finished[probes[index].name]
  if index > #probes then
    gfx.clear(gfx.kColorWhite); gfx.drawTextAligned("Probe suite done", 200, 110, kTextAlignment.center)
    if ended ~= "done" then logLine("suite done"); ended = "done" end
    playdate.update = function() end
    if realSimulator then realSimulator.exit() end
    return
  end
  -- the progress line is shown for a moment, then the screen is cleared again, so that the probe starts with a white
  -- display (some probes read the display image)
  gfx.clear(gfx.kColorWhite)
  gfx.drawText(string.format("%d/%d %s", index, #probes, probes[index].name), 4, 4)
  playdate.display.flush()
  gfx.clear(gfx.kColorWhite)
  settle()
  playdate.display.flush()
  start(probes[index])
  playdate.update = suiteUpdate
end

-- an error in the runner itself is logged to suite.txt, and the probe that was running ends with "runner-error"
function suiteUpdate()
  local ok, err = pcall(step)
  if not ok then
    logLine("runner error: " .. tostring(err))
    if current then pcall(finish, "runner-error") end
    playdate.update = suiteUpdate
  end
end

playdate.setAutoLockDisabled(true) -- a run takes longer than the auto-lock delay
playdate.update = suiteUpdate
