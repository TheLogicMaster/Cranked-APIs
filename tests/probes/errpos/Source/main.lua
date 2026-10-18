-- Probe: whether errors raised by API functions carry the calling Lua line
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function rec(name, ok, e) fh:write(name .. " " .. tostring(ok) .. " " .. tostring(e) .. "\n") end
rec("direct pcall image.new", pcall(gfx.image.new, 0, 20))
rec("from Lua image.new", pcall(function() return gfx.image.new(0, 20) end))
rec("from Lua file.run", pcall(function() return playdate.file.run("nope") end))
rec("from Lua setMenuImage", pcall(function() return playdate.setMenuImage(5) end))
rec("from Lua wait", pcall(function() return playdate.wait(1) end))
rec("from Lua image:draw bad", pcall(function() return gfx.image.new(4, 4):draw("x") end))
rec("from Lua sprite.new(5)", pcall(function() return gfx.sprite.new(5) end))
rec("from Lua error()", pcall(function() error("mine") end))
rec("from Lua error level 2", pcall(function() error("mine2", 2) end))
rec("from Lua string.rep", pcall(function() return string.rep("x", -1, 5) end))
rec("from Lua math.floor('a')", pcall(function() return math.floor("a") end))
rec("from Lua setmetatable", pcall(function() return setmetatable(1, {}) end))
rec("nested", pcall(function() local function inner() return gfx.image.new(0, 1) end return inner() end))
fh:close()
function playdate.update() end
