# Set up WezTerm on Windows + WSL with a background image

**Task for the assistant:** install and configure WezTerm on this Windows machine so it opens
directly into WSL (Ubuntu) and displays a background image behind the terminal text, with the text
remaining fully readable. Also make Neovim's inline markdown images work.

Work through the phases in order. Verify each before moving on.

---

## Why WezTerm and not something else

- **Windows Terminal** supports background images but *not* the kitty graphics protocol, so inline
  images in Neovim will never work there.
- **kitty** is Linux-only as a GUI app. It can run under WSLg, but that adds a Wayland-through-D3D12
  translation layer and needs Windows 11.
- **WezTerm** is a native Windows application that supports both background images *and* the kitty
  graphics protocol, and has first-class WSL integration. It is the only option that satisfies all
  the requirements at once.

---

## Phase 1 — Prerequisites

Confirm these before installing anything. Report the values back.

```powershell
wsl --list --verbose          # need an Ubuntu distro on VERSION 2
wsl --status
winget --version              # may be absent or blocked on managed machines
$PSVersionTable.PSVersion
```

WSL1 will not work for the Neovim image support. If the distro shows `VERSION 1`:

```powershell
wsl --set-version Ubuntu 2
```

---

## Phase 2 — Install WezTerm

Try in this order and stop at the first that succeeds.

**Option A — winget (preferred):**

```powershell
winget install wez.wezterm
```

**Option B — Scoop, if winget is blocked:**

```powershell
scoop bucket add extras
scoop install wezterm
```

**Option C — portable zip, if the machine blocks installers entirely.**
Download the `WezTerm-windows-*.zip` from <https://github.com/wezterm/wezterm/releases/latest>,
extract to `%LOCALAPPDATA%\Programs\wezterm`, and run `wezterm-gui.exe` from there. No admin rights
needed. This is the fallback that works on locked-down corporate machines.

Verify:

```powershell
wezterm --version
```

---

## Phase 3 — Install the font (Windows side)

The config references **JetBrainsMono Nerd Font**. It must be installed on *Windows*, not inside
WSL — WezTerm is a Windows process and renders with Windows fonts.

```powershell
winget install --id=DEVCOM.JetBrainsMonoNerdFont
```

If that ID is unavailable, download `JetBrainsMono.zip` from
<https://github.com/ryanoasis/nerd-fonts/releases/latest>, extract, select all `.ttf` files, right
click → **Install for all users** (or **Install** if you lack admin).

Verify the exact family name, because it must match the config string:

```powershell
[System.Drawing.Text.InstalledFontCollection]::new().Families | Where-Object { $_.Name -like "*JetBrains*" }
```

Without this font every icon in Neovim renders as a box.

---

## Phase 4 — Configuration

WezTerm reads `%USERPROFILE%\.wezterm.lua`. A ready-made config is tracked in this repo at
`wezterm/wezterm.lua` — copy it across (a symlink made from WSL onto the Windows filesystem
is a WSL-style symlink that Windows cannot follow):

```bash
WINHOME="$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")"
cp ~/dotfiles/wezterm/wezterm.lua "$WINHOME/.wezterm.lua"
```

Re-copy after any edit; WezTerm reloads on save. Then substitute the marked values. For
reference, the file contains:

```lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Open straight into WSL rather than PowerShell.
-- Run `wezterm.exe cli list-clients` or check `wsl -l -q` for the exact distro name.
config.default_domain = 'WSL:Ubuntu'

-- Must match an installed Windows font family exactly (see Phase 3).
config.font = wezterm.font 'JetBrainsMono Nerd Font'
config.font_size = 11.0

-- ── Background image ────────────────────────────────────────────────
-- Use a Windows path with forward slashes. A WSL path also works:
--   '//wsl$/Ubuntu/home/<user>/Pictures/wallpaper.png'
config.window_background_image = 'C:/Users/CHANGEME/Pictures/wallpaper.png'

-- brightness is the readability knob. LOWER = image more washed out.
-- 0.05-0.10 is a subtle texture; 0.3+ is a picture you will struggle to read over.
-- This is the inverse of kitty's `background_tint`.
config.window_background_image_hsb = {
  brightness = 0.08,
  hue        = 1.0,
  saturation = 1.0,
}

-- Optional: also make the window itself translucent over the desktop.
-- config.window_background_opacity = 0.95

config.color_scheme = 'Visual Studio Dark+'
config.enable_scroll_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = { left = 4, right = 4, top = 4, bottom = 4 }

-- ── Live brightness adjustment ──────────────────────────────────────
-- WezTerm has no built-in action for this, so cycle through presets.
local levels = { 0.02, 0.05, 0.08, 0.12, 0.20, 0.35 }
local idx = 3
wezterm.on('cycle-brightness', function(window, _)
  idx = (idx % #levels) + 1
  local o = window:get_config_overrides() or {}
  o.window_background_image_hsb = { brightness = levels[idx], hue = 1.0, saturation = 1.0 }
  window:set_config_overrides(o)
  window:toast_notification('wezterm', 'brightness ' .. levels[idx], nil, 1500)
end)

config.keys = {
  { key = 'b', mods = 'CTRL|ALT', action = wezterm.action.EmitEvent 'cycle-brightness' },
  { key = 'F11', mods = '',       action = wezterm.action.ToggleFullScreen },
}

return config
```

**Two values to change:**

1. `default_domain` — replace `Ubuntu` with the exact name from `wsl -l -q`.
2. `window_background_image` — point at a real image file.

---

## Phase 5 — Linux-side configuration

Neovim and tmux both paint their own opaque background and will cover the image unless configured.
Clone the dotfiles repo inside WSL and stow the relevant packages:

```bash
sudo apt update && sudo apt install -y stow git
git clone git@github.com:rparysz/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh nvim tmux bash git
```

The critical settings, if applying by hand instead:

- **Neovim:** the colorscheme must be transparent. For `vscode.nvim`:
  `{ "Mofiqul/vscode.nvim", opts = { transparent = true } }`
- **tmux** in `~/.tmux.conf`:

  ```text
  set -g window-style        'bg=default'
  set -g window-active-style 'bg=default'
  set -g status-style        'bg=default,fg=colour248'
  set -g allow-passthrough on
  set -ga terminal-overrides ",xterm-256color:Tc"
  ```

  Without `allow-passthrough`, inline images will not survive tmux.

Then enable the image module in the Neovim config (`snacks.nvim` opts):

```lua
image = { enabled = true, doc = { enabled = true, inline = true } }
```

---

## Phase 6 — Verify

Run each and confirm:

1. **Background image** — open WezTerm. The image is visible behind the prompt.
2. **WSL** — `uname -a` reports Linux, not an error.
3. **Font** — `echo -e "\ue0b0 \uf07c \uf121"` shows three icons, not boxes.
4. **Truecolor** — `printf '\e[38;2;255;100;0mTRUECOLOR\e[0m\n'` prints in orange.
5. **Transparency through the stack** — open Neovim, then tmux, then Neovim inside tmux. The image
   stays visible in all three.
6. **Inline images** — in Neovim: `:checkhealth snacks`. The image section must report that the
   terminal supports the kitty graphics protocol. Then open a markdown file containing
   `![x](some-image.png)` and confirm it renders.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Image invisible, solid background | nvim/tmux painting over it | Phase 5 — transparency settings |
| Icons render as boxes | Nerd Font missing or name mismatch | Phase 3; verify the exact family name |
| `checkhealth` says no kitty graphics protocol | Not running under WezTerm, or nested in something that strips escapes | Confirm `$TERM_PROGRAM`; check tmux `allow-passthrough` |
| Images fail only inside tmux | passthrough disabled | `set -g allow-passthrough on`, then `tmux kill-server` |
| Colors look flat/wrong in tmux | missing `:Tc` override | add `terminal-overrides` line, restart tmux server |
| WezTerm opens PowerShell | wrong `default_domain` | check `wsl -l -q` for the exact name |
| Text unreadable over image | brightness too high | lower `brightness` to 0.03-0.05, or `ctrl+alt+b` to cycle |
| Config changes ignored | Lua syntax error | run `wezterm --config-file $env:USERPROFILE\.wezterm.lua ls-fonts` to see the parse error |

---

## Notes

- WezTerm reloads `.wezterm.lua` automatically on save — no restart needed.
- `tmux kill-server` is required after changing `window-style`; sourcing the config is not enough.
- On a managed corporate machine, Phase 2 Option C (portable zip) avoids needing admin rights
  entirely. Everything else in this document works without elevation.
