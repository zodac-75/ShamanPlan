-- Loads a Questie DB string "X = [[return {...}]]" from a file.
function QLoad(path, var)
  local f = assert(io.open(path)); local s = f:read("a"); f:close()
  local i = s:find(var .. " = %[%[return", 1) or s:find(var .. "%s*=%s*%[=*%[return")
  assert(i, "no " .. var .. " in " .. path)
  local open = s:match("%[(=*)%[return", i)
  local a = s:find("[" .. open .. "[return", i, true) + #open + 2
  local b = s:find("]" .. open .. "]", a, true)
  return assert(load(s:sub(a, b - 1)))()
end
