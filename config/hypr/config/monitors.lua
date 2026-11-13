-- Derived from Serpantinum (https://github.com/ilyamiro/serpantinum), AGPL-3.0.
-- Modified by fedora-hyprland-serpantinum-dotfiles.
hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = 1.0,
})

-- Example: mirror the laptop panel 1:1 on an HDMI TV/monitor. Many TVs report
-- 1360x768 as their preferred mode, which looks blurry, so force 1080p.
-- Find output names with `hyprctl monitors all`.
-- hl.monitor({
--   output = "HDMI-A-1",
--   mode = "1920x1080@60",
--   position = "auto",
--   scale = 1.0,
--   mirror = "eDP-1",
-- })
