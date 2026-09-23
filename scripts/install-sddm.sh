#!/usr/bin/env bash
# Install SDDM + a login theme and make SDDM the display manager.
# The greeter runs on Weston (sddm-wayland-generic), so no KDE/KWin is needed.
#
# Usage: ./scripts/install-sddm.sh [--theme pixie|serpantinum-obsidian] [--background IMAGE] [--avatar IMAGE]
#   --theme       pixie (default, Pixel-style lock screen by xCaptaiN09) or serpantinum-obsidian
#   --background  Login background (default: first image in ~/Pictures/Wallpapers/workspaces)
#   --avatar      Round avatar (default: Serpantinum's general.avatarPath, then ~/.face)
#
# GDM is only disabled, not removed. To go back: Ctrl+Alt+F3, log in, then
#   sudo systemctl disable sddm && sudo systemctl enable --force gdm && sudo reboot
set -euo pipefail

DOTS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEME="pixie"
BG=""
AVATAR=""

while [ $# -gt 0 ]; do
    case "$1" in
        --theme)      THEME="$2"; shift 2 ;;
        --background) BG="$2"; shift 2 ;;
        --avatar)     AVATAR="$2"; shift 2 ;;
        -h|--help)    sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

case "$THEME" in
    pixie|serpantinum-obsidian) ;;
    *) echo "Unknown theme: $THEME (use pixie or serpantinum-obsidian)" >&2; exit 1 ;;
esac
THEME_SRC="$DOTS/sddm/$THEME"
THEME_DEST="/usr/share/sddm/themes/$THEME"

[ "$EUID" -ne 0 ] || { echo "Run as your normal user; sudo is used where needed." >&2; exit 1; }

if [ -z "$BG" ]; then
    BG="$(ls -1v "$HOME/Pictures/Wallpapers/workspaces"/*.{jpg,jpeg,png,webp} 2>/dev/null | head -n 1 || true)"
fi
if [ -z "$AVATAR" ]; then
    AVATAR="$(jq -r '.general.avatarPath // empty' "$HOME/.config/serpantinum/settings.json" 2>/dev/null || true)"
    [ -n "$AVATAR" ] && [ -f "$AVATAR" ] || AVATAR=""
    [ -z "$AVATAR" ] && [ -f "$HOME/.face" ] && AVATAR="$HOME/.face"
fi

echo "==> Installing SDDM (Weston greeter)"
sudo dnf install -y sddm sddm-wayland-generic adwaita-mono-fonts ImageMagick

echo "==> Building the theme"
tmp="$(mktemp -d)"
cp -r "$THEME_SRC/." "$tmp/"
if [ "$THEME" = pixie ]; then
    BG_OUT="$tmp/assets/background.jpg"
    AVATAR_OUT="$tmp/assets/avatar.jpg"
else
    BG_OUT="$tmp/bg.jpg"
    AVATAR_OUT="$tmp/faces/$USER.png"
fi
if [ -n "$BG" ] && [ -f "$BG" ]; then
    magick "$BG" -resize '1920x1080^' -gravity center -extent 1920x1080 -quality 90 "$BG_OUT"
    echo "   background: $BG"
else
    echo "   no background image found, using the theme's default"
fi
if [ -n "$AVATAR" ] && [ -f "$AVATAR" ]; then
    mkdir -p "$(dirname "$AVATAR_OUT")"
    # Center square crop, same as Serpantinum shows it
    magick "$AVATAR" -gravity center -extent "%[fx:min(w,h)]x%[fx:min(w,h)]" -resize 512x512 "$AVATAR_OUT"
    echo "   avatar: $AVATAR"
else
    echo "   no avatar found, using the theme's default"
fi

sudo rm -rf "$THEME_DEST"
sudo mkdir -p "$THEME_DEST"
sudo cp -r "$tmp/." "$THEME_DEST/"
sudo chmod -R 755 "$THEME_DEST"
rm -rf "$tmp"

echo "==> /etc/sddm.conf.d/10-serpantinum.conf"
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/10-serpantinum.conf >/dev/null <<EOF
[Theme]
Current=$THEME
ThemeDir=/usr/share/sddm/themes

[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_DISABLE_WINDOWDECORATION=1
InputMethod=
EOF

echo "==> Unlock gnome-keyring at login (saved browser/VS Code passwords)"
if ! grep -q pam_gnome_keyring /etc/pam.d/sddm; then
    sudo cp -a /etc/pam.d/sddm /etc/pam.d/sddm.bak
    sudo sed -i '0,/^auth[[:space:]].*\(include\|substack\).*$/s//&\n-auth       optional     pam_gnome_keyring.so/' /etc/pam.d/sddm
    echo "-session    optional     pam_gnome_keyring.so auto_start" | sudo tee -a /etc/pam.d/sddm >/dev/null
    echo "   added (backup: /etc/pam.d/sddm.bak)"
else
    echo "   already configured"
fi

echo "==> Switching the display manager to SDDM"
current="$(readlink /etc/systemd/system/display-manager.service 2>/dev/null || true)"
if [ -n "$current" ] && [ "$(basename "$current")" != "sddm.service" ]; then
    sudo systemctl disable "$(basename "$current")" || true
fi
sudo systemctl enable --force sddm.service

cat <<EOF

Done. Preview without logging out (close it with Super+Q; sign-in does nothing in test mode):
  sddm-greeter-qt6 --test-mode --theme $THEME_DEST

Reboot or log out to use it.
EOF
