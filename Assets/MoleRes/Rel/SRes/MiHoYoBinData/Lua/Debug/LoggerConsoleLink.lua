local _orig = debug.traceback
local _base = "Assets/MoleRes/Rel/SRes/Lua/"

function debug.traceback(msg_or_thread, ...)
  if type(msg_or_thread) == "thread" then
    return _orig(msg_or_thread, ...)
  end
  local msg, level = msg_or_thread, (...)
  if msg ~= nil then
    msg = tostring(msg)
  end
  local raw = _orig(msg, (level or 1) + 1)
  return (raw:gsub([[
	([^%[%]
]-):(%d+): in ([^
]*)]], function(src, ln, rest)
    local full = _base .. src .. ".lua"
    local short = src .. ".lua"
    return "\t" .. rest .. " (at <a href=\"" .. full .. "\" line=\"" .. ln .. "\">" .. short .. ":" .. ln .. "</a>)"
  end))
end
