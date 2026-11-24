# AGENTS.md — Ion Ring (repo: NeonPulse)

Instructions for coding agents (OpenCode, Claude Code, Codex and similar). `CONTRIBUTING.md` is
loaded alongside this file through `opencode.json`.

## Project

Garmin Connect IQ watchface for the fenix 8 51mm AMOLED (454×454). Formerly NeonPulse, now branded
**Ion Ring**. Six gauge arcs, three round widgets, neon glow, colour themes and a burn-in-safe
always-on mode. All options are Connect IQ settings.

- Language: Monkey C; manifest `manifest.xml`, build file `monkey.jungle`
- Helper scripts: Python 3.12

## Layout

| Path | What lives there |
| --- | --- |
| `source/FaceApp.mc` | Lifecycle |
| `source/FaceView.mc` | All drawing (including `drawLowPower`) |
| `source/Metrics.mc` | Which activity/health values feed arcs and widgets |
| `source/Cfg.mc` | Settings lookups and palette |
| `resources/` | Generated properties, settings and strings, plus drawables |
| `tools/gen_settings.py` | **Single source of truth** for the settings UI; regenerates `resources/{properties,settings,strings}` |
| `tools/check_resources.py` | Verifies every `@Strings/@Drawables/@Properties` reference and `Cfg.num("…")` key |
| `docs/PUBLISHING.md` | (Dutch) build, sign and private-beta upload |

## Checks

```sh
python3 tools/gen_settings.py       # after editing the settings tables; never hand-edit generated XML
python3 tools/check_resources.py
git diff --exit-code resources      # CI fails if generated resources are out of date
```

Building needs the Connect IQ SDK and a Java runtime; CI does not compile:

```sh
monkeyc -d fenix847mm -f monkey.jungle -o bin/IonRing.prg -y ~/.garmin-keys/developer_key.der
monkeydo bin/IonRing.prg fenix847mm
```

## Rules

- Never commit the developer key or built `.iq`/`.prg` files.
- Keep coordinates in 454-pixel units scaled from screen width.
- Per-minute work costs battery: cache property lookups, do not read them per frame.
- Always-on path stays dimmed and offset (burn-in protection is a feature).
- Adding a device: edit `<iq:products>` in `manifest.xml` and the device list in `README.md`.

## Release process

Build the store package with `monkeyc -e -f monkey.jungle -o bin/IonRing.iq -y <key>` and upload it to
the Garmin developer portal as a (beta) Watch Face, see `docs/PUBLISHING.md`. The owner also wants a
GitHub release with notes explaining what changed in the code.
