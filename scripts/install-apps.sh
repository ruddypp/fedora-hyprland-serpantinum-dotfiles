#!/usr/bin/env bash
# Install the apps pinned in the dock, so the desktop looks like the screenshots.
#
# Usage: ./scripts/install-apps.sh [--skip GROUP[,GROUP...]] [--help]
#   Groups: dnf, chrome, vscode, flatpak, appimage
#   Example: ./scripts/install-apps.sh --skip vscode,appimage
#
#   dnf       Firefox, GNOME Text Editor
#   chrome    Google Chrome (Google's official dnf repo)
#   vscode    Visual Studio Code (Microsoft's official dnf repo)
#   flatpak   Spotify, Discord, Mission Center (Flathub)
#   appimage  Obsidian, Orca, WordCraft, GridCraft, PdfCraft, DeckCraft
#             (latest GitHub release, checked against the SHA-256 GitHub publishes)
#
# Safe to run again: anything already installed is skipped. AppImages are only
# replaced when a newer release exists.
set -euo pipefail

# Edit these lists to change what gets installed.
DNF_APPS=(firefox gnome-text-editor)
FLATPAK_APPS=(com.spotify.Client com.discordapp.Discord io.missioncenter.MissionCenter)
# name | GitHub repo | asset regex | desktop id | extra env for Exec
APPIMAGES=(
    "obsidian|obsidianmd/obsidian-releases|^Obsidian-[0-9.]+\\.AppImage$|obsidian|"
    "orca|stablyai/orca|^orca-linux\\.AppImage$|orca|"
    "wordcraft|storytold/wordcraft|-linux-x86_64\\.AppImage$|ai.storyteller.wordcraft|WORDCRAFT_WAYLAND=1"
    "gridcraft|storytold/gridcraft|-linux-x86_64\\.AppImage$|ai.storyteller.gridcraft|"
    "pdfcraft|storytold/pdfcraft|-linux-x86_64\\.AppImage$|ai.storyteller.pdfcraft|"
    "deckcraft|storytold/deckcraft|-linux-x86_64\\.AppImage$|ai.storyteller.deckcraft|DECKCRAFT_WAYLAND=1"
)

SKIP=","
info() { printf '\e[36m==>\e[0m %s\n' "$*"; }
warn() { printf '\e[33m!!\e[0m %s\n' "$*"; }
die()  { printf '\e[31mxx\e[0m %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
    case "$1" in
        --skip)    SKIP=",${2:-},"; shift 2 ;;
        -h|--help) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) die "Unknown option: $1 (see --help)" ;;
    esac
done
want() { [[ "$SKIP" != *",$1,"* ]]; }

[ "$EUID" -ne 0 ] || die "Run as your normal user, not root. sudo is used where needed."
[ "$(uname -m)" = "x86_64" ] || warn "Only tested on x86_64; Chrome and some AppImages may not exist for $(uname -m)."

# ---------- dnf ----------
if want dnf; then
    info "dnf: ${DNF_APPS[*]}"
    sudo dnf install -y "${DNF_APPS[@]}"
fi

# ---------- Google Chrome ----------
if want chrome; then
    if rpm -q google-chrome-stable >/dev/null 2>&1; then
        info "Google Chrome already installed"
    else
        info "Google Chrome (dl.google.com repo)"
        sudo tee /etc/yum.repos.d/google-chrome.repo >/dev/null <<'EOF'
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
        sudo dnf install -y google-chrome-stable
    fi
fi

# ---------- VS Code ----------
if want vscode; then
    if rpm -q code >/dev/null 2>&1; then
        info "VS Code already installed"
    else
        info "VS Code (packages.microsoft.com repo)"
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
        sudo dnf install -y code
    fi
fi

# ---------- Flatpak ----------
if want flatpak; then
    command -v flatpak >/dev/null 2>&1 || sudo dnf install -y flatpak
    info "Flathub: ${FLATPAK_APPS[*]}"
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    sudo flatpak install -y --noninteractive flathub "${FLATPAK_APPS[@]}"
fi

# ---------- AppImages ----------
install_appimage() {
    local name="$1" repo="$2" pattern="$3" id="$4" env="$5"
    local bin="$HOME/.local/bin/$name.AppImage"
    local apps="$HOME/.local/share/applications"
    local icons="$HOME/.local/share/icons/hicolor"
    local release asset url digest version tmp

    release="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest")" \
        || { warn "$name: GitHub API unreachable or rate-limited, skipped"; return 0; }
    version="$(jq -r '.tag_name' <<<"$release")"
    asset="$(jq -c --arg re "$pattern" '[.assets[] | select(.name | test($re))][0]' <<<"$release")"
    [ "$asset" != "null" ] || { warn "$name: no matching AppImage in $repo $version, skipped"; return 0; }
    url="$(jq -r '.browser_download_url' <<<"$asset")"
    digest="$(jq -r '.digest // empty' <<<"$asset")"

    if [ -x "$bin" ] && grep -qx "X-AppImage-Version=$version" "$apps/$id.desktop" 2>/dev/null; then
        info "$name $version already installed"
        return 0
    fi

    info "$name $version"
    tmp="$(mktemp -d)"
    curl -fL --retry 3 -o "$tmp/app.AppImage" "$url"
    if [ -n "$digest" ]; then
        echo "${digest#sha256:}  $tmp/app.AppImage" | sha256sum -c --quiet - \
            || { rm -rf "$tmp"; die "$name: SHA-256 mismatch, download rejected"; }
    else
        warn "$name: GitHub published no checksum for this file, installed unverified"
    fi
    chmod +x "$tmp/app.AppImage"

    # Icons come from inside the AppImage
    (cd "$tmp" && ./app.AppImage --appimage-extract 'usr/share/icons/*' >/dev/null 2>&1 \
                && ./app.AppImage --appimage-extract '.DirIcon' >/dev/null 2>&1) || true
    if [ -d "$tmp/squashfs-root/usr/share/icons/hicolor" ]; then
        mkdir -p "$icons"
        cp -r "$tmp/squashfs-root/usr/share/icons/hicolor/." "$icons/"
    fi
    # The dock needs an absolute PNG path; make sure a 256px icon named after the desktop id exists
    if [ ! -f "$icons/256x256/apps/$id.png" ]; then
        local src
        src="$(find "$tmp/squashfs-root/usr/share/icons" -path '*256x256*' -name '*.png' 2>/dev/null | head -n 1)"
        [ -n "$src" ] || src="$(readlink -f "$tmp/squashfs-root/.DirIcon" 2>/dev/null || true)"
        if [ -n "$src" ] && [ -f "$src" ]; then
            mkdir -p "$icons/256x256/apps"
            cp "$src" "$icons/256x256/apps/$id.png"
        fi
    fi

    mkdir -p "$HOME/.local/bin" "$apps"
    mv "$tmp/app.AppImage" "$bin"
    rm -rf "$tmp"
    ln -sf "$bin" "$HOME/.local/bin/$name"

    local exec="$bin"
    [ -z "$env" ] || exec="env $env $bin"
    case "$name" in
        obsidian)  write_desktop "$id" "Obsidian" "Knowledge base / markdown notes" "$exec %U" "Office;" "x-scheme-handler/obsidian;" "obsidian" ;;
        orca)      write_desktop "$id" "Orca" "IDE for parallel agentic development" "$exec %U" "Development;" "x-scheme-handler/orca;" "orca" ;;
        wordcraft) write_desktop "$id" "WordCraft" "Write documents; open and save Word files" "$exec %F" "Office;WordProcessor;" \
                     "application/vnd.openxmlformats-officedocument.wordprocessingml.document;application/msword;application/vnd.oasis.opendocument.text;application/rtf;text/rtf;" "$id" ;;
        gridcraft) write_desktop "$id" "GridCraft" "Spreadsheets; open and save Excel files" "$exec %F" "Office;Spreadsheet;" \
                     "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;application/vnd.ms-excel;application/vnd.oasis.opendocument.spreadsheet;text/csv;text/tab-separated-values;" "$id" ;;
        pdfcraft)  write_desktop "$id" "PdfCraft" "Read and edit PDF files" "$exec %F" "Office;Viewer;" "application/pdf;" "$id" ;;
        deckcraft) write_desktop "$id" "DeckCraft" "Presentations; open and save PowerPoint files" "$exec %F" "Office;Presentation;" \
                     "application/vnd.openxmlformats-officedocument.presentationml.presentation;application/vnd.ms-powerpoint;application/vnd.oasis.opendocument.presentation;" "$id" ;;
    esac
    sed -i "\$aX-AppImage-Version=$version" "$apps/$id.desktop"
}

# Own .desktop files instead of the bundled ones: the bundled ones point at a
# mount path that changes every launch, and some claim text/markdown or text/plain.
write_desktop() {
    local id="$1" title="$2" comment="$3" exec="$4" cats="$5" mime="$6" wmclass="$7"
    local icon="$HOME/.local/share/icons/hicolor/256x256/apps/$id.png"
    [ -f "$icon" ] || icon="$id"
    cat > "$HOME/.local/share/applications/$id.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$title
Comment=$comment
Exec=$exec
Icon=$icon
Terminal=false
StartupNotify=true
StartupWMClass=$wmclass
Categories=$cats
MimeType=$mime
EOF
}

if want appimage; then
    command -v jq >/dev/null 2>&1 || sudo dnf install -y jq
    rpm -q fuse-libs >/dev/null 2>&1 || sudo dnf install -y fuse fuse-libs   # AppImages need FUSE 2
    for entry in "${APPIMAGES[@]}"; do
        IFS='|' read -r name repo pattern id env <<<"$entry"
        install_appimage "$name" "$repo" "$pattern" "$id" "$env"
    done
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    gtk-update-icon-cache -q "$HOME/.local/share/icons/hicolor" 2>/dev/null || true

    info "Default apps: Word/Excel/PowerPoint/PDF -> the Craft apps"
    xdg-mime default ai.storyteller.wordcraft.desktop application/vnd.openxmlformats-officedocument.wordprocessingml.document application/msword application/vnd.oasis.opendocument.text
    xdg-mime default ai.storyteller.gridcraft.desktop application/vnd.openxmlformats-officedocument.spreadsheetml.sheet application/vnd.ms-excel application/vnd.oasis.opendocument.spreadsheet text/csv
    xdg-mime default ai.storyteller.deckcraft.desktop application/vnd.openxmlformats-officedocument.presentationml.presentation application/vnd.ms-powerpoint application/vnd.oasis.opendocument.presentation
    xdg-mime default ai.storyteller.pdfcraft.desktop application/pdf
fi

info "Apps done. AppImages have no auto-update: run this script again to update them."
