# Application migration inventory

Local inventory of the Fedora 43 Hyprland machine, 2026-11-14. This is a
work in progress, not a promise that the installer reproduces every program.
Package names and local launchers were inspected without fetching remote sources
or testing a clean-machine installation.

## In the installer

- Fedora desktop applications: Firefox, Text Editor, Celluloid, Loupe, Kitty,
  Ptyxis, dconf Editor and Syncthing, in addition to the desktop dependencies.
- Development: Git, GitHub CLI, Neovim, PHP, Composer, MariaDB and PostgreSQL
  packages, phpMyAdmin, Python, CMake, Clang, Podman, Toolbox and
  Android tools. The complete package list is in `scripts/install-apps.sh` and
  `packages/fedora.txt`.
- Chrome, VS Code, Spotify, Discord, Mission Center, Extension Manager,
  Obsidian, Orca, WordCraft, GridCraft, PdfCraft, DeckCraft and Claude Code.
- graphify is installed by `scripts/install-brain.sh`.
- Docker Engine, Tailscale, nvm, Node 24.12.0, Codex, Railway CLI, 9router,
  Firecrawl CLI, neonctl, OpenCode, Turbo and the observed global npm libraries
  are installed by `scripts/install-extra-apps.sh`. Docker and Tailscale services
  are enabled. Tailscale requires sign-in; Docker commands require sudo unless
  the user configures access separately.

## Still to migrate

- RPMs from other sources: RPM Fusion FFmpeg and EnvyControl.
  Their repository setup and installation have not been verified for a clean
  machine. NVIDIA drivers are hardware-specific.
- User-installed tools: Grok CLI, `agy`, fzf, pyprland, pywal16, skillspector,
  Maestro AppImage and user-installed Python utilities. Their exact sources,
  dependencies and portable install procedures still need investigation.
- Local projects and custom launchers: db-toggle, Winboat and
  create-monorepo. These require separate source and dependency checks; do not
  copy a local launcher containing a machine-specific path and call it installed.
- MetaTrader 5 has a desktop launcher pointing to a missing `~/.local/bin/mt5`;
  the current launcher alone does not establish a working installation.

Accounts, credentials, databases, personal files and application licenses are
not part of this inventory. Some software may need account sign-in or a license
on the target machine even after its installer is added.

## Excluded by request

Screaming Frog SEO Spider, Go, .NET SDK, AnyDesk and ninecop are not included.
