# Pull request checklist

- [ ] `python3 tools/gen_settings.py` re-run after any settings-table change, with the regenerated
      XML committed
- [ ] `python3 tools/check_resources.py` passes (CI runs both)
- [ ] Built and observed in the Connect IQ simulator; a second device or a screenshot of the always-on
      view when the change affects it
- [ ] `README.md` device list and `manifest.xml` `<iq:products>` still agree
- [ ] No `developer_key*`, `*.der`, `bin/`, `.iq` or `.prg` file in the diff
- [ ] Battery/recompute impact mentioned when the drawing path changed
