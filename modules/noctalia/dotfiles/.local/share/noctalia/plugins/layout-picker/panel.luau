local modes = {
  { id = "dwindle", title = "Dwindle", description = "Split windows into smaller tiles" },
  { id = "master-left", title = "Master left", description = "Main window left · stack right" },
  { id = "master-right", title = "Master right", description = "Main window right · stack left" },
  { id = "master-top", title = "Master top", description = "Main window above a row" },
  { id = "master-bottom", title = "Master bottom", description = "Main window below a row" },
  { id = "master-center", title = "Master centered", description = "Main window between side stacks" },
}
local opened, busy, generation = false, false, 0
local selected, active, available, message = 1, "", {}, ""
local receivedCycles, pendingCycles = 0, 0
local render, advance

local function helper()
  return noctalia.pluginDir() .. "/layouts.py"
end

local function errorMessage(result, fallback)
  local text = noctalia.string.trim(result.stderr or "")
  return text ~= "" and text or fallback
end

local function choose(index)
  local mode = modes[index]
  if not opened or busy or not mode or not available[mode.id] then return end
  selected = index
  busy, message = true, ""
  render()
  local request = generation
  local accepted = noctalia.runAsync({ "python3", helper(), "--apply", mode.id }, function(result)
    if not opened or request ~= generation then return end
    busy = false
    if result.exitCode == 0 then
      active = mode.id
      if pendingCycles > 0 then
        local steps = pendingCycles
        pendingCycles = 0
        advance(steps)
      else render() end
    else
      pendingCycles = 0
      message = errorMessage(result, "Could not change the layout.")
      render()
    end
  end)
  if not accepted then busy = false; message = "Could not start layout controls."; render() end
end

advance = function(steps)
  local enabled, position = {}, 0
  for index, mode in ipairs(modes) do
    if available[mode.id] then
      table.insert(enabled, index)
      if selected == index then position = #enabled end
    end
  end
  if #enabled == 0 then return end
  choose(enabled[((position - 1 + steps) % #enabled) + 1])
end

local function receiveCycles(count)
  if not opened or type(count) ~= "number" then return end
  local steps = math.max(0, count - receivedCycles)
  receivedCycles = count
  if busy then pendingCycles = pendingCycles + steps
  elseif steps > 0 then advance(steps) end
end

noctalia.state.watch("cycles", receiveCycles)

-- Native themed shapes form a miniature window arrangement, not just a generic icon.
local function window(number, primary)
  return ui.column({ flexGrow = 1, radius = 6, fill = primary and "primary" or "secondary/0.35",
    justify = "center", align = "center" }, {
    ui.label({ text = tostring(number), fontSize = 14,
      color = primary and "on_primary" or "on_surface" }),
  })
end

local function preview(id)
  local children, vertical = {}, false
  if id == "master-top" or id == "master-bottom" then
    vertical = true
    local stack = ui.row({ flexGrow = 1, gap = 5 }, { window(2), window(3), window(4) })
    children = id == "master-top" and { window(1, true), stack } or { stack, window(1, true) }
  elseif id == "master-center" then
    children = {
      ui.column({ flexGrow = 1, gap = 5 }, { window(2), window(4) }),
      ui.column({ flexGrow = 2, gap = 5 }, { window(1, true) }),
      ui.column({ flexGrow = 1, gap = 5 }, { window(3) }),
    }
  elseif id == "master-left" or id == "master-right" then
    local stack = ui.column({ flexGrow = 1, gap = 5 }, { window(2), window(3), window(4) })
    children = id == "master-left" and { window(1, true), stack } or { stack, window(1, true) }
  else
    children = { window(1, true), ui.column({ flexGrow = 1, gap = 5 }, {
      window(2),
      ui.row({ flexGrow = 1, gap = 5 }, { window(3), window(4) }),
    }) }
  end
  local container = vertical and ui.column or ui.row
  return container({ height = 120, padding = 7, gap = 5, radius = 12, fill = "surface/0.8" }, children)
end

local function tile(mode, index)
  local enabled = not busy and available[mode.id] == true
  return ui.column({ key = mode.id, flexGrow = 1, gap = 12, padding = 12, radius = 18,
    fill = "surface_variant/0.5", border = selected == index and "primary" or "surface/0",
    borderWidth = 2, opacity = available[mode.id] and 1 or 0.4,
    onClick = function() if enabled then choose(index) end end,
  }, {
    preview(mode.id),
    ui.row({ gap = 8, align = "center" }, {
      ui.label({ text = mode.title, fontSize = 18, fontWeight = "bold", flexGrow = 1 }),
      ui.label({ text = active == mode.id and "✓" or tostring(index), fontSize = 12, color = "primary" }),
    }),
    ui.label({ text = mode.description, fontSize = 11, color = "on_surface_variant", maxLines = 2 }),
  })
end

render = function()
  if not opened then return end
  local rows = {}
  for first = 1, #modes, 3 do
    local tiles = {}
    for index = first, math.min(first + 2, #modes) do table.insert(tiles, tile(modes[index], index)) end
    table.insert(rows, ui.row({ gap = 12, align = "stretch" }, tiles))
  end
  panel.render(ui.column({ padding = 20, gap = 16 }, {
    ui.row({ gap = 12, align = "center" }, {
      ui.glyph({ name = "layout", size = 26, color = "primary" }),
      ui.column({ gap = 3, flexGrow = 1 }, {
        ui.label({ text = "Hyprland Layouts", fontSize = 22, fontWeight = "bold" }),
        ui.label({ text = "Live tiling layout · applies to all workspaces", fontSize = 12, color = "on_surface_variant" }),
      }),
      ui.button({ glyph = "x", variant = "ghost", onClick = function() panel.close() end }),
    }),
    ui.column({ gap = 12 }, rows),
    ui.label({ text = message, color = "error", fontSize = 11, maxLines = 2, visible = message ~= "" }),
    ui.label({ text = busy and "Working…" or "Super+T / Arrows Cycle · 1–6 Choose · Enter / Esc Close",
      fontSize = 11, color = "on_surface_variant" }),
  }))
end

function onOpen()
  generation = generation + 1
  opened, busy, selected, active, available, message = true, true, 1, "", {}, ""
  receivedCycles, pendingCycles = 0, 0
  noctalia.state.set("visible", true)
  receiveCycles(noctalia.state.get("cycles"))
  render()
  local request = generation
  local accepted = noctalia.runAsync({ "python3", helper(), "--status" }, function(result)
    if not opened or request ~= generation then return end
    busy = false
    local data = noctalia.json.decode(result.stdout or "")
    if result.exitCode == 0 and type(data) == "table" and type(data.available) == "table" then
      active = data.current or ""
      for _, id in ipairs(data.available) do available[id] = true end
      for index, mode in ipairs(modes) do if mode.id == active then selected = index end end
      if pendingCycles > 0 then advance(pendingCycles); pendingCycles = 0 end
      if #data.available == 0 then message = "No supported tiling layouts are available." end
    else message = errorMessage(result, "Could not read Hyprland layouts.") end
    render()
  end)
  if not accepted then busy = false; message = "Could not read Hyprland layouts."; render() end
end

function onClose()
  opened = false
  noctalia.state.set("visible", false)
  noctalia.state.set("cycles", 0)
  receivedCycles, pendingCycles = 0, 0
  generation = generation + 1
end

function onKey(chord, pressed)
  if not pressed then return end
  if chord == "Return" then panel.close(); return end
  if busy then return end
  local digit = tonumber(chord)
  if digit then choose(digit); return end
  local step = ({ Left = -1, Right = 1, Up = -3, Down = 3 })[chord]
  if step then advance(step) end
end
