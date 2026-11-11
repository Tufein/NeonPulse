import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Layout is designed for the 454x454 round AMOLED of the Fenix 8 51mm and scales to other sizes.
// All coordinates below are in 454px units and multiplied by s.
// Angles follow Garmin's convention: 0 = 3 o'clock, counter-clockwise positive.
class FaceView extends WatchUi.WatchFace {
    private var _lowPower as Boolean = false;

    // Vector fonts, rebuilt when a text size setting changes.
    private var _fontKey as Number = -1;
    private var _arcFont as VectorFont? = null;    // drawRadialText needs a vector font
    private var _widValFont as VectorFont? = null;
    private var _widLblFont as VectorFont? = null;
    private var _topValFont as VectorFont? = null;
    private var _topLblFont as VectorFont? = null;
    private var _dateFont as VectorFont? = null;

    private const JUST = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
    private const CLEAR = Graphics.COLOR_TRANSPARENT;

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

    // ---- fonts -------------------------------------------------------------

    private function loadFonts(w as Number) as Void {
        var key = Cfg.num("LabelSize", 1) * 10 + Cfg.num("TopTextSize", 1);
        if (key == _fontKey) { return; }
        _fontKey = key;
        if (!(Graphics has :getVectorFont)) { return; }
        var ls = Cfg.scale("LabelSize");
        var ts = Cfg.scale("TopTextSize");
        _arcFont = vfont(true, 18 * ls, w);
        _widValFont = vfont(true, 24 * ls, w);
        _widLblFont = vfont(false, 14 * ls, w);
        _dateFont = vfont(true, 24 * ls, w);
        _topValFont = vfont(true, 34 * ts, w);
        _topLblFont = vfont(false, 16 * ts, w);
    }

    // Roboto Condensed vector font; size is in pixels on the 454px screen.
    private function vfont(bold as Boolean, size as Float, w as Number) as VectorFont? {
        var faces = bold ? ["RobotoCondensedBold", "RobotoCondensedRegular", "RobotoRegular"]
                         : ["RobotoCondensedRegular", "RobotoCondensedBold", "RobotoRegular"];
        return Graphics.getVectorFont({ :face => faces, :size => (size * w / 454).toNumber() });
    }

    // Vector font when available, otherwise the given system font.
    private function pick(v as VectorFont?, fallback as FontType) as FontType {
        return (v != null) ? v : fallback;
    }

    // ---- main face ---------------------------------------------------------

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var cx = w / 2;
        var cy = dc.getHeight() / 2;
        var s = w / 454.0;
        loadFonts(w);

        if (_lowPower) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.clear();
            drawLowPower(dc, cx, cy, s);
            return;
        }
        dc.setColor(Graphics.COLOR_WHITE, Cfg.background());
        dc.clear();
        if (dc has :setAntiAlias) { dc.setAntiAlias(true); }

        drawTicks(dc, cx, cy, s);

        var aw = Cfg.arcScale();
        var topStyle = Cfg.num("TopStyle", 0); // 0 arc + value, 1 value only, 2 arc only
        if (topStyle != 1) { gauge(dc, cx, cy, s, "Top", 200, 135, 90, true, 10 * aw); }
        gauge(dc, cx, cy, s, "Right", 200, -30, 60, false, 10 * aw);
        gauge(dc, cx, cy, s, "Left1", 200, 210, 60, true, 8 * aw);
        gauge(dc, cx, cy, s, "Left2", 186, 210, 60, true, 8 * aw);
        gauge(dc, cx, cy, s, "Left3", 172, 210, 60, true, 8 * aw);
        gauge(dc, cx, cy, s, "Bottom", 200, 220, 100, false, 10 * aw);

        if (topStyle != 2) { drawTopText(dc, cx, s); }
        if (Metrics.charging()) { drawChargeBadge(dc, cx, (50 * s).toNumber(), s); }
        drawSideText(dc, cx, cy, s);
        if (Cfg.flag("ShowDate", true)) {
            dc.setColor(Cfg.color("DateColor"), CLEAR);
            dc.drawText(cx, (134 * s).toNumber(), pick(_dateFont, Graphics.FONT_XTINY), dateString(), JUST);
        }
        var large = Cfg.num("TimeSize", 0) == 1;
        drawTime(dc, cx, cy, s, Cfg.color("TimeColor"),
            large ? Graphics.FONT_NUMBER_MEDIUM : Graphics.FONT_NUMBER_MILD, 0, 0);

        var wy = cy + (90 * s).toNumber();
        var wr = (46 * s).toNumber();
        var wdx = (104 * s).toNumber();
        drawWidget(dc, cx - wdx, wy, wr, s, "W1");
        drawWidget(dc, cx, wy, wr, s, "W2");
        drawWidget(dc, cx + wdx, wy, wr, s, "W3");
    }

    // ---- drawing helpers -----------------------------------------------------

    private function norm(a as Number) as Number {
        return ((a % 360) + 360) % 360;
    }

    private function px(cx as Number, deg as Float, r as Float) as Float {
        return cx + Math.cos(Math.toRadians(deg)) * r;
    }

    private function py(cy as Number, deg as Float, r as Float) as Float {
        return cy - Math.sin(Math.toRadians(deg)) * r;
    }

    // Arc with rounded ends: dim full-length track, bright fill for the metric's fraction.
    private function arcRounded(dc as Dc, cx as Number, cy as Number, r as Number, startDeg as Number,
                                span as Number, cw as Boolean, pen as Number, col as Number, frac as Float) as Void {
        var attr = cw ? Graphics.ARC_CLOCKWISE : Graphics.ARC_COUNTER_CLOCKWISE;
        var dir = cw ? -1 : 1;
        var endDeg = startDeg + dir * span;
        var cap = pen / 2.0;

        dc.setPenWidth(pen);
        dc.setColor(Cfg.dim(col, 0.2), CLEAR);
        dc.drawArc(cx, cy, r, attr, norm(startDeg), norm(endDeg));
        dc.fillCircle(px(cx, startDeg.toFloat(), r.toFloat()), py(cy, startDeg.toFloat(), r.toFloat()), cap);
        dc.fillCircle(px(cx, endDeg.toFloat(), r.toFloat()), py(cy, endDeg.toFloat(), r.toFloat()), cap);

        if (frac > 0.01) {
            var fillEnd = startDeg + dir * span * frac;
            dc.setColor(col, CLEAR);
            if (span * frac >= 1.0) {
                dc.drawArc(cx, cy, r, attr, norm(startDeg), norm(fillEnd.toNumber()));
            }
            dc.fillCircle(px(cx, startDeg.toFloat(), r.toFloat()), py(cy, startDeg.toFloat(), r.toFloat()), cap);
            dc.fillCircle(px(cx, fillEnd.toFloat(), r.toFloat()), py(cy, fillEnd.toFloat(), r.toFloat()), cap);
        }
    }

    private function gauge(dc as Dc, cx as Number, cy as Number, s as Float, slot as String,
                           radius as Number, startDeg as Number, span as Number,
                           cw as Boolean, pen as Float) as Void {
        var id = Cfg.num(slot + "Field", 0);
        if (id == 0) { return; }
        var m = Metrics.get(id);
        var p = (pen * s).toNumber();
        if (p < 2) { p = 2; }
        arcRounded(dc, cx, cy, (radius * s).toNumber(), startDeg, span, cw, p,
            Cfg.color(slot + "Color"), m[0] as Float);
    }

    private function drawTicks(dc as Dc, cx as Number, cy as Number, s as Float) as Void {
        var style = Cfg.num("TickStyle", 0); // 0 all minutes, 1 hours only, 2 none
        var tick = Cfg.dim(Cfg.color("TickColor"), 0.6);
        var showSec = Cfg.flag("ShowSeconds", true);
        var sec = System.getClockTime().sec;
        var outer = 226 * s;
        for (var i = 0; i < 60; i++) {
            var hour = (i % 5 == 0);
            if (style == 2 || (style == 1 && !hour)) { continue; }
            if (showSec && i == sec) { continue; } // the seconds marker replaces this tick
            var deg = (90 - i * 6).toFloat();
            var inner = (hour ? 212 : 219) * s;
            dc.setColor(hour ? tick : Cfg.dim(tick, 0.6), CLEAR);
            dc.setPenWidth(((hour ? 4 : 2) * s).toNumber());
            dc.drawLine(px(cx, deg, inner), py(cy, deg, inner), px(cx, deg, outer), py(cy, deg, outer));
        }
        if (showSec) {
            var deg = (90 - sec * 6).toFloat();
            dc.setColor(Cfg.color("SecColor"), CLEAR);
            dc.setPenWidth((4 * s).toNumber());
            dc.drawLine(px(cx, deg, 207 * s), py(cy, deg, 207 * s), px(cx, deg, outer), py(cy, deg, outer));
        }
    }

    // Text bent along the circle, falling back to plain text if unsupported.
    private function radial(dc as Dc, cx as Number, cy as Number, text as String,
                            angle as Number, radius as Number, cw as Boolean) as Void {
        var vf = _arcFont;
        if (vf != null && (dc has :drawRadialText)) {
            dc.drawRadialText(cx, cy, vf, text, Graphics.TEXT_JUSTIFY_CENTER, angle, radius,
                cw ? Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE : Graphics.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE);
        } else {
            var a = angle.toFloat();
            dc.drawText(px(cx, a, radius.toFloat()), py(cy, a, radius.toFloat()), Graphics.FONT_XTINY, text, JUST);
        }
    }

    // Value of the top arc (battery by default) with its unit/status underneath.
    private function drawTopText(dc as Dc, cx as Number, s as Float) as Void {
        var id = Cfg.num("TopField", 0);
        if (id == 0) { return; }
        var m = Metrics.get(id);
        var col = Cfg.color("TopColor");
        var ts = Cfg.scale("TopTextSize");
        var units = Cfg.flag("ShowUnits", true);
        var vy = units ? 80 : 88;
        dc.setColor(col, CLEAR);
        dc.drawText(cx, (vy * s).toNumber(), pick(_topValFont, Graphics.FONT_TINY), m[1], JUST);
        if (units) {
            dc.setColor(Cfg.dim(col, 0.75), CLEAR);
            dc.drawText(cx, ((80 + 23 * ts) * s).toNumber(), pick(_topLblFont, Graphics.FONT_XTINY), m[2], JUST);
        }
    }

    // Small circle with a lightning bolt, shown at 12 o'clock while charging.
    private function drawChargeBadge(dc as Dc, x as Number, y as Number, s as Float) as Void {
        var col = Cfg.color("TopColor");
        var r = 13 * s;
        dc.setColor(Cfg.dim(col, 0.25), CLEAR);
        dc.fillCircle(x, y, r);
        dc.setColor(col, CLEAR);
        dc.setPenWidth((2 * s).toNumber());
        dc.drawCircle(x, y, r);
        drawIcon(dc, 6, x, y, 8 * s);
    }

    private function drawSideText(dc as Dc, cx as Number, cy as Number, s as Float) as Void {
        var units = Cfg.flag("ShowUnits", true);
        // Right: value + unit running downward.
        var id = Cfg.num("RightField", 0);
        if (id != 0) {
            var m = Metrics.get(id);
            dc.setColor(Cfg.color("RightColor"), CLEAR);
            radial(dc, cx, cy, units ? m[1] + " " + m[2] : m[1], 0, (170 * s).toNumber(), true);
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
            var wf = pick(_arcFont, Graphics.FONT_XTINY);
            var gap = 10 * s;
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
                dc.setColor(cols[i], CLEAR);
                radial(dc, cx, cy, texts[i], (a - half).toNumber(), lr, true);
                a -= 2.0 * half + gap * degPerPx;
            }
        }
        // Bottom: unit + value reading left to right.
        var bid = Cfg.num("BottomField", 0);
        if (bid != 0) {
            var bm = Metrics.get(bid);
            dc.setColor(Cfg.color("BottomColor"), CLEAR);
            radial(dc, cx, cy, units ? bm[2] + "  " + bm[1] : bm[1], 270, (170 * s).toNumber(), false);
        }
    }

    private function dateString() as String {
        var fmt = Cfg.num("DateFormat", 0); // 0 "SUN 1 NOV", 1 "1 NOV", 2 "01/11"
        if (fmt == 2) {
            var n = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
            return (n.day as Number).format("%02d") + "/" + (n.month as Number).format("%02d");
        }
        var i = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        if (fmt == 1) {
            return (i.day + " " + i.month).toUpper();
        }
        return (i.day_of_week + " " + i.day + " " + i.month).toUpper();
    }

    private function drawTime(dc as Dc, cx as Number, cy as Number, s as Float, color as Number,
                              font as FontType, dx as Number, dy as Number) as Void {
        var t = System.getClockTime();
        var fmt = Cfg.num("TimeFormat", 0); // 0 watch setting, 1 12h, 2 24h
        var is24 = (fmt == 0) ? System.getDeviceSettings().is24Hour : (fmt == 2);
        var h = t.hour;
        if (!is24) {
            h = h % 12;
            if (h == 0) { h = 12; }
        }
        dc.setColor(color, CLEAR);
        dc.drawText(cx + dx, cy - (20 * s).toNumber() + dy, font,
            h.format("%d") + ":" + t.min.format("%02d"), JUST);
    }

    // Round widget: progress ring (or plain ring), small icon, value and label.
    private function drawWidget(dc as Dc, x as Number, y as Number, r as Number, s as Float, slot as String) as Void {
        var id = Cfg.num(slot + "Field", 0);
        if (id == 0) { return; }
        var col = Cfg.color(slot + "Color");
        var wd = Metrics.widget(id);
        var frac = wd[2] as Float;
        var pen = (4 * s).toNumber();

        if (Cfg.flag("WidgetRing", true)) {
            dc.setPenWidth(pen);
            if (frac < 0.0) {
                dc.setColor(Cfg.dim(col, 0.55), CLEAR);
                dc.drawCircle(x, y, r);
            } else {
                dc.setColor(Cfg.dim(col, 0.2), CLEAR);
                dc.drawCircle(x, y, r);
                if (frac > 0.01) {
                    arcRounded(dc, x, y, r, 90, (360 * frac).toNumber(), true, pen, col, 1.0);
                }
            }
        }
        var units = Cfg.flag("ShowUnits", true);
        drawIconColored(dc, id, x, y - (24 * s).toNumber(), 7 * s, col);
        dc.setColor(col, CLEAR);
        dc.drawText(x, y + ((units ? 0 : 4) * s).toNumber(), pick(_widValFont, Graphics.FONT_XTINY), wd[0], JUST);
        if (units) {
            dc.setColor(Cfg.dim(col, 0.7), CLEAR);
            dc.drawText(x, y + (22 * s).toNumber(), pick(_widLblFont, Graphics.FONT_XTINY), wd[1], JUST);
        }
    }

    private function drawIconColored(dc as Dc, id as Number, x as Number, y as Number, h as Float, col as Number) as Void {
        dc.setColor(col, CLEAR);
        drawIcon(dc, id, x, y, h);
    }

    // Tiny line-art icons, h = half height. ids follow the widget list.
    private function drawIcon(dc as Dc, id as Number, x as Number, y as Number, h as Float) as Void {
        var pw = (h / 3.5).toNumber();
        if (pw < 1) { pw = 1; }
        dc.setPenWidth(pw);
        if (id == 1) { // thermometer
            dc.drawRoundedRectangle(x - h * 0.3, y - h, h * 0.6, h * 1.3, h * 0.3);
            dc.fillCircle(x, y + h * 0.55, h * 0.45);
        } else if (id == 2) { // battery
            dc.drawRectangle(x - h, y - h * 0.5, h * 1.8, h);
            dc.fillRectangle(x + h * 0.8, y - h * 0.25, h * 0.3, h * 0.5);
            dc.fillRectangle(x - h * 0.75, y - h * 0.28, h * 1.1, h * 0.56);
        } else if (id == 3) { // heart
            dc.fillCircle(x - h * 0.45, y - h * 0.25, h * 0.5);
            dc.fillCircle(x + h * 0.45, y - h * 0.25, h * 0.5);
            dc.fillPolygon([[x - h * 0.93, y - h * 0.05], [x + h * 0.93, y - h * 0.05], [x, y + h]]);
        } else if (id == 4) { // steps: two footprints
            dc.fillEllipse(x - h * 0.4, y - h * 0.15, h * 0.3, h * 0.55);
            dc.fillEllipse(x + h * 0.4, y + h * 0.15, h * 0.3, h * 0.55);
        } else if (id == 5) { // calories: flame
            dc.fillCircle(x, y + h * 0.35, h * 0.6);
            dc.fillPolygon([[x - h * 0.58, y + h * 0.25], [x + h * 0.58, y + h * 0.25], [x + h * 0.1, y - h]]);
        } else if (id == 6) { // body battery / charging: lightning bolt
            dc.fillPolygon([[x + h * 0.2, y - h], [x - h * 0.6, y + h * 0.15], [x - h * 0.05, y + h * 0.15],
                            [x - h * 0.2, y + h], [x + h * 0.6, y - h * 0.15], [x + h * 0.05, y - h * 0.15]]);
        } else if (id == 7) { // floors: stairs
            var st = h * 0.66;
            dc.fillRectangle(x - h, y + h - st, st, st);
            dc.fillRectangle(x - h + st, y + h - 2 * st, st, 2 * st);
            dc.fillRectangle(x - h + 2 * st, y - h, st, 3 * st);
        } else if (id == 8) { // notifications: bell
            dc.fillPolygon([[x - h * 0.55, y + h * 0.5], [x + h * 0.55, y + h * 0.5],
                            [x + h * 0.45, y - h * 0.4], [x - h * 0.45, y - h * 0.4]]);
            dc.fillCircle(x, y - h * 0.4, h * 0.45);
            dc.fillRectangle(x - h * 0.85, y + h * 0.45, h * 1.7, h * 0.2);
            dc.fillCircle(x, y + h * 0.85, h * 0.2);
        } else if (id == 9) { // stress: zig-zag line
            dc.drawLine(x - h, y, x - h * 0.5, y);
            dc.drawLine(x - h * 0.5, y, x - h * 0.2, y - h * 0.8);
            dc.drawLine(x - h * 0.2, y - h * 0.8, x + h * 0.2, y + h * 0.8);
            dc.drawLine(x + h * 0.2, y + h * 0.8, x + h * 0.5, y);
            dc.drawLine(x + h * 0.5, y, x + h, y);
        }
    }

    // Always-on display: black background, dimmed time and date plus a battery figure,
    // the whole block shifted each minute to limit AMOLED burn-in.
    private function drawLowPower(dc as Dc, cx as Number, cy as Number, s as Float) as Void {
        var m = System.getClockTime().min;
        var dx = (((m % 5) - 2) * 4 * s).toNumber();
        var dy = ((((m / 5) % 5) - 2) * 4 * s).toNumber();
        var large = Cfg.num("TimeSize", 0) == 1;
        drawTime(dc, cx, cy, s, Cfg.dim(Cfg.color("TimeColor"), 0.6),
            large ? Graphics.FONT_NUMBER_MEDIUM : Graphics.FONT_NUMBER_MILD, dx, dy);
        if (Cfg.flag("ShowDate", true)) {
            dc.setColor(Cfg.dim(Cfg.color("DateColor"), 0.45), CLEAR);
            dc.drawText(cx + dx, (134 * s).toNumber() + dy, pick(_dateFont, Graphics.FONT_XTINY), dateString(), JUST);
        }
        var batt = System.getSystemStats().battery.toNumber();
        dc.setColor(Cfg.dim(Cfg.color("TopColor"), 0.45), CLEAR);
        dc.drawText(cx + dx, cy + (80 * s).toNumber() + dy, pick(_widValFont, Graphics.FONT_XTINY), batt + "%", JUST);
    }
}
