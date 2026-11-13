#!/usr/bin/env bash
# Additional tools on the source workstation. Run as a normal user.
set -eo pipefail

[ "$EUID" -ne 0 ] || { echo 'Run as a normal user, not root.' >&2; exit 1; }
. /etc/os-release
[ "${ID:-}" = fedora ] || { echo 'Fedora is required.' >&2; exit 1; }

echo 'Installing Docker Engine and Tailscale from their official repositories'
sudo dnf install -y dnf5-plugins
if [ ! -f /etc/yum.repos.d/docker-ce.repo ]; then
    sudo dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo
fi
if [ ! -f /etc/yum.repos.d/tailscale.repo ]; then
    sudo tee /etc/yum.repos.d/tailscale.repo >/dev/null <<'EOF'
[tailscale-stable]
name=Tailscale stable
baseurl=https://pkgs.tailscale.com/stable/fedora/$basearch
enabled=1
type=rpm
repo_gpgcheck=1
gpgcheck=1
gpgkey=https://pkgs.tailscale.com/stable/fedora/repo.gpg
EOF
fi
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin tailscale
sudo systemctl enable --now docker tailscaled

echo 'Installing nvm, Node.js and global command-line tools'
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    [ ! -e "$NVM_DIR" ] || { echo "$NVM_DIR exists but is not an nvm install; resolve it first." >&2; exit 1; }
    git clone --depth 1 --branch v0.40.7 https://github.com/nvm-sh/nvm.git "$NVM_DIR"
fi
# nvm is not compatible with nounset in all supported releases.
set +u
. "$NVM_DIR/nvm.sh"
nvm install 24.12.0
nvm alias default 24.12.0
nvm use 24.12.0
npm install -g @openai/codex@0.159.3 @railway/cli@5.62.1 9router@0.5.75 \
    firecrawl-cli@1.19.21 neonctl@2.20.1 opencode-ai@1.18.32 turbo@2.11.2 \
    better-sqlite3@13.0.3 harmonyos-sans@1.0.0 systray2@2.1.4

if ! grep -q 'nvm.sh' "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" <<'EOF'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
EOF
fi
echo 'Extra apps installed. Tailscale needs sign-in; Docker commands need sudo unless access is configured.'
