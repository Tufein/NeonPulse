import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Weather;

// Every data field a face in the series can show. One id list for all faces, so the
// generated settings (tools/series.py, FIELDS) stay identical everywhere.
//   0 none, 1 battery, 2 heart rate, 3 steps, 4 calories, 5 active minutes,
//   6 body battery, 7 floors, 8 distance, 9 stress, 10 altitude, 11 temperature,
//   12 notifications, 13 next sunrise/sunset
// get(id) returns [fraction 0..1 or -1.0 when the field has no goal, value text, label].
module Stats {
    function clamp(v as Float) as Float {
        if (v < 0.0) { return 0.0; }
        if (v > 1.0) { return 1.0; }
        return v;
    }

    function battery() as Number {
        return System.getSystemStats().battery.toNumber();
    }

    function charging() as Boolean {
        var st = System.getSystemStats();
        return (st has :charging) && st.charging;
    }

    function heartRate() as Number? {
        var ai = Activity.getActivityInfo();
        if (ai != null && ai.currentHeartRate != null) { return ai.currentHeartRate; }
        if (ActivityMonitor has :getHeartRateHistory) {
            var s = ActivityMonitor.getHeartRateHistory(1, true).next();
            if (s != null && s.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) { return s.heartRate; }
        }
        return null;
    }

    function bodyBattery() as Number? {
        if ((Toybox has :SensorHistory) && (SensorHistory has :getBodyBatteryHistory)) {
            var it = SensorHistory.getBodyBatteryHistory({ :period => 1 });
            var s = (it != null) ? it.next() : null;
            if (s != null && s.data != null) { return s.data.toNumber(); }
        }
        return null;
    }

    // Altitude in metres, or feet when the watch uses statute elevation units.
    function altitude() as Number? {
        var ai = Activity.getActivityInfo();
        if (ai == null || ai.altitude == null) { return null; }
        var a = ai.altitude.toFloat();
        if (System.getDeviceSettings().elevationUnits == System.UNIT_STATUTE) { a = a * 3.28084; }
        return a.toNumber();
    }

    function temperature() as Number? {
        if (!(Toybox has :Weather)) { return null; }
        var c = Weather.getCurrentConditions();
        if (c == null || c.temperature == null) { return null; }
        var deg = c.temperature.toFloat();
        if (System.getDeviceSettings().temperatureUnits == System.UNIT_STATUTE) { deg = deg * 9.0 / 5.0 + 32.0; }
        return deg.toNumber();
    }

    function get(id as Number) as Array {
        var info = ActivityMonitor.getInfo();
        if (id == 1) {
            var b = battery();
            return [clamp(b / 100.0), b.toString() + "%", "BATT"];
        } else if (id == 2) {
            var hr = heartRate();
            if (hr == null) { return [0.0, "--", "BPM"]; }
            return [clamp((hr - 40) / 150.0), hr.toString(), "BPM"];
        } else if (id == 3) {
            var goal = (info.stepGoal != null && info.stepGoal > 0) ? info.stepGoal : 10000;
            var v = (info.steps != null) ? info.steps : 0;
            return [clamp(v.toFloat() / goal), v.toString(), "STEPS"];
        } else if (id == 4) {
            var v = (info.calories != null) ? info.calories : 0;
            return [clamp(v.toFloat() / 2500.0), v.toString(), "KCAL"];
        } else if (id == 5) {
            var am = info.activeMinutesDay;
            var v = (am != null) ? am.total : 0;
            var goal = (info.activeMinutesWeekGoal != null && info.activeMinutesWeekGoal > 0)
                ? info.activeMinutesWeekGoal / 7.0 : 30.0;
            return [clamp(v / goal), v.toString(), "ACTIVE"];
        } else if (id == 6) {
            var bb = bodyBattery();
            if (bb == null) { return [0.0, "--", "ENERGY"]; }
            return [clamp(bb / 100.0), bb.toString(), "ENERGY"];
        } else if (id == 7) {
            var goal = (info.floorsClimbedGoal != null && info.floorsClimbedGoal > 0) ? info.floorsClimbedGoal : 10;
            var v = (info.floorsClimbed != null) ? info.floorsClimbed : 0;
            return [clamp(v.toFloat() / goal), v.toString(), "FLOORS"];
        } else if (id == 8) {
            var cm = (info.distance != null) ? info.distance : 0;
            if (System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE) {
                var mi = cm / 160934.4;
                return [clamp(mi / 6.0), mi.format("%.1f"), "MI"];
            }
            var km = cm / 100000.0;
            return [clamp(km / 10.0), km.format("%.1f"), "KM"];
        } else if (id == 9) {
            var s = info.stressScore;
            if (s == null) { return [0.0, "--", "STRESS"]; }
            return [clamp(s / 100.0), s.toString(), "STRESS"];
        } else if (id == 10) {
            var a = altitude();
            var ft = System.getDeviceSettings().elevationUnits == System.UNIT_STATUTE;
            return [-1.0, (a == null) ? "--" : a.toString(), ft ? "ALT FT" : "ALT M"];
        } else if (id == 11) {
            var t = temperature();
            return [-1.0, (t == null) ? "--" : t.toString() + "°", "TEMP"];
        } else if (id == 12) {
            var n = System.getDeviceSettings().notificationCount;
            return [-1.0, (n != null ? n : 0).toString(), "ALERTS"];
        } else if (id == 13) {
            var sun = Kit.sun();
            if (sun == null) { return [-1.0, "--:--", "SUN"]; }
            var now = Kit.nowHours();
            if (now >= sun[0] && now < sun[1]) { return [-1.0, Kit.clockText(sun[1] as Float), "SUNSET"]; }
            return [-1.0, Kit.clockText(sun[0] as Float), "SUNRISE"];
        }
        return [-1.0, "", ""];
    }
}
