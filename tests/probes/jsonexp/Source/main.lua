-- Probe: how json.decode rounds numbers with fractions and exponents (positive and negative, subnormals,
-- 32-bit limits). Each line: the JSON number, a tab, then "i<integer>", "f<float bits as hex>" or "nil <message>".
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function res(v, msg)
  if v == nil then return "nil " .. tostring(msg) end
  local x = v[1]
  if math.type(x) == "integer" then return "i" .. x end
  if math.type(x) == "float" then
    local s = string.pack("<f", x)
    local b1, b2, b3, b4 = string.byte(s, 1, 4)
    return string.format("f%02x%02x%02x%02x", b4, b3, b2, b1)
  end
  return "?" .. type(x)
end
local n = 0
local function case(s)
  local v, msg = json.decode("[" .. s .. "]")
  fh:write(s .. "\t" .. res(v, msg) .. "\n")
  n = n + 1
end
-- Wichmann-Hill generator (small products, same on every Lua number model)
local s1, s2, s3 = 171, 172, 170
local function rnd(k) -- 0..k-1
  s1 = (171 * s1) % 30269 s2 = (172 * s2) % 30307 s3 = (170 * s3) % 30323
  local u = s1 / 30269 + s2 / 30307 + s3 / 30323
  u = u - math.floor(u)
  local r = math.floor(u * k)
  if r >= k then r = k - 1 end
  return r
end
local function digits(k)
  local t = {}
  for i = 1, k do t[i] = tostring(rnd(10)) end
  return table.concat(t)
end

-- fixed cases
local fixed = { "1.2345e-7", "5.543E-8", "1e-1", "1e-2", "1e-7", "1e-10", "1e-38", "1e-39", "1e-44", "1e-45", "1e-46",
  "1.4e-45", "1.401298464e-45", "2.8e-45", "7e-46", "1.17549435e-38", "1.1754942e-38", "3e-39", "5.877e-39",
  "9.99e-41", "1e-50", "1e-100", "1e-99999", "0.1e-0", "1e0", "1e-0", "5e0", "-5e0", "1.5e0", "0e5", "-0e5", "0e-5",
  "-0.0e-3", "1e1", "1e3", "-1e3", "1e9", "2e9", "-2e9", "2.1e9", "21e8", "2147483647e0", "2147483647e1",
  "214748364e1", "214748365e1", "-214748364e1", "-214748365e1", "4294967295e0", "4294967296e1", "9999999999e1",
  "1e10", "-1e10", "1e38", "3.4e38", "3.4028235e38", "3.5e38", "1e39", "-1e39", "1e45", "1e100", "1e99999",
  "1.5e3", "1.5e1", "12.5e1", "0.5e1", "1.25e2", "-1.5e3", "1E3", "1E-3", "0.001", "1e-4", "1.0e-4", "9.99e-5",
  "123456789e-9", "123456789.123456789e-3", "0.000123456789", "1.23456789e-4", "3.14159265358979e-2",
  "6.02214076e23", "1.602176634e-19", "6.62607015e-34", "1e", "1e-", "1E", "-1e-", "1.5e", "1e-3x",
  "0.0e39", "0.0e50", "-0.0e45", "0.0e38", "0.0e-50", "1.0e39", "1.5e-50", "0e39", "0e50", "-0e-50", "0.5e39", "9.9e38",
  "1e00003", "1e-00003", "3e2147483648", "1e-2147483649", "1.5e99999999", "123.456e5", "123.456e-5",
  "0e308", "0e309", "0e400", "-0e400", "5e-400", "5e-324", "1e308", "1e309", "-1e309", "0.0e-2147483648", "1e4294967297", "1e-4294967297" }
for _, s in ipairs(fixed) do case(s) end
-- every mantissa from a small set with every exponent
local mants = { "1", "2", "3", "7", "9", "1.1", "1.5", "2.5", "3.3", "4.7", "9.9", "1.2345", "5.543", "1.23456789",
  "8.765432109", "123", "12345", "1234567", "0.1", "0.5", "0.123", "-1", "-3.3", "-8.765432109" }
for _, m in ipairs(mants) do
  for e = -47, 40 do case(m .. "e" .. e) end
end
-- random numbers
for i = 1, 2500 do
  local t = {}
  if rnd(4) == 0 then t[#t + 1] = "-" end
  local id = 1 + rnd(10)
  if rnd(6) == 0 then id = 1 end
  t[#t + 1] = digits(id)
  if rnd(5) < 3 then t[#t + 1] = "." .. digits(1 + rnd(12)) end
  if rnd(20) < 17 then
    t[#t + 1] = (rnd(2) == 0) and "e" or "E"
    local ex = rnd(84) - 45
    if ex < 0 then t[#t + 1] = "-" end
    if rnd(10) == 0 then t[#t + 1] = "0" end
    t[#t + 1] = tostring(math.abs(ex))
  end
  case(table.concat(t))
end
fh:write("count " .. n .. "\n")
fh:close()
if playdate.simulator then playdate.simulator.exit() end
function playdate.update() end
