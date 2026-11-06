import QtQuick

Item {
    id: root

    required property var ctx
    property real unit: 800
    readonly property bool pin: Config.input === "pin"
    readonly property bool pad: Config.keypad
    readonly property real key: Math.max(52, Math.min(80, unit * 0.095))
    readonly property real fieldW: pin ? Math.max(dots.implicitWidth, 200) : 380

    width: pad ? Math.max(3 * key + 28, fieldW) : fieldW
    height: col.implicitHeight

    Column {
        id: col

        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16

        MdShape {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 64
            height: 64
            kind: root.ctx.error !== "" ? "pebble" : ((root.ctx.busy || root.ctx.unlocking) ? "sunny" : "cookie")
            color: root.ctx.error !== "" ? Theme.s.errorContainer : Theme.s.primaryContainer

            Icon {
                anchors.centerIn: parent
                width: 30
                height: 30
                kind: root.ctx.unlocking ? "enter" : "lock"
                color: root.ctx.error !== "" ? Theme.s.onErrorContainer : Theme.s.onPrimaryContainer
            }

        }

        Tx {
            anchors.horizontalCenter: parent.horizontalCenter
            role: "titleMedium"
            color: root.ctx.error !== "" ? Theme.s.error : Theme.s.onSurface
            text: root.ctx.unlocking ? "Welcome back" : root.ctx.busy ? "Checking\u2026" : (root.ctx.error !== "" ? root.ctx.error : (root.pin ? "Enter PIN" : "Enter password"))
        }

        Item {
            id: entry

            anchors.horizontalCenter: parent.horizontalCenter
            width: root.pin ? dots.implicitWidth : field.width
            height: root.pin ? 28 : field.height

            PinDots {
                id: dots

                visible: root.pin
                ctx: root.ctx
                anchors.centerIn: parent
            }

            PasswordField {
                id: field

                visible: !root.pin
                ctx: root.ctx
            }

            transform: Translate {
                id: tr
            }

        }

        Item {
            visible: root.pad
            width: 1
            height: 6
        }

        PinPad {
            visible: root.pad
            anchors.horizontalCenter: parent.horizontalCenter
            ctx: root.ctx
            key: root.key
        }

    }

    SequentialAnimation {
        id: shk

        NumberAnimation {
            target: tr
            property: "x"
            to: -16
            duration: 55
        }

        NumberAnimation {
            target: tr
            property: "x"
            to: 14
            duration: 70
        }

        NumberAnimation {
            target: tr
            property: "x"
            to: -10
            duration: 70
        }

        NumberAnimation {
            target: tr
            property: "x"
            to: 6
            duration: 60
        }

        NumberAnimation {
            target: tr
            property: "x"
            to: 0
            duration: 60
        }

    }

    Connections {
        function onShakeChanged() {
            shk.restart();
        }

        target: root.ctx
    }

}
