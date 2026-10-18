-- Probe: every function reachable from the playdate table (no CoreLibs), for comparing the API surface
local out = playdate.file.open("out.txt", playdate.file.kFileWrite)
local seen = {}
local names = {}
local function walk(t, path, depth)
    if seen[t] or depth > 5 then return end
    seen[t] = true
    local keys = {}
    for k, v in pairs(t) do if type(k) == "string" then keys[#keys + 1] = k end end
    table.sort(keys)
    for _, k in ipairs(keys) do
        local v = rawget(t, k)
        local p = path .. "." .. k
        if type(v) == "function" then names[#names + 1] = p
        elseif type(v) == "table" and k ~= "__index" and k ~= "_G" then walk(v, p, depth + 1) end
    end
    local mt = getmetatable(t)
    if type(mt) == "table" and not seen[mt] then walk(mt, path .. "<mt>", depth + 1) end
end
walk(playdate, "playdate", 0)
table.sort(names)
for _, n in ipairs(names) do out:write(n .. "\n") end
out:close()
function playdate.update() end
