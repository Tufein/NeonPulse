import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

// Bitlevel: retro 8-bit face. Pixel digits, hearts for battery (HP), an XP bar for the
// step goal (or any field), two stat lines and a strip of pixel ground at the bottom.
class FaceView extends BaseFace {
    // Fixed star positions in design units (x, y), drawn in the night sky.
    private const STARS = [70, 150, 120, 95, 330, 90, 390, 160, 250, 40, 175, 60, 300, 135, 95, 230, 365, 240];

    function initialize() {
        BaseFace.initialize();
    }

    function drawFace(dc as Dc, sc as Kit.Screen, awake as Boolean) as Void {
        var cx = sc.cx;
        var cy = sc.cy;
        var accent = Kit.color("AccentColor", 1);
        var heartCol = Kit.color("HeartColor", 2);
        var x0 = cx - sc.n(227);
        var y0 = cy - sc.n(227);

        // Stars
        var star = sc.n(4);
        if (star < 2) { star = 2; }
        dc.setColor(0x6A7090, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < STARS.size(); i += 2) {
            dc.fillRectangle(x0 + sc.n(STARS[i]), y0 + sc.n(STARS[i + 1]), star, star);
        }

        // HP hearts: battery in steps of 20%
        var hp = sc.n(4);
        if (hp < 2) { hp = 2; }
        var batt = Stats.battery();
        var full = (batt + 10) / 20;
        var step = hp * 9;
        var hx = cx - (5 * step - 2 * hp) / 2;
        var hy = y0 + sc.n(58);
        for (var i = 0; i < 5; i++) {
            if (i < full) {
                dc.setColor(batt <= 20 ? 0xFF3B5C : heartCol, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(0x3A3A48, Graphics.COLOR_TRANSPARENT);
            }
            Pixel.heart(dc, hx + i * step, hy, hp);
        }
        if (Stats.charging()) {
            dc.setColor(0xFFE000, Graphics.COLOR_TRANSPARENT);
            Pixel.draw(dc, cx, hy + hp * 8, "CHARGE", sc.n(3) < 2 ? 2 : sc.n(3));
        }

        // Date
        var tp = sc.n(4);
        if (tp < 2) { tp = 2; }
        dc.setColor(0xC8CCE0, Graphics.COLOR_TRANSPARENT);
        Pixel.draw(dc, cx, cy - sc.n(100), Kit.dateText(), tp);

        // Time
        var t = System.getClockTime();
        var p = sc.n(16);
        if (p < 4) { p = 4; }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        Pixel.draw(dc, cx, cy - sc.n(62), Kit.hour(t.hour).toString() + ":" + Kit.two(t.min), p);
        if (awake && Kit.flag("ShowSeconds", false)) {
            dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
            Pixel.draw(dc, cx + sc.n(178), cy - sc.n(2), Kit.two(t.sec), tp);
        }

        // XP bar
        var xp = Stats.get(Kit.num("XpField", 3));
        var sp = sc.n(3);
        if (sp < 2) { sp = 2; }
        dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
        Pixel.draw(dc, cx, cy + sc.n(34), "XP " + xp[1], sp);
        var bw = sc.n(240);
        var bh = sc.n(22);
        var bx = cx - bw / 2;
        var by = cy + sc.n(58);
        dc.setColor(0xC8CCE0, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(bx, by, bw, bh);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(bx + sp, by + sp, bw - 2 * sp, bh - 2 * sp);
        var frac = (xp[0] as Float) < 0.0 ? 0.0 : xp[0] as Float;
        // Fill in whole blocks so the bar stays pixel-like.
        var inner = bw - 4 * sp;
        var blocks = (frac * (inner / (2 * sp))).toNumber();
        dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < blocks; i++) {
            dc.fillRectangle(bx + 2 * sp + i * 2 * sp, by + 2 * sp, sp + sp / 2, bh - 4 * sp);
        }

        // Two stat lines
        var f1 = Stats.get(Kit.num("Field1", 2));
        var f2 = Stats.get(Kit.num("Field2", 6));
        dc.setColor(0xC8CCE0, Graphics.COLOR_TRANSPARENT);
        Pixel.draw(dc, cx - sc.n(82), cy + sc.n(104), f1[1] + " " + f1[2], sp);
        Pixel.draw(dc, cx + sc.n(82), cy + sc.n(104), f2[1] + " " + f2[2], sp);

        drawGround(dc, sc);
    }

    // Grass strip and dirt bricks along the bottom edge.
    private function drawGround(dc as Dc, sc as Kit.Screen) as Void {
        var top = sc.cy + sc.n(150);
        var grass = sc.n(12);
        var brick = sc.n(24);
        if (brick < 6) { brick = 6; }
        dc.setColor(0x7A4A21, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, top + grass, sc.w, sc.h - top - grass);
        dc.setColor(0x4E2E12, Graphics.COLOR_TRANSPARENT);
        var row = 0;
        for (var y = top + grass; y < sc.h; y += brick) {
            dc.fillRectangle(0, y, sc.w, 2);
            var off = (row % 2 == 0) ? 0 : brick;
            for (var x = off; x < sc.w; x += brick * 2) {
                dc.fillRectangle(x, y, 2, brick);
            }
            row += 1;
        }
        dc.setColor(0x3CB043, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, top, sc.w, grass);
        dc.setColor(0x2A8A30, Graphics.COLOR_TRANSPARENT);
        for (var x = 0; x < sc.w; x += grass * 2) {
            dc.fillRectangle(x, top + grass - grass / 3, grass, grass / 3);
        }
    }

    // Always-on: grey pixel time only, which keeps lit pixels low.
    function drawAod(dc as Dc, sc as Kit.Screen, dx as Number, dy as Number) as Void {
        var t = System.getClockTime();
        var p = sc.n(12);
        if (p < 3) { p = 3; }
        dc.setColor(0x7A7A7A, Graphics.COLOR_TRANSPARENT);
        Pixel.draw(dc, sc.cx + dx, sc.cy - p * 5 / 2 + dy, Kit.hour(t.hour).toString() + ":" + Kit.two(t.min), p);
        var tp = sc.n(4);
        if (tp < 2) { tp = 2; }
        dc.setColor(0x4A4A4A, Graphics.COLOR_TRANSPARENT);
        Pixel.draw(dc, sc.cx + dx, sc.cy + sc.n(50) + dy, Kit.dateText(), tp);
    }
}
