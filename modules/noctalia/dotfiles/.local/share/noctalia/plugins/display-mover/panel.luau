-- Native palette roles stay bound to Noctalia's live theme.
local outputs, workspace = {}, {}
local selected, busy, message, opened, generation = 1, false, "", false, 0
local accents = { "primary", "secondary", "tertiary" }
local render

local function usableWorkspace()
  return type(workspace.id) == "number" and workspace.id ~= 0 and workspace.id ~= -1
    and not string.match(workspace.name or "", "^special:")
end

local function helper()
  return noctalia.pluginDir() .. "/mover.py"
end

local function choose(index)
  if busy or not opened or not outputs[index] or not usableWorkspace() then return end
  busy = true
  message = "Moving workspace…"
  render()
  local request = generation
  local accepted = noctalia.runAsync({ "python3", helper(), "--move", tostring(workspace.id), outputs[index].name }, function(result)
    if request ~= generation or not opened then return end
    busy = false
    if result.exitCode == 0 then
      panel.close()
    else
      message = noctalia.string.trim(result.stderr or "")
      if message == "" then message = "Could not move this workspace. Reopen the picker and try again." end
      render()
    end
  end)
  if not accepted then
    busy = false
    message = "Could not start the display mover."
    render()
  end
end

local function tile(output, index)
  local accent = accents[(index - 1) % #accents + 1]
  local current = output.name == workspace.monitor
  local active = index == selected
  return ui.column({ key = output.name, width = 196, gap = 9, padding = 5, radius = 18,
    fill = active and "surface_variant/0.55" or "surface/0",
    border = active and "primary" or "surface/0", borderWidth = 2,
    onClick = function() choose(index) end,
    onHover = function(state)
      if state == "true" and not busy and selected ~= index then selected = index; render() end
    end,
  }, {
    ui.column({ height = 104, fill = accent, radius = 12, padding = 12, justify = "space_between" }, {
      ui.row({ justify = "space_between", align = "center" }, {
        ui.glyph({ name = "device-desktop", size = 18, color = "on_" .. accent }),
        ui.label({ text = tostring(index), fontSize = 12, color = "on_" .. accent }),
      }),
      ui.row({ justify = "center", align = "center", flexGrow = 1 }, {
        ui.glyph({ name = current and "check" or "arrow-up-right", size = 28, color = "on_" .. accent }),
      }),
      ui.box({ height = 12, fill = "surface/0" }),
    }),
    ui.column({ gap = 5, paddingH = 12, paddingV = 10 }, {
      ui.label({ text = output.name, fontSize = 14, fontWeight = "bold" }),
      ui.label({ text = string.format("%d×%d · Workspace %s", output.width, output.height,
        tostring((output.activeWorkspace or {}).name or "—")), fontSize = 11, color = "on_surface_variant" }),
    }),
  })
end

render = function()
  if not opened then return end
  local rows = {}
  for first = 1, #outputs, 3 do
    local cells = {}
    for i = first, math.min(first + 2, #outputs) do table.insert(cells, tile(outputs[i], i)) end
    table.insert(rows, ui.row({ gap = 12, align = "start" }, cells))
  end
  if #outputs == 0 then
    table.insert(rows, ui.label({ text = busy and "Reading displays…" or "No active displays", color = "on_surface_variant" }))
  end
  panel.render(ui.column({ padding = 20, gap = 14, flexGrow = 1 }, {
    ui.row({ gap = 12, align = "center" }, {
      ui.glyph({ name = "device-desktop", size = 24, color = "primary" }),
      ui.column({ gap = 3, flexGrow = 1 }, {
        ui.label({ text = "Display Mover", fontSize = 21, fontWeight = "bold" }),
        ui.label({ text = "Choose a display for this workspace", fontSize = 12, color = "on_surface_variant" }),
      }),
      ui.button({ glyph = "x", variant = "ghost", width = 34, onClick = function() panel.close() end }),
    }),
    ui.scroll({ flexGrow = 1, gap = 12 }, rows),
    ui.label({ text = message, fontSize = 11, color = "error", visible = message ~= "" }),
    ui.row({ justify = "space_between", align = "center" }, {
      ui.label({ text = "← →  Select     ↵  Move     1–9  Quick move", fontSize = 11, color = "on_surface_variant" }),
      ui.label({ text = "Esc  Close", fontSize = 11, color = "on_surface_variant" }),
    }),
  }))
end

local function apply(data)
  workspace = data.workspace or {}
  outputs = data.outputs or {}
  selected = 1
  for i, output in ipairs(outputs) do if output.name == workspace.monitor then selected = i end end
  if not usableWorkspace() then message = "No active workspace. Select a workspace, then press Super+Shift+F3." end
  render()
end

function onOpen(context)
  generation = generation + 1
  opened, busy, message = true, false, ""
  outputs, workspace, selected = {}, {}, 1
  local data = context and noctalia.json.decode(context)
  if type(data) == "table" and type(data.outputs) == "table" then
    apply(data)
  else
    busy = true
    render()
    local request = generation
    local accepted = noctalia.runAsync({ "python3", helper(), "--snapshot" }, function(result)
      if request ~= generation or not opened then return end
      busy = false
      local parsed = noctalia.json.decode(result.stdout or "")
      if result.exitCode == 0 and type(parsed) == "table" then apply(parsed)
      else message = "Could not read Hyprland displays."; render() end
    end)
    if not accepted then busy = false; message = "Could not read Hyprland displays."; render() end
  end
end

function onClose()
  opened = false
  generation = generation + 1
end

function onKey(chord, pressed)
  if not pressed or busy or #outputs == 0 then return end
  local digit = tonumber(chord)
  if digit then choose(digit); return end
  if chord == "Return" then choose(selected); return end
  local step = ({ Left = -1, Right = 1, Up = -3, Down = 3 })[chord]
  if step then selected = ((selected - 1 + step) % #outputs) + 1; render() end
end
