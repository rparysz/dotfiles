#!/usr/bin/env bash
# Symlink dotfiles into $HOME. No dependencies beyond coreutils — works on
# machines where you cannot install packages.
#
#   ./install.sh                link every package
#   ./install.sh nvim kitty     link only those
#   ./install.sh -n             dry run, show what would happen
#   ./install.sh -D [pkgs...]   unlink (removes only symlinks into this repo)
#
# Existing real files are moved to ~/.dotfiles-backup-<timestamp>/ before
# being replaced. Symlinks already pointing at this repo are left alone.
set -euo pipefail
REPO="$(cd "$(dirname "$(realpath "$0")")" && pwd)"
cd "$REPO"

ALL=(bash git tmux nvim kitty alacritty bin markdownlint)
DRY=0; UNLINK=0
while [ $# -gt 0 ]; do
  case "$1" in
    -n) DRY=1; shift ;;
    -D) UNLINK=1; shift ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) break ;;
  esac
done
PKGS=("$@"); [ ${#PKGS[@]} -eq 0 ] && PKGS=("${ALL[@]}")

BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
say() { [ "$DRY" = 1 ] && echo "  [dry] $*" || echo "  $*"; }
run() { [ "$DRY" = 1 ] || "$@"; }

linked=0; backed=0; skipped=0; removed=0

for pkg in "${PKGS[@]}"; do
  [ -d "$pkg" ] || { echo ":: skip '$pkg' (no such package)"; continue; }
  echo ":: $pkg"
  while IFS= read -r src; do
    rel="${src#"$pkg"/}"
    dst="$HOME/$rel"
    abs="$REPO/$src"

    if [ "$UNLINK" = 1 ]; then
      if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$abs" ]; then
        say "unlink $rel"; run rm -f "$dst"; removed=$((removed+1))
      fi
      continue
    fi

    # already correct?
    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$abs" ]; then
      skipped=$((skipped+1)); continue
    fi
    # back up anything real that is in the way
    if [ -e "$dst" ] || [ -L "$dst" ]; then
      say "backup $rel"
      run mkdir -p "$BACKUP/$(dirname "$rel")"
      run mv "$dst" "$BACKUP/$rel"
      backed=$((backed+1))
    fi
    say "link   $rel"
    run mkdir -p "$(dirname "$dst")"
    run ln -s "$abs" "$dst"
    linked=$((linked+1))
  done < <(find "$pkg" -type f -printf '%p\n')
done

# ── Seed machine-local files ──────────────────────────────────────────
# These hold anything that differs per machine and are never tracked.
if [ "$UNLINK" = 0 ]; then
  seed() {  # $1 = template, $2 = destination
    [ -e "$2" ] && return 0
    say "seed   ${2/#$HOME/\~}"
    run mkdir -p "$(dirname "$2")"
    run cp "$REPO/templates/$1" "$2"
  }
  seed bashrc.local     "$HOME/.bashrc.local"
  seed gitconfig.local  "$HOME/.gitconfig.local"
  seed kitty-local.conf "$HOME/.config/kitty/local.conf"
fi

echo
if [ "$UNLINK" = 1 ]; then
  echo "  removed $removed symlink(s)."
else
  echo "  linked $linked, already correct $skipped, backed up $backed"
  [ "$backed" -gt 0 ] && echo "  originals saved in: $BACKUP"
fi
[ "$DRY" = 1 ] && echo "  (dry run — nothing changed)"
exit 0
