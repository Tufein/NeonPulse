#!/usr/bin/env python3
"""Generates every face of the watchface series from one table.

For each face in FACES it writes, under series/faces/<id>/:
  manifest.xml, monkey.jungle, resources/strings/strings.xml,
  resources/properties/properties.xml, resources/settings/settings.xml,
  resources/drawables/drawables.xml and resources/drawables/launcher_icon.png

Usage:
  python3 series/tools/series.py                 write all faces
  python3 series/tools/series.py --check         fail when the files are out of date (CI)
  python3 series/tools/series.py --sdk-devices DIR
        keep only device ids that exist in the Connect IQ SDK device folder, e.g.
        "$HOME/Library/Application Support/Garmin/ConnectIQ/Devices" on macOS,
        and print each id with its screen size, shape and display type.

Source code lives in series/common/source (shared) and series/faces/<id>/source.
"""
import argparse
import io
import json
import os
import sys
from xml.sax.saxutils import escape

HERE = os.path.dirname(os.path.abspath(__file__))
SERIES = os.path.dirname(HERE)
FACES_DIR = os.path.join(SERIES, "faces")

# Devices. Priority: Fenix 8 and Venu (requested), then watches that share the same
# screen sizes, so the scaled layouts work without extra work.
#   AMOLED round 390 / 416 / 454, MIP round 260 / 280, Venu X1 rectangle 448x486.
DEVICES = [
    # Fenix 8 family
    "fenix843mm", "fenix847mm", "fenix8solar47mm", "fenix8solar51mm",
    "fenix8pro47mm", "fenixe", "enduro3",
    # Venu family
    "venu3", "venu3s", "venu441mm", "venu445mm", "venux1",
    # Same screens, little extra effort
    "fr970", "fr57042mm", "fr57047mm", "fr965", "fr265", "fr165",
    "vivoactive6", "vivoactive5",
    "epix2pro42mm", "epix2pro47mm", "epix2pro51mm",
]

FIELDS = ["None", "Battery", "Heart rate", "Steps", "Calories", "Active minutes",
          "Body battery", "Floors", "Distance", "Stress", "Altitude", "Temperature",
          "Notifications", "Next sunrise/sunset"]
COLORS = ["White", "Mint", "Red", "Amber", "Blue", "Pink", "Purple", "Orange",
          "Yellow", "Grey"]
TIME_FORMAT = ("TimeFormat", "Time format", "list", 0, ["Watch setting", "12 hour", "24 hour"])


def seconds(default):
    return ("ShowSeconds", "Show seconds (awake only)", "boolean", default, None)


# (id, title, kind, default, options); option lists become @Strings entries.
FACES = [
    {
        "id": "bitlevel", "name": "Bitlevel", "uuid": "c5d46609-4387-4f53-9086-923afee79efe",
        "icon": ("pixel", 0x00E5A0),
        "settings": [
            ("AccentColor", "XP bar color", "list", 1, COLORS),
            ("HeartColor", "Heart color", "list", 2, COLORS),
            ("XpField", "XP bar", "list", 3, FIELDS),
            ("Field1", "Left stat", "list", 2, FIELDS),
            ("Field2", "Right stat", "list", 6, FIELDS),
            seconds(False), TIME_FORMAT,
        ],
    },
    {
        "id": "ridgeline", "name": "Ridgeline", "uuid": "4301c24b-2108-4ad6-b923-b6c3759064e8",
        "icon": ("ridge", 0xFFB000),
        "settings": [
            ("AccentColor", "Accent color", "list", 3, COLORS),
            ("Sky", "Sky", "list", 0, ["Black", "Night blue"]),
            ("Field1", "Left field", "list", 10, FIELDS),
            ("Field2", "Middle field", "list", 13, FIELDS),
            ("Field3", "Right field", "list", 11, FIELDS),
            seconds(False), TIME_FORMAT,
        ],
    },
    {
        "id": "meridian", "name": "Meridian Chrono", "uuid": "121fbc93-470f-4fe8-8d50-a2e35746ae9a",
        "icon": ("dial", 0xFF7A1A),
        "settings": [
            ("AccentColor", "Accent color", "list", 7, COLORS),
            ("DialColor", "Dial", "list", 0, ["Black", "Navy", "Bronze", "Slate"]),
            ("Field1", "Left sub-dial", "list", 1, FIELDS),
            ("Field2", "Right sub-dial", "list", 3, FIELDS),
            ("Field3", "Bottom sub-dial", "list", 2, FIELDS),
            seconds(True),
        ],
    },
    {
        "id": "stacked", "name": "Stacked Hours", "uuid": "a1ecb1f9-85c2-4585-a467-06a52603b845",
        "icon": ("stack", 0x2FA8FF),
        "settings": [
            ("AccentColor", "Hours color", "list", 4, COLORS),
            ("MinuteColor", "Minutes color", "list", 0, COLORS),
            ("Field1", "Upper field", "list", 3, FIELDS),
            ("Field2", "Lower field", "list", 2, FIELDS),
            seconds(False), TIME_FORMAT,
        ],
    },
    {
        "id": "gridwork", "name": "Gridwork", "uuid": "e50b5620-8705-467f-87cf-1dad6bd0a37e",
        "icon": ("grid", 0x00E5A0),
        "settings": [
            ("AccentColor", "Accent color", "list", 1, COLORS),
            ("Field1", "Tile 1 (top left)", "list", 3, FIELDS),
            ("Field2", "Tile 2 (top middle)", "list", 2, FIELDS),
            ("Field3", "Tile 3 (top right)", "list", 6, FIELDS),
            ("Field4", "Tile 4 (bottom left)", "list", 4, FIELDS),
            ("Field5", "Tile 5 (bottom middle)", "list", 11, FIELDS),
            ("Field6", "Tile 6 (bottom right)", "list", 13, FIELDS),
            seconds(False), TIME_FORMAT,
        ],
    },
    {
        "id": "sunpath", "name": "Sunpath 24", "uuid": "a13b9cd7-97ea-4d9f-b691-c2ccfab6edfc",
        "icon": ("sun", 0xFFB000),
        "settings": [
            ("AccentColor", "Daylight color", "list", 3, COLORS),
            ("Field1", "Bottom field", "list", 1, FIELDS),
            seconds(False), TIME_FORMAT,
        ],
    },
]

JUNGLE = """project.manifest = manifest.xml
# Shared series code first, then this face's own code and resources.
base.sourcePath = ../../common/source;source
base.resourcePath = resources
"""


def manifest(face, devices):
    products = "\n".join('            <iq:product id="%s"/>' % d for d in devices)
    return """<?xml version="1.0"?>
<!-- Generated by series/tools/series.py. Edit the FACES table there, not this file. -->
<iq:manifest xmlns:iq="http://www.garmin.com/xml/connectiq" version="3">
    <iq:application entry="SeriesApp" id="%s" launcherIcon="@Drawables.LauncherIcon" minApiLevel="4.2.0" name="@Strings.AppName" type="watchface">
        <iq:products>
%s
        </iq:products>
        <iq:permissions>
            <iq:uses-permission id="SensorHistory"/>
        </iq:permissions>
        <iq:languages>
            <iq:language>eng</iq:language>
        </iq:languages>
        <iq:barrels/>
    </iq:application>
</iq:manifest>
""" % (face["uuid"], products)


def resources(face):
    """Returns (strings, properties, settings) XML for one face."""
    strings = [("AppName", face["name"])]
    option_ids = {}

    def option(text):
        if text not in option_ids:
            option_ids[text] = "Opt%d" % len(option_ids)
            strings.append((option_ids[text], text))
        return option_ids[text]

    props, sets = [], []
    for key, title, kind, default, options in face["settings"]:
        strings.append((key, title))
        if kind == "boolean":
            props.append('<property id="%s" type="boolean">%s</property>' % (key, str(default).lower()))
            sets.append('<setting propertyKey="@Properties.%s" title="@Strings.%s">'
                        '<settingConfig type="boolean"/></setting>' % (key, key))
        else:
            props.append('<property id="%s" type="number">%d</property>' % (key, default))
            entries = "\n".join('<listEntry value="%d">@Strings.%s</listEntry>' % (i, option(o))
                                for i, o in enumerate(options))
            sets.append('<setting propertyKey="@Properties.%s" title="@Strings.%s">'
                        '<settingConfig type="list">\n%s\n</settingConfig></setting>' % (key, key, entries))
    s = "<strings>\n%s\n</strings>\n" % "\n".join(
        '<string id="%s">%s</string>' % (i, escape(t)) for i, t in strings)
    p = "<properties>\n%s\n</properties>\n" % "\n".join(props)
    st = "<settings>\n%s\n</settings>\n" % "\n".join(sets)
    return s, p, st


DRAWABLES = """<drawables>
    <bitmap id="LauncherIcon" filename="launcher_icon.png"/>
</drawables>
"""


def icon_png(kind, color):
    """Draws a 70x70 launcher icon; returns PNG bytes (needs Pillow)."""
    from PIL import Image, ImageDraw
    size, k = 70, 4  # draw at 4x and downscale for smooth edges
    big = size * k
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rgb = ((color >> 16) & 255, (color >> 8) & 255, color & 255, 255)
    white = (255, 255, 255, 255)
    d.ellipse([0, 0, big - 1, big - 1], fill=(14, 17, 22, 255))
    c = big // 2
    if kind == "pixel":
        p = 18
        heart = ["0110110", "1111111", "1111111", "0111110", "0011100", "0001000"]
        x0, y0 = c - 7 * p // 2, c - 3 * p
        for r, row in enumerate(heart):
            for col, ch in enumerate(row):
                if ch == "1":
                    d.rectangle([x0 + col * p, y0 + r * p, x0 + col * p + p - 2, y0 + r * p + p - 2],
                                fill=(255, 59, 92, 255))
        d.rectangle([c - 90, c + 70, c + 90, c + 90], fill=rgb)
    elif kind == "ridge":
        d.ellipse([c + 20, c - 90, c + 70, c - 40], fill=(255, 200, 48, 255))
        d.polygon([(10, c + 60), (c - 60, c - 30), (c - 20, c + 10), (c + 30, c - 50),
                   (big - 10, c + 60), (big - 30, big - 60), (30, big - 60)], fill=rgb)
    elif kind == "dial":
        d.ellipse([30, 30, big - 30, big - 30], outline=white, width=10)
        d.line([c, c, c, 60], fill=white, width=14)
        d.line([c, c, c + 70, c + 30], fill=rgb, width=14)
        d.ellipse([c - 14, c - 14, c + 14, c + 14], fill=rgb)
    elif kind == "stack":
        d.rectangle([c - 70, 50, c - 10, 130], fill=rgb)
        d.rectangle([c + 10, 50, c + 70, 130], fill=rgb)
        d.rectangle([c - 70, 150, c - 10, 230], fill=white)
        d.rectangle([c + 10, 150, c + 70, 230], fill=white)
    elif kind == "grid":
        w, g = 56, 10
        x0, y0 = c - (3 * w + 2 * g) // 2, c - (2 * w + g) // 2
        for i in range(6):
            x, y = x0 + (i % 3) * (w + g), y0 + (i // 3) * (w + g)
            d.rounded_rectangle([x, y, x + w, y + w], radius=10, fill=(40, 46, 56, 255))
            d.rectangle([x + 8, y + 8, x + w - 8, y + 16], fill=rgb)
    elif kind == "sun":
        d.ellipse([24, 24, big - 24, big - 24], outline=(22, 36, 74, 255), width=22)
        d.arc([24, 24, big - 24, big - 24], start=200, end=340, fill=rgb, width=22)
        d.ellipse([c - 22, 6, c + 22, 50], fill=(255, 216, 74, 255))
    img = img.resize((size, size), Image.LANCZOS)
    out = io.BytesIO()
    img.save(out, format="PNG", optimize=True)
    return out.getvalue()


def sdk_devices(path):
    """Reads compiler.json of each SDK device; returns {id: description}."""
    found = {}
    for dev in sorted(os.listdir(path)):
        cfg = os.path.join(path, dev, "compiler.json")
        if not os.path.isfile(cfg):
            continue
        try:
            with open(cfg) as f:
                data = json.load(f)
        except (OSError, ValueError):
            continue
        res = data.get("resolution", {})
        found[dev] = "%sx%s %s %s" % (res.get("width", "?"), res.get("height", "?"),
                                     data.get("deviceFamily", ""), data.get("displayType", ""))
    return found


def outputs(devices):
    """Every generated file: {path: bytes}."""
    files = {}
    for face in FACES:
        base = os.path.join(FACES_DIR, face["id"])
        res = os.path.join(base, "resources")
        s, p, st = resources(face)
        files[os.path.join(base, "manifest.xml")] = manifest(face, devices).encode()
        files[os.path.join(base, "monkey.jungle")] = JUNGLE.encode()
        files[os.path.join(res, "strings", "strings.xml")] = s.encode()
        files[os.path.join(res, "properties", "properties.xml")] = p.encode()
        files[os.path.join(res, "settings", "settings.xml")] = st.encode()
        files[os.path.join(res, "drawables", "drawables.xml")] = DRAWABLES.encode()
    return files


def missing_keys():
    """Setting keys read in a face's source (Kit.num/flag/color) that the face does not define."""
    import re
    pat = re.compile(r'Kit\.(?:num|flag|color)\(\s*"([A-Za-z0-9_]+)"')
    problems = []
    common = os.path.join(SERIES, "common", "source")
    shared = set()
    for fn in os.listdir(common):
        shared |= set(pat.findall(open(os.path.join(common, fn)).read()))
    for face in FACES:
        keys = {s[0] for s in face["settings"]}
        src = os.path.join(FACES_DIR, face["id"], "source")
        used = set(shared)
        consts = set()
        for fn in os.listdir(src):
            text = open(os.path.join(src, fn)).read()
            used |= set(pat.findall(text))
            # KEYS arrays such as ["Field1", "Field2"] passed to Kit.num(KEYS[i])
            consts |= set(re.findall(r'"(Field[0-9])"', text))
        used |= consts
        for k in sorted(used - keys):
            # TimeFormat falls back to the watch setting when a face has no such option.
            if k != "TimeFormat":
                problems.append("%s: setting %s is read but not defined" % (face["id"], k))
    return problems


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true", help="fail when generated files are out of date")
    ap.add_argument("--sdk-devices", help="Connect IQ SDK Devices folder; drops unknown device ids")
    args = ap.parse_args()

    devices = list(DEVICES)
    if args.sdk_devices:
        known = sdk_devices(args.sdk_devices)
        for d in DEVICES:
            print("%-18s %s" % (d, known.get(d, "NOT IN SDK - skipped")))
        devices = [d for d in DEVICES if d in known]

    files = outputs(devices)
    stale = []
    for path, data in sorted(files.items()):
        old = open(path, "rb").read() if os.path.exists(path) else None
        if old == data:
            continue
        stale.append(os.path.relpath(path, SERIES))
        if not args.check:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "wb") as f:
                f.write(data)
    if not args.check:
        # Icons are binary and only (re)drawn when missing, so CI does not need Pillow.
        for face in FACES:
            png = os.path.join(FACES_DIR, face["id"], "resources", "drawables", "launcher_icon.png")
            if not os.path.exists(png):
                kind, color = face["icon"]
                with open(png, "wb") as f:
                    f.write(icon_png(kind, color))
                stale.append(os.path.relpath(png, SERIES))
    problems = missing_keys()
    for msg in problems:
        print("ERROR: " + msg)
    if problems:
        return 1
    if args.check and stale and not args.sdk_devices:
        print("Out of date, run python3 series/tools/series.py:\n  " + "\n  ".join(stale))
        return 1
    for s in stale:
        print(("stale: " if args.check else "wrote: ") + s)
    return 0


if __name__ == "__main__":
    sys.exit(main())
