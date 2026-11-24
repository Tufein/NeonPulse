import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Stacked Hours: huge hours stacked over huge minutes, a slim side column with the day
// and two data fields, and two thin edge arcs (step goal on top, battery at the bottom).
class FaceView extends BaseFace {
    private const JUST = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

    function initialize() {
        BaseFace.initialize();
    }

    function drawFace(dc as Dc, sc as Kit.Screen, awake as Boolean) as Void {
        var cx = sc.cx;
        var cy = sc.cy;
        var accent = Kit.color("AccentColor", 4);
        var minCol = Kit.color("MinuteColor", 0);
        var T = Graphics.COLOR_TRANSPARENT;
        var t = System.getClockTime();
        var big = Kit.pick(Kit.vfont(true, 176, sc), Graphics.FONT_NUMBER_THAI_HOT);
        var dx = cx - sc.n(40);

        dc.setColor(accent, T);
        dc.drawText(dx, cy - sc.n(80), big, Kit.two(Kit.hour(t.hour)), JUST);
        dc.setColor(minCol, T);
        dc.drawText(dx, cy + sc.n(80), big, Kit.two(t.min), JUST);

        // Side column
        var colX = cx + sc.n(124);
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        dc.setColor(accent, T);
        dc.drawText(colX, cy - sc.n(96), Kit.pick(Kit.vfont(true, 24, sc), Graphics.FONT_XTINY), Kit.dayName(), JUST);
        dc.setColor(Graphics.COLOR_WHITE, T);
        dc.drawText(colX, cy - sc.n(58), Kit.pick(Kit.vfont(true, 48, sc), Graphics.FONT_SMALL), info.day.toString(), JUST);
        dc.setColor(0x3A3E46, T);
        dc.fillRectangle(colX - sc.n(28), cy - sc.n(24), sc.n(56), sc.n(3) < 1 ? 1 : sc.n(3));

        var vf = Kit.pick(Kit.vfont(true, 30, sc), Graphics.FONT_TINY);
        var lf = Kit.pick(Kit.vfont(false, 15, sc), Graphics.FONT_XTINY);
        var f1 = Stats.get(Kit.num("Field1", 3));
        var f2 = Stats.get(Kit.num("Field2", 2));
        dc.setColor(Graphics.COLOR_WHITE, T);
        dc.drawText(colX, cy + sc.n(10), vf, f1[1] as String, JUST);
        dc.drawText(colX, cy + sc.n(80), vf, f2[1] as String, JUST);
        dc.setColor(0x8A909A, T);
        dc.drawText(colX, cy + sc.n(36), lf, f1[2] as String, JUST);
        dc.drawText(colX, cy + sc.n(106), lf, f2[2] as String, JUST);

        if (awake && Kit.flag("ShowSeconds", false)) {
            dc.setColor(accent, T);
            dc.drawText(colX, cy + sc.n(150), vf, Kit.two(t.sec), JUST);
        }

        // Edge arcs: steps on top (clockwise over 12), battery at the bottom (left to right).
        var r = sc.r - sc.n(12);
        var pen = sc.n(6) < 2 ? 2 : sc.n(6);
        dc.setPenWidth(pen);
        dc.setColor(0x24282E, T);
        dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, 135, 45);
        dc.drawArc(cx, cy, r, Graphics.ARC_COUNTER_CLOCKWISE, 225, 315);
        var steps = Stats.get(3)[0] as Float;
        if (steps > 0.0) {
            dc.setColor(accent, T);
            Kit.arcCw(dc, cx, cy, r, 135, (steps * 90).toNumber());
        }
        var b = Stats.battery();
        var sweep = b * 90 / 100;
        if (sweep > 0) {
            dc.setColor(b <= 20 ? 0xFF3B5C : minCol, T);
            dc.drawArc(cx, cy, r, Graphics.ARC_COUNTER_CLOCKWISE, 225, 225 + sweep);
        }
        dc.setPenWidth(1);
    }

    // Always-on: the same stack, smaller and grey.
    function drawAod(dc as Dc, sc as Kit.Screen, dx as Number, dy as Number) as Void {
        var t = System.getClockTime();
        var f = Kit.pick(Kit.vfont(true, 120, sc), Graphics.FONT_NUMBER_MEDIUM);
        dc.setColor(0x6A6A6A, Graphics.COLOR_TRANSPARENT);
        dc.drawText(sc.cx + dx, sc.cy - sc.n(56) + dy, f, Kit.two(Kit.hour(t.hour)), JUST);
        dc.setColor(0x4A4A4A, Graphics.COLOR_TRANSPARENT);
        dc.drawText(sc.cx + dx, sc.cy + sc.n(56) + dy, f, Kit.two(t.min), JUST);
    }
}
