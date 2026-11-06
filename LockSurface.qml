import QtQuick
import QtQuick.Effects

Item {
    id: root

    required property var ctx
    property url shot: ""
    readonly property bool authing: ctx.authing
    readonly property bool leaving: ctx.unlocking
    readonly property int leaveMs: Config.transition ? Config.transitionMs : 1
    readonly property var s: Theme.s
    readonly property real vh: height
    readonly property real vw: width
    readonly property real hintTop: vh - vh * 0.035 - 46
    property bool settled: false

    function grab() {
        forceActiveFocus();
    }

    focus: true
    Component.onCompleted: grab()
    onVisibleChanged: {
        if (visible) {
            grab();
        }
    }
    onWidthChanged: {
        if (!settled) {
            settle.restart();
        }
    }
    onHeightChanged: {
        if (!settled) {
            settle.restart();
        }
    }
    Keys.onPressed: (event) => {
        if (ctx.unlocking) {
            event.accepted = true;
            return ;
        }
        if (ctx.activity()) {
            event.accepted = true;
            return ;
        }
        var k = event.key;
        var mod = event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier);
        event.accepted = true;
        ctx.poke();
        if (k === Qt.Key_Escape) {
            ctx.back();
        } else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
            if (!ctx.authing)
                ctx.open();
            else
                ctx.submit();
        } else if (k === Qt.Key_Backspace)
            ctx.backspace();
        else if (k === Qt.Key_U && (event.modifiers & Qt.ControlModifier))
            ctx.clear();
        else if (!mod && event.text.length === 1 && event.text >= " ")
            ctx.type(event.text);
        else if (!mod && k !== Qt.Key_Shift && k !== Qt.Key_Control && k !== Qt.Key_Alt && k !== Qt.Key_Meta && k !== Qt.Key_CapsLock)
            ctx.open();
    }

    Timer {
        interval: 250
        repeat: true
        running: !root.activeFocus
        onTriggered: root.grab()
    }

    HoverHandler {
        onHoveredChanged: root.grab()
        onPointChanged: root.ctx.activity()
    }

    Timer {
        id: settle

        interval: 450
        onTriggered: root.settled = true
    }

    Rectangle {
        anchors.fill: parent
        color: root.s.surface
    }

    Rectangle {
        anchors.fill: parent
        opacity: 0.55

        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.s.primaryContainer
            }

            GradientStop {
                position: 1
                color: root.s.surface
            }

        }

    }

    Item {
        id: wpBox

        anchors.fill: parent
        clip: true
        opacity: wp.status === Image.Ready ? 1 : 0
        layer.enabled: true

        Image {
            id: wp

            anchors.fill: parent
            asynchronous: true
            source: Theme.wallPath !== "" ? "file://" + Theme.wallPath : ""
            fillMode: Image.PreserveAspectCrop
            autoTransform: true
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 500
            }

        }

        layer.effect: MultiEffect {
            blurEnabled: Config.blur > 0
            blurMax: Math.max(1, Config.blur)
            blur: root.authing && !root.leaving ? 1 : 0

            Behavior on blur {
                NumberAnimation {
                    duration: root.leaving ? root.leaveMs : 500
                    easing.type: Easing.OutCubic
                }

            }

        }

    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.leaving ? 0 : Math.min(0.85, Config.dim + (root.authing ? 0.22 : 0))

        Behavior on opacity {
            NumberAnimation {
                duration: root.leaving ? root.leaveMs : 500
                easing.type: Easing.OutCubic
            }

        }

    }

    Rectangle {
        height: root.vh * 0.55
        opacity: root.authing || root.leaving ? 0 : 1

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 400
            }

        }

        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#70000000"
            }

            GradientStop {
                position: 1
                color: "#00000000"
            }

        }

    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(root.s.surface, 0.3)
        opacity: root.authing && !root.leaving ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: root.leaving ? root.leaveMs : 500
            }

        }

    }

    MouseArea {
        property real y0: 0

        anchors.fill: parent
        onPressed: (m) => {
            y0 = m.y;
            root.grab();
            root.ctx.activity();
        }
        onReleased: (m) => {
            if (!root.ctx.authing && (y0 - m.y > 50 || Math.abs(y0 - m.y) < 8))
                root.ctx.open();
            else
                root.ctx.poke();
        }
        onWheel: {
            if (!root.ctx.activity())
                root.ctx.open();

        }
    }

    Item {
        id: shotBox

        anchors.fill: parent
        visible: shotImg.status === Image.Ready && opacity > 0.001
        opacity: root.leaving ? 1 : 0
        layer.enabled: true

        Image {
            id: shotImg

            anchors.fill: parent
            source: root.shot
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.leaveMs
                easing.type: Easing.InOutCubic
            }

        }

        layer.effect: MultiEffect {
            blurEnabled: Config.blur > 0
            blurMax: Math.max(1, Config.blur)
            blur: root.leaving ? 0 : 1

            Behavior on blur {
                NumberAnimation {
                    duration: root.leaveMs
                    easing.type: Easing.OutCubic
                }

            }

        }

    }

    Item {
        id: ui

        anchors.fill: parent
        transformOrigin: Item.Center
        opacity: root.leaving ? 0 : 1
        scale: root.leaving ? 1.05 : 1

        MdShape {
            x: 28
            y: 24
            width: 40
            height: 40
            kind: "cookie"
            color: Qt.alpha(root.s.primaryContainer, 0.95)

            Icon {
                anchors.centerIn: parent
                width: 20
                height: 20
                kind: "lock"
                color: root.s.onPrimaryContainer
            }

        }

        StatusRow {
            visible: Config.statusOn

            anchors {
                right: parent.right
                rightMargin: 32
                top: parent.top
                topMargin: 28
            }

        }

        Item {
            id: clockWrap

            readonly property real mediaRoom: Config.mediaOn && media.has ? media.height + 30 : 0
            readonly property real mediaTop: root.hintTop - mediaRoom - 24
            readonly property real maxBlockH: Math.min(2 * mediaTop - root.vh, root.vh - 2 * 90)
            readonly property real digit: Math.max(80, Math.min(root.vw * 0.26, root.vh * 0.32, (maxBlockH - 60) / 1.65))
            readonly property real authScale: 0.36
            readonly property real authGap: root.vh * 0.04
            readonly property real authGroupH: bc.height * authScale + authGap + auth.height
            readonly property real authTop: Math.max(root.vh * 0.05, (root.vh - authGroupH) / 2)
            readonly property real authBottom: authTop + bc.height * authScale

            width: Math.max(bc.width, glance.width)
            height: stack.implicitHeight
            anchors.horizontalCenter: parent.horizontalCenter
            transformOrigin: Item.Top
            y: root.authing ? authTop : Math.round((root.vh - height) / 2)
            scale: root.authing ? authScale : 1

            Column {
                id: stack

                width: clockWrap.width
                spacing: clockWrap.digit * 0.06

                BigClock {
                    id: bc

                    x: (stack.width - width) / 2
                    size: clockWrap.digit
                }

                Row {
                    id: glance

                    x: (stack.width - width) / 2
                    spacing: 12
                    opacity: root.authing ? 0 : 1

                    Tx {
                        px: Math.max(18, root.vh * 0.028)
                        text: Qt.formatDate(new Date(), "ddd, MMM d")
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Row {
                        visible: Config.weatherOn && wx.ok
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter

                        Tx {
                            px: Math.max(18, root.vh * 0.028)
                            text: "\u00B7"
                            color: root.s.onSurfaceVariant
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Icon {
                            width: Math.max(22, root.vh * 0.032)
                            height: width
                            kind: wx.kind
                            color: root.s.tertiaryFixedDim
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Tx {
                            px: Math.max(18, root.vh * 0.028)
                            text: wx.temp
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Tx {
                            visible: Config.weatherPlace && wx.place !== ""
                            px: Math.max(16, root.vh * 0.024)
                            text: wx.place
                            color: root.s.onSurfaceVariant
                            anchors.verticalCenter: parent.verticalCenter
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 250
                        }

                    }

                }

            }

            Behavior on y {
                enabled: root.settled

                SpringAnimation {
                    spring: 2.4
                    damping: 0.28
                    epsilon: 0.2
                }

            }

            Behavior on scale {
                enabled: root.settled

                SpringAnimation {
                    spring: 2.4
                    damping: 0.28
                    epsilon: 0.002
                }

            }

        }

        WeatherData {
            id: wx
        }

        MediaCard {
            id: media

            visible: Config.mediaOn && has && opacity > 0.01
            width: Math.min(460, root.vw * 0.9)
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.hintTop - 22 - height + (root.authing ? 70 : 0)
            opacity: root.authing ? 0 : 1

            Behavior on y {
                enabled: root.settled

                SpringAnimation {
                    spring: 2.4
                    damping: 0.3
                    epsilon: 0.2
                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                }

            }

        }

        Column {
            spacing: 2
            opacity: root.authing ? 0 : 0.9

            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: root.vh * 0.035
            }

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 26
                height: 26
                kind: "chevron-up"
                color: root.s.onSurface

                SequentialAnimation on y {
                    loops: Animation.Infinite
                    running: !root.authing

                    NumberAnimation {
                        to: -5
                        duration: 700
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        to: 0
                        duration: 700
                        easing.type: Easing.InOutSine
                    }

                }

            }

            Tx {
                anchors.horizontalCenter: parent.horizontalCenter
                role: "labelLarge"
                text: "Click, swipe up or type to unlock"
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                }

            }

        }

        AuthBlock {
            id: auth

            ctx: root.ctx
            unit: root.vh
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.authing ? clockWrap.authBottom + clockWrap.authGap : root.vh
            opacity: root.authing ? 1 : 0
            visible: opacity > 0.01

            Behavior on y {
                enabled: root.settled

                SpringAnimation {
                    spring: 2.2
                    damping: 0.3
                    epsilon: 0.2
                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: Math.round(root.leaveMs * 0.7)
                easing.type: Easing.OutCubic
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: root.leaveMs
                easing.type: Easing.OutCubic
            }

        }

    }

}
