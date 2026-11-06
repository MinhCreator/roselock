import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Row {
    id: root

    property bool wifiOn: false
    property int sig: 0
    property bool eth: false
    readonly property var dev: UPower.displayDevice
    readonly property bool hasBat: dev !== null && dev.isPresent
    readonly property real pct: !hasBat ? 0 : (dev.percentage > 1 ? dev.percentage : dev.percentage * 100)
    readonly property bool charging: hasBat && (dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.FullyCharged)

    function parse(t) {
        var w = false, g = 0, e = false;
        t.split("\n").forEach(function(l) {
            var m = l.match(/^yes:(\d+)/);
            if (m) {
                w = true;
                g = parseInt(m[1]);
            }
            if (l.indexOf("ethernet:") === 0)
                e = true;

        });
        wifiOn = w;
        sig = g;
        eth = e;
    }

    spacing: 14

    Process {
        id: proc

        command: ["sh", "-c", "nmcli -t -f ACTIVE,SIGNAL dev wifi list --rescan no 2>/dev/null | grep '^yes' | head -1; nmcli -t -f TYPE,STATE dev 2>/dev/null | grep '^ethernet:connected' | head -1"]

        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }

    }

    Timer {
        interval: 8000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (!proc.running) {
                proc.running = true;
            }
        }
    }

    Icon {
        visible: root.wifiOn || !root.eth
        width: 24
        height: 24
        anchors.verticalCenter: parent.verticalCenter
        kind: root.wifiOn ? "wifi" : "wifi-off"
        level: Math.min(3, Math.ceil(root.sig / 34))
        color: Theme.s.onSurface
    }

    Row {
        visible: root.hasBat
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter

        Icon {
            width: 26
            height: 26
            anchors.verticalCenter: parent.verticalCenter
            kind: "battery"
            level: root.pct / 100
            charging: root.charging
            color: root.pct < 15 && !root.charging ? Theme.s.error : Theme.s.onSurface
        }

        Tx {
            anchors.verticalCenter: parent.verticalCenter
            role: "labelLarge"
            text: Math.round(root.pct) + "%"
        }

    }

}
