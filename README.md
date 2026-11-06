# Roselock

Pixel/Material 3 lock screen for Quickshell + Wayland (ext-session-lock). Palette comes from your wallpaper (`seed.py`, same helper as Rosebar/Rosewidgets).

## Install
    cp -r roselock ~/.config/quickshell/roselock
    qs -c roselock            # locks immediately, exits on unlock

First run writes `~/.config/roselock/config.toml` (edit it, takes effect next lock).
Bind it, e.g. MangoWM: `bind=SUPER,l,spawn,qs -c roselock`, or idle-lock: `swayidle -w timeout 300 'qs -c roselock'`.

## Try it without locking
    ROSELOCK_TEST=1 qs -c roselock      # shows it in a normal window, any correct password closes it

## Unlock
- Click / swipe up / wheel / any key opens the entry view; `Esc` goes back, `Enter` submits, `Ctrl+U` clears.
- The on-screen keypad is **off by default**; set `keypad = true` under `[general]` to show it. `input = "password"` is a text field, `"pin"` a row of dots. Keyboard typing works in all combinations.
- `clock_gap` (default 0.06) tunes the space between the hour and minute rows.
- The keypad types into the normal PAM password prompt, so a numeric PIN only works if your account password is numeric. Use `pin_length = N` for auto-submit.
- `pam_config = ""` uses `pam/password.conf` (pam_unix). Set e.g. `"login"` to use /etc/pam.d/login instead.

## Notes
- Font defaults to Google Sans (set `font`). Needs Qt 6.6+ (CurveRenderer) and `curl`, `nmcli`, UPower for weather/status.
- Keep a TTY handy while testing a lock screen (Ctrl+Alt+F2, then `pkill quickshell`). On Hyprland a killed lock client leaves the session locked until you run `qs -c roselock` again.
- Weather uses `weather.py` (open-meteo, then wttr.in, then a cached reading) and needs only python3. Leave `location` empty to use your IP location.
- PAM: the bundled `pam/password.conf` is loaded by absolute path; if it fails, roselock retries once with the system `login` service.

## Unlock transition
On a correct password the lock screen no longer just vanishes: the icon turns into a check ("Welcome back"), the blur and dim fade out and the clock/entry lift away, so the last frame is your plain wallpaper, and only then is the session unlocked. It looks seamless when the desktop wallpaper is the same image (the lock screen crops it to fill the screen like most wallpaper daemons do). `transition = false` under `[general]` disables it, `transition_ms` (default 550) sets the length.

## Weather cache
`weather.py` keeps `~/.cache/roselock/weather.json`. A reading younger than `cache_minutes` (`[weather]`, default 30) is used with no network at all. An older one is shown immediately and refreshed in the background; the request is conditional (ETag / Last-Modified), so nothing is downloaded if the server's data hasn't changed. The location lookup is cached too (a day for a named place, 6h when located by IP). Offline, a reading up to 6h old is still shown.

## Unlock: screenshot fade
Before locking, roselock grabs each screen with `grim` into `$XDG_RUNTIME_DIR/roselock/` (tmpfs, 0700; deleted after unlock). On unlock that screenshot fades in while it de-blurs, so the last frame is your real desktop, windows and bar included, and the actual unlock changes nothing on screen. Locking waits for grim (~0.2s); if grim is missing or hangs for 1.5s it locks without a screenshot and falls back to the wallpaper fade. `screenshot = false` turns it off. Needs `grim` and a compositor with wlr-screencopy.

## Screen off while locked
After `screen_off_timeout` seconds (default **60**, on out of the box; `0` = never) without input the screens are switched off, and any key / click / mouse move switches them back on (the key that wakes them isn't typed into the field). Idle is detected on the seat (ext-idle-notify), not just on the lock surface, because on MangoWM an "off" output is torn down together with the lock surface on it, so input can't reach that surface any more.

Default commands, first one found wins: `mmsg dispatch disable_monitor,<output>` / `enable_monitor` (MangoWM) -> `wlopm --off '*'` -> `wlr-randr --output <o> --off`. To use something else set `screen_off_cmd` / `screen_on_cmd` under `[general]` (any shell command; the output names are in `"$@"`).
What happened is logged: run `qs -c roselock` from a terminal (or look at the Quickshell log) and you'll see `roselock: screen off command exited with N` plus any error text. Try `screen_off_timeout = 10` while testing.
If the screens ever stay black after roselock was killed, from a TTY: `mmsg dispatch enable_monitor,<name>` (Mango) or `wlopm --on '*'`.
