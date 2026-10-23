local modes = {
  { id = "laptop", glyph = "device-laptop", title = "Laptop only", description = "Use the built-in screen" },
  { id = "duplicate", glyph = "copy", title = "Duplicate", description = "Show the same desktop on every screen" },
  { id = "extend", glyph = "devices", title = "Extend", description = "Use external displays as more desktop space" },
  { id = "external", glyph = "device-desktop", title = "External only", description = "Turn off the laptop screen" },
}
local opened, busy, refreshing = false, false, false
local outputs, pending, message = {}, nil, ""
local render, refresh
panel.setWantsSecondTicks(true)

local function helper()
  return noctalia.pluginDir() .. "/projector.py"
end

local function hasExternal()
  for _, output in ipairs(outputs) do
    if not string.match(output.name, "^eDP%-") and not string.match(output.name, "^LVDS%-")
      and not string.match(output.name, "^DSI%-") then return true end
  end
  return false
end

local function execute(option, argument)
  if busy then return end
  busy = true
  message = ""
  render()
  local accepted = noctalia.runAsync({ "python3", helper(), option, argument }, function(result)
    busy = false
    if result.exitCode ~= 0 then message = noctalia.string.trim(result.stderr or "Display change failed.") end
    if opened then refresh() end
  end)
  if not accepted then busy = false; message = "Could not start display controls."; render() end
end

local function choose(index)
  if not opened or busy or pending or not modes[index] then return end
  if index ~= 1 and not hasExternal() then return end
  execute("--apply", modes[index].id)
end

render = function()
  if not opened then return end
  local content = {
    ui.row({ gap = 12, align = "center" }, {
      ui.glyph({ name = "presentation", size = 28, color = "primary" }),
      ui.label({ text = "Project", fontSize = 24, fontWeight = "bold", flexGrow = 1 }),
      ui.button({ glyph = "x", variant = "ghost", onClick = function() panel.close() end }),
    }),
  }
  if pending then
    local title = pending.mode
    for _, mode in ipairs(modes) do if mode.id == pending.mode then title = mode.title end end
    table.insert(content, ui.column({ gap = 16, padding = 16, radius = 20, fill = "surface_variant/0.5" }, {
      ui.glyph({ name = "device-desktop-check", size = 44, color = "primary" }),
      ui.label({ text = "Keep this display setup?", fontSize = 20, fontWeight = "bold" }),
      ui.label({ text = title, fontSize = 16 }),
      ui.label({ text = "Reverting automatically in " .. pending.remaining .. " seconds", fontSize = 12, color = "on_surface_variant" }),
      ui.button({ text = "Keep changes", variant = "primary", enabled = not busy,
        onClick = function() execute("--keep", pending.token) end }),
      ui.button({ text = "Revert", enabled = not busy,
        onClick = function() execute("--revert", pending.token) end }),
    }))
  else
    for index, mode in ipairs(modes) do
      local enabled = not busy and (index == 1 or hasExternal())
      table.insert(content, ui.row({ key = mode.id, padding = 12, gap = 16, radius = 20,
        fill = "surface_variant/0.5", opacity = enabled and 1 or 0.4, align = "center",
        onClick = function() if enabled then choose(index) end end,
      }, {
        ui.glyph({ name = mode.glyph, size = 28, color = "primary" }),
        ui.column({ gap = 4, flexGrow = 1 }, {
          ui.label({ text = mode.title, fontSize = 16, fontWeight = "bold" }),
          ui.label({ text = mode.description, fontSize = 11, color = "on_surface_variant" }),
        }),
        ui.label({ text = tostring(index), fontSize = 12, color = "on_surface_variant" }),
      }))
    end
    table.insert(content, ui.label({ text = hasExternal() and "Choose a mode · 1–4 quick select · Esc close"
      or "Connect an external display for more options", fontSize = 11, color = "on_surface_variant" }))
  end
  if message ~= "" then table.insert(content, ui.label({ text = message, fontSize = 11, color = "error", maxLines = 2 })) end
  panel.render(ui.column({ padding = 12, gap = 12 }, content))
end

refresh = function()
  if not opened or refreshing or busy then return end
  refreshing = true
  local accepted = noctalia.runAsync({ "python3", helper(), "--status" }, function(result)
    refreshing = false
    if not opened then return end
    local data = noctalia.json.decode(result.stdout or "")
    if result.exitCode == 0 and type(data) == "table" then
      outputs, pending = data.outputs or {}, data.pending
    else
      message = noctalia.string.trim(result.stderr or "Could not read displays.")
    end
    render()
  end)
  if not accepted then refreshing = false; message = "Could not read displays."; render() end
end

function onOpen()
  opened = true
  refresh()
  render()
end

function onClose()
  opened = false
end

function update()
  refresh()
end

function onKey(chord, pressed)
  if pressed then choose(tonumber(chord)) end
end
