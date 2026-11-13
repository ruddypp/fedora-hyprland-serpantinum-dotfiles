
# graphify: code graphs live outside the repo
- **Code repo graphs must never live inside the repo.** Store them at `~/Documents/catatan/graph-repo/<repo-folder-name>/graphify-out/`, and always set `GRAPHIFY_OUT=<that path>` when building or updating (`GRAPHIFY_OUT=$G graphify update .`). Query with `--graph $G/graph.json`. If a `graphify-out/` shows up inside a repo, move it there.
- For codebase questions, run `graphify query "<question>" --graph $G/graph.json` first when that file exists; `graphify path "<A>" "<B>"` for relationships, `graphify explain "<concept>"` for one concept.

# Notes (read first)
All working notes live in `~/Documents/catatan/`. Before starting a task (main session and every subagent), read `~/Documents/catatan/00-INDEX.md`, then pull context with `cd ~/Documents/catatan/<topic> && graphify query "<question>"` (read the .md files when the topic has no graph). When a task produces important decisions, workflows or project status, update that topic's notes and rebuild its graph (`/graphify <folder> --update`).
