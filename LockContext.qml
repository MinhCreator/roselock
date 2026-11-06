import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

Scope {
    id: root

    property string text: ""
    property bool authing: false
    property bool unlocking: false
    property bool screenOn: true
    property var offNames: []
    property string error: ""
    property int shake: 0
    property bool fallback: false
    readonly property bool busy: pam.active
    readonly property bool pin: Config.input === "pin"
    readonly property bool custom: Config.pamConfig !== ""

    signal unlocked()

    function powerScript(on) {
        if (on && Config.screenOnCmd !== "")
            return Config.screenOnCmd;

        if (!on && Config.screenOffCmd !== "")
            return Config.screenOffCmd;

        var mm = on ? "enable_monitor" : "disable_monitor", fl = on ? "--on" : "--off";
        return 'if command -v mmsg >/dev/null 2>&1; then for o in "$@"; do mmsg dispatch ' + mm + ',"$o" || mmsg -d ' + mm + ',"$o"; done; ' + 'elif command -v wlopm >/dev/null 2>&1; then wlopm ' + fl + " '*'; " + 'else for o in "$@"; do wlr-randr --output "$o" ' + fl + '; done; fi';
    }

    function runPower(on, names) {
        var proc = on ? onProc : offProc;
        proc.command = ["sh", "-c", powerScript(on), "roselock-dpms"].concat(names);
        proc.running = true;
    }

    function wakeScreen() {
        if (screenOn)
            return false;

        screenOn = true;
        runPower(true, offNames);
        return true;
    }

    function sleepScreen() {
        if (Config.screenOffSec <= 0 || unlocking || busy || !screenOn)
            return ;

        offNames = Quickshell.screens.map(function(s) {
            return s.name;
        });
        screenOn = false;
        runPower(false, offNames);
    }

    function activity() {
        if (wakeScreen()) {
            screenTimer.restart();
            return true;
        }
        if (Config.screenOffSec > 0 && !unlocking)
            screenTimer.restart();

        return false;
    }

    function open() {
        authing = true;
        idle.restart();
    }

    function poke() {
        if (authing)
            idle.restart();

    }

    function back() {
        if (busy || unlocking)
            return ;

        authing = false;
        text = "";
        error = "";
        idle.stop();
    }

    function type(ch) {
        if (busy || unlocking)
            return ;

        open();
        error = "";
        text += ch;
        if (pin && Config.pinLength > 0 && text.length >= Config.pinLength)
            submit();

    }

    function backspace() {
        if (busy || unlocking)
            return ;

        open();
        error = "";
        text = text.slice(0, -1);
    }

    function clear() {
        if (busy || unlocking)
            return ;

        text = "";
        error = "";
    }

    function submit() {
        if (busy || unlocking || text === "")
            return ;

        error = "";
        idle.restart();
        pam.start();
    }

    Component.onCompleted: {
        if (Config.screenOffSec > 0) {
            screenTimer.start();
        }
    }

    PamContext {
        id: pam

        configDirectory: (root.custom || root.fallback) ? "/etc/pam.d" : Quickshell.shellPath("pam")
        config: root.custom ? Config.pamConfig : (root.fallback ? "login" : "password.conf")
        onPamMessage: {
            if (responseRequired)
                respond(root.text);

        }
        onCompleted: (result) => {
            if (result === PamResult.Success) {
                root.error = "";
                root.unlocking = true;
                idle.stop();
                screenTimer.stop();
                if (Config.transition)
                    finish.start();
                else
                    root.unlocked();
                return ;
            }
            root.error = result === PamResult.MaxTries ? "Too many attempts" : (root.pin ? "Wrong PIN" : "Wrong password");
            root.text = "";
            root.shake++;
        }
        onError: {
            console.warn("roselock: PAM error with " + configDirectory + "/" + config);
            if (!root.custom && !root.fallback) {
                root.fallback = true;
                retry.start();
                return ;
            }
            root.error = "Authentication error";
            root.text = "";
            root.shake++;
        }
    }

    Timer {
        id: retry

        interval: 30
        onTriggered: {
            if (root.text !== "")
                pam.start();

        }
    }

    Process {
        id: offProc

        onExited: (code, status) => {
            return console.log("roselock: screen off command exited with " + code);
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    console.warn("roselock: screen off: " + text.trim());
                }
            }
        }

    }

    Process {
        id: onProc

        onExited: (code, status) => {
            return console.log("roselock: screen on command exited with " + code);
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    console.warn("roselock: screen on: " + text.trim());
                }
            }
        }

    }

    IdleMonitor {
        timeout: Math.max(5, Config.screenOffSec)
        enabled: Config.screenOffSec > 0 && !root.unlocking
        respectInhibitors: false
        onIsIdleChanged: {
            if (isIdle)
                root.sleepScreen();
            else
                root.wakeScreen();
        }
    }

    Timer {
        id: screenTimer

        interval: Math.max(5, Config.screenOffSec) * 1000
        onTriggered: root.sleepScreen()
    }

    Timer {
        id: finish

        interval: Config.transitionMs + 80
        onTriggered: root.unlocked()
    }

    Timer {
        id: idle

        interval: Math.max(5, Config.idleTimeout) * 1000
        onTriggered: root.back()
    }

}
