#!/usr/bin/env bash
# Builds every face of the series on a Mac with the Connect IQ SDK installed.
#
#   series/build.sh                 store packages: series/bin/<Name>.iq for every face
#   series/build.sh fenix847mm      also a simulator build per face: series/bin/<id>-fenix847mm.prg
#
# Then run one in the simulator:  connectiq &  monkeydo series/bin/bitlevel-fenix847mm.prg fenix847mm
set -euo pipefail

KEY="${KEY:-$HOME/.garmin-keys/developer_key.der}"
DEVDIR="${DEVDIR:-$HOME/Library/Application Support/Garmin/ConnectIQ/Devices}"
SIM="${1:-}"
[ -d /opt/homebrew/opt/openjdk@21/bin ] && export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"

cd "$(dirname "$0")"
command -v monkeyc >/dev/null || { echo "monkeyc not found: add the SDK bin folder to PATH"; exit 1; }
[ -f "$KEY" ] || { echo "Developer key not found: $KEY"; exit 1; }

# Keep only device ids this SDK knows (prints every device with its screen).
if [ -d "$DEVDIR" ]; then
    python3 tools/series.py --sdk-devices "$DEVDIR"
else
    echo "SDK device folder not found ($DEVDIR); using the full device list."
    python3 tools/series.py
fi

mkdir -p bin
for dir in faces/*/; do
    id="$(basename "$dir")"
    name="$(sed -n 's:.*<string id="AppName">\(.*\)</string>.*:\1:p' "$dir/resources/strings/strings.xml" | tr -d ' ')"
    echo "== $name ($id)"
    monkeyc -e -r -w -f "$dir/monkey.jungle" -o "bin/$name.iq" -y "$KEY"
    if [ -n "$SIM" ]; then
        monkeyc -d "$SIM" -w -f "$dir/monkey.jungle" -o "bin/$id-$SIM.prg" -y "$KEY"
    fi
done
echo "Done. Store packages are in series/bin/"
