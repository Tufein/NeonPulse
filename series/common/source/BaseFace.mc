import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Entry point shared by every face; each face defines its own FaceView.
class SeriesApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [ new FaceView() ];
    }

    function onSettingsChanged() {
        WatchUi.requestUpdate();
    }
}

// Base class for every face. It handles sleep mode, the AMOLED always-on screen and
// screen geometry, so a face only implements drawFace (and optionally drawAod).
//   AMOLED, asleep: drawAod on black, shifted every minute against burn-in.
//   MIP, asleep:    drawFace with awake = false (faces hide their seconds).
class BaseFace extends WatchUi.WatchFace {
    protected var _awake as Boolean = true;
    protected var _amoled as Boolean = false;

    function initialize() {
        WatchFace.initialize();
        _amoled = Kit.amoled();
    }

    function onEnterSleep() as Void {
        _awake = false;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _awake = true;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var sc = new Kit.Screen(dc);
        if (dc has :setAntiAlias) { dc.setAntiAlias(true); }
        if (!_awake && _amoled) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.clear();
            var m = System.getClockTime().min;
            // Moves the always-on content around a small 3x3 grid, one step per minute.
            var dx = ((m % 3) - 1) * sc.n(10);
            var dy = (((m / 3) % 3) - 1) * sc.n(10);
            drawAod(dc, sc, dx, dy);
            return;
        }
        dc.setColor(Graphics.COLOR_WHITE, background());
        dc.clear();
        drawFace(dc, sc, _awake);
    }

    // Background color; faces override for their own look.
    function background() as Number {
        return Graphics.COLOR_BLACK;
    }

    // Full face. awake is false on MIP screens in low power mode.
    function drawFace(dc as Dc, sc as Kit.Screen, awake as Boolean) as Void {
    }

    // Default always-on screen: dimmed time and date. Keep lit pixels well under 10%.
    function drawAod(dc as Dc, sc as Kit.Screen, dx as Number, dy as Number) as Void {
        var t = System.getClockTime();
        var font = Kit.pick(Kit.vfont(true, 110, sc), Graphics.FONT_NUMBER_MEDIUM);
        dc.setColor(0x8A8A8A, Graphics.COLOR_TRANSPARENT);
        dc.drawText(sc.cx + dx, sc.cy + dy, font, Kit.hour(t.hour).toString() + ":" + Kit.two(t.min),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x5A5A5A, Graphics.COLOR_TRANSPARENT);
        dc.drawText(sc.cx + dx, sc.cy + dy + sc.n(80), Kit.pick(Kit.vfont(false, 26, sc), Graphics.FONT_XTINY),
            Kit.dateText(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
