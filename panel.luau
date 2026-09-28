--!nonstrict
-- WhatsApp Automation Control Panel for Noctalia Shell
-- Interactive declarative UI with Scheduled Messaging, Auto Call Redial, and Dependency Management.

local pluginDir = noctalia.pluginDir()
local binPath = pluginDir .. "/bin/noctalia-whatsapp"
local installScript = pluginDir .. "/scripts/install-deps.sh"

-- Active navigation tab: "messages" | "redial" | "deps"
local activeTab = "messages"

-- State tracking
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

-- Form state: Messaging
local messageText = "-100"
local countText = "1300"
local delayText = "120"
local graceText = "5"
local intervalText = "0.08"
local selectedMode = "separate" -- "separate" | "single"

-- Form keys for programmatically updating input fields
local msgKey = 0
local countKey = 0
local delayKey = 0
local graceKey = 0
local intervalKey = 0

-- Form state: Auto Call Redial
local selectedCallType = "voice" -- "voice" | "video"
local attemptsText = "5"
local timeoutText = "35"
local endCallOnTimeout = true
local pauseText = "5"
local callGraceText = "3"

-- Redial form keys
local attemptsKey = 0
local timeoutKey = 0
local pauseKey = 0
local callGraceKey = 0

local render

-- ── Terminal Runner ──────────────────────────────────────────────────────────

local function runTerminalCommand(cmd)
  local customTerm = noctalia.getConfig("terminal_cmd")
  if customTerm and customTerm ~= "" then
    local escaped = cmd:gsub("'", "'\\''")
    noctalia.runAsync(`{customTerm} sh -c '{escaped}'`)
    panel.close()
    return
  end

  local ok = noctalia.runInTerminal(cmd)
  if not ok then
    -- Fallback to hyprctl floating execution if runInTerminal fails
    local escaped = cmd:gsub("'", "'\\''")
    noctalia.runAsync(`hyprctl dispatch exec "[float;size 780 540;center] kitty sh -c '{escaped}'"`)
  end
  panel.close()
end

-- ── Message Action Handlers ──────────────────────────────────────────────────

function onMsgChange(val)
  messageText = val
end

function onCountChange(val)
  countText = val
end

function setCount(val)
  countText = tostring(val)
  countKey = countKey + 1
  render()
end

function onDelayChange(val)
  delayText = val
end

function setDelay(val)
  delayText = tostring(val)
  delayKey = delayKey + 1
  render()
end

function onGraceChange(val)
  graceText = val
end

function setGrace(val)
  graceText = tostring(val)
  graceKey = graceKey + 1
  render()
end

function onIntervalChange(val)
  intervalText = val
end

function setInterval(val)
  intervalText = tostring(val)
  intervalKey = intervalKey + 1
  render()
end

function setMode(mode)
  selectedMode = mode
  render()
end

function launchMessageTerminal()
  local msgEsc = (messageText or "-100"):gsub("'", "'\\''")
  local d = tonumber(delayText) or 120
  local g = tonumber(graceText) or 5
  local c = tonumber(countText) or 1300
  local i = tonumber(intervalText) or 0.08
  local m = selectedMode or "separate"

  local cmd = `python3 "{binPath}" --message '{msgEsc}' --delay {d} --grace {g} --count {c} --interval {i} --mode {m}`
  runTerminalCommand(cmd)
end

function startMessageBackground()
  local msgEsc = (messageText or "-100"):gsub("'", "'\\''")
  local d = tonumber(delayText) or 120
  local g = tonumber(graceText) or 5
  local c = tonumber(countText) or 1300
  local i = tonumber(intervalText) or 0.08
  local m = selectedMode or "separate"

  local cmd = `python3 "{binPath}" --message '{msgEsc}' --delay {d} --grace {g} --count {c} --interval {i} --mode {m}`
  noctalia.runAsync(cmd)
  noctalia.state.set("whatsapp.cmd", "STARTED_MESSAGES_BG")
  noctalia.notify(noctalia.tr("name"), "Started messaging automation in background.")
  panel.close()
end

function stopBackground()
  noctalia.state.set("whatsapp.cmd", "STOP")
end

-- ── Call Redial Action Handlers ──────────────────────────────────────────────

function setCallType(callType)
  selectedCallType = callType
  render()
end

function onAttemptsChange(val)
  attemptsText = val
end

function setAttempts(val)
  attemptsText = tostring(val)
  attemptsKey = attemptsKey + 1
  render()
end

function onTimeoutChange(val)
  timeoutText = val
end

function setTimeout(val)
  timeoutText = tostring(val)
  timeoutKey = timeoutKey + 1
  render()
end

function setEndCall(val)
  endCallOnTimeout = val
  render()
end

function onPauseChange(val)
  pauseText = val
end

function setPause(val)
  pauseText = tostring(val)
  pauseKey = pauseKey + 1
  render()
end

function onCallGraceChange(val)
  callGraceText = val
end

function setCallGrace(val)
  callGraceText = tostring(val)
  callGraceKey = callGraceKey + 1
  render()
end

function launchRedialTerminal()
  local ct = selectedCallType or "voice"
  local a = tonumber(attemptsText) or 5
  local t = tonumber(timeoutText) or 35
  local d = tonumber(pauseText) or 5
  local g = tonumber(callGraceText) or 3
  local endFlag = endCallOnTimeout and "--end-call" or "--no-end-call"

  local cmd = `python3 "{binPath}" call --call-type {ct} --attempts {a} --timeout {t} --delay {d} --grace {g} {endFlag}`
  runTerminalCommand(cmd)
end

function startRedialBackground()
  local ct = selectedCallType or "voice"
  local a = tonumber(attemptsText) or 5
  local t = tonumber(timeoutText) or 35
  local d = tonumber(pauseText) or 5
  local g = tonumber(callGraceText) or 3
  local endFlag = endCallOnTimeout and "--end-call" or "--no-end-call"

  local cmd = `python3 "{binPath}" call --call-type {ct} --attempts {a} --timeout {t} --delay {d} --grace {g} {endFlag}`
  noctalia.runAsync(cmd)
  noctalia.state.set("whatsapp.cmd", "STARTED_REDIAL_BG")
  noctalia.notify(noctalia.tr("name"), "Started auto call redialer in background.")
  panel.close()
end

function calibrateCall()
  local cmd = `python3 "{binPath}" call --calibrate-call`
  runTerminalCommand(cmd)
end

function calibrateEnd()
  local cmd = `python3 "{binPath}" call --calibrate-end`
  runTerminalCommand(cmd)
end

-- ── Dependency Handlers ──────────────────────────────────────────────────────

function installDependencies()
  runTerminalCommand(`bash "{installScript}"`)
end

function refreshDependencies()
  noctalia.state.set("whatsapp.cmd", "CHECK_DEPS")
  noctalia.notify(noctalia.tr("name"), "Refreshing dependency audit...")
end

function switchTab(tab)
  activeTab = tab
  render()
end

function onClose()
  panel.close()
end

-- ── UI Rendering ─────────────────────────────────────────────────────────────

render = function()
  local scrollItems = {}

  -- Missing Dependencies Banner (when on messages or redial tab)
  if hasMissingDeps and activeTab ~= "deps" then
    table.insert(scrollItems, ui.column({
      fill = "warning/0.12",
      border = "warning/0.4",
      borderWidth = 1,
      radius = 8,
      padding = 10,
      gap = 6,
    }, {
      ui.row({ align = "center", justify = "space_between" }, {
        ui.row({ gap = 8, align = "center" }, {
          ui.glyph({ name = "alert-triangle", color = "warning", size = 18 }),
          ui.label({
            text = noctalia.tr("ui.missing_deps_banner"),
            color = "warning",
            fontSize = 12,
            fontWeight = "bold",
          }),
        }),
        ui.button({
          text = "Install",
          variant = "primary",
          controlSize = "sm",
          onClick = "installDependencies",
        }),
      }),
    }))
  end

  -- ============================================================================
  -- TAB 1: SCHEDULED MESSAGES
  -- ============================================================================
  if activeTab == "messages" then
    -- 1. Message Text
    table.insert(scrollItems, ui.column({ gap = 6 }, {
      ui.label({ text = noctalia.tr("ui.message_text_header"), fontSize = 11, fontWeight = "bold", color = "outline" }),
      ui.input({
        key = "msg-" .. msgKey,
        value = messageText,
        placeholder = noctalia.tr("ui.message_text_placeholder"),
        controlSize = "md",
        onChange = "onMsgChange",
      }),
    }))

    -- 2. Repetitions (Count)
    table.insert(scrollItems, ui.column({ gap = 6 }, {
      ui.label({ text = noctalia.tr("ui.repetitions_header"), fontSize = 11, fontWeight = "bold", color = "outline" }),
      ui.row({ gap = 6, align = "center" }, {
        ui.input({
          key = "cnt-" .. countKey,
          value = countText,
          width = 90,
          controlSize = "sm",
          onChange = "onCountChange",
        }),
        ui.button({ text = "10", controlSize = "sm", selected = countText == "10", onClick = function() setCount(10) end }),
        ui.button({ text = "100", controlSize = "sm", selected = countText == "100", onClick = function() setCount(100) end }),
        ui.button({ text = "500", controlSize = "sm", selected = countText == "500", onClick = function() setCount(500) end }),
        ui.button({ text = "1300", controlSize = "sm", selected = countText == "1300", onClick = function() setCount(1300) end }),
      }),
    }))

    -- 3. Countdown Delay
    table.insert(scrollItems, ui.column({ gap = 6 }, {
      ui.label({ text = noctalia.tr("ui.countdown_delay_header"), fontSize = 11, fontWeight = "bold", color = "outline" }),
      ui.row({ gap = 6, align = "center" }, {
        ui.input({
          key = "delay-" .. delayKey,
          value = delayText,
          width = 80,
          controlSize = "sm",
          onChange = "onDelayChange",
        }),
        ui.button({ text = "5s", controlSize = "sm", selected = delayText == "5", tooltip = "Quick test", onClick = function() setDelay(5) end }),
        ui.button({ text = "30s", controlSize = "sm", selected = delayText == "30", onClick = function() setDelay(30) end }),
        ui.button({ text = "1m", controlSize = "sm", selected = delayText == "60", onClick = function() setDelay(60) end }),
        ui.button({ text = "2m", controlSize = "sm", selected = delayText == "120", onClick = function() setDelay(120) end }),
        ui.button({ text = "5m", controlSize = "sm", selected = delayText == "300", onClick = function() setDelay(300) end }),
      }),
    }))

    -- 4. Grace Period
    table.insert(scrollItems, ui.column({ gap = 6 }, {
      ui.label({ text = noctalia.tr("ui.grace_period_header"), fontSize = 11, fontWeight = "bold", color = "outline" }),
      ui.row({ gap = 6, align = "center" }, {
        ui.input({
          key = "grace-" .. graceKey,
          value = graceText,
          width = 80,
          controlSize = "sm",
          onChange = "onGraceChange",
        }),
        ui.button({ text = "0s", controlSize = "sm", selected = graceText == "0", tooltip = "Instant", onClick = function() setGrace(0) end }),
        ui.button({ text = "3s", controlSize = "sm", selected = graceText == "3", onClick = function() setGrace(3) end }),
        ui.button({ text = "5s", controlSize = "sm", selected = graceText == "5", onClick = function() setGrace(5) end }),
        ui.button({ text = "10s", controlSize = "sm", selected = graceText == "10", onClick = function() setGrace(10) end }),
      }),
    }))

    -- 5. Keystroke Interval
    table.insert(scrollItems, ui.column({ gap = 6 }, {
      ui.label({ text = noctalia.tr("ui.interval_header"), fontSize = 11, fontWeight = "bold", color = "outline" }),
      ui.row({ gap = 6, align = "center" }, {
        ui.input({
          key = "int-" .. intervalKey,
          value = intervalText,
          width = 80,
          controlSize = "sm",
          onChange = "onIntervalChange",
        }),
        ui.button({ text = "Fast (0.04s)", controlSize = "sm", selected = intervalText == "0.04", onClick = function() setInterval(0.04) end }),
        ui.button({ text = "Normal (0.08s)", controlSize = "sm", selected = intervalText == "0.08", onClick = function() setInterval(0.08) end }),
        ui.button({ text = "Safe (0.15s)", controlSize = "sm", selected = intervalText == "0.15", onClick = function() setInterval(0.15) end }),
      }),
    }))

    -- 6. Mode
    table.insert(scrollItems, ui.column({ gap = 6 }, {
      ui.label({ text = noctalia.tr("ui.mode_header"), fontSize = 11, fontWeight = "bold", color = "outline" }),
      ui.row({ gap = 8 }, {
        ui.button({
          text = noctalia.tr("ui.mode_separate"),
          flexGrow = 1,
          controlSize = "md",
          selected = selectedMode == "separate",
          onClick = function() setMode("separate") end,
        }),
        ui.button({
          text = noctalia.tr("ui.mode_single"),
          flexGrow = 1,
          controlSize = "md",
          selected = selectedMode == "single",
          onClick = function() setMode("single") end,
        }),
      }),
    }))

    table.insert(scrollItems, ui.separator({ thickness = 1, color = "outline/0.2", spacing = 4 }))

    -- 7. Actions
    local msgBgRow = {
      ui.button({
        text = isRunning and noctalia.tr("ui.btn_running_bg") or noctalia.tr("ui.btn_start_bg"),
        glyph = "player-play",
        flexGrow = 1,
        controlSize = "md",
        enabled = not isRunning,
        onClick = "startMessageBackground",
      }),
    }
    if isRunning then
      table.insert(msgBgRow, ui.button({
        text = noctalia.tr("ui.btn_stop"),
        glyph = "player-stop",
        variant = "destructive",
        controlSize = "md",
        onClick = "stopBackground",
      }))
    end

    table.insert(scrollItems, ui.column({ gap = 8 }, {
      ui.button({
        text = noctalia.tr("ui.btn_launch_terminal"),
        glyph = "terminal-2",
        variant = "primary",
        controlSize = "md",
        onClick = "launchMessageTerminal",
      }),
      ui.row({ gap = 8 }, msgBgRow),
    }))

    table.insert(scrollItems, ui.label({
      text = noctalia.tr("ui.note_messages"),
      fontSize = 11,
      color = "outline",
      maxLines = 2,
    }))

  -- ============================================================================
  -- TAB 2: AUTO CALL REDIAL
  -- ============================================================================
  elseif activeTab == "redial" then
    -- 0. Call Type
    table.insert(scrollItems, ui.column({ gap = 6 }, {
      ui.label({ text = noctalia.tr("ui.call_type_header"), fontSize = 11, fontWeight = "bold", color = "outline" }),
      ui.row({ gap = 8 }, {
        ui.button({
          text = noctalia.tr("ui.call_voice"),
          glyph = "phone",
          flexGrow = 1,
          controlSize = "md",
          selected = selectedCallType == "voice",
          onClick = function() setCallType("voice") end,
        }),
        ui.button({
          text = noctalia.tr("ui.call_video"),
          glyph = "video",
          flexGrow = 1,
          controlSize = "md",
          selected = selectedCallType == "video",
          onClick = function() setCallType("video") end,
        }),
      }),
    }))

    -- 1. Redial Attempts
    table.insert(scrollItems, ui.column({ gap = 6 }, {
      ui.label({ text = noctalia.tr("ui.redial_attempts_header"), fontSize = 11, fontWeight = "bold", color = "outline" }),
      ui.row({ gap = 6, align = "center" }, {
        ui.input({
          key = "att-" .. attemptsKey,
          value = attemptsText,
          width = 80,
          controlSize = "sm",
          onChange = "onAttemptsChange",
        }),
        ui.button({ text = "3", controlSize = "sm", selected = attemptsText == "3", onClick = function() setAttempts(3) end }),
        ui.button({ text = "5", controlSize = "sm", selected = attemptsText == "5", onClick = function() setAttempts(5) end }),
        ui.button({ text = "10", controlSize = "sm", selected = attemptsText == "10", onClick = function() setAttempts(10) end }),
        ui.button({ text = "20", controlSize = "sm", selected = attemptsText == "20", onClick = function() setAttempts(20) end }),
        ui.button({ text = "∞ (0)", controlSize = "sm", selected = attemptsText == "0", tooltip = "Infinite", onClick = function() setAttempts(0) end }),
      }),
    }))

    -- 2. Ring Timeout
    table.insert(scrollItems, ui.column({ gap = 6 }, {
      ui.label({ text = noctalia.tr("ui.ring_timeout_header"), fontSize = 11, fontWeight = "bold", color = "outline" }),
      ui.row({ gap = 6, align = "center" }, {
        ui.input({
          key = "to-" .. timeoutKey,
          value = timeoutText,
          width = 80,
          controlSize = "sm",
          onChange = "onTimeoutChange",
        }),
        ui.button({ text = "15s", controlSize = "sm", selected = timeoutText == "15", onClick = function() setTimeout(15) end }),
        ui.button({ text = "30s", controlSize = "sm", selected = timeoutText == "30", onClick = function() setTimeout(30) end }),
        ui.button({ text = "45s", controlSize = "sm", selected = timeoutText == "45", onClick = function() setTimeout(45) end }),
        ui.button({ text = "60s", controlSize = "sm", selected = timeoutText == "60", onClick = function() setTimeout(60) end }),
      }),
    }))

    -- 3. Action on Ring Timeout
    table.insert(scrollItems, ui.column({ gap = 6 }, {
      ui.label({ text = noctalia.tr("ui.action_timeout_header"), fontSize = 11, fontWeight = "bold", color = "outline" }),
      ui.row({ gap = 8 }, {
        ui.button({
          text = noctalia.tr("ui.action_hangup"),
          flexGrow = 1,
          controlSize = "md",
          selected = endCallOnTimeout == true,
          onClick = function() setEndCall(true) end,
        }),
        ui.button({
          text = noctalia.tr("ui.action_natural"),
          flexGrow = 1,
          controlSize = "md",
          selected = endCallOnTimeout == false,
          onClick = function() setEndCall(false) end,
        }),
      }),
    }))

    -- 4. Pause Between Calls
    table.insert(scrollItems, ui.column({ gap = 6 }, {
      ui.label({ text = noctalia.tr("ui.pause_between_calls_header"), fontSize = 11, fontWeight = "bold", color = "outline" }),
      ui.row({ gap = 6, align = "center" }, {
        ui.input({
          key = "pause-" .. pauseKey,
          value = pauseText,
          width = 80,
          controlSize = "sm",
          onChange = "onPauseChange",
        }),
        ui.button({ text = "2s", controlSize = "sm", selected = pauseText == "2", onClick = function() setPause(2) end }),
        ui.button({ text = "5s", controlSize = "sm", selected = pauseText == "5", onClick = function() setPause(5) end }),
        ui.button({ text = "10s", controlSize = "sm", selected = pauseText == "10", onClick = function() setPause(10) end }),
      }),
    }))

    -- 5. Grace Period
    table.insert(scrollItems, ui.column({ gap = 6 }, {
      ui.label({ text = noctalia.tr("ui.grace_period_call_header"), fontSize = 11, fontWeight = "bold", color = "outline" }),
      ui.row({ gap = 6, align = "center" }, {
        ui.input({
          key = "cgrace-" .. callGraceKey,
          value = callGraceText,
          width = 80,
          controlSize = "sm",
          onChange = "onCallGraceChange",
        }),
        ui.button({ text = "0s", controlSize = "sm", selected = callGraceText == "0", onClick = function() setCallGrace(0) end }),
        ui.button({ text = "3s", controlSize = "sm", selected = callGraceText == "3", onClick = function() setCallGrace(3) end }),
        ui.button({ text = "5s", controlSize = "sm", selected = callGraceText == "5", onClick = function() setCallGrace(5) end }),
      }),
    }))

    -- 6. Position Calibration
    table.insert(scrollItems, ui.column({ gap = 6 }, {
      ui.label({ text = noctalia.tr("ui.calibration_header"), fontSize = 11, fontWeight = "bold", color = "outline" }),
      ui.row({ gap = 8 }, {
        ui.button({
          text = noctalia.tr("ui.btn_calibrate_call"),
          glyph = "target",
          flexGrow = 1,
          controlSize = "sm",
          onClick = "calibrateCall",
        }),
        ui.button({
          text = noctalia.tr("ui.btn_calibrate_end"),
          glyph = "phone-off",
          flexGrow = 1,
          controlSize = "sm",
          onClick = "calibrateEnd",
        }),
      }),
    }))

    table.insert(scrollItems, ui.separator({ thickness = 1, color = "outline/0.2", spacing = 4 }))

    -- 7. Redial Actions
    local redialActionRow = {
      ui.button({
        text = isRedialing and "▶ Redialing in Background..." or noctalia.tr("ui.btn_start_redial_bg"),
        glyph = "phone-calling",
        flexGrow = 1,
        controlSize = "md",
        enabled = not isRedialing,
        onClick = "startRedialBackground",
      }),
    }
    if isRedialing then
      table.insert(redialActionRow, ui.button({
        text = noctalia.tr("ui.btn_stop_redial"),
        glyph = "phone-off",
        variant = "destructive",
        controlSize = "md",
        onClick = "stopBackground",
      }))
    end

    table.insert(scrollItems, ui.column({ gap = 8 }, {
      ui.button({
        text = noctalia.tr("ui.btn_start_redial_terminal"),
        glyph = "terminal-2",
        variant = "primary",
        controlSize = "md",
        onClick = "launchRedialTerminal",
      }),
      ui.row({ gap = 8 }, redialActionRow),
    }))

    table.insert(scrollItems, ui.label({
      text = noctalia.tr("ui.note_redial"),
      fontSize = 11,
      color = "outline",
      maxLines = 2,
    }))

  -- ============================================================================
  -- TAB 3: DEPENDENCIES & SETUP
  -- ============================================================================
  elseif activeTab == "deps" then
    table.insert(scrollItems, ui.column({ gap = 6 }, {
      ui.label({ text = noctalia.tr("ui.deps_header"), fontSize = 13, fontWeight = "bold", color = "primary" }),
      ui.label({ text = noctalia.tr("ui.deps_desc"), fontSize = 11, color = "outline" }),
    }))

    local function depRow(label, installed, desc, fixHint)
      local iconName = installed and "circle-check" or "circle-x"
      local iconColor = installed and "primary" or "error"
      local statusLbl = installed and "Installed" or "Missing"

      local cardChildren = {
        ui.row({ align = "center", justify = "space_between" }, {
          ui.row({ gap = 8, align = "center" }, {
            ui.glyph({ name = iconName, color = iconColor, size = 18 }),
            ui.label({ text = label, fontWeight = "bold", fontSize = 13 }),
          }),
          ui.label({ text = statusLbl, fontWeight = "bold", fontSize = 12, color = iconColor }),
        }),
        ui.label({ text = desc, fontSize = 11, color = "outline" }),
      }
      if not installed and fixHint then
        table.insert(cardChildren, ui.label({ text = fixHint, fontSize = 11, color = "warning" }))
      end

      return ui.column({
        padding = 10,
        radius = 8,
        fill = installed and "surface_variant/0.3" or "error/0.1",
        border = installed and "outline/0.2" or "error/0.4",
        borderWidth = 1,
        gap = 4,
      }, cardChildren)
    end

    table.insert(scrollItems, depRow(
      "wtype",
      deps.wtype,
      "Wayland keystroke typer - required to send text messages automatically.",
      "Arch: pacman -S wtype | Fedora: dnf install wtype | Debian: apt install wtype"
    ))

    table.insert(scrollItems, depRow(
      "wl-clipboard (wl-copy)",
      deps.wl_copy,
      "Wayland clipboard utility - required for single message assembly & paste.",
      "Install wl-clipboard package."
    ))

    table.insert(scrollItems, depRow(
      "hyprctl (Hyprland)",
      deps.hyprctl,
      "Hyprland window manager IPC - used to focus WhatsApp and get coordinates.",
      "Ensure you are running Noctalia on Hyprland."
    ))

    table.insert(scrollItems, depRow(
      "python3",
      deps.python3,
      "Python 3 runtime - drives the automation script and timing logic.",
      "Standard python package."
    ))

    table.insert(scrollItems, depRow(
      "python-evdev",
      deps.python_evdev,
      "Kernel input injection - required for clicking Call and Hang-Up buttons.",
      "Arch: pacman -S python-evdev | Fedora: python3-evdev | Debian: python3-evdev"
    ))

    local uinputDesc = deps.uinput_access
      and "/dev/uinput is writable by current user."
      or "Write access to /dev/uinput required for mouse clicks without root."
    local uinputFix = "Run installer or: sudo usermod -aG input $USER (with udev rules)."
    table.insert(scrollItems, depRow(
      "/dev/uinput permissions",
      deps.uinput_access,
      uinputDesc,
      uinputFix
    ))

    table.insert(scrollItems, ui.separator({ thickness = 1, color = "outline/0.2", spacing = 6 }))

    table.insert(scrollItems, ui.row({ gap = 8 }, {
      ui.button({
        text = noctalia.tr("ui.btn_install_deps"),
        glyph = "bolt",
        variant = "primary",
        flexGrow = 1,
        controlSize = "md",
        onClick = "installDependencies",
      }),
      ui.button({
        text = noctalia.tr("ui.btn_refresh_deps"),
        glyph = "refresh",
        variant = "secondary",
        controlSize = "md",
        onClick = "refreshDependencies",
      }),
    }))
  end

  -- ============================================================================
  -- MAIN PANEL CONTAINER
  -- ============================================================================
  panel.render(ui.column({
    padding = 14,
    gap = 10,
    fill = "surface",
    radius = 12,
  }, {
    -- Header Row
    ui.row({ align = "center", justify = "space_between" }, {
      ui.row({ gap = 8, align = "center" }, {
        ui.glyph({ name = "brand-whatsapp", color = "#25D366", size = 22 }),
        ui.label({
          text = noctalia.tr("ui.title"),
          fontSize = 15,
          fontWeight = "bold",
          color = "on_surface",
        }),
      }),
      ui.button({
        glyph = "x",
        variant = "ghost",
        controlSize = "sm",
        onClick = "onClose",
      }),
    }),

    -- Tab Switcher
    ui.row({ gap = 6 }, {
      ui.button({
        text = noctalia.tr("ui.tab_messages"),
        flexGrow = 1,
        controlSize = "sm",
        selected = activeTab == "messages",
        onClick = function() switchTab("messages") end,
      }),
      ui.button({
        text = noctalia.tr("ui.tab_redial"),
        flexGrow = 1,
        controlSize = "sm",
        selected = activeTab == "redial",
        onClick = function() switchTab("redial") end,
      }),
      ui.button({
        text = hasMissingDeps and "⚠️ Setup" or noctalia.tr("ui.tab_deps"),
        flexGrow = 1,
        controlSize = "sm",
        selected = activeTab == "deps",
        variant = hasMissingDeps and "outline" or "default",
        onClick = function() switchTab("deps") end,
      }),
    }),

    ui.separator({ thickness = 1, color = "outline/0.2", spacing = 2 }),

    -- Scrollable content
    ui.scroll({
      gap = 12,
      padding = 2,
      flexGrow = 1,
    }, scrollItems),
  }))
end

function onOpen(_context)
  isRunning = noctalia.state.get("whatsapp.isRunning") == true
  isRedialing = noctalia.state.get("whatsapp.isRedialing") == true
  statusText = noctalia.state.get("whatsapp.statusText") or "Idle"
  hasMissingDeps = noctalia.state.get("whatsapp.hasMissingDeps") == true
  local curDeps = noctalia.state.get("whatsapp.deps")
  if curDeps then
    deps = curDeps
  end

  -- Refresh dependencies check on panel open
  noctalia.state.set("whatsapp.cmd", "CHECK_DEPS")

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

noctalia.state.watch("whatsapp.deps", function(val)
  if val then
    deps = val
    render()
  end
end)
