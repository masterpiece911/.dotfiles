"""Exercise the Lua-compatible panel/event logic with mocked Noctalia APIs."""
import ctypes
import ctypes.util
import json
from pathlib import Path
import unittest


class PanelTests(unittest.TestCase):
    def test_open_live_cycle_queue_wrap_errors_and_close(self):
        library = ctypes.util.find_library('lua5.4')
        if not library:
            self.skipTest('liblua5.4 is not available for the panel mock')
        lua = ctypes.CDLL(library)
        lua.luaL_newstate.restype = ctypes.c_void_p
        lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
        lua.luaL_loadstring.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
        lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int,
                                 ctypes.c_ssize_t, ctypes.c_void_p]
        lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
        lua.lua_tolstring.restype = ctypes.c_char_p
        lua.lua_close.argtypes = [ctypes.c_void_p]
        root = Path(__file__).resolve().parent
        script = r'''
local state, watchers, requests = {}, {}, {}
local tree, closes = nil, 0
ui = setmetatable({}, { __index = function(_, kind)
  return function(props, children) return { kind = kind, props = props, children = children or {} } end
end })
panel = {
  render = function(value) tree = value end,
  close = function() closes = closes + 1; onClose() end,
}
noctalia = {
  pluginDir = function() return "/mock" end,
  string = { trim = function(text) return text:match("^%s*(.-)%s*$") end },
  json = { decode = function(value) return value end },
  runAsync = function(args, callback)
    table.insert(requests, { args = args, callback = callback }); return true
  end,
  togglePanel = function() onOpen() end,
  state = {
    get = function(key) return state[key] end,
    set = function(key, value)
      state[key] = value
      if watchers[key] then watchers[key](value) end
    end,
    watch = function(key, callback) watchers[key] = callback end,
  },
}
local all = { "dwindle", "master-left", "master-right", "master-top", "master-bottom", "master-center" }
local function complete(code, data, error)
  local request = table.remove(requests, 1)
  assert(request, "Expected an async request")
  request.callback({ exitCode = code or 0, stdout = data, stderr = error or "" })
end
local function applying(name)
  assert(#requests == 1 and requests[1].args[3] == "--apply" and requests[1].args[4] == name,
    "Expected live application of " .. name)
end
local function hasText(node, text)
  if node.props.text and node.props.text:find(text, 1, true) then return true end
  for _, child in ipairs(node.children) do if hasText(child, text) then return true end end
  return false
end
'''
        script += f'\ndofile({json.dumps(str(root / "panel.luau"))})\n'
        script += f'dofile({json.dumps(str(root / "events.luau"))})\n'
        script += r'''
onIpc("ignored", "")
assert(#requests == 0)
onIpc("advance", "")
assert(state.visible and #requests == 1 and requests[1].args[3] == "--status")
-- Fast presses during discovery must not be lost or apply the initial layout.
onIpc("advance", "")
onIpc("advance", "")
complete(0, { current = "dwindle", available = all })
applying("master-right")
-- More presses during an application queue behind it, keeping the panel open.
onIpc("advance", "")
onIpc("advance", "")
complete()
applying("master-bottom")
complete()
assert(closes == 0 and #requests == 0)
onIpc("advance", "")
applying("master-center"); complete()
onIpc("advance", "")
applying("dwindle"); complete()
onKey("Right", true)
applying("master-left"); complete()
onKey("6", true)
applying("master-center"); complete()
-- The informational last line and the old Apply instructions are gone.
assert(not hasText(tree, "Runtime only") and not hasText(tree, "Enter Apply"))
-- Failed live switches keep the panel usable and show the error.
onIpc("advance", "")
applying("dwindle"); complete(1, "", "test failure")
assert(hasText(tree, "test failure") and closes == 0)
onKey("Return", true)
assert(closes == 1 and not state.visible and state.cycles == 0 and #requests == 0)
-- Reopening highlights current state; unavailable layouts are skipped.
onIpc("advance", "")
complete(0, { current = "dwindle", available = { "dwindle" } })
assert(#requests == 0)
onIpc("advance", "")
applying("dwindle"); complete()
panel.close()
assert(not state.visible and state.cycles == 0)
'''
        vm = lua.luaL_newstate()
        self.assertTrue(vm)
        try:
            lua.luaL_openlibs(vm)
            result = lua.luaL_loadstring(vm, script.encode())
            if result == 0:
                result = lua.lua_pcallk(vm, 0, 0, 0, 0, None)
            if result:
                self.fail(lua.lua_tolstring(vm, -1, None).decode())
        finally:
            lua.lua_close(vm)


if __name__ == '__main__':
    unittest.main()
