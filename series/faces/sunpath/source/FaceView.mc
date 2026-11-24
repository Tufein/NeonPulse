import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

// Sunpath 24: a 24-hour dial. Midnight at the bottom, noon at the top. The ring is lit
// from sunrise to sunset, and a sun (or moon) marker shows the current time on it.
// Center: digital time, date, sunrise and sunset, and daylight (or darkness) remaining.
class FaceView extends BaseFace {
    private const JUST = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

    function initialize() {
        BaseFace.initialize();
    }

    // Garmin angle for a time of day in hours: 0 h at the bottom, 6 h left, 12 h top, 18 h right.
    private function angle(hours as Float) as Float {
        return 270.0 - hours * 15.0;
    }

    function drawFace(dc as Dc, sc as Kit.Screen, awake as Boolean) as Void {
        var cx = sc.cx;
        var cy = sc.cy;
        var dayCol = Kit.color("AccentColor", 3);
        var T = Graphics.COLOR_TRANSPARENT;
        var sun = Kit.sun();
        var rise = (sun != null) ? sun[0] as Float : 6.0;
        var set = (sun != null) ? sun[1] as Float : 18.0;
        var now = Kit.nowHours();
        var day = now >= rise && now < set;

        // Ring: night all round, day arc on top.
        var r = sc.n(204);
        var pen = sc.n(16) < 4 ? 4 : sc.n(16);
        dc.setPenWidth(pen);
        dc.setColor(0x16244A, T);
        dc.drawCircle(cx, cy, r);
        dc.setColor(dayCol, T);
        Kit.arcCw(dc, cx, cy, r, angle(rise), ((set - rise) * 15.0).toNumber());
        dc.setPenWidth(1);

        // Hour dots and the 0/6/12/18 numerals
        var nf = Kit.pick(Kit.vfont(true, 22, sc), Graphics.FONT_XTINY);
        for (var h = 0; h < 24; h++) {
            var ha = angle(h.toFloat());
            var major = h % 6 == 0;
            dc.setColor(major ? 0xFFFFFF : 0x5A6070, T);
            dc.fillCircle(Kit.px(cx, ha, sc.n(224)), Kit.py(cy, ha, sc.n(224)), major ? sc.n(3) + 1 : sc.n(2) + 1);
            if (major) {
                dc.setColor(0xB0B6C2, T);
                dc.drawText(Kit.px(cx, ha, sc.n(174)), Kit.py(cy, ha, sc.n(174)), nf, h.toString(), JUST);
            }
        }

        // Sun / moon marker
        var a = angle(now);
        var mx = Kit.px(cx, a, r);
        var my = Kit.py(cy, a, r);
        var mr = sc.n(15);
        dc.setColor(Graphics.COLOR_BLACK, T);
        dc.fillCircle(mx, my, mr + sc.n(5));
        if (day) {
            if (_amoled) {
                dc.setColor(Kit.dim(0xFFC830, 0.35), T);
                dc.fillCircle(mx, my, mr + sc.n(4));
            }
            dc.setColor(0xFFD84A, T);
            dc.fillCircle(mx, my, mr);
        } else {
            dc.setColor(0xD8DCE8, T);
            dc.fillCircle(mx, my, mr);
            dc.setColor(Graphics.COLOR_BLACK, T);
            dc.fillCircle(mx + mr / 2, my - mr / 3, mr - 1);
        }

        // Center block
        var t = System.getClockTime();
        dc.setColor(0x9AA0AA, T);
        dc.drawText(cx, cy - sc.n(78), Kit.pick(Kit.vfont(true, 24, sc), Graphics.FONT_XTINY), Kit.dateText(), JUST);
        dc.setColor(Graphics.COLOR_WHITE, T);
        dc.drawText(cx, cy - sc.n(18), Kit.pick(Kit.vfont(true, 100, sc), Graphics.FONT_NUMBER_MEDIUM),
            Kit.hour(t.hour).toString() + ":" + Kit.two(t.min), JUST);
        if (awake && Kit.flag("ShowSeconds", false)) {
            dc.setColor(dayCol, T);
            dc.drawText(cx + sc.n(128), cy, Kit.pick(Kit.vfont(true, 26, sc), Graphics.FONT_XTINY), Kit.two(t.sec), JUST);
        }

        var vf = Kit.pick(Kit.vfont(true, 26, sc), Graphics.FONT_TINY);
        var lf = Kit.pick(Kit.vfont(false, 15, sc), Graphics.FONT_XTINY);
        var riseText = (sun != null) ? Kit.clockText(rise) : "--:--";
        var setText = (sun != null) ? Kit.clockText(set) : "--:--";
        dc.setColor(Graphics.COLOR_WHITE, T);
        dc.drawText(cx - sc.n(62), cy + sc.n(52), vf, riseText, JUST);
        dc.drawText(cx + sc.n(62), cy + sc.n(52), vf, setText, JUST);
        dc.setColor(dayCol, T);
        dc.drawText(cx - sc.n(62), cy + sc.n(76), lf, "SUNRISE", JUST);
        dc.drawText(cx + sc.n(62), cy + sc.n(76), lf, "SUNSET", JUST);

        // Daylight or darkness remaining, then one free field.
        var left = day ? set - now : ((now >= set) ? rise + 24.0 - now : rise - now);
        var mins = (left * 60.0).toNumber();
        dc.setColor(0x8A909A, T);
        dc.drawText(cx, cy + sc.n(106), lf,
            (day ? "DAYLIGHT " : "DARK ") + (mins / 60).toString() + ":" + Kit.two(mins % 60), JUST);
        var f = Stats.get(Kit.num("Field1", 1));
        dc.setColor(Graphics.COLOR_WHITE, T);
        dc.drawText(cx, cy + sc.n(138), vf, (f[1] as String) + " " + (f[2] as String), JUST);
    }

    // Always-on: grey time and the sun marker position as a small dot on a faint ring.
    function drawAod(dc as Dc, sc as Kit.Screen, dx as Number, dy as Number) as Void {
        BaseFace.drawAod(dc, sc, dx, dy);
        var a = angle(Kit.nowHours());
        dc.setColor(0x6A6A6A, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(Kit.px(sc.cx + dx, a, sc.n(200)), Kit.py(sc.cy + dy, a, sc.n(200)), sc.n(8));
    }
}
