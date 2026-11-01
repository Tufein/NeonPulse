# Neon Pulse (Garmin Connect IQ watchface)

Customizable ring-style watchface for the Garmin Fenix 8 51mm AMOLED (454x454).

- 6 gauge arcs (top, right, 3 left, bottom) and 3 round widgets, each with a selectable data field and color
- Battery, heart rate, steps, calories, active minutes, body battery, floors, distance, stress, temperature, notifications
- Seconds marker on the tick ring, date toggle, always-on mode with burn-in shifting
- All options live in the Garmin Connect app / Connect IQ settings (resources/settings/settings.xml)

## Build
Install the Connect IQ SDK (SDK Manager), then:

    monkeyc -d fenix8amoled51mm -f monkey.jungle -o bin/NeonPulse.prg -y developer_key.der
    connectiq   # start the simulator, then:
    monkeydo bin/NeonPulse.prg fenix8amoled51mm

Add more devices in manifest.xml `<iq:products>`.
