import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Meridian Chrono: analog chronograph look. Minute track, hour bars, three sub-dials
// (left, right, bottom) with a progress ring each, a day/date window under 12 and
// tapered hands. The seconds hand only runs while the watch is awake.
class FaceView extends BaseFace {
    private const JUST = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

    function initialize() {
        BaseFace.initialize();
    }

    function background() as Number {
        var bg = [0x000000, 0x0B1A2E, 0x1A1410, 0x0E1116];
        var i = Kit.num("DialColor", 0);
        return (i >= 0 && i < bg.size()) ? bg[i] as Number : 0x000000;
    }

    function drawFace(dc as Dc, sc as Kit.Screen, awake as Boolean) as Void {
        var cx = sc.cx;
        var cy = sc.cy;
        var accent = Kit.color("AccentColor", 7);
        var T = Graphics.COLOR_TRANSPARENT;

        drawTicks(dc, sc, 0xD0D4DA, 0x6A707A);

        // 12 numeral and the date window
        dc.setColor(Graphics.COLOR_WHITE, T);
        dc.drawText(cx, cy - sc.n(168), Kit.pick(Kit.vfont(true, 40, sc), Graphics.FONT_SMALL), "12", JUST);
        var df = Kit.pick(Kit.vfont(true, 22, sc), Graphics.FONT_XTINY);
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dt = Kit.dayName() + " " + info.day.toString();
        var bw = sc.n(96);
        var bh = sc.n(30);
        dc.setColor(0x2A2E36, T);
        dc.fillRoundedRectangle(cx - bw / 2, cy - sc.n(120) - bh / 2, bw, bh, sc.n(6));
        dc.setColor(Graphics.COLOR_WHITE, T);
        dc.drawText(cx, cy - sc.n(120), df, dt, JUST);

        // Sub-dials
        var keys = ["Field1", "Field2", "Field3"];
        var defs = [1, 3, 2];
        var pos = [[-112, 8], [112, 8], [0, 118]];
        for (var i = 0; i < 3; i++) {
            var p = pos[i] as Array;
            subDial(dc, sc, cx + sc.n(p[0]), cy + sc.n(p[1]), Stats.get(Kit.num(keys[i] as String, defs[i] as Number)), accent);
        }

        // Hands
        var t = System.getClockTime();
        var hourDeg = ((t.hour % 12) + t.min / 60.0) * 30.0;
        var minDeg = (t.min + t.sec / 60.0) * 6.0;
        if (!awake) { minDeg = t.min * 6.0; }
        dc.setColor(Graphics.COLOR_WHITE, T);
        hand(dc, sc, 0, 0, hourDeg, 128, 22, 16);
        hand(dc, sc, 0, 0, minDeg, 196, 26, 12);
        dc.setColor(accent, T);
        hand(dc, sc, 0, 0, hourDeg, 100, -30, 4);
        if (awake && Kit.flag("ShowSeconds", true)) {
            var a = Math.toRadians(t.sec * 6.0);
            var dx = Math.sin(a);
            var dy = -Math.cos(a);
            dc.setPenWidth(sc.n(3) < 1 ? 1 : sc.n(3));
            dc.drawLine(cx - dx * sc.n(40), cy - dy * sc.n(40), cx + dx * sc.n(206), cy + dy * sc.n(206));
            dc.setPenWidth(1);
            dc.fillCircle(cx - dx * sc.n(40), cy - dy * sc.n(40), sc.n(7));
        }
        dc.setColor(Graphics.COLOR_WHITE, T);
        dc.fillCircle(cx, cy, sc.n(11));
        dc.setColor(accent, T);
        dc.fillCircle(cx, cy, sc.n(5));
    }

    // Minute track and hour bars.
    private function drawTicks(dc as Dc, sc as Kit.Screen, hourCol as Number, minCol as Number) as Void {
        var outer = 222;
        for (var i = 0; i < 60; i++) {
            var deg = 90 - i * 6;
            var hourTick = i % 5 == 0;
            if (hourTick) {
                if (i == 0) { continue; } // the "12" numeral sits there
                dc.setColor(hourCol, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(sc.n(7) < 2 ? 2 : sc.n(7));
            } else {
                dc.setColor(minCol, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(sc.n(2) < 1 ? 1 : sc.n(2));
            }
            var inner = hourTick ? outer - 30 : outer - 10;
            dc.drawLine(Kit.px(sc.cx, deg, sc.n(inner)), Kit.py(sc.cy, deg, sc.n(inner)),
                Kit.px(sc.cx, deg, sc.n(outer)), Kit.py(sc.cy, deg, sc.n(outer)));
        }
        dc.setPenWidth(1);
    }

    // One sub-dial: ring, progress arc from 12 o'clock, value and label.
    private function subDial(dc as Dc, sc as Kit.Screen, x as Number, y as Number, m as Array, accent as Number) as Void {
        var r = sc.n(50);
        var pen = sc.n(6) < 2 ? 2 : sc.n(6);
        dc.setPenWidth(pen);
        dc.setColor(0x2A2E36, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(x, y, r);
        var f = m[0] as Float;
        if (f > 0.0) {
            dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
            Kit.arcCw(dc, x, y, r, 90, (f * 360).toNumber());
        }
        dc.setPenWidth(1);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y - sc.n(6), Kit.pick(Kit.vfont(true, 26, sc), Graphics.FONT_XTINY), m[1] as String, JUST);
        dc.setColor(0x9AA0AA, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y + sc.n(20), Kit.pick(Kit.vfont(false, 14, sc), Graphics.FONT_XTINY), m[2] as String, JUST);
    }

    // Tapered hand around the center shifted by ox/oy. deg is clockwise from 12; len and tail in design units, width at the base.
    private function hand(dc as Dc, sc as Kit.Screen, ox as Number, oy as Number, deg as Float, len as Number, tail as Number, width as Number) as Void {
        var a = Math.toRadians(deg);
        var dx = Math.sin(a);
        var dy = -Math.cos(a);
        var L = sc.n(len);
        var B = sc.n(tail);
        var W = sc.n(width) / 2.0;
        if (W < 1.0) { W = 1.0; }
        var cx = sc.cx + ox;
        var cy = sc.cy + oy;
        dc.fillPolygon([
            [cx - dx * B - dy * W, cy - dy * B + dx * W],
            [cx + dx * L * 0.88 - dy * W * 0.6, cy + dy * L * 0.88 + dx * W * 0.6],
            [cx + dx * L, cy + dy * L],
            [cx + dx * L * 0.88 + dy * W * 0.6, cy + dy * L * 0.88 - dx * W * 0.6],
            [cx - dx * B + dy * W, cy - dy * B - dx * W]
        ]);
    }

    // Always-on: dim hour bars and grey hands.
    function drawAod(dc as Dc, sc as Kit.Screen, dx as Number, dy as Number) as Void {
        var t = System.getClockTime();
        dc.setColor(0x505050, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(sc.n(4) < 1 ? 1 : sc.n(4));
        for (var i = 0; i < 12; i++) {
            var deg = 90 - i * 30;
            dc.drawLine(Kit.px(sc.cx + dx, deg, sc.n(196)), Kit.py(sc.cy + dy, deg, sc.n(196)),
                Kit.px(sc.cx + dx, deg, sc.n(216)), Kit.py(sc.cy + dy, deg, sc.n(216)));
        }
        dc.setPenWidth(1);
        dc.setColor(0x7A7A7A, Graphics.COLOR_TRANSPARENT);
        hand(dc, sc, dx, dy, ((t.hour % 12) + t.min / 60.0) * 30.0, 120, 0, 10);
        hand(dc, sc, dx, dy, t.min * 6.0, 186, 0, 7);
    }
}
