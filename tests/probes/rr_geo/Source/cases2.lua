local cases2 = {}
local function c(name, f) cases2[#cases2 + 1] = { name, f } end
local function s(v)
    if type(v) ~= "table" then return tostring(v) end
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local parts = {}
    for _, k in ipairs(keys) do parts[#parts + 1] = tostring(k) .. "=" .. s(v[k]) end
    return "{" .. table.concat(parts, ",") .. "}"
end
c("indexOfElement found", function() return table.indexOfElement({ "a", "b", "c" }, "b") end)
c("indexOfElement missing", function() return tostring(table.indexOfElement({ "a", "b" }, "z")) end)
c("indexOfElement number", function() return table.indexOfElement({ 5, 6, 7 }, 7) end)
c("getsize", function() local a, h = table.getsize({ 1, 2, 3, x = 1, y = 2 }); return tostring(a) .. "," .. tostring(h) end)
c("getsize empty", function() local a, h = table.getsize({}); return tostring(a) .. "," .. tostring(h) end)
c("shallowcopy", function() local src = { 1, { 2 }, k = "v" }; local d = table.shallowcopy(src); return s(d) .. " sameInner=" .. tostring(d[2] == src[2]) end)
c("shallowcopy into dest", function() local d = { z = 9 }; local r = table.shallowcopy({ a = 1 }, d); return s(d) .. " returnsDest=" .. tostring(r == d) end)
c("deepcopy", function() local src = { 1, { 2, { 3 } }, k = "v" }; local d = table.deepcopy(src); return s(d) .. " sameInner=" .. tostring(d[2] == src[2]) end)
c("deepcopy keeps metatable", function() local mt = {}; local d = table.deepcopy(setmetatable({ 1 }, mt)); return tostring(getmetatable(d) == mt) end)
c("deepcopy non-table", function() return tostring(table.deepcopy(5)) end)
c("table.create", function() local t = table.create(4, 2); return type(t) .. " " .. tostring(#t) end)
c("accelerometerIsRunning initial", function() return tostring(playdate.accelerometerIsRunning()) end)
c("accelerometerIsRunning after start", function() playdate.startAccelerometer(); return tostring(playdate.accelerometerIsRunning()) end)
c("accelerometerIsRunning after stop", function() playdate.stopAccelerometer(); return tostring(playdate.accelerometerIsRunning()) end)
c("inputHandlers push pop", function()
    local h = {}; playdate.inputHandlers.push(h); playdate.inputHandlers.pop(); return "ok" end)
c("inputHandlers pop empty", function() playdate.inputHandlers.pop(); playdate.inputHandlers.pop(); return "ok" end)
function runCases2(write)
    for _, case in ipairs(cases2) do
        local ok, r = pcall(case[2])
        write(case[1] .. "\t" .. (ok and tostring(r) or "ERR"))
    end
end

function runAll12(write, skip)
    skip = skip or {}
    runCases(function(s) local k = s:match("^([^\t]+)"); if not skip[k] then write(s) end end)
    runCases2(function(s) local k = s:match("^([^\t]+)"); if not skip[k] then write(s) end end)
end
