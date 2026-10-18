-- Probe: whether setmetatable and getmetatable work on userdata (host addresses print as ADDR)
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function rec(name, ok, ...) local t = {} for _, v in ipairs({...}) do t[#t + 1] = (tostring(v):gsub("0x%x+", "ADDR")) end fh:write(name .. " " .. tostring(ok) .. " " .. table.concat(t, " ") .. "\n") end
local img = gfx.image.new(4, 4)
local orig = getmetatable(img)
rec("getmetatable name", true, orig and orig.__name)
local mt = { __index = function(t, k) return "custom " .. k end, __name = "mine" }
rec("setmetatable image", pcall(setmetatable, img, mt))
rec("after: index", pcall(function() return img.foo end))
rec("after: getSize", pcall(function() return img:getSize() end))
rec("getmetatable after", true, getmetatable(img) == mt, getmetatable(img) == orig)
rec("tostring", pcall(tostring, img))
local s = gfx.sprite.new()
rec("setmetatable sprite", pcall(setmetatable, s, { __index = gfx.sprite }))
rec("setmetatable nil", pcall(setmetatable, gfx.image.new(2, 2), nil))
rec("setmetatable number", pcall(setmetatable, 5, {}))
rec("setmetatable protected", pcall(setmetatable, setmetatable({}, { __metatable = "locked" }), {}))
rec("rawequal", true, rawequal(img, img))
fh:close()
function playdate.update() end
