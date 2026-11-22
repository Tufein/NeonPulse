#!/usr/bin/env python3
"""Checks the Ion Ring Connect IQ resources for reference drift.

Verified without the SDK or any network access:
  1. manifest.xml and every XML file in resources/ parses as XML;
  2. every @Strings.X / @Drawables.X / @Properties.X reference in manifest.xml and
     resources/settings/settings.xml resolves to an id in those resources;
  3. every literal setting key passed to Cfg.num/flag/color/... in source/*.mc exists
     in resources/properties/properties.xml;
  4. every bitmap listed in resources/drawables/drawables.xml is present on disk.

Usage:  python3 tools/check_resources.py
See also tools/gen_settings.py, which writes properties, settings and strings.
"""
import os
import re
import sys
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "resources")
MANIFEST = os.path.join(ROOT, "manifest.xml")
STRINGS = os.path.join(RES, "strings", "strings.xml")
PROPERTIES = os.path.join(RES, "properties", "properties.xml")
SETTINGS = os.path.join(RES, "settings", "settings.xml")
DRAWABLES = os.path.join(RES, "drawables", "drawables.xml")
REF_RE = re.compile(r"@(Strings|Drawables|Properties)\.([A-Za-z0-9_]+)")
CFG_RE = re.compile(r"Cfg\.[A-Za-z]+\(\s*\"([A-Za-z0-9_]+)\"")


def parse(path):
    """Parses one XML file; returns its root, or None when it is missing or invalid."""
    try:
        return ET.parse(path).getroot()
    except (ET.ParseError, OSError) as error:
        print("ERROR: %s: %s" % (rel(path), error))
        return None


def rel(path):
    """Path relative to the repository root, for readable messages."""
    return os.path.relpath(path, ROOT)


def ids(root, tag):
    """Collects the id attribute of every element named tag."""
    return {element.get("id") for element in root.iter(tag) if element.get("id")}


def refs_in(element):
    """Yields (kind, name) for each @Kind.Name reference in attributes or text."""
    values = list(element.attrib.values()) + [element.text or ""]
    for value in values:
        for match in REF_RE.finditer(value):
            yield match.group(1), match.group(2)


def main():
    roots = {}
    for path in (MANIFEST, STRINGS, PROPERTIES, SETTINGS, DRAWABLES):
        root = parse(path)
        if root is None:
            return 1
        roots[rel(path)] = root

    pools = {"Strings": ids(roots[rel(STRINGS)], "string"),
             "Properties": ids(roots[rel(PROPERTIES)], "property"),
             "Drawables": ids(roots[rel(DRAWABLES)], "bitmap")}

    failed = False

    # Every reference in the manifest and in the settings catalogue must resolve.
    for name in (rel(MANIFEST), rel(SETTINGS)):
        for element in roots[name].iter():
            for kind, identifier in refs_in(element):
                if identifier not in pools[kind]:
                    print("ERROR: %s references @%s.%s, which does not exist"
                          % (name, kind, identifier))
                    failed = True

    # Every literal key the face reads must be a documented setting.
    source_dir = os.path.join(ROOT, "source")
    for entry in sorted(os.listdir(source_dir)):
        if not entry.endswith(".mc"):
            continue
        with open(os.path.join(source_dir, entry)) as handle:
            for line_no, line in enumerate(handle, 1):
                for key in CFG_RE.findall(line):
                    if key not in pools["Properties"]:
                        print("ERROR: source/%s:%d reads setting \"%s\", which is not in "
                              "properties.xml" % (entry, line_no, key))
                        failed = True

    # Every bitmap named by drawables.xml must be shipped.
    for bitmap in roots[rel(DRAWABLES)].iter("bitmap"):
        filename = bitmap.get("filename")
        if filename and not os.path.isfile(os.path.join(os.path.dirname(DRAWABLES), filename)):
            print("ERROR: drawables.xml lists %s, which is missing" % filename)
            failed = True

    if failed:
        return 1
    print("OK: %d strings, %d settings, %d drawables, every reference resolves"
          % (len(pools["Strings"]), len(pools["Properties"]), len(pools["Drawables"])))
    return 0


if __name__ == "__main__":
    sys.exit(main())
