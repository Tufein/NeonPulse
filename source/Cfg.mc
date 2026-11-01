import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;

// Reads user settings and maps palette indexes to colors.
module Cfg {
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

    function num(key as String, def as Number) as Number {
        var v = null;
        try {
            v = Application.Properties.getValue(key);
        } catch (e) {
            v = null;
        }
        return (v instanceof Number) ? v : def;
    }

    function flag(key as String, def as Boolean) as Boolean {
        var v = null;
        try {
            v = Application.Properties.getValue(key);
        } catch (e) {
            v = null;
        }
        return (v instanceof Boolean) ? v : def;
    }

    function color(key as String) as Number {
        var i = num(key, 0);
        if (i < 0 || i >= PALETTE.size()) {
            i = 0;
        }
        return PALETTE[i];
    }

    // Darkens a color (f from 0.0 to 1.0) for gauge tracks.
    function dim(c as Number, f as Float) as Number {
        var r = (((c >> 16) & 0xFF) * f).toNumber();
        var g = (((c >> 8) & 0xFF) * f).toNumber();
        var b = ((c & 0xFF) * f).toNumber();
        return (r << 16) | (g << 8) | b;
    }
}
