// Serpantinum Obsidian: SDDM login screen matching the Serpantinum Obsidian preset
// (black/white/gray, Adwaita Mono). Centered, card-less content over bg.jpg, with the user's avatar.
// Part of fedora-hyprland-serpantinum-dotfiles, AGPL-3.0.
import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "#000000"

    // Obsidian palette (same as ~/.config/serpantinum/settings.json)
    readonly property color cText: "#ffffff"
    readonly property color cSub0: "#a0a0a0"
    readonly property color cSub1: "#c0c0c0"
    readonly property color cOverlay0: "#5a5a5a"
    readonly property color cSurface0: "#1a1a1a"
    readonly property color cSurface1: "#2a2a2a"
    readonly property color cSurface2: "#3a3a3a"
    readonly property real radius: 10 * s

    readonly property real s: Screen.height / 1080
    readonly property bool hasSddm: typeof sddm !== "undefined"
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property string errorMessage: ""
    property bool busy: false

    // Font: "Adwaita Mono" from the adwaita-mono-fonts package
    readonly property string mono: "Adwaita Mono"

    // User and session names are read through hidden ListViews (the usual way to read SDDM models)
    ListView {
        id: sessionHelper
        model: typeof sessionModel !== "undefined" ? sessionModel : null
        currentIndex: root.sessionIndex
        opacity: 0
        width: 100
        height: 100
        z: -100
        delegate: Item { property string sName: model.name || "" }
    }
    ListView {
        id: userHelper
        model: typeof userModel !== "undefined" ? userModel : null
        currentIndex: root.userIndex
        opacity: 0
        width: 100
        height: 100
        z: -100
        delegate: Item {
            property string uName: model.realName || model.name || ""
            property string uLogin: model.name || ""
            property string uIcon: model.icon || ""
        }
    }

    readonly property string userLogin: userHelper.currentItem ? userHelper.currentItem.uLogin : (typeof userModel !== "undefined" ? userModel.lastUser : "")
    readonly property string userName: userHelper.currentItem && userHelper.currentItem.uName !== "" ? userHelper.currentItem.uName : userLogin
    readonly property string userIcon: userHelper.currentItem ? String(userHelper.currentItem.uIcon).replace("file://", "") : ""
    readonly property string sessionName: sessionHelper.currentItem ? sessionHelper.currentItem.sName : "Session"

    function doLogin() {
        if (root.busy || pwd.text.length === 0) return;
        root.busy = true;
        root.errorMessage = "";
        if (root.hasSddm) sddm.login(root.userLogin, pwd.text, root.sessionIndex);
    }

    Connections {
        target: root.hasSddm ? sddm : null
        function onLoginFailed() {
            root.busy = false;
            root.errorMessage = "Wrong password";
            pwd.text = "";
            shake.start();
            pwd.forceActiveFocus();
        }
        function onLoginSucceeded() { root.busy = false; }
    }

    Component.onCompleted: {
        if (typeof keyboard !== "undefined") keyboard.numLock = true;
        focusTimer.start();
    }
    Timer { id: focusTimer; interval: 200; onTriggered: pwd.forceActiveFocus() }

    // ---------- Background: bg.jpg, dimmed + vignette so the centered text stays readable ----------
    Image {
        id: bg
        anchors.fill: parent
        source: "bg.jpg"
        fillMode: Image.PreserveAspectCrop
    }
    Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.38) }
    RadialGradient {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.35) }
            GradientStop { position: 0.35; color: Qt.rgba(0, 0, 0, 0.10) }
            GradientStop { position: 0.75; color: Qt.rgba(0, 0, 0, 0.45) }
        }
    }

    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    // ---------- Centered content, no card ----------
    Item {
        id: content
        anchors.fill: parent
        // Soft shadow on all content: blends into the image but stays readable
        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 2 * s
            radius: 18 * s
            samples: 37
            color: Qt.rgba(0, 0, 0, 0.55)
            transparentBorder: true
        }

        Column {
            id: center
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 90 * s
            spacing: 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(root.now, "HH:mm")
                color: root.cText
                font.family: root.mono
                font.bold: true
                font.pixelSize: 136 * s
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.now.toLocaleDateString(Qt.locale(), "dddd, d MMMM")
                color: root.cSub1
                font.family: root.mono
                font.pixelSize: 20 * s
                font.letterSpacing: 1 * s
            }

            Item { width: 1; height: 64 * s }

            // Avatar + name (click to switch user when there is more than one)
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 360 * s
                height: userCol.implicitHeight
                Column {
                    id: userCol
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12 * s
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        id: avatarFrame
                        width: 88 * s; height: 88 * s; radius: width / 2
                        color: Qt.rgba(1, 1, 1, 0.10)

                        // Avatar: faces/<login>.png inside the theme, then the icon SDDM provides
                        Image {
                            id: avatarImg
                            anchors.fill: parent
                            source: root.userLogin !== "" ? "faces/" + root.userLogin + ".png" : ""
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 256
                            sourceSize.height: 256
                            smooth: true
                            visible: false
                            onStatusChanged: {
                                if (status === Image.Error && root.userIcon !== "" && source.toString().indexOf(root.userIcon) < 0)
                                    source = "file://" + root.userIcon;
                            }
                        }
                        Rectangle { id: avatarMask; anchors.fill: parent; radius: width / 2; visible: false }
                        OpacityMask {
                            anchors.fill: parent
                            source: avatarImg
                            maskSource: avatarMask
                            visible: avatarImg.status === Image.Ready
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "transparent"
                            border.width: 2
                            border.color: Qt.rgba(1, 1, 1, 0.55)
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: avatarImg.status !== Image.Ready
                            text: root.userName.length > 0 ? root.userName.charAt(0).toUpperCase() : "?"
                            color: root.cText
                            font.family: root.mono
                            font.bold: true
                            font.pixelSize: 34 * s
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.userName
                        color: root.cText
                        font.family: root.mono
                        font.bold: true
                        font.pixelSize: 20 * s
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: typeof userModel !== "undefined" && userModel.rowCount() > 1
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.userIndex = (root.userIndex + 1) % userModel.rowCount()
                }
            }

            Item { width: 1; height: 22 * s }

            // Password field: thin pill with the sign-in arrow on the right
            Rectangle {
                id: pwdBox
                anchors.horizontalCenter: parent.horizontalCenter
                width: 340 * s
                height: 50 * s
                radius: height / 2
                color: Qt.rgba(1, 1, 1, pwd.activeFocus ? 0.14 : 0.08)
                border.width: 1
                border.color: pwd.activeFocus ? Qt.rgba(1, 1, 1, 0.50) : Qt.rgba(1, 1, 1, 0.20)
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                TextInput {
                    id: pwd
                    anchors.left: parent.left
                    anchors.right: goBtn.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 22 * s
                    anchors.rightMargin: 8 * s
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: root.cText
                    selectionColor: root.cSurface2
                    font.family: root.mono
                    font.pixelSize: 18 * s
                    font.letterSpacing: 2 * s
                    clip: true
                    focus: true
                    enabled: !root.busy
                    onAccepted: root.doLogin()
                    onTextChanged: if (text.length > 0) root.errorMessage = ""
                    Keys.onEscapePressed: text = ""
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 22 * s
                    visible: pwd.text.length === 0
                    text: root.busy ? "Signing in…" : "Password"
                    color: Qt.rgba(1, 1, 1, 0.45)
                    font.family: root.mono
                    font.pixelSize: 16 * s
                }

                Rectangle {
                    id: goBtn
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 6 * s
                    width: 38 * s; height: 38 * s; radius: width / 2
                    color: pwd.text.length > 0 ? (goMa.containsMouse ? "#e8e8e8" : root.cText) : Qt.rgba(1, 1, 1, 0.10)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text {
                        anchors.centerIn: parent
                        text: "→"
                        color: pwd.text.length > 0 ? "#000000" : Qt.rgba(1, 1, 1, 0.5)
                        font.family: root.mono
                        font.bold: true
                        font.pixelSize: 18 * s
                    }
                    MouseArea {
                        id: goMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.doLogin()
                    }
                }

                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: pwdBox; property: "anchors.horizontalCenterOffset"; to: 12 * s; duration: 50 }
                    NumberAnimation { target: pwdBox; property: "anchors.horizontalCenterOffset"; to: -12 * s; duration: 70 }
                    NumberAnimation { target: pwdBox; property: "anchors.horizontalCenterOffset"; to: 7 * s; duration: 60 }
                    NumberAnimation { target: pwdBox; property: "anchors.horizontalCenterOffset"; to: 0; duration: 60 }
                }
            }

            Item { width: 1; height: 14 * s }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.errorMessage
                opacity: root.errorMessage !== "" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                color: root.cText
                font.family: root.mono
                font.pixelSize: 14 * s
            }
        }

        // Bottom row: session + power actions as plain text links
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 44 * s
            spacing: 34 * s

            component Link: Text {
                id: link
                signal activated()
                color: linkMa.containsMouse ? root.cText : Qt.rgba(1, 1, 1, 0.55)
                Behavior on color { ColorAnimation { duration: 120 } }
                font.family: root.mono
                font.pixelSize: 14 * s
                font.letterSpacing: 1 * s
                MouseArea {
                    id: linkMa
                    anchors.fill: parent
                    anchors.margins: -8 * s
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: link.activated()
                }
            }

            Link {
                text: root.sessionName + "  ▾"
                onActivated: {
                    if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0)
                        root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount();
                }
            }
            Text { text: "·"; color: Qt.rgba(1, 1, 1, 0.3); font.pixelSize: 14 * s }
            Link { text: "Sleep"; onActivated: if (root.hasSddm) sddm.suspend() }
            Link { text: "Restart"; onActivated: if (root.hasSddm) sddm.reboot() }
            Link { text: "Shut down"; onActivated: if (root.hasSddm) sddm.powerOff() }
        }
    }

}
