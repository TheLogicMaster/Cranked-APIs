-- Probe: json.encode number and string formatting, encodePretty, decode types, and edge cases
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function w(label, ok, v) fh:write(label .. " " .. tostring(ok) .. " " .. tostring(v) .. "\n") fh:flush() end
local vals = { 0, 1, -1, 1.5, 0.1, 1/3, 1e20, 1e-7, 2^31, 2^53, -0.0, 100.0, 3, math.huge, -math.huge, 0/0, "a\"b\\c\n\t\1/", "\u{E9}", true, false }
for i, v in ipairs(vals) do local ok, r = pcall(json.encode, v) w("enc" .. i, ok, r) end
local ok, r = pcall(json.encode, { 1, 2, nil, 4 }) w("holes", ok, r)
ok, r = pcall(json.encode, { [1] = "a", [3] = "c" }) w("sparse", ok, r)
ok, r = pcall(json.encode, { x = { y = { z = {} } }, arr = {} }) w("nested", ok, r)
ok, r = pcall(json.encode, { [1] = 1, a = 2 }) w("mixed", ok, r)
ok, r = pcall(json.encode, { [2.5] = 1 }) w("floatkey", ok, r)
ok, r = pcall(json.encodePretty, { a = { 1, 2 }, b = "x" }) w("pretty", ok, r and r:gsub("\n", "\\n"))
local t = {} t.self = t ok, r = pcall(json.encode, t) w("cycle", ok, r)
ok, r = pcall(json.encode, function() end) w("func", ok, r and r:gsub("0x%x+", "ADDR"))
for i, s in ipairs({ "1", "1.0", "1e2", "-0", "123456789012", "0.5", "[1,2,3]", '{"a":1}', '"\\u00e9"', 'true', 'null', '[]', '{}', ' 7 ', '[1,]', '{"a":}', '01', '1.', '"x', '[1,2', 'nan' }) do
  local ok2, d = pcall(json.decode, s)
  local desc = type(d) == "table" and ("table#" .. #d) or tostring(d)
  w("dec" .. i .. " " .. s, ok2, desc .. " " .. tostring(math.type(d)))
end
fh:close()
function playdate.update() end
