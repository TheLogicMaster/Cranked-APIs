-- Probe: json.decode edge cases
local f = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function show(v, depth)
    depth = depth or 0
    local t = type(v)
    if t == "table" then
        if depth > 4 then return "{...}" end
        local keys = {}
        for k in pairs(v) do keys[#keys + 1] = k end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        local parts = {}
        for _, k in ipairs(keys) do parts[#parts + 1] = (type(k) == "number" and "#" or "") .. tostring(k) .. "=" .. show(v[k], depth + 1) end
        return "{" .. table.concat(parts, ",") .. "}"
    elseif t == "number" then
        return (math.type(v) == "integer" and "i" or "f") .. string.format(math.type(v) == "integer" and "%d" or "%.9g", v)
    elseif t == "string" then
        return "s" .. string.format("%q", v):gsub("\n", "n")
    end
    return tostring(v)
end
local function c(src)
    f:write("START\t" .. src .. "\n"); f:flush()
    local ok, a, b = pcall(json.decode, src)
    local r
    if not ok then r = "ERR " .. tostring(a) else r = show(a) .. " | " .. show(b) end
    f:write(src .. "\t" .. r .. "\n"); f:flush()
end
local inputs = {
    '[1,2,3]', '{"a":1}', '[]', '{}', '  [ 1 , 2 ]  ', '[\t1,\r\n2]', '12', '12 ', '1.5', '1.5 ', '"str"', '"str" ', 'true', 'true ', 'null', 'null ',
    '[0]', '[-0]', '[-7]', '[0.1]', '[3.14159]', '[1e3]', '[1E-2]', '[2.5e+3]', '[01]', '[1.]', '[.5]', '[-.5]', '[-]',
    '[9999999999]', '[-2147483649]', '[21e8]', '[3e9]', '[1e400]', '[5e-1]', '[1e0]', '[0.123456789123]', '[123456.789]', '[1e5]', '1e5',
    '["\\b\\f\\n\\r\\t\\/\\\\\\""]', '["\\u0041"]', '["\\u00e9"]', '["\\u20ac"]', '["\\ud83d\\ude00"]', '["\\q"]', '["\\uZZ41"]', '["abc', '["a\\u0000b"]',
    '[1,]', '{"a":1,}', '{"a" 1}', '{a:1}', "['x']", '[True]', '[nul]', '[1] 2', '', '   ', '{"a":1', '[1,null,3]', '{"a":null,"b":2}', '{"a":1,"a":2}',
    '{"_array":[1,2],"x":4}', '{"_array":{"k":1}}', '[[1,[2,[3]]],{"x":{"y":[]}}]', '{"":1}', '{"1":"one","2":"two"}', '[1, "two", true, false, null]',
    '{"a":[1,2],"b":{"c":"d"}}', '[1 2]', '{"a":1 "b":2}', '[-1.5e2]', '[1e]', '[1e-]', '[\n\n1,\nx]', '{\n"a":\n\n!}', '[1.234567891234]', '[100000000000000000000.0]',
}
for _, s in ipairs(inputs) do c(s) end
f:close()
playdate.stop()
function playdate.update() end
