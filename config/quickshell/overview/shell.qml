// GNOME-style overview: Super+Tab shows every workspace; drag a window onto
// another workspace to move it. Click a window to focus it, click a workspace to go there.
// Runs as its own Quickshell config so Serpantinum updates never overwrite it.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

ShellRoot {
    id: shell
    property bool open: false

    function refresh() {
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
    }

    function hypr(lua) {
        runner.command = ["hyprctl", "eval", lua];
        runner.running = true;
    }

    Process {
        id: runner
        onExited: shell.refresh()
    }

    IpcHandler {
        target: "overview"
        function toggle(): void {
            if (!shell.open) shell.refresh();
            shell.open = !shell.open;
        }
        function close(): void { shell.open = false; }
    }

    PanelWindow {
        id: win
        visible: shell.open
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "overview"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        readonly property int activeWs: Hyprland.focusedWorkspace?.id ?? 1
        readonly property var monIpc: Hyprland.focusedMonitor?.lastIpcObject ?? ({})
        readonly property real monX: monIpc.x ?? 0
        readonly property real monY: monIpc.y ?? 0

        function wsOf(t) {
            const ipc = t.lastIpcObject;
            if (ipc && ipc.workspace && ipc.workspace.id !== undefined) return ipc.workspace.id;
            return t.workspace ? t.workspace.id : -1;
        }

        readonly property var windows: Hyprland.toplevels.values.filter(t => wsOf(t) > 0)
        readonly property int wsCount: {
            let m = activeWs;
            for (const t of windows) m = Math.max(m, wsOf(t));
            return m + 1; // one empty slot at the end to create a new workspace
        }

        // dragged window position (stage coordinates)
        property var dragTop: null
        property real dragW: 0
        property real dragH: 0
        property point dragPos: Qt.point(0, 0)

        function cardAt(p) {
            for (let i = 0; i < cards.count; i++) {
                const c = cards.itemAt(i);
                const q = c.mapFromItem(stage, p.x, p.y);
                if (q.x >= 0 && q.y >= 0 && q.x <= c.width && q.y <= c.height) return c;
            }
            return null;
        }

        function moveWindow(t, ws) {
            shell.hypr(`hl.dispatch(hl.dsp.window.move({ workspace = "${ws}", window = "address:0x${String(t.address).replace(/^0x/, "")}" })) `
                     + `hl.dispatch(hl.dsp.focus({ workspace = "${activeWs}" }))`);
        }

        function focusWindow(t) {
            shell.open = false;
            shell.hypr(`hl.dispatch(hl.dsp.focus({ window = "address:0x${String(t.address).replace(/^0x/, "")}" }))`);
        }

        function gotoWs(ws) {
            shell.open = false;
            shell.hypr(`hl.dispatch(hl.dsp.focus({ workspace = "${ws}" }))`);
        }

        Item {
            id: stage
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: shell.open = false

            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: 0.55
            }

            MouseArea {
                anchors.fill: parent
                onClicked: shell.open = false
            }

            Row {
                id: row
                anchors.centerIn: parent
                spacing: 24

                readonly property real cardW: Math.min(win.width * 0.3,
                                                       (win.width - 80 - spacing * (win.wsCount - 1)) / win.wsCount)
                readonly property real cardH: cardW * win.height / win.width
                readonly property real scale: cardW / win.width

                Repeater {
                    id: cards
                    model: win.wsCount

                    Rectangle {
                        id: card
                        required property int index
                        readonly property int wsId: index + 1
                        readonly property bool hovered: win.dragTop !== null && win.cardAt(win.dragPos) === card
                        width: row.cardW
                        height: row.cardH
                        radius: 12
                        color: "#1c1c1c"
                        border.width: wsId === win.activeWs || hovered ? 2 : 1
                        border.color: hovered ? "#ffffff" : (wsId === win.activeWs ? "#9a9a9a" : "#333333")
                        clip: true

                        MouseArea {
                            anchors.fill: parent
                            onClicked: win.gotoWs(card.wsId)
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !win.windows.some(t => win.wsOf(t) === card.wsId)
                            text: card.wsId === win.wsCount ? "+" : card.wsId
                            color: "#666666"
                            font.pixelSize: 28
                        }

                        Repeater {
                            model: win.windows.filter(t => win.wsOf(t) === card.wsId)

                            Item {
                                id: thumb
                                required property var modelData
                                readonly property var ipc: modelData.lastIpcObject ?? ({})
                                x: ((ipc.at?.[0] ?? 0) - win.monX) * row.scale
                                y: ((ipc.at?.[1] ?? 0) - win.monY) * row.scale
                                width: Math.max(24, (ipc.size?.[0] ?? 200) * row.scale)
                                height: Math.max(16, (ipc.size?.[1] ?? 120) * row.scale)
                                opacity: win.dragTop === modelData ? 0.3 : 1

                                ScreencopyView {
                                    anchors.fill: parent
                                    captureSource: shell.open ? thumb.modelData.wayland : null
                                    live: shell.open
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"
                                    radius: 6
                                    border.width: ma.containsMouse ? 2 : 0
                                    border.color: "#ffffff"
                                }

                                MouseArea {
                                    id: ma
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    property point start
                                    property bool dragging: false

                                    onPressed: m => { start = Qt.point(m.x, m.y); dragging = false; }
                                    onPositionChanged: m => {
                                        if (!pressed) return;
                                        if (!dragging && Math.hypot(m.x - start.x, m.y - start.y) > 8) {
                                            dragging = true;
                                            win.dragW = thumb.width;
                                            win.dragH = thumb.height;
                                            win.dragTop = thumb.modelData;
                                        }
                                        if (dragging) win.dragPos = mapToItem(stage, m.x, m.y);
                                    }
                                    onReleased: m => {
                                        if (!dragging) { win.focusWindow(thumb.modelData); return; }
                                        const target = win.cardAt(mapToItem(stage, m.x, m.y));
                                        if (target && target.wsId !== card.wsId) win.moveWindow(thumb.modelData, target.wsId);
                                        win.dragTop = null;
                                        dragging = false;
                                    }
                                }
                            }
                        }

                        Text {
                            anchors { left: parent.left; bottom: parent.bottom; margins: 8 }
                            text: card.wsId
                            color: "#bbbbbb"
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                }
            }

            // the window being dragged follows the cursor
            Item {
                visible: win.dragTop !== null
                width: win.dragW
                height: win.dragH
                x: win.dragPos.x - width / 2
                y: win.dragPos.y - height / 2
                z: 100

                ScreencopyView {
                    anchors.fill: parent
                    captureSource: win.dragTop ? win.dragTop.wayland : null
                    live: true
                }
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    radius: 6
                    border.width: 2
                    border.color: "#ffffff"
                }
            }
        }
    }
}
