import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property bool test: Quickshell.env("ROSELOCK_TEST") === "1"
    readonly property string shotDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/roselock"
    property bool armed: false
    property bool started: false
    property bool shotsOk: false

    function shotFor(s) {
        return root.shotsOk && s && s.name ? "file://" + root.shotDir + "/" + s.name + ".jpg" : "";
    }

    function begin() {
        if (started || !Config.ready)
            return ;

        started = true;
        if (test || !Config.screenshot) {
            armed = true;
            return ;
        }
        grab.command = ["sh", "-c", 'd="$1"; shift; rm -rf "$d"; mkdir -p "$d" && chmod 700 "$d" || exit 1; ' + 'for o in "$@"; do grim -o "$o" -t jpeg -q 92 "$d/$o.jpg" & done; wait', "roselock-grab", root.shotDir].concat(Quickshell.screens.map(function(s) {
            return s.name;
        }));
        grab.running = true;
        failsafe.start();
    }

    Component.onCompleted: begin()

    Connections {
        function onReadyChanged() {
            root.begin();
        }

        target: Config
    }

    Process {
        id: grab

        onExited: (code, status) => {
            failsafe.stop();
            root.shotsOk = code === 0;
            root.armed = true;
        }
    }

    Timer {
        id: failsafe

        interval: 1500
        onTriggered: root.armed = true
    }

    Process {
        id: cleanup

        command: ["rm", "-rf", root.shotDir]
    }

    LockContext {
        id: lockCtx

        onUnlocked: {
            lock.locked = false;
            cleanup.running = true;
            quit.start();
        }
    }

    Timer {
        id: quit

        interval: 400
        onTriggered: Qt.quit()
    }

    WlSessionLock {
        id: lock

        locked: root.armed && !root.test

        WlSessionLockSurface {
            id: surf

            color: "black"

            LockSurface {
                anchors.fill: parent
                ctx: lockCtx
                shot: root.shotFor(surf.screen)
            }

        }

    }

    Loader {
        active: root.test

        sourceComponent: FloatingWindow {
            implicitWidth: 1280
            implicitHeight: 800
            color: "black"

            LockSurface {
                anchors.fill: parent
                ctx: lockCtx
            }

        }

    }

}
