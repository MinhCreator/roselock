import QtQuick
import QtQuick.Effects
import Quickshell.Services.Mpris

Item {
    id: root

    readonly property var player: {
        var l = Mpris.players.values;
        for (var i = 0; i < l.length; i++) if (l[i].isPlaying) {
            return l[i];
        }
        return l.length > 0 ? l[0] : null;
    }
    readonly property bool has: player !== null
    readonly property bool playing: player !== null && player.isPlaying
    readonly property real len: player && player.lengthSupported ? player.length : 0
    readonly property real pos: player && player.positionSupported ? player.position : 0
    readonly property real frac: len > 0 ? Math.min(1, pos / len) : 0
    readonly property string artKind: playing ? "cookie" : "squircle"

    function fmt(s) {
        s = Math.max(0, Math.floor(s));
        return Math.floor(s / 60) + ":" + ("0" + (s % 60)).slice(-2);
    }

    implicitWidth: 460
    implicitHeight: 142

    Timer {
        running: root.playing
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    MdShape {
        anchors.fill: parent
        kind: "rounded"
        radius: 28
        color: Qt.alpha(Theme.s.surfaceContainerHigh, 0.92)
    }

    MouseArea {
        anchors.fill: parent
        onPressed: (m) => {
            return m.accepted = true;
        }
        onWheel: (w) => {
            return w.accepted = true;
        }
    }

    Item {
        id: art

        width: 78
        height: 78

        anchors {
            left: parent.left
            leftMargin: 16
            verticalCenter: parent.verticalCenter
        }

        MdShape {
            anchors.fill: parent
            kind: root.artKind
            color: Theme.s.secondaryContainer
        }

        Image {
            id: img

            anchors.fill: parent
            visible: false
            asynchronous: true
            sourceSize.width: 200
            sourceSize.height: 200
            fillMode: Image.PreserveAspectCrop
            source: root.player ? root.player.trackArtUrl : ""
        }

        Item {
            id: mask

            anchors.fill: parent
            visible: false
            layer.enabled: true

            MdShape {
                anchors.fill: parent
                kind: root.artKind
                color: "black"
            }

        }

        MultiEffect {
            anchors.fill: parent
            opacity: img.status === Image.Ready ? 1 : 0
            visible: opacity > 0.01
            source: img
            maskEnabled: true
            maskSource: mask

            Behavior on opacity {
                NumberAnimation {
                    duration: 350
                }

            }

        }

    }

    Column {
        spacing: 2

        anchors {
            left: art.right
            leftMargin: 16
            right: parent.right
            rightMargin: 18
            verticalCenter: parent.verticalCenter
        }

        Tx {
            width: parent.width
            elide: Text.ElideRight
            role: "titleMedium"
            text: root.player ? (root.player.trackTitle || "Unknown") : ""
        }

        Tx {
            width: parent.width
            elide: Text.ElideRight
            role: "bodyMedium"
            color: Theme.s.onSurfaceVariant
            text: root.player ? (root.player.trackArtist || "") : ""
        }

        Item {
            width: parent.width
            height: 20

            Tx {
                id: tL

                role: "labelSmall"
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.s.onSurfaceVariant
                text: root.fmt(root.pos)
            }

            Tx {
                id: tR

                role: "labelSmall"
                color: Theme.s.onSurfaceVariant
                text: root.fmt(root.len)

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

            }

            WavyProgress {
                value: root.frac
                playing: root.playing
                activeColor: Theme.s.primary
                trackColor: Theme.s.secondaryContainer
                onSeek: (f) => {
                    if (root.player && root.player.canSeek && root.len > 0)
                        root.player.position = f * root.len;

                }

                anchors {
                    left: tL.right
                    leftMargin: 8
                    right: tR.left
                    rightMargin: 8
                    verticalCenter: parent.verticalCenter
                }

            }

        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            height: 42

            MdButton {
                id: bp

                height: 42
                width: 52 + (down ? 8 : 0) - (bm.down ? 4 : 0)
                shape: "squircle"
                pressedShape: "circle"
                iconSize: 24
                bg: Theme.s.secondaryContainer
                fg: Theme.s.onSecondaryContainer
                icon: "prev"
                onClicked: {
                    if (root.player) {
                        root.player.previous();
                    }
                }
            }

            MdButton {
                id: bm

                height: 42
                width: 80 + (down ? 10 : 0) - ((bp.down || bn.down) ? 4 : 0)
                shape: root.playing ? "squircle" : "circle"
                pressedShape: root.playing ? "circle" : "squircle"
                iconSize: 26
                bg: Theme.s.primary
                fg: Theme.s.onPrimary
                icon: root.playing ? "pause" : "play"
                onClicked: {
                    if (root.player) {
                        root.player.togglePlaying();
                    }
                }
            }

            MdButton {
                id: bn

                height: 42
                width: 52 + (down ? 8 : 0) - (bm.down ? 4 : 0)
                shape: "squircle"
                pressedShape: "circle"
                iconSize: 24
                bg: Theme.s.secondaryContainer
                fg: Theme.s.onSecondaryContainer
                icon: "next"
                onClicked: {
                    if (root.player) {
                        root.player.next();
                    }
                }
            }

        }

    }

}
