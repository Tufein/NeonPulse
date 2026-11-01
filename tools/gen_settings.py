#!/usr/bin/env python3
"""Generates resources/properties, settings and strings XML for Neon Pulse.

Edit the tables below and run:  python3 tools/gen_settings.py
"""
import os
from xml.sax.saxutils import escape

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "resources")

ARCS = ["None", "Battery", "Heart rate", "Steps", "Calories", "Active minutes",
        "Body battery", "Floors", "Distance", "Stress"]
WIDGETS = ["None", "Temperature", "Battery", "Heart rate", "Steps", "Calories",
           "Body battery", "Floors", "Notifications", "Stress"]
COLORS = ["White", "Mint", "Red", "Amber", "Blue", "Pink", "Purple", "Orange",
          "Yellow", "Grey", "Custom color 1", "Custom color 2"]
SIZES = ["Small", "Medium", "Large"]

# (id, title, kind, default, options)
SETTINGS = [
    ("TopField", "Top arc", "list", 1, ARCS),
    ("TopColor", "Top arc color", "list", 1, COLORS),
    ("TopStyle", "Top arc style", "list", 0, ["Arc + value", "Value only", "Arc only"]),
    ("TopTextSize", "Top value size", "list", 1, SIZES),
    ("RightField", "Right arc", "list", 2, ARCS),
    ("RightColor", "Right arc color", "list", 2, COLORS),
    ("Left1Field", "Left arc 1 (outer)", "list", 5, ARCS),
    ("Left1Color", "Left arc 1 (outer) color", "list", 3, COLORS),
    ("Left2Field", "Left arc 2", "list", 3, ARCS),
    ("Left2Color", "Left arc 2 color", "list", 4, COLORS),
    ("Left3Field", "Left arc 3 (inner)", "list", 4, ARCS),
    ("Left3Color", "Left arc 3 (inner) color", "list", 5, COLORS),
    ("BottomField", "Bottom arc", "list", 6, ARCS),
    ("BottomColor", "Bottom arc color", "list", 1, COLORS),
    ("W1Field", "Widget 1 (left)", "list", 4, WIDGETS),
    ("W1Color", "Widget 1 (left) color", "list", 0, COLORS),
    ("W2Field", "Widget 2 (middle)", "list", 1, WIDGETS),
    ("W2Color", "Widget 2 (middle) color", "list", 3, COLORS),
    ("W3Field", "Widget 3 (right)", "list", 8, WIDGETS),
    ("W3Color", "Widget 3 (right) color", "list", 7, COLORS),
    ("WidgetRing", "Widget rings", "boolean", True, None),
    ("TimeColor", "Time color", "list", 0, COLORS),
    ("TimeSize", "Time size", "list", 0, ["Normal", "Large"]),
    ("TimeFormat", "Time format", "list", 0, ["Watch setting", "12 hour", "24 hour"]),
    ("DateColor", "Date color", "list", 0, COLORS),
    ("DateFormat", "Date format", "list", 0, ["SUN 1 NOV", "1 NOV", "01/11"]),
    ("ShowDate", "Show date", "boolean", True, None),
    ("LabelSize", "Label text size", "list", 1, SIZES),
    ("ShowUnits", "Show units", "boolean", True, None),
    ("ArcWidth", "Arc thickness", "list", 1, ["Thin", "Normal", "Thick"]),
    ("TickStyle", "Tick marks", "list", 0, ["All minutes", "Hours only", "None"]),
    ("TickColor", "Tick marks color", "list", 9, COLORS),
    ("ShowSeconds", "Seconds marker", "boolean", True, None),
    ("SecColor", "Seconds marker color", "list", 7, COLORS),
    ("BgColor", "Background", "list", 0, ["Black", "Charcoal", "Navy", "Plum", "Forest"]),
    ("CustomColor1", "Custom color 1 (hex RRGGBB)", "text", "00E5FF", None),
    ("CustomColor2", "Custom color 2 (hex RRGGBB)", "text", "FF00AA", None),
    ("CalorieGoal", "Calorie goal", "number", 2500, (500, 10000)),
    ("DistGoal", "Distance goal (km)", "number", 10, (1, 100)),
    ("HrMax", "Max heart rate", "number", 190, (120, 220)),
]

def main():
    strings = {"AppName": "Neon Pulse"}
    option_ids = {}  # option text -> string id (shared between settings)
    props, sets = [], []

    def opt_id(text):
        if text not in option_ids:
            option_ids[text] = "Opt%d" % len(option_ids)
            strings[option_ids[text]] = text
        return option_ids[text]

    for sid, title, kind, default, opts in SETTINGS:
        strings[sid] = title
        if kind == "list":
            props.append('<property id="%s" type="number">%d</property>' % (sid, default))
            entries = "".join('<listEntry value="%d">@Strings.%s</listEntry>\n' % (i, opt_id(o))
                              for i, o in enumerate(opts))
            sets.append('<setting propertyKey="@Properties.%s" title="@Strings.%s"><settingConfig type="list">\n%s</settingConfig></setting>' % (sid, sid, entries))
        elif kind == "boolean":
            props.append('<property id="%s" type="boolean">%s</property>' % (sid, "true" if default else "false"))
            sets.append('<setting propertyKey="@Properties.%s" title="@Strings.%s"><settingConfig type="boolean"/></setting>' % (sid, sid))
        elif kind == "number":
            props.append('<property id="%s" type="number">%d</property>' % (sid, default))
            sets.append('<setting propertyKey="@Properties.%s" title="@Strings.%s"><settingConfig type="numeric" min="%d" max="%d"/></setting>' % (sid, sid, opts[0], opts[1]))
        elif kind == "text":
            props.append('<property id="%s" type="string">%s</property>' % (sid, default))
            sets.append('<setting propertyKey="@Properties.%s" title="@Strings.%s"><settingConfig type="alphaNumeric" maxLength="7"/></setting>' % (sid, sid))

    def write(rel, body):
        with open(os.path.join(ROOT, rel), "w") as f:
            f.write(body)

    write("properties/properties.xml", "<properties>\n" + "\n".join(props) + "\n</properties>\n")
    write("settings/settings.xml", "<settings>\n" + "\n".join(sets) + "\n</settings>\n")
    write("strings/strings.xml", "<strings>\n" + "".join(
        '<string id="%s">%s</string>\n' % (k, escape(v)) for k, v in strings.items()) + "</strings>\n")

if __name__ == "__main__":
    main()
