# dotfiles

Configuration for Fedora/KDE and WSL. Everything tracked here is **portable** — no
absolute paths, no hostnames, no machine-specific toolchains. Per-machine settings live
in untracked `*.local` files that the installer seeds from `templates/`.

New machine? See **[SETUP.md](SETUP.md)**. Windows/WSL? See
**[docs/wezterm-wsl-setup.md](docs/wezterm-wsl-setup.md)**.
Browsing a repo's markdown in a browser? See **[docs/mdview.md](docs/mdview.md)**.

## Layout

| Package | Links to | Contents |
|---|---|---|
| `bash` | `~/.bashrc`, `~/.bash_profile`, `~/.profile` | idempotent PATH helpers, `md` function, distro-agnostic git prompt |
| `git` | `~/.gitconfig` | portable settings; identity via `~/.gitconfig.local` |
| `tmux` | `~/.tmux.conf` | `Ctrl-a` prefix, prefixless key table, transparent panes, graphics passthrough |
| `nvim` | `~/.config/nvim/` | LazyVim, vscode colorscheme (transparent), markdown rendering, inline images |
| `kitty` | `~/.config/kitty/` | font, background image, tint keybindings, `wallpapers/` |
| `alacritty` | `~/.config/alacritty/` | fallback terminal |
| `bin` | `~/.local/bin/`, `~/.local/lib/` | `kitty-bg`, `kitty-tint`, `mdview` |
| `markdownlint` | `~/.markdownlint-cli2.yaml` | linter rules |

`wezterm/wezterm.lua` is tracked but **not** symlinked — WezTerm runs on the Windows side
and reads `%USERPROFILE%\.wezterm.lua`, which has to be copied rather than linked. See
[docs/wezterm-wsl-setup.md](docs/wezterm-wsl-setup.md).

Portable across both terminals: `bash`, `git`, `tmux`, `nvim`, `markdownlint`.
Terminal-specific: `kitty` + `bin` (kitty only), `wezterm` (Windows/WSL only).

## Install

```bash
git clone git@github.com:rparysz/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh -n          # preview
./install.sh             # link everything
./install.sh nvim kitty  # or just some packages
./install.sh -D          # unlink
```

No dependencies beyond coreutils — deliberately no `stow`, so it runs on machines where
you cannot install packages. Real files it displaces are moved to
`~/.dotfiles-backup-<timestamp>/`; symlinks already pointing here are left alone. `-D`
removes only symlinks that point into this repo.

## Machine-local files

Seeded on first install, never tracked:

| File | Holds |
|---|---|
| `~/.bashrc.local` | toolchain paths, per-machine env |
| `~/.gitconfig.local` | git identity — work vs. personal email |
| `~/.config/kitty/local.conf` | font size, alternate wallpaper |

`.bashrc` exposes three helpers for use in `.bashrc.local`:

```bash
path_prepend /some/dir    # first — user tools
path_append  /some/dir    # last  — toolchains bundling their own cmake/ninja
path_demote  /opt/st      # move matching entries to the end
```

`path_demote` exists because installers drop scripts into `/etc/profile.d/` that prepend
their own toolchain ahead of `/usr/bin` — STM32CubeCLT does exactly this, shadowing the
system `cmake` and `ninja`. Demoting fixes it without editing anything under `/etc`.
All three are idempotent, so nested shells don't grow `PATH`.

## The terminal look

Two independent knobs in `kitty.conf`:

- `background_tint` (0→1) — blends the terminal background *over* the image. Higher is
  more readable. Default `0.92`.
- `background_opacity` (1→0) — makes the window translucent so the desktop shows
  through. Commented out.

| Key | Effect |
|---|---|
| `ctrl+alt+=` / `ctrl+alt+-` | image back / forward |
| `ctrl+alt+0` | reset tint |
| `ctrl+shift+f5` | reload kitty config |
| `ctrl+shift+f11` | fullscreen |

Wallpapers are **not tracked** — download your own per machine. `kitty-bg --add <file>`
converts one to WebP, stores it in `~/.config/kitty/wallpapers/`, and records it in
`local.conf`. `kitty-bg` alone lists what is available; `kitty-bg <name>` switches.

The image is only visible if nvim and tmux stay transparent — both are configured here.

## Inline images in Neovim

`snacks.image` needs the **kitty graphics protocol**: kitty, WezTerm or Ghostty only.
Not Windows Terminal, konsole or alacritty. Check with `:checkhealth snacks`.

It also needs **no tmux**. snacks identifies the terminal with an `XTVERSION` query that
goes unanswered through tmux, so kitty is never detected, unicode placeholders are ruled
out, and the hover-float fallback draws the image at the terminal origin instead of in
the float. `ui.lua` therefore sets `doc.enabled = vim.env.TMUX == nil` — images render in
bare kitty and are off inside tmux. Read markdown with `mdview` there instead.
