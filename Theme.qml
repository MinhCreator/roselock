import QtQuick
import Quickshell
import Quickshell.Io
import "md3.js" as Md3
pragma Singleton

Singleton {
    id: root

    readonly property var typeScale: ({
        "displayLarge": {
            "size": 57,
            "weight": Font.Normal,
            "ls": -0.25
        },
        "displayMedium": {
            "size": 45,
            "weight": Font.Normal,
            "ls": 0
        },
        "displaySmall": {
            "size": 36,
            "weight": Font.Normal,
            "ls": 0
        },
        "headlineMedium": {
            "size": 28,
            "weight": Font.Normal,
            "ls": 0
        },
        "titleLarge": {
            "size": 22,
            "weight": Font.Normal,
            "ls": 0
        },
        "titleMedium": {
            "size": 16,
            "weight": Font.Medium,
            "ls": 0.15
        },
        "titleSmall": {
            "size": 14,
            "weight": Font.Medium,
            "ls": 0.1
        },
        "bodyLarge": {
            "size": 16,
            "weight": Font.Normal,
            "ls": 0.5
        },
        "bodyMedium": {
            "size": 14,
            "weight": Font.Normal,
            "ls": 0.25
        },
        "bodySmall": {
            "size": 12,
            "weight": Font.Normal,
            "ls": 0.4
        },
        "labelLarge": {
            "size": 14,
            "weight": Font.Medium,
            "ls": 0.1
        },
        "labelMedium": {
            "size": 12,
            "weight": Font.Medium,
            "ls": 0.5
        },
        "labelSmall": {
            "size": 11,
            "weight": Font.Medium,
            "ls": 0.5
        }
    })
    property string wallSeed: ""
    property string wallPath: ""
    property string lastKey: ""
    readonly property string seed: Config.md3Seed !== "wallpaper" ? Config.md3Seed : (wallSeed !== "" ? wallSeed : "#6750A4")
    readonly property bool dark: Config.md3Mode !== "light"
    readonly property var s: Md3.scheme(seed, dark)

    Component.onCompleted: {
        var t = "";
        try {
            t = lastFv.text();
        } catch (e) {
            t = "";
        }
        var L = t.split("\n");
        if (L.length > 1 && L[0].indexOf("|") > 0 && /^#[0-9a-fA-F]{6}$/.test(L[1].trim())) {
            wallPath = L[0].slice(0, L[0].lastIndexOf("|"));
            wallSeed = L[1].trim();
            lastKey = L[0];
        }
    }

    FileView {
        id: lastFv

        path: Quickshell.env("HOME") + "/.cache/rose/last.txt"
        blockLoading: true
        printErrors: false
    }

    Process {
        id: seedProc

        command: ["python3", Quickshell.shellPath("seed.py"), Config.md3Wallpaper, Config.md3WallpaperCmd, root.lastKey]

        stdout: StdioCollector {
            onStreamFinished: {
                var L = text.split("\n");
                if (L[0] !== "")
                    root.wallPath = L[0].slice(0, L[0].lastIndexOf("|"));

                if (L.length > 1 && L[1].trim() !== "") {
                    root.wallSeed = L[1].trim();
                    root.lastKey = L[0];
                }
            }
        }

    }

    Timer {
        interval: 30
        running: Config.ready
        onTriggered: seedProc.running = true
    }

}
