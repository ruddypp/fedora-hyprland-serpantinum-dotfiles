# Troubleshooting

Useful logs:

```bash
# Quickshell / Serpantinum (newest log)
ls -t /run/user/$UID/quickshell/by-id/*/log.qslog | head -1
# Hyprland
ls -t $XDG_RUNTIME_DIR/hypr/*/hyprland.log | head -1
# SDDM greeter
journalctl -b | grep -i sddm-greeter
```

Start Serpantinum by hand to see errors immediately:

```bash
serpantinumd start      # should print "Configuration Loaded"
```

## Blank screen after login (no bar, no wallpaper)

Hyprland is running but Quickshell exits right away. Run `serpantinumd start` in a terminal (`Super+Enter` still works). The classic error on Fedora 43:

```
ERROR: caused by @reusables/PasswordInput.qml[807:46]: Unexpected token `reserved word'
```

Qt 6.10 treats `char` as a reserved word, so `required property string char` fails to parse. PasswordInput is used by the lock screen, the lock screen is loaded by Shell.qml, and so the whole shell dies. Patch `0001` fixes it. If you updated Serpantinum yourself, re-run `./install.sh --skip-packages`. If the error points to a new file, look for another `property ... char` and rename it the same way.

## "Missing dependencies" when taking a screenshot

The screenshot script checks for `grim satty wl-copy pactl quickshell zbarimg python3`. satty lives in `~/.local/bin` (built with cargo), and a session started by GDM/SDDM on Fedora only gets `PATH=/usr/local/bin:/usr/bin`. `config/hypr/config/env.lua` prepends `~/.local/bin`. If you replaced that file, add back:

```lua
hl.env("PATH", os.getenv("HOME") .. "/.local/bin:" .. (os.getenv("PATH") or "/usr/local/bin:/usr/bin"))
```

Then log out and back in.

## satty: `GLIBC_2.43 not found`

You installed satty's GitHub release binary. Fedora 43 ships glibc 2.42. Build it instead:

```bash
rm -f ~/.local/bin/satty
cargo install --locked --root ~/.local satty
```

## Dock/launcher still show default icons

Quickshell ignores the GTK icon setting. It reads `QS_ICON_THEME` (set in `env.lua`). That variable is only picked up when Serpantinum is started **by Hyprland**, so log out and back in. To restart just Serpantinum from inside the session:

```bash
hyprctl reload
hyprctl eval 'hl.exec_cmd("sh -c \"serpantinumd stop; sleep 1; serpantinumd start\"")'
```

Check it took effect: `tr '\0' '\n' < /proc/$(pgrep -f "quickshell -p" | head -1)/environ | grep QS_ICON`.

## The UI is huge after changing scale

Someone (you) set the monitor scale to 2 or 3 in the Display tab. Open a terminal with `Super+Enter`, even if you can barely see it, and run:

```bash
hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.0 })'
```

Replace `eDP-1` with your output from `hyprctl monitors`. `hyprctl keyword monitor ...` does not work with the Lua config.

## The bar shows 10 workspaces

The bar grows up to the workspace you're on. You probably pressed `Super+0` (workspace 10) or an app opened on a high-numbered workspace. Move windows back with `Super+Shift+1/2/3`.

## Windows don't tile

They do, but every window is on its own workspace, so each one fills the screen. Put two on the same workspace (`Super+Shift+<n>`).

## "Your system does not have hyprland-guiutils installed"

```bash
sudo dnf install hyprland-guiutils
```

(Already in `packages/fedora.txt`. This happens if you skipped packages.)

## Login screen looks broken or plain (SDDM fallback theme)

SDDM falls back to its built-in theme when the configured one fails to load. Check:

```bash
journalctl -b | grep -i 'sddm-greeter.*qml'
```

- `Unexpected token 'reserved word'`: same Qt 6.10 `char` problem, in whatever theme you're using
- `module "Qt5Compat.GraphicalEffects" is not installed`: `sudo dnf install qt6-qt5compat`

Test a theme without logging out: `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/pixie`.

## Locked out: no login screen at all

Press `Ctrl+Alt+F3`, log in on the text console, then:

```bash
journalctl -b -u sddm | tail -30
# back to GDM (only if GNOME is still installed):
sudo systemctl disable sddm && sudo systemctl enable --force gdm && sudo reboot
```

## Saved passwords in Chrome/VS Code are gone after switching to SDDM

gnome-keyring isn't being unlocked at login. `scripts/install-sddm.sh` adds `pam_gnome_keyring` to `/etc/pam.d/sddm`; check it's there:

```bash
grep gnome_keyring /etc/pam.d/sddm
```

## A patch does not apply after changing the Serpantinum commit

Upstream changed the lines the patch touches. Apply the rest by hand, or update the patch:

```bash
cd ~/.cache/serpantinum-src
git checkout <new-commit>
git apply --reject /path/to/dotfiles/patches/serpantinum/000X-*.patch   # leaves *.rej files
# fix the rejected hunks, then regenerate:
git diff -- src/quickshell/<file> > /path/to/dotfiles/patches/serpantinum/000X-*.patch
```

## Don't use `pkill -f` from inside the session's terminals

`serpantinumd stop` and `pkill -f <pattern>` can match the shell that runs them. Use `serpantinumd stop` from a normal terminal, or restart through `hyprctl eval 'hl.exec_cmd(...)'` as shown above.
