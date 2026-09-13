# mdview — browsable markdown for a whole repo

Serves a directory of markdown as GitHub-styled HTML, with **links between files that
actually resolve**. That is the one thing Neovim's markdown tooling cannot do:
`markdown-preview.nvim` (`<space>cp`) renders a single file, and clicking a relative
`.md` link inside it does not navigate. `mdview` gives you the VS Code preview
experience — index, working links, real browser back/forward — for any repo.

Not a replacement for in-editor rendering. Keep using `render-markdown.nvim` while
writing and `marksman`'s `gd`/`gr` to jump between files; reach for `mdview` when you
want to *read* a set of linked notes.

Distinct from the `md` shell function, which pandoc-converts one file and opens it.

---

## Setup on a new machine

### 1. Node.js

```bash
sudo dnf install -y nodejs npm            # Fedora
sudo apt install -y nodejs npm            # Debian / Ubuntu / WSL
```

Verified on Node 20. Anything currently supported works.

### 2. Point npm's global prefix at `$HOME`

**Do this before installing markserv**, or `npm -g` writes to `/usr/local` and needs
`sudo` for every install:

```bash
npm config set prefix ~/.npm-global
```

This writes `prefix=~/.npm-global` to `~/.npmrc`. That file is **not tracked here** —
npm also stores registry auth tokens in it, and a symlink into a git repo is the wrong
place for those. One command per machine instead.

`.bashrc` already does `path_prepend "$HOME/.npm-global/bin"`, so nothing else to wire
up. Open a new shell afterwards.

### 3. markserv

```bash
npm install -g markserv
```

### 4. Link the dotfiles package

```bash
cd ~/dotfiles && ./install.sh bin
```

Installs two files:

| Repo path | Links to | Role |
|---|---|---|
| `bin/.local/bin/mdview` | `~/.local/bin/mdview` | the script |
| `bin/.local/lib/mdview/preload.js` | `~/.local/lib/mdview/preload.js` | patches markserv at startup |
| `bin/.local/lib/mdview/dark.css` | `~/.local/lib/mdview/dark.css` | dark theme, injected by the preload |

The script finds the preload relative to its own resolved path, so the symlink layout
works unchanged — and it runs fine if the preload is missing, just light-themed with
`asm` blocks unhighlighted.

### 5. Check

```bash
mdview -h
cd ~/dotfiles && mdview
```

**Always start it with `mdview`, not `markserv`.** Both patches below ride in on
`NODE_OPTIONS`, which `mdview` sets; a bare `markserv .` serves the same files with no
dark theme and no `asm` highlighting.

---

## Usage

```text
mdview              serve the current git repo (found from any subdirectory)
mdview path/to/dir  serve that directory
mdview -c           serve $PWD, not the repo root
mdview -d           force the dark theme (default: follow the browser)
mdview -n           don't open a browser
mdview -l           list running servers
mdview -k           stop all servers
mdview -h           help
```

`Ctrl+C` stops the server in the foreground; the pidfile is cleaned by a trap. Each run
takes the first free port from **8642** upward, so several repos can run side by side —
`mdview -l` shows which is which. Livereload uses port + 1000.

Servers bind to **localhost only**. markserv has no authentication; do not expose it.

---

## WSL

Works, with two things to know.

**Opening the browser.** There is no `xdg-open` that reaches Windows. Install `wslu`:

```bash
sudo apt install -y wslu
```

`mdview` tries `$BROWSER`, then `wslview`, then `explorer.exe`, then `xdg-open` — the
same precedence as `open_file()` in `.bashrc`. Without `wslu` it falls back to
`explorer.exe`, which takes the URL directly (no `wslpath` needed, unlike a file path).
If all four are missing it prints the URL for you to paste.

**Reaching the server from Windows.** WSL2 forwards `localhost` to the Windows host by
default, so `http://localhost:8642` opens in a Windows browser unchanged. If it does
not, `localhostForwarding` has been disabled — either re-enable it in `.wslconfig`:

```ini
[wsl2]
localhostForwarding=true
```

or use the VM's address instead: `hostname -I | awk '{print $1}'`.

Serving a repo stored on `/mnt/c` works but is slow — the 9p filesystem makes markserv's
file watching crawl. Keep repos in the Linux filesystem.

---

## Dark theme

markserv ships a GitHub-light stylesheet and no way to change it — no flag, no config
file, no environment variable, and `templates/markdown.html` is loaded from markserv's
own `__dirname`.

`dark.css` is injected instead (see below). By default it is wrapped in
`@media (prefers-color-scheme: dark)`, so pages follow the browser. The palette is
VS Code Dark+ — the same values as `lua/plugins/markdown.lua`, so a file looks the same
in the browser as in Neovim.

Following the browser is unreliable on Linux: Firefox tracks the GTK theme, which a KDE
dark setup often does not change, and Chrome ignores the desktop entirely without
`--force-dark-mode`. So the wrapper can be dropped:

| Mode | How |
|---|---|
| Follow the browser (default) | `mdview` |
| Always dark | `mdview -d`, or `MDVIEW_THEME=dark` |
| Never inject | `MDVIEW_THEME=light` |

One override is load-bearing: markserv sets `outline: 1300px solid #fff` on `body` above
768px wide, which paints white around the whole content column. `dark.css` repoints that
outline at the page background.

Edit `~/.local/lib/mdview/dark.css` to retune. No restart needed for the CSS itself —
markserv re-reads the template per request — but the file list is read once at startup.

## Syntax highlighting: the `asm` alias

markserv bundles highlight.js, which has `x86asm`, `armasm`, `avrasm` and `mipsasm` but
**no plain `asm`**. Fences written as ```` ```asm ```` — which is what GitHub and nvim's
treesitter both accept — produce:

```text
Could not find the language 'asm', did you forget to load/include a language module?
```

and render unhighlighted.

Renaming the fences to `x86asm` would fix markserv and break the other two renderers, so
`preload.js` registers `asm`, `assembly` and `nasm` as aliases of `x86asm` instead. Add
more in that file's `aliases` map. `text`, `plaintext` and `txt` are all valid already —
use one of them for content with no lexer (tmux config, ssh config, terminal output).

## How the preload works

Both patches ride in on `NODE_OPTIONS=--require`, which runs `preload.js` before markserv
builds anything:

- **aliases** — resolve markserv's *own* copy of highlight.js and call
  `registerAliases`. It has to be that copy, or the alias lands on a different module
  instance. `process.argv[1]` arrives as the `~/.npm-global/bin/markserv` symlink and
  that directory has no `node_modules`, so it is `realpath`'d first.
- **dark theme** — wrap `fs.readFile`, and when markserv reads one of its
  `templates/*.html`, append `<style>dark.css</style>` before `</head>`.

Patching `node_modules` directly would be simpler and would not survive
`npm install -g markserv`. Failures in either patch are swallowed — a page with wrong
colours beats no page — so debug with:

```bash
MDVIEW_DEBUG=1 NODE_OPTIONS="--require ~/.local/lib/mdview/preload.js" \
  markserv --port 8700 --browser=false .
```

## Troubleshooting

| Symptom | Cause |
|---|---|
| Every link 404s, error page shows a path from elsewhere | markserv resolves requests against the **process cwd**, not its path argument. `mdview` `cd`s into the target first; calling `markserv <dir>` by hand from another directory does not. |
| No auto-refresh on save | The livereload server runs, but markserv injects no client script into the page. It expects the LiveReload browser extension. Without it, press F5. |
| `mdview: markserv not found` | Step 2 or 3 skipped, or the shell predates the `PATH` change. Check `npm config get prefix` and open a new shell. |
| Code block unhighlighted, console names a language | highlight.js has no such language. Add an alias in `hljs-aliases.js` if a close one exists. |
| Two DEP0128 deprecation warnings on start | markserv's own dependencies. Silenced with `NODE_OPTIONS=--no-deprecation`. |
| No dark theme **and** the `asm` error is back | The server was started as `markserv` rather than `mdview`, so it never got `NODE_OPTIONS`. Check with `mdview -l` — a server it did not start is not listed. |
| Page stays light under `mdview` | The browser reports a light `prefers-color-scheme`. Use `mdview -d`. |
| Changed the theme but the page did not | A server started earlier is still running on that port. `mdview -k`, then start again. |
| `markserv -b false` silently kills livereload | markserv's `--help` is wrong: `-b` is the alias for `--livereloadport`, not `--browser`, and `-l` is not an alias at all. Use the long forms — `mdview` does. |
