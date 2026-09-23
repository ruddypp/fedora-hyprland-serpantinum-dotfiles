-- Derived from Serpantinum (https://github.com/ilyamiro/serpantinum), AGPL-3.0.
-- Modified by fedora-hyprland-serpantinum-dotfiles.
hl.on("hyprland.start", function()
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
  hl.exec_cmd("systemctl --user enable --now easyeffects")
  hl.exec_cmd("serpantinumd start")
  hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/workspace-compact.py")
  hl.exec_cmd("qs -c overview")
end)
