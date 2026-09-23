-- Part of fedora-hyprland-serpantinum-dotfiles.
-- Predictable dwindle tiling: new windows always open to the right/bottom,
-- splits stay put when resizing, and dialogs/popups are not tiled.
hl.config({
  dwindle = {
    preserve_split = true,   -- keep split direction after closing/resizing
    force_split = 2,         -- new window always right/bottom (not based on cursor position)
    smart_resizing = true,
    split_width_multiplier = 1.2, -- wide screens: prefer side-by-side splits
  },
  binds = {
    movefocus_cycles_fullscreen = false,
  },
  gestures = {
    workspace_swipe_use_r = true, -- 3-finger swipe goes 1-2-3-4-5, does not skip empty workspaces
  },
})

-- Apps (Chrome etc.) request maximize on their own and break tiling. Ignore it.
hl.window_rule({
  name = "suppress-maximize-events",
  match = { class = ".*" },
  suppress_event = "maximize",
})

-- Empty XWayland windows (drag handles/tooltips) must not steal focus
hl.window_rule({
  name = "fix-xwayland-drags",
  match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
  no_focus = true,
})

-- Dialogs & small utilities: float centered instead of tiling
hl.window_rule({
  name = "float-dialogs",
  match = { title = "^(Open File|Open Folder|Save File|Save As|Select a File|Choose Files|File Upload|Open|Save|Rename.*|Properties|.* Properties|Confirm.*|Authentication Required)$" },
  float = true,
  center = true,
})

hl.window_rule({
  name = "float-portal-picker",
  match = { class = "^(xdg-desktop-portal-gtk|xdg-desktop-portal-gnome|org.freedesktop.impl.portal.desktop.*)$" },
  float = true,
  center = true,
})

hl.window_rule({
  name = "float-utilities",
  match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|nm-connection-editor|blueman-manager|.blueman-manager-wrapped|hyprland-share-picker|hyprland-dialog|hyprland-donate-screen|polkit-gnome-authentication-agent-1|org.gnome.Calculator|satty)$" },
  float = true,
  center = true,
})

-- Chrome/Firefox Picture-in-Picture: floating and pinned to all workspaces
hl.window_rule({
  name = "pip",
  match = { title = "^(Picture.in.[Pp]icture)$" },
  float = true,
  pin = true,
  keep_aspect_ratio = true,
})
