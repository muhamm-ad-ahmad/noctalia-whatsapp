--!nonstrict
-- Control center tile for WhatsApp Automation

local function render()
  shortcut.setLabel(noctalia.tr("name"))
  shortcut.setIcon("brand-whatsapp")
  local isRunning = noctalia.state.get("whatsapp.isRunning") == true
  shortcut.setActive(isRunning)
end

render()

noctalia.state.watch("whatsapp.isRunning", function(_)
  render()
end)

function onClick()
  noctalia.togglePanel("muhamm-ad-ahmad/whatsapp:panel")
end
