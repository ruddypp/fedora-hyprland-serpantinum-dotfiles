-- Derived from Serpantinum (https://github.com/ilyamiro/serpantinum), AGPL-3.0.
-- Modified by fedora-hyprland-serpantinum-dotfiles.
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- A session started by the display manager on Fedora only gets /usr/local/bin:/usr/bin.
-- satty and wl-gammarelay-rs are built with cargo into ~/.local/bin, so add it here.
hl.env("PATH", os.getenv("HOME") .. "/.local/bin:" .. (os.getenv("PATH") or "/usr/local/bin:/usr/bin"))

-- Icon theme for the Serpantinum dock and launcher (Quickshell does not read the GTK setting)
hl.env("QS_ICON_THEME", "WhiteSur-dark")

-- Folder for per-workspace wallpapers (patch 0002): workspace N uses the Nth image
hl.env("SERPANTINUM_WORKSPACE_WALLPAPERS", os.getenv("HOME") .. "/Pictures/Wallpapers/workspaces")
