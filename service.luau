--!nonstrict
-- WhatsApp Automation Headless Service for Noctalia Shell
-- Manages background execution, process monitoring, and dependency audit.

noctalia.setUpdateInterval(1000)

local pluginDir = noctalia.pluginDir()
local binPath = pluginDir .. "/bin/noctalia-whatsapp"

local isRunning = false
local isRedialing = false
local statusText = "Idle"
local deps = {
  wtype = false,
  wl_copy = false,
  hyprctl = false,
  python3 = false,
  python_evdev = false,
  uinput_access = false,
  all_ok = false,
}
local hasMissingDeps = false

-- Publish initial state
noctalia.state.set("whatsapp.isRunning", false)
noctalia.state.set("whatsapp.isRedialing", false)
noctalia.state.set("whatsapp.statusText", "Idle")
noctalia.state.set("whatsapp.hasMissingDeps", false)
noctalia.state.set("whatsapp.deps", deps)

local function checkDependencies()
  -- Fast checks directly via noctalia host capabilities
  deps.wtype = noctalia.commandExists("wtype")
  deps.wl_copy = noctalia.commandExists("wl-copy")
  deps.hyprctl = noctalia.commandExists("hyprctl")
  deps.python3 = noctalia.commandExists("python3")

  -- Run python audit for evdev and uinput permissions
  local cmd = `python3 "{binPath}" check-deps --json`
  noctalia.runAsync(cmd, function(result)
    if result.stdout and result.stdout ~= "" then
      local parsed, err = noctalia.json.decode(result.stdout)
      if parsed and not err then
        deps.wtype = parsed.wtype == true
        deps.wl_copy = parsed.wl_copy == true
        deps.hyprctl = parsed.hyprctl == true
        deps.python3 = parsed.python3 == true
        deps.python_evdev = parsed.python_evdev == true
        deps.uinput_access = parsed.uinput_access == true
        deps.all_ok = parsed.all_ok == true
      end
    end

    hasMissingDeps = not (deps.wtype and deps.wl_copy and deps.python3 and deps.python_evdev and deps.uinput_access)
    noctalia.state.set("whatsapp.deps", deps)
    noctalia.state.set("whatsapp.hasMissingDeps", hasMissingDeps)
  end)
end

-- Command listener
noctalia.state.watch("whatsapp.cmd", function(cmd)
  if cmd == "CHECK_DEPS" then
    checkDependencies()
  elseif cmd == "STOP" then
    noctalia.runAsync("pkill -f noctalia-whatsapp", function()
      isRunning = false
      isRedialing = false
      statusText = "Idle"
      noctalia.state.set("whatsapp.isRunning", false)
      noctalia.state.set("whatsapp.isRedialing", false)
      noctalia.state.set("whatsapp.statusText", "Idle")
      noctalia.notify(noctalia.tr("name"), "Process stopped.")
    end)
  elseif cmd == "STARTED_MESSAGES_BG" then
    isRunning = true
    isRedialing = false
    statusText = "Sending..."
    noctalia.state.set("whatsapp.isRunning", true)
    noctalia.state.set("whatsapp.isRedialing", false)
    noctalia.state.set("whatsapp.statusText", statusText)
  elseif cmd == "STARTED_REDIAL_BG" then
    isRunning = true
    isRedialing = true
    statusText = "Redialing..."
    noctalia.state.set("whatsapp.isRunning", true)
    noctalia.state.set("whatsapp.isRedialing", true)
    noctalia.state.set("whatsapp.statusText", statusText)
  end
end)

local tickCount = 0

function update()
  tickCount = tickCount + 1

  -- Check process state when marked running
  if isRunning or isRedialing then
    noctalia.processMatches(function(matched)
      if not matched then
        -- Process finished or was terminated
        isRunning = false
        isRedialing = false
        statusText = "Idle"
        noctalia.state.set("whatsapp.isRunning", false)
        noctalia.state.set("whatsapp.isRedialing", false)
        noctalia.state.set("whatsapp.statusText", "Idle")
      end
    end, "noctalia-whatsapp")
  end

  -- Periodically re-check dependencies every 10 seconds if there were missing deps
  if hasMissingDeps and tickCount % 10 == 0 then
    checkDependencies()
  end
end

-- Initial dependency check at service load
checkDependencies()
