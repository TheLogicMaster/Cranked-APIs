-- Constants probe: every numeric or string field named k* under playdate, plus kTextAlignment.
function runCases5(write)
    local seen = {}
    local function walk(t, path, depth)
        if depth > 4 or seen[t] then return end
        seen[t] = true
        local keys = {}
        for k in pairs(t) do if type(k) == "string" then keys[#keys + 1] = k end end
        table.sort(keys)
        for _, k in ipairs(keys) do
            local ok, val = pcall(function() return t[k] end)
            if ok then
                local vt = type(val)
                if (vt == "number" or vt == "string") and k:match("^k") then
                    write("const " .. path .. "." .. k .. "\t" .. tostring(val) .. (math.type(val) and (" " .. math.type(val)) or ""))
                elseif vt == "table" and not k:match("^__") then
                    walk(val, path .. "." .. k, depth + 1)
                end
            end
        end
    end
    walk(playdate, "playdate", 0)
    if kTextAlignment then walk(kTextAlignment, "kTextAlignment", 1); for k, val in pairs(kTextAlignment) do write("const kTextAlignment." .. k .. "\t" .. tostring(val)) end end
end
