#!/usr/bin/env bash
# OPTIONAL: remove GNOME (and leftover KDE libraries) so only Hyprland + Serpantinum remain.
# Dry run by default: it only checks what would happen. Pass --yes to actually remove.
#
# The lists in scripts/lists/ were verified on Fedora 43 Workstation with `rpm -e --test`
# so they do not break Nautilus, gnome-keyring, SDDM or Flatpak. Your system may differ,
# which is why the script re-checks and refuses to continue on any conflict.
#
# There is NO GNOME fallback afterwards. Make sure you can log in to Hyprland through SDDM
# first (./scripts/install-sddm.sh). Emergency access: Ctrl+Alt+F3 (text console).
set -euo pipefail

DOTS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
L="$DOTS/scripts/lists"
YES=false
[ "${1:-}" = "--yes" ] && YES=true

[ "$EUID" -ne 0 ] || { echo "Run as your normal user; sudo is used where needed." >&2; exit 1; }

dm="$(basename "$(readlink /etc/systemd/system/display-manager.service 2>/dev/null)" 2>/dev/null || true)"
if [ "$dm" != "sddm.service" ]; then
    echo "SDDM is not your display manager (found: ${dm:-none})."
    echo "Removing GNOME would also remove GDM and leave you without a login screen."
    echo "Run ./scripts/install-sddm.sh and log in through it first."
    exit 1
fi

# Only packages that are actually installed
mapfile -t WANT < <(cat "$L/gnome-remove.txt" "$L/kde-remove.txt" | grep -vE '^\s*(#|$)')
REMOVE=()
for p in "${WANT[@]}"; do rpm -q "$p" >/dev/null 2>&1 && REMOVE+=("$p"); done
[ ${#REMOVE[@]} -gt 0 ] || { echo "Nothing from the lists is installed. Done."; exit 0; }

echo "==> ${#REMOVE[@]} packages would be removed:"
printf '   %s\n' "${REMOVE[@]}" | column -c 100
echo

echo "==> Checking dependencies (rpm -e --test)"
if ! conflicts="$(rpm -e --test "${REMOVE[@]}" 2>&1)"; then
    echo "$conflicts" | sed 's/^/   /'
    echo
    echo "Something you still have installed needs these packages. Nothing was removed."
    echo "Move the needed package names out of scripts/lists/*-remove.txt and run again."
    exit 1
fi
echo "   no conflicts"

if [ "$YES" = false ]; then
    echo
    echo "Dry run only. Re-run with --yes to remove them."
    exit 0
fi

echo "==> Unprotecting gnome-shell (Fedora Workstation marks it as protected)"
P=/etc/dnf/protected.d/fedora-workstation.conf
if [ -f "$P" ]; then
    sudo cp -an "$P" "$P.bak"
    sudo sed -i '/^gnome-shell$/d' "$P"
fi

echo "==> Marking kept packages as user-installed so autoremove leaves them alone"
mapfile -t KEEP < <(grep -vE '^\s*(#|$)' "$L/keep.txt")
KEEP_INSTALLED=()
for p in "${KEEP[@]}"; do rpm -q "$p" >/dev/null 2>&1 && KEEP_INSTALLED+=("$p"); done
[ ${#KEEP_INSTALLED[@]} -gt 0 ] && sudo dnf mark user -y "${KEEP_INSTALLED[@]}" >/dev/null

echo "==> Removing"
# dnf also removes dependencies nothing else needs anymore (e.g. QEMU/libvirt from GNOME Boxes)
sudo dnf remove "${REMOVE[@]}"

echo
echo "Done. Log out and back in through SDDM."
