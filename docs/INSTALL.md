# Installation

## Requirements

- **Fedora 43** (Workstation or any spin), x86_64, a normal user with `sudo`
- A Wayland-capable GPU. Intel/AMD work out of the box. NVIDIA works with the proprietary driver (tested with 580 on an MX330 hybrid laptop)
- ~2 GB of downloads (packages, Rust toolchain for building satty, fonts, icons)
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
```

This installs SDDM with the Weston greeter (`sddm-wayland-generic`, no KDE needed), builds the `serpantinum-obsidian` theme with your background and avatar, makes sure gnome-keyring unlocks at login, and switches the display manager from GDM to SDDM. GDM is only disabled, not removed.

Preview it before logging out:

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/serpantinum-obsidian
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
sudo rm -rf /usr/share/sddm/themes/serpantinum-obsidian /etc/sddm.conf.d/10-serpantinum.conf
```

Packages can be removed with `sudo dnf remove hyprland quickshell ...` (see `packages/fedora.txt`).
