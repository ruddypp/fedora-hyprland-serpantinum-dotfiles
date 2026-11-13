# Notes index

Every topic gets its own folder here, with its own knowledge graph in `<topic>/graphify-out/`.

## Rules for Claude (and any agent)
1. Before a task, look for context here: read this index, then query the matching topic:
   `cd ~/Documents/catatan/<topic> && graphify query "<question>"`
   (or `graphify explain "<concept>"`, or just read the .md files if the topic has no graph yet).
2. Notes are never complete. If something is missing, ask me or check the original source, then add it here.
3. After an important decision, workflow or status change, update that topic's notes and rebuild its graph
   (`/graphify <folder> --update` in Claude Code), then refresh the Obsidian vault:
   `python3 ~/Documents/catatan/_tools/sync_obsidian.py`

## Topics
| Folder | What's inside | When to use it |
|---|---|---|
| `graph-repo/` | One knowledge graph per code repo (`graph-repo/<repo>/graphify-out/`), kept out of the repo itself | Questions about a codebase |
| `<vault>/` | Obsidian vault: every topic + graph, synced by `_tools/sync_obsidian.py` | Reading notes in Obsidian |

<!-- Add a row per topic folder you create, e.g.
| `work/` | Client projects, decisions, status | Anything about work |
-->
