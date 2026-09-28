--!nonstrict
-- WhatsApp Automation Bar Widget for Noctalia Shell
-- Displays current automation status in the status bar and opens the control panel on click.

local glyphConfig = noctalia.getConfig("glyph") or "brand-whatsapp"
local showStatusConfig = noctalia.getConfig("show_status")
if showStatusConfig == nil then
  showStatusConfig = true
end

local isRunning = false
local isRedialing = false
local statusText = "Idle"
local hasMissingDeps = false
local isVertical = false

local function render()
  local iconColor = isRunning and "primary" or (hasMissingDeps and "warning" or "on_surface")
  local currentGlyph = glyphConfig

  if isVertical then
    barWidget.render(ui.column({ align = "center", justify = "center" }, {
      ui.glyph({ name = currentGlyph, color = iconColor, size = 18 }),
    }))
  else
    local children = {
      ui.glyph({ name = currentGlyph, color = iconColor, size = 18 }),
    }

    if showStatusConfig and isRunning and statusText ~= "Idle" then
      table.insert(children, ui.label({
        text = statusText,
        fontSize = 12,
        fontWeight = "bold",
        color = "primary",
      }))
    end

    barWidget.render(ui.row({ gap = 6, align = "center", justify = "center" }, children))
  end

  local tooltipMsg = noctalia.tr("name")
  if isRunning then
    tooltipMsg = `{tooltipMsg} ({statusText})`
  elseif hasMissingDeps then
    tooltipMsg = `{tooltipMsg} (Setup required - missing dependencies)`
  end
  barWidget.setTooltip(tooltipMsg)
end

function update()
  isVertical = barWidget.isVertical()
  render()
end

noctalia.state.watch("whatsapp.isRunning", function(val)
  isRunning = val == true
  render()
end)

noctalia.state.watch("whatsapp.isRedialing", function(val)
  isRedialing = val == true
  render()
end)

noctalia.state.watch("whatsapp.statusText", function(val)
  statusText = val or "Idle"
  render()
end)

noctalia.state.watch("whatsapp.hasMissingDeps", function(val)
  hasMissingDeps = val == true
  render()
end)

function onClick()
  noctalia.togglePanel("muhamm-ad-ahmad/whatsapp:panel")
end

render()
