-- Services receive IPC even before a panel VM has been opened.
function onIpc(event, _payload)
  if event ~= "advance" then return end
  if noctalia.state.get("visible") == true then
    noctalia.state.set("cycles", (noctalia.state.get("cycles") or 0) + 1)
  else
    noctalia.state.set("cycles", 0)
    noctalia.state.set("visible", true)
    noctalia.togglePanel("noyan/layout-picker:chooser")
  end
end
