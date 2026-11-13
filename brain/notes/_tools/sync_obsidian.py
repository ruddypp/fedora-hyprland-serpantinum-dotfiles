#!/usr/bin/env python3
"""
Sync every topic folder + its graphify graph into the Obsidian vault.

- Every topic folder that has graphify-out/graph.json is symlinked into the vault,
  so each note exists once (edit it in Obsidian or anywhere else, same file).
- Each graph is exported with `graphify export obsidian` into <vault>/_graph/<topic>/.
- Canvas paths are rewritten to be vault-relative, and every node note links back
  to the note it was extracted from.

Run after rebuilding any graph:  python3 ~/Documents/catatan/_tools/sync_obsidian.py [--force]

Paths: NOTES_DIR (default ~/Documents/catatan), OBSIDIAN_VAULT (default: your username).
"""
import getpass
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(os.environ.get("NOTES_DIR", Path.home() / "Documents" / "catatan")).expanduser()
VAULT = ROOT / os.environ.get("OBSIDIAN_VAULT", getpass.getuser())
GRAPH_DIR = VAULT / "_graph"


def topics():
    return sorted(p.name for p in ROOT.iterdir()
                  if p.is_dir() and p != VAULT and (p / "graphify-out" / "graph.json").exists())


def link(name):
    target = VAULT / name
    if target.is_symlink() or target.exists():
        return
    target.symlink_to(Path("..") / name)


def export(topic):
    out = GRAPH_DIR / topic
    if out.exists():
        shutil.rmtree(out)
    subprocess.run(["graphify", "export", "obsidian", "--dir", str(out)],
                   cwd=ROOT / topic, check=True, capture_output=True)

    # Canvas paths are relative to the export dir; make them relative to the vault root.
    for canvas in out.glob("*.canvas"):
        data = json.loads(canvas.read_text(encoding="utf-8"))
        for node in data.get("nodes", []):
            if node.get("type") == "file" and not node["file"].startswith("_graph/"):
                node["file"] = f"_graph/{topic}/{node['file']}"
        canvas.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")

    # Link each node note back to the note it was extracted from.
    for note in out.glob("*.md"):
        text = note.read_text(encoding="utf-8")
        m = re.search(r'^source_file:\s*"([^"]+)"', text, re.M)
        if not m or "Source note:" in text:
            continue
        src = Path(m.group(1)).stem
        text = text.rstrip() + f"\n\nSource note: [[{topic}/{src}|{src}]]\n"
        note.write_text(text, encoding="utf-8")
    return len(list(out.glob("*.md")))


def needs_export(topic, force=False):
    """Only re-export when graph.json is newer than the last export."""
    graph = ROOT / topic / "graphify-out" / "graph.json"
    stamp = GRAPH_DIR / topic / ".synced"
    if force or not stamp.exists():
        return True
    return graph.stat().st_mtime > float(stamp.read_text().strip() or 0)


def main():
    force = "--force" in sys.argv
    VAULT.mkdir(parents=True, exist_ok=True)
    GRAPH_DIR.mkdir(exist_ok=True)
    if (ROOT / "00-INDEX.md").exists():
        link("00-INDEX.md")
    found = topics()
    if not found:
        print(f"No topic with a graph yet in {ROOT}. Make a folder, add notes, run /graphify <folder> in Claude Code.")
    for t in found:
        link(t)
        if not needs_export(t, force):
            print(f"{t}: unchanged, skipped")
            continue
        n = export(t)
        (GRAPH_DIR / t / ".synced").write_text(
            str((ROOT / t / "graphify-out" / "graph.json").stat().st_mtime), encoding="utf-8")
        print(f"{t}: {n} node notes -> _graph/{t}/")


if __name__ == "__main__":
    main()
