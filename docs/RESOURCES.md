# Resources & credits

This repo is glue: config, patches and scripts. The real work belongs to these projects. Their licenses apply to their code; this repo only downloads/installs them.

## Core

| Project | What it does here | License |
| --- | --- | --- |
| [Serpantinum](https://github.com/ilyamiro/serpantinum) by ilyamiro | The whole shell: bar, dock, launcher, notifications, lock screen, settings. The Hyprland config here is derived from its `compositors/hyprland` | AGPL-3.0 |
| [Hyprland](https://github.com/hyprwm/Hyprland) | Wayland compositor / tiling window manager | BSD-3-Clause |
| [Quickshell](https://quickshell.org) ([source](https://git.outfoxxed.me/quickshell/quickshell), [mirror](https://github.com/quickshell-mirror/quickshell)) | QML toolkit Serpantinum is built on | LGPL-3.0 |
| [Ghostty](https://github.com/ghostty-org/ghostty) | Terminal | MIT |

## Fedora packaging

| Source | Used for |
| --- | --- |
| COPR [`lionheartp/Hyprland`](https://copr.fedorainfracloud.org/coprs/lionheartp/Hyprland/) | Hyprland, hyprland-guiutils, xdg-desktop-portal-hyprland, cliphist, matugen, gpu-screen-recorder, … (recommended in the [Hyprland wiki](https://wiki.hypr.land/Getting-Started/Installation/)) |
| COPR [`errornointernet/quickshell`](https://copr.fedorainfracloud.org/coprs/errornointernet/quickshell/) | Quickshell (from the [Quickshell install guide](https://quickshell.org/docs/v0.3.0/guide/install-setup/)) |
| [SDDM](https://github.com/sddm/sddm) + Fedora's `sddm-wayland-generic` | Login screen on a Weston greeter, no KDE required |

## Tools built from source by the installer

| Project | Why | License |
| --- | --- | --- |
| [Satty](https://github.com/Satty-org/Satty) | Screenshot annotation (`Shift+Print`). The release binary needs glibc 2.43 | MPL-2.0 |
| [wl-gammarelay-rs](https://github.com/MaxVerevkin/wl-gammarelay-rs) | Blue-light filter in Serpantinum | GPL-3.0 |

## Look & feel

| Project | Used for | License |
| --- | --- | --- |
| [WhiteSur icon theme](https://github.com/vinceliuice/WhiteSur-icon-theme) by vinceliuice | Dock/launcher/app icons (`WhiteSur-dark`) | GPL-3.0 |
| [adw-gtk3](https://github.com/lassekongo83/adw-gtk3) | GTK3 apps matching libadwaita | LGPL-2.1 |
| [Iosevka](https://github.com/be5invis/Iosevka) via [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) | Serpantinum's icon/UI font | OFL-1.1 (font) |
| [Adwaita Mono](https://gitlab.gnome.org/GNOME/adwaita-fonts) | Font of the Obsidian preset and the login screen | OFL-1.1 |
| [matugen](https://github.com/InioX/matugen) | Material You colors from wallpaper (installed, off in the Obsidian preset) | GPL-2.0 |
| [cliphist](https://github.com/sentriz/cliphist) | Clipboard history (`Super+C`) | GPL-3.0 |
| [Serpantinum wallpapers](https://github.com/ilyamiro/shell-wallpapers) | Optional wallpaper pack from upstream (not installed by default) | none stated |
| [Material-You SDDM theme](https://github.com/ilyamiro/serpantinum/tree/master/config/sddm/themes/material-you) by Darkkal44 | Serpantinum's original login theme; `serpantinum-obsidian` is a separate rewrite inspired by it | MIT |

Wallpapers and the avatar in the screenshots are fan art of Rimuru Tempest (*That Time I Got Reincarnated as a Slime*) and belong to their respective artists. They are not included in this repo.

## Docs that helped

- Quickshell: [Installation & setup](https://quickshell.org/docs/v0.3.0/guide/install-setup/), [Introduction](https://quickshell.org/docs/v0.3.0/guide/introduction/)
- Hyprland wiki: [Installation](https://wiki.hypr.land/Getting-Started/Installation/)
- SDDM: [theme API](https://github.com/sddm/sddm/wiki/Theming)
- Fedora: [DNF protected packages](https://dnf5.readthedocs.io/en/latest/dnf5.conf.5.html) (why `gnome-shell` can't be removed until you unprotect it)

## License of this repo

[AGPL-3.0](../LICENSE). The patches and Hyprland config are derivative works of Serpantinum (AGPL-3.0), so the repo uses the same license. The SDDM theme `serpantinum-obsidian`, the scripts and the docs are also released under AGPL-3.0.
