"""Roselock weather helper. args: [location] [metric|imperial] [cache minutes]
Prints JSON lines: {"ok", "temp", "desc", "kind", "place", "stale"}; the last line is the one to use.

Cached so a lock doesn't hit the network every time:
  - a reading younger than the cache time is printed and that's it (no network at all);
  - an older one (<6h) is printed straight away marked "stale", then refreshed; the fresh reading is printed after it;
  - the forecast request is conditional (ETag / Last-Modified), so if the server says nothing changed nothing is downloaded;
  - the location lookup (geocoding or IP) is cached too (a day for a named place, 6h when located by IP).
Tries open-meteo, then wttr.in."""

import json, os, re, sys, time, urllib.error, urllib.parse, urllib.request

UA = {"User-Agent": "roselock/1.0"}
CACHE = os.path.join(
    os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"),
    "roselock",
    "weather.json",
)
WMO = {
    0: "Clear",
    1: "Mostly clear",
    2: "Partly cloudy",
    3: "Overcast",
    45: "Fog",
    48: "Fog",
    51: "Light drizzle",
    53: "Drizzle",
    55: "Heavy drizzle",
    56: "Freezing drizzle",
    57: "Freezing drizzle",
    61: "Light rain",
    63: "Rain",
    65: "Heavy rain",
    66: "Freezing rain",
    67: "Freezing rain",
    71: "Light snow",
    73: "Snow",
    75: "Heavy snow",
    77: "Snow grains",
    80: "Rain showers",
    81: "Rain showers",
    82: "Heavy showers",
    85: "Snow showers",
    86: "Snow showers",
    95: "Thunderstorm",
    96: "Thunderstorm",
    99: "Thunderstorm",
}


def get(url, t=6):
    with urllib.request.urlopen(
        urllib.request.Request(url, headers=UA), timeout=t
    ) as r:
        return json.loads(r.read().decode("utf-8", "replace"))


def kind_of(desc):
    d = desc.lower()
    if "thunder" in d:
        return "bolt"
    if re.search(r"snow|sleet|blizzard|ice", d):
        return "snow"
    if re.search(r"rain|drizzle|shower", d):
        return "rain"
    if re.search(r"fog|mist|haze", d):
        return "fog"
    if re.search(r"sun|clear", d):
        return "sun"
    return "cloud"


class NotModified(Exception):
    pass


def fetch(url, t=6, extra=None):
    req = urllib.request.Request(url, headers=dict(UA, **(extra or {})))
    try:
        with urllib.request.urlopen(req, timeout=t) as r:
            return json.loads(r.read().decode("utf-8", "replace")), r.headers
    except urllib.error.HTTPError as e:
        if e.code == 304:
            raise NotModified()
        raise


def locate(loc, cache):
    g = cache.get("geo") or {}
    ttl = 24 * 3600 if loc else 6 * 3600
    if g.get("loc") == loc and time.time() - g.get("t", 0) < ttl and "lat" in g:
        return g
    if loc:
        r = get(
            "https://geocoding-api.open-meteo.com/v1/search?count=1&name="
            + urllib.parse.quote(loc)
        )["results"][0]
        g = {"lat": r["latitude"], "lon": r["longitude"], "place": r["name"]}
    else:
        r = get("https://ipwho.is/")
        if r.get("success") is False:
            raise RuntimeError("geoip failed")
        g = {"lat": r["latitude"], "lon": r["longitude"], "place": r.get("city", "")}
    g.update({"loc": loc, "t": time.time()})
    cache["geo"] = g
    return g


def open_meteo(loc, imperial, cache, key):
    g = locate(loc, cache)
    url = (
        "https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=temperature_2m,weather_code"
        "&temperature_unit=%s"
        % (g["lat"], g["lon"], "fahrenheit" if imperial else "celsius")
    )
    fc = cache.get("fc") or {}
    hdr = {}
    if fc.get("url") == url and cache.get("key") == key and cache.get("out"):
        if fc.get("etag"):
            hdr["If-None-Match"] = fc["etag"]
        if fc.get("lm"):
            hdr["If-Modified-Since"] = fc["lm"]
    try:
        j, h = fetch(url, extra=hdr)
    except NotModified:
        return cache["out"]
    cache["fc"] = {"url": url, "etag": h.get("ETag"), "lm": h.get("Last-Modified")}
    c = j["current"]
    desc = WMO.get(int(c["weather_code"]), "Cloudy")
    return {
        "temp": "%d\u00b0" % round(c["temperature_2m"]),
        "desc": desc,
        "kind": kind_of(desc),
        "place": g["place"],
    }


def wttr(loc, imperial, cache, key):
    j = get("https://wttr.in/%s?format=j1" % urllib.parse.quote(loc))
    c = j["current_condition"][0]
    desc = c["weatherDesc"][0]["value"]
    try:
        place = j["nearest_area"][0]["areaName"][0]["value"]
    except Exception:
        place = loc
    return {
        "temp": "%s\u00b0" % (c["temp_F"] if imperial else c["temp_C"]),
        "desc": desc,
        "kind": kind_of(desc),
        "place": place,
    }


def load():
    try:
        return json.load(open(CACHE))
    except Exception:
        return {}


def save(c):
    try:
        os.makedirs(os.path.dirname(CACHE), exist_ok=True)
        tmp = CACHE + ".tmp"
        json.dump(c, open(tmp, "w"))
        os.replace(tmp, CACHE)
    except Exception:
        pass


def emit(out, stale):
    print(json.dumps(dict(out, ok=True, stale=stale)), flush=True)


def main():
    loc, units, mins = (sys.argv[1:4] + ["", "", ""])[:3]
    imperial = units == "imperial"
    try:
        ttl = max(1, int(float(mins or 30))) * 60
    except ValueError:
        ttl = 1800
    key = "%s|%s" % (loc, units)
    cache = load()
    have = cache.get("out") if cache.get("key") == key else None
    age = time.time() - cache.get("t", 0)
    if have and age < ttl:
        emit(have, False)
        return
    shown = False
    if have and age < 6 * 3600:
        emit(have, True)
        shown = True
    for fn in (open_meteo, wttr):
        try:
            out = fn(loc, imperial, cache, key)
            cache.update({"key": key, "t": time.time(), "out": out})
            save(cache)
            emit(out, False)
            return
        except Exception:
            continue
    if not shown:
        print(json.dumps({"ok": False}))


if __name__ == "__main__":
    main()
