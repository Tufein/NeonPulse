import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;

// Reads user settings and maps list indexes to colors and sizes.
module Cfg {
    // Color list used by every "... color" setting. 10 and 11 are the two custom hex colors.
    const PALETTE = [
        0xFFFFFF, // White
        0x00E5A0, // Mint
        0xFF3B5C, // Red
        0xFFB000, // Amber
        0x2FA8FF, // Blue
        0xFF4FA3, // Pink
        0xB070FF, // Purple
        0xFF7A1A, // Orange
        0xFFE000, // Yellow
        0x808890  // Grey
    ];
    const CUSTOM_1 = 10;
    const CUSTOM_2 = 11;

    // Background list: Black, Charcoal, Navy, Plum, Forest.
    const BACKGROUNDS = [0x000000, 0x0E1116, 0x0A1028, 0x140A22, 0x07160F];

    // Theme presets, 11 colors each: top/bottom accent, right, left 1-3, widget 1-3,
    // time, tick/date and seconds. Row 0 is "Custom" (element colors) and unused.
    const THEME_COLORS = 11;
    const THEMES = [
        0xFFFFFF, 0xFFFFFF, 0xFFFFFF, 0xFFFFFF, 0xFFFFFF, 0xFFFFFF, 0xFFFFFF,
        0xFFFFFF, 0xFFFFFF, 0xFFFFFF, 0xFFFFFF, // Custom
        0x00E5FF, 0xFF00AA, 0xB070FF, 0x7C8CFF, 0x2FA8FF, 0x00E5A0, 0x00E5FF,
        0xFFB000, 0xFFFFFF, 0x5B6472, 0xFFB000, // Neon
        0xFF7A1A, 0xFF3B5C, 0xFFB000, 0xFF4FA3, 0xFF8A5C, 0xFFD166, 0xFF7A1A,
        0xFFE000, 0xFFFFFF, 0x6B5B5B, 0xFFE000, // Sunset
        0x7FDBFF, 0x4FA3FF, 0xA0E8D0, 0xC8F0FF, 0x6FC3FF, 0x8FE3FF, 0x7FDBFF,
        0xE8FBFF, 0xFFFFFF, 0x5A6B78, 0xE8FBFF, // Arctic
        0xFFFFFF, 0xC0C6CE, 0x8A9099, 0xA8AEB7, 0xD6DAE0, 0xFFFFFF, 0xE6E9ED,
        0xC0C6CE, 0xFFFFFF, 0x565C64, 0xFFFFFF  // Mono
    ];

    function value(key as String) as PropertyValueType? {
        try {
            return Application.Properties.getValue(key);
        } catch (e) {
            return null;
        }
    }

    function num(key as String, def as Number) as Number {
        var v = value(key);
        return (v instanceof Number) ? v : def;
    }

    function flag(key as String, def as Boolean) as Boolean {
        var v = value(key);
        return (v instanceof Boolean) ? v : def;
    }

    // Selected theme index; 0 means the per-element colors apply.
    function theme() as Number {
        var i = num("Theme", 0);
        return (i > 0 && i * THEME_COLORS < THEMES.size()) ? i : 0;
    }

    // Theme slot for an element color key; -1 when the key has no theme slot.
    function role(key as String) as Number {
        if (key.equals("TopColor") || key.equals("BottomColor")) { return 0; }
        if (key.equals("RightColor")) { return 1; }
        if (key.equals("Left1Color")) { return 2; }
        if (key.equals("Left2Color")) { return 3; }
        if (key.equals("Left3Color")) { return 4; }
        if (key.equals("W1Color")) { return 5; }
        if (key.equals("W2Color")) { return 6; }
        if (key.equals("W3Color")) { return 7; }
        if (key.equals("TimeColor")) { return 8; }
        if (key.equals("DateColor") || key.equals("TickColor")) { return 9; }
        if (key.equals("SecColor")) { return 10; }
        return -1;
    }

    function color(key as String) as Number {
        var t = theme();
        if (t > 0) {
            var r = role(key);
            if (r >= 0) { return THEMES[t * THEME_COLORS + r] as Number; }
        }
        var i = num(key, 0);
        if (i == CUSTOM_1) { return hex("CustomColor1", 0x00E5FF); }
        if (i == CUSTOM_2) { return hex("CustomColor2", 0xFF00AA); }
        if (i < 0 || i >= PALETTE.size()) { i = 0; }
        return PALETTE[i] as Number;
    }

    // Parses "RRGGBB" or "#RRGGBB"; returns def when the text is not a valid color.
    function hex(key as String, def as Number) as Number {
        var v = value(key);
        if (!(v instanceof String)) { return def; }
        var t = v as String;
        if (t.length() > 0 && t.substring(0, 1).equals("#")) { t = t.substring(1, t.length()) as String; }
        if (t.length() != 6) { return def; }
        var n = t.toNumberWithBase(16);
        return (n != null) ? n : def;
    }

    function background() as Number {
        var i = num("BgColor", 0);
        if (i < 0 || i >= BACKGROUNDS.size()) { i = 0; }
        return BACKGROUNDS[i] as Number;
    }

    // Small / Medium / Large list setting as a size factor.
    function scale(key as String) as Float {
        var i = num(key, 1);
        if (i == 0) { return 0.85; }
        if (i == 2) { return 1.18; }
        return 1.0;
    }

    // Thin / Normal / Thick arcs.
    function arcScale() as Float {
        var i = num("ArcWidth", 1);
        if (i == 0) { return 0.7; }
        if (i == 2) { return 1.4; }
        return 1.0;
    }

    // Darkens a color (f from 0.0 to 1.0) for gauge tracks and the always-on face.
    function dim(c as Number, f as Float) as Number {
        var r = (((c >> 16) & 0xFF) * f).toNumber();
        var g = (((c >> 8) & 0xFF) * f).toNumber();
        var b = ((c & 0xFF) * f).toNumber();
        return (r << 16) | (g << 8) | b;
    }
}
