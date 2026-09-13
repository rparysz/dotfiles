# .bashrc — portable across Fedora and Debian/Ubuntu (including WSL).
# Machine-specific settings belong in ~/.bashrc.local (not tracked by git).

# ── Distro global definitions ─────────────────────────────────────────
# Fedora uses /etc/bashrc, Debian/Ubuntu /etc/bash.bashrc.
for _f in /etc/bashrc /etc/bash.bashrc; do
    [ -f "$_f" ] && . "$_f"
done
unset _f

# ── PATH helpers ──────────────────────────────────────────────────────
# Idempotent: safe to call from nested shells without the PATH growing.
# The old config prepended unguarded, which produced 51 entries with
# /usr/bin and ~/.npm-global/bin each repeated four times.
path_prepend() {
    [ -d "$1" ] || return 0
    case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH" ;; esac
}
path_append() {
    [ -d "$1" ] || return 0
    case ":$PATH:" in *":$1:"*) ;; *) PATH="$PATH:$1" ;; esac
}

# Remove duplicate entries, keeping the first occurrence of each.
path_dedupe() {
    local out= entry
    local IFS=:
    for entry in $PATH; do
        [ -z "$entry" ] && continue
        case ":$out:" in *":$entry:"*) continue ;; esac
        out="${out:+$out:}$entry"
    done
    PATH="$out"
}

# Move every entry starting with $1 to the end of PATH, preserving order.
# System-wide scripts in /etc/profile.d often prepend toolchain paths that
# shadow /usr/bin — this demotes them without editing files under /etc.
path_demote() {
    local keep= move= entry
    local IFS=:
    for entry in $PATH; do
        [ -z "$entry" ] && continue
        case "$entry" in
            "$1"*) move="${move:+$move:}$entry" ;;
            *)     keep="${keep:+$keep:}$entry" ;;
        esac
    done
    PATH="${keep}${move:+:$move}"
}

# Last prepend wins, so ~/.local/bin ends up first.
path_prepend "$HOME/.npm-global/bin"
path_prepend "$HOME/bin"
path_prepend "$HOME/.local/bin"
export PATH

# ── Drop-in fragments ─────────────────────────────────────────────────
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        [ -f "$rc" ] && . "$rc"
    done
    unset rc
fi

# ── Functions ─────────────────────────────────────────────────────────
# Render a markdown file to HTML and open it in the browser.
md() {
    local in="$1"
    [ -z "$in" ] && { echo "Usage: md <file.md>"; return 2; }
    [ ! -f "$in" ] && { echo "File not found: $in"; return 1; }

    local base out
    base="$(basename "$in")"
    out="${TMPDIR:-/tmp}/${base%.*}.html"

    command -v pandoc >/dev/null || { echo "pandoc is not installed"; return 1; }
    pandoc "$in" -o "$out" || return 1
    open_file "$out"
}

# Open a file in the desktop's default application.
# Under WSL there is no xdg-open that reaches Windows: wslview (from the
# wslu package) is the usual bridge, and explorer.exe works without it as
# long as the path is translated with wslpath.
open_file() {
    if command -v wslview >/dev/null 2>&1; then
        wslview "$1" >/dev/null 2>&1 &
    elif grep -qi microsoft /proc/version 2>/dev/null && command -v explorer.exe >/dev/null 2>&1; then
        explorer.exe "$(wslpath -w "$1")" >/dev/null 2>&1 &
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$1" >/dev/null 2>&1 &
    else
        echo "no opener found; file is at: $1"
    fi
}

# ── Prompt: user@host:cwd (branch) ────────────────────────────────────
# git-prompt.sh lives at a different path on every distro.
if [[ $- == *i* ]]; then
    for _gp in /usr/share/git-core/contrib/completion/git-prompt.sh \
               /usr/lib/git-core/git-sh-prompt \
               /etc/bash_completion.d/git-prompt \
               /usr/share/bash-completion/completions/git-prompt.sh; do
        if [ -f "$_gp" ]; then
            . "$_gp"
            GIT_PS1_SHOWCOLORHINTS=1
            PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}'__git_ps1 "\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]" " \\\$ "'
            break
        fi
    done
    unset _gp
    # Fallback if no git-prompt.sh exists — same colours, no branch.
    if [ -z "${PROMPT_COMMAND:-}" ] && ! declare -F __git_ps1 >/dev/null; then
        PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\] \$ '
    fi
fi

# ── Machine-specific ──────────────────────────────────────────────────
# Toolchain paths, work proxies, anything that differs per machine.
# Use path_append for toolchains that bundle their own cmake/ninja so the
# system versions keep priority.
[ -f ~/.bashrc.local ] && . ~/.bashrc.local

# ── Final PATH cleanup ────────────────────────────────────────────────
# Must run last: /etc/bashrc re-sources /etc/profile.d/*.sh on every
# non-login shell, so nested shells accumulate duplicates regardless of
# what this file does.
path_dedupe
export PATH
