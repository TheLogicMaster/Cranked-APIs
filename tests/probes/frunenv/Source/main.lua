-- Probe: playdate.file.run(path, env) with a separately compiled file that imports a module: which table the file's
-- globals and the imported module's globals land in. pdc compiles every .lua file in Source/ to a .pdz of its own, so
-- the bundle has p/demo/main.pdz (with helper inside it) and p/demo/helper.pdz. Also file.load with a file that imports
-- another, and with one that imports nothing.
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function log(s) fh:write(s .. "\n") fh:flush() end
local printed = {}
local env = setmetatable({ print = function(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end printed[#printed + 1] = table.concat(t, " ") end }, { __index = _G })
local ok, err = pcall(playdate.file.run, "p/demo/main.pdz", env)
log("run ok " .. tostring(ok) .. " " .. tostring(err))
for _, line in ipairs(printed) do log("printed: " .. line) end
log("myGlobal env " .. tostring(rawget(env, "myGlobal")) .. " _G " .. tostring(rawget(_G, "myGlobal")))
log("helperValue env " .. type(rawget(env, "helperValue")) .. " _G " .. type(rawget(_G, "helperValue")))
log("update env " .. type(rawget(env, "playdate")) .. " playdate.update set " .. tostring(playdate.update ~= nil))
-- without env: globals go to _G
local ok2 = pcall(playdate.file.run, "p/demo/main.pdz")
log("no env: myGlobal _G " .. tostring(rawget(_G, "myGlobal")) .. " helperValue _G " .. type(rawget(_G, "helperValue")))
-- file.load with the same file, and with a file that imports nothing
local okl, el = pcall(function() local f = playdate.file.load("p/demo/main.pdz", env) return f end)
log("load with imports " .. tostring(okl) .. " " .. tostring(el):gsub("0x%x+", "ADDR"))
local okl2, el2 = pcall(playdate.file.load, "p/demo/main.pdz")
log("load with imports, direct pcall " .. tostring(okl2) .. " " .. tostring(el2):gsub("0x%x+", "ADDR"))
local okh, eh = pcall(function() return playdate.file.load("p/demo/helper.pdz") end)
log("load without imports " .. tostring(okh) .. " " .. type(eh))
fh:close()
function playdate.update() if playdate.simulator then playdate.simulator.exit() end end
