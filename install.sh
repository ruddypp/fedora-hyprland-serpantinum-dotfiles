#!/usr/bin/env bash
# fedora-hyprland-serpantinum-dotfiles installer
# Hyprland + Quickshell + Serpantinum on Fedora 43, without the Arch-only upstream installer.
#
# Usage: ./install.sh [--skip-packages] [--skip-icons] [--with-sddm] [--help]
set -euo pipefail

SERPANTINUM_REPO="https://github.com/ilyamiro/serpantinum.git"
SERPANTINUM_COMMIT="14f5e45765f01a8ee30aabcbfc00680349b65946"   # v2.1.9, the commit the patches are tested against

DOTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/serpantinum-src"
TARGET="$HOME/.local/share/serpantinum"
STAMP="$(date +%Y%m%d_%H%M%S)"

SKIP_PACKAGES=false
SKIP_ICONS=false
WITH_SDDM=false

info() { printf '\e[36m==>\e[0m %s\n' "$*"; }
warn() { printf '\e[33m!!\e[0m %s\n' "$*"; }
die()  { printf '\e[31mxx\e[0m %s\n' "$*" >&2; exit 1; }

usage() {
    sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'
    cat <<'EOF'

Options:
  --skip-packages  Do not enable COPRs or install dnf packages
  --skip-icons     Do not install the WhiteSur icon theme
  --with-sddm      Also install SDDM + the serpantinum-obsidian login theme (runs scripts/install-sddm.sh)
  --help           Show this help
EOF
}

for arg in "$@"; do
    case "$arg" in
        --skip-packages) SKIP_PACKAGES=true ;;
        --skip-icons)    SKIP_ICONS=true ;;
        --with-sddm)     WITH_SDDM=true ;;
        -h|--help)       usage; exit 0 ;;
        *) die "Unknown option: $arg (see --help)" ;;
    esac
done

# ---------- checks ----------
[ "$EUID" -ne 0 ] || die "Run as your normal user, not root. sudo is used where needed."
. /etc/os-release
[ "${ID:-}" = "fedora" ] || die "This installer targets Fedora (found: ${ID:-unknown})."
[ "${VERSION_ID:-0}" -ge 43 ] || warn "Tested on Fedora 43; you have Fedora ${VERSION_ID}. Continuing anyway."

# Copy a config dir, backing up whatever is there first
backup_and_copy() {
    local src="$1" dest="$2"
    if [ -e "$dest" ]; then
        mv "$dest" "$dest.bak-$STAMP"
        warn "Existing $dest moved to $dest.bak-$STAMP"
    fi
    mkdir -p "$(dirname "$dest")"
    cp -r "$src" "$dest"
}

# ---------- 1. packages ----------
if [ "$SKIP_PACKAGES" = false ]; then
    info "Enabling COPRs (Hyprland, Quickshell)"
    sudo dnf copr enable -y lionheartp/Hyprland
    sudo dnf copr enable -y errornointernet/quickshell

    info "Installing packages from packages/fedora.txt"
    mapfile -t PKGS < <(grep -vE '^\s*(#|$)' "$DOTS/packages/fedora.txt")
    sudo dnf install -y "${PKGS[@]}"
fi

# ---------- 2. satty + wl-gammarelay-rs ----------
# satty's release binary needs glibc 2.43 (Fedora 43 ships 2.42), wl-gammarelay-rs has no package.
for tool in satty wl-gammarelay-rs; do
    if command -v "$tool" >/dev/null 2>&1; then
        info "$tool already installed"
    else
        info "Building $tool with cargo into ~/.local/bin (takes a few minutes)"
        cargo install --locked --root "$HOME/.local" "$tool"
    fi
done

# ---------- 3. Serpantinum: pinned upstream + patches ----------
info "Fetching Serpantinum at ${SERPANTINUM_COMMIT:0:7}"
if [ ! -d "$SRC_CACHE/.git" ]; then
    git clone "$SERPANTINUM_REPO" "$SRC_CACHE"
fi
git -C "$SRC_CACHE" fetch --quiet origin
git -C "$SRC_CACHE" checkout --quiet --force "$SERPANTINUM_COMMIT"
git -C "$SRC_CACHE" reset --quiet --hard "$SERPANTINUM_COMMIT"

info "Applying patches"
for p in "$DOTS"/patches/serpantinum/*.patch; do
    git -C "$SRC_CACHE" apply "$p"
    echo "   $(basename "$p")"
done

info "Deploying Serpantinum to $TARGET (same layout as the upstream installer)"
rm -rf "$TARGET"
mkdir -p "$TARGET" "$HOME/.local/bin"
cp -r "$SRC_CACHE/bin" "$SRC_CACHE/src" "$TARGET/"
chmod +x "$TARGET"/bin/*
find "$TARGET/src/scripts" -type f -name '*.sh' -exec chmod +x {} +
ln -sf "$TARGET/bin/serpantinum"  "$HOME/.local/bin/serpantinum"
ln -sf "$TARGET/bin/serpantinumd" "$HOME/.local/bin/serpantinumd"
# The display manager session does not always have ~/.local/bin in PATH
sudo ln -sf "$TARGET/bin/serpantinum"  /usr/local/bin/serpantinum
sudo ln -sf "$TARGET/bin/serpantinumd" /usr/local/bin/serpantinumd

# Version state, telemetry off
mkdir -p "$HOME/.local/state/serpantinum"
cat > "$HOME/.local/state/serpantinum/version" <<EOF
SERPANTINUM_VERSION="$(cat "$SRC_CACHE/version.txt" 2>/dev/null | xargs)"
SERPANTINUM_COMMIT="$SERPANTINUM_COMMIT"
TELEMETRY_ID=""
ENABLE_TELEMETRY="false"
SELECTED_COMPOSITORS="hyprland"
EOF

# ---------- 4. configs ----------
info "Installing configs (existing ones are backed up)"
backup_and_copy "$DOTS/config/hypr" "$HOME/.config/hypr"   # includes scripts/toggle-transparency.sh
chmod +x "$HOME/.config/hypr/scripts/"*.sh

backup_and_copy "$DOTS/config/ghostty" "$HOME/.config/ghostty"

# cava + fastfetch configs come from upstream Serpantinum
for cfg in cava fastfetch; do
    [ -d "$SRC_CACHE/config/$cfg" ] && backup_and_copy "$SRC_CACHE/config/$cfg" "$HOME/.config/$cfg"
done

if [ -e "$HOME/.config/serpantinum/settings.json" ]; then
    cp "$HOME/.config/serpantinum/settings.json" "$HOME/.config/serpantinum/settings.json.bak-$STAMP"
    warn "Existing settings.json backed up to settings.json.bak-$STAMP"
fi
mkdir -p "$HOME/.config/serpantinum"
sed "s|__HOME__|$HOME|g" "$DOTS/config/serpantinum/settings.json" > "$HOME/.config/serpantinum/settings.json"

mkdir -p "$HOME/Pictures/Wallpapers/workspaces" "$HOME/Pictures/Screenshots"

# ---------- 5. fonts ----------
FONT_DIR="$HOME/.local/share/fonts/IosevkaNerdFont"
if ! ls "$FONT_DIR"/*.ttf >/dev/null 2>&1; then
    info "Installing Iosevka Nerd Font"
    tmp="$(mktemp -d)"
    curl -fL --retry 3 -o "$tmp/Iosevka.zip" \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Iosevka.zip
    mkdir -p "$FONT_DIR"
    unzip -qo "$tmp/Iosevka.zip" -d "$tmp"
    mv "$tmp"/*.ttf "$FONT_DIR/"
    rm -f "$FONT_DIR"/*Mono*.ttf
    rm -rf "$tmp"
    fc-cache -f "$HOME/.local/share/fonts" >/dev/null
fi

# ---------- 6. icons + GTK ----------
if [ "$SKIP_ICONS" = false ] && [ ! -d "$HOME/.local/share/icons/WhiteSur-dark" ]; then
    info "Installing WhiteSur icon theme"
    tmp="$(mktemp -d)"
    git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git "$tmp/whitesur"
    (cd "$tmp/whitesur" && ./install.sh)
    rm -rf "$tmp"
fi

info "GTK: adw-gtk3-dark + dark color scheme"
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark' 2>/dev/null || true

# ---------- 7. services ----------
info "Enabling services"
systemctl --user enable --now pipewire wireplumber pipewire-pulse 2>/dev/null || true
sudo systemctl enable --now NetworkManager power-profiles-daemon bluetooth 2>/dev/null || true

# ---------- 8. SDDM (optional) ----------
if [ "$WITH_SDDM" = true ]; then
    bash "$DOTS/scripts/install-sddm.sh"
fi

cat <<EOF

$(printf '\e[32mDone.\e[0m')

Next steps:
  1. Put your wallpapers in ~/Pictures/Wallpapers/workspaces (1st image = workspace 1, ...).
  2. Log out and pick the "Hyprland" session (not "uwsm") on the login screen.
  3. Press Super+H for the Serpantinum guide. Full keybindings: docs/KEYBINDINGS.md

Want the matching login screen? ./scripts/install-sddm.sh
EOF
