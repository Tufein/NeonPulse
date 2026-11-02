# Vivid Orbit (Garmin Connect IQ watchface)

Customizable ring-style watchface for the Garmin Fenix 8 51mm AMOLED (454x454).

- 6 gauge arcs (top, right, 3 left, bottom) with rounded ends, a dim track and a bright fill
- 3 round widgets with a progress ring (steps, battery, calories, ...), a small icon, value and label
- Battery on the top arc by default, with a bolt badge at 12 o'clock while charging
- Seconds marker on the tick ring, burn-in shifted always-on face (dimmed time, date and battery)

## Settings
All options are in the Garmin Connect app / Connect IQ settings. Defaults give the standard look.

| Setting | Options |
| --- | --- |
| Arc / widget data fields | Battery, heart rate, steps, calories, active minutes, body battery, floors, distance, stress, temperature, notifications |
| Colors (every element) | White, Mint, Red, Amber, Blue, Pink, Purple, Orange, Yellow, Grey, Custom color 1, Custom color 2 |
| Custom color 1 / 2 | Hex text, e.g. `33CCFF` or `#33CCFF` (invalid text falls back to cyan / magenta) |
| Top arc style | Arc + value, Value only, Arc only |
| Top value size | Small, Medium, Large |
| Label text size | Small, Medium, Large (arc labels, date, widgets) |
| Show units | On / Off |
| Arc thickness | Thin, Normal, Thick |
| Tick marks | All minutes, Hours only, None (+ tick color, seconds marker on/off and color) |
| Time size / format | Normal, Large / Watch setting, 12 hour, 24 hour |
| Date format | SUN 1 NOV, 1 NOV, 01/11 (+ show date, date color) |
| Widget rings | On / Off |
| Background | Black, Charcoal, Navy, Plum, Forest |
| Goals | Calorie goal, distance goal, max heart rate |

The settings XML is generated: edit `tools/gen_settings.py` and run `python3 tools/gen_settings.py`.

## Build
Install the Connect IQ SDK (SDK Manager) and a Java runtime, then:

    monkeyc -d fenix847mm -f monkey.jungle -o bin/VividOrbit.prg -y ~/.garmin-keys/developer_key.der
    connectiq   # start the simulator, then:
    monkeydo bin/VividOrbit.prg fenix847mm

`fenix847mm` is Garmin's device id for the fenix 8 47mm *and* 51mm AMOLED (454x454);
there is no separate 51mm id. Keep the developer key outside the repo.

## Install on the watch
Connect the watch by USB and copy `bin/VividOrbit.prg` into `GARMIN/APPS/` on the watch
(on macOS use Garmin Express or OpenMTP / Android File Transfer, since the fenix 8 uses MTP).
Unplug, then pick Vivid Orbit under Watch Face on the watch.

Add more devices in manifest.xml `<iq:products>`.
