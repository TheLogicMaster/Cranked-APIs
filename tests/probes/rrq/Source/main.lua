-- Probe: display refresh rate values read back after setRefreshRate
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function log(s) fh:write(s .. "\n") end
log("default " .. tostring(playdate.display.getRefreshRate()))
for _, r in ipairs({0, 1, 20, 30, 40, 49.5, 50, 51, 60, 100, -5, 7.5, 20, -0.5, 20, -100, 20, 50.25, 1e9, 0.25, 0, 0/0}) do
  local ok, e = pcall(playdate.display.setRefreshRate, r)
  log(tostring(r) .. " " .. tostring(ok) .. " " .. tostring(e) .. " -> " .. tostring(playdate.display.getRefreshRate()))
end
fh:close()
function playdate.update() end
