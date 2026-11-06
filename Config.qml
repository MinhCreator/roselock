import QtQuick
import Quickshell
import Quickshell.Io
import "toml.js" as Toml
pragma Singleton

Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/roselock"
    readonly property string path: dir + "/config.toml"
    property var data: ({
    })
    property bool ready: false
    readonly property var general: data.general || ({
    })
    readonly property var weather: data.weather || ({
    })
    readonly property var media: data.media || ({
    })
    readonly property var status: data.status || ({
    })
    readonly property string input: general.input === "pin" ? "pin" : "password"
    readonly property bool keypad: general.keypad === true
    readonly property real clockGap: general.clock_gap !== undefined ? Number(general.clock_gap) : 0.06
    readonly property int pinLength: Number(general.pin_length || 0)
    readonly property string font: general.font || "Google Sans"
    readonly property string md3Mode: general.md3_mode === "light" ? "light" : "dark"
    readonly property string md3Seed: general.md3_seed || "wallpaper"
    readonly property string md3Wallpaper: general.md3_wallpaper || ""
    readonly property string md3WallpaperCmd: general.md3_wallpaper_cmd || ""
    readonly property real blur: general.blur !== undefined ? Number(general.blur) : 64
    readonly property real dim: general.dim !== undefined ? Number(general.dim) : 0.35
    readonly property bool hour24: general.hour24 === true
    readonly property string clockStyle: general.clock === "inline" ? "inline" : "stacked"
    readonly property bool transition: general.transition !== false
    readonly property int transitionMs: Math.max(150, Math.min(2000, Number(general.transition_ms || 550)))
    readonly property bool screenshot: general.screenshot !== false
    readonly property int screenOffSec: Math.max(0, Math.round(general.screen_off_timeout !== undefined ? Number(general.screen_off_timeout) : 60))
    readonly property string screenOffCmd: general.screen_off_cmd || ""
    readonly property string screenOnCmd: general.screen_on_cmd || ""
    readonly property int idleTimeout: Number(general.idle_timeout || 20)
    readonly property string pamConfig: general.pam_config || ""
    readonly property bool weatherOn: weather.enabled !== false
    readonly property string weatherLoc: weather.location || ""
    readonly property int weatherCacheMin: Math.max(1, Math.round(Number(weather.cache_minutes || 30)))
    readonly property bool weatherPlace: weather.show_place === true
    readonly property bool imperial: weather.units === "imperial"
    readonly property bool mediaOn: media.enabled !== false
    readonly property bool statusOn: status.enabled !== false
    readonly property string defaultText: ["[general]", "input = \"password\"       # password = text field | pin = row of dots (keyboard typing works in both)", "keypad = false           # true = show the on-screen number keypad under the field", "pin_length = 0           # >0: show N slots and auto-submit after N digits", "font = \"Google Sans\"", "md3_mode = \"dark\"        # dark | light (dark reads best over wallpapers)", "md3_seed = \"wallpaper\"   # \"wallpaper\" or a hex colour like \"#6750A4\"", "md3_wallpaper = \"\"       # force a wallpaper path", "md3_wallpaper_cmd = \"\"   # command that prints the wallpaper path", "blur = 64                # blur while unlocking, 0 = off", "dim = 0.35               # wallpaper dimming 0..1", "hour24 = false", "clock = \"stacked\"        # stacked | inline", "clock_gap = 0.06         # space between the hour and minute rows, as a fraction of the digit size", "idle_timeout = 20        # seconds before the keypad hides again", "screenshot = true        # grab the desktop before locking so unlock can fade (and deblur) into it; needs grim", "screen_off_timeout = 60  # seconds of no input before the screens turn off while locked, 0 = never", "transition = true        # animate into the desktop on unlock (blur + dim fade out, clock lifts away)", "transition_ms = 550      # length of that animation", "pam_config = \"\"          # \"\" = bundled pam/password.conf, or a name from /etc/pam.d (e.g. \"login\")", "", "[weather]", "enabled = true", "location = \"\"", "show_place = false        # also show the city name next to the temperature", "cache_minutes = 30        # reuse the last reading this long before asking the server again", "units = \"metric\"         # metric | imperial", "", "[media]", "enabled = true", "", "[status]", "enabled = true", ""].join("\n")

    FileView {
        id: fv

        path: root.path
        onLoaded: {
            root.data = Toml.parse(text());
            root.ready = true;
        }
        onLoadFailed: {
            root.ready = true;
            mk.running = true;
        }
    }

    Process {
        id: mk

        command: ["sh", "-c", "mkdir -p '" + root.dir + "' && [ -f '" + root.path + "' ] || cat > '" + root.path + "' <<'ROSELOCK_EOF'\n" + root.defaultText + "ROSELOCK_EOF"]
    }

}
