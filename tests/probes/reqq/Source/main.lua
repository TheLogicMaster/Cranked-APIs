-- Probe: every key of _G and of the standard library tables
local out = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function keys(t) local k = {} for n, v in pairs(t) do k[#k + 1] = tostring(n) .. ":" .. type(v) end table.sort(k) return table.concat(k, " ") end
local g = {} for n, v in pairs(_G) do if n ~= "playdate" and n ~= "out" then g[#g + 1] = n .. ":" .. type(v) end end table.sort(g)
out:write("_G\t" .. table.concat(g, " ") .. "\n")
for _, lib in ipairs({ "string", "table", "math", "coroutine", "utf8", "debug", "os", "io", "json" }) do
  if type(_G[lib]) == "table" then out:write(lib .. "\t" .. keys(_G[lib]) .. "\n") else out:write(lib .. "\t" .. type(_G[lib]) .. "\n") end
end
out:write("kTA\t" .. type(kTextAlignment) .. "\t" .. tostring(getmetatable(_G)) .. "\t" .. tostring(rawget(_G, "kTextAlignment")) .. "\n")
out:write("version\t" .. tostring(_VERSION) .. "\n")
out:write("maxinteger\t" .. tostring(math.maxinteger) .. "\t" .. tostring(math.type(1)) .. "\t" .. tostring(1e300) .. "\t" .. tostring(2^53 + 1) .. "\t" .. tostring(1/3) .. "\n")
out:write("intdiv\t" .. tostring(7 // 2) .. "\t" .. tostring(7.0 // 2) .. "\t" .. tostring(-7 // 2) .. "\t" .. tostring(7 % -3) .. "\t" .. tostring(math.tointeger(3.0)) .. "\n")
out:write("strnum\t" .. tostring("10" + 1) .. "\t" .. tostring("0x10" + 0) .. "\t" .. tostring(10 .. "") .. "\t" .. tostring(3.0) .. "\t" .. tostring(-0.0) .. "\n")
out:write("fmt\t" .. string.format("%5.2f|%d|%x|%g|%q", 3.14159, 42, 255, 1e20, "a\nb") .. "\n")
out:close()
function playdate.update() end
