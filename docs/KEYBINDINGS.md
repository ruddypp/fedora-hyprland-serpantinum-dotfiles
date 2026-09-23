# Keybindings

`Super` is the Windows/Meta key. Bindings live in [`config/hypr/config/keybinds.lua`](../config/hypr/config/keybinds.lua).

## Apps

| Keys | Action |
| --- | --- |
| `Super+Enter` | Terminal (Ghostty, set in `variables.lua`) |
| `Super+D` | App launcher |
| `Super+F` | Browser (`browser` in `variables.lua`, Firefox by default) |
| `Super+E` | File manager (Nautilus) |

## Windows

| Keys | Action |
| --- | --- |
| `Super+Q` | Close window |
| `Super+Shift+F` | Toggle floating |
| `Super+Z` | Maximize (bar and gaps stay visible) |
| `Super+Shift+Z` | True fullscreen |
| `Super+J` | Toggle split direction (side-by-side ⇄ stacked) |
| `Super+P` | Pseudo-tile (keep the window's own size inside its slot) |
| `Super+Ctrl+C` | Center a floating window |
| `Super+←/→/↑/↓` | Move focus |
| `Super+Ctrl+←/→/↑/↓` | Swap window in that direction |
| `Super+Shift+←/→/↑/↓` | Resize (repeats while held) |
| `Super+Left mouse drag` | Move window |
| `Super+Right mouse drag` | Resize window |
| `Super+T` | Toggle window transparency |

## Workspaces

| Keys | Action |
| --- | --- |
| `Super+1…9, 0` | Go to workspace 1–10 |
| `Super+Shift+1…9, 0` | Move the focused window to workspace 1–10 |
| 3-finger horizontal swipe | Previous/next workspace (one by one, empty ones included) |
| `Super+Tab` | Overview: drag a window onto another workspace to move it, click a window to focus it, click a workspace to go there, `Esc` to close. The last `+` card creates a new workspace. |

Workspaces never have gaps: `scripts/workspace-compact.py` renumbers occupied workspaces to 1, 2, 3… as windows open, close or move. To turn it off, remove its line from `config/autostart.lua`.

The bar shows 3 workspaces and grows when you go past them (`bar.workspaceCount` in `settings.json`).

## Serpantinum panels

| Keys | Panel |
| --- | --- |
| `Super+H` | Guide + settings |
| `Super+B` | System panel |
| `Super+N` | Network / Wi-Fi |
| `Super+V` | Volume |
| `Super+M` | Music player |
| `Super+S` | Calendar |
| `Super+C` | Clipboard history |
| `Super+W` | Wallpaper picker |
| `Super+A` | Toggle bar autohide |
| `Super+R` | Reload Serpantinum |
| `Super+L` | Lock screen |

## Screenshots

Saved to `~/Pictures/Screenshots`.

| Keys | Action |
| --- | --- |
| `Print` | Select an area, save |
| `Shift+Print` | Select an area, open in satty to annotate |
| `Super+Print` | Full screen |
| `Super+Shift+Print` | Full screen, open in satty |

On many laptops Print is `Fn+PrtSc`.

## Media and hardware keys

| Keys | Action |
| --- | --- |
| `Super+Space`, Play/Pause key | Play/pause |
| Prev/Next keys | Previous/next track |
| Volume keys, Mute, Mic mute | Volume (with on-screen display) |
| Brightness keys | Screen brightness |
| Power key | Lock screen |
