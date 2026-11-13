# Installation

## Requirements

- **Fedora 43** (Workstation or any spin), x86_64, a normal user with `sudo`
- A Wayland-capable GPU. Intel/AMD work out of the box. NVIDIA works with the proprietary driver (tested with 580 on an MX330 hybrid laptop)
- Several GB of downloads, including desktop packages, development tools, AppImages and the Rust toolchain
- Internet access for COPR, GitHub and crates.io

You do **not** need to remove GNOME. Hyprland shows up as an extra session on your login screen and GNOME stays as a fallback until you decide otherwise.

## 1. Clone

```bash
git clone https://github.com/ruddypp/fedora-hyprland-serpantinum-dotfiles.git
cd fedora-hyprland-serpantinum-dotfiles
```

## 2. Run the installer

```bash
./install.sh
```

Options:

| Flag | Effect |
| --- | --- |
| `--skip-packages` | Don't touch COPR/dnf (you installed the packages yourself) |
| `--skip-icons` | Don't install WhiteSur icons |
| `--no-brain` | Don't set up the notes/graphify/Obsidian brain (see below) |
| `--no-apps` | Don't install the dock apps (see below) |
| `--with-sddm` | Also run `scripts/install-sddm.sh` at the end |

What it does, in order:

1. **COPRs**: enables `lionheartp/Hyprland` (the one [the Hyprland wiki](https://wiki.hypr.land/Getting-Started/Installation/) points Fedora users to) and `errornointernet/quickshell` (from the [Quickshell docs](https://quickshell.org/docs/v0.3.0/guide/install-setup/)).
2. **Packages** from [`packages/fedora.txt`](../packages/fedora.txt). This is Serpantinum's Arch dependency list mapped to Fedora names (`fd` -> `fd-find`, `qt6-5compat` -> `qt6-qt5compat`, `pipewire-pulse` -> `pipewire-pulseaudio`, `imagemagick` -> `ImageMagick`, ...). Quickshell on Fedora is built against **Qt6**, so the Qt modules are the `qt6-*` ones.
3. **satty + wl-gammarelay-rs** built with `cargo install --root ~/.local`. satty is required: Serpantinum's screenshot script refuses to run without it.
4. **Serpantinum** cloned into `~/.cache/serpantinum-src`, checked out at the tested commit, patched with `patches/serpantinum/*.patch`, then deployed exactly like the upstream installer does:
   - `~/.local/share/serpantinum/{bin,src}`
   - `serpantinum` and `serpantinumd` symlinked into `~/.local/bin` and `/usr/local/bin`
   - `~/.local/state/serpantinum/version` with `ENABLE_TELEMETRY="false"`
5. **Configs**. Anything already there is moved to `<name>.bak-<timestamp>` first:
   - `~/.config/hypr` (+ `scripts/toggle-transparency.sh`)
   - `~/.config/serpantinum/settings.json` (existing file copied to `settings.json.bak-<timestamp>`)
   - `~/.config/ghostty`, and Serpantinum's own `~/.config/cava` and `~/.config/fastfetch`
6. **Iosevka Nerd Font** into `~/.local/share/fonts` (Serpantinum's icon font).
7. **WhiteSur icons** into `~/.local/share/icons`, GTK set to `adw-gtk3-dark` + dark color scheme.
8. **Services**: pipewire/wireplumber (user), NetworkManager, power-profiles-daemon, bluetooth.

It also creates `~/Pictures/Wallpapers/workspaces` (per-workspace wallpapers) and `~/Pictures/Screenshots`.

### Dock apps

`install.sh` ends by running `scripts/install-apps.sh`, so every app pinned in the dock is actually there after the first login:

| Group | Apps | Source |
| --- | --- | --- |
| `dnf` | Firefox, Text Editor, Celluloid, Loupe, Ptyxis, Syncthing, development tools and database packages | Fedora repos; full list in `scripts/install-apps.sh` |
| `chrome` | Google Chrome | Google's dnf repo |
| `vscode` | Visual Studio Code | Microsoft's dnf repo |
| `flatpak` | Spotify, Discord, Mission Center, Extension Manager | Flathub |
| `appimage` | Obsidian, Orca, WordCraft, GridCraft, PdfCraft, DeckCraft | Latest GitHub release into `~/.local/bin`, SHA-256 checked |
| `claude` | Claude Code (CLI, run `claude` in Ghostty) | Anthropic's native installer into `~/.local/bin`, updates itself |
| `extras` | Docker Engine, Tailscale, nvm, Node 24 and global development CLIs | Official Docker and Tailscale repositories, nvm and npm |

Skip what you don't want, or run it on its own later:

```bash
./scripts/install-apps.sh --skip vscode,appimage
# Skip Docker, Tailscale and the Node toolchain:
./scripts/install-apps.sh --skip extras
```

The AppImages are about 750 MB together (Orca alone is ~260 MB); skip `appimage` on a metered connection. AppImages don't update themselves; run the script again to pull newer releases. It also makes the Craft apps the default for Word, Excel, PowerPoint and PDF files. To change the list, edit the arrays at the top of the script and the `dock.apps` entries in `config/serpantinum/settings.json`.

The application migration is **not complete**: see [APPLICATION-INVENTORY.md](APPLICATION-INVENTORY.md) for the locally observed applications, exclusions and outstanding installers. Installing MariaDB or PostgreSQL packages does not initialize databases, migrate data, or start services. Docker and Tailscale services are enabled by the extras installer; Tailscale requires sign-in. Docker commands require sudo unless access is configured separately. Open a new terminal to use nvm and the Node tools.

### Second brain (notes + graphify + Obsidian)

`scripts/install-brain.sh` runs after the apps. It ships **no notes**, only the structure:

| Piece | Where |
| --- | --- |
| graphify CLI (`graphifyy`, via uv) | `~/.local/bin/graphify` |
| `/graphify` skill for Claude Code | `~/.claude/skills/graphify` |
| Rules: read the notes index first, keep code graphs out of repos | appended to `~/.claude/CLAUDE.md` |
| Hooks: remind Claude to query the graph before grepping/reading | `~/.claude/settings.json` (`PreToolUse`) |
| Notes folder with `00-INDEX.md`, `graph-repo/`, `_tools/sync_obsidian.py` | `~/Documents/catatan` (`--notes DIR`) |
| Obsidian vault (core plugins + graph view preset) | `~/Documents/catatan/<username>` (`--vault NAME`) |

Existing `~/.claude` files are backed up first and existing notes are never overwritten. Day to day:

```bash
mkdir ~/Documents/catatan/work            # one folder per topic, write .md notes in it
# in Claude Code:  /graphify ~/Documents/catatan/work
python3 ~/Documents/catatan/_tools/sync_obsidian.py   # notes + graph nodes into Obsidian
```

Then in Obsidian: "Open folder as vault" and pick `~/Documents/catatan/<username>`.

## 3. Add wallpapers

Put images in `~/Pictures/Wallpapers/workspaces`. They are sorted naturally (`ls -v`): the 1st image is workspace 1, the 2nd is workspace 2, and so on. With fewer images than workspaces they repeat. Details in [CUSTOMIZATION.md](CUSTOMIZATION.md#per-workspace-wallpapers).

## 4. Log in

Log out. On the login screen pick **Hyprland**. Pick the plain one, not "Hyprland (uwsm-managed)", because this config is tested with the plain session. Log in.

First steps:

- `Super+H`: Serpantinum's guide and settings
- `Super+D`: app launcher
- `Super+Enter`: terminal

All shortcuts: [KEYBINDINGS.md](KEYBINDINGS.md).

## 5. Optional: matching login screen

```bash
./scripts/install-sddm.sh
# or pick the images yourself:
./scripts/install-sddm.sh --background ~/Pictures/login.jpg --avatar ~/Pictures/me.png
./scripts/install-sddm.sh --theme serpantinum-obsidian   # the older card-less theme
```

This installs SDDM with the Weston greeter (`sddm-wayland-generic`, no KDE needed), builds the login theme (`pixie` by default) with your background and avatar, makes sure gnome-keyring unlocks at login, and switches the display manager from GDM to SDDM. GDM is only disabled, not removed.

Preview it before logging out:

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/pixie
```

(Test mode can't sign in; close it with `Super+Q`.)

## 6. Optional: remove GNOME

See [REMOVING-GNOME.md](REMOVING-GNOME.md). Do this only after you've logged in through SDDM at least once.

## Updating

Pull this repo and re-run the installer. It re-applies the patches to the pinned Serpantinum commit:

```bash
git pull
./install.sh --skip-packages
```

Want a newer Serpantinum than the pinned one? Change `SERPANTINUM_COMMIT` in `install.sh`. If a patch no longer applies, the installer stops at that patch; see [TROUBLESHOOTING.md](TROUBLESHOOTING.md#a-patch-does-not-apply-after-changing-the-serpantinum-commit).

Don't run Serpantinum's own `install.sh`. It only works on Arch.

## Uninstalling

```bash
serpantinumd stop
rm -rf ~/.local/share/serpantinum ~/.local/state/serpantinum ~/.cache/serpantinum-src
rm -f ~/.local/bin/serpantinum ~/.local/bin/serpantinumd
sudo rm -f /usr/local/bin/serpantinum /usr/local/bin/serpantinumd
# restore your old configs from the *.bak-<timestamp> copies in ~/.config
```

If you installed the login screen and want GDM back:

```bash
sudo systemctl disable sddm && sudo systemctl enable --force gdm
sudo rm -rf /usr/share/sddm/themes/pixie /usr/share/sddm/themes/serpantinum-obsidian /etc/sddm.conf.d/10-serpantinum.conf
```

Packages can be removed with `sudo dnf remove hyprland quickshell ...` (see `packages/fedora.txt`).
