import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Layout is designed for the 454x454 round AMOLED of the Fenix 8 51mm.
// Angles follow Garmin's convention: 0 = 3 o'clock, counter-clockwise positive.
class FaceView extends WatchUi.WatchFace {
    private var _lowPower as Boolean = false;

    function initialize() {
        WatchFace.initialize();
    }

    function onEnterSleep() as Void {
        _lowPower = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _lowPower = false;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth();
        var cx = w / 2;
        var cy = dc.getHeight() / 2;
        var s = w / 454.0; // scale so other screen sizes still work

        if (_lowPower) {
            drawLowPower(dc, cx, cy, s);
            return;
        }

        drawTicks(dc, cx, cy, s);

        // Gauges: [setting key prefix, radius, start angle, span, clockwise, pen, radial text angle, radial text dir]
        gauge(dc, cx, cy, s, "Top", 200, 135, 90, true, 10);
        gauge(dc, cx, cy, s, "Right", 200, -30, 60, false, 10);
        gauge(dc, cx, cy, s, "Left1", 200, 210, 60, true, 8);
        gauge(dc, cx, cy, s, "Left2", 186, 210, 60, true, 8);
        gauge(dc, cx, cy, s, "Left3", 172, 210, 60, true, 8);
        gauge(dc, cx, cy, s, "Bottom", 200, 220, 100, false, 10);

        drawTopText(dc, cx, cy, s);
        drawSideText(dc, cx, cy, s);
        drawDate(dc, cx, cy, s);
        drawTime(dc, cx, cy, s, Cfg.color("TimeColor"), 0, 0);
        drawWidget(dc, cx - (95 * s).toNumber(), cy + (82 * s).toNumber(), (44 * s).toNumber(), "W1");
        drawWidget(dc, cx, cy + (82 * s).toNumber(), (44 * s).toNumber(), "W2");
        drawWidget(dc, cx + (95 * s).toNumber(), cy + (82 * s).toNumber(), (44 * s).toNumber(), "W3");
    }

    // ---- drawing helpers -------------------------------------------------

    private function norm(a as Number) as Number {
        return ((a % 360) + 360) % 360;
    }

    private function gauge(dc as Dc, cx as Number, cy as Number, s as Float, slot as String,
                           radius as Number, startDeg as Number, span as Number,
                           cw as Boolean, pen as Number) as Void {
        var id = Cfg.num(slot + "Field", 0);
        if (id == 0) { return; }
        var col = Cfg.color(slot + "Color");
        var m = Metrics.get(id);
        var r = (radius * s).toNumber();
        var attr = cw ? Graphics.ARC_CLOCKWISE : Graphics.ARC_COUNTER_CLOCKWISE;
        var endDeg = cw ? startDeg - span : startDeg + span;

        dc.setPenWidth((pen * s).toNumber());
        dc.setColor(Cfg.dim(col, 0.22), Graphics.COLOR_BLACK);
        dc.drawArc(cx, cy, r, attr, norm(startDeg), norm(endDeg));

        var frac = m[0] as Float;
        if (frac > 0.01) {
            var fillEnd = cw ? startDeg - (span * frac) : startDeg + (span * frac);
            dc.setColor(col, Graphics.COLOR_BLACK);
            dc.drawArc(cx, cy, r, attr, norm(startDeg), norm(fillEnd.toNumber()));
        }
    }

    private function drawTicks(dc as Dc, cx as Number, cy as Number, s as Float) as Void {
        var tick = Cfg.color("TickColor");
        var secCol = Cfg.color("SecColor");
        var sec = System.getClockTime().sec;
        var showSec = Cfg.flag("ShowSeconds", true);
        for (var i = 0; i < 60; i++) {
            var rad = Math.toRadians(90 - i * 6);
            var outer = 226 * s;
            var inner = ((i % 5 == 0) ? 212 : 218) * s;
            var hot = showSec && (i == sec);
            if (hot) { inner = 208 * s; }
            dc.setColor(hot ? secCol : Cfg.dim(tick, 0.5), Graphics.COLOR_BLACK);
            dc.setPenWidth(((i % 5 == 0 || hot) ? 4 : 2) * s);
            dc.drawLine(cx + Math.cos(rad) * inner, cy - Math.sin(rad) * inner,
                        cx + Math.cos(rad) * outer, cy - Math.sin(rad) * outer);
        }
    }

    // Text bent along the circle, falling back to plain text if unsupported.
    private function radial(dc as Dc, cx as Number, cy as Number, text as String, font as FontType,
                            angle as Number, radius as Number, cw as Boolean) as Void {
        if (dc has :drawRadialText) {
            dc.drawRadialText(cx, cy, font, text, Graphics.TEXT_JUSTIFY_CENTER, angle, radius,
                cw ? Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE : Graphics.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE);
        } else {
            var rad = Math.toRadians(angle);
            dc.drawText(cx + Math.cos(rad) * radius, cy - Math.sin(rad) * radius, font, text,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    private function drawTopText(dc as Dc, cx as Number, cy as Number, s as Float) as Void {
        var id = Cfg.num("TopField", 0);
        if (id == 0) { return; }
        var col = Cfg.color("TopColor");
        var m = Metrics.get(id);
        dc.setColor(col, Graphics.COLOR_BLACK);
        dc.drawText(cx, (62 * s).toNumber(), Graphics.FONT_SMALL, m[1], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, (92 * s).toNumber(), Graphics.FONT_XTINY, m[2], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawSideText(dc as Dc, cx as Number, cy as Number, s as Float) as Void {
        var f = Graphics.FONT_XTINY;
        // Right: value + unit running downward.
        var id = Cfg.num("RightField", 0);
        if (id != 0) {
            var m = Metrics.get(id);
            dc.setColor(Cfg.color("RightColor"), Graphics.COLOR_BLACK);
            radial(dc, cx, cy, m[1] + " " + m[2], f, 0, (170 * s).toNumber(), true);
        }
        // Left: three values stacked, each in its arc color.
        var slots = ["Left1", "Left2", "Left3"];
        var angles = [200, 180, 160];
        for (var i = 0; i < 3; i++) {
            var lid = Cfg.num(slots[i] + "Field", 0);
            if (lid == 0) { continue; }
            var lm = Metrics.get(lid);
            dc.setColor(Cfg.color(slots[i] + "Color"), Graphics.COLOR_BLACK);
            radial(dc, cx, cy, lm[1], f, angles[i], (150 * s).toNumber(), true);
        }
        // Bottom: value + unit reading left to right.
        var bid = Cfg.num("BottomField", 0);
        if (bid != 0) {
            var bm = Metrics.get(bid);
            dc.setColor(Cfg.color("BottomColor"), Graphics.COLOR_BLACK);
            radial(dc, cx, cy, bm[2] + "  " + bm[1], f, 270, (170 * s).toNumber(), false);
        }
    }

    private function dateString() as String {
        var i = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        return (i.day_of_week + " " + i.day + " " + i.month).toUpper();
    }

    private function drawDate(dc as Dc, cx as Number, cy as Number, s as Float) as Void {
        if (!Cfg.flag("ShowDate", true)) { return; }
        dc.setColor(Cfg.color("DateColor"), Graphics.COLOR_BLACK);
        dc.drawText(cx, (132 * s).toNumber(), Graphics.FONT_SMALL, dateString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawTime(dc as Dc, cx as Number, cy as Number, s as Float, color as Number,
                              dx as Number, dy as Number) as Void {
        var t = System.getClockTime();
        var h = t.hour;
        if (!System.getDeviceSettings().is24Hour) {
            h = h % 12;
            if (h == 0) { h = 12; }
        }
        dc.setColor(color, Graphics.COLOR_BLACK);
        dc.drawText(cx + dx, cy - (22 * s).toNumber() + dy, Graphics.FONT_NUMBER_HOT,
            h.format("%d") + ":" + t.min.format("%02d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawWidget(dc as Dc, x as Number, y as Number, r as Number, slot as String) as Void {
        var id = Cfg.num(slot + "Field", 0);
        if (id == 0) { return; }
        var col = Cfg.color(slot + "Color");
        var wd = Metrics.widget(id);
        dc.setPenWidth(4);
        dc.setColor(col, Graphics.COLOR_BLACK);
        dc.drawCircle(x, y, r);
        dc.drawText(x, y - 8, Graphics.FONT_TINY, wd[0], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Cfg.dim(col, 0.7), Graphics.COLOR_BLACK);
        dc.drawText(x, y + 17, Graphics.FONT_XTINY, wd[1], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Always-on display: dim time and date only, shifted each minute to limit AMOLED burn-in.
    private function drawLowPower(dc as Dc, cx as Number, cy as Number, s as Float) as Void {
        var m = System.getClockTime().min;
        var dx = ((m % 5) - 2) * 3;
        var dy = (((m / 5) % 5) - 2) * 3;
        drawTime(dc, cx, cy, s, 0x9AA0A6, dx, dy);
        dc.setColor(0x606670, Graphics.COLOR_BLACK);
        dc.drawText(cx + dx, cy - (110 * s).toNumber() + dy, Graphics.FONT_SMALL, dateString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
