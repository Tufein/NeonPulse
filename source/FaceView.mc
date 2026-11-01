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
    private var _arcFont as VectorFont? = null;    // for drawRadialText, which needs a vector font
    private var _widValFont as VectorFont? = null; // widget value, narrow enough to fit the circle
    private var _widLblFont as VectorFont? = null; // widget label

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

    function onLayout(dc as Dc) as Void {
        if (Graphics has :getVectorFont) {
            _arcFont = Graphics.getVectorFont({
                :face => ["RobotoCondensedBold", "RobotoCondensedRegular", "RobotoRegular"],
                :size => (22 * dc.getWidth() / 454)
            });
            _widValFont = Graphics.getVectorFont({
                :face => ["RobotoCondensedBold", "RobotoCondensedRegular", "RobotoRegular"],
                :size => (32 * dc.getWidth() / 454)
            });
            _widLblFont = Graphics.getVectorFont({
                :face => ["RobotoCondensedRegular", "RobotoCondensedBold", "RobotoRegular"],
                :size => (20 * dc.getWidth() / 454)
            });
        }
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
        drawTime(dc, cx, cy, s, Cfg.color("TimeColor"), Graphics.FONT_NUMBER_MEDIUM, 0, 0);
        var wy = cy + (90 * s).toNumber();
        var wr = (46 * s).toNumber();
        var wdx = (104 * s).toNumber();
        drawWidget(dc, cx - wdx, wy, wr, s, "W1");
        drawWidget(dc, cx, wy, wr, s, "W2");
        drawWidget(dc, cx + wdx, wy, wr, s, "W3");
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
        var vf = _arcFont;
        if (vf != null && (dc has :drawRadialText)) {
            dc.drawRadialText(cx, cy, vf, text, Graphics.TEXT_JUSTIFY_CENTER, angle, radius,
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
        dc.drawText(cx, (68 * s).toNumber(), Graphics.FONT_SMALL, m[1], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, (103 * s).toNumber(), Graphics.FONT_XTINY, m[2], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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
        // Left: up to three values in a row along the rim (outer arc lowest), each in its
        // arc color. Spaced by their real widths and centered at 168 deg so they stay clear
        // of the date above and the widget row below.
        var slots = ["Left1", "Left2", "Left3"];
        var texts = [] as Array<String>;
        var cols = [] as Array<Number>;
        for (var i = 0; i < 3; i++) {
            var lid = Cfg.num(slots[i] + "Field", 0);
            if (lid == 0) { continue; }
            texts.add(Metrics.get(lid)[1] as String);
            cols.add(Cfg.color(slots[i] + "Color"));
        }
        if (texts.size() > 0) {
            var lr = (150 * s).toNumber();
            var wf = (_arcFont != null) ? _arcFont : f;
            var gap = 12 * s;
            var widths = [] as Array<Float>;
            var total = gap * (texts.size() - 1);
            for (var i = 0; i < texts.size(); i++) {
                var tw = dc.getTextWidthInPixels(texts[i], wf).toFloat();
                widths.add(tw);
                total += tw;
            }
            var degPerPx = 180.0 / (Math.PI * lr);
            var a = 168.0 + total * degPerPx / 2.0; // clockwise text runs from high to low angle
            for (var i = 0; i < texts.size(); i++) {
                var half = widths[i] * degPerPx / 2.0;
                dc.setColor(cols[i], Graphics.COLOR_BLACK);
                radial(dc, cx, cy, texts[i], f, (a - half).toNumber(), lr, true);
                a -= 2.0 * half + gap * degPerPx;
            }
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
        dc.drawText(cx, (137 * s).toNumber(), Graphics.FONT_TINY, dateString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawTime(dc as Dc, cx as Number, cy as Number, s as Float, color as Number,
                              font as FontType, dx as Number, dy as Number) as Void {
        var t = System.getClockTime();
        var h = t.hour;
        if (!System.getDeviceSettings().is24Hour) {
            h = h % 12;
            if (h == 0) { h = 12; }
        }
        dc.setColor(color, Graphics.COLOR_BLACK);
        dc.drawText(cx + dx, cy - (27 * s).toNumber() + dy, font,
            h.format("%d") + ":" + t.min.format("%02d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawWidget(dc as Dc, x as Number, y as Number, r as Number, s as Float, slot as String) as Void {
        var id = Cfg.num(slot + "Field", 0);
        if (id == 0) { return; }
        var col = Cfg.color(slot + "Color");
        var wd = Metrics.widget(id);
        var vf = _widValFont;
        var lf = _widLblFont;
        var just = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.setPenWidth((4 * s).toNumber());
        dc.setColor(col, Graphics.COLOR_BLACK);
        dc.drawCircle(x, y, r);
        dc.drawText(x, y - (9 * s).toNumber(), (vf != null) ? vf : Graphics.FONT_XTINY, wd[0], just);
        dc.setColor(Cfg.dim(col, 0.7), Graphics.COLOR_BLACK);
        dc.drawText(x, y + (20 * s).toNumber(), (lf != null) ? lf : Graphics.FONT_XTINY, wd[1], just);
    }

    // Always-on display: dim time and date only, shifted each minute to limit AMOLED burn-in.
    private function drawLowPower(dc as Dc, cx as Number, cy as Number, s as Float) as Void {
        var m = System.getClockTime().min;
        var dx = ((m % 5) - 2) * 3;
        var dy = (((m / 5) % 5) - 2) * 3;
        drawTime(dc, cx, cy, s, 0x9AA0A6, Graphics.FONT_NUMBER_HOT, dx, dy);
        dc.setColor(0x606670, Graphics.COLOR_BLACK);
        dc.drawText(cx + dx, cy - (110 * s).toNumber() + dy, Graphics.FONT_SMALL, dateString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
