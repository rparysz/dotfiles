-- WezTerm config, for Windows machines running WSL.
--
-- NOT symlinked by install.sh: WezTerm runs on the Windows side and reads
-- %USERPROFILE%\.wezterm.lua, which lives on the Windows filesystem. A symlink
-- created from WSL there is a WSL-style symlink that Windows cannot follow, so
-- this file has to be copied:
--
--   cp ~/dotfiles/wezterm/wezterm.lua "$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")/.wezterm.lua"
--
-- Re-copy after editing. WezTerm reloads the file automatically on save.

local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Open straight into WSL rather than PowerShell.
-- Exact name from `wsl -l -q`.
config.default_domain = 'WSL:Ubuntu'

-- Must match an installed *Windows* font family. WezTerm is a Windows process
-- and renders with Windows fonts — a Nerd Font installed only inside WSL
-- leaves every icon in LazyVim as a box.
config.font = wezterm.font 'JetBrainsMono Nerd Font'
config.font_size = 11.0

-- Disable font ligatures: JetBrains Mono Nerd Font combines sequences like
-- `!=`, `->`, `==` into single glyphs (≠, →, etc.) via OpenType calt/liga
-- features, which WezTerm applies by default. This keeps characters literal.
config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }

config.color_scheme = 'Visual Studio Dark+'
config.enable_scroll_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = { left = 4, right = 4, top = 4, bottom = 4 }

-- ── Background image ────────────────────────────────────────────────────
-- Wallpapers are not tracked in this repo; download one per machine.
-- Windows path, forward slashes. A WSL path also works:
--   '//wsl$/Ubuntu/home/<user>/.config/kitty/wallpapers/foo.webp'
-- Uncomment and point at a real file:
--
-- config.window_background_image = 'C:/Users/YOURNAME/Pictures/wallpaper.png'
--
-- brightness is the readability knob and is the INVERSE of kitty's
-- background_tint: LOWER = image more washed out. 0.05-0.10 is a subtle
-- texture; 0.3+ is a picture you will struggle to read over.
config.window_background_image_hsb = {
  brightness = 0.08,
  hue        = 1.0,
  saturation = 1.0,
}

-- ── Live brightness adjustment (the kitty-tint equivalent) ──────────────
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
  { key = 'b',   mods = 'CTRL|ALT', action = wezterm.action.EmitEvent 'cycle-brightness' },
  { key = 'F11', mods = '',         action = wezterm.action.ToggleFullScreen },
}

return config
