import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

// Ridgeline: outdoor face. Large time over two mountain ridges; the sun (by day) or the
// moon (by night) travels across the sky between sunrise and sunset. Three data fields
// sit in the front ridge (default altitude, next sunrise/sunset, temperature).
class FaceView extends BaseFace {
    // Ridge outlines in design units relative to the center: x, y pairs, left to right.
    private const BACK = [-240, 105, -185, 65, -140, 87, -95, 30, -55, 65, -10, 17, 40, 75, 85, 40, 135, 80, 180, 50, 240, 95];
    private const FRONT = [-240, 145, -190, 120, -135, 137, -70, 105, -20, 127, 35, 101, 95, 131, 150, 111, 240, 143];
    private const JUST = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

    function initialize() {
        BaseFace.initialize();
    }

    function background() as Number {
        return Kit.num("Sky", 0) == 1 ? 0x0A1028 : Graphics.COLOR_BLACK;
    }

    function drawFace(dc as Dc, sc as Kit.Screen, awake as Boolean) as Void {
        var cx = sc.cx;
        var cy = sc.cy;
        var accent = Kit.color("AccentColor", 3);
        var T = Graphics.COLOR_TRANSPARENT;

        // Battery and date
        var b = Stats.battery();
        dc.setColor(b <= 20 ? 0xFF3B5C : 0x9AA0AA, T);
        dc.drawText(cx, cy - sc.n(196), Kit.pick(Kit.vfont(true, 22, sc), Graphics.FONT_XTINY), b.toString() + "%", JUST);
        dc.setColor(accent, T);
        dc.drawText(cx, cy - sc.n(160), Kit.pick(Kit.vfont(true, 28, sc), Graphics.FONT_XTINY), Kit.dateText(), JUST);

        // Time
        var t = System.getClockTime();
        var text = Kit.hour(t.hour).toString() + ":" + Kit.two(t.min);
        dc.setColor(Graphics.COLOR_WHITE, T);
        dc.drawText(cx, cy - sc.n(92), Kit.pick(Kit.vfont(true, 118, sc), Graphics.FONT_NUMBER_MEDIUM), text, JUST);
        if (awake && Kit.flag("ShowSeconds", false)) {
            dc.setColor(accent, T);
            dc.drawText(cx + sc.n(165), cy - sc.n(60), Kit.pick(Kit.vfont(true, 30, sc), Graphics.FONT_XTINY), Kit.two(t.sec), JUST);
        }

        drawSky(dc, sc, accent);

        // Back ridge: soft fill in a dark accent tone, bright outline.
        dc.setColor(Kit.dim(accent, 0.22), T);
        dc.fillPolygon(ridge(sc, BACK));
        dc.setColor(Kit.dim(accent, 0.7), T);
        dc.setPenWidth(sc.n(3) < 1 ? 1 : sc.n(3));
        outline(dc, sc, BACK);

        // Front ridge: dark, carries the data fields.
        dc.setColor(_amoled ? 0x10141A : 0x000000, T);
        dc.fillPolygon(ridge(sc, FRONT));
        dc.setColor(accent, T);
        outline(dc, sc, FRONT);
        dc.setPenWidth(1);

        var vf = Kit.pick(Kit.vfont(true, 32, sc), Graphics.FONT_TINY);
        var lf = Kit.pick(Kit.vfont(false, 17, sc), Graphics.FONT_XTINY);
        var keys = ["Field1", "Field2", "Field3"];
        var defs = [10, 13, 11];
        for (var i = 0; i < 3; i++) {
            var m = Stats.get(Kit.num(keys[i] as String, defs[i] as Number));
            var x = cx + sc.n((i - 1) * 100);
            dc.setColor(Graphics.COLOR_WHITE, T);
            dc.drawText(x, cy + sc.n(158), vf, m[1] as String, JUST);
            dc.setColor(0x9AA0AA, T);
            dc.drawText(x, cy + sc.n(186), lf, m[2] as String, JUST);
        }
    }

    // Sun by day, moon by night, on a shallow arc that sets behind the ridges.
    private function drawSky(dc as Dc, sc as Kit.Screen, accent as Number) as Void {
        var sun = Kit.sun();
        var rise = (sun != null) ? sun[0] as Float : 6.0;
        var set = (sun != null) ? sun[1] as Float : 18.0;
        var now = Kit.nowHours();
        var day = now >= rise && now < set;
        var frac;
        if (day) {
            frac = (now - rise) / (set - rise);
        } else {
            var nightLen = 24.0 - (set - rise);
            var since = (now >= set) ? now - set : now + 24.0 - set;
            frac = since / nightLen;
        }
        var x = sc.cx + sc.n(-190 + 380 * frac);
        var y = sc.cy + sc.n(55 - Math.sin(Math.PI * frac) * 70);
        var r = sc.n(16);

        // Dotted path
        dc.setColor(0x3A4050, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i <= 20; i++) {
            var f = i / 20.0;
            dc.fillCircle(sc.cx + sc.n(-190 + 380 * f), sc.cy + sc.n(55 - Math.sin(Math.PI * f) * 70), sc.n(2) < 1 ? 1 : sc.n(2));
        }
        if (day) {
            if (_amoled) {
                dc.setColor(Kit.dim(0xFFB000, 0.3), Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(x, y, r + sc.n(8));
            }
            dc.setColor(0xFFC830, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x, y, r);
        } else {
            dc.setColor(0xD8DCE8, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x, y, r);
            dc.setColor(background(), Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x + r / 2, y - r / 3, r);
        }
    }

    // Closed polygon from a ridge outline down to the bottom edge.
    private function ridge(sc as Kit.Screen, pts as Array) as Array {
        var out = [];
        for (var i = 0; i < pts.size(); i += 2) {
            out.add([sc.cx + sc.n(pts[i]), sc.cy + sc.n(pts[i + 1])]);
        }
        out.add([sc.cx + sc.n(240), sc.h]);
        out.add([sc.cx - sc.n(240), sc.h]);
        return out;
    }

    private function outline(dc as Dc, sc as Kit.Screen, pts as Array) as Void {
        for (var i = 0; i + 3 < pts.size(); i += 2) {
            dc.drawLine(sc.cx + sc.n(pts[i]), sc.cy + sc.n(pts[i + 1]), sc.cx + sc.n(pts[i + 2]), sc.cy + sc.n(pts[i + 3]));
        }
    }
}
