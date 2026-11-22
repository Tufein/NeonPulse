# Security and maintenance

Ion Ring is an offline watchface: it has no network access and stores nothing but its own
settings on the watch. The only secret involved is your Garmin developer key, which never belongs in
this repository.

Use GitHub private vulnerability reporting **if the repository owner has enabled it**. No separate
confidential contact is configured in this repository. If private reporting is unavailable, open a
minimal issue asking for a private contact rather than describing the exploit.

## What this project trusts

- **The developer key** (`~/.garmin-keys/developer_key.der`) signs the `.iq` and `.prg` output.
  `.gitignore` excludes `bin/`, `*.iq`, `*.prg` and `developer_key*`/`*.der`; keep it that way, and
  back the key up somewhere private — every update must be signed with the same key, or it becomes a
  different app on the Connect IQ store.
- **`SensorHistory`** is the only requested permission, used for the health gauges on the dial. No
  data leaves the watch.
- **Generated resources** (`resources/properties`, `settings`, `strings`) come from
  `tools/gen_settings.py`. Editing the XML by hand makes them disagree with the generator, so the
  settings job in CI fails instead of silently shipping mismatched option lists.

## Maintenance procedure

- Run `python3 tools/check_resources.py` and `python3 tools/gen_settings.py` before building; CI runs
  both on every push and pull request.
- Build and test in the Connect IQ simulator (`monkeyc`, `monkeydo`) and confirm battery drain on a
  real fenix 8 before publishing a beta, as `docs/PUBLISHING.md` describes.
- Keep the device list in `manifest.xml` and the supported-devices text in `README.md` in step.

This documents the current design, not an audit. No response SLA is promised.
