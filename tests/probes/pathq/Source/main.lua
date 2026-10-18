-- Probe: pathfinder graphs; paths with and without heuristics, adjacent-goal searches, weights, ids
local pf = playdate.pathfinder
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function ids(path) if not path then return "nil" end local t = {} for i, n in ipairs(path) do t[#t + 1] = tostring(n.id) .. "@" .. tostring(n.x) .. "," .. tostring(n.y) end return table.concat(t, " ") end
local seed = 9
local function rnd(n) seed = (seed * 16807) % 2147483647 return seed % n end
-- a grid with holes
local w, h = 12, 9
local map = {}
for i = 1, w * h do map[i] = (rnd(5) == 0) and 0 or 1 end
map[1] = 1 map[w * h] = 1
local g = pf.graph.new2DGrid(w, h, false, map)
local g8 = pf.graph.new2DGrid(w, h, true, map)
local function try(label, f) local ok, r = pcall(f) fh:write(label .. " " .. (ok and ids(r) or ("ERR " .. tostring(r))) .. "\n") end
for k = 1, 12 do
  local a, b = 1 + rnd(w * h), 1 + rnd(w * h)
  local na, nb = g:nodeWithID(a), g:nodeWithID(b)
  if na and nb then
    try("p4 " .. a .. "->" .. b, function() return g:findPath(na, nb) end)
    try("p4adj " .. a .. "->" .. b, function() return g:findPath(na, nb, nil, true) end)
    try("p8 " .. a .. "->" .. b, function() return g8:findPath(g8:nodeWithID(a), g8:nodeWithID(b)) end)
    try("p8h0 " .. a .. "->" .. b, function() return g8:findPath(g8:nodeWithID(a), g8:nodeWithID(b), function(n1, n2) return 0 end) end)
    try("p8hm " .. a .. "->" .. b, function() return g8:findPath(g8:nodeWithID(a), g8:nodeWithID(b), function(n1, n2) return math.abs(n1.x - n2.x) * 10 + math.abs(n1.y - n2.y) * 10 end) end)
    try("p8adj " .. a .. "->" .. b, function() return g8:findPath(g8:nodeWithID(a), g8:nodeWithID(b), nil, true) end)
    local okI, r = pcall(function() return g:findPathWithIDs(a, b) end)
    local t = {} if okI and r then for i, v in ipairs(r) do t[#t + 1] = tostring(v) end end
    fh:write("ids " .. a .. "->" .. b .. " " .. (okI and (r and table.concat(t, ",") or "nil") or ("ERR " .. tostring(r))) .. "\n")
  end
end
-- a hand-built graph with weights
local gg = pf.graph.new()
local nodes = {}
for i = 1, 8 do nodes[i] = gg:addNewNode(i, i * 10, (i % 3) * 7) end
local function link(a, b, wgt) nodes[a]:addConnection(nodes[b], wgt, true) end
link(1, 2, 5) link(2, 3, 5) link(1, 4, 2) link(4, 3, 9) link(3, 5, 1) link(4, 6, 3) link(6, 5, 3) link(5, 7, 4) link(6, 8, 10) link(7, 8, 1)
try("w 1->8", function() return gg:findPath(nodes[1], nodes[8]) end)
try("w 1->8 h", function() return gg:findPath(nodes[1], nodes[8], function(a, b) return math.abs(a.x - b.x) end) end)
try("w 1->8 adj", function() return gg:findPath(nodes[1], nodes[8], nil, true) end)
try("w 1->5 adj", function() return gg:findPath(nodes[1], nodes[5], nil, true) end)
try("w 8->1", function() return gg:findPath(nodes[8], nodes[1]) end)
local cons = {} for _, c in ipairs(nodes[4]:connectedNodes()) do cons[#cons + 1] = tostring(c.id) end fh:write("cons4 " .. table.concat(cons, ",") .. "\n")
fh:close()
function playdate.update() end
