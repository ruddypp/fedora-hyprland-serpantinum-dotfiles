# Customization

After editing a Hyprland file run `hyprctl reload`. After editing Serpantinum settings press `Super+R`, or just save: Serpantinum watches `settings.json`.

> This setup uses Hyprland's **Lua** config. `hyprctl keyword ...` does not work with it; change things at runtime with `hyprctl eval '<lua>'`.

## Per-workspace wallpapers

Patch `0002` gives every workspace its own wallpaper, like Spaces on macOS. Switching is instant: no transition, and no black flash, because the next image is loaded on a hidden layer and swapped once it's ready.

- Folder: `~/Pictures/Wallpapers/workspaces` (set in [`config/hypr/config/env.lua`](../config/hypr/config/env.lua) as `SERPANTINUM_WORKSPACE_WALLPAPERS`)
- Order: natural sort (`ls -v`). Name files `1.jpg`, `2.jpg`, ... or `ws-01.png`, `ws-02.png`, ...
- Workspace N uses image N. With fewer images than workspaces they wrap around.
- Formats: png, jpg/jpeg, webp
- After adding or renaming images: `Super+R`

Picking a wallpaper with `Super+W` still works, but only until you switch workspaces.

Want a different folder? Change the env line, then log out and back in (environment variables are read when Serpantinum starts):

```lua
hl.env("SERPANTINUM_WORKSPACE_WALLPAPERS", os.getenv("HOME") .. "/Pictures/anime")
```

## Avatar

Serpantinum → `Super+H` → General → Profile picture. It shows a center square crop of the image.

The login screen keeps its own copy. Re-run `./scripts/install-sddm.sh` after changing the avatar (it reads the same setting), or pass `--avatar path/to/image`.

## Transparency

Values are in [`config/hypr/config/settings.lua`](../config/hypr/config/settings.lua):

```lua
decoration = {
  active_opacity = 0.92,
  inactive_opacity = 0.85,
  blur = { enabled = false, size = 8, passes = 2 },
}
```

`Super+T` switches between those values and fully opaque. If you change the numbers, change `ON_ACTIVE` / `ON_INACTIVE` in `~/.config/hypr/scripts/toggle-transparency.sh` too.

Want blur? A subtle one keeps text readable over busy wallpapers:

```lua
blur = { enabled = true, size = 3, passes = 1, new_optimizations = true },
```

and set `ON_BLUR=true` in the toggle script.

Apps with their own transparency stack with Hyprland's. That's why the Ghostty config here has no `background-opacity`.

## Browser and terminal

[`config/hypr/config/variables.lua`](../config/hypr/config/variables.lua):

```lua
terminal = "ghostty"
browser = "firefox"   -- "google-chrome-stable", "brave-browser", ...
```

Terminal apps started from the launcher/dock use `launcher.terminalCommand` in `settings.json` (`"ghostty -e"`).

## Icons

Dock and launcher icons come from `QS_ICON_THEME` in `env.lua`, **not** from the GTK setting. Quickshell is a Qt app and ignores `gsettings`.

```lua
hl.env("QS_ICON_THEME", "WhiteSur-dark")   -- any theme in ~/.local/share/icons or /usr/share/icons
```

Log out/in after changing it. GTK apps use `gsettings set org.gnome.desktop.interface icon-theme <name>`.

## Colors and theme

Serpantinum → `Super+H` → Theme. This config ships the **Obsidian** preset (pure black/white/gray) with **matugen off**, so the UI does not recolor itself from the wallpaper. That keeps per-workspace wallpaper switching cheap. Turning matugen on works, but then every workspace switch recolors the whole UI.

## Dock

Apps, size and autohide are in Serpantinum → `Super+H` → Dock, or `dock` in `settings.json`.

The icon tile color comes from patch `0003` (`Qt.alpha(ThemeBackend.surface0, 0.35)` in `dock/Dock.qml`). Change the `0.35` in the patch before installing: `0.2` is lighter, `0.5` is stronger, `"transparent"` removes the tile.

## Bar workspaces

`bar.workspaceCount` in `settings.json` (2–10). The bar grows automatically when you move past that number.

## Monitors and scaling

[`config/hypr/config/monitors.lua`](../config/hypr/config/monitors.lua) uses the preferred mode at scale 1. For a 1080p laptop that feels small, try `1.25`:

```lua
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.25 })
```

Careful with the Display tab in Serpantinum's guide. A scale of 2–3 on a 1080p screen makes the UI too big to use; see [TROUBLESHOOTING.md](TROUBLESHOOTING.md#the-ui-is-huge-after-changing-scale).

## Login screen

Theme files: [`sddm/serpantinum-obsidian/Main.qml`](../sddm/serpantinum-obsidian/Main.qml). The palette is at the top (`cText`, `cSub0`, ...), and the vertical position of the centered block is `anchors.verticalCenterOffset` (default `90 * s`, pushes it below the middle so a character's face stays visible). Re-run `./scripts/install-sddm.sh` after editing.
