# Setup — fresh machine

Reproduces this environment from nothing. Adapted from an earlier Fedora/Konsole/Gruvbox
guide; everything below is what is **actually running**, not what that guide proposed.
Notable divergences from it: the colorscheme is `vscode`, not gruvbox; the terminal is
kitty, not Konsole; starship, zoxide, bat, eza and picocom are not installed.

---

## 1. Packages

### Fedora

```bash
sudo dnf install -y \
  neovim tmux git ripgrep fd-find fzf lazygit btop \
  kitty pandoc ImageMagick nodejs npm
```

### Debian / Ubuntu / WSL

```bash
sudo apt update && sudo apt install -y \
  neovim tmux git ripgrep fd-find fzf lazygit btop \
  pandoc imagemagick nodejs npm wslu
```

On WSL, skip `kitty` — see [docs/wezterm-wsl-setup.md](docs/wezterm-wsl-setup.md).
`wslu` is WSL-only; drop it on a Linux desktop.

| Package | Used by |
|---|---|
| `ripgrep`, `fd-find`, `fzf` | LazyVim's pickers (`<space><space>`, `<space>sg`) |
| `pandoc` | the `md` shell function |
| `ImageMagick` | `kitty-bg` (measures images to pick the largest in a set) |
| `lazygit`, `btop` | standalone TUIs |
| `nodejs`, `npm` | `mdview` — see [docs/mdview.md](docs/mdview.md) |
| `wslu` | `wslview`, so `mdview` and `md` can open a Windows browser from WSL |

## 2. Nerd Font

Required — without it every icon in LazyVim renders as a box.

```bash
mkdir -p ~/.local/share/fonts
curl -fLo /tmp/JetBrainsMono.zip \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -o /tmp/JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMono
fc-cache -fv
```

Verify the family name matches what `kitty.conf` and `alacritty.toml` reference:

```bash
fc-list : family | tr ',' '\n' | grep -i 'JetBrainsMono Nerd Font' | sort -u
```

## 3. Dotfiles

```bash
git clone git@github.com:erespebrn/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh -n      # preview
./install.sh         # link
```

Symlinks everything into `$HOME`, backs up anything real it displaces, and seeds three
machine-local files from `templates/`:

| File | Holds |
|---|---|
| `~/.bashrc.local` | toolchain paths, per-machine env |
| `~/.gitconfig.local` | git identity (work vs. personal email) |
| `~/.config/kitty/local.conf` | font size, alternate wallpaper |

None are tracked. Fill them in after installing.

## 4. Neovim

LazyVim bootstraps itself — plugins install on first launch.

```bash
nvim     # wait for lazy.nvim, then :q and reopen
```

`lazy-lock.json` is committed, so plugin versions match across machines. `:Lazy update`
to move forward, then commit the lockfile.

After the first launch finishes installing, run **`:Lazy restore`** interactively once.
Verified on a clean bootstrap: 43 of 47 plugins land on the pinned commit, but a few
pulled in as dependencies of other plugins (SchemaStore.nvim, friendly-snippets,
gitsigns.nvim, mason-lspconfig.nvim) install at branch HEAD instead, and a headless
`nvim --headless "+Lazy! restore"` does not correct them.

**Enabled LazyVim extras** (`lazyvim.json`, these are already in the repo):

- `lang.clangd` — C/C++ LSP
- `lang.cmake`
- `lang.json`
- `lang.markdown` — render-markdown.nvim, marksman, markdownlint-cli2

Mason installs the language servers on first run; check with `:Mason`.

**Local plugin overrides** in `lua/plugins/`:

| File | Purpose |
|---|---|
| `colorscheme.lua` | several themes kept installed; `vscode` active, `transparent = true` |
| `markdown.lua` | render-markdown disabled — markdown is edited raw; `conceallevel=0`, `gf` on relative links |
| `ui.lua` | snacks: scroll animation off, image module on (markdown images; off inside tmux) |
| `lint.lua` | passes `--config ~/.markdownlint-cli2.yaml` explicitly |
| `lsp.lua`, `tmux-navigator.lua`, `example.lua` | LSP tweaks, pane navigation, LazyVim's sample |

Verify inline images:

```vim
:checkhealth snacks
```

Must report the terminal supports the kitty graphics protocol. Only kitty, WezTerm and
Ghostty do — not Windows Terminal, konsole or alacritty. Inside tmux they do not render
either, whatever the terminal; `ui.lua` disables them there. See
[docs/mdview.md](docs/mdview.md) for reading markdown in the browser instead.

## 5. tmux

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
tmux            # then press: prefix + I   (capital i) to fetch plugins
```

Prefix is **`Ctrl-a`**. Config also defines a *prefixless* key table (toggle with
`M-o`) for pane movement without chording.

## 6. Terminal

kitty reads `~/.config/kitty/kitty.conf` from the repo. The background image is
referenced by **relative path** (`wallpapers/mountain.png`), which kitty resolves
against its own config dir — so it works on any machine with no editing.

For the image to be visible, three layers must all be transparent. All are configured
here, but if you apply this by hand:

- **kitty** draws the image
- **nvim** — colorscheme needs `transparent = true`, else it paints over everything
- **tmux** — needs `window-style`, `window-active-style` and `status-style` at `bg=default`

## 7. Markdown in the browser

`mdview` serves a whole repo as browsable HTML — unlike nvim's preview, links between
files resolve. Needs `nodejs`/`npm` from step 1, then:

```bash
npm config set prefix ~/.npm-global    # before installing, avoids sudo
npm install -g markserv
```

`~/.npmrc` is not tracked (it also holds registry tokens), so run that first line on
every machine. Full notes, including WSL: [docs/mdview.md](docs/mdview.md).

---

## Key reference

### LazyVim (leader = space)

| Action | Keys |
|---|---|
| File tree | `<space>e` |
| Find files | `<space><space>` or `<space>ff` |
| Live grep | `<space>sg` |
| Recent files | `<space>fr` |
| Definition / references | `gd` / `gr` |
| Hover docs | `K` |
| Rename symbol | `<space>cr` |
| Format | `<space>cf` |
| Diagnostics | `<space>xx` |
| Follow markdown link | `gf` (back: `Ctrl-o`) |
| Markdown browser preview | `<space>cp` |
| Floating terminal | `Ctrl-/` |

### tmux (prefix = `Ctrl-a`)

| Action | Keys |
|---|---|
| Split horizontal / vertical | `prefix \|` / `prefix -` |
| Even-split variants | `prefix %` / `prefix "` |
| Tile all panes | `prefix =` |
| Enter prefixless mode | `M-o` (again to leave) |
| Move pane (prefixless) | `M-i` / `M-j` / `M-k` / `M-l` — up/left/down/right |
| Split (prefixless) | `M-v` horizontal, `M-s` vertical |
| Detach / zoom | `prefix d` / `prefix z` |

### kitty

| Action | Keys |
|---|---|
| Fullscreen / maximise | `ctrl+shift+f11` / `ctrl+shift+f10` |
| Reload config | `ctrl+shift+f5` |
| Background image in / out | `ctrl+alt+-` / `ctrl+alt+=` |
| Reset tint | `ctrl+alt+0` |
| Font size | `ctrl+shift+=` / `ctrl+shift+-` |

### Helper scripts

| Command | Does |
|---|---|
| `kitty-bg` | list wallpapers and show the current one |
| `kitty-bg <name>` | switch (repo image, KDE set, or file path) |
| `kitty-bg --add <file>` | copy an image into the repo and use it |
| `kitty-tint +0.02` | adjust readability from the shell |
| `md <file.md>` | render one file with pandoc and open in browser |
| `mdview` | serve the current repo's markdown, links between files work |
| `mdview -l` / `-k` | list / stop running servers |

---

## Not installed

Proposed by the original guide, deliberately skipped: starship, zoxide, bat, eza,
picocom, the Gruvbox themes for tmux/btop/lazygit/Konsole, and the embedded tmux
launch script. Add them if the need shows up — starship is the strongest candidate,
since it would give an identical prompt on WSL where `git-prompt.sh` lives elsewhere.
