# Wallpapers

**Images in this directory are not tracked by git** — only this README is. They are large
binaries, and wallpapers downloaded from aggregators generally carry no redistribution
rights. Each machine gets its own.

The active image is set in `~/.config/kitty/local.conf` (also untracked), which
`kitty.conf` includes last:

```text
background_image wallpapers/foo.webp
```

Relative paths resolve against kitty's config directory, so that finds
`~/.config/kitty/wallpapers/foo.webp`.

## Adding one

```bash
kitty-bg --add ~/Pictures/foo.jpg     # full resolution
kitty-bg --add-small ~/Pictures/f.jpg # caps at 2560x1440
```

Converts to WebP, drops any alpha channel, stores it here, and writes the setting to
`local.conf`. `--add` refuses to overwrite an existing name.

## Switching

```bash
kitty-bg                 # list what is available, show current
kitty-bg foo             # switch by name
kitty-bg Coast           # a KDE system wallpaper set, if installed
kitty-bg none            # no background image
```

Then `ctrl+shift+f5`. Readability is `background_tint` in `kitty.conf` —
`ctrl+alt+-` / `ctrl+alt+=` adjust it live.
