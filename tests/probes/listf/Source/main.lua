import "mod"
-- Probe: playdate.file.listFiles on compiled bundle folders (names, extensions, order, trailing slashes).
local out = {}
for _, p in ipairs({ "images/", "images", "images/sub/", "data/", "/", "", "nope/", "/images/", "/images", "/data/", "./images/" }) do
  local l = playdate.file.listFiles(p)
  out[#out + 1] = "[" .. p .. "]\t" .. (l and table.concat(l, " | ") or "nil")
end
for _, p in ipairs({ "mod", "mod.pdz", "mod.lua", "main", "main.pdz", "images", "images/sub" }) do out[#out + 1] = "exists/isdir " .. p .. "\t" .. tostring(playdate.file.exists(p)) .. " " .. tostring(playdate.file.isdir(p)) .. " " .. tostring(playdate.file.getSize(p)) end
local fh = playdate.file.open("listf.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
