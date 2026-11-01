import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Weather;

// Every data source the face can show. Each returns [fraction 0..1, value text, unit text].
// Arc ids:    0 none, 1 battery, 2 heart rate, 3 steps, 4 calories, 5 active min, 6 body battery, 7 floors, 8 distance, 9 stress
// Widget ids: 0 none, 1 temperature, 2 battery, 3 heart rate, 4 steps, 5 calories, 6 body battery, 7 floors, 8 notifications, 9 stress
module Metrics {
    function clamp(v as Float) as Float {
        if (v < 0.0) { return 0.0; }
        if (v > 1.0) { return 1.0; }
        return v;
    }

    function heartRate() as Number? {
        var hr = null;
        var ai = Activity.getActivityInfo();
        if (ai != null && ai.currentHeartRate != null) {
            hr = ai.currentHeartRate;
        } else if (ActivityMonitor has :getHeartRateHistory) {
            var it = ActivityMonitor.getHeartRateHistory(1, true);
            var s = it.next();
            if (s != null && s.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                hr = s.heartRate;
            }
        }
        return hr;
    }

    function bodyBattery() as Number? {
        if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getBodyBatteryHistory)) {
            var it = SensorHistory.getBodyBatteryHistory({ :period => 1 });
            var s = (it != null) ? it.next() : null;
            if (s != null && s.data != null) {
                return s.data.toNumber();
            }
        }
        return null;
    }

    function get(id as Number) as Array {
        var info = ActivityMonitor.getInfo();
        if (id == 1) {
            var st = System.getSystemStats();
            return [clamp(st.battery / 100.0), st.battery.toNumber() + "%", st.charging ? "CHARGING" : "BATTERY"];
        } else if (id == 2) {
            var hr = heartRate();
            if (hr == null) { return [0.0, "--", "BPM"]; }
            var mx = Cfg.num("HrMax", 190).toFloat();
            return [clamp((hr - 40) / (mx - 40)), hr.toString(), "BPM"];
        } else if (id == 3) {
            var goal = (info.stepGoal != null && info.stepGoal > 0) ? info.stepGoal : 10000;
            var v = (info.steps != null) ? info.steps : 0;
            return [clamp(v.toFloat() / goal), v.toString(), "STEPS"];
        } else if (id == 4) {
            var v = (info.calories != null) ? info.calories : 0;
            return [clamp(v.toFloat() / Cfg.num("CalorieGoal", 2500)), v.toString(), "KCAL"];
        } else if (id == 5) {
            var am = info.activeMinutesDay;
            var v = (am != null) ? am.total : 0;
            return [clamp(v.toFloat() / 30.0), v.toString(), "MIN"];
        } else if (id == 6) {
            var bb = bodyBattery();
            if (bb == null) { return [0.0, "--", "BODY"]; }
            return [clamp(bb / 100.0), bb.toString(), "BODY"];
        } else if (id == 7) {
            var goal = (info.floorsClimbedGoal != null && info.floorsClimbedGoal > 0) ? info.floorsClimbedGoal : 10;
            var v = (info.floorsClimbed != null) ? info.floorsClimbed : 0;
            return [clamp(v.toFloat() / goal), v.toString(), "FLOORS"];
        } else if (id == 8) {
            var km = (info.distance != null) ? info.distance / 100000.0 : 0.0;
            return [clamp(km / Cfg.num("DistGoal", 10)), km.format("%.1f"), "KM"];
        } else if (id == 9) {
            var s = info.stressScore;
            if (s == null) { return [0.0, "--", "STRESS"]; }
            return [clamp(s / 100.0), s.toString(), "STRESS"];
        }
        return [0.0, "", ""];
    }

    function widget(id as Number) as Array {
        if (id == 1) {
            var t = "--";
            if (Toybox has :Weather) {
                var c = Weather.getCurrentConditions();
                if (c != null && c.temperature != null) {
                    var deg = c.temperature;
                    if (System.getDeviceSettings().temperatureUnits == System.UNIT_STATUTE) {
                        deg = deg * 9.0 / 5.0 + 32.0;
                    }
                    t = deg.toNumber().toString() + "°";
                }
            }
            return [t, "TEMP"];
        } else if (id == 2) {
            var m = get(1);
            return [m[1], "BATT"];
        } else if (id == 3) {
            var m = get(2);
            return [m[1], "BPM"];
        } else if (id == 4) {
            var m = get(3);
            return [m[1], "STEPS"];
        } else if (id == 5) {
            var m = get(4);
            return [m[1], "KCAL"];
        } else if (id == 6) {
            var m = get(6);
            return [m[1], "BODY"];
        } else if (id == 7) {
            var m = get(7);
            return [m[1], "FLOORS"];
        } else if (id == 8) {
            var n = System.getDeviceSettings().notificationCount;
            return [(n != null ? n : 0).toString(), "ALERTS"];
        } else if (id == 9) {
            var m = get(9);
            return [m[1], "STRESS"];
        }
        return ["", ""];
    }
}
