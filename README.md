#  Noctalia WhatsApp Automation Plugin

[![Noctalia Shell](https://img.shields.io/badge/Noctalia-v5%2B-blue?style=flat-square)](https://noctalia.dev)
[![Compositor](https://img.shields.io/badge/Hyprland-Wayland-brightgreen?style=flat-square)](https://hyprland.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

An official-grade plugin for **[Noctalia Shell](https://noctalia.dev)** on **Hyprland** (Wayland) that automates scheduled & repeated messaging, auto call redialing in WhatsApp Web, and includes a built-in one-click dependency installer for new users.

---

## ✨ Features

### 💬 Scheduled & Repeated Messaging
- **Custom Message Text**: Specify any message text to send.
- **Repetitions (Count)**: Set any count (e.g. 10, 100, 500, 1300, or custom).
- **Countdown Delay**: Configurable initial wait before activating WhatsApp (default: 5s test, or 30s, 1m, 2m, 5m).
- **Keystroke Interval**: Control pacing between messages (default: Safe `0.15s`, Normal `0.08s`, Fast `0.04s`).
- **Modes**:
  - **📨 Separate Messages**: Types and sends each repetition as an individual message via `wtype`.
  - **📦 Single Message**: Assembles text repeated $N$ times and pastes via `wl-copy` into a single message.
- **Execution Options**:
  - 🚀 **Floating Terminal**: Runs interactively with colored progress bar, throughput (msg/s), and instant `Ctrl+C` stop.
  - ▶ **Background Mode**: Runs silently with status shown on the Noctalia bar widget and desktop notifications.

---

### 📞 Auto Call Redial
- **Call Types**: Choose between **📞 Voice Call** or **📹 Video Call**.
- **Configurable Redial Attempts**: Call $N$ times (3, 5, 10, 20) or `0` for infinite until stopped.
- **Ring Timeout**: Ring duration per attempt before hanging up and redialing (e.g. 15s, 30s, 45s, 60s).
- **Action on Timeout**:
  - **🔴 Hang Up & Redial**: Automatically clicks the red End Call button and redials.
  - **⏳ Auto-Drop Naturally**: Waits for WhatsApp Web to time out naturally.
- **Pause Between Calls**: Configurable delay between attempts (e.g. 2s, 5s, 10s).
- **Dual Position Calibration**: Calibrate both the **Call icon** and the **End Call button** by hovering over each for 4 seconds.

---

### ⚡ Built-in Dependency Installer
Never struggle with missing packages or permissions:
- The plugin automatically checks required system packages:
  - `wtype` (Wayland keystroke typing)
  - `wl-clipboard` (`wl-copy` for clipboard paste)
  - `hyprctl` (Hyprland window focusing and cursor positioning)
  - `python3` (automation runtime)
  - `python-evdev` (Linux kernel uinput mouse clicks for call redialing)
  - `/dev/uinput` write permissions
- If any dependencies are missing, a warning banner appears with a **⚡ Install Missing Dependencies** button.
- Clicking the button launches an interactive installer script in your terminal that automatically detects your distribution package manager:
  - **Arch Linux / CachyOS / Manjaro / EndeavourOS**: `pacman`
  - **Fedora**: `dnf`
  - **Ubuntu / Debian**: `apt`
  - **openSUSE**: `zypper`
  - **Alpine Linux**: `apk`
  - **Void Linux**: `xbps`
  - **NixOS**: `nix-env`
- Also automatically configures `/dev/uinput` udev rules (`99-uinput.rules`) and adds your user to the `input` group so mouse clicks work seamlessly without requiring root!

---

## 🚀 Installation

### Option 1: Direct Local Installation (Quickest)

Clone or copy this directory into your Noctalia plugins folder:

```bash
mkdir -p ~/.local/share/noctalia/plugins
git clone https://github.com/muhamm-ad-ahmad/noctalia-whatsapp.git ~/.local/share/noctalia/plugins/whatsapp
```

Enable the plugin:

```bash
noctalia msg plugins enable muhamm-ad-ahmad/whatsapp
```

---

### Option 2: Adding as a Git Plugin Source

```bash
noctalia msg plugins source add my-plugins git https://github.com/muhamm-ad-ahmad/noctalia-whatsapp.git
noctalia msg plugins enable muhamm-ad-ahmad/whatsapp
```

---

## 🖥️ Adding the Widget to Noctalia Bar

Open your Noctalia config file (`~/.config/noctalia/config.toml`):

```toml
[bar.default]
# Add "muhamm-ad-ahmad/whatsapp:whatsapp" to start, center, or end:
end = [
  "muhamm-ad-ahmad/whatsapp:whatsapp",
  "media",
  "tray",
  "notifications",
  "volume",
  "session"
]
```

Save the file. Noctalia will hot-reload automatically, and the ** WhatsApp** icon will appear on your bar!

---

## ⌨️ CLI Usage

The plugin includes a full-featured CLI script (`noctalia-whatsapp`) that can be executed directly from your terminal or assigned to keyboard shortcuts:

### Check Dependencies
```bash
noctalia-whatsapp check-deps
```

### Install Missing Dependencies
```bash
noctalia-whatsapp install-deps
```

### Messaging Automation
```bash
# Custom message, count, and delay (default: 5s countdown, 0.15s safe interval)
noctalia-whatsapp --message "Hey there!" --count 10

# Custom parameters
noctalia-whatsapp --message "Hello" --count 50 --delay 10 --interval 0.08

# Single combined message mode (instant paste & send)
noctalia-whatsapp --message "Reminder!" --count 50 --delay 5 --mode single
```

### Auto Call Redialer
```bash
# Auto redial 5 times with 35s timeout and hang up on timeout
noctalia-whatsapp call --attempts 5 --timeout 35 --delay 5 --end-call

# Video call mode
noctalia-whatsapp call --call-type video --attempts 3 --timeout 30

# Infinite redial without hanging up (wait for natural drop)
noctalia-whatsapp call --attempts 0 --timeout 45 --delay 5 --no-end-call

# Calibrate Call button position (hover mouse over call icon for 4s)
noctalia-whatsapp call --calibrate-call

# Calibrate End Call button position (hover mouse over red hangup button for 4s)
noctalia-whatsapp call --calibrate-end
```

---

## 📁 Project Structure

```
noctalia-whatsapp/
├── plugin.toml             # Noctalia plugin manifest & settings schema
├── widget.luau             # Status bar widget entry script
├── panel.luau              # Interactive pop-up surface entry script
├── service.luau            # Headless background service (IPC & process monitor)
├── shortcut.luau           # Control Center quick-toggle tile entry script
├── bin/
│   └── noctalia-whatsapp   # Python 3 automation CLI backend
├── scripts/
│   └── install-deps.sh     # Multi-distro dependency & udev installer
├── translations/
│   └── en.json             # Localization strings
├── LICENSE                 # MIT License
└── README.md               # Documentation
```

---

## 🛠️ Uploading to Noctalia Plugins Directory

This plugin is fully compliant with the [Noctalia Plugin Development Guide](https://docs.noctalia.dev/noctalia/plugins/development/) and ready for submission to the official [Noctalia Community Plugins repository](https://github.com/noctalia-dev/community-plugins):

1. Fork `https://github.com/noctalia-dev/community-plugins`.
2. Add this folder under `whatsapp/`.
3. Open a Pull Request!

---

## 📜 License

Distributed under the [MIT License](LICENSE). Copyright © 2026 Muhammad Ahmad.
