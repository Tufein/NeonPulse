import Toybox.Activity;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Weather;

// Shared helpers for every face in the series: settings, colors, screen geometry,
// time and date text, vector fonts, arcs and sunrise/sunset.
// Layout units: every face is designed on a 454x454 round screen. Screen.s scales
// those units to the real display (390, 416, 260, 280, or 448x486 on the Venu X1).
module Kit {
    // Color list used by every "... color" setting.
    const PALETTE = [
        0xFFFFFF, // 0 White
        0x00E5A0, // 1 Mint
        0xFF3B5C, // 2 Red
        0xFFB000, // 3 Amber
        0x2FA8FF, // 4 Blue
        0xFF4FA3, // 5 Pink
        0xB070FF, // 6 Purple
        0xFF7A1A, // 7 Orange
        0xFFE000, // 8 Yellow
        0x808890  // 9 Grey
    ];

    // ---- settings ------------------------------------------------------------

    function prop(key as String) as PropertyValueType? {
        try {
            return Application.Properties.getValue(key);
        } catch (e) {
            return null;
        }
    }

    function num(key as String, def as Number) as Number {
        var v = prop(key);
        return (v instanceof Number) ? v : def;
    }

    function flag(key as String, def as Boolean) as Boolean {
        var v = prop(key);
        return (v instanceof Boolean) ? v : def;
    }

    // Palette color for a list setting; def is the palette index used when unset.
    function color(key as String, def as Number) as Number {
        var i = num(key, def);
        if (i < 0 || i >= PALETTE.size()) { i = def; }
        return PALETTE[i] as Number;
    }

    // Darkens a color, f from 0.0 (black) to 1.0 (unchanged).
    function dim(c as Number, f as Float) as Number {
        var r = (((c >> 16) & 0xFF) * f).toNumber();
        var g = (((c >> 8) & 0xFF) * f).toNumber();
        var b = ((c & 0xFF) * f).toNumber();
        return (r << 16) | (g << 8) | b;
    }

    // True on AMOLED screens (Fenix 8 AMOLED, Venu, Forerunner); false on MIP
    // (Fenix 8 Solar, Enduro 3), which never need burn-in protection.
    function amoled() as Boolean {
        var ds = System.getDeviceSettings();
        return (ds has :requiresBurnInProtection) && ds.requiresBurnInProtection;
    }

    // ---- geometry --------------------------------------------------------------

    // Screen geometry of the current Dc. Round and rectangular screens share one layout:
    // s scales from the 454 design size by the shorter side, and the face is centered.
    class Screen {
        var w as Number;
        var h as Number;
        var cx as Number;
        var cy as Number;
        var r as Number;      // radius of the largest centered circle
        var s as Float;       // design units (454) to pixels
        var round as Boolean;

        function initialize(dc as Dc) {
            w = dc.getWidth();
            h = dc.getHeight();
            cx = w / 2;
            cy = h / 2;
            var m = (w < h) ? w : h;
            r = m / 2;
            s = m / 454.0;
            round = System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND;
        }

        // Design units to whole pixels.
        function n(v as Numeric) as Number {
            return (v * s).toNumber();
        }

        // Half the usable width at design offset dy from the center: the circle's chord
        // on round screens, the full width on rectangular ones.
        function halfWidth(dy as Numeric) as Number {
            if (!round) { return cx; }
            var d = (dy * s).toFloat();
            var rr = r.toFloat();
            if (d * d >= rr * rr) { return 0; }
            return Math.sqrt(rr * rr - d * d).toNumber();
        }
    }

    // Point on a circle. Angle in degrees, Garmin convention: 0 = 3 o'clock, counter-clockwise.
    function px(cx as Numeric, deg as Numeric, r as Numeric) as Float {
        return cx + Math.cos(Math.toRadians(deg)) * r;
    }

    function py(cy as Numeric, deg as Numeric, r as Numeric) as Float {
        return cy - Math.sin(Math.toRadians(deg)) * r;
    }

    // Normalizes an angle to 0..359.
    function norm(a as Numeric) as Number {
        var n = a.toNumber();
        return ((n % 360) + 360) % 360;
    }

    // Clockwise arc from startDeg sweeping sweep degrees (Garmin angles).
    function arcCw(dc as Dc, cx as Number, cy as Number, r as Number, startDeg as Numeric, sweep as Numeric) as Void {
        if (sweep <= 0) { return; }
        if (sweep >= 360) {
            dc.drawCircle(cx, cy, r);
            return;
        }
        dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, norm(startDeg), norm(startDeg - sweep));
    }

    // ---- fonts -------------------------------------------------------------------

    // Roboto Condensed vector font, size in design units; null on devices without vector fonts.
    // Fonts are cached per pixel size, so faces can call this every frame.
    var _fonts as Dictionary = {};

    function vfont(bold as Boolean, size as Numeric, sc as Screen) as VectorFont? {
        if (!(Graphics has :getVectorFont)) { return null; }
        var key = (size * sc.s).toNumber() * 2 + (bold ? 1 : 0);
        if (_fonts.hasKey(key)) { return _fonts[key] as VectorFont?; }
        var faces = bold ? ["RobotoCondensedBold", "RobotoCondensedRegular", "RobotoRegular"]
                         : ["RobotoCondensedRegular", "RobotoCondensedBold", "RobotoRegular"];
        var pxSize = (size * sc.s).toNumber();
        if (pxSize < 8) { pxSize = 8; }
        var f = Graphics.getVectorFont({ :face => faces, :size => pxSize });
        _fonts[key] = f;
        return f;
    }

    function pick(v as VectorFont?, fallback as FontType) as FontType {
        return (v != null) ? v : fallback;
    }

    // ---- time and date -----------------------------------------------------------

    // TimeFormat setting: 0 watch setting, 1 12 hour, 2 24 hour.
    function is24() as Boolean {
        var f = num("TimeFormat", 0);
        if (f == 1) { return false; }
        if (f == 2) { return true; }
        return System.getDeviceSettings().is24Hour;
    }

    // Hour as shown on the face (1-12 or 0-23).
    function hour(h as Number) as Number {
        if (is24()) { return h; }
        var x = h % 12;
        return (x == 0) ? 12 : x;
    }

    function two(n as Number) as String {
        return n.format("%02d");
    }

    // "TUE 24 NOV"
    function dateText() as String {
        var d = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        return (d.day_of_week as String).toUpper() + " " + d.day.toString() + " " + (d.month as String).toUpper();
    }

    // "TUE"
    function dayName() as String {
        var d = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        return (d.day_of_week as String).toUpper();
    }

    // Hours as text, e.g. 7.70 -> "07:42" (follows 12/24 h).
    function clockText(hf as Float) as String {
        var mins = (hf * 60.0).toNumber() % 1440;
        return hour(mins / 60).toString() + ":" + two(mins % 60);
    }

    // ---- sunrise and sunset --------------------------------------------------------

    var _sunKey as Number = -1;
    var _sun as Array? = null;

    // [sunrise, sunset] in local hours (e.g. 7.7, 16.9), or null when the watch has no
    // position yet. Cached for ten minutes.
    function sun() as Array? {
        var now = Time.now();
        var key = now.value() / 600;
        if (key == _sunKey) { return _sun; }
        _sunKey = key;
        _sun = null;
        if (!(Toybox has :Weather) || !(Weather has :getSunrise)) { return null; }
        var loc = null;
        var ai = Activity.getActivityInfo();
        if (ai != null && ai.currentLocation != null) { loc = ai.currentLocation; }
        if (loc == null) {
            var c = Weather.getCurrentConditions();
            if (c != null && c.observationLocationPosition != null) { loc = c.observationLocationPosition; }
        }
        if (loc == null) { return null; }
        var rise = Weather.getSunrise(loc, now);
        var set = Weather.getSunset(loc, now);
        if (rise == null || set == null) { return null; }
        _sun = [localHours(rise), localHours(set)];
        return _sun;
    }

    function localHours(m as Moment) as Float {
        var d = Gregorian.info(m, Time.FORMAT_SHORT);
        return d.hour + d.min / 60.0;
    }

    // Current local time in hours, e.g. 13.5.
    function nowHours() as Float {
        var t = System.getClockTime();
        return t.hour + t.min / 60.0 + t.sec / 3600.0;
    }
}
