#!/usr/bin/env python3
"""Keep workspaces numbered without gaps: occupied workspaces are always 1, 2, 3, ...
An empty workspace that is currently focused goes last.
Windows are not moved; only the workspace ID is changed (change_id)."""
import json
import os
import socket
import subprocess
import sys
import time

TRIGGERS = (b"openwindow", b"closewindow", b"movewindow", b"workspace",
            b"createworkspace", b"destroyworkspace", b"changeworkspaceid")
DEBOUNCE = 0.15


def hyprctl_json(what):
    out = subprocess.run(["hyprctl", "-j", what], capture_output=True, text=True).stdout
    return json.loads(out or "null")


def change_id(pairs):
    lua = " ".join(
        f'hl.dispatch(hl.dsp.workspace.change_id({{ workspace = "{a}", id = {b} }}))'
        for a, b in pairs)
    subprocess.run(["hyprctl", "eval", lua], capture_output=True)


def compact():
    workspaces = hyprctl_json("workspaces") or []
    active = (hyprctl_json("activeworkspace") or {}).get("id")
    # only regular numbered workspaces (not special / named)
    normal = [w for w in workspaces if w["id"] > 0 and w["name"] == str(w["id"])]
    occupied = sorted(w["id"] for w in normal if w["windows"] > 0)
    order = occupied + ([active] if active and active > 0 and active not in occupied
                        and any(w["id"] == active for w in normal) else [])
    targets = {ws: i + 1 for i, ws in enumerate(order)}
    moves = [(ws, t) for ws, t in targets.items() if ws != t]
    if not moves:
        return
    # move other (empty, unfocused) workspaces out of the way of target IDs
    blockers = [w["id"] for w in normal if w["id"] not in targets and w["id"] <= len(order)]
    first = [(ws, 1000 + i) for i, ws in enumerate(blockers)]
    first += [(ws, 2000 + i) for i, (ws, _) in enumerate(moves)]
    second = [(2000 + i, t) for i, (_, t) in enumerate(moves)]
    change_id(first + second)


def main():
    sock_path = os.path.join(os.environ["XDG_RUNTIME_DIR"], "hypr",
                             os.environ["HYPRLAND_INSTANCE_SIGNATURE"], ".socket2.sock")
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect(sock_path)
    s.settimeout(None)
    compact()
    buf = b""
    pending = False
    while True:
        s.settimeout(DEBOUNCE if pending else None)
        try:
            data = s.recv(4096)
        except socket.timeout:
            pending = False
            compact()
            continue
        if not data:
            sys.exit(1)
        buf += data
        *lines, buf = buf.split(b"\n")
        if any(line.startswith(TRIGGERS) for line in lines):
            pending = True


if __name__ == "__main__":
    while True:
        try:
            main()
        except json.JSONDecodeError:
            time.sleep(1)
