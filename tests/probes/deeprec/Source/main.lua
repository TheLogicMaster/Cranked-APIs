-- Probe: deep Lua recursion that returns normally (no C calls in between)
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function r(n) if n == 0 then return 0 end return 1 + r(n - 1) end
for _, n in ipairs({1000, 10000, 50000, 100000}) do
  local t0 = playdate.getCurrentTimeMilliseconds()
  local ok, v = pcall(r, n)
  fh:write(n .. " " .. tostring(ok) .. " " .. tostring(v) .. " " .. (playdate.getCurrentTimeMilliseconds() - t0) .. "ms mem " .. math.floor(collectgarbage("count")) .. "\n") fh:flush()
end
fh:close()
function playdate.update() end
