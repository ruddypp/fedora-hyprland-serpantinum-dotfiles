#!/usr/bin/env bash
# Super+T: toggle window transparency for every app window.
# Values while "on" must match decoration in config/settings.lua.
ON_ACTIVE=0.92
ON_INACTIVE=0.85
# Blur: true = on, false = off. For a subtle blur set this to true and lower
# blur.size / blur.passes in settings.lua (e.g. 3 / 1).
ON_BLUR=false
STATE="${XDG_RUNTIME_DIR:-/tmp}/hypr-transparency-off"

if [ -f "$STATE" ]; then
    rm -f "$STATE"
    hyprctl eval "hl.config({ decoration = { active_opacity = $ON_ACTIVE, inactive_opacity = $ON_INACTIVE, blur = { enabled = $ON_BLUR } } })" >/dev/null
    notify-send -a "Hyprland" -t 1500 "Transparency: on"
else
    touch "$STATE"
    hyprctl eval "hl.config({ decoration = { active_opacity = 1.0, inactive_opacity = 1.0, blur = { enabled = false } } })" >/dev/null
    notify-send -a "Hyprland" -t 1500 "Transparency: off"
fi
