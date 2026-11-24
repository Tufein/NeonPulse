import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

// Gridwork: data-dense face. Time and date on top, a battery bar, and a 3x2 grid of
// tiles with six configurable fields. The grid follows the screen: narrower on round
// screens, wider on the rectangular Venu X1.
class FaceView extends BaseFace {
    private const JUST = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
    private const KEYS = ["Field1", "Field2", "Field3", "Field4", "Field5", "Field6"];
    private const DEFS = [3, 2, 6, 4, 11, 13];

    function initialize() {
        BaseFace.initialize();
    }

    function drawFace(dc as Dc, sc as Kit.Screen, awake as Boolean) as Void {
        var cx = sc.cx;
        var cy = sc.cy;
        var accent = Kit.color("AccentColor", 1);
        var T = Graphics.COLOR_TRANSPARENT;
        var t = System.getClockTime();

        dc.setColor(0x9AA0AA, T);
        dc.drawText(cx, cy - sc.n(168), Kit.pick(Kit.vfont(true, 26, sc), Graphics.FONT_XTINY), Kit.dateText(), JUST);
        var time = Kit.hour(t.hour).toString() + ":" + Kit.two(t.min);
        dc.setColor(Graphics.COLOR_WHITE, T);
        dc.drawText(cx, cy - sc.n(104), Kit.pick(Kit.vfont(true, 112, sc), Graphics.FONT_NUMBER_MEDIUM), time, JUST);
        if (awake && Kit.flag("ShowSeconds", false)) {
            dc.setColor(accent, T);
            dc.drawText(cx + sc.n(150), cy - sc.n(84), Kit.pick(Kit.vfont(true, 28, sc), Graphics.FONT_XTINY), Kit.two(t.sec), JUST);
        }

        // Battery bar
        var b = Stats.battery();
        var bw = sc.n(150);
        var bh = sc.n(6) < 2 ? 2 : sc.n(6);
        var by = cy - sc.n(42);
        dc.setColor(0x24282E, T);
        dc.fillRoundedRectangle(cx - bw / 2, by, bw, bh, bh / 2);
        dc.setColor(b <= 20 ? 0xFF3B5C : accent, T);
        dc.fillRoundedRectangle(cx - bw / 2, by, bw * b / 100, bh, bh / 2);

        // Tile grid
        var gap = sc.n(8);
        var tileH = sc.n(74);
        var top1 = cy - sc.n(22);
        var top2 = top1 + tileH + gap;
        var bottom = top2 + tileH;
        var half = sc.halfWidth((bottom - cy) / sc.s) - sc.n(14);
        if (half > sc.n(200)) { half = sc.n(200); }
        var tileW = (2 * half - 2 * gap) / 3;
        var x0 = cx - half;
        var vf = Kit.pick(Kit.vfont(true, 30, sc), Graphics.FONT_TINY);
        var lf = Kit.pick(Kit.vfont(false, 15, sc), Graphics.FONT_XTINY);
        for (var i = 0; i < 6; i++) {
            var x = x0 + (i % 3) * (tileW + gap);
            var y = (i < 3) ? top1 : top2;
            tile(dc, sc, x, y, tileW, tileH, Stats.get(Kit.num(KEYS[i] as String, DEFS[i] as Number)), accent, vf, lf);
        }
    }

    private function tile(dc as Dc, sc as Kit.Screen, x as Number, y as Number, w as Number, h as Number,
                          m as Array, accent as Number, vf as FontType, lf as FontType) as Void {
        var rad = sc.n(10);
        dc.setColor(_amoled ? 0x161A20 : 0x000000, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, y, w, h, rad);
        if (!_amoled) {
            dc.setColor(0x55555F, Graphics.COLOR_TRANSPARENT);
            dc.drawRoundedRectangle(x, y, w, h, rad);
        }
        // Progress strip along the top edge (full accent when the field has no goal).
        var f = m[0] as Float;
        var stripH = sc.n(5) < 2 ? 2 : sc.n(5);
        dc.setColor(Kit.dim(accent, 0.3), Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x + rad, y + sc.n(6), w - 2 * rad, stripH);
        dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
        var fw = (f < 0.0) ? w - 2 * rad : ((w - 2 * rad) * f).toNumber();
        dc.fillRectangle(x + rad, y + sc.n(6), fw, stripH);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + w / 2, y + h / 2 + sc.n(2), vf, m[1] as String, JUST);
        dc.setColor(0x8A909A, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + w / 2, y + h - sc.n(13), lf, m[2] as String, JUST);
    }
}
