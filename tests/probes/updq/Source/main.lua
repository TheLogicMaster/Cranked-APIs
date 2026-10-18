-- Probe (with src/main.c): a Lua update and a C update callback set in kEventInitLua
local log = {}
local luaCalls, cCalls = 0, 0
local written = false
local function maybeWrite()
  if written or luaCalls + cCalls < 30 then return end
  written = true
  local f = playdate.file.open("updq.txt", playdate.file.kFileWrite)
  f:write("lua calls " .. luaCalls .. " C calls " .. cCalls .. "\n")
  f:write(table.concat(log, " ", 1, math.min(#log, 12)) .. "\n")
  f:close()
end
function noteC(n) cCalls = n; log[#log + 1] = "C" .. n; maybeWrite() end
function playdate.update()
  luaCalls += 1
  log[#log + 1] = "L" .. luaCalls
  maybeWrite()
end
