import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool ok: false
    property string temp: ""
    property string desc: ""
    property string place: ""
    property string kind: "cloud"
    property bool stale: false

    function parse(t) {
        try {
            var j = JSON.parse(t.trim().split("\n").pop());
            if (!j.ok)
                return false;

            root.temp = j.temp;
            root.desc = j.desc;
            root.kind = j.kind;
            root.place = j.place || "";
            root.ok = true;
            root.stale = j.stale === true;
            return true;
        } catch (e) {
            return false;
        }
    }

    Process {
        id: proc

        command: ["python3", Quickshell.shellPath("weather.py"), Config.weatherLoc, Config.imperial ? "imperial" : "metric", String(Config.weatherCacheMin)]
        onExited: {
            if (!root.ok || root.stale)
                retry.restart();

        }

        stdout: SplitParser {
            onRead: (line) => {
                return root.parse(line);
            }
        }

    }

    Timer {
        id: retry

        interval: 45000
        onTriggered: {
            if (Config.weatherOn && !proc.running) {
                proc.running = true;
            }
        }
    }

    Timer {
        interval: 1.8e+06
        repeat: true
        running: Config.weatherOn
        triggeredOnStart: true
        onTriggered: {
            if (!proc.running) {
                proc.running = true;
            }
        }
    }

}
