# Removing GNOME (optional)

GNOME idles at roughly 650 MB of RAM (`gnome-shell` alone ~350 MB on the test laptop). If Hyprland is all you use, you can remove it. **There is no fallback afterwards**, so do it in this order:

1. Install and log in through SDDM at least once: `./scripts/install-sddm.sh`, then log out and back in.
2. Dry run:

   ```bash
   ./scripts/remove-gnome-kde.sh
   ```

   It lists what would be removed and runs `rpm -e --test` on it. If anything you still have depends on those packages, it stops and tells you which ones. Nothing is removed in a dry run.
3. For real:

   ```bash
   ./scripts/remove-gnome-kde.sh --yes
   ```

The script refuses to run unless SDDM is your display manager. Removing GNOME removes GDM too, and without a replacement you'd boot to a black screen.

## What gets removed

- **GNOME** ([`scripts/lists/gnome-remove.txt`](../scripts/lists/gnome-remove.txt)): gnome-shell, mutter, GDM, gnome-session, gnome-settings-daemon, Settings, Software, Tour, Tweaks, Extensions, all GNOME Shell extensions, the GNOME apps (Calculator, Calendar, Clocks, Contacts, Maps, Weather, Boxes, Text Editor, Loupe, Papers, Snapshot, Showtime, Decibels, Disks, System Monitor, Logs, Characters, Fonts, Connections, Simple Scan, Baobab, Yelp, Orca, Epiphany runtime), abrt's GUI, and xdg-desktop-portal-gnome.
- **KDE leftovers** ([`scripts/lists/kde-remove.txt`](../scripts/lists/kde-remove.txt)): qt5ct, qt6ct and the kf5/kf6 libraries that only they need, plus Breeze. Serpantinum's upstream dependency list includes qt5ct/qt6ct, but nothing in the shell uses them.
- **Unused dependencies**: dnf removes anything that nothing else needs anymore. On the test machine that was ~200 extra packages, ~913 MB in total, including QEMU/libvirt (pulled in by GNOME Boxes), accountsservice, switcheroo-control, iio-sensor-proxy, bolt, and bluez-obexd. dnf shows the full list and asks before removing anything.

## What must stay (and why)

The script marks these as user-installed so autoremove leaves them alone ([`scripts/lists/keep.txt`](../scripts/lists/keep.txt)):

| Package | Why |
| --- | --- |
| `nautilus`, `gvfs`, `gvfs-client`, `gvfs-mtp`, `gvfs-smb` | File manager (`Super+E`, dock), trash, USB drives, phones |
| `gnome-keyring`, `gnome-keyring-pam` | Stores browser/VS Code/Git credentials. Remove it and saved logins break |
| `xdg-desktop-portal-gtk`, `xdg-desktop-portal-hyprland` | File pickers and screen sharing |
| `adwaita-mono-fonts`, `adw-gtk3-theme` | Fonts and GTK theme used by this setup |
| `sddm`, `sddm-wayland-generic`, `f43-backgrounds-base` | Login screen (sddm pulls in one KDE library, `kf6-kimageformats`, which stays) |

Kept automatically because other things need them: `gnome-autoar`, `gnome-desktop3/4`, `nautilus-extensions`, `localsearch`, `tinysparql`, `totem-pl-parser` (Nautilus), `malcontent-libs` (**Flatpak**), `evolution-data-server`, `gnome-online-accounts-libs`, `evince-libs`.

## Your system is different?

The lists were verified on a Fedora 43 Workstation install. If the dry run reports a conflict, move the package it names from `gnome-remove.txt` (or `kde-remove.txt`) into your own keep list and run it again. Don't force it.

## Clean up your home directory (optional)

These are just leftover settings; remove what you like:

```bash
rm -rf ~/.local/share/gnome-shell        # extensions
rm -f  ~/.config/kdeglobals ~/.config/kwinrc ~/.config/plasma*   # old Plasma settings, if any
```
