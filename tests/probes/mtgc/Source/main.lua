-- Probe: where native objects' finalizers live (the class metatable's __gc) and whether metatables are protected
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local objs = { image = gfx.image.new(4, 4), font = gfx.getSystemFont(), synth = playdate.sound.synth.new(), sample = playdate.sound.sample.new(0.01),
  imagetable = gfx.imagetable.new(1), tilemap = gfx.tilemap.new(), file = playdate.file.open("x.txt", playdate.file.kFileWrite), point = playdate.geometry.point.new(1, 2) }
local names = {} for k in pairs(objs) do names[#names + 1] = k end table.sort(names)
for _, k in ipairs(names) do
  local o = objs[k]
  local mt = getmetatable(o)
  fh:write(string.format("%s type=%s mt=%s gc=%s protected=%s\n", k, type(o), mt and tostring(rawget(mt, "__name")) or "nil", mt and type(rawget(mt, "__gc")) or "-", mt and tostring(rawget(mt, "__metatable") ~= nil) or "-"))
end
-- a finalizer kept in the user value would still run after the swap: count images freed via a weak table
local weak = setmetatable({}, { __mode = "k" })
for i = 1, 50 do local im = gfx.image.new(8, 8) weak[im] = true setmetatable(im, {}) end
collectgarbage("collect") collectgarbage("collect")
local n = 0 for _ in pairs(weak) do n = n + 1 end
fh:write("swapped images still referenced: " .. n .. "\n")
fh:close()
function playdate.update() end
