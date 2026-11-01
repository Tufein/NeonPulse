# Neon Pulse (Garmin Connect IQ watchface)

Customizable ring-style watchface for the Garmin Fenix 8 51mm AMOLED (454x454).

- 6 gauge arcs (top, right, 3 left, bottom) and 3 round widgets, each with a selectable data field and color
- Battery, heart rate, steps, calories, active minutes, body battery, floors, distance, stress, temperature, notifications
- Seconds marker on the tick ring, date toggle, always-on mode with burn-in shifting
- All options live in the Garmin Connect app / Connect IQ settings (resources/settings/settings.xml)

## Build
Install the Connect IQ SDK (SDK Manager) and a Java runtime, then:

    monkeyc -d fenix847mm -f monkey.jungle -o bin/NeonPulse.prg -y ~/.garmin-keys/developer_key.der
    connectiq   # start the simulator, then:
    monkeydo bin/NeonPulse.prg fenix847mm

`fenix847mm` is Garmin's device id for the fenix 8 47mm *and* 51mm AMOLED (454x454);
there is no separate 51mm id. Keep the developer key outside the repo.

## Install on the watch
Connect the watch by USB and copy `bin/NeonPulse.prg` into `GARMIN/APPS/` on the watch
(on macOS use Garmin Express or OpenMTP / Android File Transfer, since the fenix 8 uses MTP).
Unplug, then pick Neon Pulse under Watch Face on the watch.

Add more devices in manifest.xml `<iq:products>`.
