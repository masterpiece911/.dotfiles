-- Panel VMs are lazy-loaded, so a service accepts IPC even before the first open.
function onIpc(event, payload)
  if event ~= "show" then return end
  local index = tonumber(payload)
  if not index or index % 1 ~= 0 or index < 1 or index > 12 then return end
  noctalia.state.set("press", { index = index, at = noctalia.nowMs() })
  if noctalia.state.get("visible") ~= true then
    noctalia.state.set("visible", true)
    noctalia.togglePanel("noyan/media-key-guide:guide")
  end
end
