# Contributing to Vivid Orbit

Vivid Orbit is a single-device watchface for the Garmin fenix 8. Changes are small and mostly about
what the dial draws and what it costs in battery.

## Layout

- `source/FaceApp.mc` — lifecycle; `source/FaceView.mc` — all drawing; `source/Metrics.mc` — which
  activity/health values feed the arcs and widgets; `source/Cfg.mc` — settings lookups and the palette.
- `tools/gen_settings.py` is the single source of truth for the settings UI: it writes
  `resources/properties/properties.xml`, `resources/settings/settings.xml` and
  `resources/strings/strings.xml`.
- `docs/PUBLISHING.md` (Dutch) covers building, signing and the private beta route.

## Checks you should run

```sh
python3 tools/gen_settings.py      # after editing the settings tables
python3 tools/check_resources.py   # every @Strings/@Drawables/@Properties reference resolves
```

CI runs both. The second check also catches a literal key in `Cfg.num("…")` that no longer exists, so
regenerate the resources before you push.

## Build

Building needs the Connect IQ SDK and a Java runtime (not installed in CI, so CI does not compile):

```sh
monkeyc -d fenix847mm -f monkey.jungle -o bin/VividOrbit.prg -y ~/.garmin-keys/developer_key.der
monkeydo bin/VividOrbit.prg fenix847mm
```

Never commit the developer key or the built `.iq`/`.prg` files; `.gitignore` already excludes them.

## Conventions

- The dial draws in 454-pixel units and scales from the screen width, so keep coordinates in those
  units instead of hard-coding another device's size.
- Anything that runs every minute update costs battery: prefer caching property lookups over reading
  them per frame, and say in the pull request what you noticed in the simulator.
- Burn-in avoidance is a feature: the always-on path stays dimmed and offset (`drawLowPower`).
- Adding a device means editing `<iq:products>` in `manifest.xml` **and** the supported-devices list
  in `README.md`, then checking the dial in the simulator for that device.
