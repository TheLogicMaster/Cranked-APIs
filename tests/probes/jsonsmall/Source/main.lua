-- Probe: json.decodeFile on very short files (0 to 4 bytes, some with a UTF-8 byte order mark), by path and by an
-- open file, next to json.decode of the same text. Each line: the case, then what decodeFile (path), decodeFile
-- (open file) and decode returned.
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function show(v)
  if type(v) == "table" then
    local keys = {}
    for k, x in pairs(v) do keys[#keys + 1] = tostring(k) .. "=" .. show(x) end
    table.sort(keys)
    return "{" .. table.concat(keys, ",") .. "}"
  elseif type(v) == "string" then
    return string.format("%q", v)
  elseif math.type(v) then
    return math.type(v) .. ":" .. tostring(v)
  end
  return tostring(v)
end
local function r(ok, v, msg)
  if not ok then return "ERR " .. tostring(v) end
  return show(v) .. " / " .. show(msg)
end
local bom = "\239\187\191"
local cases = { { "lbrk", "[]" }, { "lbrace", "{}" }, { "one", "1" }, { "empty", "" }, { "space", " " },
  { "arr1", "[1]" }, { "two", "12" }, { "onesp", "1 " }, { "onenl", "1\n" }, { "nl", "\n" }, { "nl2", "\n\n" },
  { "str", '""' }, { "strx", '"x"' }, { "t", "t" }, { "tr", "tr" }, { "brk", "[" }, { "brk2", "[ " }, { "zero", "0 " },
  { "neg", "-1 " }, { "arrsp", "[ ]" }, { "objsp", "{ }" }, { "arr2", "[12]" }, { "bom", bom }, { "bomarr", bom .. "[]" },
  { "bomobj", bom .. "{}" }, { "bomone", bom .. "1" }, { "bomb1", "\239" }, { "bomb2", "\239\187" }, { "bomb2arr", "\239\187[]" },
  { "true", "true" }, { "null", "null" }, { "nullsp", "null " }, { "x", "x" }, { "nul", "\0" }, { "nularr", "[]\0" } }
for i, c in ipairs(cases) do
  local name = "f" .. i .. ".json"
  local f = playdate.file.open(name, playdate.file.kFileWrite)
  if #c[2] > 0 then f:write(c[2]) end
  f:close()
  local size = playdate.file.getSize(name)
  local a = r(pcall(json.decodeFile, name))
  local g = playdate.file.open(name, playdate.file.kFileRead)
  local b = g and r(pcall(json.decodeFile, g)) or "no file"
  if g then g:close() end
  local d = r(pcall(json.decode, c[2]))
  fh:write(c[1] .. " size=" .. tostring(size) .. "\tpath: " .. a .. "\tfile: " .. b .. "\tdecode: " .. d .. "\n")
end
-- a table saved with encodeToFile and read back
json.encodeToFile("e1.json", false, {})
fh:write("encodeToFile {} size=" .. tostring(playdate.file.getSize("e1.json")) .. "\t" .. r(pcall(json.decodeFile, "e1.json")) .. "\n")
json.encodeToFile("e2.json", true, {})
fh:write("encodeToFile pretty {} size=" .. tostring(playdate.file.getSize("e2.json")) .. "\t" .. r(pcall(json.decodeFile, "e2.json")) .. "\n")
fh:close()
if playdate.simulator then playdate.simulator.exit() end
function playdate.update() end
