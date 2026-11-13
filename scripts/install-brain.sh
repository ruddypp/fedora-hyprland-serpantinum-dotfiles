#!/usr/bin/env bash
# Set up an empty "second brain": notes folder + graphify knowledge graphs + Obsidian vault,
# wired into Claude Code. Nothing personal is copied: you start with an empty index.
#
# Usage: ./scripts/install-brain.sh [--notes DIR] [--vault NAME] [--no-claude] [--help]
#   --notes      Notes folder (default ~/Documents/catatan)
#   --vault      Obsidian vault folder name inside the notes folder (default: your username)
#   --no-claude  Do not touch ~/.claude (skill, CLAUDE.md, hooks)
#
# What it does:
#   1. Installs graphify (pip package "graphifyy") with uv into ~/.local/bin
#   2. Claude Code: graphify skill (/graphify), notes + graph rules in ~/.claude/CLAUDE.md,
#      and hooks that remind Claude to query the graph before grepping/reading raw files
#   3. Creates the notes folder: 00-INDEX.md, graph-repo/, _tools/sync_obsidian.py
#   4. Creates the Obsidian vault with the same core plugins and graph view settings
#
# Safe to run again: existing notes are never overwritten, ~/.claude files are backed up.
set -euo pipefail

DOTS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NOTES="$HOME/Documents/catatan"
VAULT_NAME="$(id -un)"
WITH_CLAUDE=true
STAMP="$(date +%Y%m%d_%H%M%S)"

info() { printf '\e[36m==>\e[0m %s\n' "$*"; }
warn() { printf '\e[33m!!\e[0m %s\n' "$*"; }
die()  { printf '\e[31mxx\e[0m %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
    case "$1" in
        --notes)     NOTES="${2%/}"; shift 2 ;;
        --vault)     VAULT_NAME="$2"; shift 2 ;;
        --no-claude) WITH_CLAUDE=false; shift ;;
        -h|--help)   sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) die "Unknown option: $1 (see --help)" ;;
    esac
done
[ "$EUID" -ne 0 ] || die "Run as your normal user, not root."
export PATH="$HOME/.local/bin:$PATH"

# ---------- 1. graphify ----------
if command -v graphify >/dev/null 2>&1; then
    info "graphify already installed ($(command -v graphify))"
else
    command -v uv >/dev/null 2>&1 || { info "Installing uv"; sudo dnf install -y uv; }
    info "Installing graphify (graphifyy) with uv"
    uv tool install graphifyy
fi
command -v jq >/dev/null 2>&1 || sudo dnf install -y jq

# ---------- 2. Claude Code ----------
if [ "$WITH_CLAUDE" = true ]; then
    mkdir -p "$HOME/.claude"
    for f in CLAUDE.md settings.json; do
        [ -f "$HOME/.claude/$f" ] && cp "$HOME/.claude/$f" "$HOME/.claude/$f.bak-$STAMP"
    done

    info "Claude Code: graphify skill (/graphify)"
    graphify install --platform claude >/dev/null

    if grep -q '^# graphify: code graphs live outside the repo' "$HOME/.claude/CLAUDE.md" 2>/dev/null; then
        info "Claude Code: notes rules already in ~/.claude/CLAUDE.md"
    else
        info "Claude Code: notes + graph rules -> ~/.claude/CLAUDE.md"
        sed "s|~/Documents/catatan|${NOTES/#$HOME/\~}|g" "$DOTS/brain/claude-md-block.md" >> "$HOME/.claude/CLAUDE.md"
    fi

    info "Claude Code: graph hooks -> ~/.claude/settings.json"
    settings="$HOME/.claude/settings.json"
    [ -s "$settings" ] || echo '{}' > "$settings"
    gbin="$(command -v graphify)"
    tmp="$(mktemp)"
    jq --arg s "$gbin hook-guard search" --arg r "$gbin hook-guard read" '
        def add($m; $c):
            if any(.hooks.PreToolUse[]?; any(.hooks[]?; (.command // "") | test("graphify hook-guard")) and .matcher == $m)
            then . else .hooks.PreToolUse += [{matcher: $m, hooks: [{type: "command", command: $c}]}] end;
        .hooks //= {} | .hooks.PreToolUse //= [] | add("Bash|Grep"; $s) | add("Read|Glob"; $r)
    ' "$settings" > "$tmp" && mv "$tmp" "$settings"
fi

# ---------- 3. notes folder ----------
info "Notes folder: $NOTES"
mkdir -p "$NOTES/graph-repo" "$NOTES/_tools"
[ -e "$NOTES/00-INDEX.md" ] || sed "s|~/Documents/catatan|${NOTES/#$HOME/\~}|g; s|<vault>|$VAULT_NAME|g" \
    "$DOTS/brain/notes/00-INDEX.md" > "$NOTES/00-INDEX.md"
install -m 755 "$DOTS/brain/notes/_tools/sync_obsidian.py" "$NOTES/_tools/sync_obsidian.py"

# ---------- 4. Obsidian vault ----------
VAULT="$NOTES/$VAULT_NAME"
info "Obsidian vault: $VAULT"
mkdir -p "$VAULT/.obsidian"
for f in "$DOTS"/brain/obsidian/*.json; do
    [ -e "$VAULT/.obsidian/$(basename "$f")" ] || cp "$f" "$VAULT/.obsidian/"
done
NOTES_DIR="$NOTES" OBSIDIAN_VAULT="$VAULT_NAME" python3 "$NOTES/_tools/sync_obsidian.py" >/dev/null

cat <<EOF

$(printf '\e[32mBrain ready.\e[0m') It is empty on purpose:
  1. Make a topic folder, e.g. $NOTES/work, and write notes in it (.md).
  2. In Claude Code: /graphify $NOTES/work   (builds the graph)
  3. python3 $NOTES/_tools/sync_obsidian.py  (puts notes + graph into Obsidian)
  4. Obsidian -> "Open folder as vault" -> $VAULT
Code repos: graphs go to $NOTES/graph-repo/<repo>/graphify-out (see ~/.claude/CLAUDE.md).
EOF
