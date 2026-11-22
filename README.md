# Ion Ring (Garmin Connect IQ watchface)

Customizable ring-style watchface for the Garmin Fenix 8 51mm AMOLED (454x454).

- 6 gauge arcs (top, right, 3 left, bottom) with rounded ends, a dim track and a bright fill
- Optional neon glow under every arc, widget ring and the seconds marker
- 3 round widgets with a progress ring (steps, battery, calories, ...), a small icon, value and label
- Battery on the top arc by default, with a bolt badge at 12 o'clock while charging
- Slashed-phone badge at 12 o'clock when the phone is out of range
- Battery metrics turn red at 20% or less
- 4 color themes (Neon, Sunset, Arctic, Mono) plus Custom, which keeps the per-element colors
- Distance follows the watch's kilometre/mile setting
- Seconds marker on the tick ring (line or pulse dot), burn-in shifted always-on face
  (dimmed time, date and battery)

## Settings
All options are in the Garmin Connect app / Connect IQ settings. Defaults give the standard look.

| Setting | Options |
| --- | --- |
| Arc / widget data fields | Battery, heart rate, steps, calories, active minutes, body battery, floors, distance, stress, temperature, notifications |
| Colors (every element) | White, Mint, Red, Amber, Blue, Pink, Purple, Orange, Yellow, Grey, Custom color 1, Custom color 2 |
| Color theme | Custom (element colors), Neon, Sunset, Arctic, Mono — a preset overrides the per-element colors |
| Custom color 1 / 2 | Hex text, e.g. `33CCFF` or `#33CCFF` (invalid text falls back to cyan / magenta) |
| Top arc style | Arc + value, Value only, Arc only |
| Top value size | Small, Medium, Large |
| Label text size | Small, Medium, Large (arc labels, date, widgets) |
| Show units | On / Off |
| Arc thickness | Thin, Normal, Thick |
| Neon glow | On / Off (wide dim underlay that fakes an AMOLED glow) |
| Tick marks | All minutes, Hours only, None (+ tick color, seconds marker on/off and color) |
| Seconds marker style | Line, Dot (the dot gets a glow halo) |
| Time size / format | Normal, Large / Watch setting, 12 hour, 24 hour |
| Date format | SUN 1 NOV, 1 NOV, 01/11 (+ show date, date color) |
| Widget rings | On / Off |
| Background | Black, Charcoal, Navy, Plum, Forest |
| Always-on content | Time, date + battery; Time + battery; Time only |
| Shift always-on screen | On / Off (moves the dimmed block each minute against AMOLED burn-in) |
| Phone connection alert | On / Off (badge at 12 o'clock while disconnected) |
| Low battery warning | On / Off (battery metrics turn red at 20%) |
| Goals | Calorie goal, distance goal (km or mi, following the watch), max heart rate |

The settings XML is generated: edit `tools/gen_settings.py` and run `python3 tools/gen_settings.py`.

## Build
Install the Connect IQ SDK (SDK Manager) and a Java runtime, then:

    monkeyc -d fenix847mm -f monkey.jungle -o bin/IonRing.prg -y ~/.garmin-keys/developer_key.der
    connectiq   # start the simulator, then:
    monkeydo bin/IonRing.prg fenix847mm

`fenix847mm` is Garmin's device id for the fenix 8 47mm *and* 51mm AMOLED (454x454);
there is no separate 51mm id. Keep the developer key outside the repo.

## Install on the watch
Connect the watch by USB and copy `bin/IonRing.prg` into `GARMIN/APPS/` on the watch
(on macOS use Garmin Express or OpenMTP / Android File Transfer, since the fenix 8 uses MTP).
Unplug, then pick Ion Ring under Watch Face on the watch.

Add more devices in manifest.xml `<iq:products>`.

## Checks

No SDK or network is needed for these, and CI runs both on every push and pull request:

    python3 tools/check_resources.py   # every @Strings/@Drawables/@Properties reference resolves
    python3 tools/gen_settings.py      # regenerate settings, then commit the diff

The settings XML in `resources/` is generated from `tools/gen_settings.py`; editing it by hand
makes the second check fail. Building and signing still need the Connect IQ SDK (see above), so
CI does not compile the face.

## License

Ion Ring is released under the [MIT license](LICENSE). The Garmin Connect IQ SDK, its APIs and the
device names are Garmin's; this watchface is an independent project and is not affiliated with Garmin.

## Security

See [SECURITY.md](SECURITY.md) for how to report a vulnerability and which secrets this project stores.

## Documentation

[Preview](docs/preview.html) · [Contributing](CONTRIBUTING.md) · [Security](SECURITY.md) · [Publishing](docs/PUBLISHING.md)
