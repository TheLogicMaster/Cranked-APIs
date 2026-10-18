-- Probe: exact bits of Lua math results (sin, cos, tan, asin, acos, atan, atan2, sqrt, exp, log, log with base,
-- pow, fmod, floor division and float arithmetic) over fixed inputs, to see which libm the runtime uses
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function b(v) if math.type(v) == "integer" then return "i" .. v end return string.format("%08x", string.unpack("<I4", string.pack("<f", v))) end
local inputs = {}
local s = 1
for i = 1, 60 do s = (s * 1103515245 + 12345) % 2147483648 inputs[#inputs + 1] = (s / 2147483648 - 0.5) * 20 end
for _, v in ipairs({ 0.5, 1.0, 1e-3, 3.14159265, 1.5707963, 100.25, 12345.678, 1e-30, 7.7e5 }) do inputs[#inputs + 1] = v end
local fns = {
  { "sin", math.sin }, { "cos", math.cos }, { "tan", math.tan }, { "exp", math.exp },
  { "asin", function(x) return math.asin(x / 21) end }, { "acos", function(x) return math.acos(x / 21) end },
  { "atan", math.atan }, { "atan2", function(x) return math.atan(x, 3.3) end },
  { "sqrt", function(x) return math.sqrt(math.abs(x)) end }, { "log", function(x) return math.log(math.abs(x) + 0.001) end },
  { "log2", function(x) return math.log(math.abs(x) + 0.001, 2) end }, { "log10", function(x) return math.log(math.abs(x) + 0.001, 10) end },
  { "pow", function(x) return (math.abs(x) + 0.5) ^ 1.37 end }, { "fmod", function(x) return math.fmod(x, 1.7) end },
  { "idiv", function(x) return x // 0.37 end }, { "mod", function(x) return x % 0.37 end },
  { "muladd", function(x) return x * 1.1 + 0.3 end }, { "rad", math.rad }, { "deg", math.deg },
}
for _, f in ipairs(fns) do
  local parts = {}
  for _, x in ipairs(inputs) do local ok, r = pcall(f[2], x) parts[#parts + 1] = ok and b(r) or "err" end
  fh:write(f[1] .. " " .. table.concat(parts, " ") .. "\n")
end
fh:write("tostring " .. tostring(0.1) .. " " .. tostring(1/3) .. " " .. tostring(2^24 + 1) .. " " .. tostring(math.pi) .. " " .. string.format("%.10f", 0.1) .. "\n")
fh:close()
function playdate.update() end
